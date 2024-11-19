Nmsh = {}

Nmsh['Settings'] = {
    menu = 'qb-menu',
    input = 'qb-input',
    progressbar = 'progressbar',
    progressbarTime = 10000,
    inventory = 'qb-inventory/html/images/',
    core = 'qb-core',
}

Nmsh.MaxInventoryWeight = 120000 -- Maximum weight a player can carry


Nmsh['Seller-NPC'] = {
    model = 'mp_g_m_pros_01',
    coords = vector3(4.82, -707.0, 45.97),
    buyShopMethod = 'cash',
    heading = 207.09,
    blip = {
        sprite = 366,
        color = 2,
        scale = 0.8,
        name = 'Supermarkets Seller',
    }
}

Nmsh['Products'] = {
    ['water_bottle'] = {
        name = 'Water Bottle',
        price = 10,
    },
    ['tosti'] = {
        name = 'Bread',
        price = 20,
    },
}

Nmsh['locations'] = {
    vector3(1181.18, -3240.07, 6.03)
}

Nmsh['Supermarkets'] = {
    ['supermarket1'] = {
        name = 'Supermarket 1',
        coords = vector3(24.5, -1346.04, 29.5),
        truck = vector4(15.93, -1342.45, 29.29, 174.82),
        npc = {
            model = 'mp_m_shopkeep_01',
            coords = vector3(24.5, -1346.04, 29.5),
            heading = 274.77,
        },
        manager = {
            model = 's_m_m_linecook',
            coords = vector3(30.11, -1339.82, 29.5),
            heading = 83.68,
        },
        price = 100,
    },
    ['supermarket2'] = {
        name = 'Supermarket 2',
        coords = vector3(-47.34, -1758.7, 29.42),
        truck = vector4(-59.67, -1745.42, 29.36, 50.95),
        npc = {
            model = 'mp_m_shopkeep_01',
            coords = vector3(-47.34, -1758.7, 29.42),
            heading = 45.37,
        },
        manager = {
            model = 's_m_m_linecook',
            coords = vector3(-41.83, -1748.77, 29.42),
            heading = 138.37,
        },
        price = 100,
    },
    ['supermarket3'] = {
        name = 'Supermarket 3',
        coords = vector3(-1485.76, -378.56, 40.16),
        truck =  vector4(-1472.17, -395.97, 38.26, 134.22),
        npc = {
            model = 'mp_m_shopkeep_01',
            coords = vector3(-1485.76, -378.56, 40.16),
            heading = 135.33,
        },
        manager = {
            model = 's_m_m_linecook',
            coords = vector3(-1478.07, -374.65, 39.16),
            heading = 49.48,
        },
        price = 100,

    },
    ['supermarket4'] = {
        name = 'Supermarket 4',
        coords = vector3(-1222.49, -908.68, 12.33), 
        truck = vector4(-1227.47, -895.01, 12.21, 127.46),
        npc = {
            model = 'mp_m_shopkeep_01',
            coords = vector3(-1222.49, -908.68, 12.33),
            heading = 31.26,
        },
        manager = {
            model = 's_m_m_linecook',
            coords = vector3(-1220.11, -916.89, 11.33),
            heading = 304.14,
        },
        price = 100,
    },
    ['supermarket5'] = {
        name = 'Supermarket 5',
        coords = vector3(-706.13, -914.65, 19.22),
        truck = vector4(-715.31, -921.04, 19.01, 176.61),
        npc = {
            model = 'mp_m_shopkeep_01',
            coords = vector3(-706.13, -914.65, 19.22),
            heading = 89.36,
        },
        manager = {
            model = 's_m_m_linecook',
            coords = vector3(-708.23, -903.55, 19.22),
            heading = 176.71,
        },
        price = 100,
    },
}