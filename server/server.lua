local QBCore = exports['qb-core']:GetCoreObject()
local SoldHouses = {} -- Satılan evlerin listesi ve sahipleri: [houseId] = "Ad Soyad"

-- Sunucu Başladığında Satılan Evleri ve İsimleri Çek
CreateThread(function()
    -- player_houses tablosu ile players tablosunu birleştirip isimleri alıyoruz
    local result = MySQL.query.await('SELECT h.house_id, p.charinfo FROM player_houses h LEFT JOIN players p ON h.citizenid = p.citizenid')
    
    if result then
        for _, v in pairs(result) do
            if v.charinfo then
                local char = json.decode(v.charinfo)
                -- İsim Soyisim birleştir
                local fullname = char.firstname .. ' ' .. char.lastname
                SoldHouses[v.house_id] = fullname
            else
                SoldHouses[v.house_id] = "Bilinmiyor"
            end
        end
    end
end)

-- Oyuncu oyuna girdiğinde blip verilerini gönder
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    TriggerClientEvent('thd_house:client:syncBlips', Player.PlayerData.source, SoldHouses)
end)

-- Script restartlanırsa aktif oyunculara blipleri gönder
RegisterNetEvent('thd_house:server:requestBlips', function()
    local src = source
    TriggerClientEvent('thd_house:client:syncBlips', src, SoldHouses)
end)

-- EV SATIN ALMA İŞLEMİ (Güncellendi)
RegisterNetEvent('thd_house:server:buyHouse', function(houseId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local house = Config.Houses[houseId]

    if not house then return end

    local result = MySQL.query.await('SELECT * FROM player_houses WHERE house_id = ?', {houseId})
    if result[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Bu mülk zaten sahipli.', 'error')
        return
    end

    if Player.Functions.RemoveMoney('bank', house.price, "Ev Satın Alımı") then
        MySQL.insert('INSERT INTO player_houses (house_id, citizenid) VALUES (?, ?)', {houseId, Player.PlayerData.citizenid})
        
        -- Metadata: houseId bilgisini iteme yazıyoruz
        local info = { houseId = houseId, description = house.label }
        exports.ox_inventory:AddItem(src, 'house_key', 1, info)
        
        -- BLIP GÜNCELLEME KISMI
        local fullname = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        SoldHouses[houseId] = fullname
        
        -- Tüm oyuncuların haritasını güncelle (Kırmızıdan Yeşile dönsün)
        TriggerClientEvent('thd_house:client:updateSingleBlip', -1, houseId, fullname)
        
        TriggerClientEvent('QBCore:Notify', src, 'Ev satın alındı!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Yeterli paran yok.', 'error')
    end
end)

-- Anahtar Kullanımı (Değişmedi)
QBCore.Functions.CreateUseableItem("house_key", function(source, item)
    local src = source
    if item.metadata and item.metadata.houseId then
        TriggerClientEvent("thd_house:client:useKey", src, item.metadata.houseId)
    end
end)

-- Doorlock Trigger
RegisterNetEvent('thd_house:server:toggleDoor', function(houseId, doorId, newState)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player has key with metadata.houseId == houseId
    local hasKey = false
    local items = exports.ox_inventory:GetInventoryItems(src)
    if items then
        for _, item in pairs(items) do
            if item.name == 'house_key' and item.metadata and tostring(item.metadata.houseId) == tostring(houseId) then
                hasKey = true
                break
            end
        end
    end
    
    if hasKey then
        exports.ox_doorlock:setDoorState(doorId, newState)
        
        if newState == 0 then
            TriggerClientEvent('InteractSound_SV:PlayWithinDistance', src, 5.0, 'key_unlock', 0.6)
            TriggerClientEvent('QBCore:Notify', src, "Kapı kilidi açıldı.", "success")
        else
            TriggerClientEvent('InteractSound_SV:PlayWithinDistance', src, 5.0, 'door_lock', 0.6)
            TriggerClientEvent('QBCore:Notify', src, "Kapı kilitlendi.", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "Bu evin anahtarına sahip değilsin.", "error")
    end
end)

-- Oyuncunun sahip olduğu evleri getiren Callback
QBCore.Functions.CreateCallback('thd_house:server:getOwnedHouses', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return cb({}) end

    local result = MySQL.query.await('SELECT house_id FROM player_houses WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local owned = {}
    
    for _, v in pairs(result) do
        owned[v.house_id] = true
    end
    
    cb(owned)
end)

-- EVİ GERİ SATMA İŞLEMİ (Anahtar Silme Sorunu Düzeltildi)
RegisterNetEvent('thd_house:server:sellHouse', function(houseId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local house = Config.Houses[houseId]

    if not house then return end

    -- Evin gerçekten bu oyuncuya ait olup olmadığını kontrol et
    local result = MySQL.query.await('SELECT * FROM player_houses WHERE house_id = ? AND citizenid = ?', {
        houseId, Player.PlayerData.citizenid
    })

    if not result[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Bu ev size ait değil!', 'error')
        return
    end

    -- 1. Veritabanından sil
    MySQL.query('DELETE FROM player_houses WHERE house_id = ?', {houseId})

    -- 2. Para iadesi yap
    local refundAmount = math.floor(house.price * Config.SellRefundPercentage)
    Player.Functions.AddMoney('bank', refundAmount, "Ev Geri Satışı")

    -- 3. ANAHTAR SİLME (Garanti Yöntem: Slot Bulma)
    -- Oyuncunun tüm itemlerini çek
    local items = exports.ox_inventory:GetInventoryItems(src)
    local keySlot = nil

    if items then
        for _, item in pairs(items) do
            -- İtem 'housekey' mi? VE Metadata'sı var mı?
            if item.name == 'house_key' and item.metadata and item.metadata.houseId then
                -- ID eşleşiyor mu? (tonumber kullanarak string/int farkını yok sayıyoruz)
                if tonumber(item.metadata.houseId) == tonumber(houseId) then
                    keySlot = item.slot
                    break -- Bulduk, döngüden çık
                end
            end
        end
    end

    if keySlot then
        -- Direkt olarak bulunan slottaki itemi sil
        -- RemoveItem(source, item, count, metadata, slot)
        exports.ox_inventory:RemoveItem(src, 'house_key', 1, nil, keySlot)
    else
        -- Anahtar bulunamadıysa (oyuncu yere atmış olabilir) log düşebiliriz
        print("UYARI: Oyuncu evi sattı ama envanterinde silinecek anahtar bulunamadı. HouseID: " .. houseId)
    end

    -- 4. Blip Sistemini Güncelle
    SoldHouses[houseId] = nil
    TriggerClientEvent('thd_house:client:updateSingleBlip', -1, houseId, nil)

    TriggerClientEvent('QBCore:Notify', src, 'Ev başarıyla satıldı. İade: $' .. refundAmount, 'success')
end)

-- SUNUCU BAŞLANGICINDA STASH'LERİ OLUŞTUR (GÜVENLİ VERSİYON)
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    for k, v in pairs(Config.Houses) do
        local houseId = k
        
        -- 1. Normal Stash Kaydı (Zaten vardı)
        if houseId and v.label then
            local stashId = 'house_stash_' .. tostring(houseId)
            local label = 'Ev Deposu: ' .. v.label
            exports.ox_inventory:RegisterStash(stashId, label, Config.Stash.slots, Config.Stash.weight)
        end

        -- 2. GİZLİ KASA KAYDI (YENİ)
        -- Eğer configde secretStash tanımlıysa bunu da kaydet
        if houseId and v.secretStash then
            local secretId = 'house_secret_' .. tostring(houseId)
            local secretLabel = 'Gizli Kasa: ' .. v.label
            exports.ox_inventory:RegisterStash(secretId, secretLabel, Config.SecretStashSettings.slots, Config.SecretStashSettings.weight)
        end
    end
end)

-- GİZLİ KASA AÇMA EVENTİ (YENİ)
RegisterNetEvent('thd_house:server:openSecretStash', function(houseId)
    local src = source
    if not houseId then return end

    local secretId = 'house_secret_' .. tostring(houseId)
    
    -- Ox Inventory ile aç
    exports.ox_inventory:forceOpenInventory(src, 'stash', secretId)
end)

-- STASH AÇMA EVENTİ (GÜVENLİ VERSİYON)
RegisterNetEvent('thd_house:server:openStash', function(houseId)
    local src = source
    
    -- Eğer houseId boş geldiyse işlemi durdur (Hatayı önler)
    if not houseId then 
        TriggerClientEvent('QBCore:Notify', src, 'Depo ID bulunamadı!', 'error')
        return 
    end

    local stashId = 'house_stash_' .. tostring(houseId)
    
    -- Oyuncu stashi açar
    exports.ox_inventory:forceOpenInventory(src, 'stash', stashId)
end)