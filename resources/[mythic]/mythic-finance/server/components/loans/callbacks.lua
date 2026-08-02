function GetCharactersLoans(stateId)
    return MySQL.query.await('SELECT * FROM loans WHERE SID = ?', { stateId })
end

function RegisterLoanCallbacks()
    Callbacks:RegisterServerCallback('Loans:GetLoans', function(source, data, cb)
        local char = Fetch:Source(source):GetData('Character')
        if char then
            local SID = char:GetData('SID')
            local loans = GetCharactersLoans(SID)
            cb({
                loans = loans,
                creditScore = GetCharacterCreditScore(SID)
            })
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback('Loans:Payment', function(source, data, cb)
        local char = Fetch:Source(source):GetData('Character')
        if char and data and data.loan then
            local SID = char:GetData('SID')
            local res = Loans:MakePayment(source, data.loan, data.paymentAhead, data.weeks)
            if res and res.success then
                cb(res, {
                    loans = GetCharactersLoans(SID),
                    creditScore = GetCharacterCreditScore(SID),
                })
            else
                cb(res)
            end
        else
            cb(false)
        end
    end)
end