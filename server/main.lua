local s = Nmsh['Settings']
local QBCore = exports[s.core]:GetCoreObject()

-- Event handler for purchasing a shop
RegisterNetEvent('nmsh-supermarkets:buyShop', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local shop = data.shop
    local price = data.price

    if Player and Nmsh['Supermarkets'][shop] then
        local playerMoney = Player.Functions.GetMoney(Nmsh['Seller-NPC'].buyShopMethod)
        local citizenid = Player.PlayerData.citizenid

        -- Check if the player already owns a shop
        MySQL.scalar('SELECT COUNT(*) FROM player_shops WHERE owner_identifier = ?', { citizenid }, function(ownedShops)
            if ownedShops > 0 then
                -- Player already owns a shop, notify them
                TriggerClientEvent('QBCore:Notify', src, 'You already own a shop and cannot buy another one.', 'error')
            else
                -- Check if the shop is already owned by someone else
                MySQL.scalar('SELECT owner_identifier FROM player_shops WHERE shop_id = ?', { shop }, function(owner)
                    if owner then
                        -- Shop is already owned, notify the player
                        TriggerClientEvent('QBCore:Notify', src, 'This shop is already owned by someone else.', 'error')
                    else
                        -- Shop is not owned, proceed with purchase
                        if playerMoney >= price then
                            -- Deduct the money from the player's account
                            Player.Functions.RemoveMoney(Nmsh['Seller-NPC'].buyShopMethod, price)

                            local shopName = Nmsh['Supermarkets'][shop].name

                            -- Create a default products list with 0 stock
                            local defaultProducts = {}
                            for productId, productData in pairs(Nmsh['Products']) do
                                defaultProducts[productId] = { stock = 0, price = productData.price } -- Set stock to 0 by default
                            end

                            -- Insert the shop ownership data and default products into the database
                            MySQL.insert('INSERT INTO player_shops (shop_id, owner_identifier, shop_name, purchase_price, products) VALUES (?, ?, ?, ?, ?)', {
                                shop, citizenid, shopName, price, json.encode(defaultProducts)
                            }, function(insertId)
                                if insertId then
                                    -- Notify the player of successful purchase
                                    TriggerClientEvent('QBCore:Notify', src, 'You have successfully purchased ' .. shopName .. ' for $' .. price, 'success')
                                else
                                    -- If the insert failed, notify the player
                                    TriggerClientEvent('QBCore:Notify', src, 'An error occurred while trying to purchase the shop. Please try again.', 'error')
                                end
                            end)
                        else
                            -- Player doesn't have enough money
                            TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to buy this shop!', 'error')
                        end
                    end
                end)
            end
        end)
    else
        -- Shop not found or player doesn't exist
        TriggerClientEvent('QBCore:Notify', src, 'An error occurred while trying to purchase the shop. Please try again.', 'error')
    end
end)


QBCore.Functions.CreateCallback('nmsh-supermarkets:getProductStock', function(source, cb, shopId, productId)
    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products)
            if products and products[productId] then
                cb(products[productId]) -- Return the stock of the product
            else
                cb(0) -- If product doesn't exist in stock, return 0
            end
        else
            cb(0) -- No shop found or no products found
        end
    end)
end)


QBCore.Functions.CreateCallback('nmsh-supermarkets:isShopOwner', function(source, cb, shopId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenId = Player.PlayerData.citizenid

    -- Query the database to check if the player is the owner of the shop
    MySQL.query('SELECT owner_identifier FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] and result[1].owner_identifier == citizenId then
            cb(true) -- Player is the owner
        else
            cb(false) -- Player is not the owner
        end
    end)
end)


RegisterNetEvent('nmsh-supermarkets:orderProduct', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local shopId = data.shopId
    local productId = data.productId
    local price = data.price
    local quantity = data.quantity

    if Player then
        local citizenid = Player.PlayerData.citizenid

        MySQL.query('SELECT owner_identifier, products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] and result[1].owner_identifier == citizenid then
                local products = json.decode(result[1].products or '{}')

                -- Calculate the total cost of the order
                local totalPrice = price * quantity

                -- Check if the player has enough money
                if Player.Functions.RemoveMoney('cash', totalPrice) then
                    -- Update product stock
                    products[productId] = (products[productId] or 0) + quantity

                    -- Update the products in the database
                    MySQL.update('UPDATE player_shops SET products = ? WHERE shop_id = ?', {
                        json.encode(products), shopId
                    })

                    TriggerClientEvent('QBCore:Notify', src, 'You have ordered ' .. quantity .. ' units of ' .. Nmsh['Products'][productId].name .. ' for $' .. totalPrice, 'success')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to place this order.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'You are not the owner of this shop.', 'error')
            end
        end)
    end
end)


-- Event to handle withdrawing money from the shop balance
RegisterNetEvent('nmsh-supermarkets:withdrawMoney', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    print(json.encode(data))
    local shopId = data.shopId

    if Player then
        local citizenid = Player.PlayerData.citizenid

        -- Fetch the shop owner and balance from the database
        MySQL.query('SELECT owner_identifier, balance FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] then
                if result[1].owner_identifier == citizenid then
                    local balance = tonumber(result[1].balance) -- Convert balance to a number

                    if balance > 0 then
                        -- Withdraw the balance and update the database
                        Player.Functions.AddMoney('cash', balance)
                        MySQL.update('UPDATE player_shops SET balance = 0 WHERE shop_id = ?', { shopId })
                        TriggerClientEvent('QBCore:Notify', src, 'You have withdrawn $' .. balance .. ' from your shop.', 'success')
                    else
                        TriggerClientEvent('QBCore:Notify', src, 'Your shop has no balance to withdraw.', 'error')
                    end
                else
                    TriggerClientEvent('QBCore:Notify', src, 'You are not the owner of this shop.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Shop not found.', 'error')
            end
        end)
    end
end)



-- Event to check stock levels
RegisterNetEvent('nmsh-supermarkets:checkStock', function(data)
    local src = source
    local shopId = data.shopId

    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products or '{}')
            TriggerClientEvent('nmsh-supermarkets:showStockMenu', src, products)
        else
            TriggerClientEvent('QBCore:Notify', src, 'No stock data found for this shop.', 'error')
        end
    end)
end)

-- Server-side: Show balance event
RegisterNetEvent('nmsh-supermarkets:showBalance', function(data)
    local src = source
    local shopId = data.shopId
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        -- Fetch the balance of the shop from your table
        MySQL.Async.fetchScalar('SELECT balance FROM player_shops WHERE shop_id = @shop_id', {
            ['@shop_id'] = shopId
        }, function(balance)
            if balance then
                -- Send the balance to the player
                TriggerClientEvent('QBCore:Notify', src, 'Current shop balance: $' .. balance, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Could not retrieve shop balance.', 'error')
            end
        end)
    end
end)


QBCore.Functions.CreateCallback('nmsh-supermarkets:getProductStock', function(source, cb, shopId, productId)
    -- Query the database for the current stock
    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products)
            print('Products found in shop:', json.encode(products)) -- Debug: Show all products in the shop
            print('Requested product:', productId) -- Debug: Show requested product ID

            if products[productId] then
                print('Stock for product:', productId, '=', products[productId]) -- Debug: Show the stock value
                cb(products[productId]) -- Return the stock if the product exists
            else
                print('No stock found for product:', productId) -- Debug: Show error if product not found
                cb(0) -- Return 0 if no stock is found for the product
            end
        else
            print('No result found for shop:', shopId) -- Debug: Show error if shop not found
            cb(0) -- Return 0 if no result found
        end
    end)
end)



-- Event to handle product sales
RegisterNetEvent('nmsh-supermarkets:sellProduct', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local shopId = data.shopId
    local productName = data.productName
    local price = data.price

    MySQL.query('SELECT products, balance FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products or '{}')
            local stock = products[productName] or 0

            if stock > 0 then
                -- Decrease stock and increase shop balance
                products[productName] = stock - 1
                local newBalance = result[1].balance + price

                -- Update products and balance in the database
                MySQL.update('UPDATE player_shops SET products = ?, balance = ? WHERE shop_id = ?', {
                    json.encode(products), newBalance, shopId
                })

                TriggerClientEvent('QBCore:Notify', src, 'You have purchased ' .. productName .. ' for $' .. price, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'This product is out of stock.', 'error')
            end
        end
    end)
end)


RegisterNetEvent('nmsh-supermarkets:finalizePurchase', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local totalPrice = data.totalPrice
    local basket = data.basket
    local shopId = data.shopId

    if Player then
        -- Check if the player has enough money and deduct it
        if Player.Functions.RemoveMoney('cash', totalPrice) then
            -- Notify the player of the successful purchase
            TriggerClientEvent('QBCore:Notify', src, 'Purchase completed. Your delivery truck is ready.', 'success')

            -- Trigger the client-side event to spawn the truck and start the delivery process
            TriggerClientEvent('nmsh-supermarkets:spawnTruckForDelivery', src, {
                basket = basket,
                shopId = shopId
            })
        else
            TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to complete the purchase.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to process the purchase. Please try again.', 'error')
    end
end)

RegisterNetEvent('nmsh-supermarkets:transferItemsToStore', function(shopId, vehiclePlate, basket)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        -- Get the supermarket's current stock from the database
        MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] then
                local products = json.decode(result[1].products or '{}')

                -- Add each item from the basket to the supermarket's stock
                for productId, quantity in pairs(basket) do
                    if products[productId] then
                        -- If the product already exists, increase its stock
                        products[productId].stock = (products[productId].stock or 0) + quantity
                    else
                        -- If the product doesn't exist, create a new entry with 0 stock and the default price
                        products[productId] = {
                            stock = quantity,
                            price = Nmsh['Products'][productId].price -- Assign the default price from Nmsh['Products']
                        }
                    end
                end

                -- Update the store's inventory in the database
                MySQL.update('UPDATE player_shops SET products = ? WHERE shop_id = ?', {
                    json.encode(products), shopId
                })

                -- Notify the player of the successful delivery
                TriggerClientEvent('QBCore:Notify', src, 'Items have been successfully stocked in your market.', 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Failed to find the store. Please try again.', 'error')
            end
        end)
    end
end)




QBCore.Functions.CreateCallback('nmsh-supermarkets:getPlayerShopId', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        -- Query the database for the player's shop
        MySQL.query('SELECT shop_id FROM player_shops WHERE owner_identifier = ?', { citizenid }, function(result)
            if result[1] then
                local shopId = result[1].shop_id
                cb(shopId)
            else
                cb(nil) -- No shop found for the player
            end
        end)
    else
        cb(nil) -- Player not found
    end
end)


QBCore.Functions.CreateCallback('nmsh-supermarkets:getShopProducts', function(source, cb, shopId)
    -- Query the database to get the products for this shop
    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products) -- Decode the JSON string to a Lua table
            cb(products) -- Send the products back to the client
        else
            cb(nil) -- No products found for this shop
        end
    end)
end)

QBCore.Functions.CreateCallback('nmsh-supermarkets:getProductStock', function(source, cb, shopId, productId)
    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', {shopId}, function(result)
        if result[1] then
            local products = json.decode(result[1].products) -- Decode the JSON products

            if products[productId] then
                -- Return the stock value for the requested product
                cb(products[productId].stock or 0)
            else
                -- Product not found, return 0 stock
                cb(0)
            end
        else
            -- Shop not found, return 0 stock
            cb(0)
        end
    end)
end)



RegisterNetEvent('nmsh-supermarkets:processPurchase', function(totalPrice, paymentType, basket, shopId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    -- Fetch the current shop stock and balance from the database
    MySQL.query('SELECT products, balance FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products) -- Decode the product JSON from the database
            local shopBalance = result[1].balance or 0 -- Get current shop balance
            local canCarryAll = true -- Check if player can carry all items

            -- Loop through the basket to check if the player has enough inventory weight for all items
            for productId, quantity in pairs(basket) do
                if not CanPlayerCarryItem(Player, productId, quantity) then
                    canCarryAll = false
                    TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough room for ' .. Nmsh['Products'][productId].name .. '.', 'error')
                    break -- Stop the loop if the player can't carry the items
                end
            end

            -- If player can carry all items, proceed with the purchase
            if canCarryAll then
                local paymentSuccess = false

                -- Check if player has enough money and proceed with the transaction
                if paymentType == 'cash' and Player.Functions.RemoveMoney('cash', totalPrice) then
                    paymentSuccess = true
                    TriggerClientEvent('QBCore:Notify', src, 'Purchase successful! Items have been added to your inventory.', 'success')
                elseif paymentType == 'bank' and Player.Functions.RemoveMoney('bank', totalPrice) then
                    paymentSuccess = true
                    TriggerClientEvent('QBCore:Notify', src, 'Purchase successful! Items have been added to your inventory.', 'success')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money!', 'error')
                end

                if paymentSuccess then
                    -- Loop through the basket and give the items to the player, update stock
                    for productId, quantity in pairs(basket) do
                        -- Access stock from the product table correctly
                        local productStock = products[productId].stock
                        
                        if productStock and productStock >= quantity then
                            -- Add the item to the player's inventory
                            Player.Functions.AddItem(productId, quantity)
                            
                            -- Deduct only the purchased quantity from the shop's stock
                            products[productId].stock = productStock - quantity
                        else
                            TriggerClientEvent('QBCore:Notify', src, 'Not enough stock for ' .. Nmsh['Products'][productId].name, 'error')
                        end
                    end

                    -- Update the shop's stock and balance in the database
                    local newBalance = shopBalance + totalPrice -- Add the total price to the shop's balance
                    MySQL.update('UPDATE player_shops SET products = ?, balance = ? WHERE shop_id = ?', {
                        json.encode(products), -- Update the entire products table, keeping products with 0 stock intact
                        newBalance,
                        shopId
                    })

                    -- Notify the shop owner (if they are online) about the new balance
                    TriggerEvent('nmsh-supermarkets:notifyOwner', shopId, totalPrice, newBalance)

                    -- Reset the player's basket after purchase
                    playerBasket = {}
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Shop not found.', 'error')
        end
    end)
end)


-- Ensure all shops have all products in the Nmsh['Products'] list on script start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    -- Fetch all shops from the database
    MySQL.query('SELECT shop_id, products FROM player_shops', {}, function(shops)
        if shops then
            -- Loop through each shop
            for _, shop in pairs(shops) do
                local shopId = shop.shop_id
                local shopProducts = json.decode(shop.products) or {}

                -- Track if we need to update the products
                local needsUpdate = false

                -- Loop through all products in Nmsh['Products']
                for productId, productData in pairs(Nmsh['Products']) do
                    if shopProducts[productId] then
                        -- Product exists in the shop, preserve its price and stock
                        shopProducts[productId].price = shopProducts[productId].price or productData.price
                    else
                        -- Product missing from the shop, add it with 0 stock and the price from Nmsh['Products']
                        shopProducts[productId] = { stock = 0, price = productData.price }
                        needsUpdate = true
                        print('Added missing product: ' .. productId .. ' to shop: ' .. shopId)
                    end
                end

                -- If products were added, update the database
                if needsUpdate then
                    MySQL.update('UPDATE player_shops SET products = ? WHERE shop_id = ?', { json.encode(shopProducts), shopId })
                    print('Shop ' .. shopId .. ' updated with missing products.')
                end
            end
        end
    end)
end)



RegisterNetEvent('nmsh-supermarkets:notifyOwner', function(shopId, amountEarned, newBalance)
    -- Fetch the owner of the shop from the database (assuming there's a column for owner)
    MySQL.query('SELECT owner_identifier FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local ownerIdentifier = result[1].owner

            -- Check if the shop owner is online
            for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
                local Player = QBCore.Functions.GetPlayer(playerId)
                if Player and Player.PlayerData.citizenid == ownerIdentifier then
                    -- Notify the owner about the money earned and the new balance
                    TriggerClientEvent('QBCore:Notify', playerId, 'Your shop earned $' .. amountEarned .. '. New balance: $' .. newBalance, 'success')
                    break
                end
            end
        end
    end)
end)


-- Function to calculate the player's current inventory weight
function GetPlayerCurrentInventoryWeight(player)
    local currentWeight = 0
    local inventory = player.PlayerData.items

    -- Loop through each item in the player's inventory
    for _, item in pairs(inventory) do
        if item and item.weight and item.amount then
            currentWeight = currentWeight + (item.weight * item.amount)
        end
    end

    print('Current inventory weight: ' .. currentWeight) -- Debug print

    return currentWeight
end

-- Function to check if the player can carry the given item and quantity
function CanPlayerCarryItem(player, itemId, quantity)
    local itemWeight = QBCore.Shared.Items[itemId].weight -- Get the weight of the item
    local totalWeight = itemWeight * quantity -- Calculate total weight for the quantity
    local currentInventoryWeight = GetPlayerCurrentInventoryWeight(player) -- Calculate the player's current inventory weight
    local maxInventoryWeight = Nmsh.MaxInventoryWeight -- Define the player's max inventory weight (adjust this)

    print('Item weight: ' .. itemWeight .. ', Quantity: ' .. quantity .. ', Total weight: ' .. totalWeight) -- Debug print
    print('Current weight: ' .. currentInventoryWeight .. ', Max weight: ' .. maxInventoryWeight) -- Debug print

    -- Check if the player can carry the total weight
    if (currentInventoryWeight + totalWeight) <= maxInventoryWeight then
        return true
    else
        return false
    end
end

RegisterNetEvent('nmsh-supermarkets:updateProductPrice', function(shopId, productId, newPrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    print('Updating product price:', shopId, productId, newPrice)
    if Player then
        -- Fetch the current products from the database
        MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] then
                -- Parse the products JSON
                local products = json.decode(result[1].products)

                if products[productId] then
                    -- Update the price for the selected product
                    products[productId].price = newPrice

                    -- Save the updated products back into the database
                    MySQL.update('UPDATE player_shops SET products = ? WHERE shop_id = ?', { json.encode(products), shopId }, function(affectedRows)
                        if affectedRows > 0 then
                            TriggerClientEvent('QBCore:Notify', src, 'Product price updated to $' .. newPrice, 'success')
                        else
                            TriggerClientEvent('QBCore:Notify', src, 'Failed to update product price.', 'error')
                        end
                    end)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Product not found.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Shop not found.', 'error')
            end
        end)
    end
end)
