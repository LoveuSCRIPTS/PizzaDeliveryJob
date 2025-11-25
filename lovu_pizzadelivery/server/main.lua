local ESX = exports['es_extended']:getSharedObject()

-- Callback for money check
ESX.RegisterServerCallback('lovu_delivery:checkMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= Config.DepositPrice then
        xPlayer.removeMoney(Config.DepositPrice)
        cb(true)
    else
        cb(false)
    end
end)

-- Return deposit
RegisterNetEvent('lovu_delivery:returnDeposit', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addMoney(Config.DepositPrice)
end)

-- Payment for delivery
RegisterNetEvent('lovu_delivery:pay', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Random reward
    local amount = math.random(Config.Payment.min, Config.Payment.max)
    
    xPlayer.addMoney(amount)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Delivered',
        description = 'Customer gave you ' .. amount .. '$',
        type = 'success'
    })
end)