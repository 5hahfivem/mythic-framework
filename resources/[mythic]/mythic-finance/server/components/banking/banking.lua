function GenerateBankAccountNumber()
    local bankAccount = math.random(100001, 999999)
    while IsAccountNumberInUse(bankAccount) do
        bankAccount = math.random(100001, 999999)
    end

    return bankAccount
end

function IsAccountNumberInUse(account)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM bank_accounts WHERE Account = ?', { account })

    return count ~= nil and count > 0
end

function DecodeBankAccount(row)
    if row == nil then
        return false
    end

    local account = json.decode(row.data)
    account._id = row.id
    account.Account = row.Account
    account.Balance = row.Balance

    return account
end

function BuildAccountQuery(query)
    local clauses, params = {}, {}

    for k, v in pairs(query) do
        if k == 'Account' or k == 'Type' or k == 'Owner' or k == 'Name' then
            table.insert(clauses, string.format('`%s` = ?', k))
            table.insert(params, v)
        elseif k == '$or' then
            local ors = {}
            for k2, condition in ipairs(v) do
                for k3, val in pairs(condition) do
                    if k3 == 'JointOwners' then
                        table.insert(ors, "JSON_CONTAINS(JSON_EXTRACT(`data`, '$.JointOwners'), CAST(? AS JSON))")
                        table.insert(params, json.encode(val))
                    else
                        table.insert(ors, string.format('`%s` = ?', k3))
                        table.insert(params, val)
                    end
                end
            end
            table.insert(clauses, string.format('(%s)', table.concat(ors, ' OR ')))
        end
    end

    if #clauses == 0 then
        return '1 = 1', params
    end

    return table.concat(clauses, ' AND '), params
end

function FindBankAccount(query)
    local where, params = BuildAccountQuery(query)

    return DecodeBankAccount(MySQL.single.await(
        string.format('SELECT * FROM bank_accounts WHERE %s', where),
        params
    ))
end

function FindBankAccounts(query)
    local where, params = BuildAccountQuery(query)
    local rows = MySQL.query.await(
        string.format('SELECT * FROM bank_accounts WHERE %s', where),
        params
    )

    if #rows == 0 then
        return false
    end

    local accounts = {}
    for k, v in ipairs(rows) do
        table.insert(accounts, DecodeBankAccount(v))
    end

    return accounts
end

function CreateBankAccount(document)
    if type(document) ~= 'table' then return false end

    if not document.Account then
        document.Account = GenerateBankAccountNumber()
    end

    if not document.Name then
        document.Name = document.Account
    end

    if not document.Balance or document.Balance < 0 then
        document.Balance = 0
    end

    local insertedId = MySQL.insert.await(
        'INSERT INTO bank_accounts (Account, Type, Owner, Name, Balance, `data`) VALUES(?, ?, ?, ?, ?, ?)',
        {
            document.Account,
            document.Type,
            document.Owner,
            document.Name,
            document.Balance,
            json.encode(document),
        }
    )

    if insertedId == nil then
        return false
    end

    document._id = insertedId

    return document
end

function UpdateBankAccount(searchQuery, updateQuery)
    local where, params = BuildAccountQuery(searchQuery)
    local clauses, setParams = {}, {}

    for op, fields in pairs(updateQuery) do
        for k, v in pairs(fields) do
            if op == '$inc' and k == 'Balance' then
                table.insert(clauses, 'Balance = Balance + ?')
                table.insert(setParams, v)
            elseif op == '$set' and (k == 'Name' or k == 'Balance' or k == 'Owner' or k == 'Type') then
                table.insert(clauses, string.format('`%s` = ?', k))
                table.insert(setParams, v)
            elseif op == '$set' then
                table.insert(clauses, "`data` = JSON_SET(`data`, ?, CAST(? AS JSON))")
                table.insert(setParams, string.format('$."%s"', k))
                table.insert(setParams, json.encode(v))
            elseif op == '$push' then
                table.insert(clauses, "`data` = JSON_ARRAY_APPEND(COALESCE(`data`, '{}'), ?, CAST(? AS JSON))")
                table.insert(setParams, string.format('$."%s"', k))
                table.insert(setParams, json.encode(v))
            end
        end
    end

    if #clauses == 0 then
        return false
    end

    for k, v in ipairs(params) do
        table.insert(setParams, v)
    end

    local updated = MySQL.query.await(
        string.format('UPDATE bank_accounts SET %s WHERE %s', table.concat(clauses, ', '), where),
        setParams
    )

    if updated == nil then
        return false
    end

    return FindBankAccount(searchQuery)
end

function FindBankAccountTransactions(query)
    local p = promise.new()

    local rows = MySQL.query.await(
        'SELECT * FROM bank_accounts_transactions WHERE Account = ? ORDER BY Timestamp DESC LIMIT 80',
        { query.Account }
    )

    if #rows > 0 then
        local transactions = {}
        for k, v in ipairs(rows) do
            table.insert(transactions, json.decode(v.transaction))
        end
        p:resolve(transactions)
    else
        p:resolve(false)
    end

    local res = Citizen.Await(p)
    return res
end

function GetDefaultBankAccountPermissions()
    return {
        MANAGE = 'BANK_ACCOUNT_MANAGE', -- Can Manage The Account (IDK What this does yet)
        WITHDRAW = 'BANK_ACCOUNT_WITHDRAW', -- Can Withdraw/Tranfer money
        DEPOSIT = 'BANK_ACCOUNT_DEPOSIT', -- Can Deposit
        TRANSACTIONS = 'BANK_ACCOUNT_TRANSACTIONS', -- Can View Transaction History
        BILL = 'BANK_ACCOUNT_BILL', -- Can Bill Using This Account
        BALANCE = 'BANK_ACCOUNT_BALANCE',
    }
end

function HasBankAccountPermission(source, accountData, permission, stateId)
    if accountData.Type == 'personal' then
        if accountData.Owner == stateId then
            return true
        end
    elseif accountData.Type == 'personal_savings' then
        if accountData.Owner == stateId then
            return true
        elseif accountData.JointOwners and #accountData.JointOwners > 0 then
            for k, v in ipairs(accountData.JointOwners) do
                if v == stateId and permission ~= 'MANAGE' then
                    return true
                end
            end
        end
    elseif accountData.Type == 'organization' then
        if accountData.JobAccess and #accountData.JobAccess > 0 then
            for k, v in ipairs(accountData.JobAccess) do
                if Jobs.Permissions:HasJob(source, v.Job, v.Workplace, false, false, false, v.Permissions[permission]) then
                    return true
                end
            end
        end
    end
    return false
end