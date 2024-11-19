local s = Nmsh['Settings']
local QBCore = exports[s.core]:GetCoreObject()
local playerBasket = {}

CreateThread(function()
    -- Define the model and request it
    local model = GetHashKey(Nmsh['Seller-NPC'].model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    -- Create the ped
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

    -- Set blip properties
    SetBlipSprite(sellerBlip, Nmsh['Seller-NPC'].blip.sprite)
    SetBlipDisplay(sellerBlip, 4) -- Display blip on all maps
    SetBlipScale(sellerBlip, Nmsh['Seller-NPC'].blip.scale)
    SetBlipColour(sellerBlip, Nmsh['Seller-NPC'].blip.color)
    SetBlipAsShortRange(sellerBlip, true) -- Make the blip visible only when close

    -- Set the blip name
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Nmsh['Seller-NPC'].blip.name)
    EndTextCommandSetBlipName(sellerBlip)

    -- Add an interaction to the ped
    exports.interact:AddLocalEntityInteraction({
        entity = ped,
        id = 'sellerInteraction', -- Unique identifier for this interaction
        distance = 2.5, -- Distance for the interaction to be accessible
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
            icon = 'fas fa-store', -- أيقونة المتجر من Font Awesome
            txt = 'Choose a shop to purchase and manage it.'
        },
    }
    
    for k, v in pairs(Nmsh['Supermarkets']) do
        table.insert(Menu, {
            id = k,
            header = v.name,
            txt = 'Price: $' .. v.price,
            icon = 'fas fa-shopping-cart', -- أيقونة لكل متجر
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

    -- خيار الإغلاق
    table.insert(Menu, {
        id = #Menu + 1,
        header = '❌ Close',
        txt = 'Exit the shop selection menu.',
        icon = 'fas fa-times-circle', -- أيقونة إغلاق
        params = {
            event = 'qb-menu:client:closeMenu'
        }
    })

    -- فتح القائمة
    exports[s.menu]:openMenu(Menu)
end

-- الحدث لفتح قائمة الأفعال لكل متجر
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

    -- فتح القائمة الخاصة بالمتجر المحدد
    exports[s.menu]:openMenu(marketActionsMenu)
end)

-- الحدث لإضافة نقطة الطريق (waypoint) إلى موقع المتجر
RegisterNetEvent('nmsh-supermarkets:setWaypoint', function(data)
    local coords = data.coords
    SetNewWaypoint(coords.x, coords.y) -- تحديد نقطة الطريق على الخريطة باستخدام الإحداثيات
    TriggerEvent('QBCore:Notify', 'Waypoint set to the selected supermarket.', 'success')
end)




-- Function to get the closest shop ID
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
        -- Define the seller model and request it
        local sellerModel = GetHashKey(supermarket.npc.model)
        RequestModel(sellerModel)
        while not HasModelLoaded(sellerModel) do
            Wait(1)
        end

        -- Create the seller ped
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
        -- Add an interaction to the seller ped
        exports.interact:AddLocalEntityInteraction({
            entity = sellerPed,
            offset = vec3(0.0, 0.0, 0.2), -- optional
            id = 'shopsellerInteraction_' .. shopId, -- Unique identifier for each interaction
            distance = 6.0, -- Distance for the interaction to be accessible
            interactDst = 5.0,
            options = {
                {
                    label = 'Talk to Seller',
                    action = function(entity, coords, args)
                        -- Trigger the event to open the closest shop menu for customers
                        TriggerEvent('nmsh-supermarkets:openSellerMenu', shopId)
                    end,
                },
            }
        })

        -- Define the manager model and request it
        local managerModel = GetHashKey(supermarket.manager.model)
        RequestModel(managerModel)
        while not HasModelLoaded(managerModel) do
            Wait(1)
        end

        -- Create the manager ped
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
        -- Add an interaction to the manager ped (for management menu)
        exports.interact:AddLocalEntityInteraction({
            entity = managerPed,
            offset = vec3(0.0, 0.0, 0.2), -- optional
            id = 'shopmanagerInteraction_' .. shopId, -- Unique identifier for manager interaction
            distance = 6.0, -- Distance for the interaction to be accessible
            interactDst = 5.0,
            options = {
                {
                    label = 'Access Management Menu',
                    action = function(entity, coords, args)
                        -- Trigger the callback to check if the player is the shop owner
                        QBCore.Functions.TriggerCallback('nmsh-supermarkets:isShopOwner', function(isOwner)
                            if isOwner then
                                -- Open the management menu if the player is the owner
                                print(shopId)
                                TriggerEvent('nmsh-supermarkets:openManagementMenu', shopId)
                            else
                                -- Notify the player if they are not the owner
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
        SetBlipSprite(blip, 52) -- Change 52 to another number for different blip icons
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7) -- Adjust size as needed
        SetBlipColour(blip, 2) -- Change 2 to a different number for different blip colors
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
            icon = 'fas fa-store' -- Icon for shop management header
        },
        {
            id = 2,
            header = 'Order Products',
            txt = 'Order products to restock your shop.',
            icon = 'fas fa-box', -- Icon for ordering products
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
            icon = 'fas fa-hand-holding-usd', -- Icon for withdrawing money
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
            icon = 'fas fa-boxes', -- Icon for checking stock
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
            icon = 'fas fa-tags', -- Icon for changing item prices
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
            icon = 'fas fa-times-circle', -- Icon for closing the menu
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

    -- Loop through the products and add them to the price change menu
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

    -- Close option
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
                text = 'Enter the new price for the product', -- Placeholder text
                name = 'newPrice', -- Name for the returned data
                type = 'number', -- Input type (number)
                isRequired = true, -- Ensure the field is not empty
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



-- Event for Manage Money
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
            icon = 'fas fa-balance-scale', -- Unique icon for showing balance
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
            icon = 'fas fa-dollar-sign', -- Unique icon for withdrawing money
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
            icon = 'fas fa-arrow-left', -- Icon for going back to the previous menu
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

    -- Loop through the products and add them to the menu
    for productId, productData in pairs(products) do
        local productName = Nmsh['Products'][productId] and Nmsh['Products'][productId].name or productId
        local productImage = QBCore.Shared.Items[productId] and QBCore.Shared.Items[productId].image or nil
        local stock = productData.stock or 0 -- Access the 'stock' value correctly from the productData table

        table.insert(stockMenu, {
            id = #stockMenu + 1,
            header = productName,
            icon = "nui://" .. s.inventory .. productImage,
            disabled = true,
            txt = 'Stock: ' .. stock .. ' units',
        })
    end

    -- Add a close option at the end of the menu
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
                text = 'Amount', -- Placeholder text
                name = 'quantity', -- Name for the returned data
                type = 'number', -- Input type (number)
                isRequired = true, -- Ensure the field is not empty
            },
        }
    })

    if input then
        local quantity = tonumber(input.quantity)
        if quantity and quantity > 0 then
            -- Trigger the event to order the selected quantity of the product
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
            icon = 'fas fa-boxes' -- Icon for the menu header
        },
    }

    -- Loop through the products and add them to the menu
    for productId, productData in pairs(Nmsh['Products']) do
        table.insert(productMenu, {
            id = #productMenu + 1,
            header = productData.name .. ' - $' .. productData.price .. ' per unit',
            icon = "nui://" .. "qb-inventory/html/images/" .. productId, -- Adding the product image icon
            params = {
                event = 'nmsh-supermarkets:addToBasket',
                args = {
                    productId = productId,
                    price = productData.price
                }
            }
        })
    end

    -- Add a button to review the basket
    table.insert(productMenu, {
        id = #productMenu + 1,
        header = '🛒 Review Basket',
        txt = 'View items in your basket and the total cost.',
        icon = 'fas fa-shopping-basket', -- Icon for reviewing the basket
        params = {
            event = 'nmsh-supermarkets:reviewBasket',
        }
    })

    -- Add a close option at the end of the menu
    table.insert(productMenu, {
        id = #productMenu + 1,
        header = 'Close',
        icon = 'fas fa-times-circle', -- Icon for closing the menu
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
                text = 'Quantity', -- Placeholder text
                name = 'quantity', -- Name for the returned data
                type = 'number', -- Input type (number)
                isRequired = true, -- Ensure the field is not empty
            },
        }
    })

    if input then
        local quantity = tonumber(input.quantity)
        if quantity and quantity > 0 then
            local productId = data.productId
            local price = data.price

            -- Add the product and quantity to the basket
            productBasket[productId] = (productBasket[productId] or 0) + quantity
            TriggerEvent('QBCore:Notify', 'Added ' .. quantity .. ' units of ' .. Nmsh['Products'][productId].name .. ' to the basket.', 'success')
        else
            TriggerEvent('QBCore:Notify', 'Invalid quantity entered.', 'error')
        end
    end
end)

RegisterNetEvent('nmsh-supermarkets:reviewBasket', function()
    -- Call the server-side function to get the player's shop ID
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
                icon = 'fas fa-shopping-basket' -- Basket icon from Font Awesome
            },
        }

        -- Calculate total price and add items to the review menu
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
                icon = 'fas fa-box' -- Product icon from Font Awesome
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
                    shopId = shopId -- Pass the shopId obtained from the callback
                }
            },
            icon = 'fas fa-check-circle' -- Confirm icon from Font Awesome
        })

        -- Add a return option to go back to the product selection menu
        table.insert(basketMenu, {
            id = #basketMenu + 1,
            header = 'Return',
            txt = 'Go back to product selection.',
            params = {
                event = 'nmsh-supermarkets:openProductMenu' -- Calls the event to open the product menu
            },
            icon = 'fas fa-arrow-left' -- Return icon from Font Awesome
        })

        -- Add a close option at the end of the menu
        table.insert(basketMenu, {
            id = #basketMenu + 1,
            header = 'Close',
            params = {
                event = s.menu .. 'client:closeMenu'
            },
            icon = 'fas fa-times-circle' -- Close icon from Font Awesome
        })

        exports[s.menu]:openMenu(basketMenu)
    end)
end)



local vehicle_name = nil
RegisterNetEvent('nmsh-supermarkets:spawnTruckForDelivery', function(data)
    local vehicleModel = 'bison' -- Replace with the desired truck model
    local basket = data.basket
    local shopId = data.shopId
    local boxModel = 'prop_paper_box_01' -- Box model
    local playerPed = PlayerPedId()
    local supermarketCoords = Nmsh['Supermarkets'][shopId].coords
    local truckCoords = Nmsh['Supermarkets'][shopId].truck
    --ocal vehicleHash = GetHashKey(vehicleModel)
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

    -- If using a vehicle keys script, give keys to the player:
    -- TriggerServerEvent('vehiclekeys:server:SetVehicleOwner', GetVehicleNumberPlateText(vehicle))

    -- Generate a random collection location
    local collectionLocation = Nmsh['locations'][math.random(1, #Nmsh['locations'])]

    -- Create a blip for the collection location
    local collectionBlip = AddBlipForCoord(collectionLocation.x, collectionLocation.y, collectionLocation.z)
    SetBlipSprite(collectionBlip, 1)
    SetBlipColour(collectionBlip, 3)
    SetBlipRoute(collectionBlip, true)
    SetBlipRouteColour(collectionBlip, 3)

    -- Create a thread to monitor when the player reaches the collection point
    CreateThread(function()
        local hasCollected = false
        while not hasCollected do
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - collectionLocation)

            if distance < 10.0 then
                -- Remove the blip and show progress bar for collection
                RemoveBlip(collectionBlip)
                TriggerEvent('QBCore:Notify', 'Collecting products. Please wait...', 'primary')
                
                -- Show progress bar for 10 seconds
                exports[s.progressbar]:Progress({
                    name = 'collecting_products',
                    duration = s.progressbarTime, -- 10 seconds
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
                       -- DeleteEntity(boxEntity)
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

-- Event to add items to the basket
RegisterNetEvent('nmsh-supermarkets:addToPlayerBasket', function(data)
    local productId = data.productId
    local price = data.price
    local shopId = data.shopId

    -- Check if shopId exists
    if not shopId then
        TriggerEvent('QBCore:Notify', 'Shop ID is missing.', 'error')
        return
    end

    -- Trigger server callback to get the stock of the selected product
    QBCore.Functions.TriggerCallback('nmsh-supermarkets:getProductStock', function(stock)
        if stock > 0 then
            -- Prompt the player to input the quantity they want to purchase
            local input = exports[s.input]:ShowInput({
                header = "Enter Quantity",
                submitText = "Add to Basket",
                inputs = {
                    {
                        text = "Quantity", -- Text above the input
                        name = "quantity", -- Form field name
                        type = "number", -- Input type
                        isRequired = true, -- Make the input required
                    }
                }
            })

            if input then
                local quantity = tonumber(input.quantity)
                if quantity and quantity > 0 then
                    -- Check if the requested quantity is available in stock
                    if stock >= quantity then
                        -- Add the product to the basket with the chosen quantity
                        if playerBasket[productId] then
                            -- Check if the item already exists in the basket
                            playerBasket[productId] = playerBasket[productId] + quantity
                        else
                            -- Add new item to the basket
                            playerBasket[productId] = quantity
                        end

                        -- Notify the player and reopen the seller menu for more purchases
                        TriggerEvent('QBCore:Notify', Nmsh['Products'][productId].name .. ' x' .. quantity .. ' added to basket.', 'success')

                        -- Reopen the seller menu
                        TriggerEvent('nmsh-supermarkets:openSellerMenu', shopId)
                    else
                        -- Notify the player that there is not enough stock
                        TriggerEvent('QBCore:Notify', 'Not enough stock for ' .. Nmsh['Products'][productId].name .. '. Available: ' .. stock, 'error')
                    end
                else
                    TriggerEvent('QBCore:Notify', 'Invalid quantity. Please try again.', 'error')
                end
            end
        else
            -- Notify the player that there is no stock
            TriggerEvent('QBCore:Notify', 'No stock available for this product.', 'error')
        end
    end, shopId, productId) -- Pass the shopId and productId to the server callback
end)





RegisterNetEvent('nmsh-supermarkets:confirmPurchase', function(data)
    -- Check if the player's basket is empty
    if next(playerBasket) == nil then -- `next()` returns nil if the table is empty
        -- Notify the player that the basket is empty
        TriggerEvent('QBCore:Notify', 'Your basket is empty. You cannot proceed with the purchase.', 'error')
        return -- Exit the function to prevent the purchase from proceeding
    end

    -- At this point, the basket is not empty, so we can proceed with the purchase logic

    local totalPrice = 0

    -- Calculate the total price of items in the basket
    for productId, quantity in pairs(playerBasket) do
        local productData = Nmsh['Products'][productId]
        if productData then
            totalPrice = totalPrice + (productData.price * quantity)
        end
    end

    -- Open a payment menu (bank or cash) and handle the payment logic
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
                    basket = playerBasket -- Pass the basket here
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
                    basket = playerBasket -- Pass the basket here
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

    -- Open the payment menu
    exports[s.menu]:openMenu(paymentMenu)
end)


RegisterNetEvent('nmsh-supermarkets:processPayment', function(data)
    local paymentType = data.paymentType
    local totalPrice = data.totalPrice
    local basket = data.basket
    local shopId = data.shopId

    -- Debugging: print the data being sent to the server
    print("Processing payment:")
    print("Payment type:", paymentType)
    print("Total price:", totalPrice)
    print("Basket:", json.encode(basket))
    print("Shop ID:", shopId)

    -- Trigger the server event to process the purchase
    TriggerServerEvent('nmsh-supermarkets:processPurchase', totalPrice, paymentType, basket, shopId)

    -- Clear the player's basket after the purchase is processed
    playerBasket = {}

    -- Notify the player that the basket has been cleared
    TriggerEvent('QBCore:Notify', 'Your purchase is complete and your basket has been cleared.', 'success')
end)




RegisterNetEvent('nmsh-supermarkets:openSellerMenu', function(shopId)
    -- Trigger a callback to get the products for this shop
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

        -- Loop through products in the shop and add them to the menu
        for productId, productInfo in pairs(products) do
            local productData = Nmsh['Products'][productId] -- Get the product information from the product list

            if productData then
                -- Access stock and price correctly
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
                            shopId = shopId -- Pass shopId here
                        }
                    },
                })
            end
        end

        -- Confirm purchase button
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

        -- Add a close option
        table.insert(sellerMenu, {
            id = #sellerMenu + 1,
            header = 'Close',
            params = {
                event = s.menu .. ':client:closeMenu'
            },
            icon = 'fas fa-times-circle'
        })

        -- Open the menu
        exports[s.menu]:openMenu(sellerMenu)
    end, shopId)
end)

RegisterNetEvent('nmsh-supermarkets:openSellerMenu', function(shopId)
    -- Trigger a callback to get the products for this shop
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

        -- Loop through products in the shop and add them to the menu
        for productId, productInfo in pairs(products) do
            local productData = Nmsh['Products'][productId] -- Get the product information from the product list

            if productData then
                -- Access stock and price correctly
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
                            shopId = shopId -- Pass shopId here
                        }
                    },
                })
            end
        end

        -- Confirm purchase button
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

        -- Add a close option
        table.insert(sellerMenu, {
            id = #sellerMenu + 1,
            header = 'Close',
            params = {
                event = s.menu .. ':client:closeMenu'
            },
            icon = 'fas fa-times-circle'
        })

        -- Open the menu
        exports[s.menu]:openMenu(sellerMenu)
    end, shopId)
end)



RegisterNetEvent('nmsh-supermarkets:makePayment', function(data)
    local paymentType = data.paymentType
    local totalPrice = data.totalPrice
    local shopId = data.shopId

    -- Trigger the server-side event to process the purchase
    TriggerServerEvent('nmsh-supermarkets:processPurchase', totalPrice, paymentType, playerBasket, shopId)

    -- Clear the player's basket after purchase
    playerBasket = {}
end)


RegisterNetEvent('nmsh-supermarkets:showInvoice', function(totalPrice)
    -- Display an invoice UI after successful payment
    -- For this, you can use any notification system or custom UI
    TriggerEvent('QBCore:Notify', 'Purchase successful! Total: $' .. totalPrice, 'success')

    -- Clear the basket
    playerBasket = {}
end)