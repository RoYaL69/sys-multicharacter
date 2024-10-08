local cam = nil
local characters = {}
local QBCore = exports['qb-core']:GetCoreObject()
local id = 0
local MugshotsCache = {}
local Answers = {}
local hoveredCoords = nil
local selectedCoords = nil
local lightCoords = nil
local menuType = "FE_MENU_VERSION_EMPTY_NO_BACKGROUND"
-- Main Thread

CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            TriggerEvent('sys-multicharacter:client:chooseChar')
            return
        end
    end
end)

-- Functions

function GetMugShotBase64(Ped, Tasparent)
    if not Ped then
        return ""
    end
    id = id + 1

    local Handle = RegisterPedheadshot(Ped)

    local timer = 2000
    while ((not Handle or not IsPedheadshotReady(Handle) or not IsPedheadshotValid(Handle)) and timer > 0) do
        Citizen.Wait(10)
        timer = timer - 10
    end

    local MugShotTxd = 'none'
    if (IsPedheadshotReady(Handle) and IsPedheadshotValid(Handle)) then
        MugshotsCache[id] = Handle
        MugShotTxd = GetPedheadshotTxdString(Handle)
    end

    SendNUIMessage({
        action = 'convert',
        pMugShotTxd = MugShotTxd,
        removeImageBackGround = Tasparent or false,
        id = id
    })

    local p = promise.new()
    Answers[id] = p

    return Citizen.Await(p)
end

local function skyCam(bool)
    TriggerEvent('qb-weathersync:client:DisableSync')
    if bool then
        DoScreenFadeIn(1000)
        SetTimecycleModifier('hud_def_blur')
        SetTimecycleModifierStrength(1.0)
        FreezeEntityPosition(PlayerPedId(), false)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z,
            0.0, 0.0, Config.CamCoords.w, 60.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    else
        SetTimecycleModifier('default')
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end
local function openCharMenu(bool)
    QBCore.Functions.TriggerCallback("sys-multicharacter:server:GetNumberOfCharacters", function(result)
        local translations = {}
        for k in pairs(Lang.fallback and Lang.fallback.phrases or Lang.phrases) do
            if k:sub(0, ('ui.'):len()) then
                translations[k:sub(('ui.'):len() + 1)] = Lang:t(k)
            end
        end
        SetNuiFocus(bool, bool)
        SendNUIMessage({
            action = "ui",
            customNationality = Config.customNationality,
            color = Config.Color,
            toggle = bool,
            nChar = result,
            enableDeleteButton = Config.EnableDeleteButton,
            translations = translations
        })
        skyCam(bool)
        if not loadScreenCheckState then
            ShutdownLoadingScreenNui()
            loadScreenCheckState = true
        end
    end)
    ActivateFrontendMenu(GetHashKey(menuType), 0, -1)
    Citizen.Wait(100)
    SetMouseCursorVisibleInMenus(false)
end

function SpawnPlayerPed(k, name, citizenid)
    local ped = promise.new()
    Wait(0)
    QBCore.Functions.TriggerCallback('sys-multicharacter:server:getSkin', function(skinData, data)
        local model = nil
        if skinData == nil then return end
        if Config.Clothing == 'qb-clothing' then
            model = skinData ~= nil and tonumber(skinData) or false
        elseif Config.Clothing == 'illenium-appearance' then
            model = skinData.model
        else
            print('Clothing system "' .. Config.Clothing .. '" is not supported')
        end
        if model ~= nil then
            CreateThread(function()
                Wait(500)
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
                local character = CreatePed(2, model, Config.PedCoords[k].x, Config.PedCoords[k].y,
                    Config.PedCoords[k].z - 0.98, Config.PedCoords[k].w, false, true)

                local RandomAnimins = {"WORLD_HUMAN_HANG_OUT_STREET", "WORLD_HUMAN_STAND_IMPATIENT",
                                       "WORLD_HUMAN_SMOKING_POT", "WORLD_HUMAN_LEANING", "WORLD_HUMAN_DRUG_DEALER_HARD"}
                local PlayAnimin = RandomAnimins[math.random(#RandomAnimins)]
                SetPedCanPlayAmbientAnims(character, true)
                TaskStartScenarioInPlace(character, PlayAnimin, 0, true)
                PlaceObjectOnGroundProperly(character)
                SetPedComponentVariation(character, 0, 0, 0, 2)
                FreezeEntityPosition(character, false)
                SetEntityInvincible(character, true)
                SetEntityAsMissionEntity(character, true)
                PlaceObjectOnGroundProperly(character)
                SetBlockingOfNonTemporaryEvents(character, true)
                if Config.Clothing == 'illenium-appearance' then
                    exports['illenium-appearance']:setPedAppearance(character, skinData)
                elseif Config.Clothing == 'qb-clothing' then
                    data = json.decode(data)
                    TriggerEvent('qb-clothing:client:loadPlayerClothing', data, character)
                end

                characters[k] = character
            end)
        else
            CreateThread(function()
                local character = CreatePed(2, skinData, Config.PedCoords[k].x, Config.PedCoords[k].y,
                    Config.PedCoords[k].z - 0.98, Config.PedCoords[k].w, false, true)
                SetPedComponentVariation(character, 0, 0, 0, 2)
                FreezeEntityPosition(character, false)
                SetEntityInvincible(character, true)
                PlaceObjectOnGroundProperly(character)
                SetBlockingOfNonTemporaryEvents(character, true)
                characters[k] = character
            end)
        end
        ped:resolve(true)
    end, citizenid)
    return ped
end

local function ClearUseless()
    ClearAreaOfPeds(Config.PedCoords[1].x, Config.PedCoords[1].y, Config.PedCoords[1].z, 10.0)
    local chair1 = GetClosestObjectOfType(Config.PedCoords[1].x, Config.PedCoords[1].y, Config.PedCoords[1].z, 10.0,
        'v_58_soloff_gchair', 0, 0, 0)
    SetEntityAsMissionEntity(chair1, true, true)

    if DoesEntityExist(chair1) then
        DeleteEntity(chair1)
    end

    local chair2 = GetClosestObjectOfType(Config.PedCoords[1].x, Config.PedCoords[1].y, Config.PedCoords[1].z, 10.0,
        'v_58_soloff_gchair2', 0, 0, 0)
    SetEntityAsMissionEntity(chair2, true, true)

    if DoesEntityExist(chair2) then
        DeleteEntity(chair2)
    end
end

-- Events

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerEvent('sys-multicharacter:client:setPlayerCharacter')
end)

RegisterNetEvent('sys-multicharacter:client:setPlayerCharacter', function()
    local image = GetMugShotBase64(GetPlayerPed(-1), false)
    TriggerServerEvent('sys-multicharacter:server:setPlayerCharacter', image)
end)

RegisterNetEvent('sys-multicharacter:client:closeNUIdefault',
    function() -- This event is only for no starting apartments
        for _, v in pairs(characters) do
            DeleteEntity(v)
        end
        SetNuiFocus(false, false)
        DoScreenFadeOut(500)
        Wait(2000)
        SetEntityCoords(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        Wait(500)
        openCharMenu()
        SetEntityVisible(PlayerPedId(), true)
        Wait(500)
        DoScreenFadeIn(250)
        TriggerEvent('qb-weathersync:client:EnableSync')
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    end)

RegisterNetEvent('sys-multicharacter:client:closeNUI', function()
    for _, v in pairs(characters) do
        DeleteEntity(v)
    end
    if (IsScreenFadedOut() or IsPauseMenuActive()) and menuType ~= nil then
        ActivateFrontendMenu(GetHashKey(menuType), false, -1)
    end
    SetNuiFocus(false, false)
end)

RegisterNetEvent('sys-multicharacter:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z - 18.9)
    LoadInterior(interior)
    while not IsInteriorReady(interior) do
        Wait(1000)
    end
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    openCharMenu(true)
end)

-- NUI Callbacks

RegisterNUICallback('closeUI', function(_, cb)
    openCharMenu(false)
    cb("ok")
end)

RegisterNUICallback('disconnectButton', function(_, cb)
    for _, v in pairs(characters) do
        SetEntityAsMissionEntity(v, true, true)
        DeleteEntity(v)
    end
    TriggerServerEvent('sys-multicharacter:server:disconnect')
    cb("ok")
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    local cData = data.cData
    ClearAreaOfPeds(Config.PedCoords[1].x, Config.PedCoords[1].y, Config.PedCoords[1].z, 10.0)
    DoScreenFadeOut(10)
    TriggerServerEvent('sys-multicharacter:server:loadUserData', cData)
    openCharMenu(false)
    for _, v in pairs(characters) do
        SetEntityAsMissionEntity(v, true, true)
        DeleteEntity(v)
    end
    cb("ok")
end)

RegisterNUICallback('CharacterUnHover', function(_, cb)
    hoveredCoords = nil
end)

RegisterNUICallback('CharacterHover', function(data, cb)
    local p = data.id
    hoveredCoords = GetEntityCoords(characters[tonumber(p)])
end)

RegisterNUICallback('cDataPed', function(nData, cb)
    local cData = nData.cData
    for _, v in pairs(characters) do
        SetEntityAsMissionEntity(v, true, true)
    end
    if cData ~= nil then
        local pedId = cData.cid
        selectedCoords = GetEntityCoords(characters[tonumber(pedId)])
        local ped = characters[tonumber(pedId)]
        local x, y, z = table.unpack(Config.PedCamCoords[tonumber(pedId)])
        local coords = {
            x = x,
            y = y,
            z = z,
            w = GetEntityHeading(ped)
        }
        moveCameraToCoords(coords)
        for _, char in pairs(characters) do
            SetEntityLocallyInvisible(char)
        end
    else
        selectedCoords = nil
    end
    cb("ok")
end)

function moveCameraToCoords(coords)
    local animationDuration = 180
    local animationStartCoords = GetCamCoord(cam)
    local startRot = GetCamRot(cam, 2)
    local startRotX = startRot.x
    local startRotY = startRot.y
    local startRotZ = startRot.z
    local endRot = coords.w + 180
    local endRotZ = endRot - startRotZ
        if endRotZ > 180 then
            endRotZ = endRotZ - 360
        elseif endRotZ < -180 then
            endRotZ = endRotZ + 360
        end
    local animationEndCoords = vector3(coords.x, coords.y, coords.z + 0.2)
    local endRotX, endRotY, endRotZ = 0.0, 0.0, endRotZ
    local rotX, rotY, rotZ = 0, 0, 0

    for i = 0, animationDuration do
        local t = i / animationDuration
        local camX = animationStartCoords.x + (animationEndCoords.x - animationStartCoords.x) * t
        local camY = animationStartCoords.y + (animationEndCoords.y - animationStartCoords.y) * t
        local camZ = animationStartCoords.z + (animationEndCoords.z - animationStartCoords.z) * t
        rotX = startRotX + (endRotX - startRotX) * t
        rotY = startRotY + (endRotY - startRotY) * t
        rotZ = startRotZ + endRotZ * t
        SetCamCoord(cam, camX, camY, camZ)
        SetCamRot(cam, rotX, rotY, rotZ)
        Citizen.Wait(0)
    end
    RenderScriptCams(true, false, 0, true, true)
    SetCamCoord(cam, coords.x, coords.y, coords.z + 0.2)
    SetCamRot(cam, endRotX, endRotY, startRotZ + endRotZ)
    SendNUIMessage({
        action = "showPlayerCard",
        characters = result
    })
end

Citizen.CreateThread(function()
    while true do
        if hoveredCoords ~= nil then
            local notSameAsSelected = selectedCoords == nil or
                                          ((selectedCoords.x ~= hoveredCoords.x) and
                                              (selectedCoords.y ~= hoveredCoords.y) and
                                              (selectedCoords.z ~= hoveredCoords.z))
            if notSameAsSelected then
                DrawLightWithRangeAndShadow(hoveredCoords.x, hoveredCoords.y, hoveredCoords.z, 255, 255, 255, 2.0, 10.0,
                    15.0)
            end
        end

        if selectedCoords ~= nil then
            DrawLightWithRangeAndShadow(selectedCoords.x, selectedCoords.y, selectedCoords.z, 255, 255, 255, 2.0, 10.0,
                15.0)
        end
        Citizen.Wait(1)
    end
end)

RegisterNUICallback('setupCharacters', function(_, cb)
    ClearUseless()
    for _, v in pairs(characters) do
        DeleteEntity(v)
    end
    QBCore.Functions.TriggerCallback("sys-multicharacter:server:setupCharacters", function(result)
        for k, v in pairs(result) do
            local name = v.charinfo.firstname .. " " .. v.charinfo.lastname
            Citizen.Await(SpawnPlayerPed(v.cid, name, v.citizenid))
        end
        SendNUIMessage({
            action = "setupCharacters",
            characters = result
        })
        cb("ok")
    end)
end)

RegisterNUICallback('removeBlur', function(_, cb)
    SetTimecycleModifier('default')
    cb("ok")
end)

RegisterNUICallback('createNewCharacter', function(data, cb)
    ClearUseless()
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == "Male" then
        cData.gender = 0
    elseif cData.gender == "Female" then
        cData.gender = 1
    end
    TriggerServerEvent('sys-multicharacter:server:createCharacter', cData)
    Wait(500)
    DoScreenFadeOut(150)
    SetTimecycleModifier('default')
    RenderScriptCams(false, false, 1, true, true)
    FreezeEntityPosition(PlayerPedId(), false)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    cb("ok")
end)

RegisterNUICallback('removeCharacter', function(data, cb)
    TriggerServerEvent('sys-multicharacter:server:deleteCharacter', data.citizenid)
    TriggerEvent('sys-multicharacter:client:chooseChar')
    cb("ok")
end)

RegisterNUICallback('Answer', function(data)
    if MugshotsCache[data.Id] then
        UnregisterPedheadshot(MugshotsCache[data.Id])
        MugshotsCache[data.Id] = nil
    end
    Answers[data.Id]:resolve(data.Answer)
    Answers[data.Id] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if (IsScreenFadedOut() or IsPauseMenuActive()) and menuType ~= nil then
        ActivateFrontendMenu(GetHashKey(menuType), false, -1)
    end
    for k, v in pairs(MugshotsCache) do
        UnregisterPedheadshot(v)
    end
    MugshotsCache = {}
    id = 0
end)

