Config = {}
Config.Color = "#4ade80"
Config.EnableDeleteButton = true -- Define if the player can delete the character or not
Config.Clothing = 'bl_appearance' -- qb-clothing or 'bl_appearance'
Config.DefaultNumberOfCharacters = 5 -- Define maximum amount of default characters, Max 4 //ST4LTH
Config.PlayersNumberOfCharacters = {
    -- Define maximum amount of player characters by rockstar license (you can find this license in your server's database in the player table)
}

-- Unless you know what you are doing, do not touch the section below

Config.Interior = vector3(-1004.36, -477.9, 51.63) -- Interior to load where characters are previewed
Config.DefaultSpawn = vector3(-1004.36, -477.9, 51.63) -- Default spawn coords if you have start apartments disabled
Config.HiddenCoords = vector4(-1001.11, -478.06, 50.03, 24.55) -- Hides your actual ped while you are in selection
Config.CamCoords = vector4(-1005.53, -480.73, 50.31, 27.44) -- Camera coordinates for character preview screen

Config.PedCoords = {
    [1] = vector4(-1007.89, -474.23, 50.03, 223.49),
    [2] = vector4(-1005.68, -474.85, 50.03, 143.8),
    [3] = vector4(-1007.51, -477.25, 50.03, 208.27),
    [4] = vector4(-1010.4, -475.8, 50.03, 217.6),
    [5] = vector4(-1010.56, -478.8, 50.03, 282.33)
}

Config.PedCamCoords = {
    [1] = vector4(-1006.7, -475.35, 50.31, 33.25),
    [2] = vector4(-1006.59, -476.5, 50.31, 312.18),
    [3] = vector4(-1006.21, -478.83, 50.31, 36.25),
    [4] = vector4(-1008.49, -477.9, 50.31, 31.8),
    [5] = vector4(-1008.53, -477.99, 50.31, 106.34)
}

Apartments = {}
Apartments.Starting = true
Apartments.SpawnOffset = 30
Apartments.Locations = {
    ["apartment1"] = {
        name = "apartment1",
        label = "South Rockford Drive",
        coords = {
            enter = vector4(-667.02, -1105.24, 14.63, 242.32),
        },
        polyzoneBoxData = {
            heading = 245,
            minZ = 13.5,
            maxZ = 16.0,
            debug = false,
            length = 1,
            width = 3,
            distance = 2.0,
            created = false
        }
    },
    ["apartment2"] = {
        name = "apartment2",
        label = "Morningwood Blvd",
        coords = {
            enter = vector4(-1288.52, -430.51, 35.15, 124.81),
        },
        polyzoneBoxData = {
            heading = 124,
            minZ = 34.0,
            maxZ = 37.0,
            debug = false,
            length = 1,
            width = 3,
            distance = 2.0,
            created = false
        }
    },
    ["apartment3"] = {
        name = "apartment3",
        label = "Integrity Way",
        coords = {
            enter = vector4(269.73, -640.75, 42.02, 249.07),
        },
        polyzoneBoxData = {
            heading = 250,
            minZ = 40,
            maxZ = 43.5,
            debug = false,
            length = 1,
            width = 1,
            distance = 2.0,
            created = false
        }
    },
    ["apartment4"] = {
        name = "apartment4",
        label = "Tinsel Towers",
        coords = {
            enter = vector4(-619.29, 37.69, 43.59, 181.03),
        },
        polyzoneBoxData = {
            heading = 180,
            minZ = 41.0,
            maxZ = 45.5,
            debug = false,
            length = 1,
            width = 2,
            distance = 2.0,
            created = false
        }
    },
    ["apartment5"] = {
        name = "apartment5",
        label = "Fantastic Plaza",
        coords = {
            enter = vector4(291.517, -1078.674, 29.405, 270.75),
        },
        polyzoneBoxData = {
            heading = 270,
            minZ = 28.5,
            maxZ = 31.0,
            debug = false,
            length = 1,
            width = 2,
            distance = 2.0,
            created = false
        }
    },
}
