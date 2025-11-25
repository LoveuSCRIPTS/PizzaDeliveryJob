local ESX = exports['es_extended']:getSharedObject()
local hasJob = false
local hasPizzaInHand = false
local hasBigBoxInHand = false
local pizzasInStock = 0
local MaxStock = 2 -- Limit
local deliveryTimer = 0
local isTimerRunning = false

local currentVehicle = nil
local currentDelivery = nil
local deliveryBlip = nil
local customerPed = nil
local deliveryPoint = nil

local lastDeliveryIndex = nil 
local totalDelivered = 0

-- Function to format time (MM:SS)
local function formatTime(seconds)
    local min = math.floor(seconds / 60)
    local sec = seconds % 60
    return string.format("%02d:%02d", min, sec)
end

-- Cleanup function
local function cleanupDelivery()
    if customerPed and DoesEntityExist(customerPed) then
        DeleteEntity(customerPed)
    end
    if deliveryPoint then deliveryPoint:remove() end
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    
    customerPed = nil
    deliveryPoint = nil
    hasPizzaInHand = false
    isTimerRunning = false
    lib.hideTextUI()
    ExecuteCommand('e c')
end

-- 4. PHASE: Create Customer + Animations
local function spawnCustomer()
    if customerPed and DoesEntityExist(customerPed) then return end

    local model = GetHashKey(currentDelivery.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end

    local idleDict = 'anim@heists@heist_corona@single_team'
    RequestAnimDict(idleDict)
    while not HasAnimDictLoaded(idleDict) do Wait(1) end

    customerPed = CreatePed(4, model, currentDelivery.coords.x, currentDelivery.coords.y, currentDelivery.coords.z - 1.0, currentDelivery.heading, false, true)
    FreezeEntityPosition(customerPed, true)
    SetEntityInvincible(customerPed, true)
    SetBlockingOfNonTemporaryEvents(customerPed, true)

    TaskPlayAnim(customerPed, idleDict, 'single_team_loop_boss', 8.0, -8.0, -1, 1, 0, false, false, false)

    exports.ox_target:addLocalEntity(customerPed, {
        {
            name = 'deliver_pizza',
            icon = 'fa-solid fa-pizza-slice',
            label = 'Give Pizza',
            canInteract = function()
                return hasPizzaInHand
            end,
            onSelect = function()
                isTimerRunning = false
                lib.hideTextUI()

                local interactDict = 'mp_common'
                RequestAnimDict(interactDict)
                while not HasAnimDictLoaded(interactDict) do Wait(1) end

                TaskPlayAnim(customerPed, interactDict, 'givetake2_a', 8.0, 8.0, -1, 0, 0, false, false, false)

                if lib.progressBar({
                    duration = 2000,
                    label = 'Handing over order...',
                    useWhileDead = false,
                    canCancel = false,
                    disable = { move = true },
                    anim = {
                        dict = 'mp_common',
                        clip = 'givetake2_a'
                    },
                }) then
                    TriggerServerEvent('lovu_delivery:pay')
                    
                    pizzasInStock = pizzasInStock - 1
                    totalDelivered = totalDelivered + 1
                    
                    lib.notify({title = 'Done', description = 'Pizza delivered! Stock remaining: ' .. pizzasInStock, type = 'success'})
                    
                    cleanupDelivery()
                    Wait(2000)
                    
                    if pizzasInStock > 0 then
                        nextDelivery()
                    else
                        lib.notify({title = 'Empty Box', description = 'Out of stock! Return to pizzeria for more.', type = 'warning'})
                        SetNewWaypoint(Config.StartLocation.coords.x, Config.StartLocation.coords.y)
                    end
                end
            end
        }
    })
end

-- 3. PHASE: Setup Delivery + TIMER
function nextDelivery()
    if not hasJob then return end
    if pizzasInStock <= 0 then return end 

    local randomIndex = math.random(#Config.DeliveryPoints)
    if #Config.DeliveryPoints > 1 then
        while randomIndex == lastDeliveryIndex do
            randomIndex = math.random(#Config.DeliveryPoints)
            Wait(0)
        end
    end

    lastDeliveryIndex = randomIndex
    currentDelivery = Config.DeliveryPoints[randomIndex]

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(currentDelivery.coords.x, currentDelivery.coords.y, currentDelivery.coords.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Customer (Pizza)")
    EndTextCommandSetBlipName(deliveryBlip)

    lib.notify({title = 'New Order', description = 'Go to the marked location! Time is ticking.', type = 'info'})

    deliveryTimer = Config.DeliveryTime
    isTimerRunning = true
    
    CreateThread(function()
        while isTimerRunning and hasJob do
            if deliveryTimer > 0 then
                deliveryTimer = deliveryTimer - 1
                
                lib.showTextUI('Delivery Time: ' .. formatTime(deliveryTimer), {
                    position = "top-center",
                    icon = 'stopwatch',
                    style = {
                        borderRadius = 5,
                        backgroundColor = '#1c1c1c',
                        color = 'white'
                    }
                })
            else
                isTimerRunning = false
                lib.hideTextUI()
                
                lib.notify({
                    title = "Time's up!",
                    description = 'Customer cancelled the order. Pizza got cold.',
                    type = 'error'
                })

                pizzasInStock = pizzasInStock - 1
                
                cleanupDelivery()
                
                Wait(2000)
                
                if pizzasInStock > 0 then
                    nextDelivery()
                else
                    lib.notify({title = 'Empty Box', description = 'Nothing to deliver. Return for stock.', type = 'warning'})
                    SetNewWaypoint(Config.StartLocation.coords.x, Config.StartLocation.coords.y)
                end
                
                break 
            end
            Wait(1000)
        end
        lib.hideTextUI()
    end)

    deliveryPoint = lib.points.new({
        coords = currentDelivery.coords,
        distance = 60.0,
        onEnter = spawnCustomer,
        onExit = function()
            if customerPed and DoesEntityExist(customerPed) then
                DeleteEntity(customerPed)
                customerPed = nil
            end
        end
    })
end

-- 2. PHASE: Restock
local function takeStock()
    if pizzasInStock > 0 then
        lib.notify({type = 'error', description = 'You still have pizzas in the bike!'})
        return
    end

    if lib.progressBar({
        duration = 2000,
        label = 'Taking pizza stock...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true },
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle'
        },
    }) then
        hasBigBoxInHand = true
        ExecuteCommand('e carrypizza2')
        lib.notify({title = 'Got Stock', description = 'Now go to the bike and load it.', type = 'info'})
    end
end

-- 1. PHASE: Start Job + TUNING & FUEL
local function startJob()
    ESX.TriggerServerCallback('lovu_delivery:checkMoney', function(hasMoney)
        if hasMoney then
            hasJob = true
            totalDelivered = 0
            pizzasInStock = 0
            lastDeliveryIndex = nil
            
            ESX.Game.SpawnVehicle(Config.VehicleModel, Config.VehicleSpawn.coords, Config.VehicleSpawn.heading, function(vehicle)
                currentVehicle = vehicle
                TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
                SetVehicleNumberPlateText(vehicle, "PIZZA")
                
                -- === TUNING & FUEL ===
                SetVehicleModKit(vehicle, 0)
                SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Engine Max
                SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Brakes Max
                SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmission Max
                ToggleVehicleMod(vehicle, 18, true) -- Turbo

                -- Set Fuel 100%
                SetVehicleFuelLevel(vehicle, 100.0)
                if GetResourceState('ox_fuel') == 'started' then
                    Entity(vehicle).state.fuel = 100
                elseif GetResourceState('LegacyFuel') == 'started' then
                    exports['LegacyFuel']:SetFuel(vehicle, 100)
                end
                -- =====================

                exports.ox_target:addLocalEntity(vehicle, {
                    {
                        name = 'load_pizza_stock',
                        icon = 'fa-solid fa-boxes-packing',
                        label = 'Load pizzas into box',
                        canInteract = function()
                            return hasJob and hasBigBoxInHand and pizzasInStock == 0
                        end,
                        onSelect = function()
                            if lib.progressBar({
                                duration = 1500,
                                label = 'Loading pizzas...',
                                useWhileDead = false,
                                canCancel = false,
                                disable = { move = true },
                                anim = { dict = 'mini@repair', clip = 'fixing_a_ped' }
                            }) then
                                hasBigBoxInHand = false
                                pizzasInStock = MaxStock
                                ExecuteCommand('e c')
                                lib.notify({type = 'success', description = 'Box is full ('..MaxStock..'x). Start delivering!'})
                                nextDelivery()
                            end
                        end
                    },
                    {
                        name = 'take_pizza_single',
                        icon = 'fa-solid fa-box-open',
                        label = 'Take pizza for customer',
                        canInteract = function()
                            if not hasJob or hasPizzaInHand or pizzasInStock <= 0 then return false end
                            
                            if currentDelivery then
                                local dist = #(GetEntityCoords(cache.ped) - currentDelivery.coords)
                                return dist < 40.0
                            end
                            return false
                        end,
                        onSelect = function()
                            if lib.progressBar({
                                duration = 1000,
                                label = 'Taking pizza...',
                                useWhileDead = false,
                                canCancel = true,
                                disable = { move = true },
                                anim = { dict = 'mini@repair', clip = 'fixing_a_ped' }
                            }) then
                                hasPizzaInHand = true
                                ExecuteCommand('e carrypizza2')
                                lib.notify({description = 'You have the pizza, deliver it to the customer!', type = 'info'})
                            end
                        end
                    }
                })
            end)

            lib.notify({title = 'Shift Started', description = 'Scooter (Full Tuned) is ready. Take stock from the boss (via menu).', type = 'success'})
        else
            lib.notify({title = 'Error', description = 'Not enough money for deposit.', type = 'error'})
        end
    end)
end

local function stopJob()
    if currentVehicle then
        ESX.Game.DeleteVehicle(currentVehicle)
        currentVehicle = nil
    end
    cleanupDelivery()
    hasJob = false
    hasBigBoxInHand = false
    lastDeliveryIndex = nil
    ExecuteCommand('e c')
    TriggerServerEvent('lovu_delivery:returnDeposit')
    lib.notify({title = 'Finished', description = 'Deposit returned.', type = 'success'})
end

local function openPizzaMenu()
    local options = {}

    if not hasJob then
        table.insert(options, {
            title = 'Start Shift',
            description = 'Scooter Deposit: ' .. Config.DepositPrice .. '$',
            icon = 'motorcycle',
            onSelect = startJob
        })
    else
        if pizzasInStock == 0 and not hasBigBoxInHand then
            table.insert(options, {
                title = 'Take New Stock (2x)',
                description = 'Take boxes and load them onto the bike',
                icon = 'box',
                onSelect = takeStock
            })
        end

        table.insert(options, {
            title = 'End Shift',
            description = 'Return scooter and get deposit',
            icon = 'xmark',
            onSelect = stopJob
        })

        table.insert(options, {
            title = 'Status Info',
            description = 'Pizzas in bike: ' .. pizzasInStock .. '/' .. MaxStock .. '\nTotal delivered: ' .. totalDelivered,
            icon = 'circle-info',
            readOnly = true
        })
    end

    lib.registerContext({
        id = 'pizza_main_menu',
        title = 'Pizza This',
        options = options
    })
    lib.showContext('pizza_main_menu')
end

CreateThread(function()
    local model = GetHashKey(Config.StartLocation.npcModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end

    local ped = CreatePed(4, model, Config.StartLocation.coords.x, Config.StartLocation.coords.y, Config.StartLocation.coords.z - 1.0, Config.StartLocation.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'open_pizza_menu',
            icon = 'fa-solid fa-pizza-slice',
            label = 'Pizza Delivery Job',
            onSelect = openPizzaMenu
        }
    })

    local blip = AddBlipForCoord(Config.StartLocation.coords.x, Config.StartLocation.coords.y, Config.StartLocation.coords.z)
    SetBlipSprite(blip, 267)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza This")
    EndTextCommandSetBlipName(blip)
end)