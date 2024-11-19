local s = Nmsh['Settings']
local QBCore = exports[s.core]:GetCoreObject()
local playerBasket = {}

CreateThread(function()

    local model = GetHashKey(Nmsh['Seller-NPC'].model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    local ped = CreatePed(0, model, Nmsh['Seller-NPC'].coords, false, false)
    SetEntityHeading(ped, Nmsh['Seller-NPC'].heading)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedDiesWhenInjured(ped, false)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, Nmsh['Seller-NPC'].coords, false, false, false, true)

    local sellerBlip = AddBlipForCoord(Nmsh['Seller-NPC'].coords.x, Nmsh['Seller-NPC'].coords.y, Nmsh['Seller-NPC'].coords.z)

    SetBlipSprite(sellerBlip, Nmsh['Seller-NPC'].blip.sprite)
    SetBlipDisplay(sellerBlip, 4) 
    SetBlipScale(sellerBlip, Nmsh['Seller-NPC'].blip.scale)
    SetBlipColour(sellerBlip, Nmsh['Seller-NPC'].blip.color)
    SetBlipAsShortRange(sellerBlip, true) 

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Nmsh['Seller-NPC'].blip.name)
    EndTextCommandSetBlipName(sellerBlip)

    exports.interact:AddLocalEntityInteraction({
        entity = ped,
        id = 'sellerInteraction', 
        distance = 2.5, 
        options = {
            {
                label = 'Talk to Seller',
                action = function(entity, coords, args)
                    openShopsMenu()
                end,
            },
        }
    })
end)

function openShopsMenu()
    local Menu = {
        {
            id = 1,
            isMenuHeader = true,
            header = '🛒 Supermarkets',
            icon = 'fas fa-store', 
            txt = 'Choose a shop to purchase and manage it.'
        },
    }

    for k, v in pairs(Nmsh['Supermarkets']) do
        table.insert(Menu, {
            id = k,
            header = v.name,
            txt = 'Price: $' .. v.price,
            icon = 'fas fa-shopping-cart', 
            params = {
                event = 'nmsh-supermarkets:openMarketActionsMenu',
                args = {
                    shop = k,
                    price = v.price,
                    coords = v.coords
                }
            },
        })
    end

    table.insert(Menu, {
        id = #Menu + 1,
        header = '❌ Close',
        txt = 'Exit the shop selection menu.',
        icon = 'fas fa-times-circle', 
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    })

    exports[s.menu]:openMenu(Menu)
end

RegisterNetEvent('nmsh-supermarkets:openMarketActionsMenu', function(data)
    local marketActionsMenu = {
        {
            id = 1,
            isMenuHeader = true,
            header = '🛒 ' .. Nmsh['Supermarkets'][data.shop].name,
            txt = 'Price: $' .. data.price,
            icon = 'fas fa-store'
        },
        {
            id = 2,
            header = '💰 Buy Shop',
            txt = 'Purchase this supermarket for $' .. data.price,
            icon = 'fas fa-money-bill-wave',
            params = {
                isServer = true,
                event = 'nmsh-supermarkets:buyShop',
                args = {
                    shop = data.shop,
                    price = data.price
                }
            }
        },
        {
            id = 3,
            header = '📍 See Location',
            txt = 'Set a waypoint to this supermarket.',
            icon = 'fas fa-map-marker-alt',
            params = {
                event = 'nmsh-supermarkets:setWaypoint',
                args = {
                    coords = data.coords
                }
            }
        },
        {
            id = 4,
            header = '❌ Close',
            txt = 'Return to the previous menu.',
            icon = 'fas fa-times-circle',
            params = {
                event = 'qb-menu:client:closeMenu'
            }
        }
    }

    exports[s.menu]:openMenu(marketActionsMenu)
end)

RegisterNetEvent('nmsh-supermarkets:setWaypoint', function(data)
    local coords = data.coords
    SetNewWaypoint(coords.x, coords.y) 
    TriggerEvent('QBCore:Notify', 'Waypoint set to the selected supermarket.', 'success')
end)

function GetClosestShop()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestShopId = nil
    local closestDistance = -1

    for shopId, shopData in pairs(Nmsh['Supermarkets']) do
        local shopCoords = shopData.coords
        local distance = #(playerCoords - shopCoords)

        if closestDistance == -1 or distance < closestDistance then
            closestDistance = distance
            closestShopId = shopId
        end
    end

    return closestShopId
end

CreateThread(function()
    for shopId, supermarket in pairs(Nmsh['Supermarkets']) do

        local sellerModel = GetHashKey(supermarket.npc.model)
        RequestModel(sellerModel)
        while not HasModelLoaded(sellerModel) do
            Wait(1)
        end

        local sellerPed = CreatePed(0, sellerModel, supermarket.npc.coords, false, false)
        SetEntityHeading(sellerPed, supermarket.npc.heading)
        SetPedFleeAttributes(sellerPed, 0, 0)
        SetPedDiesWhenInjured(sellerPed, false)
        TaskStartScenarioInPlace(sellerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
        SetPedKeepTask(sellerPed, true)
        SetBlockingOfNonTemporaryEvents(sellerPed, true)
        SetEntityInvincible(sellerPed, true)
        FreezeEntityPosition(sellerPed, true)
        SetEntityCoordsNoOffset(sellerPed, supermarket.npc.coords, false, false, false, true)

        exports.interact:AddLocalEntityInteraction({
            entity = sellerPed,
            offset = vec3(0.0, 0.0, 0.2), 
            id = 'shopsellerInteraction_' .. shopId, 
            distance = 6.0, 
            interactDst = 5.0,
            options = {
                {
                    label = 'Talk to Seller',
                    action = function(entity, coords, args)

                        TriggerEvent('nmsh-supermarkets:openSellerMenu', shopId)
                    end,
                },
            }
        })

        local managerModel = GetHashKey(supermarket.manager.model)
        RequestModel(managerModel)
        while not HasModelLoaded(managerModel) do
            Wait(1)
        end

        local managerPed = CreatePed(0, managerModel, supermarket.manager.coords, false, false)
        SetEntityHeading(managerPed, supermarket.manager.heading)
        SetPedFleeAttributes(managerPed, 0, 0)
        SetPedDiesWhenInjured(managerPed, false)
        TaskStartScenarioInPlace(managerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
        SetPedKeepTask(managerPed, true)
        SetBlockingOfNonTemporaryEvents(managerPed, true)
        SetEntityInvincible(managerPed, true)
        FreezeEntityPosition(managerPed, true)
        SetEntityCoordsNoOffset(managerPed, supermarket.manager.coords, false, false, false, true)

        exports.interact:AddLocalEntityInteraction({
            entity = managerPed,
            offset = vec3(0.0, 0.0, 0.2), 
            id = 'shopmanagerInteraction_' .. shopId, 
            distance = 6.0, 
            interactDst = 5.0,
            options = {
                {
                    label = 'Access Management Menu',
                    action = function(entity, coords, args)

                        QBCore.Functions.TriggerCallback('nmsh-supermarkets:isShopOwner', function(isOwner)
                            if isOwner then

                                print(shopId)
                                TriggerEvent('nmsh-supermarkets:openManagementMenu', shopId)
                            else

                                TriggerEvent('QBCore:Notify', 'You are not authorized to access the management menu.', 'error')
                            end
                        end, shopId)
                    end,
                },
            }
        })
    end
end)

CreateThread(function()
    for _, supermarket in pairs(Nmsh['Supermarkets']) do
        local blip = AddBlipForCoord(supermarket.coords.x, supermarket.coords.y, supermarket.coords.z)
        SetBlipSprite(blip, 52) 
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7) 
        SetBlipColour(blip, 2) 
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(supermarket.name)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterCommand('openshops', function()
    openManagementMenu("supermarket1")
end)

function openManagementMenu(shopId)
    local Menu = {
        {
            id = 1,
            isMenuHeader = true,
            header = 'Manage ' .. Nmsh['Supermarkets'][shopId].name,
            icon = 'fas fa-store' 
        },
        {
            id = 2,
            header = 'Order Products',
            txt = 'Order products to restock your shop.',
            icon = 'fas fa-box', 
            params = {
                event = 'nmsh-supermarkets:openProductMenu',
                args = {
                    shopId = shopId
                }
            }
        },
        {
            id = 3,
            header = 'Withdraw Money',
            txt = 'Withdraw earnings from your shop.',
            icon = 'fas fa-hand-holding-usd', 
            params = {
                isServer = true,
                event = 'nmsh-supermarkets:withdrawMoney',
                args = {
                    shopId = shopId
                }
            }
        },
        {
            id = 4,
            header = 'Check Stock',
            txt = 'View current stock levels.',
            icon = 'fas fa-boxes', 
            params = {
                isServer = true,
                event = 'nmsh-supermarkets:checkStock',
                args = {
                    shopId = shopId
                }
            }
        },
        {
            id = 5,
            header = 'Change Item Prices',
            txt = 'Change the prices of items in your shop.',
            icon = 'fas fa-tags', 
            params = {
                event = 'nmsh-supermarkets:changeItemPrices',
                args = {
                    shopId = shopId
                }
            }
        },
        {
            id = 6,
            header = 'Close',
            icon = 'fas fa-times-circle', 
            params = {
                event = s.menu .. 'client:closeMenu'
            }
        }
    }
    exports[s.menu]:openMenu(Menu)
end

RegisterNetEvent('nmsh-supermarkets:changeItemPrices', function(data)
    local shopId = data.shopId
    local priceMenu = {
        {
            id = 1,
            isMenuHeader = true,
            header = 'Change Item Prices'
        }
    }

    for productId, productData in pairs(Nmsh['Products']) do
        table.insert(priceMenu, {
            id = #priceMenu + 1,
            header = productData.name .. ' - Current Price: $' .. productData.price,
            txt = 'Click to change price.',
            params = {
                event = 'nmsh-supermarkets:inputNewPrice',
                args = {
                    productId = productId,
                    shopId = shopId
                }
            }
        })
    end

    table.insert(priceMenu, {
        id = #priceMenu + 1,
        header = 'Close',
        icon = 'fas fa-times-circle',
        params = {
            event = s.menu .. 'client:closeMenu'
        }
    })

    exports[s.menu]:openMenu(priceMenu)
end)

RegisterNetEvent('nmsh-supermarkets:inputNewPrice', function(data)
    local productId = data.productId
    local shopId = data.shopId
    print('Product ID:', productId)
    local input = exports[s.input]:ShowInput({
        header = 'Change Price for ' .. Nmsh['Products'][productId].name,
        submitText = 'Confirm',
        inputs = {
            {
                text = 'Enter the new price for the product', 
                name = 'newPrice', 
                type = 'number', 
                isRequired = true, 
            },
        }
    })
    if input then
        print('Result', input)
        print('New Price:', input.newPrice)
        local newPrice = tonumber(input.newPrice)

        if newPrice and newPrice > 0 then
            TriggerServerEvent('nmsh-supermarkets:updateProductPrice', shopId, productId, newPrice)
        else
            TriggerEvent('QBCore:Notify', 'Invalid price entered.', 'error')
        end
    end
end)

RegisterNetEvent('nmsh-supermarkets:manageMoney', function(data)
    print(data.shopId)
    local shopId = data.shopId

    local moneyMenu = {
        {
            id = 1,
            isMenuHeader = true,
            header = 'Money Management'
        },
        {
            id = 2,
            header = 'Show Balance',
            txt = 'View the current balance of your shop.',
            icon = 'fas fa-balance-scale', 
            params = {
                isServer = true,
                event = 'nmsh-supermarkets:showBalance',
                args = {
                    shopId = shopId
                }
            }
        },
        {
            id = 3,
            header = 'Withdraw Money',
            txt = 'Withdraw earnings from your shop.',
            icon = 'fas fa-dollar-sign', 
            params = {
                isServer = true,
                event = 'nmsh-supermarkets:withdrawMoney',
                args = {
                    shopId = shopId
                }
            }
        },
        {
            id = 4,
            header = 'Back',
            icon = 'fas fa-arrow-left', 
            params = {
                event = 'nmsh-supermarkets:openManagementMenu',
                args = {
                    shopId = shopId
                }
            }
        }
    }
    exports[s.menu]:openMenu(moneyMenu)
end)

RegisterNetEvent('nmsh-supermarkets:showStockMenu', function(products)
    local stockMenu = {
        {
            id = 1,
            isMenuHeader = true,
            header = 'Shop Stock Levels',
        },
    }

    for productId, productData in pairs(products) do
        local productName = Nmsh['Products'][productId] and Nmsh['Products'][productId].name or productId
        local productImage = QBCore.Shared.Items[productId] and QBCore.Shared.Items[productId].image or nil
        local stock = productData.stock or 0 

        table.insert(stockMenu, {
            id = #stockMenu + 1,
            header = productName,
            icon = "nui://" .. s.inventory .. productImage,
            disabled = true,
            txt = 'Stock: ' .. stock .. ' units',
        })
    end

    table.insert(stockMenu, {
        id = #stockMenu + 1,
        header = 'Close',
        params = {
            event = s.menu .. 'client:closeMenu'
        }
    })

    exports[s.menu]:openMenu(stockMenu)
end)

RegisterNetEvent('nmsh-supermarkets:openManagementMenu', function(shopId)
    openManagementMenu(shopId)
end)

RegisterNetEvent('nmsh-supermarkets:selectQuantity', function(data)
    local input = exports[s.input]:ShowInput({
        header = 'Enter Quantity',
        submitText = 'Order',
        inputs = {
            {
                text = 'Amount', 
                name = 'quantity', 
                type = 'number', 
                isRequired = true, 
            },
        }
    })

    if input then
        local quantity = tonumber(input.quantity)
        if quantity and quantity > 0 then

            TriggerServerEvent('nmsh-supermarkets:orderProduct', {
                shopId = data.shopId,
                productId = data.productId,
                price = data.price,
                quantity = quantity
            })
        else
            TriggerEvent('QBCore:Notify', 'Invalid quantity entered.', 'error')
        end
    end
end)

local productBasket = {}

RegisterNetEvent('nmsh-supermarkets:openProductMenu', function()
    local productMenu = {
        {
            id = 1,
            isMenuHeader = true,
            header = 'Select Products',
            icon = 'fas fa-boxes' 
        },
    }

    for productId, productData in pairs(Nmsh['Products']) do
        table.insert(productMenu, {
            id = #productMenu + 1,
            header = productData.name .. ' - $' .. productData.price .. ' per unit',
            icon = "nui://" .. "qb-inventory/html/images/" .. productId, 
            params = {
                event = 'nmsh-supermarkets:addToBasket',
                args = {
                    productId = productId,
                    price = productData.price
                }
            }
        })
    end

    table.insert(productMenu, {
        id = #productMenu + 1,
        header = '🛒 Review Basket',
        txt = 'View items in your basket and the total cost.',
        icon = 'fas fa-shopping-basket', 
        params = {
            event = 'nmsh-supermarkets:reviewBasket',
        }
    })

    table.insert(productMenu, {
        id = #productMenu + 1,
        header = 'Close',
        icon = 'fas fa-times-circle', 
        params = {
            event = s.menu .. 'client:closeMenu'
        }
    })

    exports[s.menu]:openMenu(productMenu)
end)

RegisterNetEvent('nmsh-supermarkets:addToBasket', function(data)
    local input = exports[s.input]:ShowInput({
        header = 'Enter Quantity',
        submitText = 'Add to Basket',
        inputs = {
            {
                text = 'Quantity', 
                name = 'quantity', 
                type = 'number', 
                isRequired = true, 
            },
        }
    })

    if input then
        local quantity = tonumber(input.quantity)
        if quantity and quantity > 0 then
            local productId = data.productId
            local price = data.price

            productBasket[productId] = (productBasket[productId] or 0) + quantity
            TriggerEvent('QBCore:Notify', 'Added ' .. quantity .. ' units of ' .. Nmsh['Products'][productId].name .. ' to the basket.', 'success')
        else
            TriggerEvent('QBCore:Notify', 'Invalid quantity entered.', 'error')
        end
    end
end)

RegisterNetEvent('nmsh-supermarkets:reviewBasket', function()

    QBCore.Functions.TriggerCallback('nmsh-supermarkets:getPlayerShopId', function(shopId)
        if not shopId then
            TriggerEvent('QBCore:Notify', 'You do not own a market.', 'error')
            return
        end

        local basketMenu = {
            {
                id = 1,
                isMenuHeader = true,
                header = 'Your Basket',
                icon = 'fas fa-shopping-basket' 
            },
        }

        local totalPrice = 0
        for productId, quantity in pairs(productBasket) do
            local productName = Nmsh['Products'][productId].name
            local price = Nmsh['Products'][productId].price
            local itemTotal = price * quantity
            totalPrice = totalPrice + itemTotal

            table.insert(basketMenu, {
                id = #basketMenu + 1,
                header = productName .. ' x ' .. quantity,
                txt = 'Total: $' .. itemTotal,
                disabled = true,
                icon = 'fas fa-box' 
            })
        end
        table.insert(basketMenu, {
            id = #basketMenu + 1,
            header = 'Confirm Purchase - Total: $' .. totalPrice,
            txt = 'Complete the purchase and start the delivery process.',
            params = {
                isServer = true,
                event = 'nmsh-supermarkets:finalizePurchase',
                args = {
                    totalPrice = totalPrice,
                    basket = productBasket,
                    shopId = shopId 
                }
            },
            icon = 'fas fa-check-circle' 
        })

        table.insert(basketMenu, {
            id = #basketMenu + 1,
            header = 'Return',
            txt = 'Go back to product selection.',
            params = {
                event = 'nmsh-supermarkets:openProductMenu' 
            },
            icon = 'fas fa-arrow-left' 
        })

        table.insert(basketMenu, {
            id = #basketMenu + 1,
            header = 'Close',
            params = {
                event = s.menu .. 'client:closeMenu'
            },
            icon = 'fas fa-times-circle' 
        })

        exports[s.menu]:openMenu(basketMenu)
    end)
end)

local vehicle_name = nil
RegisterNetEvent('nmsh-supermarkets:spawnTruckForDelivery', function(data)
    local vehicleModel = 'bison' 
    local basket = data.basket
    local shopId = data.shopId
    local boxModel = 'prop_paper_box_01' 
    local playerPed = PlayerPedId()
    local supermarketCoords = Nmsh['Supermarkets'][shopId].coords
    local truckCoords = Nmsh['Supermarkets'][shopId].truck

    print('Basket:', json.encode(shopId))
    print('Truck spawned with ID: ' .. truckCoords.x .. ',' .. truckCoords.y .. ',' .. truckCoords.z .. ', heading: ' .. truckCoords.w)

    QBCore.Functions.SpawnVehicle(vehicleModel, function(veh)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
        SetVehicleEngineOn(veh, true, true)
        boxEntity = CreateObject(GetHashKey(boxModel), truckCoords.x, truckCoords.y, truckCoords.z, true, true, true)
        vehicle_name = veh
        SetEntityAsMissionEntity(boxEntity, true, true)
        SetEntityHeading(boxEntity, truckCoords.w)
        AttachEntityToEntity(boxEntity, veh, GetEntityBoneIndexByName(veh, "boot"), 0.0, 1.0, 0.2, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    end, vector4(truckCoords.x, truckCoords.y, truckCoords.z, truckCoords.w), true)    

    local collectionLocation = Nmsh['locations'][math.random(1, #Nmsh['locations'])]

    local collectionBlip = AddBlipForCoord(collectionLocation.x, collectionLocation.y, collectionLocation.z)
    SetBlipSprite(collectionBlip, 1)
    SetBlipColour(collectionBlip, 3)
    SetBlipRoute(collectionBlip, true)
    SetBlipRouteColour(collectionBlip, 3)

    CreateThread(function()
        local hasCollected = false
        while not hasCollected do
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - collectionLocation)

            if distance < 10.0 then

                RemoveBlip(collectionBlip)
                TriggerEvent('QBCore:Notify', 'Collecting products. Please wait...', 'primary')

                exports[s.progressbar]:Progress({
                    name = 'collecting_products',
                    duration = s.progressbarTime, 
                    label = 'Collecting Products...',
                    useWhileDead = false,
                    canCancel = false,
                    controlDisables = {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    },
                }, function(status)
                    if not status then
                        hasCollected = true
                        TriggerEvent('QBCore:Notify', 'Products collected. Return to the supermarket to stock them.', 'success')
                        local returnBlip = AddBlipForCoord(truckCoords.x, truckCoords.y, truckCoords.z)
                        SetBlipSprite(returnBlip, 1)
                        SetBlipColour(returnBlip, 2)
                        SetBlipRoute(returnBlip, true)
                        SetBlipRouteColour(returnBlip, 2)

                       local coords = GetEntityCoords(boxEntity)
                        print('coords:'..coords)
                        print('vehicle:'..json.encode(vehicle_name))
                        local box_open = CreateObjectNoOffset("prop_paper_box_03", coords, true, true, true)
                        AttachEntityToEntity(box_open, vehicle_name, GetEntityBoneIndexByName(vehicle_name, "boot"), 0.0, 1.0, 0.2, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                        DeleteEntity(boxEntity)
                        CreateThread(function()
                            while true do
                                local playerCoords = GetEntityCoords(playerPed)
                                local distance = #(playerCoords - vector3(truckCoords.x, truckCoords.y, truckCoords.z))
                                if distance < 10.0 then
                                    TriggerServerEvent('nmsh-supermarkets:transferItemsToStore', shopId, GetVehicleNumberPlateText(vehicle), basket)
                                    NetworkFadeOutEntity(vehicle_name, true,false)
                                    Citizen.Wait(1000)
                                    QBCore.Functions.DeleteVehicle(vehicle_name)
                                    DeleteEntity(box_open)
                                    vehicle_name = nil
                                    RemoveBlip(returnBlip)
                                    break
                                end

                                Wait(1000)
                            end
                        end)
                    end
                end)
            end

            Wait(1000)
        end
    end)
end)

RegisterNetEvent('nmsh-supermarkets:addToPlayerBasket', function(data)
    local productId = data.productId
    local price = data.price
    local shopId = data.shopId

    if not shopId then
        TriggerEvent('QBCore:Notify', 'Shop ID is missing.', 'error')
        return
    end

    QBCore.Functions.TriggerCallback('nmsh-supermarkets:getProductStock', function(stock)
        if stock > 0 then

            local input = exports[s.input]:ShowInput({
                header = "Enter Quantity",
                submitText = "Add to Basket",
                inputs = {
                    {
                        text = "Quantity", 
                        name = "quantity", 
                        type = "number", 
                        isRequired = true, 
                    }
                }
            })

            if input then
                local quantity = tonumber(input.quantity)
                if quantity and quantity > 0 then

                    if stock >= quantity then

                        if playerBasket[productId] then

                            playerBasket[productId] = playerBasket[productId] + quantity
                        else

                            playerBasket[productId] = quantity
                        end

                        TriggerEvent('QBCore:Notify', Nmsh['Products'][productId].name .. ' x' .. quantity .. ' added to basket.', 'success')

                        TriggerEvent('nmsh-supermarkets:openSellerMenu', shopId)
                    else

                        TriggerEvent('QBCore:Notify', 'Not enough stock for ' .. Nmsh['Products'][productId].name .. '. Available: ' .. stock, 'error')
                    end
                else
                    TriggerEvent('QBCore:Notify', 'Invalid quantity. Please try again.', 'error')
                end
            end
        else

            TriggerEvent('QBCore:Notify', 'No stock available for this product.', 'error')
        end
    end, shopId, productId) 
end)

RegisterNetEvent('nmsh-supermarkets:confirmPurchase', function(data)

    if next(playerBasket) == nil then 

        TriggerEvent('QBCore:Notify', 'Your basket is empty. You cannot proceed with the purchase.', 'error')
        return 
    end

    local totalPrice = 0

    for productId, quantity in pairs(playerBasket) do
        local productData = Nmsh['Products'][productId]
        if productData then
            totalPrice = totalPrice + (productData.price * quantity)
        end
    end

    local paymentMenu = {
        {
            id = 1,
            isHeader = true,
            header = 'Select Payment Method',
        },
        {
            id = 2,
            header = 'Pay with Cash',
            txt = 'Total: $' .. totalPrice,
            params = {
                event = 'nmsh-supermarkets:processPayment',
                args = {
                    paymentType = 'cash',
                    shopId = data.shopId,
                    totalPrice = totalPrice,
                    basket = playerBasket 
                }
            }
        },
        {
            id = 3,
            header = 'Pay with Bank',
            txt = 'Total: $' .. totalPrice,
            params = {
                event = 'nmsh-supermarkets:processPayment',
                args = {
                    paymentType = 'bank',
                    shopId = data.shopId,
                    totalPrice = totalPrice,
                    basket = playerBasket 
                }
            }
        },
        {
            id = 4,
            header = 'Cancel',
            params = {
                event = s.menu .. 'client:closeMenu'
            }
        }
    }

    exports[s.menu]:openMenu(paymentMenu)
end)

RegisterNetEvent('nmsh-supermarkets:processPayment', function(data)
    local paymentType = data.paymentType
    local totalPrice = data.totalPrice
    local basket = data.basket
    local shopId = data.shopId

    print("Processing payment:")
    print("Payment type:", paymentType)
    print("Total price:", totalPrice)
    print("Basket:", json.encode(basket))
    print("Shop ID:", shopId)

    TriggerServerEvent('nmsh-supermarkets:processPurchase', totalPrice, paymentType, basket, shopId)

    playerBasket = {}

    TriggerEvent('QBCore:Notify', 'Your purchase is complete and your basket has been cleared.', 'success')
end)

RegisterNetEvent('nmsh-supermarkets:openSellerMenu', function(shopId)

    QBCore.Functions.TriggerCallback('nmsh-supermarkets:getShopProducts', function(products)
        if not products then
            TriggerEvent('QBCore:Notify', 'No products found in this shop.', 'error')
            return
        end

        local sellerMenu = {
            {
                id = 1,
                isHeader = true,
                header = Nmsh['Supermarkets'][shopId].name .. ' Products',
                icon = 'fas fa-shopping-cart'
            },
        }

        for productId, productInfo in pairs(products) do
            local productData = Nmsh['Products'][productId] 

            if productData then

                local stock = productInfo.stock or 0
                local price = productData.price or 0

                table.insert(sellerMenu, {
                    id = #sellerMenu + 1,
                    header = productData.name .. ' - $' .. price .. ' per unit (' .. stock .. ' in stock)',
                    icon = "nui://" .. "qb-inventory/html/images/" .. QBCore.Shared.Items[productId].image,
                    params = {
                        event = 'nmsh-supermarkets:addToPlayerBasket',
                        args = {
                            productId = productId,
                            price = price,
                            shopId = shopId 
                        }
                    },
                })
            end
        end

        table.insert(sellerMenu, {
            id = #sellerMenu + 1,
            header = 'Confirm Purchase',
            txt = 'Review your basket and proceed to payment.',
            params = {
                event = 'nmsh-supermarkets:confirmPurchase',
                args = {
                    shopId = shopId
                }
            },
            icon = 'fas fa-check-circle'
        })

        table.insert(sellerMenu, {
            id = #sellerMenu + 1,
            header = 'Close',
            params = {
                event = s.menu .. ':client:closeMenu'
            },
            icon = 'fas fa-times-circle'
        })

        exports[s.menu]:openMenu(sellerMenu)
    end, shopId)
end)

RegisterNetEvent('nmsh-supermarkets:openSellerMenu', function(shopId)

    QBCore.Functions.TriggerCallback('nmsh-supermarkets:getShopProducts', function(products)
        if not products then
            TriggerEvent('QBCore:Notify', 'No products found in this shop.', 'error')
            return
        end

        local sellerMenu = {
            {
                id = 1,
                isHeader = true,
                header = Nmsh['Supermarkets'][shopId].name .. ' Products',
                icon = 'fas fa-shopping-cart'
            },
        }

        for productId, productInfo in pairs(products) do
            local productData = Nmsh['Products'][productId] 

            if productData then

                local stock = productInfo.stock or 0
                local price = productInfo.price or 0

                table.insert(sellerMenu, {
                    id = #sellerMenu + 1,
                    header = productData.name .. ' - $' .. price .. ' per unit (' .. stock .. ' in stock)',
                    icon = "nui://" .. "qb-inventory/html/images/" .. QBCore.Shared.Items[productId].image,
                    params = {
                        event = 'nmsh-supermarkets:addToPlayerBasket',
                        args = {
                            productId = productId,
                            price = price,
                            shopId = shopId 
                        }
                    },
                })
            end
        end

        table.insert(sellerMenu, {
            id = #sellerMenu + 1,
            header = 'Confirm Purchase',
            txt = 'Review your basket and proceed to payment.',
            params = {
                event = 'nmsh-supermarkets:confirmPurchase',
                args = {
                    shopId = shopId
                }
            },
            icon = 'fas fa-check-circle'
        })

        table.insert(sellerMenu, {
            id = #sellerMenu + 1,
            header = 'Close',
            params = {
                event = s.menu .. ':client:closeMenu'
            },
            icon = 'fas fa-times-circle'
        })

        exports[s.menu]:openMenu(sellerMenu)
    end, shopId)
end)

RegisterNetEvent('nmsh-supermarkets:makePayment', function(data)
    local paymentType = data.paymentType
    local totalPrice = data.totalPrice
    local shopId = data.shopId

    TriggerServerEvent('nmsh-supermarkets:processPurchase', totalPrice, paymentType, playerBasket, shopId)

    playerBasket = {}
end)

RegisterNetEvent('nmsh-supermarkets:showInvoice', function(totalPrice)

    TriggerEvent('QBCore:Notify', 'Purchase successful! Total: $' .. totalPrice, 'success')

    playerBasket = {}
end)
