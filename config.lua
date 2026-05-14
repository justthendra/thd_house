Config = {}

-- Emlakçı Konumu (Satış Noktası)
Config.RealEstateLocation = vector4(1140.38, -465.53, 66.83, 250.09)
Config.SellRefundPercentage = 0.5 -- Ev fiyatının %50'si iade edilir. (0.75 yaparsanız %75'i olur)


Config.Stash = {
    slots = 50,      -- Depo slot sayısı
    weight = 100000, -- Depo ağırlığı (100kg)
}

Config.DoorIds = {
    [1] = "mirror1",
    [2] = "mirror2",
    [3] = "mirror3",
    [4] = "mirror4",
    [5] = "mirror5",
    [6] = "mirror6",
    [7] = "mirror7",
    [8] = "mirror8",
    [9] = "mirror9",
    [10] = "mirror10",
    [11] = "villa1",
    [12] = "villa2",
    [13] = "villa3",
}

Config.BackDoorIds = {
    [1] = "mirrorarka1",
    [2] = "mirrorarka2",
    [3] = "mirrorarka3",
    [4] = "mirrorarka4",
    [5] = "mirrorarka5",
    [6] = "mirrorarka6",
    [7] = "mirrorarka7",
    [8] = "mirrorarka8",
    [9] = "mirrorarka9",
    [10] = "mirrorarka10",
    [11] = "mirrorarka11",
    [12] = "mirrorarka12",
    [13] = "mirrorarka13",
    [7] = "mirrorarka7",
    [8] = "mirrorarka8",
    [9] = "mirrorarka9",
    [10] = "mirrorarka10",
    [11] = "villaarka1",
    [13] = "villaarka2",
}

Config.SecretDoorIds = {
    [11] = "gizli1",
    -- [12] = 128,
}

Config.SecretStashSettings = {
    slots = 50,      -- Gizli kasa daha küçük olur (örn: 10 slot)
    weight = 50000,  -- 50kg kapasite
    label = "Kasa"
}

-- Ev Listesi
Config.Houses = {
    [1] = { coords = vector3(1100.67, -411.41, 67.56), backDoorCoords = vector3(1117.74, -412.93, 67.55), price = 50000, label = "Ev No: 1", doorId = "mirror1", stash = vector3(1102.98, -411.62, 67.56), wardrobe = vector3(1105.26, -415.22, 70.89) },
    [2] = { coords = vector3(1303.05, -527.71, 71.48), backDoorCoords = vector3(1309.06, -511.82, 71.48), price = 60000, label = "Ev No: 2", doorId = "mirror2", stash = vector3(1304.04, -525.55, 71.47), wardrobe = vector3(1307.9, -524.4, 74.79) },
    [3] = { coords = vector3(1348.22, -547.08, 73.89), backDoorCoords = vector3(1355.14, -531.47, 73.89), price = 55000, label = "Ev No: 3", doorId = "mirror3", stash = vector3(1349.44, -545.01, 73.89), wardrobe = vector3(1353.37, -544.06, 77.22) },
    [4] = { coords = vector3(1388.77, -569.66, 74.5), backDoorCoords = vector3(1404.44, -563.21, 74.5), price = 70000, label = "Ev No: 4", doorId = "mirror4", stash = vector3(1390.9, -569.0, 74.51), wardrobe = vector3(1394.43, -570.99, 77.83) },
    [5] = { coords = vector3(1385.96, -593.34, 74.52), backDoorCoords = vector3(1399.51, -603.99, 74.52), price = 75000, label = "Ev No: 5", doorId = "mirror5", stash = vector3(1387.78, -594.91, 74.49) , wardrobe = vector3(1387.6, -598.86, 77.82) },
    [6] = { coords = vector3(1367.2, -606.42, 74.73), backDoorCoords = vector3(1367.04, -623.36, 74.73), price = 65000, label = "Ev No: 6", doorId = "mirror6", stash = vector3(1367.03, -608.63, 74.72), wardrobe = vector3(1363.72, -610.99, 78.05) },
    [7] = { coords = vector3(1323.42, -582.93, 73.25), backDoorCoords = vector3(1316.12, -598.71, 73.25), price = 60000, label = "Ev No: 7", doorId = "mirror7", stash = vector3(1322.33, -584.93, 73.25), wardrobe = vector3(1318.32, -585.78, 76.58) },
    [8] = { coords = vector3(1301.09, -574.02, 71.73), backDoorCoords = vector3(1295.88, -590.33, 71.73), price = 55000, label = "Ev No: 8", doorId = "mirror8", stash = vector3(1300.24, -576.13, 71.74), wardrobe = vector3(1296.37, -577.42, 75.06) },
    [9] = { coords = vector3(906.4, -489.7, 59.47), backDoorCoords = vector3(899.57, -473.89, 59.47), price = 80000, label = "Ev No: 9", doorId = "mirror9", stash = vector3(905.62, -487.57, 59.44), wardrobe = vector3(907.34, -484.04, 62.77) },
    [10] = { coords = vector3(919.99, -569.88, 58.38), backDoorCoords = vector3(912.39, -554.31, 58.38), price = 85000, label = "Ev No: 10", doorId = "mirror10", stash = vector3(919.12, -567.81, 58.37), secretStash = vector3(107.75, 468.73, 142.21), wardrobe = vector3(920.83, -564.12, 61.7) },
    [11] = { coords = vector3(107.06, 467.1, 147.56), backDoorCoords = vector3(108.75, 464.86, 147.37), secretDoorCoords = vector3(108.4, 463.18, 142.21), price = 1200000, label = "Ev No: 11", doorId = "villa1", stash = vector3(108.32, 462.82, 147.37), secretStash = vector3(107.87, 468.59, 142.21), wardrobe = vector3(107.89, 460.16, 147.37) },
    [12] = { coords = vector3(-176.73, 970.9, 237.53), price = 950000, label = "Ev No: 12", doorId = "villa2", stash = vector3(-176.28, 972.95, 237.53), wardrobe = vector3(-178.07, 973.74, 237.53) },
    [13] = { coords = vector3(-151.75, 910.81, 235.66), backDoorCoords = vector3(-145.55, 899.14, 235.66), price = 1500000, label = "Ev No: 13", doorId = "villa3", stash = vector3(-165.2, 902.55, 237.15), wardrobe = vector3(-163.87, 896.47, 237.15) },
}