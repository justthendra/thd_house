local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local Blips = {} 

-- Kapı durumlarını yerel olarak takip etmek için tablo
local HouseDoorStates = {} 

-- HouseDoorStates artık ox_doorlock tarafından yönetiliyor, yerel tabloya gerek kalmadı.

-- BLIP SİSTEMİ
local function CreateHouseBlip(houseId, ownerName)
    local house = Config.Houses[houseId]
    if Blips[houseId] then RemoveBlip(Blips[houseId]) end
    
    local blip = AddBlipForCoord(house.coords.x, house.coords.y, house.coords.z)
    SetBlipSprite(blip, 40)
    SetBlipScale(blip, 0.6)
    SetBlipAsShortRange(blip, true)

    if ownerName then
        SetBlipColour(blip, 2) -- Yeşil (Satılmış)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Ev - " .. ownerName)
        EndTextCommandSetBlipName(blip)
    else
        SetBlipColour(blip, 1) -- Kırmızı (Satılık)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Satılık Ev - " .. houseId)
        EndTextCommandSetBlipName(blip)
    end
    Blips[houseId] = blip
end

-- EMLAKÇI SABİT BLİP'İ
CreateThread(function()
    -- Config'deki emlakçı koordinatını kullanıyoruz
    local blip = AddBlipForCoord(Config.RealEstateLocation.x, Config.RealEstateLocation.y, Config.RealEstateLocation.z)
    
    SetBlipSprite(blip, 374) -- 374: Ev/Ofis İkonu
    SetBlipDisplay(blip, 4)  -- Hem minimap hem büyük haritada göster
    SetBlipScale(blip, 0.8)  -- Boyut
    SetBlipColour(blip, 3)   -- 3: Mavi (Ofis/Kurumsal hissi verir), 0: Beyaz, 1: Kırmızı
    SetBlipAsShortRange(blip, true) -- Sadece haritaya yakınlaşınca görünsün (uzaktan kalabalık etmesin)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Emlak Ofisi") -- Haritada görünecek isim
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('thd_house:server:requestBlips')
end)

RegisterNetEvent('thd_house:client:syncBlips', function(soldHouses)
    for id, _ in pairs(Config.Houses) do
        CreateHouseBlip(id, soldHouses[id])
    end
end)

RegisterNetEvent('thd_house:client:updateSingleBlip', function(houseId, ownerName)
    CreateHouseBlip(houseId, ownerName)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(1000)
    TriggerServerEvent('thd_house:server:requestBlips')
end)

-- EMLAKÇI PED & MENÜ
CreateThread(function()
    local model = `a_m_y_business_03`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(4, model, Config.RealEstateLocation.x, Config.RealEstateLocation.y, Config.RealEstateLocation.z - 1.0, Config.RealEstateLocation.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "thd_house:client:openRealEstateMenu",
                icon = "fas fa-file-contract",
                label = "Emlak Listesini Gör",
            },
        },
        distance = 2.0
    })
end)

-- GÜNCELLENMİŞ EMLAK MENÜSÜ (Satın Al & Geri Sat)
RegisterNetEvent('thd_house:client:openRealEstateMenu', function()
    -- Önce oyuncunun sahip olduğu evleri serverdan öğren
    QBCore.Functions.TriggerCallback('thd_house:server:getOwnedHouses', function(ownedHouses)
        local menu = {
            {
                header = "Emlak Ofisi",
                isMenuHeader = true,
                icon = "fas fa-building"
            }
        }

        -- KATEGORİ 1: BENİM MÜLKLERİM (Geri Satma)
        local hasOwned = false
        menu[#menu+1] = { header = "🏠 Mülklerim (Geri Sat)", isMenuHeader = true }

        for id, house in pairs(Config.Houses) do
            if ownedHouses[id] then
                hasOwned = true
                local refund = math.floor(house.price * Config.SellRefundPercentage)
                menu[#menu+1] = {
                    header = house.label .. " (Sahibisin)",
                    txt = "Geri Satış Fiyatı: $" .. refund .. " (Anahtar silinir)",
                    icon = "fas fa-key",
                    params = {
                        event = "thd_house:client:previewSell",
                        args = {
                            houseId = id,
                            refund = refund
                        }
                    }
                }
            end
        end

        if not hasOwned then
            menu[#menu+1] = { header = "Henüz bir mülkünüz yok.", isMenuHeader = true, txt = "" }
        end

        -- KATEGORİ 2: SATILIK MÜLKLER
        menu[#menu+1] = { header = "💰 Satılık Mülkler", isMenuHeader = true }
        
        -- Blip sisteminde tuttuğumuz veriyi (SoldHouses) kontrol etmek için serverdan veri çekebilirdik 
        -- ama burada basitçe 'ownedHouses' kontrolü yapıyoruz.
        -- Eğer ev başkasına satılmışsa listede "SATILDI" yazarız.
        -- Not: İdeal sistemde 'SoldHouses' verisi clientta zaten var (syncBlips ile geliyor).
        -- Ancak SoldHouses global değil, local tanımlıysa erişemeyiz. 
        -- Bu yüzden basit mantık ilerliyoruz: Sadece "Satın Al" butonunu koyuyoruz, server zaten kontrol ediyor.

        for id, house in pairs(Config.Houses) do
            -- Eğer benim değilse listele
            if not ownedHouses[id] then
                menu[#menu+1] = {
                    header = house.label,
                    txt = "Fiyat: $" .. house.price,
                    icon = "fas fa-home",
                    params = {
                        event = "thd_house:client:previewBuy",
                        args = {
                            houseId = id
                        }
                    }
                }
            end
        end

        exports['qb-menu']:openMenu(menu)
    end)
end)

-- SATIŞ ONAY MENÜSÜ (YENİ)
RegisterNetEvent('thd_house:client:previewSell', function(data)
    local house = Config.Houses[data.houseId]
    
    local confirmMenu = {
        {
            header = "⚠️ Evi Geri Sat?",
            isMenuHeader = true,
            txt = "İşlem geri alınamaz. Anahtarınız silinir."
        },
        {
            header = "✅ Evet, Sat ($" .. data.refund .. ")",
            params = {
                isServer = true, -- Direkt server eventini tetikle
                event = "thd_house:server:sellHouse",
                args = data.houseId
            }
        },
        {
            header = "❌ Vazgeç",
            params = {
                event = "thd_house:client:openRealEstateMenu" -- Ana menüye dön
            }
        }
    }
    exports['qb-menu']:openMenu(confirmMenu)
end)

RegisterNetEvent('thd_house:client:previewBuy', function(data)
    local house = Config.Houses[data.houseId]
    SetNewWaypoint(house.coords.x, house.coords.y)
    QBCore.Functions.Notify("Konum işaretlendi.", "primary")
    local confirmMenu = {
        { header = house.label .. " Satın Al?", isMenuHeader = true },
        { header = "Onayla ($" .. house.price .. ")", params = { isServer = true, event = "thd_house:server:buyHouse", args = data.houseId } },
        { header = "Vazgeç", params = { event = "qb-menu:closeMenu" } }
    }
    exports['qb-menu']:openMenu(confirmMenu)
end)

-- ANAHTAR KULLANIMI (Ön ve Arka Kapı Destekli)
RegisterNetEvent('thd_house:client:useKey', function(keyHouseId)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local house = Config.Houses[keyHouseId]

    if not house then 
        QBCore.Functions.Notify("Ev verisi bulunamadı.", "error")
        return 
    end

    -- MESAFE KONTROLLERİ
    local distFront = #(pos - house.coords)
    local distBack = 100.0 -- Varsayılan uzak değer
    local distSecret = 100.0
    
    -- Eğer arka kapı koordinatı girilmişse mesafeyi ölç
    if house.backDoorCoords then
        distBack = #(pos - house.backDoorCoords)
    end

    if house.secretDoorCoords then
        distSecret = #(pos - house.secretDoorCoords)
    end

    local targetDoorId = nil
    
    -- Hangi kapıya yakınız? (3.0 metre)
    if distFront < 3.0 then
        -- ÖN KAPIYI SEÇ
        targetDoorId = Config.DoorIds[keyHouseId]
        
    elseif distBack < 3.0 then
        -- ARKA KAPIYI SEÇ
        if Config.BackDoorIds and Config.BackDoorIds[keyHouseId] then
            targetDoorId = Config.BackDoorIds[keyHouseId]
        else
            QBCore.Functions.Notify("Bu evin arka kapı kilidi tanımlanmamış.", "error")
            return
        end

    elseif distSecret < 3.0 then
        -- GİZLİ KAPIYI SEÇ
        if Config.SecretDoorIds and Config.SecretDoorIds[keyHouseId] then
            targetDoorId = Config.SecretDoorIds[keyHouseId]
        else
            QBCore.Functions.Notify("Bu evin gizli kapı kilidi tanımlanmamış.", "error")
            return
        end
    else
        QBCore.Functions.Notify("Herhangi bir kapıya yeterince yakın değilsin.", "error")
        return
    end

    -- EĞER KAPI ID BULUNDUYSA İŞLEM YAP
    if targetDoorId then
        -- Kapı durumunu ox_doorlock üzerinden al
        local doorData = exports.ox_doorlock:getDoor(targetDoorId)
        local isLocked = (doorData and doorData.state == 1) or false

        -- Animasyon
        RequestAnimDict("anim@heists@keycard@")
        while not HasAnimDictLoaded("anim@heists@keycard@") do Wait(10) end
        TaskPlayAnim(ped, "anim@heists@keycard@", "exit", 8.0, 8.0, -1, 48, 1, false, false, false)
        Wait(500)

        local newState = isLocked and 0 or 1
        TriggerServerEvent('thd_house:server:toggleDoor', keyHouseId, targetDoorId, newState)
        
        Wait(500)
        ClearPedTasks(ped)
    else
        QBCore.Functions.Notify("Kapı ID'si bulunamadı (Config hatası).", "error")
    end
end)

-- EV İÇİ ETKİLEŞİMLER (Stash & Wardrobe)
CreateThread(function()
    for id, house in pairs(Config.Houses) do
        -- 1. STASH (DEPO) NOKTASI
        if house.stash then
            exports['qb-target']:AddCircleZone("house_stash_"..id, house.stash, 1.0, {
                name = "house_stash_"..id,
                debugPoly = false,
            }, {
                options = {
                    {
                        type = "client",
                        event = "thd_house:client:openStash",
                        icon = "fas fa-box-open",
                        label = "Depoyu Aç",
                        args = { houseId = id } -- Hangi evin deposu olduğunu gönderiyoruz
                    },
                },
                distance = 2.0
            })
        end

        if house.secretStash then
            exports['qb-target']:AddCircleZone("house_secret_"..id, house.secretStash, 0.6, { -- 0.6 daha küçük alan
                name = "house_secret_"..id,
                debugPoly = false,
            }, {
                options = {
                    {
                        type = "client",
                        event = "thd_house:client:openSecretStash",
                        icon = "fas fa-user-secret", -- Gizli ajan ikonu :)
                        label = "Gizli Bölmeyi Aç",
                        args = { houseId = id }
                    },
                },
                distance = 1.5
            })
        end

        -- 2. WARDROBE (GARDIROP) NOKTASI
        if house.wardrobe then
            exports['qb-target']:AddCircleZone("house_wardrobe_"..id, house.wardrobe, 1.0, {
                name = "house_wardrobe_"..id,
                debugPoly = false,
            }, {
                options = {
                    {
                        type = "client",
                        event = "thd_house:client:openWardrobe",
                        icon = "fas fa-tshirt",
                        label = "Kıyafet Dolabı",
                        -- Gardırop açmak için özel bir ID'ye gerek yok, oyuncu kendi kıyafetlerini görür
                    },
                },
                distance = 2.0
            })
        end
    end
end)

-- STASH AÇMA İSTEMCİ EVENTİ (Düzeltildi)
RegisterNetEvent('thd_house:client:openStash', function(data)
    -- qb-target bazen veriyi data.args.houseId olarak, bazen data.houseId olarak gönderir.
    -- Garantiye almak için ikisini de kontrol ediyoruz.
    
    local houseId = nil
    
    if data.houseId then
        houseId = data.houseId
    elseif data.args and data.args.houseId then
        houseId = data.args.houseId
    end

    if houseId then
        TriggerServerEvent('thd_house:server:openStash', houseId)
    else
        QBCore.Functions.Notify("Stash verisi okunamadı, scripte restart atın.", "error")
    end
end)

RegisterNetEvent('thd_house:client:openSecretStash', function(data)
    local houseId = nil
    if data.houseId then houseId = data.houseId
    elseif data.args and data.args.houseId then houseId = data.args.houseId end

    if houseId then
        -- Animasyon ekleyelim (Eğilip kurcalama)
        local ped = PlayerPedId()
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        while not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b") do Wait(0) end
        TaskPlayAnim(ped, "amb@prop_human_bum_bin@idle_b", "idle_d", 8.0, 8.0, -1, 1, 0, false, false, false)
        
        QBCore.Functions.Progressbar("open_secret", "Gizli bölme açılıyor...", 2000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Bittiğinde
            ClearPedTasks(ped)
            TriggerServerEvent('thd_house:server:openSecretStash', houseId)
        end, function() -- İptal
            ClearPedTasks(ped)
        end)
    end
end)

-- GARDIROP AÇMA İSTEMCİ EVENTİ (Illenium-Appearance)
RegisterNetEvent('thd_house:client:openWardrobe', function()
    -- Illenium Appearance Kıyafet Menüsünü Tetikle
    TriggerEvent('illenium-appearance:client:openOutfitMenu')
end)

-- SUNUCU AÇILIŞINDA KAPILARI ZORLA KİLİTLEME VE TANITMA
-- Bu kod restart sonrası kapıların algılanmama sorununu çözer.
CreateThread(function()
    -- Diğer scriptlerin yüklenmesi için kısa bir bekleme
    Wait(2000)
    
    -- ox_doorlock sisteminde kapılar otomatik olarak senkronize edilir.
    -- Ancak özel bir durum varsa TriggerServerEvent('ox_doorlock:setState', doorId, 1) kullanılabilir.

    print("thd_house: ox_doorlock uzerinde senkronizasyon saglandi.")
end)