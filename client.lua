local QBCore = exports['qb-core']:GetCoreObject()

function GetNearbyPlayers()
    local players = {}
    local coords = GetEntityCoords(PlayerPedId())
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= PlayerPedId() then
            local dist = #(coords - GetEntityCoords(ped))
            if dist <= 5.0 then
                local serverId = GetPlayerServerId(playerId)
                table.insert(players, { label = ("[%s] %s"):format(serverId, GetPlayerName(playerId)), value = serverId })
            end
        end
    end
    return players
end

function ProcessPayment(targetId, method, amount)
    TriggerServerEvent('qb-payment:server:RequestPayment', targetId, method, amount)
end

RegisterNetEvent('qb-payment:client:ShowPaymentRequest', function(fromId, amount, method)
    -- تحويل طريقة الدفع إلى نص عربي
    local methodLabel = method == "cash" and "نقداً" or "تحويل بنكي"
    
    -- الحصول على اسم اللاعب المرسل بناءً على serverId
    local senderName = GetPlayerName(GetPlayerFromServerId(fromId)) or ("[%s]"):format(fromId)

    -- تسجيل واجهة Context باستخدام ox_lib
    lib.registerContext({
        id = 'payment_request_context',
        title = 'طلب دفع',
        options = {
            {
                -- عرض اسم المرسل
                title = 'المرسل',
                description = senderName,
                icon = 'user'
            },
            {
                -- عرض طريقة الدفع (كاش أو بنك)
                title = 'طريقة الدفع',
                description = methodLabel,
                icon = method == "cash" and "money-bill-wave" or "building-columns"
            },
            {
                -- عرض المبلغ المطلوب
                title = 'المبلغ',
                description = "$" .. amount,
                icon = 'dollar-sign'
            },
            {
                -- زر لتأكيد الدفع
                title = '✅ دفع المبلغ',
                icon = 'check',
                onSelect = function()
                    TriggerServerEvent('qb-payment:server:ConfirmPayment', fromId, method, amount)
                    lib.hideContext()
                end
            },
            {
                -- زر لرفض الطلب
                title = '❌ رفض الدفع',
                icon = 'xmark',
                onSelect = function()
                    TriggerServerEvent('qb-payment:server:RejectPayment', fromId)
                    lib.hideContext()
                end
            }
        }
    })

    -- عرض الواجهة للمستخدم المستهدف
    lib.showContext('payment_request_context')
end)


Citizen.CreateThread(function()
    Citizen.Wait(1000)

    for i, point in pairs(Config.PaymentPoints) do
        local success, err = pcall(function()
            exports["interact"]:AddInteraction({
                coords = point.coords,
                distance = Config.ViewDistance,
                interactDst = Config.InteractDistance,
                id = 'payment_system_' .. i,
                name = point.name,
                groups = {
                    [point.job] = point.grade
                },
                options = {
                    {
                        label = point.name,
                        action = function()
                            local nearbyPlayers = GetNearbyPlayers()

                            if #nearbyPlayers == 0 then
                                QBCore.Functions.Notify("لا يوجد لاعبين بالقرب.", "error")
                                return
                            end

                            local playerInput = lib.inputDialog('اختر لاعباً للدفع', {
                                {
                                    type = 'select',
                                    label = 'اللاعب',
                                    options = nearbyPlayers,
                                    required = true
                                },
                                {
                                    type = 'select',
                                    label = 'طريقة الدفع',
                                    options = {
                                        { label = 'نقداً', value = 'cash' },
                                        { label = 'تحويل بنكي', value = 'bank' }
                                    },
                                    required = true
                                },
                                {
                                    type = 'number',
                                    label = 'المبلغ',
                                    min = 1,
                                    required = true
                                }
                            })

                            if playerInput then
                                local targetId = playerInput[1]
                                local paymentMethod = playerInput[2]
                                local amount = playerInput[3]

                                ProcessPayment(targetId, paymentMethod, amount)
                            end
                        end,
                    },
                }
            })
        end)

        if not success then
            print("فشل في تسجيل نقطة التفاعل #" .. i .. ": " .. tostring(err))
        elseif Config.EnableDebug then
            print(("تم تهيئة نقطة دفع #%s عند %s"):format(i, tostring(point.coords)))
        end
    end
end)
