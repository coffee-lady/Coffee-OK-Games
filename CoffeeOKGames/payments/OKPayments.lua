--- @type OKGamesSDK
local OKGames = require('OKGames.okgames')
local Nakama = require('CoffeeOKGames.nakama.nakama')

local OKPayments = {}

function OKPayments.init()
end

-- return success, error
function OKPayments.purchase_async(id, title, price)
    local result =
        OKGames:show_payments_async(
        {
            name = title,
            description = '',
            code = id,
            price = price
        }
    )

    return result.status
end

function OKPayments.sync_wallet_events_async(wallet)
    return Nakama:sync_wallet_events(
        {
            wallet_items = wallet
        }
    )
end

function OKPayments.get_wallet_async()
    local wallet = Nakama:get_user_wallet_async()

    return wallet
end

function OKPayments._process_purchases(purchases)
    local result = {}

    for i = 1, #purchases do
        local data = purchases[i]

        result[i] = {
            product_id = data.productID,
            token = data.purchaseToken,
            payload = data.developerPayload,
            signature = data.signature
        }
    end

    return result
end

function OKPayments.get_catalog_async()
    local data = Nakama:get_catalog_async()

    if not data then
        return {}
    end

    local catalog = OKPayments._process_catalog(data.bundles)
    return catalog
end

function OKPayments._process_catalog(catalog)
    local result = {}

    for i = 1, #catalog do
        local data = catalog[i]
        local items = {}

        for _, item in pairs(data.items) do
            items[item.key] = item.amount
        end

        result[i] = {
            id = data.id,
            type = data.sales_type,
            price = tonumber(data.price),
            items = items
        }
    end

    return result
end

return OKPayments
