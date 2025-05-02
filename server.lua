local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('qb-payment:server:RequestPayment', function(targetId, method, amount)
    local src = source
    TriggerClientEvent('qb-payment:client:ShowPaymentRequest', targetId, src, amount, method)
end)

RegisterNetEvent('qb-payment:server:RejectPayment', function(fromId)
    TriggerClientEvent('QBCore:Notify', fromId, "تم رفض طلب الدفع.", "error")
end)

RegisterNetEvent('qb-payment:server:ConfirmPayment', function(toId, method, amount)
    local src = source
    local payer = QBCore.Functions.GetPlayer(src)
    local receiver = QBCore.Functions.GetPlayer(toId)

    if not payer or not receiver then return end

    local hasMoney = payer.PlayerData.money[method] >= amount

    if not hasMoney then
        TriggerClientEvent('QBCore:Notify', src, "ليس لديك المبلغ الكافي", "error")
        return
    end

    payer.Functions.RemoveMoney(method, amount, "payment-to-player")
    receiver.Functions.AddMoney(method, amount, "payment-from-player")

    TriggerClientEvent('QBCore:Notify', src, ("تم دفع $%s"):format(amount), "success")
    TriggerClientEvent('QBCore:Notify', toId, ("استلمت $%s من اللاعب"):format(amount), "success")
end)
