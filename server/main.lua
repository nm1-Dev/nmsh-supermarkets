local s = Nmsh['Settings']
local QBCore = exports[s.core]:GetCoreObject()

RegisterNetEvent('nmsh-supermarkets:buyShop', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local shop = data.shop
    local price = data.price

    if Player and Nmsh['Supermarkets'][shop] then
        local playerMoney = Player.Functions.GetMoney(Nmsh['Seller-NPC'].buyShopMethod)
        local citizenid = Player.PlayerData.citizenid

        MySQL.scalar('SELECT COUNT(*) FROM player_shops WHERE owner_identifier = ?', { citizenid }, function(ownedShops)
            if ownedShops > 0 then

                TriggerClientEvent('QBCore:Notify', src, 'You already own a shop and cannot buy another one.', 'error')
            else

                MySQL.scalar('SELECT owner_identifier FROM player_shops WHERE shop_id = ?', { shop }, function(owner)
                    if owner then

                        TriggerClientEvent('QBCore:Notify', src, 'This shop is already owned by someone else.', 'error')
                    else

                        if playerMoney >= price then

                            Player.Functions.RemoveMoney(Nmsh['Seller-NPC'].buyShopMethod, price)

                            local shopName = Nmsh['Supermarkets'][shop].name

                            local defaultProducts = {}
                            for productId, productData in pairs(Nmsh['Products']) do
                                defaultProducts[productId] = { stock = 0, price = productData.price } 
                            end

                            MySQL.insert('INSERT INTO player_shops (shop_id, owner_identifier, shop_name, purchase_price, products) VALUES (?, ?, ?, ?, ?)', {
                                shop, citizenid, shopName, price, json.encode(defaultProducts)
                            }, function(insertId)
                                if insertId then

                                    TriggerClientEvent('QBCore:Notify', src, 'You have successfully purchased ' .. shopName .. ' for $' .. price, 'success')
                                else

                                    TriggerClientEvent('QBCore:Notify', src, 'An error occurred while trying to purchase the shop. Please try again.', 'error')
                                end
                            end)
                        else

                            TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to buy this shop!', 'error')
                        end
                    end
                end)
            end
        end)
    else

        TriggerClientEvent('QBCore:Notify', src, 'An error occurred while trying to purchase the shop. Please try again.', 'error')
    end
end)

QBCore.Functions.CreateCallback('nmsh-supermarkets:getProductStock', function(source, cb, shopId, productId)
    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products)
            if products and products[productId] then
                cb(products[productId]) 
            else
                cb(0) 
            end
        else
            cb(0) 
        end
    end)
end)

QBCore.Functions.CreateCallback('nmsh-supermarkets:isShopOwner', function(source, cb, shopId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenId = Player.PlayerData.citizenid

    MySQL.query('SELECT owner_identifier FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] and result[1].owner_identifier == citizenId then
            cb(true) 
        else
            cb(false) 
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

                local totalPrice = price * quantity

                if Player.Functions.RemoveMoney('cash', totalPrice) then

                    products[productId] = (products[productId] or 0) + quantity

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

RegisterNetEvent('nmsh-supermarkets:withdrawMoney', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    print(json.encode(data))
    local shopId = data.shopId

    if Player then
        local citizenid = Player.PlayerData.citizenid

        MySQL.query('SELECT owner_identifier, balance FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] then
                if result[1].owner_identifier == citizenid then
                    local balance = tonumber(result[1].balance) 

                    if balance > 0 then

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

RegisterNetEvent('nmsh-supermarkets:showBalance', function(data)
    local src = source
    local shopId = data.shopId
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then

        MySQL.Async.fetchScalar('SELECT balance FROM player_shops WHERE shop_id = @shop_id', {
            ['@shop_id'] = shopId
        }, function(balance)
            if balance then

                TriggerClientEvent('QBCore:Notify', src, 'Current shop balance: $' .. balance, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Could not retrieve shop balance.', 'error')
            end
        end)
    end
end)

QBCore.Functions.CreateCallback('nmsh-supermarkets:getProductStock', function(source, cb, shopId, productId)

    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products)
            print('Products found in shop:', json.encode(products)) 
            print('Requested product:', productId) 

            if products[productId] then
                print('Stock for product:', productId, '=', products[productId]) 
                cb(products[productId]) 
            else
                print('No stock found for product:', productId) 
                cb(0) 
            end
        else
            print('No result found for shop:', shopId) 
            cb(0) 
        end
    end)
end)

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

                products[productName] = stock - 1
                local newBalance = result[1].balance + price

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

        if Player.Functions.RemoveMoney('cash', totalPrice) then

            TriggerClientEvent('QBCore:Notify', src, 'Purchase completed. Your delivery truck is ready.', 'success')

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

        MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] then
                local products = json.decode(result[1].products or '{}')

                for productId, quantity in pairs(basket) do
                    if products[productId] then

                        products[productId].stock = (products[productId].stock or 0) + quantity
                    else

                        products[productId] = {
                            stock = quantity,
                            price = Nmsh['Products'][productId].price 
                        }
                    end
                end

                MySQL.update('UPDATE player_shops SET products = ? WHERE shop_id = ?', {
                    json.encode(products), shopId
                })

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

        MySQL.query('SELECT shop_id FROM player_shops WHERE owner_identifier = ?', { citizenid }, function(result)
            if result[1] then
                local shopId = result[1].shop_id
                cb(shopId)
            else
                cb(nil) 
            end
        end)
    else
        cb(nil) 
    end
end)

QBCore.Functions.CreateCallback('nmsh-supermarkets:getShopProducts', function(source, cb, shopId)

    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products) 
            cb(products) 
        else
            cb(nil) 
        end
    end)
end)

QBCore.Functions.CreateCallback('nmsh-supermarkets:getProductStock', function(source, cb, shopId, productId)
    MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', {shopId}, function(result)
        if result[1] then
            local products = json.decode(result[1].products) 

            if products[productId] then

                cb(products[productId].stock or 0)
            else

                cb(0)
            end
        else

            cb(0)
        end
    end)
end)

RegisterNetEvent('nmsh-supermarkets:processPurchase', function(totalPrice, paymentType, basket, shopId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    MySQL.query('SELECT products, balance FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local products = json.decode(result[1].products) 
            local shopBalance = result[1].balance or 0 
            local canCarryAll = true 

            for productId, quantity in pairs(basket) do
                if not CanPlayerCarryItem(Player, productId, quantity) then
                    canCarryAll = false
                    TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough room for ' .. Nmsh['Products'][productId].name .. '.', 'error')
                    break 
                end
            end

            if canCarryAll then
                local paymentSuccess = false

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

                    for productId, quantity in pairs(basket) do

                        local productStock = products[productId].stock

                        if productStock and productStock >= quantity then

                            Player.Functions.AddItem(productId, quantity)

                            products[productId].stock = productStock - quantity
                        else
                            TriggerClientEvent('QBCore:Notify', src, 'Not enough stock for ' .. Nmsh['Products'][productId].name, 'error')
                        end
                    end

                    local newBalance = shopBalance + totalPrice 
                    MySQL.update('UPDATE player_shops SET products = ?, balance = ? WHERE shop_id = ?', {
                        json.encode(products), 
                        newBalance,
                        shopId
                    })

                    TriggerEvent('nmsh-supermarkets:notifyOwner', shopId, totalPrice, newBalance)

                    playerBasket = {}
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Shop not found.', 'error')
        end
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    MySQL.query('SELECT shop_id, products FROM player_shops', {}, function(shops)
        if shops then

            for _, shop in pairs(shops) do
                local shopId = shop.shop_id
                local shopProducts = json.decode(shop.products) or {}

                local needsUpdate = false

                for productId, productData in pairs(Nmsh['Products']) do
                    if shopProducts[productId] then

                        shopProducts[productId].price = shopProducts[productId].price or productData.price
                    else

                        shopProducts[productId] = { stock = 0, price = productData.price }
                        needsUpdate = true
                        print('Added missing product: ' .. productId .. ' to shop: ' .. shopId)
                    end
                end

                if needsUpdate then
                    MySQL.update('UPDATE player_shops SET products = ? WHERE shop_id = ?', { json.encode(shopProducts), shopId })
                    print('Shop ' .. shopId .. ' updated with missing products.')
                end
            end
        end
    end)
end)

RegisterNetEvent('nmsh-supermarkets:notifyOwner', function(shopId, amountEarned, newBalance)

    MySQL.query('SELECT owner_identifier FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
        if result[1] then
            local ownerIdentifier = result[1].owner

            for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
                local Player = QBCore.Functions.GetPlayer(playerId)
                if Player and Player.PlayerData.citizenid == ownerIdentifier then

                    TriggerClientEvent('QBCore:Notify', playerId, 'Your shop earned $' .. amountEarned .. '. New balance: $' .. newBalance, 'success')
                    break
                end
            end
        end
    end)
end)

function GetPlayerCurrentInventoryWeight(player)
    local currentWeight = 0
    local inventory = player.PlayerData.items

    for _, item in pairs(inventory) do
        if item and item.weight and item.amount then
            currentWeight = currentWeight + (item.weight * item.amount)
        end
    end

    print('Current inventory weight: ' .. currentWeight) 

    return currentWeight
end

function CanPlayerCarryItem(player, itemId, quantity)
    local itemWeight = QBCore.Shared.Items[itemId].weight 
    local totalWeight = itemWeight * quantity 
    local currentInventoryWeight = GetPlayerCurrentInventoryWeight(player) 
    local maxInventoryWeight = Nmsh.MaxInventoryWeight 

    print('Item weight: ' .. itemWeight .. ', Quantity: ' .. quantity .. ', Total weight: ' .. totalWeight) 
    print('Current weight: ' .. currentInventoryWeight .. ', Max weight: ' .. maxInventoryWeight) 

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

        MySQL.query('SELECT products FROM player_shops WHERE shop_id = ?', { shopId }, function(result)
            if result[1] then

                local products = json.decode(result[1].products)

                if products[productId] then

                    products[productId].price = newPrice

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
