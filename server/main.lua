local QBCore = exports['qb-core']:GetCoreObject()

-- Functions

local function GiveStarterItems(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    for _, v in pairs(QBCore.Shared.StarterItems) do
        local info = {}
        if v.item == "id_card" then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == "driver_license" then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = "Class C Driver License"
        end
        Player.Functions.AddItem(v.item, v.amount, false, info)
    end
end

local function loadHouseData(src)
    local HouseGarages = {}
    local Houses = {}
    local result = MySQL.query.await('SELECT * FROM properties', {})
    
    if result[1] ~= nil then
        for _, v in pairs(result) do
            local owned = false
            if v.owner ~= nil and v.owner ~= "" then
                owned = true
            end
            local garageConfig = Garages[v.property_name]  -- Hier die Garagenkonfiguration aus qbx_garages holen
            local garage = garageConfig and garageConfig.vehicleType or {}  -- Beispiel für Garage, Fahrzeugtyp verwenden
            Houses[v.property_name] = {
                coords = json.decode(v.coords),
                owned = owned,
                price = v.price,
                locked = true,
                adress = v.property_name,
                tier = v.tier or 1,  -- Falls `tier` existiert, ansonsten Standardwert
                garage = garage,
                decorations = {}  -- Falls Dekorationen aus anderen Feldern benötigt werden
            }
            HouseGarages[v.property_name] = {
                label = v.property_name,
                takeVehicle = garage
            }
        end
    end
    
    TriggerClientEvent("qb-garages:client:houseGarageConfig", src, HouseGarages)
    TriggerClientEvent("qb-houses:client:setHouseConfig", src, Houses)
end


-- Commands

QBCore.Commands.Add("logout", "Logout of Character (Admin Only)", {}, false, function(source, args)
    local src = args[1] or source
    QBCore.Player.Logout(src)
    TriggerClientEvent('sys-multicharacter:client:chooseChar', src)
end, "admin")

QBCore.Commands.Add("closeNUI", "Close Multi NUI", {}, false, function(source)
    local src = source
    TriggerClientEvent('sys-multicharacter:client:closeNUI', src)
end)

-- Events

RegisterNetEvent('sys-multicharacter:server:disconnect', function()
    local src = source
    DropPlayer(src, "You have disconnected from QBCore")
end)

RegisterNetEvent('sys-multicharacter:server:setPlayerCharacter', function(image)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local changed = MySQL.insert.await(
            'INSERT INTO player_pictures (citizenid, image) VALUES (:citizenid, :image) ON DUPLICATE KEY UPDATE image = :image',
            {
                ['citizenid'] = Player.PlayerData.citizenid,
                ['image'] = image
            })
    end
end)

RegisterNetEvent('sys-multicharacter:server:loadUserData', function(cData)
    local src = source
    if QBCore.Player.Login(src, cData.citizenid) then
        print('^2[qb-core]^7 ' .. GetPlayerName(src) .. ' (Citizen ID: ' .. cData.citizenid ..
                  ') has succesfully loaded!')
        QBCore.Commands.Refresh(src)
        loadHouseData(src)
        TriggerClientEvent('sys-multicharacter:client:setPlayerCharacter', src, cData)
        TriggerClientEvent('apartments:client:setupSpawnUI', src, cData)
        TriggerEvent("qb-log:server:CreateLog", "joinleave", "Loaded", "green",
            "**" .. GetPlayerName(src) .. "** (" .. (QBCore.Functions.GetIdentifier(src, 'discord') or 'undefined') ..
                " |  ||" .. (QBCore.Functions.GetIdentifier(src, 'ip') or 'undefined') .. "|| | " ..
                (QBCore.Functions.GetIdentifier(src, 'license') or 'undefined') .. " | " .. cData.citizenid .. " | " ..
                src .. ") loaded..")
    end
end)

RegisterNetEvent('sys-multicharacter:server:createCharacter', function(data)
    local src = source
    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data
    if QBCore.Player.Login(src, false, newData) then
        if config.characters.startingApartment then
            local randbucket = (GetPlayerPed(src) .. math.random(1, 999))
            SetPlayerRoutingBucket(src, randbucket)
            print('^2[qb-core]^7 ' .. GetPlayerName(src) .. ' has succesfully loaded!')
            QBCore.Commands.Refresh(src)
            loadHouseData(src)
            TriggerClientEvent("sys-multicharacter:client:closeNUI", src)
            TriggerClientEvent('apartments:client:setupSpawnUI', src, newData)
            -- TriggerEvent('apartments:client:setupSpawnUI', newData)
            GiveStarterItems(src)
        else
            print('^2[qb-core]^7 ' .. GetPlayerName(src) .. ' has succesfully loaded!')
            QBCore.Commands.Refresh(src)
            loadHouseData(src)
            TriggerClientEvent("sys-multicharacter:client:closeNUIdefault", src)
            GiveStarterItems(src)
        end
    end
end)

RegisterNetEvent('sys-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    QBCore.Player.DeleteCharacter(src, citizenid)
    TriggerClientEvent('QBCore:Notify', src, "Character deleted!", "success")
end)

-- Callbacks

QBCore.Functions.CreateCallback("sys-multicharacter:server:GetUserCharacters", function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')

    MySQL.query('SELECT * FROM players WHERE license = ?', {license}, function(result)
        print(json.encode(result))
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback("sys-multicharacter:server:GetServerLogs", function(_, cb)
    MySQL.query('SELECT * FROM server_logs', {}, function(result)
        cb(result)
    end)
end)

QBCore.Functions.CreateCallback("sys-multicharacter:server:GetNumberOfCharacters", function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    local numOfChars = 0

    if next(Config.PlayersNumberOfCharacters) then
        for _, v in pairs(Config.PlayersNumberOfCharacters) do
            if v.license == license then
                numOfChars = v.numberOfChars
                break
            else
                numOfChars = Config.DefaultNumberOfCharacters
            end
        end
    else
        numOfChars = Config.DefaultNumberOfCharacters
    end
    cb(numOfChars)
end)

QBCore.Functions.CreateCallback("sys-multicharacter:server:setupCharacters", function(source, cb)
    local license = QBCore.Functions.GetIdentifier(source, 'license')
    local plyChars = {}
    MySQL.query(
        'SELECT c.*, pc.image FROM players c LEFT JOIN player_pictures pc ON pc.citizenid = c.citizenid WHERE c.license = ?',
        {license}, function(result)
            for i = 1, (#result), 1 do
                result[i].charinfo = json.decode(result[i].charinfo)
                result[i].money = json.decode(result[i].money)
                result[i].job = json.decode(result[i].job)
                plyChars[#plyChars + 1] = result[i]
            end
            cb(plyChars)
        end)
end)

QBCore.Functions.CreateCallback("sys-multicharacter:server:getSkin", function(_, cb, cid)
    local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {cid, 1})
    if result[1] ~= nil then
        if Config.Clothing == 'qb-clothing' then
            cb(result[1].model, result[1].skin)
        elseif Config.Clothing == 'bl_appearance' then
            cb(json.decode(result[1].skin))
        elseif Config.Clothing == 'illenium-appearance' then
            cb(json.decode(result[1].skin))
        else
            print('Clothing system "' .. Config.Clothing .. '" is not supported')
            cb(nil)
        end
    else
        cb(nil)
    end
end)

