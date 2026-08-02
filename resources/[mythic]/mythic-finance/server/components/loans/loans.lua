local _ranStartup = false

function RunLoanStartup()
    if _ranStartup then return end
    _ranStartup = true

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM loans WHERE Remaining > 0', {})

    if count ~= nil then
        Logger:Trace('Loans', 'Loaded ^2' .. count .. '^7 Active Loans')
    end
end

AddEventHandler('Finance:Server:Startup', function()
    RunLoanStartup()
    RegisterLoanCallbacks()

    CreateLoanTasks()
end)

function CreateLoanTasks()
    Tasks:Register('loan_payment', 60, function()
    --RegisterCommand('testloans', function()
        local TASK_RUN_TIMESTAMP = os.time()

        local applied = MySQL.query.await(
            [[UPDATE loans SET
                InterestRate = InterestRate + ?,
                LastMissedPayment = ?,
                MissedPayments = MissedPayments + 1,
                TotalMissedPayments = TotalMissedPayments + 1,
                NextPayment = NextPayment + ?,
                Remaining = Remaining + (Total * ?)
                WHERE NextPayment > 0 AND NextPayment <= ? AND Defaulted = 0 AND Remaining >= 0]],
            {
                _loanConfig.missedPayments.interestIncrease,
                TASK_RUN_TIMESTAMP,
                _loanConfig.paymentInterval,
                (_loanConfig.missedPayments.charge / 100),
                TASK_RUN_TIMESTAMP,
            }
        )

        if applied ~= nil then
            -- Get All the Loans are now need to be defaulted and notify/seize
            local results = MySQL.query.await(
                'SELECT * FROM loans WHERE MissedPayments >= MissablePayments AND Defaulted = 0',
                {}
            )

            if #results > 0 then
                local updatingAssets = {}

                for k, v in ipairs(results) do
                    table.insert(updatingAssets, v.AssetIdentifier)
                end

                local updated = MySQL.query.await(
                    string.format(
                        'UPDATE loans SET Defaulted = 1 WHERE AssetIdentifier IN (%s)',
                        string.rep('?, ', #updatingAssets - 1) .. '?'
                    ),
                    updatingAssets
                )

                if updated ~= nil then
                    Logger:Info('Loans', '^2' .. #results .. '^7 Loans Have Just Been Defaulted')
                    for k, v in ipairs(results) do
                        if v.SID then
                            DecreaseCharacterCreditScore(v.SID, _creditScoreConfig.removal.defaultedLoan)
                            local onlineChar = Fetch:SID(v.SID)
                            if onlineChar then
                                SendDefaultedLoanNotification(onlineChar:GetData('Source'), v)
                            end
                        end

                        if v.AssetIdentifier then
                            if v.Type == 'vehicle' then
                                Vehicles.Owned:Seize(v.AssetIdentifier, true)
                            elseif v.Type == 'property' then
                                -- TODO: PROPERTY TEMP SEIZURE
                            end
                        end
                    end
                end
            end

            -- Notify if someone just missed a payment.
            local results = MySQL.query.await(
                'SELECT * FROM loans WHERE MissedPayments < MissablePayments AND Defaulted = 0 AND LastMissedPayment = ?',
                { TASK_RUN_TIMESTAMP }
            )

            if #results > 0 then
                Logger:Info('Loans', '^2' .. #results .. '^7 Loan Payments Were Just Missed')
                for k, v in ipairs(results) do
                    if v.SID then
                        DecreaseCharacterCreditScore(v.SID, _creditScoreConfig.removal.missedLoanPayment)

                        local onlineChar = Fetch:SID(v.SID)
                        if onlineChar then
                            SendMissedLoanNotification(onlineChar:GetData('Source'), v)
                        end
                    end
                end
            end
        end
    end)

    Tasks:Register('loan_reminder', 120, function()
        local TASK_RUN_TIMESTAMP = os.time()
        -- Get All Loans That are Due Soon
        local results = MySQL.query.await(
            [[SELECT * FROM loans
                WHERE Remaining > 0 AND Defaulted = 0
                    AND ((NextPayment > 0 AND NextPayment <= ?) OR MissedPayments > 0)]],
            { (TASK_RUN_TIMESTAMP + (60 * 60 * 6)) }
        )

        print("this might hitch the server (loan_reminder task)")
        if #results > 0 then
                for k, v in ipairs(results) do
                    if v.SID then
                        local onlineChar = Fetch:SID(v.SID)
                        if onlineChar then
                            Phone.Notification:Add(onlineChar:GetData("Source"), "Loan Payment Due", "You have a loan payment that is due very soon.", os.time() * 1000, 7500, "loans", {})
                        end

                        Wait(100)
                    end
                end
        end
    end)
end

function SendMissedLoanNotification(source, loanData)
    Phone.Notification:Add(source, "Loan Payment Missed", "You just missed a loan payment on one of your loans.", os.time() * 1000, 7500, "loans", {})
end

function SendDefaultedLoanNotification(source, loanData)
    Phone.Notification:Add(source, "Loan Defaulted", "One of your loans just got defaulted and the assets are going to be seized.", os.time() * 1000, 7500, "loans", {})
end

local typeNames = {
    vehicle = 'Vehicle Loan',
    property = 'Property Loan',
}

function GetLoanTypeName(type)
    return typeNames[type]
end