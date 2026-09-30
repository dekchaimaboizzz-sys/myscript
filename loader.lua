-- 540CHEATS v24 GUI | Cheat Hub (Loop Towers Mode Added)

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local VIM             = game:GetService("VirtualInputManager")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService      = game:GetService("GuiService")
local VirtualUser     = nil; pcall(function() VirtualUser = game:GetService("VirtualUser") end)
local LP = Players.LocalPlayer
while not LP do
    task.wait(0.1)
    LP = Players.LocalPlayer
end
local RS              = game:GetService("ReplicatedStorage")
local CFG = nil

local function waitForLoad()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(2)
end
waitForLoad()

-- ── Game Modules ──────────────────────────────────────────────────────────────
local Framework = RS:FindFirstChild("Framework") or RS:WaitForChild("Framework", 15)
local RealUpgrades      = nil; pcall(function() RealUpgrades = require(Framework.Features.Upgrades.Upgrades) end)
local RealTreeStructure = nil; pcall(function() RealTreeStructure = require(Framework.Features.Upgrades.TreeStructure) end)
local RealTowers        = nil; pcall(function() RealTowers = require(Framework.Features.Towers.Towers) end)
local TowerCtrl         = nil; pcall(function() TowerCtrl = require(Framework.Features.Towers.TowerController) end)
local UIReferences      = nil; pcall(function() UIReferences = require(Framework.Features.UI.UIReferences) end)
local HUDController     = nil; pcall(function() HUDController = require(Framework.Features.UI.HUDController) end)
local UnitUtil          = nil; pcall(function() UnitUtil = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitUtil) end)
local UnitController    = nil; pcall(function() UnitController = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitController) end)
local EntryRegistry     = nil; pcall(function() EntryRegistry = require(RS.Framework.Features.Inventory.EntryRegistry) end)
local PlotConfig        = nil; pcall(function() PlotConfig = require(RS.Framework.Features.Plot.PlotConfig) end)
local PlotController    = nil; pcall(function() PlotController = require(RS.Framework.Features.Plot.PlotController) end)
local EntryDropCtrl     = nil; pcall(function() EntryDropCtrl = require(RS.Framework.Features.Notifications.EntryDropController) end)
local _towerFinishedSignal = 0
local showNotif = function(text)
    print("[CHEAT HUB] " .. tostring(text))
end

local TowerScreen, TowerBg, HiddenBtn = nil, nil, nil
pcall(function()
    TowerScreen = UIReferences.Root.Tower.Screen
    TowerBg     = TowerScreen.Parent.Background
    HiddenBtn   = TowerScreen.Parent.Hidden
end)

pcall(function()
    HUDController.showAll("inTower")
    if TowerScreen then TowerScreen.Visible = false end
    if TowerBg then TowerBg.Visible = false end
end)

pcall(function()
    local MenuController = require(RS.Framework.Features.UI.MenuController)
    if MenuController and MenuController.OpenMenu then
        local origOpen = MenuController.OpenMenu
        MenuController.OpenMenu = function(menu)
            if CFG and CFG.AutoTowerQueue and menu and typeof(menu) == "Instance" and menu.Name == "TowerRewards" then
                if menu:IsA("GuiObject") then menu.Visible = false end
                _towerFinishedSignal = tick()
                pcall(function()
                    if EntryDropCtrl and menu:FindFirstChild("Content") and menu.Content:FindFirstChild("ScrollingFrame") then
                        for _, item in ipairs(menu.Content.ScrollingFrame:GetChildren()) do
                            if item:IsA("GuiObject") and item.Name ~= "UIGridLayout" and item.Name ~= "UIPadding" then
                                local name = item.Name
                                local amt = 1
                                local amtLbl = item:FindFirstChild("Amount", true) or item:FindFirstChild("Count", true) or item:FindFirstChild("TextLabel", true)
                                if amtLbl and amtLbl.Text then
                                    amt = tonumber(amtLbl.Text:match("%d+")) or 1
                                end
                                task.spawn(function()
                                    pcall(function() EntryDropCtrl.Play(name, amt) end)
                                end)
                            end
                        end
                    end
                end)
                return
            end
            return origOpen(menu)
        end
    end
end)

-- ── Remotes ───────────────────────────────────────────────────────────────────
local NetRoot = RS:FindFirstChild("Network") or RS:WaitForChild("Network", 10)

local function RE(svc, name)
    if not NetRoot then return nil end
    local s = NetRoot:FindFirstChild(svc) or NetRoot:WaitForChild(svc, 3)
    if not s then return nil end
    local re = s:FindFirstChild("RE") or s:WaitForChild("RE", 3)
    if not re then return nil end
    return re:FindFirstChild(name) or re:WaitForChild(name, 3)
end
local function RF(svc, name)
    if not NetRoot then return nil end
    local s = NetRoot:FindFirstChild(svc) or NetRoot:WaitForChild(svc, 3)
    if not s then return nil end
    local rf = s:FindFirstChild("RF") or s:WaitForChild("RF", 3)
    if not rf then return nil end
    return rf:FindFirstChild(name) or rf:WaitForChild(name, 3)
end
local function REroot(name)
    if not NetRoot then return nil end
    local re = NetRoot:FindFirstChild("RE") or NetRoot:WaitForChild("RE", 3)
    if not re then return nil end
    return re:FindFirstChild(name) or re:WaitForChild(name, 3)
end

local CollectBalance = nil; pcall(function() CollectBalance = RE("PlotService", "CollectBalance") end)
local EquipBest      = nil; pcall(function() EquipBest = RE("PlotService", "EquipBest") end)
local LevelUpSlot    = nil; pcall(function() LevelUpSlot = RE("PlotService", "LevelUpSlot") end)
local InteractSlot   = nil; pcall(function() InteractSlot = RE("PlotService", "InteractSlot") end)
local EquipUnitRF    = nil; pcall(function() EquipUnitRF = RF("UnitService", "Equip") end)
local UnequipUnitRF  = nil; pcall(function() UnequipUnitRF = RF("UnitService", "Unequip") end)
local RebirthSignal  = nil; pcall(function() RebirthSignal = RE("RebirthService", "Rebirth") end)
local QuestSignal    = nil; pcall(function() QuestSignal = RE("QuestService", "Claim") end)
local BuyDice        = nil; pcall(function() BuyDice = RE("DiceShopService", "BuyDice") end)
local EquipDice      = nil; pcall(function() EquipDice = RE("DiceShopService", "EquipDice") end)
local RollDice       = nil; pcall(function() RollDice = RF("RollService", "RollDice") end)
local SellInventoryRF  = nil; pcall(function() SellInventoryRF = RF("SellService", "SellInventory") end)
local SellEquippedRF   = nil; pcall(function() SellEquippedRF  = RF("SellService", "SellEquipped") end)
local UpdateAutoSellRE = nil; pcall(function() UpdateAutoSellRE = RE("SellService", "UpdateAutoSell") end)
if not UpdateAutoSellRE or not SellInventoryRF then
    pcall(function()
        local ClientComm = require(RS.Packages.Network).ClientComm
        local sComm = ClientComm.new(RS.Network, false, "SellService")
        if not UpdateAutoSellRE then UpdateAutoSellRE = sComm:GetSignal("UpdateAutoSell") end
        if not SellInventoryRF then SellInventoryRF = sComm:GetFunction("SellInventory") end
    end)
end
local BuyUpgrade     = nil; pcall(function() BuyUpgrade = REroot("BuyUpgrade") end)
local CancelTower    = nil; pcall(function() CancelTower = RF("Towers", "CancelTower") end)
local EquipBestTeam  = nil; pcall(function() EquipBestTeam = RE("Towers", "EquipBestTowerTeam") end)
local UseBoost       = nil
pcall(function() UseBoost = RE("BoostService", "Use") end)
if not UseBoost then
    pcall(function()
        local ClientComm = require(RS.Packages.Network).ClientComm
        local bComm = ClientComm.new(RS.Network, false, "BoostService")
        UseBoost = bComm:GetSignal("Use")
    end)
end

local RewardSignals = {
    DailyClaim = nil,
    GroupClaim = nil,
    OfflineClaim = nil
}
pcall(function()
    local ClientComm = require(RS.Packages.Network).ClientComm
    RewardSignals.DailyClaim = ClientComm.new(RS.Network, false, "DailyRewardService"):GetSignal("Claim")
    RewardSignals.GroupClaim = ClientComm.new(RS.Network, false, "GroupRewardService"):GetSignal("Claim")
    RewardSignals.OfflineClaim = ClientComm.new(RS.Network, false, "OfflineEarningsService"):GetSignal("Claim")
end)
if not RewardSignals.DailyClaim then pcall(function() RewardSignals.DailyClaim = RE("DailyRewardService", "Claim") end) end
if not RewardSignals.GroupClaim then pcall(function() RewardSignals.GroupClaim = RE("GroupRewardService", "Claim") end) end
if not RewardSignals.OfflineClaim then pcall(function() RewardSignals.OfflineClaim = RE("OfflineEarningsService", "Claim") end) end

local function fireCommSignal(sig, ...)
    if not sig then return false end
    if type(sig.Fire) == "function" then
        return pcall(function(...) sig:Fire(...) end, ...)
    elseif type(sig.FireServer) == "function" then
        return pcall(function(...) sig:FireServer(...) end, ...)
    end
    return false
end

print("[HUB] Remotes OK")

local UPGRADE_PRICES = {}
local UPGRADE_PARENT = {}
if RealUpgrades then
    for name, data in pairs(RealUpgrades) do
        if name ~= "Start" and data.price then
            UPGRADE_PRICES[name] = data.price
            local parent = RealTreeStructure and RealTreeStructure.GetParent and RealTreeStructure.GetParent(name)
            if parent then UPGRADE_PARENT[name] = parent end
        end
    end
end

local ALL_TOWERS = {}
if RealTowers and type(RealTowers.GetAll) == "function" then
    pcall(function()
        for name, data in pairs(RealTowers.GetAll()) do
            table.insert(ALL_TOWERS, {
                name       = name,
                order      = data.order or 99,
                difficulty = (data.difficulty and data.difficulty.name) or "Normal"
            })
        end
        table.sort(ALL_TOWERS, function(a,b) return a.order < b.order end)
    end)
end

local SelectedTowers = {}

local SKILL_BRANCHES = {
    { name = "Money",        desc = "Money Multiplier (เพิ่มตัวคูณเงิน)" },
    { name = "Luck",         desc = "Luck (เพิ่มค่าโชค)" },
    { name = "Roll Speed",   desc = "Roll Speed (เพิ่มความเร็วการทอย)" },
    { name = "Sell",         desc = "Sell Multiplier (เพิ่มราคาขาย)" },
    { name = "Damage",       desc = "Tower Damage (เพิ่มพลังโจมตี)" },
    { name = "Walkspeed",    desc = "Walkspeed (เพิ่มความเร็วเดิน)" },
    { name = "Unit Storage", desc = "Unit Storage (เพิ่มช่องเก็บยูนิต)" },
    { name = "Health",       desc = "Health (เพิ่มเลือดหอคอย)" },
    { name = "Fortune",      desc = "Fortune (เพิ่มโชค Fortune)" },
}
local SelectedSkills = {}
for _, b in ipairs(SKILL_BRANCHES) do
    SelectedSkills[b.name] = true
end

-- ── Potion & Boost Definitions (Luck / Cash / Damage across 6 Themes) ───────────
local POTION_DATA = {
    ["Luck"] = {
        name = "Luck (เพิ่มค่าโชค)",
        icon = "🍀",
        categories = {
            { id = "Luck",        name = "Standard Luck", sub = "Luck I - IV (1.25x - 4.25x)", items = {"Luck IV", "Luck III", "Luck II", "Luck I"} },
            { id = "Dragon Luck", name = "Dragon Luck",   sub = "Dragon Luck I - III (1.25x - 2.0x)", items = {"Dragon Luck III", "Dragon Luck II", "Dragon Luck I"} },
            { id = "Cursed Luck", name = "Cursed Luck",   sub = "Cursed Luck I - III (1.25x - 2.0x)", items = {"Cursed Luck III", "Cursed Luck II", "Cursed Luck I"} },
            { id = "Pirate Luck", name = "Pirate Luck",   sub = "Pirate Luck I - III (1.5x - 3.0x)", items = {"Pirate Luck III", "Pirate Luck II", "Pirate Luck I"} },
            { id = "Leaf Luck",   name = "Leaf Luck",     sub = "Leaf Luck I - III (2.0x - 4.0x)", items = {"Leaf Luck III", "Leaf Luck II", "Leaf Luck I"} },
            { id = "Slayer Luck", name = "Slayer Luck",   sub = "Slayer Luck I - III (2.0x - 4.0x)", items = {"Slayer Luck III", "Slayer Luck II", "Slayer Luck I"} },
        }
    },
    ["Cash"] = {
        name = "Cash (เพิ่มตัวคูณเงิน)",
        icon = "💰",
        categories = {
            { id = "Income",        name = "Standard Income", sub = "Income I - IV (1.25x - 4.0x)", items = {"Income IV", "Income III", "Income II", "Income I"} },
            { id = "Dragon Income", name = "Dragon Income",   sub = "Dragon Income I - III (1.25x - 2.0x)", items = {"Dragon Income III", "Dragon Income II", "Dragon Income I"} },
            { id = "Cursed Income", name = "Cursed Income",   sub = "Cursed Income I - III (1.25x - 2.0x)", items = {"Cursed Income III", "Cursed Income II", "Cursed Income I"} },
            { id = "Pirate Income", name = "Pirate Income",   sub = "Pirate Income I - III (1.5x - 3.0x)", items = {"Pirate Income III", "Pirate Income II", "Pirate Income I"} },
            { id = "Leaf Income",   name = "Leaf Income",     sub = "Leaf Income I - III (2.0x - 4.0x)", items = {"Leaf Income III", "Leaf Income II", "Leaf Income I"} },
            { id = "Slayer Income", name = "Slayer Income",   sub = "Slayer Income I - III (2.0x - 4.0x)", items = {"Slayer Income III", "Slayer Income II", "Slayer Income I"} },
        }
    },
    ["Damage"] = {
        name = "Damage (เพิ่มพลังโจมตี)",
        icon = "⚔️",
        categories = {
            { id = "Damage",        name = "Standard Damage", sub = "Damage I - IV (1.5x - 5.0x)", items = {"Damage IV", "Damage III", "Damage II", "Damage I"} },
            { id = "Dragon Damage", name = "Dragon Damage",   sub = "Dragon Damage I - III (1.25x - 2.0x)", items = {"Dragon Damage III", "Dragon Damage II", "Dragon Damage I"} },
            { id = "Cursed Damage", name = "Cursed Damage",   sub = "Cursed Damage I - III (1.25x - 2.0x)", items = {"Cursed Damage III", "Cursed Damage II", "Cursed Damage I"} },
            { id = "Pirate Damage", name = "Pirate Damage",   sub = "Pirate Damage I - III (1.5x - 3.0x)", items = {"Pirate Damage III", "Pirate Damage II", "Pirate Damage I"} },
            { id = "Leaf Damage",   name = "Leaf Damage",     sub = "Leaf Damage I - III (2.0x - 4.0x)", items = {"Leaf Damage III", "Leaf Damage II", "Leaf Damage I"} },
            { id = "Slayer Damage", name = "Slayer Damage",   sub = "Slayer Damage I - III (2.0x - 4.0x)", items = {"Slayer Damage III", "Slayer Damage II", "Slayer Damage I"} },
        }
    }
}
local LUCK_CATEGORIES = POTION_DATA["Luck"].categories
local SelectedPotionCategories = {
    ["Luck"] = {},
    ["Cash"] = {},
    ["Damage"] = {}
}
for pType, data in pairs(POTION_DATA) do
    for _, cat in ipairs(data.categories) do
        SelectedPotionCategories[pType][cat.id] = true
    end
end
local SelectedLuckCategories = SelectedPotionCategories["Luck"]

-- ── Constants ─────────────────────────────────────────────────────────────────
-- ── Real-time Auto-Fetch from Game Modules ──────────────────────────────────────
local REBIRTH_COSTS = {}
pcall(function()
    local GameRebirths = require(RS.Framework.Features.Rebirth.Rebirths)
    if GameRebirths and GameRebirths.Get then
        for t = 1, 100 do
            local inf = GameRebirths.Get(t)
            if inf and inf.cost then
                REBIRTH_COSTS[t] = inf.cost
            else
                break
            end
        end
    end
end)
-- Fallback if module failed
if not next(REBIRTH_COSTS) then
    REBIRTH_COSTS = {
        [1]=50000,[2]=5000000,[3]=500000000,[4]=50000000000,
        [5]=5000000000000,[6]=500000000000000,[7]=1e16,
        [8]=1e18,[9]=1e20,[10]=1e22,[11]=1e24,[12]=1e26,[13]=1e28,[14]=1e30,
    }
end

local QUEST_PERIODS = {
    Daily  = {},
    Weekly = {}
}
pcall(function()
    local QC = require(RS.Framework.Features.Quests.QuestConfig)
    if QC and QC.Periods then
        for periodKey, pData in pairs(QC.Periods) do
            QUEST_PERIODS[periodKey] = {}
            if pData.quests then
                for _, q in ipairs(pData.quests) do
                    table.insert(QUEST_PERIODS[periodKey], q.id)
                end
            end
        end
    end
end)
if #QUEST_PERIODS.Daily == 0 then
    QUEST_PERIODS.Daily  = {"Playtime","Rolls","Towers","UnitsSold"}
    QUEST_PERIODS.Weekly = {"Playtime","Rolls","Towers","UnitsSold"}
end

local DICE_LIST = {}
pcall(function()
    local GameDice = require(RS.Framework.Features.Rolling.Dice)
    if GameDice and GameDice.GetAll then
        local all = GameDice.GetAll()
        if all and type(all) == "table" then
            for dName, dData in pairs(all) do
                if dData and dData.luck then
                    table.insert(DICE_LIST, {
                        name  = dName,
                        luck  = tonumber(dData.luck) or 1,
                        price = tonumber(dData.price) or 0
                    })
                end
            end
            table.sort(DICE_LIST, function(a, b) return a.luck > b.luck end)
        end
    end
end)
if #DICE_LIST == 0 then
    DICE_LIST = {
        {name="Radiant",    luck=5000000000, price=1e29},
        {name="Alchemy",    luck=2000000000, price=5e27},
        {name="Frostfire",  luck=950000000,  price=2.5e26},
        {name="Ethereal",   luck=375000000,  price=1e25},
        {name="Toxic",      luck=150000000,  price=7.5e23},
        {name="Cyber",      luck=62500000,   price=1e23},
        {name="Chrono",     luck=25000000,   price=1.5e22},
        {name="Titan",      luck=10000000,   price=1e21},
        {name="Corrupted",  luck=5000000,    price=1.5e20},
        {name="Arcane",     luck=2000000,    price=1.2e19},
        {name="Prismatic",  luck=1000000,    price=1e18},
        {name="Royal",      luck=400000,     price=1e17},
        {name="Dragon",     luck=200000,     price=8.5e15},
        {name="Black Hole", luck=100000,     price=1e15},
        {name="Galaxy",     luck=50000,      price=1.5e14},
        {name="Lunar",      luck=25000,      price=3.75e13},
        {name="Solar",      luck=12500,      price=5e12},
        {name="Void",       luck=6000,       price=7.5e11},
        {name="Blood Moon", luck=3000,       price=1e11},
        {name="Light",      luck=1500,       price=1.2e10},
        {name="Shadow",     luck=750,        price=1.5e9},
        {name="Storm",      luck=400,        price=2e8},
        {name="Magma",      luck=200,        price=3e7},
        {name="Ice",        luck=100,        price=4e6},
        {name="Lightning",  luck=42.5,       price=500000},
        {name="Nature",     luck=20,         price=75000},
        {name="Water",      luck=10,         price=10000},
        {name="Fire",       luck=5,          price=2500},
        {name="Normal",     luck=2,          price=1},
    }
end

local function getGameMaxSlots()
    local maxSlots = 16
    if PlotConfig and PlotConfig.GetMaxSlots then
        pcall(function() maxSlots = PlotConfig.GetMaxSlots() or maxSlots end)
    end
    return maxSlots
end
local SLOT_COUNT = getGameMaxSlots()
local ROLL_DELAY   = 2.6
local COLLECT_LOOP = 1
local EQUIP_LOOP   = 5
local REBIRTH_LOOP = 2
local QUEST_LOOP   = 30
local DICE_LOOP    = 5
local UPGRADE_LOOP = 3
local PLOT_UPGRADE_LOOP = 0.3

CFG = {
    AutoCollect      = false,
    AutoEquip        = false,
    AutoEquipMode    = "Rarity",
    AutoRoll         = false,
    FastAutoRoll     = false,
    RollDelay        = 0.15,
    AutoSellRolled   = false,
    AutoSellThreshold= 1000,
    AutoCleanInventory = true,
    ShowRollCashNotif= true,
    AutoReconnect    = true,
    SkipCutscene     = true,
    AutoRebirth            = false,
    AntiAFK                = true,
    AutoClaimRewards       = false,
    AutoQuest              = false,
    AutoBuyDice            = false,
    AutoEquipDice          = false,
    AutoUpgrade            = false,
    AutoTowerQueue         = false,
    LoopTower              = false,
    EquipTeamBefore        = true,
    AutoUpgradePlot        = false,
    PlotTargetLvl          = 50,
    PlotUpgradeMode        = "Equal",
    BoostFPS               = false,
    Disable3DRender        = false,
    SuperRAMSaver          = false,
    HideGameUI             = false,
    LowDetailMode          = false,
    HideOtherPlayers       = false,
    DisableWeatherFX       = false,
    DisableParticles       = false,
    HidePlotUnits          = false,
    SelectedTeleport       = "MyPlot",
    PotionType             = "Luck",
    AutoUsePotion          = false,
    AutoUseLuck            = false,
    AutoLuckOnEvent        = false,
    WeatherNotifyScreen    = true,
    WeatherNotifyWebhook   = true,
    WebhookUrl             = "",
    WebhookEnabled         = false,
    WebhookNotifyRareUnit  = true,
    WebhookMinRarity       = 100000,
    WebhookNotifyTower     = true,
    WebhookNotifyStats     = false,
    WebhookStatsInterval   = 15,
}

local FONT        = Enum.Font.Gotham
local FONT_BOLD   = Enum.Font.GothamBold
local FONT_MEDIUM = Enum.Font.GothamMedium

-- 540 HUB High-Clarity Dark-Purple Aesthetic Palette
local DARK = {
    bg       = Color3.fromRGB(13, 10, 19),        -- Main background (Deep Dark Purple)
    sidebar  = Color3.fromRGB(16, 12, 24),       -- Sidebar background
    header   = Color3.fromRGB(19, 14, 28),       -- Header top bar
    hAccent  = Color3.fromRGB(175, 55, 255),     -- Vibrant Purple Neon
    banner   = Color3.fromRGB(145, 15, 245),     -- Banner Header color
    item     = Color3.fromRGB(23, 17, 33),       -- Card item background (Better contrast)
    card     = Color3.fromRGB(23, 17, 33),       -- Card item background
    itemSel  = Color3.fromRGB(52, 26, 85),       -- Selected tab / item
    text     = Color3.fromRGB(255, 255, 255),    -- Pure White Text (High Clarity)
    subtext  = Color3.fromRGB(195, 188, 222),    -- Bright Crisp Subtext (High Readability)
    accent   = Color3.fromRGB(175, 55, 255),     -- Accent neon purple
    border   = Color3.fromRGB(50, 36, 72),       -- Crisp Card Border
    tOn      = Color3.fromRGB(175, 55, 255),     -- Toggle ON (Vibrant Purple)
    tOff     = Color3.fromRGB(48, 38, 64),       -- Toggle OFF (Muted dark slate)
    purple   = Color3.fromRGB(175, 55, 255),     -- Neon Purple
    red      = Color3.fromRGB(255, 65, 130),     -- Close button Pinkish-Red
    dropdown = Color3.fromRGB(26, 19, 38),       -- Dropdown menu background
    inputBg  = Color3.fromRGB(36, 28, 52),       -- Input box background
    searchBg = Color3.fromRGB(28, 21, 40),       -- Search bar background
}

-- ── DataController ────────────────────────────────────────────────────────────
local _DC = nil
local function getDC()
    if _DC then return _DC end
    local ok,v = pcall(require, RS.Framework.Features.Data.DataController)
    if ok and v then _DC=v end
    return _DC
end
local function getMoney()
    local DC=getDC(); if DC and DC.Money then return tonumber(DC.Money()) or 0 end; return 0
end
local function getRebirthLevel()
    local DC=getDC(); if DC and DC.Rebirth then return tonumber(DC.Rebirth()) or 0 end; return 0
end

local function syncInGameAutoSell(threshold)
    if UpdateAutoSellRE then
        pcall(function()
            if UpdateAutoSellRE.FireServer then
                UpdateAutoSellRE:FireServer(threshold or 0)
            elseif UpdateAutoSellRE.Fire then
                UpdateAutoSellRE:Fire(threshold or 0)
            end
        end)
    end
end

local function cleanInventoryAutoSell(notify)
    local DC = getDC()
    if not DC or not DC.Inventory or not DC.Slots then return 0 end
    local inv = nil
    pcall(function() inv = DC.Inventory() end)
    if not inv or type(inv) ~= "table" then return 0 end
    local slots = nil
    pcall(function() slots = DC.Slots() end)
    if not slots or type(slots) ~= "table" then slots = {} end

    local equippedKeys = {}
    if slots and type(slots) == "table" then
        for _, sData in pairs(slots) do
            if type(sData) == "table" and sData.unitId then
                equippedKeys[sData.unitId] = true
            elseif type(sData) == "string" then
                equippedKeys[sData] = true
            end
        end
    end

    local threshold = CFG.AutoSellThreshold or 1000
    local keysToSell = {}
    for key, item in pairs(inv) do
        if item and item.name and not equippedKeys[key] then
            local r = getUnitRarity(item)
            local isLocked = item.locked == true or item.favorite == true
            if not isLocked and r and r <= threshold then
                table.insert(keysToSell, key)
            end
        end
    end

    if #keysToSell > 0 and SellInventoryRF then
        local ok, gained = pcall(function()
            return SellInventoryRF:InvokeServer(keysToSell)
        end)
        if ok and gained and gained > 0 then
            if notify then
                showNotif(string.format("💰 ขายยูนิตอัตโนมัติ %d ตัว (+%s Cash)", #keysToSell, formatNumberCompact(gained)))
            end
            return gained
        end
    end
    return 0
end

-- ── Discord Webhook System ───────────────────────────────────────────────────
local function getHttpRequestFunc()
    if syn and type(syn.request) == "function" then return syn.request end
    if http and type(http.request) == "function" then return http.request end
    if type(http_request) == "function" then return http_request end
    if type(request) == "function" then return request end
    return nil
end

local function sendDiscordWebhook(url, payload)
    if not url or url == "" then return false, "Webhook URL is empty" end
    if not url:find("discord%.com/api/webhooks") and not url:find("discordapp%.com/api/webhooks") then
        return false, "Invalid Discord Webhook URL"
    end
    local req = getHttpRequestFunc()
    if not req then return false, "Executor does not support HTTP requests" end

    local okEnc, body = pcall(function() return HttpService:JSONEncode(payload) end)
    if not okEnc or not body then return false, "Failed to encode JSON payload" end

    local ok, res = pcall(function()
        return req({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    end)

    if ok and res then
        local code = res.StatusCode or res.status_code
        if code and (code >= 200 and code < 300 or code == 204) then
            return true, "Success"
        else
            return false, "HTTP Error " .. tostring(code)
        end
    end
    return false, tostring(res)
end

local function formatNumberCompact(n)
    if not n or type(n) ~= "number" then return tostring(n or 0) end
    if n >= 1e18 then return string.format("%.2fQi", n / 1e18)
    elseif n >= 1e15 then return string.format("%.2fQa", n / 1e15)
    elseif n >= 1e12 then return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n / 1e3)
    else return tostring(math.floor(n)) end
end

local function sendTestWebhook()
    local url = CFG.WebhookUrl
    if not url or url == "" then
        showNotif("⚠️ กรุณาใส่ Webhook URL ก่อนกดทดสอบ")
        return false
    end
    local payload = {
        username = "CHEAT HUB v24",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {
            {
                title = "🔔 Discord Webhook Test",
                description = "การเชื่อมต่อ Discord Webhook สำเร็จเรียบร้อย พร้อมรับการแจ้งเตือนจาก CHEAT HUB v24 แล้ว!",
                color = 0x8A2BE2,
                fields = {
                    { name = "👤 Player", value = LP.Name .. " (" .. LP.DisplayName .. ")", inline = true },
                    { name = "🆔 User ID", value = tostring(LP.UserId), inline = true },
                    { name = "⚡ Status", value = "Connected & Active ✓", inline = true }
                },
                footer = { text = "CHEAT HUB v24 · Automated System" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    local ok, msg = sendDiscordWebhook(url, payload)
    if ok then
        showNotif("✅ ส่งข้อความทดสอบเข้า Discord สำเร็จแล้ว!")
        return true
    else
        showNotif("❌ ส่งไม่สำเร็จ: " .. tostring(msg))
        return false
    end
end

local function sendRareUnitWebhook(unitName, mutation, chance)
    if not CFG.WebhookEnabled or not CFG.WebhookNotifyRareUnit then return end
    local url = CFG.WebhookUrl
    if not url or url == "" then return end

    local mutationStr = mutation and (" (" .. tostring(mutation) .. ")") or ""
    local chanceStr = "1 in " .. formatNumberCompact(chance)

    local payload = {
        username = "CHEAT HUB v24",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {
            {
                title = "🔥 Rare Unit Rolled!",
                description = string.format("ยินดีด้วย! คุณเพิ่งทอยได้ยูนิตหายาก **%s%s**!", unitName, mutationStr),
                color = 0xF59E0B,
                fields = {
                    { name = "👤 Player", value = LP.Name .. " (" .. LP.DisplayName .. ")", inline = true },
                    { name = "🎲 Unit", value = "**" .. unitName .. "**" .. mutationStr, inline = true },
                    { name = "✨ Rarity", value = "**" .. chanceStr .. "**", inline = true },
                    { name = "💰 Money", value = "$" .. formatNumberCompact(getMoney()), inline = true },
                    { name = "🔄 Rebirth", value = "Tier " .. tostring(getRebirthLevel()), inline = true }
                },
                footer = { text = "CHEAT HUB v24 · Rare Alert" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    task.spawn(sendDiscordWebhook, url, payload)
end

local function sendTowerWebhook(towerName, floor, loopCount)
    if not CFG.WebhookEnabled or not CFG.WebhookNotifyTower then return end
    local url = CFG.WebhookUrl
    if not url or url == "" then return end

    local loopStr = loopCount and string.format("Round #%d", loopCount) or "1 Round"
    local payload = {
        username = "CHEAT HUB v24",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {
            {
                title = "🏰 Tower Completed!",
                description = string.format("การลงหอคอย **%s** จบลงเรียบร้อยแล้ว!", towerName),
                color = 0x8B5CF6,
                fields = {
                    { name = "👤 Player", value = LP.Name .. " (" .. LP.DisplayName .. ")", inline = true },
                    { name = "🏰 Tower Name", value = towerName, inline = true },
                    { name = "🏆 Highest Floor", value = "Floor " .. tostring(floor), inline = true },
                    { name = "🔁 Tower Loop", value = loopStr, inline = true },
                    { name = "💰 Current Money", value = "$" .. formatNumberCompact(getMoney()), inline = true },
                    { name = "🔄 Rebirth", value = "Tier " .. tostring(getRebirthLevel()), inline = true }
                },
                footer = { text = "CHEAT HUB v24 · Tower Report" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    task.spawn(sendDiscordWebhook, url, payload)
end

local function sendWeatherWebhook(eventName, multiplierText, duration)
    if not CFG.WebhookEnabled or not CFG.WeatherNotifyWebhook then return end
    local url = CFG.WebhookUrl
    if not url or url == "" then return end

    local color = 0x10B981
    if eventName:find("Cash") then
        color = 0xF59E0B
    elseif eventName:find("Speed") then
        color = 0x06B6D4
    end

    local payload = {
        username = "CHEAT HUB v24",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {
            {
                title = "🌦️ [WEATHER EVENT] ตรวจพบสภาพอากาศพิเศษ!",
                description = string.format("สภาพอากาศพิเศษ **%s** กำลังทำงานในเซิร์ฟเวอร์!", eventName),
                color = color,
                fields = {
                    { name = "👤 ผู้เล่น", value = LP.Name .. " (" .. LP.DisplayName .. ")", inline = true },
                    { name = "⚡ สภาพอากาศ", value = "**" .. eventName .. "**", inline = true },
                    { name = "📊 บัฟที่ได้รับ", value = multiplierText or "โชค/เงินพิเศษ", inline = true },
                    { name = "⏳ ระยะเวลา", value = tostring(duration or 0) .. " วินาที", inline = true },
                    { name = "🌐 Job ID", value = string.format("`%s`", tostring(game.JobId)), inline = false }
                },
                footer = { text = "CHEAT HUB v24 · Weather Tracker" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    task.spawn(sendDiscordWebhook, url, payload)
end

local function sendRewardWebhook(rewardName, rewardDetail)
    if not CFG.WebhookEnabled then return end
    local url = CFG.WebhookUrl
    if not url or url == "" then return end

    local payload = {
        username = "CHEAT HUB v24",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {
            {
                title = "🎁 [REWARDS] รับของรางวัลฟรีสำเร็จ!",
                description = string.format("ผู้เล่น **%s** ได้รับของรางวัลฟรี: **%s**", LP.Name, rewardName),
                color = 0x3B82F6,
                fields = {
                    { name = "🎁 ประเภทรางวัล", value = rewardName, inline = true },
                    { name = "📋 รายละเอียด", value = rewardDetail or "สำเร็จ", inline = true },
                    { name = "💰 เงินปัจจุบัน", value = "$" .. formatNumberCompact(getMoney()), inline = true }
                },
                footer = { text = "CHEAT HUB v24 · Auto Rewards" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    task.spawn(sendDiscordWebhook, url, payload)
end

local function sendStatsWebhook()
    if not CFG.WebhookEnabled or not CFG.WebhookNotifyStats then return end
    local url = CFG.WebhookUrl
    if not url or url == "" then return end

    local DC = getDC()
    local diceName = "Default"
    if DC and DC.Dice then
        pcall(function() diceName = tostring(DC.Dice()) end)
    end

    local payload = {
        username = "CHEAT HUB v24",
        avatar_url = "https://i.imgur.com/4M34hi2.png",
        embeds = {
            {
                title = "📊 AFK Farm Stats Summary",
                description = "รายงานสถานะความคืบหน้าการฟาร์มปัจจุบันของคุณ",
                color = 0x3B82F6,
                fields = {
                    { name = "👤 Player", value = LP.Name .. " (" .. LP.DisplayName .. ")", inline = true },
                    { name = "💰 Money", value = "$" .. formatNumberCompact(getMoney()), inline = true },
                    { name = "🔄 Rebirth", value = "Tier " .. tostring(getRebirthLevel()), inline = true },
                    { name = "🎲 Current Dice", value = diceName, inline = true }
                },
                footer = { text = "CHEAT HUB v24 · Periodic Report" },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    task.spawn(sendDiscordWebhook, url, payload)
end

local function checkRollWebhook(res)
    if not CFG.WebhookEnabled or not CFG.WebhookNotifyRareUnit then return end
    if not res or type(res) ~= "table" then return end
    for _, item in ipairs(res) do
        if type(item) == "table" and item.result then
            local unitName = item.result
            local mutation = item.mutation
            local chance = 0
            if EntryRegistry and EntryRegistry.getEntryConfig then
                local ok, cfg = pcall(function() return EntryRegistry.getEntryConfig(unitName) end)
                if ok and cfg and cfg.chance then
                    pcall(function() chance = cfg.chance({ mutation = mutation }) end)
                end
            end
            if chance == 0 then
                chance = getUnitRarity({ name = unitName, attributes = { mutation = mutation } })
            end

            local minChance = CFG.WebhookMinRarity or 100000
            if chance >= minChance then
                sendRareUnitWebhook(unitName, mutation, chance)
            end
        end
    end
end

-- ── Cheat functions ───────────────────────────────────────────────────────────
local function collectAll()
    local maxS = getGameMaxSlots()
    for s=1,maxS do
        task.spawn(function() pcall(function() CollectBalance:FireServer(s) end) end)
    end
end

local function tryRebirth()
    local c=REBIRTH_COSTS[getRebirthLevel()+1]; if not c then return end
    if getMoney()>=c then pcall(function() RebirthSignal:FireServer() end) end
end

local function claimAllQuests()
    local DC=getDC(); if not DC then return end
    for period, ids in pairs(QUEST_PERIODS) do
        local qd; pcall(function() qd=DC.Quests[period]() end)
        if not qd then continue end
        for _, id in ipairs(ids) do
            if not (qd.claimed or {})[id] then
                pcall(function() QuestSignal:FireServer(period,id,qd.expiresAt or 0) end)
                task.wait(0.25)
            end
        end
    end
end

local function claimDailyReward(manual)
    local DC = getDC(); if not DC then return false end
    local lastClaim = 0
    pcall(function() lastClaim = DC.LastDailyRewardClaim and DC.LastDailyRewardClaim() or 0 end)
    local isReady = (lastClaim == 0) or (os.time() - lastClaim >= 82800)
    if isReady then
        fireCommSignal(RewardSignals.DailyClaim)
        local claimedIdx = 1
        pcall(function() claimedIdx = (DC.DailyRewardsClaimed and DC.DailyRewardsClaimed() or 0) + 1 end)
        showNotif("🎁 รับรางวัลรายวัน (Day " .. tostring(claimedIdx) .. ") เรียบร้อย ✓")
        print("[REWARDS] Claimed Daily Reward Day " .. tostring(claimedIdx))
        pcall(sendRewardWebhook, "Daily Reward (Day " .. tostring(claimedIdx) .. ")", "รับรางวัลล็อกอินประจำวันสำเร็จ")
        return true
    elseif manual then
        local waitSec = math.max(0, 82800 - (os.time() - lastClaim))
        local h = math.floor(waitSec / 3600)
        local m = math.floor((waitSec % 3600) / 60)
        showNotif(string.format("⏳ รางวัลรายวันยังไม่พร้อม (รออีก %d ชม. %d นาที)", h, m))
    end
    return false
end

local function claimGroupReward(manual)
    local DC = getDC(); if not DC then return false end
    local alreadyClaimed = false
    pcall(function() alreadyClaimed = DC.ClaimedGroupReward and DC.ClaimedGroupReward() end)
    if not alreadyClaimed then
        fireCommSignal(RewardSignals.GroupClaim)
        showNotif("👥 รับของรางวัลกลุ่ม (Group Chest) เรียบร้อย ✓")
        print("[REWARDS] Claimed Group Chest Reward")
        pcall(sendRewardWebhook, "Group Chest", "รับของรางวัลกล่องกลุ่มเรียบร้อย")
        return true
    elseif manual then
        showNotif("ℹ️ รับของรางวัลกลุ่มไปแล้ว")
    end
    return false
end

local function claimOfflineEarnings(manual)
    local DC = getDC(); if not DC then return false end
    local pending = 0
    pcall(function() pending = DC.PendingOfflineEarnings and DC.PendingOfflineEarnings() or 0 end)
    if pending and pending > 0 then
        fireCommSignal(RewardSignals.OfflineClaim)
        local formatted = formatNumberCompact(pending)
        showNotif("💰 รับเงินออฟไลน์ $" .. formatted .. " เรียบร้อย ✓")
        print("[REWARDS] Claimed Offline Earnings: $" .. tostring(pending))
        pcall(sendRewardWebhook, "Offline Earnings", "รับเงินสะสมออฟไลน์ $" .. formatted)
        return true
    elseif manual then
        showNotif("ℹ️ ไม่มีเงินออฟไลน์คงค้างในขณะนี้")
    end
    return false
end

local function claimAllFreeRewards(manual)
    local anyClaimed = false
    if claimDailyReward(manual) then anyClaimed = true task.wait(0.3) end
    if claimGroupReward(manual) then anyClaimed = true task.wait(0.3) end
    if claimOfflineEarnings(manual) then anyClaimed = true task.wait(0.3) end
    if CFG.AutoQuest then claimAllQuests() end
    if manual and not anyClaimed then
        showNotif("✓ ตรวจสอบแล้ว: ไม่มีรางวัลฟรีที่ค้างรับในขณะนี้")
    end
end

local function getBestDice(DC)
    local money=getMoney()
    local bestOwned,bestBuyable=nil,nil
    for _, d in ipairs(DICE_LIST) do
        local owned=DC and DC.OwnedDice and DC.OwnedDice[d.name] and DC.OwnedDice[d.name]()
        if owned==true then
            if not bestOwned then bestOwned=d end
        elseif d.price and money>=d.price then
            if not bestBuyable then bestBuyable=d end
        end
    end
    return bestOwned,bestBuyable
end

local function autoDice()
    local DC=getDC(); if not DC then return end
    local bestOwned,bestBuyable=getBestDice(DC)
    if CFG.AutoBuyDice and bestBuyable then
        local shouldBuy=not bestOwned or bestBuyable.luck>bestOwned.luck
        if shouldBuy then
            pcall(function() BuyDice:FireServer(bestBuyable.name) end)
            task.wait(0.6); _DC=nil
            DC=getDC(); bestOwned,_=getBestDice(DC)
        end
    end
    if CFG.AutoEquipDice and bestOwned then
        local cur; pcall(function() cur=DC.Dice() end)
        if cur~=bestOwned.name then
            pcall(function() EquipDice:FireServer(bestOwned.name) end)
        end
    end
end

local _isEquippingRarity = false

local function getUnitRarity(unit)
    if not unit or not unit.name then return 0 end
    if not EntryRegistry then
        pcall(function() EntryRegistry = require(RS.Framework.Features.Inventory.EntryRegistry) end)
    end
    if not EntryRegistry or not EntryRegistry.getEntryConfig then return 0 end
    local cfg = nil
    pcall(function() cfg = EntryRegistry.getEntryConfig(unit.name) end)
    if not cfg or cfg.kind ~= "Unit" then return 0 end
    if cfg.chance then
        local ok, ch = pcall(cfg.chance, unit.attributes or {})
        if ok and typeof(ch) == "number" and ch > 0 then
            return ch
        end
    end
    if cfg.income then
        local ok, inc = pcall(cfg.income, unit.attributes or {})
        if ok and typeof(inc) == "number" and inc > 0 then
            return inc ^ 1.3793103448275863
        end
    end
    return 0
end

local function getUnitIncome(unit)
    if not unit or not unit.name then return 0 end
    if not EntryRegistry then
        pcall(function() EntryRegistry = require(RS.Framework.Features.Inventory.EntryRegistry) end)
    end
    if not EntryRegistry or not EntryRegistry.getEntryConfig then return 0 end
    local cfg = nil
    pcall(function() cfg = EntryRegistry.getEntryConfig(unit.name) end)
    if not cfg or cfg.kind ~= "Unit" or not cfg.income then return 0 end
    local ok, inc = pcall(cfg.income, unit.attributes or {})
    if ok and typeof(inc) == "number" then
        return inc
    end
    return 0
end

local function equipBestByRarity(notify)
    if _isEquippingRarity then
        if notify then showNotif("กำลังจัดยูนิตอยู่ กรุณารอสักครู่...") end
        return
    end
    _isEquippingRarity = true

    task.spawn(function()
        local ok, err = pcall(function()
            local DC = getDC()
            if not DC then
                if notify then showNotif("ไม่สามารถโหลด DataController ได้") end
                return
            end
            if not DC.Inventory or not DC.Slots then
                if notify then showNotif("ไม่พบข้อมูล Inventory หรือ Slots") end
                return
            end
            local inv = nil
            pcall(function() inv = DC.Inventory() end)
            if not inv or type(inv) ~= "table" then
                if notify then showNotif("กระเป๋าว่างเปล่า หรือยังโหลดไม่เสร็จ") end
                return
            end

            local reb = getRebirthLevel()
            local unlocked = {}
            local maxS = getGameMaxSlots()
            for s = 1, maxS do
                local req = 0
                if PlotConfig and PlotConfig.GetSlotRebirthRequirement then
                    pcall(function() req = PlotConfig.GetSlotRebirthRequirement(s) or 0 end)
                end
                if reb >= req then
                    table.insert(unlocked, s)
                end
            end
            if #unlocked == 0 then
                if notify then showNotif("ไม่พบ Slot ที่ปลดล็อก") end
                return
            end

            local allUnits = {}
            for key, item in pairs(inv) do
                if item and item.name and (item.amount or 1) > 0 then
                    local r = getUnitRarity(item)
                    local inc = getUnitIncome(item)
                    table.insert(allUnits, {
                        key = key,
                        name = item.name,
                        rarity = r,
                        income = inc
                    })
                end
            end

            if #allUnits == 0 then
                if notify then showNotif("ไม่พบยูนิตในกระเป๋า") end
                return
            end

            table.sort(allUnits, function(a, b)
                if a.rarity == b.rarity then
                    return a.income > b.income
                end
                return a.rarity > b.rarity
            end)

            local maxEquip = math.min(#unlocked, #allUnits)
            local topUnits = {}
            local topKeys = {}
            for i = 1, maxEquip do
                table.insert(topUnits, allUnits[i])
                topKeys[allUnits[i].key] = true
            end

            local curSlots = {}
            local curKeys = {}
            for _, s in ipairs(unlocked) do
                local sData = nil
                pcall(function() sData = DC.Slots[tostring(s)]() end)
                if sData and sData.unitId then
                    curSlots[s] = sData.unitId
                    curKeys[sData.unitId] = true
                end
            end

            local needed = {}
            for _, u in ipairs(topUnits) do
                if not curKeys[u.key] then
                    table.insert(needed, u)
                end
            end

            if #needed == 0 then
                if notify then showNotif("ยูนิตที่หายากที่สุดถูกสวมใส่ใน Plot ครบแล้ว ✓") end
                return
            end

            if notify then
                showNotif("กำลังจัดยูนิตตามความหายาก (1 in X) " .. #needed .. " ตัว...")
            end

            local targetSlots = {}
            for _, s in ipairs(unlocked) do
                local curKey = curSlots[s]
                if not curKey or not topKeys[curKey] then
                    table.insert(targetSlots, s)
                end
            end

            if not UnitController then
                pcall(function() UnitController = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitController) end)
            end

            for i = 1, math.min(#needed, #targetSlots) do
                local u = needed[i]
                local s = targetSlots[i]

                local equipped = false
                if EquipUnitRF then
                    local success, res = pcall(function() return EquipUnitRF:InvokeServer(u.key) end)
                    if success and res ~= false then equipped = true end
                end
                if not equipped and UnitController and UnitController.Equip then
                    pcall(UnitController.Equip, u.key)
                end
                task.wait(0.55)

                if InteractSlot then
                    pcall(function() InteractSlot:FireServer(s) end)
                end
                task.wait(0.55)
            end

            if UnequipUnitRF then
                pcall(function() UnequipUnitRF:InvokeServer() end)
            elseif UnitController and UnitController.Unequip then
                pcall(UnitController.Unequip)
            end

            if notify then
                showNotif("จัดวางยูนิตหายากที่สุด (1 in X) สำเร็จเรียบร้อย ✓")
            end
        end)

        if not ok then
            warn("[EquipRarity Error]", err)
            if notify then showNotif("เกิดข้อผิดพลาด: " .. tostring(err)) end
        end
        _isEquippingRarity = false
    end)
end

local function getSlotUpgradeInfo(s)
    local DC = getDC()
    if not DC or not DC.Slots or not DC.Inventory then return nil end
    local slotGetter = DC.Slots[tostring(s)]
    if not slotGetter then return nil end
    local slotData = slotGetter()
    if not slotData or not slotData.unitId then return nil end
    local invGetter = DC.Inventory[slotData.unitId]
    if not invGetter then return nil end
    local unit = invGetter()
    if not unit or not unit.attributes then return nil end
    local lvl = unit.attributes.level or 1
    local price = nil
    if UnitUtil and UnitUtil.GetLevelPrice then
        pcall(function() price = UnitUtil.GetLevelPrice(unit.name, unit.attributes) end)
    end
    return lvl, price, unit
end

local function autoUpgradePlots()
    local targetLvl = tonumber(CFG.PlotTargetLvl) or 50
    local money = getMoney()
    local DC = getDC()
    if not DC then return end

    local maxS = getGameMaxSlots()
    local candidates = {}
    for s = 1, maxS do
        local unlocked = true
        if PlotConfig and PlotConfig.GetSlotRebirthRequirement then
            unlocked = (getRebirthLevel() >= PlotConfig.GetSlotRebirthRequirement(s))
        end
        if unlocked then
            local lvl, price = getSlotUpgradeInfo(s)
            if lvl and lvl < targetLvl then
                table.insert(candidates, { slot = s, level = lvl, price = price })
            end
        end
    end

    if #candidates == 0 then return end

    if CFG.PlotUpgradeMode == "Single" then
        table.sort(candidates, function(a, b)
            if a.level ~= b.level then return a.level > b.level end
            return a.slot < b.slot
        end)
    else
        table.sort(candidates, function(a, b)
            if a.level ~= b.level then return a.level < b.level end
            return a.slot < b.slot
        end)
    end

    local target = candidates[1]
    if target and (not target.price or money >= target.price) then
        pcall(function() LevelUpSlot:FireServer(target.slot) end)
    end
end

local function autoUpgradeSkillTree()
    local DC=getDC(); if not DC then return end
    local money=getMoney()
    if money<=0 then return end
    for upgName, price in pairs(UPGRADE_PRICES) do
        if money<price then continue end
        local allowed = false
        for _, branch in ipairs(SKILL_BRANCHES) do
            if SelectedSkills[branch.name] and upgName:sub(1, #branch.name) == branch.name then
                allowed = true
                break
            end
        end
        if not allowed then continue end

        local alreadyOwned; pcall(function() alreadyOwned=DC.Upgrades[upgName]() end)
        if alreadyOwned then continue end
        local parent=UPGRADE_PARENT[upgName]
        if parent and parent~="Start" then
            local parentOwned; pcall(function() parentOwned=DC.Upgrades[parent]() end)
            if not parentOwned then continue end
        end
        pcall(function() BuyUpgrade:FireServer(upgName) end)
        money=money-price; task.wait(0.15)
        if money<=0 then break end
    end
end

-- ── Tower Logic ───────────────────────────────────────────────────────────────
local tBannerTitle, tBannerSub, towerRunBtn
local isTowerBusy = false

local function setBanner(title, sub)
    task.spawn(function()
        pcall(function()
            if title and tBannerTitle then tBannerTitle.Text = tostring(title) end
            if sub and tBannerSub then tBannerSub.Text = tostring(sub) end
        end)
    end)
end

local function updateRunBtnText()
    task.spawn(function()
        pcall(function()
            if not towerRunBtn then return end
            if isTowerBusy then
                towerRunBtn.BackgroundColor3 = DARK.red
                towerRunBtn.Text = "⏹ Cancel Tower Queue"
            else
                towerRunBtn.BackgroundColor3 = DARK.purple
                if CFG.LoopTower then
                    towerRunBtn.Text = "▶ Start Selected Towers (Loop Mode)"
                else
                    towerRunBtn.Text = "▶ Start Selected Towers (1 Run Each)"
                end
            end
        end)
    end)
end

pcall(function()
    if TowerScreen then
        TowerScreen:GetPropertyChangedSignal("Visible"):Connect(function()
            if CFG.AutoTowerQueue and TowerScreen.Visible then
                TowerScreen.Visible = false
                pcall(function() HUDController.showAll("inTower") end)
            end
        end)
    end
end)

pcall(function()
    if TowerBg then
        TowerBg:GetPropertyChangedSignal("Visible"):Connect(function()
            if CFG.AutoTowerQueue and TowerBg.Visible then
                TowerBg.Visible = false
            end
        end)
    end
end)

pcall(function()
    if HiddenBtn then
        HiddenBtn:GetPropertyChangedSignal("Position"):Connect(function()
            if CFG.AutoTowerQueue and HiddenBtn.Position ~= UDim2.new(0, -9999, 0, -9999) then
                HiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
            end
        end)
    end
end)

-- Continuous enforcer: Keep Tower UI hidden & HUD visible during AutoTowerQueue
pcall(function()
    RunService.RenderStepped:Connect(function()
        if CFG.AutoTowerQueue then
            if TowerScreen and TowerScreen.Visible then TowerScreen.Visible = false end
            if TowerBg and TowerBg.Visible then TowerBg.Visible = false end
            if HiddenBtn and HiddenBtn.Position ~= UDim2.new(0, -9999, 0, -9999) then
                HiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
            end
            local tr = UIReferences and UIReferences.Menus and UIReferences.Menus:FindFirstChild("TowerRewards")
            if tr and tr.Visible then tr.Visible = false end
            pcall(function()
                if HUDController and HUDController.isHidden and HUDController.isHidden(UIReferences.HUD.Bottom) then
                    HUDController.showAll("inTower")
                end
            end)
        end
    end)
end)

local function getTowerActiveState()
    local guvs = getupvalues or (debug and debug.getupvalues)
    if guvs and TowerCtrl and TowerCtrl.startTower then
        local ok, uvs = pcall(guvs, TowerCtrl.startTower)
        if ok and type(uvs) == "table" then
            if type(uvs[1]) == "boolean" then
                return uvs[1]
            end
            for _, v in pairs(uvs) do
                if type(v) == "boolean" then
                    return v
                end
            end
        end
    end
    local guv = getupvalue or (debug and debug.getupvalue)
    if guv and TowerCtrl and TowerCtrl.startTower then
        local ok, val = pcall(guv, TowerCtrl.startTower, 1)
        if ok and type(val) == "boolean" then
            return val
        end
    end

    if HiddenBtn and HiddenBtn:FindFirstChild("Label") and HiddenBtn.Label:IsA("TextLabel") then
        local txt = HiddenBtn.Label.Text
        if txt == "Hide" and (not TowerScreen or not TowerScreen.Visible) then
            return false
        elseif txt:match("Floor%s*%d+") then
            return true
        end
    end

    if TowerScreen and TowerScreen.Visible then
        return true
    end

    return nil
end

local function runSingleTower(towerName, curIndex, totalCount, loopCount)
    if not CFG.AutoTowerQueue then return false end

    if CFG.EquipTeamBefore then
        pcall(function() EquipBestTeam:FireServer() end)
        task.wait(1.0)
    end

    pcall(function()
        local MenuController = require(RS.Framework.Features.UI.MenuController)
        local tr = UIReferences and UIReferences.Menus and UIReferences.Menus.TowerRewards
        local pt = UIReferences and UIReferences.Root and UIReferences.Root.Menus and UIReferences.Root.Menus.PlayTower
        local active = MenuController and MenuController.ActiveMenu and MenuController.ActiveMenu()
        if active and (active == tr or active == pt) then
            MenuController.CloseMenu()
        end
    end)

    if TowerScreen then TowerScreen.Visible = false end
    if TowerBg then TowerBg.Visible = false end

    local loopStr = CFG.LoopTower and string.format("Loop #%d · ", loopCount) or ""

    if getTowerActiveState() == true then
        print(string.format("[TOWER] ตรวจพบหอคอยกำลังทำงานอยู่ รอให้รอบก่อนหน้าจบก่อน..."))
        setBanner(string.format("⚔️ [%d/%d] %s", curIndex, totalCount, towerName), loopStr .. "มีหอคอยทำงานอยู่ กำลังรอให้จบ...")
        local waitDeadline = tick() + 1800
        while CFG.AutoTowerQueue and getTowerActiveState() == true and tick() < waitDeadline do
            task.wait(1.5)
        end
        task.wait(4.0)
    end

    setBanner(string.format("⚔️ [%d/%d] %s", curIndex, totalCount, towerName), loopStr .. "กำลังรอเริ่มหอคอย...")

    local started = false
    for attempt = 1, 12 do
        if not CFG.AutoTowerQueue then return false end
        local su = setupvalue or (debug and debug.setupvalue)
        local guv = getupvalue or (debug and debug.getupvalue)
        if guv and su and TowerCtrl and TowerCtrl.startTower then
            pcall(function()
                local towerStartedFn = guv(TowerCtrl.startTower, 8)
                if towerStartedFn then
                    pcall(su, towerStartedFn, 1, true)
                end
            end)
        end
        local ok, res = pcall(function() return TowerCtrl.startTower(towerName) end)
        if ok and res == true then
            started = true
            break
        end
        print(string.format("[TOWER] รอความพร้อมเซิร์ฟเวอร์สำหรับ %s (ครั้งที่ %d/12)...", towerName, attempt))
        task.wait(3.0)
    end

    if not started then
        print("[TOWER] ไม่สามารถเริ่มได้หลังจากพยายามหลายครั้ง:", towerName)
        showNotif("⚠️ เริ่ม " .. towerName .. " ไม่สำเร็จ (ข้ามไปยังหอคอยถัดไป)")
        task.wait(2.0)
        return false
    end

    print("[TOWER] เริ่มหอคอยสำเร็จ:", towerName)
    setBanner(nil, loopStr .. "Floor 1 · กำลังต่อสู้...")

    local towerStartTime = tick()

    task.spawn(function()
        local su = setupvalue or (debug and debug.setupvalue)
        local guv = getupvalue or (debug and debug.getupvalue)
        if guv and su and TowerCtrl and TowerCtrl.startTower then
            pcall(function()
                local towerStartedFn = guv(TowerCtrl.startTower, 8)
                if towerStartedFn then
                    pcall(su, towerStartedFn, 2, true)
                end
            end)
        end

        task.wait(0.15)
        for _ = 1, 20 do
            if HiddenBtn and HiddenBtn:FindFirstChild("Label") and HiddenBtn.Label:IsA("TextLabel") then
                if HiddenBtn.Label.Text == "Hide" then
                    if firesignal then
                        pcall(firesignal, HiddenBtn.Activated)
                    elseif HiddenBtn.Activate then
                        pcall(function() HiddenBtn:Activate() end)
                    end
                    task.wait(0.2)
                    if HiddenBtn.Label.Text ~= "Hide" then
                        break
                    end
                elseif HiddenBtn.Label.Text:match("Floor") then
                    break
                end
            end
            task.wait(0.1)
        end

        pcall(function()
            HUDController.showAll("inTower")
            if TowerScreen then TowerScreen.Visible = false end
            if TowerBg then TowerBg.Visible = false end
            if HiddenBtn then HiddenBtn.Position = UDim2.new(0, -9999, 0, -9999) end
        end)
    end)

    task.wait(2.5)

    local deadline = tick() + 3600
    local finishConfirmCount = 0
    local lastSeenFloor = 1
    local lastFloorTime = tick()
    local everActive = true

    while CFG.AutoTowerQueue and tick() < deadline do
        local ctrlState = getTowerActiveState()
        if ctrlState == true then
            everActive = true
            finishConfirmCount = 0
        end

        local currentFloor = nil
        if TowerScreen and TowerScreen:FindFirstChild("Floor") and TowerScreen.Floor:IsA("TextLabel") then
            currentFloor = TowerScreen.Floor.Text:match("Floor%s*(%d+)")
        end
        if not currentFloor and HiddenBtn and HiddenBtn:FindFirstChild("Label") and HiddenBtn.Label:IsA("TextLabel") then
            currentFloor = HiddenBtn.Label.Text:match("Floor%s*(%d+)")
        end

        if currentFloor then
            local fNum = tonumber(currentFloor)
            if fNum and fNum ~= lastSeenFloor then
                lastSeenFloor = fNum
                lastFloorTime = tick()
                finishConfirmCount = 0
                setBanner(nil, string.format("%sFloor %d · กำลังต่อสู้...", loopStr, fNum))
            end
        end

        local rewardsOpen = false
        pcall(function()
            local tr = UIReferences and UIReferences.Menus and UIReferences.Menus.TowerRewards
            if tr and tr.Visible then rewardsOpen = true end
        end)

        if rewardsOpen then
            task.spawn(function()
                pcall(function()
                    local MenuController = require(RS.Framework.Features.UI.MenuController)
                    local tr = UIReferences and UIReferences.Menus and UIReferences.Menus.TowerRewards
                    if MenuController and MenuController.ActiveMenu and MenuController.ActiveMenu() == tr then
                        MenuController.CloseMenu()
                    end
                end)
            end)
            break
        end

        if _towerFinishedSignal and _towerFinishedSignal > towerStartTime then
            print(string.format("[TOWER] จบการลงจากการแจ้งเตือนของเกม (Floor สูงสุด: %d)", lastSeenFloor or 1))
            break
        end

        if ctrlState == false and everActive then
            break
        elseif ctrlState == nil then
            local isEndedByText = false
            if HiddenBtn and HiddenBtn:FindFirstChild("Label") and HiddenBtn.Label:IsA("TextLabel") then
                if HiddenBtn.Label.Text == "Hide" and everActive and (tick() - lastFloorTime >= 5) then
                    isEndedByText = true
                end
            end

            if isEndedByText then
                break
            end

            if tick() - lastFloorTime >= 90 then
                finishConfirmCount = finishConfirmCount + 1
                if finishConfirmCount >= 5 then
                    break
                end
            else
                finishConfirmCount = 0
            end
        end

        task.wait(1.0)
    end

    if not CFG.AutoTowerQueue then
        pcall(function() CancelTower:InvokeServer() end)
    end

    task.spawn(function()
        pcall(function()
            local MenuController = require(RS.Framework.Features.UI.MenuController)
            local tr = UIReferences and UIReferences.Menus and UIReferences.Menus.TowerRewards
            local pt = UIReferences and UIReferences.Root and UIReferences.Root.Menus and UIReferences.Root.Menus.PlayTower
            local active = MenuController and MenuController.ActiveMenu and MenuController.ActiveMenu()
            if active and (active == tr or active == pt) then
                MenuController.CloseMenu()
            end
        end)
        pcall(function()
            HUDController.showAll("inTower")
        end)
    end)

    print("[TOWER] จบการลง:", towerName, string.format("(ชั้นสูงสุด: %d)", lastSeenFloor or 1))
    setBanner(nil, loopStr .. "จบการลงแล้ว กำลังเตรียมตัวรอบถัดไป...")
    if CFG.WebhookEnabled and CFG.WebhookNotifyTower then
        task.spawn(sendTowerWebhook, towerName, lastSeenFloor or 1, loopCount)
    end

    task.wait(4.0)
    return true
end

local _towerQueueThread = nil
local function startTowerQueue()
    if isTowerBusy then return end
    local queue = {}
    for _, t in ipairs(ALL_TOWERS) do
        if SelectedTowers[t.name] then
            table.insert(queue, t.name)
        end
    end

    if #queue == 0 then
        CFG.AutoTowerQueue = false
        setBanner("⚠️ No Towers Selected", "กรุณากดปุ่ม Select Towers เพื่อเลือกหอคอยก่อนเริ่ม")
        return
    end

    CFG.AutoTowerQueue = true
    isTowerBusy = true
    updateRunBtnText()

    setBanner(string.format("⚔️ [1/%d] Preparing...", #queue), "กำลังเข้าสู่หอคอย...")

    _towerQueueThread = task.spawn(function()
        local ok, err = pcall(function()
            local loopCount = 1
            while CFG.AutoTowerQueue do
                for idx, towerName in ipairs(queue) do
                    if not CFG.AutoTowerQueue then break end
                    runSingleTower(towerName, idx, #queue, loopCount)
                end

                if not CFG.LoopTower then
                    break
                end

                loopCount = loopCount + 1
            end
        end)
        if not ok then
            print("[TOWER ERROR]", err)
        end

        CFG.AutoTowerQueue = false
        isTowerBusy = false
        updateRunBtnText()
        pcall(function()
            if HiddenBtn then
                HiddenBtn.Position = UDim2.fromScale(0.5, 0.76)
            end
        end)

        setBanner("✅ Completed All Rounds", "ลงเสร็จสิ้นทุกรอบแล้ว พร้อมเริ่มใหม่")
    end)
end

local function stopTowerQueue()
    CFG.AutoTowerQueue = false
    if _towerQueueThread then
        task.cancel(_towerQueueThread)
        _towerQueueThread = nil
    end
    pcall(function() CancelTower:InvokeServer() end)
    pcall(function()
        if HiddenBtn then
            HiddenBtn.Position = UDim2.fromScale(0.5, 0.76)
        end
    end)
    isTowerBusy = false
    updateRunBtnText()

    setBanner("⏹ Queue Cancelled", "หยุดการทำงานแล้ว พร้อมเริ่มรอบใหม่")
end

-- ── Multi-Category Potions Logic (Luck / Cash / Damage) ───────────────────────
local EntryRegistry = nil
pcall(function() EntryRegistry = require(RS.Framework.Features.Inventory.EntryRegistry) end)

local function getPotionsInInventory(pType)
    local DC = getDC()
    if not DC or not DC.Inventory then return {}, 0 end
    local inv = DC.Inventory() or {}
    local counts = {}
    local total = 0
    local targetType = pType or (CFG and CFG.PotionType) or "Luck"
    local pData = POTION_DATA[targetType]
    if not pData then return {}, 0 end
    for _, cat in ipairs(pData.categories) do
        counts[cat.id] = 0
        for _, itemName in ipairs(cat.items) do
            local entry = inv[itemName]
            if entry and (entry.amount or 0) > 0 then
                counts[cat.id] = counts[cat.id] + entry.amount
                total = total + entry.amount
            end
        end
    end
    return counts, total
end

local function getLuckPotionsInInventory()
    return getPotionsInInventory("Luck")
end

local function getActivePotionInfo(pType)
    local DC = getDC()
    if not DC or not DC.ActiveEntries then return {} end
    local act = DC.ActiveEntries() or {}
    local now = workspace:GetServerTimeNow()
    local activeMap = {}
    local targetType = pType or (CFG and CFG.PotionType) or "Luck"
    local pData = POTION_DATA[targetType]
    local targetCats = {}
    if pData then
        for _, cat in ipairs(pData.categories) do targetCats[cat.id] = true end
    end

    for actKey, actData in pairs(act) do
        local cfg = nil
        if EntryRegistry and EntryRegistry.getEntryConfig then
            pcall(function() cfg = EntryRegistry.getEntryConfig(actData.name or actKey) end)
        end
        if cfg and cfg.kind == "Boost" and cfg.category and (targetCats[cfg.category] or cfg.category:find(targetType)) then
            local rem = 0
            if actData.remaining and typeof(actData.remaining) == "number" then
                local started = actData.startedAt or now
                rem = math.max(0, actData.remaining - math.max(0, now - started))
            elseif actData.expiresAt and typeof(actData.expiresAt) == "number" then
                rem = math.max(0, actData.expiresAt - os.time())
            end
            if rem > 0 then
                activeMap[cfg.category] = {
                    name = actData.name or actKey,
                    remaining = math.floor(rem),
                    tier = cfg.tier or 1,
                }
            end
        end
    end
    return activeMap
end

local function getActiveLuckInfo()
    return getActivePotionInfo("Luck")
end

local BoostController = nil
pcall(function()
    BoostController = require(RS.Framework.Features.Inventory.Kinds.Boost.BoostController)
end)

local function fireUseBoost(potionName)
    local sent = false
    if BoostController and BoostController.UseBoost then
        local ok = pcall(BoostController.UseBoost, potionName)
        if ok then sent = true end
    end
    if not sent and UseBoost then
        pcall(function()
            if UseBoost.Fire then
                UseBoost:Fire(potionName)
                sent = true
            elseif UseBoost.FireServer then
                UseBoost:FireServer(potionName)
                sent = true
            end
        end)
    end
    return sent
end

local function autoUsePotions()
    local DC = getDC()
    if not DC or not DC.Inventory then return end
    local inv = DC.Inventory() or {}
    local targetType = (CFG and CFG.PotionType) or "Luck"
    local pData = POTION_DATA[targetType]
    if not pData then return end

    local activeMap = getActivePotionInfo(targetType)
    local typeSels = SelectedPotionCategories[targetType] or {}

    for _, cat in ipairs(pData.categories) do
        if typeSels[cat.id] ~= false then
            local curActive = activeMap[cat.id]
            if not curActive or curActive.remaining <= 3 then
                for _, potionName in ipairs(cat.items) do
                    local itemEntry = inv[potionName]
                    local amt = itemEntry and itemEntry.amount or 0
                    if amt > 0 then
                        fireUseBoost(potionName)
                        task.wait(0.05)
                        break
                    end
                end
            end
        end
    end
end

local function autoUseLuckPotions()
    autoUsePotions()
end

local function useBestPotionNow(pType, forceAllCategories)
    local DC = getDC()
    if not DC or not DC.Inventory then
        pcall(function() showNotif("ไม่สามารถอ่านข้อมูล Inventory ได้") end)
        return 0
    end
    local targetType = pType or (CFG and CFG.PotionType) or "Luck"
    local pData = POTION_DATA[targetType]
    if not pData then return 0 end

    local inv = DC.Inventory() or {}
    local usedCount = 0
    local typeSels = SelectedPotionCategories[targetType] or {}

    for _, cat in ipairs(pData.categories) do
        if forceAllCategories or (typeSels[cat.id] ~= false) then
            -- Use the single highest tier potion available in this category
            for _, potionName in ipairs(cat.items) do
                local itemEntry = inv[potionName]
                local amt = itemEntry and itemEntry.amount or 0
                if amt > 0 then
                    fireUseBoost(potionName)
                    usedCount = usedCount + 1
                    task.wait(0.05)
                    break -- Distinct per category (ไม่ซ้ำกัน!)
                end
            end
        end
    end
    if not forceAllCategories then
        if usedCount > 0 then
            pcall(function() showNotif("⚡ ใช้น้ำยา " .. targetType .. " สูงสุด " .. usedCount .. " ชนิดเรียบร้อย ✓") end)
        else
            pcall(function() showNotif("ไม่มีน้ำยา " .. targetType .. " ในหมวดหมู่ที่เลือกอยู่ในกระเป๋า") end)
        end
    end
    return usedCount
end

local function useBestLuckNow(forceAllCategories)
    return useBestPotionNow("Luck", forceAllCategories)
end

-- ── Weather (Server Event) Observer ───────────────────────────────────────────
local currentServerWeather = nil
local lastHandledWeatherStart = nil
local weatherUIElements = nil

local function getWeatherBuffText(wName)
    if not wName then return "ไม่มีบัฟ" end
    if wName == "Luck Event" or wName:find("Luck") then
        return "🍀 +150% Luck (2.5x Multiplier)"
    elseif wName == "Cash Event" or wName:find("Cash") then
        return "💰 +150% Money (2.5x Multiplier)"
    elseif wName == "Roll Speed Event" or wName:find("Speed") then
        return "⚡ 2x Roll Speed (0.5x Duration)"
    end
    return "✨ Special Event Multiplier"
end

local function updateWeatherUI()
    if not weatherUIElements or not weatherUIElements.icon then return end
    pcall(function()
        if currentServerWeather and currentServerWeather.name then
            local wName = tostring(currentServerWeather.name)
            local buff = getWeatherBuffText(wName)
            local dur = currentServerWeather.duration or 300
            local started = currentServerWeather.startedAt or os.time()
            local elapsed = math.max(0, os.time() - started)
            local remaining = math.max(0, dur - elapsed)
            local m = math.floor(remaining / 60)
            local s = remaining % 60

            weatherUIElements.icon.Text = wName:find("Luck") and "🍀" or (wName:find("Cash") and "💰" or "⚡")
            weatherUIElements.status.Text = string.format("%s (%02d:%02d)", wName, m, s)
            if wName:find("Luck") then
                weatherUIElements.status.TextColor3 = Color3.fromRGB(80, 255, 140)
            elseif wName:find("Cash") then
                weatherUIElements.status.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                weatherUIElements.status.TextColor3 = Color3.fromRGB(0, 220, 255)
            end
            weatherUIElements.sub.Text = string.format("Buff: %s", buff)
            weatherUIElements.sub.TextColor3 = Color3.fromRGB(220, 220, 240)
        else
            weatherUIElements.icon.Text = "☀️"
            weatherUIElements.status.Text = "Normal Weather (ไม่มีอีเวนต์)"
            weatherUIElements.status.TextColor3 = DARK.subtext
            weatherUIElements.sub.Text = "รอสภาพอากาศพิเศษ (Luck 2.5x / Cash 2.5x / Speed 2x)"
            weatherUIElements.sub.TextColor3 = DARK.subtext
        end
    end)
end

local function checkEventAutoLuck()
    if not CFG.AutoLuckOnEvent then return end
    if not currentServerWeather or not currentServerWeather.name then return end
    local wName = tostring(currentServerWeather.name)
    local wStart = currentServerWeather.startedAt or 0

    if (wName == "Luck Event" or wName:find("Luck")) then
        if lastHandledWeatherStart ~= wStart then
            lastHandledWeatherStart = wStart
            task.spawn(function()
                local used = useBestLuckNow(true)
                print("[LUCK EVENT] Auto-used " .. used .. " best luck potions!")
                pcall(function()
                    showNotif("🍀 Luck Event ตรวจพบแล้ว! กดใช้น้ำยาโชคระดับสูงสุด " .. used .. " ชนิดเรียบร้อย ✓")
                end)
            end)
        end
    end
end

local function setupWeatherListener()
    pcall(function()
        local ClientComm = require(RS.Packages.Network).ClientComm
        local weatherComm = ClientComm.new(RS.Network, false, "WeatherService")
        local activeWeatherProp = weatherComm:GetProperty("ActiveWeather")

        activeWeatherProp:Observe(function(weatherData)
            currentServerWeather = weatherData
            if weatherData and weatherData.name then
                local wName = tostring(weatherData.name)
                local wStart = weatherData.startedAt or 0
                if lastHandledWeatherStart ~= wStart then
                    local buff = getWeatherBuffText(wName)
                    if CFG.WeatherNotifyScreen then
                        pcall(function()
                            showNotif("🌦️ [EVENT] " .. wName .. " เริ่มต้นแล้ว! (" .. buff .. ")")
                        end)
                    end
                    if CFG.WeatherNotifyWebhook and CFG.WebhookEnabled then
                        pcall(sendWeatherWebhook, wName, buff, weatherData.duration or 0)
                    end
                end
                task.spawn(checkEventAutoLuck)
            else
                lastHandledWeatherStart = nil
            end
            task.spawn(updateWeatherUI)
        end)
    end)
end
task.spawn(setupWeatherListener)

task.spawn(function()
    while true do
        task.wait(1)
        if currentServerWeather and currentServerWeather.name then
            pcall(updateWeatherUI)
        end
    end
end)

-- ── Skip Cutscene Hook ────────────────────────────────────────────────────────
pcall(function()
    local RollCtrl = require(RS.Framework.Features.Rolling.RollController)
    if RollCtrl and RollCtrl.PlayCutscene then
        local origCutscene = RollCtrl.PlayCutscene
        RollCtrl.PlayCutscene = function(p1, p2, p3)
            if CFG.SkipCutscene then
                if p3 then pcall(function() p3:Destroy() end) end
                return
            end
            return origCutscene(p1, p2, p3)
        end
    end
end)

-- ── Background loops ──────────────────────────────────────────────────────────
task.spawn(function() while true do task.wait(COLLECT_LOOP)
    if CFG.AutoCollect then collectAll() end
end end)
task.spawn(function() while true do task.wait(EQUIP_LOOP)
    if CFG.AutoEquip then
        if CFG.AutoEquipMode == "Rarity" then
            equipBestByRarity(false)
        else
            pcall(function() EquipBest:FireServer() end)
        end
    end
end end)
task.spawn(function()
    while true do
        local isFast = CFG.FastAutoRoll
        local isNormal = CFG.AutoRoll
        if not (isFast or isNormal) then
            task.wait(0.5)
            continue
        end

        -- Check storage before roll to prevent "Inventory Full" server lock
        if CFG.AutoCleanInventory or isFast then
            local DC = getDC()
            if DC and DC.Inventory then
                local inv = nil
                pcall(function() inv = DC.Inventory() end)
                if inv and type(inv) == "table" then
                    local count = 0
                    for _ in pairs(inv) do count = count + 1 end
                    -- If inventory has many units (>= 18), clean junk units before next roll
                    if count >= 18 then
                        pcall(function() cleanInventoryAutoSell(false) end)
                        task.wait(0.1)
                    end
                end
            end
        end

        local baseDelay = 2.5
        if isFast then
            -- Safe adaptive fast delay: minimum 0.15s to prevent Android/Emulator packet buffer overflow (Connection Lost)
            baseDelay = math.max(0.15, tonumber(CFG.RollDelay) or 0.15)
        else
            baseDelay = math.max(1.0, tonumber(CFG.RollDelay) or 2.5)
        end

        local startMoney = getMoney()
        local ok, res = pcall(function() return RollDice:InvokeServer() end)

        if ok and res and type(res) == "table" then
            task.spawn(checkRollWebhook, res)

            -- Track auto sell cash increase and confirm visually
            task.delay(0.6, function()
                local newMoney = getMoney()
                if newMoney > startMoney then
                    local diff = newMoney - startMoney
                    if CFG.ShowRollCashNotif then
                        showNotif(string.format("💰 ได้รับ +%s Cash จากการขายยูนิตที่สุ่มได้", formatNumberCompact(diff)))
                    end
                end
            end)

            task.wait(baseDelay)
        else
            -- Backoff slightly if server is on debounce cooldown (prevents 10/sec RemoteFunction packet spam)
            task.wait(math.max(0.35, baseDelay))
        end
    end
end)
task.spawn(function()
    while true do
        local mins = CFG.WebhookStatsInterval or 15
        task.wait(math.max(1, mins) * 60)
        if CFG.WebhookEnabled and CFG.WebhookNotifyStats then
            pcall(sendStatsWebhook)
        end
    end
end)
local _lastRebirthTier = nil
task.spawn(function()
    while true do
        task.wait(REBIRTH_LOOP)
        pcall(function()
            local curLvl = getRebirthLevel()
            if _lastRebirthTier == nil then
                _lastRebirthTier = curLvl
            elseif curLvl > _lastRebirthTier then
                _lastRebirthTier = curLvl
                task.wait(0.8)
                if CFG.AutoEquip then
                    if CFG.AutoEquipMode == "Rarity" then
                        equipBestByRarity(false)
                    else
                        pcall(function() EquipBest:FireServer() end)
                    end
                end
                showNotif(string.format("Rebirth Tier %d สำเร็จ! อัปเดตการวางยูนิตลง Plot ใหม่ครบทุกช่อง ✓", curLvl))
            end
        end)
        if CFG.AutoRebirth then tryRebirth() end
    end
end)
task.spawn(function() while true do task.wait(QUEST_LOOP)
    if CFG.AutoQuest then claimAllQuests() end
end end)
task.spawn(function() while true do task.wait(30)
    if CFG.AutoClaimRewards then pcall(function() claimAllFreeRewards(false) end) end
end end)
task.spawn(function() while true do task.wait(DICE_LOOP)
    if CFG.AutoBuyDice or CFG.AutoEquipDice then autoDice() end
end end)
task.spawn(function() while true do task.wait(UPGRADE_LOOP)
    if CFG.AutoUpgrade then autoUpgradeSkillTree() end
end end)
task.spawn(function() while true do task.wait(PLOT_UPGRADE_LOOP)
    if CFG.AutoUpgradePlot then autoUpgradePlots() end
end end)
task.spawn(function() while true do task.wait(2)
    if CFG.AutoUseLuck or CFG.AutoUsePotion then pcall(autoUsePotions) end
end end)
-- ── Robust Multi-Platform Anti-AFK (PC & Emulator / Mobile) ───────────────────
pcall(function()
    if getconnections then
        for _, conn in ipairs(getconnections(LP.Idled)) do
            if conn.Disable then conn:Disable()
            elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)

LP.Idled:Connect(function()
    if CFG.AntiAFK then
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(40)
        if CFG.AntiAFK then
            pcall(function()
                if VirtualUser then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(50, 50))
                end
                if VIM then
                    VIM:SendKeyEvent(true, Enum.KeyCode.F13, false, game)
                    task.wait(0.02)
                    VIM:SendKeyEvent(false, Enum.KeyCode.F13, false, game)
                end
            end)
        end
    end
end)

-- ── Auto Reconnect / Anti-Disconnection Guardian (Emulator Safe) ──────────────
local function setupAutoReconnect()
    local reconnecting = false
    local function attemptReconnect(reason)
        if reconnecting or not CFG.AutoReconnect then return end
        reconnecting = true
        warn("[540 HUB] ตรวจพบการหลุดการเชื่อมต่อ (" .. tostring(reason) .. ") -> กำลังเชื่อมต่อใหม่เข้าเซิร์ฟเวอร์...")
        
        task.wait(2.5)
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LP)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
            end
        end)
        
        task.wait(5)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LP)
        end)
    end

    pcall(function()
        local GuiService = game:GetService("GuiService")
        GuiService.ErrorMessageChanged:Connect(function(msg)
            if msg and msg ~= "" then
                attemptReconnect("ErrorMessageChanged: " .. tostring(msg))
            end
        end)
    end)

    pcall(function()
        local CoreGui = game:GetService("CoreGui")
        local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
        if promptOverlay then
            promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" or child:FindFirstChild("MessageArea") then
                    attemptReconnect("ErrorPrompt Dialog Appeared")
                end
            end)
            if promptOverlay:FindFirstChild("ErrorPrompt") then
                attemptReconnect("Existing ErrorPrompt Detected")
            end
        end
    end)
end
pcall(setupAutoReconnect)

-- ── Boost FPS Optimizer ───────────────────────────────────────────────────────
local Lighting = game:GetService("Lighting")
local Terrain  = workspace:FindFirstChildOfClass("Terrain")
local _fpsConn = nil

local function optimizeInstance(inst)
    if inst:IsA("BasePart") then
        inst.Material = Enum.Material.SmoothPlastic
        inst.CastShadow = false
        inst.Reflectance = 0
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        inst.Transparency = 1
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
        inst.Enabled = false
    elseif inst:IsA("PostEffect") or inst:IsA("Atmosphere") or inst:IsA("Clouds") then
        inst.Enabled = false
    end
end

local function applyBoostFPS()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end
        for _, inst in ipairs(Lighting:GetDescendants()) do
            if inst:IsA("PostEffect") or inst:IsA("Atmosphere") or inst:IsA("Clouds") then
                inst.Enabled = false
            end
        end
        for _, inst in ipairs(workspace:GetDescendants()) do
            optimizeInstance(inst)
        end
    end)
end

local function toggleBoostFPS(enable)
    CFG.BoostFPS = enable
    if enable then
        applyBoostFPS()
        if not _fpsConn then
            _fpsConn = workspace.DescendantAdded:Connect(function(inst)
                if CFG.BoostFPS then
                    task.defer(function()
                        pcall(optimizeInstance, inst)
                    end)
                end
            end)
        end
    else
        if _fpsConn then
            _fpsConn:Disconnect()
            _fpsConn = nil
        end
    end
end

local UtilityFeatures = {}

do
    local _otherPlayersConn = nil
    local _charAddedConns = {}

    local function setCharHidden(char, hidden)
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if hidden then
                    if part:GetAttribute("OrigTransparency") == nil then
                        part:SetAttribute("OrigTransparency", part.Transparency)
                    end
                    part.Transparency = 1
                    part.CanCollide = false
                    part.CastShadow = false
                else
                    local orig = part:GetAttribute("OrigTransparency")
                    part.Transparency = (orig ~= nil) and orig or 0
                end
            elseif part:IsA("Decal") then
                if hidden then
                    if part:GetAttribute("OrigTransparency") == nil then
                        part:SetAttribute("OrigTransparency", part.Transparency)
                    end
                    part.Transparency = 1
                else
                    local orig = part:GetAttribute("OrigTransparency")
                    part.Transparency = (orig ~= nil) and orig or 0
                end
            elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
                part.Enabled = not hidden
            elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                part.Enabled = not hidden
            end
        end
    end

    function UtilityFeatures.toggleHideOtherPlayers(enable)
        CFG.HideOtherPlayers = enable
        if enable then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    if plr.Character then setCharHidden(plr.Character, true) end
                    if not _charAddedConns[plr] then
                        _charAddedConns[plr] = plr.CharacterAdded:Connect(function(c)
                            if CFG.HideOtherPlayers then
                                task.wait(0.2)
                                setCharHidden(c, true)
                            end
                        end)
                    end
                end
            end
            if not _otherPlayersConn then
                _otherPlayersConn = Players.PlayerAdded:Connect(function(plr)
                    if plr ~= LP then
                        _charAddedConns[plr] = plr.CharacterAdded:Connect(function(c)
                            if CFG.HideOtherPlayers then
                                task.wait(0.2)
                                setCharHidden(c, true)
                            end
                        end)
                    end
                end)
            end
        else
            if _otherPlayersConn then
                _otherPlayersConn:Disconnect()
                _otherPlayersConn = nil
            end
            for plr, conn in pairs(_charAddedConns) do
                pcall(function() conn:Disconnect() end)
                if plr.Character then setCharHidden(plr.Character, false) end
            end
            table.clear(_charAddedConns)
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    setCharHidden(plr.Character, false)
                end
            end
        end
    end

    function UtilityFeatures.toggleDisableWeatherFX(enable)
        CFG.DisableWeatherFX = enable
        pcall(function()
            LP:SetAttribute("WindDisabled", enable)
        end)
        pcall(function()
            for _, inst in ipairs(Lighting:GetDescendants()) do
                if inst:IsA("Atmosphere") or inst:IsA("Clouds") or inst:IsA("BloomEffect") or inst:IsA("SunRaysEffect") then
                    inst.Enabled = not enable
                end
            end
            if enable then
                Lighting.FogEnd = 9e9
            end
        end)
        if enable then
            for _, inst in ipairs(workspace:GetDescendants()) do
                local name = inst.Name:lower()
                if name:find("rain") or name:find("snow") or name:find("weather") or name:find("cloud") or name:find("wind") or name:find("storm") then
                    if inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") then
                        inst.Enabled = false
                    end
                end
            end
        end
    end

    local _particleConn = nil
    function UtilityFeatures.toggleDisableParticles(enable)
        CFG.DisableParticles = enable
        if enable then
            for _, inst in ipairs(workspace:GetDescendants()) do
                if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") or inst:IsA("Highlight") then
                    inst.Enabled = false
                end
            end
            if not _particleConn then
                _particleConn = workspace.DescendantAdded:Connect(function(inst)
                    if CFG.DisableParticles then
                        if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") or inst:IsA("Highlight") then
                            task.defer(function() pcall(function() inst.Enabled = false end) end)
                        end
                    end
                end)
            end
        else
            if _particleConn then
                _particleConn:Disconnect()
                _particleConn = nil
            end
        end
    end

    local _plotUnitsConn = nil

    local function setPlotInstHidden(inst, hidden)
        if inst:IsA("BasePart") then
            if hidden then
                if inst:GetAttribute("PlotOrigTrans") == nil then
                    inst:SetAttribute("PlotOrigTrans", inst.Transparency)
                end
                inst.Transparency = 1
                inst.CastShadow = false
            else
                local orig = inst:GetAttribute("PlotOrigTrans")
                inst.Transparency = (orig ~= nil) and orig or 0
            end
        elseif inst:IsA("Decal") then
            if hidden then
                if inst:GetAttribute("PlotOrigTrans") == nil then
                    inst:SetAttribute("PlotOrigTrans", inst.Transparency)
                end
                inst.Transparency = 1
            else
                local orig = inst:GetAttribute("PlotOrigTrans")
                inst.Transparency = (orig ~= nil) and orig or 0
            end
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Highlight") then
            inst.Enabled = not hidden
        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            if inst.Name ~= "UpgradeBoard" and inst.Name ~= "SlotPrompt" then
                inst.Enabled = not hidden
            end
        end
    end

    local function applyHideToPlot(plot, hidden)
        local slots = plot:FindFirstChild("Slots")
        if not slots then return end
        for _, slot in ipairs(slots:GetChildren()) do
            for _, inst in ipairs(slot:GetDescendants()) do
                setPlotInstHidden(inst, hidden)
            end
        end
    end

    function UtilityFeatures.toggleHidePlotUnits(enable)
        CFG.HidePlotUnits = enable
        local plotsFolder = workspace:FindFirstChild("Plots")
        local claimed = plotsFolder and plotsFolder:FindFirstChild("Claimed")
        if claimed then
            for _, plot in ipairs(claimed:GetChildren()) do
                applyHideToPlot(plot, enable)
            end
        end
        if enable then
            if not _plotUnitsConn and plotsFolder then
                _plotUnitsConn = plotsFolder.DescendantAdded:Connect(function(inst)
                    if CFG.HidePlotUnits then
                        task.defer(function()
                            local p = inst.Parent
                            local inSlot = false
                            while p and p ~= plotsFolder do
                                if p.Name == "Slots" then inSlot = true break end
                                p = p.Parent
                            end
                            if inSlot then
                                setPlotInstHidden(inst, true)
                            end
                        end)
                    end
                end)
            end
        else
            if _plotUnitsConn then
                _plotUnitsConn:Disconnect()
                _plotUnitsConn = nil
            end
        end
    end

    function UtilityFeatures.toggleLowDetailMode(enable)
        CFG.LowDetailMode = enable
        UtilityFeatures.toggleDisableWeatherFX(enable)
        UtilityFeatures.toggleHideOtherPlayers(enable)
        UtilityFeatures.toggleHidePlotUnits(enable)
        UtilityFeatures.toggleDisableParticles(enable)
        toggleBoostFPS(enable)
    end

    UtilityFeatures.TeleportLocations = {
        {
            id = "MyPlot",
            name = "🏠 My Plot (ฐานของฉัน)",
            sub = "ฐานและสายพานสุ่มของตัวเอง",
            getPos = function()
                local plotId = nil
                pcall(function()
                    local Property = require(RS.Packages.Network).ClientComm.new(RS.Network, false, "PlotService"):GetProperty("PlotId")
                    plotId = Property and Property:Get()
                end)
                if plotId and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Claimed") then
                    local plot = workspace.Plots.Claimed:FindFirstChild(plotId)
                    if plot then
                        local sp = plot:FindFirstChild("Spawn") or plot:FindFirstChild("Conveyor")
                        if sp and sp:IsA("BasePart") then
                            return sp.Position + Vector3.new(0, 3.5, 0)
                        end
                    end
                end
                if workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Claimed") then
                    for _, p in ipairs(workspace.Plots.Claimed:GetChildren()) do
                        local sp = p:FindFirstChild("Spawn")
                        if sp and sp:IsA("BasePart") then
                            return sp.Position + Vector3.new(0, 3.5, 0)
                        end
                    end
                end
                return Vector3.new(0, 5, 0)
            end
        },
        {
            id = "Tower",
            name = "🏰 Tower Entrance (หอคอย)",
            sub = "ประตูเข้าหอคอย Infinity Tower",
            zone = "Towers",
            pos = Vector3.new(80.98, 44.5, 80.54)
        },
        {
            id = "DiceShop",
            name = "🎲 Dice Shop (ร้านลูกเต๋า)",
            sub = "NPC ซื้อลูกเต๋าเพิ่ม Luck / ตัวคูณ",
            zone = "DiceShop",
            pos = Vector3.new(37.98, 22.5, 35.54)
        },
        {
            id = "Shop",
            name = "🛒 Shop (ร้านค้าทั่วไป)",
            sub = "ร้านค้าไอเทมและอุปกรณ์",
            zone = "Shop",
            pos = Vector3.new(19.98, 22.5, 22.12)
        },
        {
            id = "Fuse",
            name = "⚔️ Aura Fuse Machine (หลอมยูนิต)",
            sub = "แท่นหลอมรวมออร่ายูนิต",
            zone = "Fusing",
            pos = Vector3.new(37.98, 22.5, 35.54)
        },
        {
            id = "Grades",
            name = "✨ Grade Reroll (สุ่มเกรด)",
            sub = "แท่นสุ่มเกรดยูนิต (D - SSS / ∞)",
            zone = "Grades",
            pos = Vector3.new(21.98, 22.5, 34.12)
        },
        {
            id = "Traits",
            name = "🧬 Trait Reroll (สุ่มเทรต)",
            sub = "แท่นสุ่มคุณสมบัติพิเศษ (Paradox)",
            zone = "Traits",
            pos = Vector3.new(39.98, 22.5, 23.12)
        },
        {
            id = "Selling",
            name = "💰 Selling Zone (ขายยูนิต)",
            sub = "โซนขายยูนิตแลกเงิน",
            zone = "Selling",
            pos = Vector3.new(23.98, 22.5, 18.12)
        },
        {
            id = "Quests",
            name = "📜 Quests Board (เควส)",
            sub = "บอร์ดรับเควสประจำวัน",
            zone = "Quests",
            pos = Vector3.new(28.98, 22.5, 37.12)
        },
        {
            id = "Trade",
            name = "🤝 Trade Zone (เทรด)",
            sub = "โซนแลกเปลี่ยนยูนิตระหว่างผู้เล่น",
            zone = "Trade",
            pos = Vector3.new(24.98, 22.5, 37.12)
        },
        {
            id = "Podium",
            name = "🏆 Best Roll (แท่นโชว์ดวง)",
            sub = "ตู้สุ่มและแท่นโชว์ดวงดีกลางแมพ",
            pos = Vector3.new(0, 5, 0)
        }
    }

    local function resolveTeleportPos(loc)
        if loc.getPos then
            local p = loc.getPos()
            if p then return p end
        end
        if loc.zone and workspace:FindFirstChild("Zones") then
            local z = workspace.Zones:FindFirstChild(loc.zone)
            if z and z:IsA("BasePart") then
                return z.Position + Vector3.new(0, 3.5, 0)
            end
        end
        return loc.pos
    end

    function UtilityFeatures.teleportTo(loc)
        local char = LP.Character
        if not char then
            notify("Teleport", "ไม่พบตัวละครของคุณ", 2)
            return false
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            notify("Teleport", "ไม่พบ HumanoidRootPart", 2)
            return false
        end
        local targetPos = resolveTeleportPos(loc)
        if not targetPos then
            notify("Teleport", "ไม่พบพิกัดเป้าหมาย", 2)
            return false
        end
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        notify("Teleport", "วาร์ปไป: " .. loc.name .. " ✓", 2)
        return true
    end
end

local function toggle3DRendering(enable)
    CFG.Disable3DRender = enable
    pcall(function()
        RunService:Set3dRenderingEnabled(not enable)
    end)
end

local _origVolume = 1
local function toggleSuperRAMSaver(enable)
    CFG.SuperRAMSaver = enable
    CFG.Disable3DRender = enable
    pcall(function()
        RunService:Set3dRenderingEnabled(not enable)
    end)
    pcall(function()
        local ugs = UserSettings():GetService("UserGameSettings")
        if enable then
            _origVolume = ugs.MasterVolume
            ugs.MasterVolume = 0
            collectgarbage("collect")
        else
            ugs.MasterVolume = _origVolume or 1
        end
    end)
end

local _hiddenGuis = {}
local function toggleHideGameUI(enable)
    CFG.HideGameUI = enable
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end
        if enable then
            _hiddenGuis = {}
            for _, g in ipairs(pg:GetChildren()) do
                if g:IsA("ScreenGui") and g.Name ~= "540CHEATS_v24" and g.Enabled then
                    _hiddenGuis[g] = true
                    g.Enabled = false
                end
            end
        else
            for g, _ in pairs(_hiddenGuis) do
                if g and g.Parent then
                    g.Enabled = true
                end
            end
            _hiddenGuis = {}
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(60)
        if CFG.SuperRAMSaver then
            pcall(function() collectgarbage("collect") end)
        end
    end
end)

-- ============================================================
-- ===== UI =====
-- ============================================================
local gui,main,minimizedLogo,notif

pcall(function()
    local existing = (gethui and gethui():FindFirstChild("540CHEATS_v24"))
        or (LP and LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("540CHEATS_v24"))
        or (game:GetService("CoreGui"):FindFirstChild("540CHEATS_v24"))
    if existing then existing:Destroy() end
end)

local function buildHubUI()
local targetParent = nil
pcall(function()
    if gethui then
        local h = gethui()
        local test = Instance.new("Folder")
        test.Parent = h
        test:Destroy()
        targetParent = h
    end
end)
if not targetParent then
    pcall(function()
        local cg = game:GetService("CoreGui")
        local test = Instance.new("Folder")
        test.Parent = cg
        test:Destroy()
        targetParent = cg
    end)
end
if not targetParent then
    targetParent = LP:WaitForChild("PlayerGui", 10) or LP:FindFirstChildOfClass("PlayerGui") or LP:FindFirstChild("PlayerGui")
end

gui=Instance.new("ScreenGui")
gui.Name="540CHEATS_v24"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=999999
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Enabled=true

local parentOk = pcall(function()
    gui.Parent = targetParent
end)
if not parentOk or not gui.Parent then
    pcall(function()
        gui.Parent = LP:WaitForChild("PlayerGui", 5) or LP:FindFirstChild("PlayerGui")
    end)
end

notif=Instance.new("TextLabel",gui)
notif.Size=UDim2.new(0,300,0,32); notif.Position=UDim2.new(0.5,-150,0,-40)
notif.BackgroundColor3=DARK.bg; notif.BackgroundTransparency=0.15
notif.TextColor3=DARK.accent; notif.Font=FONT; notif.TextSize=13; notif.Visible=false
Instance.new("UICorner",notif).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",notif).Color=DARK.accent

showNotif = function(text)
    print("[CHEAT HUB] " .. tostring(text))
    pcall(function()
        if notif then
            notif.Text = "  > " .. tostring(text)
            notif.Visible = true
            TweenService:Create(notif, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -150, 0, 20) }):Play()
            task.delay(1.5, function()
                TweenService:Create(notif, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -150, 0, -40) }):Play()
                task.wait(0.4)
                notif.Visible = false
            end)
        end
    end)
end

main=Instance.new("Frame")
main.Size=UDim2.new(0,780,0,480)
main.Position=UDim2.new(0.5,0,0.5,0)
main.AnchorPoint=Vector2.new(0.5,0.5)
main.BackgroundColor3=DARK.bg; main.BorderSizePixel=0; main.Active=true; main.Parent=gui; main.Visible=false

-- ── 540 HUB Ultra-Premium Loading Screen ──────────────────────────────────
local loadOverlay = Instance.new("Frame", gui)
loadOverlay.Size = UDim2.new(1, 0, 1, 0)
loadOverlay.Position = UDim2.new(0, 0, 0, 0)
loadOverlay.BackgroundColor3 = Color3.fromRGB(8, 6, 15)
loadOverlay.BackgroundTransparency = 0.3
loadOverlay.BorderSizePixel = 0
loadOverlay.ZIndex = 500

-- Ambient glow backdrop
local glowBack = Instance.new("Frame", loadOverlay)
glowBack.Size = UDim2.new(0, 420, 0, 230)
glowBack.Position = UDim2.new(0.5, 0, 0.5, 0)
glowBack.AnchorPoint = Vector2.new(0.5, 0.5)
glowBack.BackgroundColor3 = Color3.fromRGB(140, 40, 240)
glowBack.BackgroundTransparency = 0.8
glowBack.BorderSizePixel = 0
glowBack.ZIndex = 501
Instance.new("UICorner", glowBack).CornerRadius = UDim.new(0, 20)

-- Main Loading Card
local loadCard = Instance.new("Frame", loadOverlay)
loadCard.Size = UDim2.new(0, 400, 0, 215)
loadCard.Position = UDim2.new(0.5, 0, 0.5, 0)
loadCard.AnchorPoint = Vector2.new(0.5, 0.5)
loadCard.BackgroundColor3 = Color3.fromRGB(16, 12, 26)
loadCard.BorderSizePixel = 0
loadCard.ZIndex = 502
Instance.new("UICorner", loadCard).CornerRadius = UDim.new(0, 16)

local cardGrad = Instance.new("UIGradient", loadCard)
cardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 38)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 9, 20))
})
cardGrad.Rotation = 45

local lcStroke = Instance.new("UIStroke", loadCard)
lcStroke.Color = Color3.fromRGB(160, 70, 255)
lcStroke.Thickness = 1.8

-- Outer Logo Glow Ring
local iconBadge = Instance.new("Frame", loadCard)
iconBadge.Size = UDim2.new(0, 56, 0, 56)
iconBadge.Position = UDim2.new(0.5, -28, 0, 16)
iconBadge.BackgroundColor3 = Color3.fromRGB(45, 18, 75)
iconBadge.BorderSizePixel = 0
iconBadge.ZIndex = 503
Instance.new("UICorner", iconBadge).CornerRadius = UDim.new(0, 14)
local badgeStroke = Instance.new("UIStroke", iconBadge)
badgeStroke.Color = Color3.fromRGB(190, 90, 255)
badgeStroke.Thickness = 1.5

local lcIcon = Instance.new("ImageLabel", iconBadge)
lcIcon.Size = UDim2.new(0, 42, 0, 42); lcIcon.Position = UDim2.new(0.5, -21, 0.5, -21)
lcIcon.BackgroundTransparency = 1; lcIcon.Image = "rbxthumb://type=Asset&id=86571453491468&w=420&h=420"
lcIcon.ScaleType = Enum.ScaleType.Fit; lcIcon.ZIndex = 504
Instance.new("UICorner", lcIcon).CornerRadius = UDim.new(0, 10)

local lcTitle = Instance.new("TextLabel", loadCard)
lcTitle.Size = UDim2.new(1, -20, 0, 22); lcTitle.Position = UDim2.new(0, 10, 0, 80)
lcTitle.BackgroundTransparency = 1; lcTitle.Text = "540 HUB"
lcTitle.TextColor3 = Color3.fromRGB(255, 255, 255); lcTitle.Font = FONT_BOLD; lcTitle.TextSize = 20
lcTitle.ZIndex = 503

local lcSub = Instance.new("TextLabel", loadCard)
lcSub.Size = UDim2.new(1, -20, 0, 14); lcSub.Position = UDim2.new(0, 10, 0, 104)
lcSub.BackgroundTransparency = 1; lcSub.Text = "ANIME DICE EDITION • BY REKTZ"
lcSub.TextColor3 = Color3.fromRGB(190, 160, 255); lcSub.Font = FONT_BOLD; lcSub.TextSize = 11
lcSub.ZIndex = 503

-- Status Text & Percentage Row
local statRow = Instance.new("Frame", loadCard)
statRow.Size = UDim2.new(1, -44, 0, 16); statRow.Position = UDim2.new(0, 22, 0, 134)
statRow.BackgroundTransparency = 1; statRow.ZIndex = 503

local statLbl = Instance.new("TextLabel", statRow)
statLbl.Size = UDim2.new(1, -60, 1, 0); statLbl.Position = UDim2.new(0, 0, 0, 0)
statLbl.BackgroundTransparency = 1; statLbl.Text = "Initializing script core..."
statLbl.TextColor3 = Color3.fromRGB(215, 205, 240); statLbl.Font = FONT_MEDIUM; statLbl.TextSize = 12
statLbl.TextXAlignment = Enum.TextXAlignment.Left; statLbl.ZIndex = 503

local pctLbl = Instance.new("TextLabel", statRow)
pctLbl.Size = UDim2.new(0, 55, 1, 0); pctLbl.Position = UDim2.new(1, -55, 0, 0)
pctLbl.BackgroundTransparency = 1; pctLbl.Text = "0%"
pctLbl.TextColor3 = Color3.fromRGB(220, 120, 255); pctLbl.Font = FONT_BOLD; pctLbl.TextSize = 13
pctLbl.TextXAlignment = Enum.TextXAlignment.Right; pctLbl.ZIndex = 503

-- Progress Bar Track
local progBg = Instance.new("Frame", loadCard)
progBg.Size = UDim2.new(1, -44, 0, 8); progBg.Position = UDim2.new(0, 22, 0, 158)
progBg.BackgroundColor3 = Color3.fromRGB(28, 20, 46); progBg.BorderSizePixel = 0
progBg.ZIndex = 503
Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 4)

local progFill = Instance.new("Frame", progBg)
progFill.Size = UDim2.new(0, 0, 1, 0); progFill.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
progFill.BorderSizePixel = 0; progFill.ZIndex = 504
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0, 4)

local fillGrad = Instance.new("UIGradient", progFill)
fillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 40, 240)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 90, 255))
})

-- Execution Sequence:
-- Fill to 100%, wait 2 seconds after full, then reveal main GUI
task.spawn(function()
    local function setProgress(pct, duration, statusText)
        statLbl.Text = statusText
        TweenService:Create(progFill, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(pct / 100, 0, 1, 0) }):Play()
        local startVal = tonumber(pctLbl.Text:match("%d+")) or 0
        local steps = 15
        for i = 1, steps do
            local cur = math.floor(startVal + (pct - startVal) * (i / steps))
            pctLbl.Text = tostring(cur) .. "%"
            task.wait(duration / steps)
        end
        pctLbl.Text = tostring(pct) .. "%"
    end

    task.wait(0.2)
    setProgress(30, 0.45, "Loading modules & game hooks...")
    setProgress(65, 0.55, "Scanning plot objects & remote events...")
    setProgress(90, 0.45, "Applying configurations & theme...")
    setProgress(100, 0.35, "100% • System Ready!")

    -- ให้มันโหลดเสร็จเต็มหลอดก่อน หลังจากนั้น 2 วิ ค่อยขึ้น gui สคริปมา
    task.wait(2.0)

    -- Smooth fade out
    local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(loadOverlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(glowBack, fadeInfo, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(loadCard, fadeInfo, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(lcStroke, fadeInfo, { Transparency = 1 }):Play()
    TweenService:Create(iconBadge, fadeInfo, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(badgeStroke, fadeInfo, { Transparency = 1 }):Play()
    TweenService:Create(lcIcon, fadeInfo, { ImageTransparency = 1 }):Play()
    TweenService:Create(lcTitle, fadeInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(lcSub, fadeInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(statLbl, fadeInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(pctLbl, fadeInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(progBg, fadeInfo, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(progFill, fadeInfo, { BackgroundTransparency = 1 }):Play()
    task.wait(0.4)
    loadOverlay:Destroy()
    main.Visible = true
    if wm then wm.Visible = true end
end)
Instance.new("UICorner",main).CornerRadius=UDim.new(0,14)
local mainStroke=Instance.new("UIStroke",main); mainStroke.Color=DARK.border; mainStroke.Thickness=1.2

-- Responsive Universal Resolution Scaling (Auto-adapts to Mobile, Tablet, 1080p, 1440p, 4K)
local uiScale = Instance.new("UIScale", main)
local function updateResolutionScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    if vp.X == 0 or vp.Y == 0 then return end
    local targetScale = 1.0
    if vp.Y >= 1440 then
        targetScale = 1.35
    elseif vp.Y >= 1080 then
        targetScale = 1.15
    elseif vp.Y < 600 or vp.X < 900 then
        targetScale = math.clamp(math.min(vp.X / 860, vp.Y / 530), 0.6, 0.95)
    else
        targetScale = 1.0
    end
    uiScale.Scale = targetScale
end
updateResolutionScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResolutionScale)
end

local HH=50
do
local header=Instance.new("Frame",main)
header.Size=UDim2.new(1,0,0,HH); header.BackgroundColor3=DARK.header; header.BorderSizePixel=0
Instance.new("UICorner",header).CornerRadius=UDim.new(0,14)
local hBot=Instance.new("Frame",header)
hBot.Size=UDim2.new(1,0,0,14); hBot.Position=UDim2.new(0,0,1,-14)
hBot.BackgroundColor3=DARK.header; hBot.BorderSizePixel=0

local dragging,dragStart,startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=main.Position end end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local curScale = (uiScale and uiScale.Scale > 0) and uiScale.Scale or 1
        local d=(i.Position-dragStart) / curScale
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)

-- 540 HUB Logo Icon
local logoBg=Instance.new("Frame",header)
logoBg.Size=UDim2.new(0,32,0,32); logoBg.Position=UDim2.new(0,14,0.5,-16)
logoBg.BackgroundColor3=Color3.fromRGB(32,20,50); logoBg.BorderSizePixel=0
Instance.new("UICorner",logoBg).CornerRadius=UDim.new(0,8)
local lStroke=Instance.new("UIStroke",logoBg); lStroke.Color=DARK.hAccent; lStroke.Thickness=1.2

local hIcon=Instance.new("ImageLabel",logoBg)
hIcon.Size=UDim2.new(0,24,0,24); hIcon.Position=UDim2.new(0.5,-12,0.5,-12)
hIcon.BackgroundTransparency=1; hIcon.Image="rbxthumb://type=Asset&id=86571453491468&w=420&h=420"; hIcon.ScaleType=Enum.ScaleType.Fit

-- Title: 540 HUB
local hT=Instance.new("TextLabel",header)
hT.Size=UDim2.new(0,160,0,18); hT.Position=UDim2.new(0,54,0,9)
hT.BackgroundTransparency=1; hT.Text="540 HUB"
hT.TextColor3=Color3.new(1,1,1); hT.TextXAlignment=Enum.TextXAlignment.Left
hT.Font=FONT_BOLD; hT.TextSize=16

-- Subtitle: Anime Dice • by .valen_vct
local hS=Instance.new("TextLabel",header)
hS.Size=UDim2.new(0,240,0,16); hS.Position=UDim2.new(0,54,0,26)
hS.BackgroundTransparency=1; hS.Text="Anime Dice • 540 HUB Edition"
hS.TextColor3=DARK.subtext; hS.TextXAlignment=Enum.TextXAlignment.Left
hS.Font=FONT_MEDIUM; hS.TextSize=12

-- Window Controls (Minimize, Expand, Close)
local bCont=Instance.new("Frame",header)
bCont.Size=UDim2.new(0,96,0,28); bCont.Position=UDim2.new(1,-104,0.5,-14); bCont.BackgroundTransparency=1

-- Minimize Button
local minBtn=Instance.new("TextButton",bCont)
minBtn.Size=UDim2.new(0,28,1,0); minBtn.Position=UDim2.new(0,0,0,0)
minBtn.BackgroundColor3=Color3.fromRGB(24,18,34); minBtn.BorderSizePixel=0
minBtn.Text="—"; minBtn.TextColor3=Color3.fromRGB(180,170,200); minBtn.Font=FONT_BOLD; minBtn.TextSize=13
Instance.new("UICorner",minBtn).CornerRadius=UDim.new(0,6)
minBtn.MouseButton1Click:Connect(function() main.Visible=false; minimizedLogo.Visible=true end)

-- Maximize / Fullscreen Icon Button
local maxBtn=Instance.new("TextButton",bCont)
maxBtn.Size=UDim2.new(0,28,1,0); maxBtn.Position=UDim2.new(0,34,0,0)
maxBtn.BackgroundColor3=Color3.fromRGB(24,18,34); maxBtn.BorderSizePixel=0
maxBtn.Text="⛶"; maxBtn.TextColor3=Color3.fromRGB(180,170,200); maxBtn.Font=FONT; maxBtn.TextSize=12
Instance.new("UICorner",maxBtn).CornerRadius=UDim.new(0,6)

-- Close Button
local closeBtn=Instance.new("TextButton",bCont)
closeBtn.Size=UDim2.new(0,28,1,0); closeBtn.Position=UDim2.new(0,68,0,0)
closeBtn.BackgroundColor3=Color3.fromRGB(36,16,32); closeBtn.BorderSizePixel=0
closeBtn.Text="×"; closeBtn.TextColor3=DARK.red; closeBtn.Font=FONT_BOLD; closeBtn.TextSize=16
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    for k, _ in pairs(CFG) do CFG[k]=false end
    stopTowerQueue()
    pcall(function() gui:Destroy() end)
end)
end

local sidebar=Instance.new("Frame",main)
sidebar.Size=UDim2.new(0,195,1,-HH); sidebar.Position=UDim2.new(0,0,0,HH)
sidebar.BackgroundColor3=DARK.sidebar; sidebar.BorderSizePixel=0

-- Search Bar in Sidebar (540 HUB Style)
local searchCont=Instance.new("Frame",sidebar)
searchCont.Size=UDim2.new(1,-20,0,34); searchCont.Position=UDim2.new(0,10,0,10)
searchCont.BackgroundColor3=DARK.searchBg; searchCont.BorderSizePixel=0
Instance.new("UICorner",searchCont).CornerRadius=UDim.new(0,8)
local scStroke=Instance.new("UIStroke",searchCont); scStroke.Color=DARK.border; scStroke.Thickness=1

local sIcon=Instance.new("TextLabel",searchCont)
sIcon.Size=UDim2.new(0,24,1,0); sIcon.Position=UDim2.new(0,6,0,0)
sIcon.BackgroundTransparency=1; sIcon.Text="🔍"; sIcon.TextColor3=DARK.accent; sIcon.TextSize=12
sIcon.Font=FONT

local searchInput=Instance.new("TextBox",searchCont)
searchInput.Size=UDim2.new(1,-34,1,0); searchInput.Position=UDim2.new(0,30,0,0)
searchInput.BackgroundTransparency=1; searchInput.PlaceholderText="Search"
searchInput.PlaceholderColor3=DARK.subtext; searchInput.Text=""
searchInput.TextColor3=Color3.new(1,1,1); searchInput.Font=FONT_MEDIUM; searchInput.TextSize=12
searchInput.TextXAlignment=Enum.TextXAlignment.Left; searchInput.ClearTextOnFocus=false

local tabs={}; local pages={}
local tabCont=Instance.new("ScrollingFrame",sidebar)
tabCont.Size=UDim2.new(1,0,1,-130); tabCont.Position=UDim2.new(0,0,0,50)
tabCont.BackgroundTransparency=1; tabCont.BorderSizePixel=0; tabCont.ScrollBarThickness=2
tabCont.ScrollBarImageColor3=DARK.accent; tabCont.CanvasSize=UDim2.new(0,0,0,0)
tabCont.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UIListLayout",tabCont).Padding=UDim.new(0,3)
local tp=Instance.new("UIPadding",tabCont)
tp.PaddingTop=UDim.new(0,4); tp.PaddingLeft=UDim.new(0,10); tp.PaddingRight=UDim.new(0,10)

-- Header Banner Generator for Pages (540 HUB style purple banner)
local function createPageBanner(parent, tabName)
    local banner=Instance.new("Frame",parent)
    banner.Size=UDim2.new(1,0,0,56); banner.BackgroundColor3=DARK.banner; banner.BorderSizePixel=0
    Instance.new("UICorner",banner).CornerRadius=UDim.new(0,10)

    local bGrad=Instance.new("UIGradient",banner)
    bGrad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 35, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 10, 215))
    })

    local bIconBg=Instance.new("Frame",banner)
    bIconBg.Size=UDim2.new(0,38,0,38); bIconBg.Position=UDim2.new(0,10,0.5,-19)
    bIconBg.BackgroundColor3=Color3.fromRGB(50, 15, 80); bIconBg.BackgroundTransparency=0.3; bIconBg.BorderSizePixel=0
    Instance.new("UICorner",bIconBg).CornerRadius=UDim.new(0,8)

    local bLogo=Instance.new("ImageLabel",bIconBg)
    bLogo.Size=UDim2.new(0,28,0,28); bLogo.Position=UDim2.new(0.5,-14,0.5,-14)
    bLogo.BackgroundTransparency=1; bLogo.Image="rbxthumb://type=Asset&id=86571453491468&w=420&h=420"
    bLogo.ScaleType=Enum.ScaleType.Fit

    local bTitle=Instance.new("TextLabel",banner)
    bTitle.Size=UDim2.new(1,-240,0,18); bTitle.Position=UDim2.new(0,58,0,10)
    bTitle.BackgroundTransparency=1; bTitle.Text="540HUB BY REKTZ"
    bTitle.TextColor3=Color3.new(1,1,1); bTitle.TextXAlignment=Enum.TextXAlignment.Left
    bTitle.Font=FONT_BOLD; bTitle.TextSize=15

    local bSub=Instance.new("TextLabel",banner)
    bSub.Size=UDim2.new(1,-240,0,16); bSub.Position=UDim2.new(0,58,0,30)
    bSub.BackgroundTransparency=1; bSub.Text="สคริปต์ Anime Dice ของ 540 HUB (" .. tostring(tabName) .. ")"
    bSub.TextColor3=Color3.fromRGB(240,225,255); bSub.TextXAlignment=Enum.TextXAlignment.Left
    bSub.Font=FONT_MEDIUM; bSub.TextSize=12

    -- Server Controls (Rejoin & Hop Server)
    local actRow=Instance.new("Frame", banner)
    actRow.Size=UDim2.new(0, 160, 0, 30); actRow.Position=UDim2.new(1, -168, 0.5, -15)
    actRow.BackgroundTransparency=1
    local arL=Instance.new("UIListLayout", actRow)
    arL.FillDirection=Enum.FillDirection.Horizontal; arL.Padding=UDim.new(0, 6)

    local rjBtn=Instance.new("TextButton", actRow)
    rjBtn.Size=UDim2.new(0, 75, 1, 0); rjBtn.BackgroundColor3=Color3.fromRGB(38, 12, 70); rjBtn.BorderSizePixel=0
    rjBtn.Text="🔄 Rejoin"; rjBtn.TextColor3=Color3.fromRGB(245, 235, 255); rjBtn.Font=FONT_BOLD; rjBtn.TextSize=11
    Instance.new("UICorner", rjBtn).CornerRadius=UDim.new(0, 6)
    local rjStroke=Instance.new("UIStroke", rjBtn); rjStroke.Color=Color3.fromRGB(180, 90, 255); rjStroke.Thickness=1

    local hopBtn=Instance.new("TextButton", actRow)
    hopBtn.Size=UDim2.new(0, 78, 1, 0); hopBtn.BackgroundColor3=Color3.fromRGB(38, 12, 70); hopBtn.BorderSizePixel=0
    hopBtn.Text="🌐 Hop Server"; hopBtn.TextColor3=Color3.fromRGB(245, 235, 255); hopBtn.Font=FONT_BOLD; hopBtn.TextSize=11
    Instance.new("UICorner", hopBtn).CornerRadius=UDim.new(0, 6)
    local hopStroke=Instance.new("UIStroke", hopBtn); hopStroke.Color=Color3.fromRGB(180, 90, 255); hopStroke.Thickness=1

    rjBtn.MouseButton1Click:Connect(function()
        showNotif("กำลังเชื่อมต่อเข้าเซิฟเวอร์เดิม...")
        task.wait(0.3)
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, LP)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
            end
        end)
    end)

    hopBtn.MouseButton1Click:Connect(function()
        showNotif("กำลังค้นหาเซิฟเวอร์ใหม่...")
        task.spawn(function()
            local placeId = game.PlaceId
            local serversUrl = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
            local httpReq = getHttpRequestFunc()
            if not httpReq then
                TeleportService:Teleport(placeId, LP)
                return
            end
            local ok, res = pcall(function()
                return httpReq({ Url = serversUrl, Method = "GET" })
            end)
            if ok and res and res.Body then
                local decodeOk, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                if decodeOk and data and data.data then
                    local serverList = {}
                    for _, s in ipairs(data.data) do
                        if type(s) == "table" and s.id and s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                            table.insert(serverList, s.id)
                        end
                    end
                    if #serverList > 0 then
                        local targetServer = serverList[math.random(1, #serverList)]
                        showNotif("พบเซิฟเวอร์! กำลังวาป...")
                        TeleportService:TeleportToPlaceInstance(placeId, targetServer, LP)
                        return
                    end
                end
            end
            showNotif("ไม่พบเซิฟเวอร์ว่าง วาปแบบสุ่มแทน...")
            TeleportService:Teleport(placeId, LP)
        end)
    end)

    return banner
end

local function createTab(name,icon)
    local btn=Instance.new("TextButton",tabCont)
    btn.Size=UDim2.new(1,0,0,38); btn.BackgroundColor3=DARK.itemSel
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0; btn.Text=""
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

    local ico=Instance.new("TextLabel",btn)
    ico.Size=UDim2.new(0,24,1,0); ico.Position=UDim2.new(0,10,0,0)
    ico.BackgroundTransparency=1; ico.Text=icon; ico.TextColor3=DARK.subtext
    ico.TextXAlignment=Enum.TextXAlignment.Left; ico.Font=FONT; ico.TextSize=15

    local lbl=Instance.new("TextLabel",btn)
    lbl.Size=UDim2.new(1,-42,1,0); lbl.Position=UDim2.new(0,38,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=DARK.subtext
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Font=FONT_BOLD; lbl.TextSize=13

    local page=Instance.new("ScrollingFrame",main)
    page.Size=UDim2.new(1,-215,1,-HH-18); page.Position=UDim2.new(0,205,0,HH+9)
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=6; page.ScrollBarImageColor3=Color3.fromRGB(170, 90, 255)
    page.ScrollBarImageTransparency=0.2; page.ScrollingDirection=Enum.ScrollingDirection.Y
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false
    page.VerticalScrollBarInset=Enum.ScrollBarInset.ScrollBar
    Instance.new("UICorner", page).CornerRadius=UDim.new(0, 4)

    local pageLayout=Instance.new("UIListLayout",page)
    pageLayout.Padding=UDim.new(0,8)
    local pp=Instance.new("UIPadding",page)
    pp.PaddingTop=UDim.new(0,4); pp.PaddingRight=UDim.new(0,10); pp.PaddingBottom=UDim.new(0,24)

    local function updatePageCanvas()
        local h = pageLayout.AbsoluteContentSize.Y
        if h > 0 then
            page.CanvasSize = UDim2.new(0, 0, 0, h + 36)
        end
    end
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)
    page:GetPropertyChangedSignal("Visible"):Connect(function()
        if page.Visible then
            task.defer(updatePageCanvas)
        end
    end)
    page.ChildAdded:Connect(function() task.defer(updatePageCanvas) end)
    page.ChildRemoved:Connect(function() task.defer(updatePageCanvas) end)

    -- Auto-insert 540 HUB Banner at top of page
    createPageBanner(page, name)

    tabs[name]={btn=btn, lbl=lbl, ico=ico, updateCanvas=updatePageCanvas}
    pages[name]=page

    btn.MouseButton1Click:Connect(function()
        for n,t in pairs(tabs) do
            t.btn.BackgroundTransparency=1
            pages[n].Visible=false
            t.lbl.TextColor3=DARK.subtext
            t.ico.TextColor3=DARK.subtext
        end
        btn.BackgroundTransparency=0
        btn.BackgroundColor3=DARK.itemSel
        page.Visible=true
        lbl.TextColor3=Color3.new(1,1,1)
        ico.TextColor3=DARK.accent
        task.defer(updatePageCanvas)
    end)
end

-- Search functionality
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local q = searchInput.Text:lower():gsub("%s+", "")
    for n, t in pairs(tabs) do
        if q == "" or n:lower():find(q) then
            t.btn.Visible = true
        else
            t.btn.Visible = false
        end
    end
end)

createTab("Main","🏠"); createTab("Roll","🎲"); createTab("Skill","⚡")
createTab("Tower","🏰"); createTab("Potion","🧪"); createTab("Quest & Rebirth","📜")
createTab("Teleport","🗺️"); createTab("Utility","⚙️"); createTab("Misc","💾"); createTab("Settings","🛠️")

-- Ensure all tabs have their canvas heights calculated accurately
task.spawn(function()
    task.wait(0.5)
    for _, t in pairs(tabs) do
        if t.updateCanvas then pcall(t.updateCanvas) end
    end
end)

tabs["Main"].btn.BackgroundTransparency=0
tabs["Main"].btn.BackgroundColor3=DARK.itemSel
pages["Main"].Visible=true
tabs["Main"].lbl.TextColor3=Color3.new(1,1,1)
tabs["Main"].ico.TextColor3=DARK.accent
-- main.Visible will be enabled by Loading Screen after 100% + 2s delay
gui.Enabled=true

-- User Profile in Sidebar Footer (540 HUB style)
do
local uPanel=Instance.new("Frame",sidebar)
uPanel.Size=UDim2.new(1,-16,0,54); uPanel.Position=UDim2.new(0,8,1,-62)
uPanel.BackgroundColor3=DARK.card; uPanel.BorderSizePixel=0
Instance.new("UICorner",uPanel).CornerRadius=UDim.new(0,8)
local upStroke=Instance.new("UIStroke",uPanel); upStroke.Color=DARK.border; upStroke.Thickness=1

local uAv=Instance.new("ImageLabel",uPanel)
uAv.Size=UDim2.new(0,36,0,36); uAv.Position=UDim2.new(0,8,0.5,-18)
uAv.BackgroundColor3=Color3.fromRGB(30,22,42); uAv.BorderSizePixel=0
Instance.new("UICorner",uAv).CornerRadius=UDim.new(1,0)
local avStroke=Instance.new("UIStroke",uAv); avStroke.Color=DARK.accent; avStroke.Thickness=1

local uNm=Instance.new("TextLabel",uPanel)
uNm.Size=UDim2.new(1,-54,0,16); uNm.Position=UDim2.new(0,50,0,10)
uNm.BackgroundTransparency=1; uNm.Text=LP.DisplayName or LP.Name
uNm.TextColor3=Color3.new(1,1,1); uNm.TextXAlignment=Enum.TextXAlignment.Left
uNm.Font=FONT_BOLD; uNm.TextSize=13; uNm.TextTruncate=Enum.TextTruncate.AtEnd

local uId=Instance.new("TextLabel",uPanel)
uId.Size=UDim2.new(1,-54,0,16); uId.Position=UDim2.new(0,50,0,28)
uId.BackgroundTransparency=1; uId.Text="@"..LP.Name
uId.TextColor3=DARK.subtext; uId.TextXAlignment=Enum.TextXAlignment.Left
uId.Font=FONT_MEDIUM; uId.TextSize=11; uId.TextTruncate=Enum.TextTruncate.AtEnd

task.spawn(function()
    local ok,t=pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
    if ok and t then uAv.Image=t end
end)
end

-- Component Builders (540 HUB Signature Components)
local function makeToggle(parent,label,sublabel,initial,cb)
    local h=sublabel and 60 or 46
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local cStroke=Instance.new("UIStroke",c); cStroke.Color=DARK.border; cStroke.Thickness=1

    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-70,0,22); l.Position=UDim2.new(0,14,0,sublabel and 8 or 12)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT_BOLD; l.TextSize=14

    if sublabel then
        local s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-70,0,18); s.Position=UDim2.new(0,14,0,32)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT_MEDIUM; s.TextSize=11
    end

    -- 540 HUB Toggle Switch Capsule
    local sw=Instance.new("Frame",c)
    sw.Size=UDim2.new(0,42,0,22); sw.Position=UDim2.new(1,-54,0.5,-11)
    sw.BackgroundColor3=initial and DARK.tOn or DARK.tOff; sw.BorderSizePixel=0
    Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)

    local k=Instance.new("Frame",sw)
    k.Size=UDim2.new(0,16,0,16)
    k.Position=initial and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    k.BackgroundColor3=Color3.new(1,1,1); k.BorderSizePixel=0
    Instance.new("UICorner",k).CornerRadius=UDim.new(1,0)

    local st=initial
    local function setVisual(val)
        st = (val == true)
        sw.BackgroundColor3 = st and DARK.tOn or DARK.tOff
        TweenService:Create(k,TweenInfo.new(0.18, Enum.EasingStyle.Quad),{
            Position=st and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    end

    local btn=Instance.new("TextButton",c)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Click:Connect(function()
        st=not st
        setVisual(st)
        cb(st)
    end)
    return setVisual,sw,k
end

local registeredToggles = {}
local function makeCfgToggle(parent,cfgKey,label,sublabel,extraCb)
    local setVis = makeToggle(parent,label,sublabel,CFG[cfgKey],function(val)
        CFG[cfgKey] = val
        if extraCb then pcall(extraCb, val) end
    end)
    registeredToggles[cfgKey] = { set = setVis, cb = extraCb }
    return setVis
end

local function makeButton(parent,label,sublabel,btnText,cb)
    local h=sublabel and 60 or 46
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local cStroke=Instance.new("UIStroke",c); cStroke.Color=DARK.border; cStroke.Thickness=1

    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-130,0,22); l.Position=UDim2.new(0,14,0,sublabel and 8 or 12)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT_BOLD; l.TextSize=14

    if sublabel then
        local s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-130,0,18); s.Position=UDim2.new(0,14,0,32)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT_MEDIUM; s.TextSize=11
    end

    local actionBtn=Instance.new("TextButton",c)
    actionBtn.Size=UDim2.new(0,102,0,32); actionBtn.Position=UDim2.new(1,-114,0.5,-16)
    actionBtn.BackgroundColor3=Color3.fromRGB(42,26,62); actionBtn.BorderSizePixel=0
    actionBtn.Text=btnText or "Click 🪄"; actionBtn.TextColor3=Color3.fromRGB(255,150,245)
    actionBtn.Font=FONT_BOLD; actionBtn.TextSize=12
    Instance.new("UICorner",actionBtn).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",actionBtn)
    stroke.Color=DARK.accent; stroke.Thickness=1

    local busy=false
    actionBtn.MouseButton1Click:Connect(function()
        if busy then return end
        busy=true
        TweenService:Create(actionBtn,TweenInfo.new(0.08),{BackgroundColor3=DARK.accent,TextColor3=Color3.new(1,1,1)}):Play()
        task.wait(0.1)
        TweenService:Create(actionBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(36,24,54),TextColor3=Color3.fromRGB(255,140,240)}):Play()
        pcall(cb)
        task.wait(0.2)
        busy=false
    end)
    return c
end

local function makeInput(parent,label,sublabel,defaultVal,cb)
    local h=sublabel and 60 or 46
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local cStroke=Instance.new("UIStroke",c); cStroke.Color=DARK.border; cStroke.Thickness=1

    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-130,0,22); l.Position=UDim2.new(0,14,0,sublabel and 8 or 12)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT_BOLD; l.TextSize=14

    if sublabel then
        local s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-130,0,18); s.Position=UDim2.new(0,14,0,32)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT_MEDIUM; s.TextSize=11
    end

    local tb=Instance.new("TextBox",c)
    tb.Size=UDim2.new(0,88,0,28); tb.Position=UDim2.new(1,-98,0.5,-14)
    tb.BackgroundColor3=DARK.inputBg; tb.BorderSizePixel=0
    tb.Text=tostring(defaultVal or ""); tb.TextColor3=Color3.fromRGB(245,240,255)
    tb.Font=FONT_BOLD; tb.TextSize=12; tb.ClearTextOnFocus=false
    tb.TextXAlignment=Enum.TextXAlignment.Center
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",tb)
    stroke.Color=DARK.border; stroke.Thickness=1

    tb.FocusLost:Connect(function()
        local num = tonumber(tb.Text)
        if num and num > 0 then
            cb(math.floor(num))
        else
            tb.Text = tostring(defaultVal or 50)
            cb(defaultVal or 50)
        end
    end)
    return c, tb
end

local function makeSelector(parent,label,sublabel,options,defaultIdx,cb)
    local h=sublabel and 60 or 46
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local cStroke=Instance.new("UIStroke",c); cStroke.Color=DARK.border; cStroke.Thickness=1

    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-185,0,22); l.Position=UDim2.new(0,14,0,sublabel and 8 or 12)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT_BOLD; l.TextSize=14
    local s=nil
    if sublabel then
        local sLbl=Instance.new("TextLabel",c)
        sLbl.Size=UDim2.new(1,-185,0,18); sLbl.Position=UDim2.new(0,14,0,32)
        sLbl.BackgroundTransparency=1; sLbl.Text=sublabel; sLbl.TextColor3=DARK.subtext
        sLbl.TextXAlignment=Enum.TextXAlignment.Left; sLbl.Font=FONT_MEDIUM; sLbl.TextSize=11
        s = sLbl
    end

    local selBtn=Instance.new("TextButton",c)
    selBtn.Size=UDim2.new(0,155,0,32); selBtn.Position=UDim2.new(1,-165,0.5,-16)
    selBtn.BackgroundColor3=DARK.inputBg; selBtn.BorderSizePixel=0
    selBtn.Font=FONT_BOLD; selBtn.TextSize=12; selBtn.TextColor3=Color3.fromRGB(245,240,255)
    Instance.new("UICorner",selBtn).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",selBtn)
    stroke.Color=DARK.border; stroke.Thickness=1

    local curIdx = defaultIdx or 1
    local function updateDisplay()
        local opt = options[curIdx]
        selBtn.Text = opt.text
        if s and opt.sub then
            s.Text = opt.sub
        end
    end
    updateDisplay()

    selBtn.MouseButton1Click:Connect(function()
        curIdx = curIdx + 1
        if curIdx > #options then curIdx = 1 end
        updateDisplay()
        cb(options[curIdx].value, curIdx)
    end)

    local function setVal(v)
        for i, opt in ipairs(options) do
            if opt.value == v then
                curIdx = i
                updateDisplay()
                break
            end
        end
    end

    return c, setVal
end

local plotLvlBox, setPlotMode, setRollDelay, setEquipMode
local dropMenu, dropBtn, refreshTowerOpts, updateDropBtnText
local skillDropMenu, skillDropBtn, refreshSkillOpts, updateSkillDropBtnText
local luckDropMenu, luckDropBtn, refreshLuckOpts, updateLuckDropBtnText
local cfgDropMenu, cfgDropBtn

-- ── Main tab ─────────────────────────────────────────────────────────────────
local function setupMainTab()
makeCfgToggle(pages["Main"],"AutoCollect","Auto Collect","เก็บเงินอัตโนมัติจากทุก Plot (15 ช่อง)")
makeButton(pages["Main"],"Collect Cash Now","กดเพื่อเก็บเงินจากทุกช่องทันที 1 ครั้ง","Collect",function()
    collectAll()
end)
makeCfgToggle(pages["Main"],"AutoUpgradePlot","Auto Upgrade Plot Lvl","อัปเกรดเลเวลยูนิตใน Plot อัตโนมัติ")
local _, plb = makeInput(pages["Main"],"Target Plot Level","ตั้งเป้าหมายเลเวลที่ต้องการอัปเกรด (เช่น 50)", CFG.PlotTargetLvl, function(val) CFG.PlotTargetLvl=val end)
plotLvlBox = plb
local _, spm = makeSelector(pages["Main"],"Upgrade Mode","อัปเกรดเฉลี่ยทุกตัวใน Plot ให้เลเวลเท่าๆ กัน",{
    { text = "Equal (Balanced)",  value = "Equal",  sub = "อัปเกรดเฉลี่ยทุกตัวใน Plot ให้เลเวลเท่าๆ กัน" },
    { text = "Focus (One by One)", value = "Single", sub = "อัปเกรดทีละตัวใน Plot ให้ถึงเป้าหมายก่อน" },
}, 1, function(val) CFG.PlotUpgradeMode=val end)
setPlotMode = spm
makeCfgToggle(pages["Main"],"AutoEquip","Auto Equip Best","สวมใส่ยูนิตที่ดีที่สุดลง Plot อัตโนมัติ")
local _, sem = makeSelector(pages["Main"],"Equip Priority","เลือกเกณฑ์ในการคัดเลือกยูนิตที่ดีที่สุด",{
    { text = "Rarity (1 in X)", value = "Rarity", sub = "เรียงจากตัวที่หายากที่สุดก่อน (เช่น 1 in 10qi > 7qi > 5qi)" },
    { text = "Income ($/s)",    value = "Income", sub = "เรียงจากตัวที่ทำเงินได้สูงสุดต่อวินาที (ตามระบบเกมเดิม)" },
}, CFG.AutoEquipMode == "Income" and 2 or 1, function(val) CFG.AutoEquipMode = val end)
setEquipMode = sem
makeButton(pages["Main"],"Equip Best Now","กดเพื่อจัดยูนิตลง Plot ทันทีตามเกณฑ์ที่เลือก","Equip",function()
    print("[CHEAT HUB] Clicked Equip Best Now (Mode: " .. tostring(CFG.AutoEquipMode) .. ")")
    if CFG.AutoEquipMode == "Rarity" then
        equipBestByRarity(true)
    else
        pcall(function() EquipBest:FireServer() end)
        showNotif("สวมใส่ยูนิตที่ทำเงินสูงสุดเรียบร้อย ✓")
    end
end)
-- [TEMPORARILY HIDDEN FROM MAIN TAB]
-- makeCfgToggle(pages["Main"],"AutoClaimRewards","Auto Claim Free Rewards","รับของรางวัลฟรีทั้งหมดอัตโนมัติ (Daily Login, Group Chest, และ Offline Cash)")
-- makeButton(pages["Main"],"Claim Free Rewards Now","กดรับ Daily Login, Group Chest, และ Offline Cash ทันที 1 ครั้ง","Claim All",function()
--     claimAllFreeRewards(true)
-- end)
end
pcall(setupMainTab)

-- ── Roll tab ──────────────────────────────────────────────────────────────────
local function setupRollTab()
makeCfgToggle(pages["Roll"],"FastAutoRoll","Fast Auto Roll","ทอยลูกเต๋าแบบเร็วพิเศษ ปรับอัตราส่งข้อมูลปลอดภัยไม่หลุดเซิร์ฟ")
local _, srd = makeSelector(pages["Roll"],"Roll Delay","ปรับความเร็วการส่งคำสั่งทอยลูกเต๋า",{
    { text = "0.15s (Ultra Fast)", value = 0.15, sub = "เร็วสูงสุดพร้อมระบบกัน Packet หลุดสำหรับ Emulator" },
    { text = "0.2s (Fast)",        value = 0.2,  sub = "ยิงทุก 0.2s รวดเร็วและเสถียรมาก" },
    { text = "0.5s (Medium)",      value = 0.5,  sub = "ทอยเร็วปานกลางทุก 0.5s" },
    { text = "1.0s (Normal)",      value = 1.0,  sub = "ทอยทุก 1 วินาที" },
    { text = "2.6s (Default)",     value = 2.6,  sub = "ทอยตามความเร็วพื้นฐานเดิมของเกม" },
}, 1, function(val) CFG.RollDelay = val end)
setRollDelay = srd
makeCfgToggle(pages["Roll"],"SkipCutscene","Skip Roll Cutscene (Fast)","ข้ามฉากคัตซีนแรร์ ไม่ล็อกมุมกล้อง ไม่เสียเวลาคัตซีน")

-- Auto Sell & Cash Notification Controls
makeCfgToggle(pages["Roll"],"AutoSellRolled","Auto Sell Rolled Units","ขายยูนิตขยะที่สุ่มได้โดยอัตโนมัติ (Server + Client Sync)")
makeSelector(pages["Roll"],"Auto Sell Threshold","เลือกระดับโอกาสที่จะให้ขายทิ้งทันทีเมื่อสุ่มได้",{
    { text = "< 100 (Common)",        value = 100,      sub = "ขายเฉพาะตัวธรรมดาต่ำกว่า 1 ใน 100" },
    { text = "< 1,000 (Rare)",        value = 1000,     sub = "ขายยูนิตต่ำกว่า 1 ใน 1,000" },
    { text = "< 10,000 (Epic)",       value = 10000,    sub = "ขายยูนิตต่ำกว่า 1 ใน 10,000" },
    { text = "< 100,000 (Legendary)", value = 100000,   sub = "ขายยูนิตต่ำกว่า 1 ใน 100,000" },
    { text = "< 1,000,000 (Mythic)",  value = 1000000,  sub = "ขายยูนิตต่ำกว่า 1 ใน 1,000,000" },
}, 2, function(val)
    CFG.AutoSellThreshold = val
    syncInGameAutoSell(val)
end)
makeCfgToggle(pages["Roll"],"AutoCleanInventory","Auto Clean Full Inventory","เคลียร์กระเป๋ายูนิตอัตโนมัติเมื่อใกล้เต็ม ป้องกัน Roll ติดขัด")
makeCfgToggle(pages["Roll"],"ShowRollCashNotif","Show Roll Cash Notif","แสดงการแจ้งเตือนเงินที่ได้รับเมื่อขายตัวจากการสุ่ม")
makeButton(pages["Roll"],"Sell Inventory Junk Now","กดขายยูนิตขยะทั้งหมดในกระเป๋าทันที 1 ครั้งตามเกณฑ์ด้านบน","Sell Junk",function()
    cleanInventoryAutoSell(true)
end)

makeCfgToggle(pages["Roll"],"AutoBuyDice","Auto Buy Best Dice","ซื้อลูกเต๋าที่มีค่าโชคสูงสุดอัตโนมัติ")
end
pcall(setupRollTab)

-- ── Skill tab ─────────────────────────────────────────────────────────────────
local function setupSkillTab()
makeCfgToggle(pages["Skill"],"AutoUpgrade","Auto Upgrade Skills","อัปเกรด Skill Tree ตามสายที่เลือกอัตโนมัติ")

local skillDropCard=Instance.new("Frame",pages["Skill"])
skillDropCard.Size=UDim2.new(1,0,0,52); skillDropCard.BackgroundColor3=DARK.item; skillDropCard.BorderSizePixel=0
Instance.new("UICorner",skillDropCard).CornerRadius=UDim.new(0,8)

local sTitle=Instance.new("TextLabel",skillDropCard)
sTitle.Size=UDim2.new(1,-170,0,18); sTitle.Position=UDim2.new(0,14,0,7)
sTitle.BackgroundTransparency=1; sTitle.Text="Select Skill Branches"
sTitle.TextColor3=DARK.text; sTitle.TextXAlignment=Enum.TextXAlignment.Left; sTitle.Font=FONT_BOLD; sTitle.TextSize=14

local sSub=Instance.new("TextLabel",skillDropCard)
sSub.Size=UDim2.new(1,-170,0,14); sSub.Position=UDim2.new(0,14,0,28)
sSub.BackgroundTransparency=1; sSub.Text="เลือกสายสกิลที่ต้องการให้อัปเกรด (เลือกได้หลายสาย)"
sSub.TextColor3=DARK.subtext; sSub.TextXAlignment=Enum.TextXAlignment.Left; sSub.Font=FONT_MEDIUM; sSub.TextSize=11

skillDropBtn=Instance.new("TextButton",skillDropCard)
skillDropBtn.Size=UDim2.new(0,155,0,30); skillDropBtn.Position=UDim2.new(1,-165,0.5,-15)
skillDropBtn.BackgroundColor3=Color3.fromRGB(34,25,52); skillDropBtn.BorderSizePixel=0
skillDropBtn.Text="Select Branches  ▾"; skillDropBtn.TextColor3=Color3.fromRGB(245,235,255)
skillDropBtn.Font=FONT_BOLD; skillDropBtn.TextSize=12
Instance.new("UICorner",skillDropBtn).CornerRadius=UDim.new(0,6)
local skillDropBtnStroke=Instance.new("UIStroke",skillDropBtn)
skillDropBtnStroke.Color=DARK.purple; skillDropBtnStroke.Thickness=1.2

local SKILL_ITEM_H = 30
local SKILL_PADDING = 2
local totalSkillHeight = #SKILL_BRANCHES * (SKILL_ITEM_H + SKILL_PADDING) + 10

skillDropMenu=Instance.new("ScrollingFrame",main)
skillDropMenu.Size=UDim2.new(0,210,0,math.min(180, totalSkillHeight))
skillDropMenu.BackgroundColor3=DARK.dropdown
skillDropMenu.BorderSizePixel=0; skillDropMenu.ScrollBarThickness=4
skillDropMenu.ScrollBarImageColor3=DARK.purple; skillDropMenu.Visible=false; skillDropMenu.ZIndex=100
skillDropMenu.CanvasSize=UDim2.new(0, 0, 0, totalSkillHeight)
skillDropMenu.AutomaticCanvasSize=Enum.AutomaticSize.None
Instance.new("UICorner",skillDropMenu).CornerRadius=UDim.new(0,8)
local sdmStroke=Instance.new("UIStroke",skillDropMenu); sdmStroke.Color=DARK.border; sdmStroke.Thickness=1.5
local sdList=Instance.new("UIListLayout",skillDropMenu); sdList.Padding=UDim.new(0,SKILL_PADDING)
local sdPad=Instance.new("UIPadding",skillDropMenu)
sdPad.PaddingTop=UDim.new(0,5); sdPad.PaddingBottom=UDim.new(0,5)
sdPad.PaddingLeft=UDim.new(0,5); sdPad.PaddingRight=UDim.new(0,5)

updateSkillDropBtnText = function()
    local count=0
    for _,sel in pairs(SelectedSkills) do if sel then count=count+1 end end
    if count==0 then
        skillDropBtn.Text="Select Branches  ▾"
        skillDropBtn.TextColor3=Color3.fromRGB(240,230,255)
    else
        skillDropBtn.Text=string.format("Selected (%d)  ▾", count)
        skillDropBtn.TextColor3=DARK.hAccent
    end
end

local function toggleSkillDropdown()
    if skillDropMenu.Visible then
        skillDropMenu.Visible=false
    else
        if dropMenu then dropMenu.Visible=false end
        local absPos=skillDropBtn.AbsolutePosition
        local mainPos=main.AbsolutePosition
        skillDropMenu.Position=UDim2.new(0, absPos.X-mainPos.X-60, 0, absPos.Y-mainPos.Y+32)
        skillDropMenu.Visible=true
    end
end

skillDropBtn.MouseButton1Click:Connect(toggleSkillDropdown)

refreshSkillOpts = {}
for _, branch in ipairs(SKILL_BRANCHES) do
    local opt=Instance.new("TextButton",skillDropMenu)
    opt.Size=UDim2.new(1,0,0,SKILL_ITEM_H); opt.BackgroundColor3=DARK.item; opt.BackgroundTransparency=1
    opt.BorderSizePixel=0; opt.Text=""; opt.ZIndex=101
    Instance.new("UICorner",opt).CornerRadius=UDim.new(0,6)

    local chk=Instance.new("TextLabel",opt)
    chk.Size=UDim2.new(0,18,1,0); chk.Position=UDim2.new(0,6,0,0)
    chk.BackgroundTransparency=1; chk.Text="○"; chk.TextColor3=DARK.subtext
    chk.Font=FONT; chk.TextSize=12; chk.ZIndex=102

    local oName=Instance.new("TextLabel",opt)
    oName.Size=UDim2.new(1,-28,1,0); oName.Position=UDim2.new(0,26,0,0)
    oName.BackgroundTransparency=1; oName.Text=branch.name; oName.TextColor3=DARK.text
    oName.TextXAlignment=Enum.TextXAlignment.Left; oName.Font=FONT; oName.TextSize=11; oName.ZIndex=102

    local function refreshOpt()
        local isSel=SelectedSkills[branch.name]==true
        chk.Text=isSel and "✓" or "○"
        chk.TextColor3=isSel and DARK.hAccent or DARK.subtext
        oName.TextColor3=isSel and Color3.new(1,1,1) or DARK.text
        opt.BackgroundTransparency=isSel and 0 or 1
        opt.BackgroundColor3=isSel and DARK.itemSel or DARK.item
    end

    opt.MouseButton1Click:Connect(function()
        SelectedSkills[branch.name]=not SelectedSkills[branch.name]
        refreshOpt()
        updateSkillDropBtnText()
    end)
    table.insert(refreshSkillOpts, refreshOpt)
    refreshOpt()
end
updateSkillDropBtnText()

end
pcall(setupSkillTab)

-- ── Tower tab ─────────────────────────────────────────────────────────────────
local function setupTowerTab()

-- ── Potion tab (Luck / Cash / Damage Multi-Category Engine) ─────────────────────
local function setupPotionTab()
    local curPotionType = CFG.PotionType or "Luck"

    local pTitle, pSub, pStatusLbl
    local updateCategoryDropdown

    -- 1. Selector for Potion Category Type (Luck / Cash / Damage)
    makeSelector(pages["Potion"], "Select Potion Type", "เลือกหมวดหมู่น้ำยาที่ต้องการใช้งาน (Luck / Cash / Damage)", {
        { text = "🍀 Luck Potions",   value = "Luck",   sub = "เน้นเพิ่มค่าโชคในการทอย (Luck I-IV + 5 สายพิเศษ)" },
        { text = "💰 Cash Potions",   value = "Cash",   sub = "เน้นเพิ่มตัวคูณเงินจาก Plot (Income I-IV + 5 สายพิเศษ)" },
        { text = "⚔️ Damage Potions", value = "Damage", sub = "เน้นเพิ่มพลังโจมตีหอคอย (Damage I-IV + 5 สายพิเศษ)" },
    }, (curPotionType == "Cash" and 2) or (curPotionType == "Damage" and 3) or 1, function(val)
        CFG.PotionType = val
        curPotionType = val
        if updateCategoryDropdown then updateCategoryDropdown() end
    end)

    -- 2. Card for Branches Selection & Active Status
    local potionDropCard = Instance.new("Frame", pages["Potion"])
    potionDropCard.Size = UDim2.new(1, 0, 0, 96); potionDropCard.BackgroundColor3 = DARK.item; potionDropCard.BorderSizePixel = 0
    Instance.new("UICorner", potionDropCard).CornerRadius = UDim.new(0, 8)
    local pdcStroke = Instance.new("UIStroke", potionDropCard); pdcStroke.Color = DARK.border; pdcStroke.Thickness = 1

    pTitle = Instance.new("TextLabel", potionDropCard)
    pTitle.Size = UDim2.new(1, -190, 0, 20); pTitle.Position = UDim2.new(0, 14, 0, 10)
    pTitle.BackgroundTransparency = 1; pTitle.Text = "🧪 Potion Branches Manager (6 Themes)"
    pTitle.TextColor3 = DARK.text; pTitle.TextXAlignment = Enum.TextXAlignment.Left; pTitle.Font = FONT_BOLD; pTitle.TextSize = 14

    pSub = Instance.new("TextLabel", potionDropCard)
    pSub.Size = UDim2.new(1, -190, 0, 16); pSub.Position = UDim2.new(0, 14, 0, 32)
    pSub.BackgroundTransparency = 1; pSub.Text = "หมวดหมู่: Luck • มีน้ำยาในกระเป๋า: 0 ชิ้น"
    pSub.TextColor3 = DARK.subtext; pSub.TextXAlignment = Enum.TextXAlignment.Left; pSub.Font = FONT_MEDIUM; pSub.TextSize = 11

    pStatusLbl = Instance.new("TextLabel", potionDropCard)
    pStatusLbl.Size = UDim2.new(1, -28, 0, 20); pStatusLbl.Position = UDim2.new(0, 14, 0, 56)
    pStatusLbl.BackgroundTransparency = 1; pStatusLbl.Text = "Active: กำลังตรวจสอบสถานะบัฟ..."
    pStatusLbl.TextColor3 = Color3.fromRGB(80, 255, 160); pStatusLbl.TextXAlignment = Enum.TextXAlignment.Left; pStatusLbl.Font = FONT_MEDIUM; pStatusLbl.TextSize = 11

    luckDropBtn = Instance.new("TextButton", potionDropCard)
    luckDropBtn.Size = UDim2.new(0, 160, 0, 32); luckDropBtn.Position = UDim2.new(1, -174, 0, 14)
    luckDropBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 54); luckDropBtn.BorderSizePixel = 0
    luckDropBtn.Text = "Select Branches (6/6)  ▾"; luckDropBtn.TextColor3 = Color3.fromRGB(245, 235, 255)
    luckDropBtn.Font = FONT_BOLD; luckDropBtn.TextSize = 12
    Instance.new("UICorner", luckDropBtn).CornerRadius = UDim.new(0, 6)
    local ldbStroke = Instance.new("UIStroke", luckDropBtn)
    ldbStroke.Color = DARK.purple; ldbStroke.Thickness = 1.2

    local LUCK_ITEM_H = 34
    local LUCK_PADDING = 2

    luckDropMenu = Instance.new("ScrollingFrame", main)
    luckDropMenu.Size = UDim2.new(0, 235, 0, 220)
    luckDropMenu.BackgroundColor3 = DARK.dropdown
    luckDropMenu.BorderSizePixel = 0; luckDropMenu.ScrollBarThickness = 4
    luckDropMenu.ScrollBarImageColor3 = DARK.purple; luckDropMenu.Visible = false; luckDropMenu.ZIndex = 100
    Instance.new("UICorner", luckDropMenu).CornerRadius = UDim.new(0, 8)
    local ldmStroke = Instance.new("UIStroke", luckDropMenu); ldmStroke.Color = DARK.border; ldmStroke.Thickness = 1.5
    local ldList = Instance.new("UIListLayout", luckDropMenu); ldList.Padding = UDim.new(0, LUCK_PADDING)
    local ldPad = Instance.new("UIPadding", luckDropMenu)
    ldPad.PaddingTop = UDim.new(0, 5); ldPad.PaddingBottom = UDim.new(0, 5)
    ldPad.PaddingLeft = UDim.new(0, 5); ldPad.PaddingRight = UDim.new(0, 5)

    local function toggleLuckDropdown()
        if luckDropMenu.Visible then
            luckDropMenu.Visible = false
        else
            if dropMenu then dropMenu.Visible = false end
            if skillDropMenu then skillDropMenu.Visible = false end
            local absPos = luckDropBtn.AbsolutePosition
            local mainPos = main.AbsolutePosition
            local curScale = (uiScale and uiScale.Scale > 0) and uiScale.Scale or 1
            luckDropMenu.Position = UDim2.new(0, (absPos.X - mainPos.X)/curScale - 60, 0, (absPos.Y - mainPos.Y)/curScale + 36)
            luckDropMenu.Visible = true
        end
    end
    luckDropBtn.MouseButton1Click:Connect(toggleLuckDropdown)

    updateCategoryDropdown = function()
        local pType = CFG.PotionType or "Luck"
        local pData = POTION_DATA[pType]
        if not pData then return end

        pTitle.Text = "🧪 " .. pType .. " Branches Manager (6 Themes)"
        local counts, total = getPotionsInInventory(pType)
        pSub.Text = string.format("หมวดหมู่: %s • มีน้ำยาในกระเป๋า: %d ชิ้น", pType, total)

        for _, child in ipairs(luckDropMenu:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local typeSels = SelectedPotionCategories[pType]
        if not typeSels then
            typeSels = {}
            SelectedPotionCategories[pType] = typeSels
            for _, cat in ipairs(pData.categories) do typeSels[cat.id] = true end
        end

        local totalListHeight = #pData.categories * (LUCK_ITEM_H + LUCK_PADDING) + 12
        luckDropMenu.CanvasSize = UDim2.new(0, 0, 0, totalListHeight)
        luckDropMenu.Size = UDim2.new(0, 235, 0, math.min(220, totalListHeight))

        local function updateBtnText()
            local count = 0
            for _, cat in ipairs(pData.categories) do
                if typeSels[cat.id] ~= false then count = count + 1 end
            end
            luckDropBtn.Text = string.format("Branches (%d/%d)  ▾", count, #pData.categories)
            luckDropBtn.TextColor3 = (count > 0) and DARK.hAccent or Color3.fromRGB(240, 230, 255)
        end
        updateBtnText()

        for _, cat in ipairs(pData.categories) do
            local opt = Instance.new("TextButton", luckDropMenu)
            opt.Size = UDim2.new(1, 0, 0, LUCK_ITEM_H); opt.BackgroundColor3 = DARK.item; opt.BackgroundTransparency = 1
            opt.BorderSizePixel = 0; opt.Text = ""; opt.ZIndex = 101
            Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 6)

            local chk = Instance.new("TextLabel", opt)
            chk.Size = UDim2.new(0, 18, 1, 0); chk.Position = UDim2.new(0, 6, 0, 0)
            chk.BackgroundTransparency = 1; chk.Text = "○"; chk.TextColor3 = DARK.subtext
            chk.Font = FONT_BOLD; chk.TextSize = 13; chk.ZIndex = 102

            local oName = Instance.new("TextLabel", opt)
            oName.Size = UDim2.new(1, -28, 0, 16); oName.Position = UDim2.new(0, 26, 0, 2)
            oName.BackgroundTransparency = 1; oName.Text = cat.name; oName.TextColor3 = DARK.text
            oName.TextXAlignment = Enum.TextXAlignment.Left; oName.Font = FONT_BOLD; oName.TextSize = 12; oName.ZIndex = 102

            local oSub = Instance.new("TextLabel", opt)
            oSub.Size = UDim2.new(1, -28, 0, 14); oSub.Position = UDim2.new(0, 26, 0, 18)
            oSub.BackgroundTransparency = 1; oSub.Text = cat.sub; oSub.TextColor3 = DARK.subtext
            oSub.TextXAlignment = Enum.TextXAlignment.Left; oSub.Font = FONT_MEDIUM; oSub.TextSize = 10; oSub.ZIndex = 102

            local function refreshOpt()
                local isSel = typeSels[cat.id] ~= false
                chk.Text = isSel and "●" or "○"
                chk.TextColor3 = isSel and DARK.hAccent or DARK.subtext
                oName.TextColor3 = isSel and Color3.new(1,1,1) or DARK.text
                opt.BackgroundTransparency = isSel and 0 or 1
                opt.BackgroundColor3 = isSel and DARK.itemSel or DARK.item
            end
            refreshOpt()

            opt.MouseButton1Click:Connect(function()
                typeSels[cat.id] = not (typeSels[cat.id] ~= false)
                refreshOpt()
                updateBtnText()
            end)
        end
    end
    updateCategoryDropdown()

    -- 3. Dedicated "Use Best Now" Button Card (ตามหมวดหมู่ที่เลือก โดยไม่ซ้ำกัน)
    makeButton(pages["Potion"], "Use Best Now", "กดใช้น้ำยาระดับสูงสุดโดยไม่ซ้ำกันตามหมวดหมู่ที่เลือกทันที 1 ครั้ง", "⚡ Use Best", function()
        useBestPotionNow(CFG.PotionType)
    end)

    -- 4. Auto Use Potions Toggle (Auto maintains buffs for selected category type)
    makeCfgToggle(pages["Potion"], "AutoUsePotion", "Auto Use Potions", "กดใช้น้ำยาระดับสูงสุดอัตโนมัติเมื่อเวลาบัฟหมดตามหมวดหมู่ที่เลือก (Luck / Cash / Damage)")

    -- 5. Auto Luck on Luck Event Toggle
    makeCfgToggle(pages["Potion"], "AutoLuckOnEvent", "Auto Luck on Luck Event", "เมื่อ Luck Event เซิร์ฟเวอร์เริ่ม จะกดใช้น้ำยาโชคทุกชนิด (Tier สูงสุด) ทันทีอย่างละ 1 ครั้ง", function(val)
        if val then
            task.spawn(checkEventAutoLuck)
        end
    end)

    -- Background status updater for Potion tab
    task.spawn(function()
        while pages["Potion"] do
            task.wait(1.5)
            pcall(function()
                local pType = (CFG and CFG.PotionType) or "Luck"
                local activeMap = getActivePotionInfo(pType)
                local activeParts = {}
                local pData = POTION_DATA[pType]
                if pData then
                    for _, cat in ipairs(pData.categories) do
                        local cur = activeMap[cat.id]
                        if cur and cur.remaining > 0 then
                            table.insert(activeParts, cur.name .. " (" .. cur.remaining .. "s)")
                        end
                    end
                end
                if #activeParts > 0 then
                    pStatusLbl.Text = "Active: " .. table.concat(activeParts, ", ")
                    pStatusLbl.TextColor3 = Color3.fromRGB(80, 255, 160)
                else
                    pStatusLbl.Text = "Active: ไม่มีน้ำยา " .. pType .. " กำลังทำงานอยู่ (Idle)"
                    pStatusLbl.TextColor3 = DARK.subtext
                end
            end)
        end
    end)
end
pcall(setupPotionTab)

-- Event tab removed
local towerBanner=Instance.new("Frame",pages["Tower"])
towerBanner.Size=UDim2.new(1,0,0,52); towerBanner.BackgroundColor3=Color3.fromRGB(38,18,68); towerBanner.BorderSizePixel=0
Instance.new("UICorner",towerBanner).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",towerBanner).Color=DARK.purple
tBannerTitle=Instance.new("TextLabel",towerBanner)
tBannerTitle.Size=UDim2.new(1,-20,0,18); tBannerTitle.Position=UDim2.new(0,14,0,7)
tBannerTitle.BackgroundTransparency=1; tBannerTitle.TextColor3=Color3.new(1,1,1)
tBannerTitle.TextXAlignment=Enum.TextXAlignment.Left; tBannerTitle.Font=FONT_BOLD; tBannerTitle.TextSize=14
tBannerTitle.Text="🏰 Tower Queue System"

tBannerSub=Instance.new("TextLabel",towerBanner)
tBannerSub.Size=UDim2.new(1,-20,0,14); tBannerSub.Position=UDim2.new(0,14,0,28)
tBannerSub.BackgroundTransparency=1; tBannerSub.TextColor3=Color3.fromRGB(190,155,255)
tBannerSub.TextXAlignment=Enum.TextXAlignment.Left; tBannerSub.Font=FONT_MEDIUM; tBannerSub.TextSize=11
tBannerSub.Text="เลือกหอคอยที่ต้องการแล้วกดเริ่มลงได้ทันที"

local dropCard=Instance.new("Frame",pages["Tower"])
dropCard.Size=UDim2.new(1,0,0,52); dropCard.BackgroundColor3=DARK.item; dropCard.BorderSizePixel=0
Instance.new("UICorner",dropCard).CornerRadius=UDim.new(0,8)

local dTitle=Instance.new("TextLabel",dropCard)
dTitle.Size=UDim2.new(1,-170,0,18); dTitle.Position=UDim2.new(0,14,0,7)
dTitle.BackgroundTransparency=1; dTitle.Text="Select Towers"
dTitle.TextColor3=DARK.text; dTitle.TextXAlignment=Enum.TextXAlignment.Left; dTitle.Font=FONT_BOLD; dTitle.TextSize=14

local dSub=Instance.new("TextLabel",dropCard)
dSub.Size=UDim2.new(1,-170,0,14); dSub.Position=UDim2.new(0,14,0,28)
dSub.BackgroundTransparency=1; dSub.Text="เลือกหอคอยที่ต้องการลง (เลือกได้หลายหอคอย)"
dSub.TextColor3=DARK.subtext; dSub.TextXAlignment=Enum.TextXAlignment.Left; dSub.Font=FONT_MEDIUM; dSub.TextSize=11

dropBtn=Instance.new("TextButton",dropCard)
dropBtn.Size=UDim2.new(0,145,0,28); dropBtn.Position=UDim2.new(1,-155,0.5,-14)
dropBtn.BackgroundColor3=Color3.fromRGB(32,24,48); dropBtn.BorderSizePixel=0
dropBtn.Text="Select Towers  ▾"; dropBtn.TextColor3=Color3.fromRGB(240,230,255)
dropBtn.Font=FONT_BOLD; dropBtn.TextSize=12
Instance.new("UICorner",dropBtn).CornerRadius=UDim.new(0,6)
local dropBtnStroke=Instance.new("UIStroke",dropBtn)
dropBtnStroke.Color=DARK.purple; dropBtnStroke.Thickness=1.2

local ITEM_H = 30
local PADDING = 2
local totalListHeight = #ALL_TOWERS * (ITEM_H + PADDING) + 10

dropMenu=Instance.new("ScrollingFrame",main)
dropMenu.Size=UDim2.new(0,210,0,math.min(180, totalListHeight))
dropMenu.BackgroundColor3=DARK.dropdown
dropMenu.BorderSizePixel=0; dropMenu.ScrollBarThickness=4
dropMenu.ScrollBarImageColor3=DARK.purple; dropMenu.Visible=false; dropMenu.ZIndex=100
dropMenu.CanvasSize=UDim2.new(0, 0, 0, totalListHeight)
dropMenu.AutomaticCanvasSize=Enum.AutomaticSize.None
Instance.new("UICorner",dropMenu).CornerRadius=UDim.new(0,8)
local dmStroke=Instance.new("UIStroke",dropMenu); dmStroke.Color=DARK.border; dmStroke.Thickness=1.5
local dList=Instance.new("UIListLayout",dropMenu); dList.Padding=UDim.new(0,PADDING)
local dPad=Instance.new("UIPadding",dropMenu)
dPad.PaddingTop=UDim.new(0,5); dPad.PaddingBottom=UDim.new(0,5)
dPad.PaddingLeft=UDim.new(0,5); dPad.PaddingRight=UDim.new(0,5)

updateDropBtnText = function()
    local count=0
    for _,sel in pairs(SelectedTowers) do if sel then count=count+1 end end
    if count==0 then
        dropBtn.Text="Select Towers  ▾"
        dropBtn.TextColor3=Color3.fromRGB(240,230,255)
    else
        dropBtn.Text=string.format("Selected (%d)  ▾", count)
        dropBtn.TextColor3=DARK.hAccent
    end
end

local function toggleDropdown()
    if dropMenu.Visible then
        dropMenu.Visible=false
    else
        local absPos=dropBtn.AbsolutePosition
        local mainPos=main.AbsolutePosition
        dropMenu.Position=UDim2.new(0, absPos.X-mainPos.X-60, 0, absPos.Y-mainPos.Y+32)
        dropMenu.Visible=true
    end
end

dropBtn.MouseButton1Click:Connect(toggleDropdown)

refreshTowerOpts = {}
for _, tower in ipairs(ALL_TOWERS) do
    local opt=Instance.new("TextButton",dropMenu)
    opt.Size=UDim2.new(1,0,0,ITEM_H); opt.BackgroundColor3=DARK.item; opt.BackgroundTransparency=1
    opt.BorderSizePixel=0; opt.Text=""; opt.ZIndex=101
    Instance.new("UICorner",opt).CornerRadius=UDim.new(0,6)

    local chk=Instance.new("TextLabel",opt)
    chk.Size=UDim2.new(0,18,1,0); chk.Position=UDim2.new(0,6,0,0)
    chk.BackgroundTransparency=1; chk.Text="○"; chk.TextColor3=DARK.subtext
    chk.Font=FONT; chk.TextSize=12; chk.ZIndex=102

    local oName=Instance.new("TextLabel",opt)
    oName.Size=UDim2.new(1,-28,1,0); oName.Position=UDim2.new(0,26,0,0)
    oName.BackgroundTransparency=1; oName.Text=tower.name; oName.TextColor3=DARK.text
    oName.TextXAlignment=Enum.TextXAlignment.Left; oName.Font=FONT; oName.TextSize=11; oName.ZIndex=102

    local function refreshOpt()
        local isSel=SelectedTowers[tower.name]==true
        chk.Text=isSel and "✓" or "○"
        chk.TextColor3=isSel and DARK.hAccent or DARK.subtext
        oName.TextColor3=isSel and Color3.new(1,1,1) or DARK.text
        opt.BackgroundTransparency=isSel and 0 or 1
        opt.BackgroundColor3=isSel and DARK.itemSel or DARK.item
    end

    opt.MouseButton1Click:Connect(function()
        if isTowerBusy then return end
        SelectedTowers[tower.name]=not SelectedTowers[tower.name]
        refreshOpt()
        updateDropBtnText()
    end)
    table.insert(refreshTowerOpts, refreshOpt)
    refreshOpt()
end

makeCfgToggle(pages["Tower"],"LoopTower","Loop Towers","วนลงหอคอยที่เลือกซ้ำเรื่อยๆ แบบอัตโนมัติ",
    function(v)
        updateRunBtnText()
    end)

makeCfgToggle(pages["Tower"],"EquipTeamBefore","Equip Best Team First","สวมใส่ทีมที่ดีที่สุดก่อนเข้าหอคอยทุกรอบ")

towerRunBtn=Instance.new("TextButton",pages["Tower"])
towerRunBtn.Size=UDim2.new(1,0,0,52); towerRunBtn.BackgroundColor3=DARK.purple; towerRunBtn.BorderSizePixel=0
towerRunBtn.TextColor3=Color3.new(1,1,1); towerRunBtn.Font=FONT_BOLD; towerRunBtn.TextSize=13
towerRunBtn.Text="▶ Start Selected Towers (1 Run Each)"
Instance.new("UICorner",towerRunBtn).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",towerRunBtn).Color=Color3.fromRGB(180,140,255)
towerRunBtn.MouseButton1Click:Connect(function()
    dropMenu.Visible=false
    if isTowerBusy then
        stopTowerQueue()
    else
        startTowerQueue()
    end
end)
end
pcall(setupTowerTab)

-- ── Teleport tab ─────────────────────────────────────────────────────────────
local function setupTeleportTab()
    local tpBanner = Instance.new("Frame", pages["Teleport"])
    tpBanner.Size = UDim2.new(1, 0, 0, 50)
    tpBanner.BackgroundColor3 = Color3.fromRGB(24, 34, 32)
    tpBanner.BorderSizePixel = 0
    Instance.new("UICorner", tpBanner).CornerRadius = UDim.new(0, 8)
    local tpStroke = Instance.new("UIStroke", tpBanner)
    tpStroke.Color = Color3.fromRGB(40, 110, 85)

    local tpTitle = Instance.new("TextLabel", tpBanner)
    tpTitle.Size = UDim2.new(1, -20, 0, 18); tpTitle.Position = UDim2.new(0, 14, 0, 7)
    tpTitle.BackgroundTransparency = 1; tpTitle.TextColor3 = Color3.new(1, 1, 1)
    tpTitle.TextXAlignment = Enum.TextXAlignment.Left; tpTitle.Font = FONT_BOLD; tpTitle.TextSize = 14
    tpTitle.Text = "🗺️ Remote Auto Teleport (วาร์ปจุดสำคัญ)"

    local tpSub = Instance.new("TextLabel", tpBanner)
    tpSub.Size = UDim2.new(1, -20, 0, 14); tpSub.Position = UDim2.new(0, 14, 0, 27)
    tpSub.BackgroundTransparency = 1; tpSub.TextColor3 = Color3.fromRGB(130, 205, 175)
    tpSub.TextXAlignment = Enum.TextXAlignment.Left; tpSub.Font = FONT_MEDIUM; tpSub.TextSize = 11
    tpSub.Text = "วาร์ปไปยังตำแหน่งสำคัญต่างๆ ในแมพได้ทันทีแบบไร้ดีเลย์"

    -- Dropdown Selector
    local tpOptions = {}
    local currentLocIdx = 1
    for i, loc in ipairs(UtilityFeatures.TeleportLocations) do
        table.insert(tpOptions, {
            text = loc.name,
            sub = loc.sub,
            value = loc.id
        })
        if loc.id == CFG.SelectedTeleport then
            currentLocIdx = i
        end
    end

    local _, setTpSel = makeSelector(pages["Teleport"], "Select Destination", "เลือกจุดหมายที่ต้องการวาร์ปไป", tpOptions, currentLocIdx, function(val, idx)
        CFG.SelectedTeleport = val
        currentLocIdx = idx
    end)

    makeButton(pages["Teleport"], "Teleport Now", "วาร์ปไปยังจุดหมายที่เลือกไว้ด้านบนทันที", "Teleport", function()
        local loc = UtilityFeatures.TeleportLocations[currentLocIdx]
        if loc then
            UtilityFeatures.teleportTo(loc)
        end
    end)

    -- Quick Teleport Buttons Grid
    local quickCard = Instance.new("Frame", pages["Teleport"])
    quickCard.Size = UDim2.new(1, 0, 0, 138)
    quickCard.BackgroundColor3 = DARK.item
    quickCard.BorderSizePixel = 0
    Instance.new("UICorner", quickCard).CornerRadius = UDim.new(0, 8)
    local qStroke = Instance.new("UIStroke", quickCard)
    qStroke.Color = DARK.border

    local qTitle = Instance.new("TextLabel", quickCard)
    qTitle.Size = UDim2.new(1, -20, 0, 16); qTitle.Position = UDim2.new(0, 14, 0, 8)
    qTitle.BackgroundTransparency = 1; qTitle.TextColor3 = DARK.accent
    qTitle.TextXAlignment = Enum.TextXAlignment.Left; qTitle.Font = FONT_BOLD; qTitle.TextSize = 14
    qTitle.Text = "⚡ Quick Teleport Buttons (กดปุ่มวาร์ปทันที)"

    local quickGrid = Instance.new("Frame", quickCard)
    quickGrid.Size = UDim2.new(1, -24, 0, 100); quickGrid.Position = UDim2.new(0, 12, 0, 28)
    quickGrid.BackgroundTransparency = 1
    local uig = Instance.new("UIGridLayout", quickGrid)
    uig.CellSize = UDim2.new(0.235, 0, 0, 44)
    uig.CellPadding = UDim2.new(0.02, 0, 0, 8)

    local quickList = {
        { id = "MyPlot",   label = "🏠 My Base" },
        { id = "Tower",    label = "🏰 Tower" },
        { id = "DiceShop", label = "🎲 Dice Shop" },
        { id = "Shop",     label = "🛒 Shop" },
        { id = "Fuse",     label = "⚔️ Aura Fuse" },
        { id = "Grades",   label = "✨ Grade Reroll" },
        { id = "Traits",   label = "🧬 Trait Reroll" },
        { id = "Selling",  label = "💰 Sell Zone" },
    }

    for _, q in ipairs(quickList) do
        local qb = Instance.new("TextButton", quickGrid)
        qb.BackgroundColor3 = Color3.fromRGB(32, 28, 44)
        qb.BorderSizePixel = 0
        qb.Font = FONT; qb.TextSize = 10; qb.TextColor3 = Color3.fromRGB(235, 225, 255)
        qb.Text = q.label
        Instance.new("UICorner", qb).CornerRadius = UDim.new(0, 6)
        local btnStroke = Instance.new("UIStroke", qb)
        btnStroke.Color = Color3.fromRGB(60, 50, 80); btnStroke.Thickness = 1

        qb.MouseButton1Click:Connect(function()
            for _, loc in ipairs(UtilityFeatures.TeleportLocations) do
                if loc.id == q.id then
                    TweenService:Create(qb, TweenInfo.new(0.08), { BackgroundColor3 = DARK.accent, TextColor3 = Color3.new(0,0,0) }):Play()
                    task.wait(0.1)
                    TweenService:Create(qb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(32, 28, 44), TextColor3 = Color3.fromRGB(235, 225, 255) }):Play()
                    UtilityFeatures.teleportTo(loc)
                    break
                end
            end
        end)
    end
end
pcall(setupTeleportTab)

-- ── Quest & Rebirth tab ─────────────────────────────────────────────────────────
local function setupQuestRebirthTab()
    -- ── Section 1: Rebirth System ──────────────────────────────────────────────
    makeCfgToggle(pages["Quest & Rebirth"], "AutoRebirth", "Auto Rebirth", "รีเบิร์ธอัตโนมัติทันทีเมื่อเงินถึงเกณฑ์ (ปลดล็อกช่อง Plot เพิ่มตาม Tier)")

    makeButton(pages["Quest & Rebirth"], "Rebirth Now", "ส่งคำขอ Rebirth ไปยังเซิร์ฟเวอร์ทันที 1 ครั้ง", "Rebirth", function()
        local curLvl = getRebirthLevel()
        local nextCost = REBIRTH_COSTS[curLvl + 1]
        if not nextCost then
            showNotif("คุณอยู่ในระดับ Rebirth สูงสุดแล้ว!")
            return
        end
        if getMoney() < nextCost then
            showNotif(string.format("เงินไม่พอสำหรับ Rebirth (ต้องการ $%s)", formatNumber(nextCost)))
            return
        end
        local ok = pcall(function() RebirthSignal:FireServer() end)
        if ok then
            showNotif(string.format("ส่งคำขอ Rebirth แล้ว (Tier %d -> %d) ✓", curLvl, curLvl + 1))
        end
    end)



    -- ── Section 2: Quests Automation ───────────────────────────────────────────
    makeCfgToggle(pages["Quest & Rebirth"], "AutoQuest", "Auto Claim Quests", "ตรวจเช็คและกดรับของรางวัลเควสทั้งหมดอัตโนมัติ (Daily & Weekly)")
    makeButton(pages["Quest & Rebirth"], "Claim Quests Now", "กดรับของรางวัลเควสทั้งหมดที่ทำสำเร็จทันที 1 ครั้ง", "Claim Quests", function()
        task.spawn(function()
            showNotif("กำลังส่งคำขอรับของรางวัลเควสทั้งหมด...")
            claimAllQuests()
            showNotif("รับของรางวัลเควสเรียบร้อย ✓")
        end)
    end)

    -- ── Section 3: Free Rewards ────────────────────────────────────────────────
    makeCfgToggle(pages["Quest & Rebirth"], "AutoClaimRewards", "Auto Claim Free Rewards", "รับของรางวัลฟรีทั้งหมดอัตโนมัติ (Daily Login, Group Chest, และ Offline Cash)")
    makeButton(pages["Quest & Rebirth"], "Claim Free Rewards Now", "กดรับ Daily Login, Group Chest, และ Offline Cash ทันที 1 ครั้ง", "Claim All", function()
        claimAllFreeRewards(true)
    end)
end
pcall(setupQuestRebirthTab)

-- Close dropdowns when clicking outside
main.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        local mPos=UIS:GetMouseLocation()
        if dropMenu and dropMenu.Visible and dropBtn then
            local dPos=dropMenu.AbsolutePosition; local dSize=dropMenu.AbsoluteSize
            local bPos=dropBtn.AbsolutePosition; local bSize=dropBtn.AbsoluteSize
            if not ((mPos.X>=dPos.X and mPos.X<=dPos.X+dSize.X and mPos.Y>=dPos.Y and mPos.Y<=dPos.Y+dSize.Y) or
                    (mPos.X>=bPos.X and mPos.X<=bPos.X+bSize.X and mPos.Y>=bPos.Y and mPos.Y<=bPos.Y+bSize.Y)) then
                dropMenu.Visible=false
            end
        end
        if skillDropMenu and skillDropMenu.Visible and skillDropBtn then
            local dPos=skillDropMenu.AbsolutePosition; local dSize=skillDropMenu.AbsoluteSize
            local bPos=skillDropBtn.AbsolutePosition; local bSize=skillDropBtn.AbsoluteSize
            if not ((mPos.X>=dPos.X and mPos.X<=dPos.X+dSize.X and mPos.Y>=dPos.Y and mPos.Y<=dPos.Y+dSize.Y) or
                    (mPos.X>=bPos.X and mPos.X<=bPos.X+bSize.X and mPos.Y>=bPos.Y and mPos.Y<=bPos.Y+bSize.Y)) then
                skillDropMenu.Visible=false
            end
        end
        if cfgDropMenu and cfgDropMenu.Visible and cfgDropBtn then
            local dPos=cfgDropMenu.AbsolutePosition; local dSize=cfgDropMenu.AbsoluteSize
            local bPos=cfgDropBtn.AbsolutePosition; local bSize=cfgDropBtn.AbsoluteSize
            if not ((mPos.X>=dPos.X and mPos.X<=dPos.X+dSize.X and mPos.Y>=dPos.Y and mPos.Y<=dPos.Y+dSize.Y) or
                    (mPos.X>=bPos.X and mPos.X<=bPos.X+bSize.X and mPos.Y>=bPos.Y and mPos.Y<=bPos.Y+bSize.Y)) then
                cfgDropMenu.Visible=false
            end
        end
        if luckDropMenu and luckDropMenu.Visible and luckDropBtn then
            local dPos=luckDropMenu.AbsolutePosition; local dSize=luckDropMenu.AbsoluteSize
            local bPos=luckDropBtn.AbsolutePosition; local bSize=luckDropBtn.AbsoluteSize
            if not ((mPos.X>=dPos.X and mPos.X<=dPos.X+dSize.X and mPos.Y>=dPos.Y and mPos.Y<=dPos.Y+dSize.Y) or
                    (mPos.X>=bPos.X and mPos.X<=bPos.X+bSize.X and mPos.Y>=bPos.Y and mPos.Y<=bPos.Y+bSize.Y)) then
                luckDropMenu.Visible=false
            end
        end
    end
end)

-- ── Utility tab ───────────────────────────────────────────────────────────────
local function setupUtilityTab()
    -- ── Section 1: Performance & Low Detail Mode ──────────────────────────────
    local perfBanner = Instance.new("Frame", pages["Utility"])
    perfBanner.Size = UDim2.new(1, 0, 0, 50)
    perfBanner.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
    perfBanner.BorderSizePixel = 0
    Instance.new("UICorner", perfBanner).CornerRadius = UDim.new(0, 8)
    local pStroke = Instance.new("UIStroke", perfBanner)
    pStroke.Color = Color3.fromRGB(48, 80, 140)

    local pTitle = Instance.new("TextLabel", perfBanner)
    pTitle.Size = UDim2.new(1, -20, 0, 18); pTitle.Position = UDim2.new(0, 14, 0, 7)
    pTitle.BackgroundTransparency = 1; pTitle.TextColor3 = Color3.new(1, 1, 1)
    pTitle.TextXAlignment = Enum.TextXAlignment.Left; pTitle.Font = FONT_BOLD; pTitle.TextSize = 14
    pTitle.Text = "🚀 Low Detail Mode & Performance (Multi-Instance)"

    local pSub = Instance.new("TextLabel", perfBanner)
    pSub.Size = UDim2.new(1, -20, 0, 14); pSub.Position = UDim2.new(0, 14, 0, 27)
    pSub.BackgroundTransparency = 1; pSub.TextColor3 = Color3.fromRGB(140, 175, 230)
    pSub.TextXAlignment = Enum.TextXAlignment.Left; pSub.Font = FONT_MEDIUM; pSub.TextSize = 11
    pSub.Text = "ลดภาระ CPU/RAM และลื่นไหลที่สุดเมื่อเปิดหลายจอ (MuMu / LDPlayer)"

    -- 1. Low Detail Mode (All-in-One)
    makeCfgToggle(pages["Utility"], "LowDetailMode", "Low Detail Mode (All-in-One)", "เปิดทีเดียว: ปิดสภาพอากาศ + ซ่อนตัวคนอื่น + ปิด Particle + Boost FPS", function(v)
        UtilityFeatures.toggleLowDetailMode(v)
    end)

    -- 2. AFK Super Saver (1+2+3) directly after Low Detail Mode
    makeCfgToggle(pages["Utility"], "SuperRAMSaver", "AFK Super Saver (1+2+3)", "กดทีเดียว: ปิด 3D จอขาว + ล้างขยะ RAM ทุก 60s + ปิดเสียง", function(v)
        toggleSuperRAMSaver(v)
    end)

    -- 3. Anti-AFK
    makeCfgToggle(pages["Utility"], "AntiAFK", "Anti-AFK", "ป้องกันการถูกเตะจากการอยู่เฉยเกิน 20 นาที (รองรับ Mobile & Emulator)")
makeCfgToggle(pages["Utility"], "AutoReconnect", "Auto Reconnect (Anti-Disconnect)", "เชื่อมต่อเข้าเกมใหม่อัตโนมัติเมื่อหลุด Connection Lost สำหรับจอ Emulator")

    -- Note: Redundant individual toggles are kept in backend logic (UtilityFeatures, toggleBoostFPS, toggle3DRendering, etc.)
    -- but omitted from UI as requested in favor of the all-in-one modes.
end
pcall(setupUtilityTab)

-- ── Misc tab (Config Manager) ────────────────────────────────────────────────
local function setupMiscTab()
    local CONFIG_FOLDER = "540Cheats_Configs"
    local AUTOLOAD_FILE = CONFIG_FOLDER .. "/autoload.txt"
    local INDEX_FILE    = CONFIG_FOLDER .. "/_index.json"

    local function fileWrite(path, content)
        if writefile then return pcall(writefile, path, content) end
        return false
    end

    local function fileRead(path)
        if readfile then
            local ok, res = pcall(readfile, path)
            if ok then return res end
        end
        return nil
    end

    local function fileExists(path)
        if isfile then
            local ok, res = pcall(isfile, path)
            return ok and res == true
        end
        return false
    end

    local function fileDelete(path)
        if delfile then return pcall(delfile, path) end
        return false
    end

    local function folderExists(path)
        if isfolder then
            local ok, res = pcall(isfolder, path)
            return ok and res == true
        end
        return false
    end

    local function folderMake(path)
        if makefolder then return pcall(makefolder, path) end
        return false
    end

    local function getFileList(folder)
        if listfiles then
            local ok, res = pcall(listfiles, folder)
            if ok and type(res) == "table" then return res end
        end
        return {}
    end

    local function readIndex()
        local content = fileRead(INDEX_FILE)
        if content then
            local ok, parsed = pcall(function() return HttpService:JSONDecode(content) end)
            if ok and type(parsed) == "table" then return parsed end
        end
        return {}
    end

    local function saveIndex(idxList)
        local ok, encoded = pcall(function() return HttpService:JSONEncode(idxList) end)
        if ok then fileWrite(INDEX_FILE, encoded) end
    end

    local function getAllConfigs()
        if not folderExists(CONFIG_FOLDER) then folderMake(CONFIG_FOLDER) end
        local set = {}
        for _, f in ipairs(getFileList(CONFIG_FOLDER)) do
            local clean = f:gsub("\\", "/")
            local name = clean:match(".*/(.*)%.json$") or clean:match("^(.*)%.json$")
            if name and not name:match("^_") and name ~= "autoload" then
                set[name] = true
            end
        end
        for _, name in ipairs(readIndex()) do
            if fileExists(CONFIG_FOLDER .. "/" .. name .. ".json") then
                set[name] = true
            end
        end
        local result = {}
        for name in pairs(set) do table.insert(result, name) end
        table.sort(result)
        return result
    end

    local function addConfigToIndex(cfgName)
        local idx = readIndex()
        for _, n in ipairs(idx) do
            if n == cfgName then return end
        end
        table.insert(idx, cfgName)
        saveIndex(idx)
    end

    local function removeConfigFromIndex(cfgName)
        local newIdx = {}
        for _, n in ipairs(readIndex()) do
            if n ~= cfgName then table.insert(newIdx, n) end
        end
        saveIndex(newIdx)
    end

    local function getAutoloadConfig()
        if fileExists(AUTOLOAD_FILE) then
            local content = fileRead(AUTOLOAD_FILE)
            if content then
                local clean = content:gsub("%s+", "")
                if clean ~= "" then return clean end
            end
        end
        return nil
    end

    local function setAutoloadConfig(name)
        if not name or name == "" then return false end
        if not folderExists(CONFIG_FOLDER) then folderMake(CONFIG_FOLDER) end
        return fileWrite(AUTOLOAD_FILE, name)
    end

    local function clearAutoloadConfig()
        if fileExists(AUTOLOAD_FILE) then fileDelete(AUTOLOAD_FILE) end
    end

    local function syncAllUI()
        for k, info in pairs(registeredToggles) do
            if CFG[k] ~= nil then
                pcall(info.set, CFG[k])
                if info.cb then pcall(info.cb, CFG[k]) end
            end
        end
        if plotLvlBox and CFG.PlotTargetLvl then plotLvlBox.Text = tostring(CFG.PlotTargetLvl) end
        if setPlotMode and CFG.PlotUpgradeMode then setPlotMode(CFG.PlotUpgradeMode) end
        if setRollDelay and CFG.RollDelay then setRollDelay(CFG.RollDelay) end
        if setEquipMode and CFG.AutoEquipMode then setEquipMode(CFG.AutoEquipMode) end
        for _, ref in ipairs(refreshSkillOpts) do pcall(ref) end
        if updateSkillDropBtnText then pcall(updateSkillDropBtnText) end
        for _, ref in ipairs(refreshTowerOpts) do pcall(ref) end
        if updateDropBtnText then pcall(updateDropBtnText) end
        if updateRunBtnText then pcall(updateRunBtnText) end
        for _, ref in ipairs(refreshLuckOpts or {}) do pcall(ref) end
        if updateLuckDropBtnText then pcall(updateLuckDropBtnText) end
    end

    local function saveConfig(name)
        if not name or name:gsub("%s+", "") == "" then
            showNotif("กรุณาใส่ชื่อ Config ก่อนบันทึก")
            return false
        end
        name = name:gsub("[^%w_%-]", "")
        if name == "" then
            showNotif("ชื่อ Config มีตัวอักษรที่ไม่อนุญาต")
            return false
        end
        if not folderExists(CONFIG_FOLDER) then folderMake(CONFIG_FOLDER) end
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode({
                CFG = CFG,
                SelectedSkills = SelectedSkills,
                SelectedTowers = SelectedTowers,
                SelectedLuckCategories = SelectedLuckCategories,
                Version = "v24",
            })
        end)
        if not ok then
            showNotif("เกิดข้อผิดพลาดในการแปลง JSON")
            return false
        end
        local wrote = fileWrite(CONFIG_FOLDER .. "/" .. name .. ".json", encoded)
        if wrote then
            addConfigToIndex(name)
            showNotif("บันทึก Config: " .. name .. " เรียบร้อย ✓")
            return true
        else
            showNotif("ไม่สามารถเขียนไฟล์ได้ (Executor ไม่อนุญาต)")
            return false
        end
    end

    local function loadConfig(name)
        if not name or name == "" then
            showNotif("กรุณาเลือก Config ที่จะโหลด")
            return false
        end
        local filePath = CONFIG_FOLDER .. "/" .. name .. ".json"
        if not fileExists(filePath) then
            showNotif("ไม่พบไฟล์ Config: " .. name)
            return false
        end
        local content = fileRead(filePath)
        if not content or content == "" then
            showNotif("ไฟล์ Config ว่างเปล่า")
            return false
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok or type(data) ~= "table" then
            showNotif("อ่านข้อมูล Config ไม่สำเร็จ")
            return false
        end
        if data.CFG and type(data.CFG) == "table" then
            for k, v in pairs(data.CFG) do
                if CFG[k] ~= nil then CFG[k] = v end
            end
        end
        if data.SelectedSkills and type(data.SelectedSkills) == "table" then
            for k, _ in pairs(SelectedSkills) do SelectedSkills[k] = false end
            for k, v in pairs(data.SelectedSkills) do SelectedSkills[k] = v end
        end
        if data.SelectedTowers and type(data.SelectedTowers) == "table" then
            for k, _ in pairs(SelectedTowers) do SelectedTowers[k] = false end
            for k, v in pairs(data.SelectedTowers) do SelectedTowers[k] = v end
        end
        if data.SelectedLuckCategories and type(data.SelectedLuckCategories) == "table" then
            for k, _ in pairs(SelectedLuckCategories) do SelectedLuckCategories[k] = false end
            for k, v in pairs(data.SelectedLuckCategories) do SelectedLuckCategories[k] = v end
        end
        syncAllUI()
        showNotif("โหลด Config: " .. name .. " สำเร็จ ✓")
        return true
    end

    local function deleteConfig(name)
        if not name or name == "" then
            showNotif("กรุณาเลือก Config ที่จะลบ")
            return false
        end
        local filePath = CONFIG_FOLDER .. "/" .. name .. ".json"
        if fileExists(filePath) then fileDelete(filePath) end
        removeConfigFromIndex(name)
        if getAutoloadConfig() == name then clearAutoloadConfig() end
        showNotif("ลบ Config: " .. name .. " เรียบร้อย")
        return true
    end

    -- ── Misc UI Elements ──────────────────────────────────────────────────────────
    local function addCard(h)
        local f = Instance.new("Frame", pages["Misc"])
        f.Size = UDim2.new(1,0,0,h); f.BackgroundColor3 = DARK.item; f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
        return f
    end

    local function addCardText(card, title, sub)
        local t = Instance.new("TextLabel", card)
        t.Size = UDim2.new(1,-170,0,18); t.Position = UDim2.new(0,14,0,8)
        t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = DARK.text
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Font = FONT_BOLD; t.TextSize = 13
        if sub then
            local s = Instance.new("TextLabel", card)
            s.Size = UDim2.new(1,-170,0,14); s.Position = UDim2.new(0,14,0,28)
            s.BackgroundTransparency = 1; s.Text = sub; s.TextColor3 = DARK.subtext
            s.TextXAlignment = Enum.TextXAlignment.Left; s.Font = FONT_MEDIUM; s.TextSize = 11
            return s
        end
    end

    local mh = addCard(52)
    local mhT = Instance.new("TextLabel", mh)
    mhT.Size = UDim2.new(1,-20,0,18); mhT.Position = UDim2.new(0,14,0,8); mhT.BackgroundTransparency = 1; mhT.Text = "Config System (Profile Manager)"; mhT.TextColor3 = DARK.text; mhT.TextXAlignment = Enum.TextXAlignment.Left; mhT.Font = FONT_BOLD; mhT.TextSize = 14
    local mhS = Instance.new("TextLabel", mh)
    mhS.Size = UDim2.new(1,-20,0,14); mhS.Position = UDim2.new(0,14,0,28); mhS.BackgroundTransparency = 1; mhS.Text = "บันทึก โหลด ลบ และตั้งค่า Autoload การตั้งค่าทั้งหมด"; mhS.TextColor3 = DARK.subtext; mhS.TextXAlignment = Enum.TextXAlignment.Left; mhS.Font = FONT_MEDIUM; mhS.TextSize = 11

    local nc = addCard(52)
    addCardText(nc, "Config Name", "พิมพ์ชื่อโปรไฟล์ที่ต้องการบันทึก")
    local cfgNameBox = Instance.new("TextBox", nc)
    cfgNameBox.Size = UDim2.new(0,145,0,28); cfgNameBox.Position = UDim2.new(1,-155,0.5,-14)
    cfgNameBox.BackgroundColor3 = Color3.fromRGB(32,24,48); cfgNameBox.BorderSizePixel = 0
    cfgNameBox.Text = "default"; cfgNameBox.TextColor3 = Color3.fromRGB(240,230,255)
    cfgNameBox.Font = FONT_BOLD; cfgNameBox.TextSize = 13; cfgNameBox.ClearTextOnFocus = false
    Instance.new("UICorner", cfgNameBox).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", cfgNameBox).Color = DARK.purple

    local dc = addCard(52)
    addCardText(dc, "Select Profile", "เลือกไฟล์คอนฟิกจากรายการที่มี")
    cfgDropBtn = Instance.new("TextButton", dc)
    cfgDropBtn.Size = UDim2.new(0,145,0,28); cfgDropBtn.Position = UDim2.new(1,-155,0.5,-14)
    cfgDropBtn.BackgroundColor3 = Color3.fromRGB(32,24,48); cfgDropBtn.BorderSizePixel = 0
    cfgDropBtn.Text = "Select Config  ▾"; cfgDropBtn.TextColor3 = Color3.fromRGB(240,230,255)
    cfgDropBtn.Font = FONT_BOLD; cfgDropBtn.TextSize = 13
    Instance.new("UICorner", cfgDropBtn).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", cfgDropBtn).Color = DARK.purple

    local selectedConfig = "default"

    cfgDropMenu = Instance.new("ScrollingFrame", main)
    cfgDropMenu.Size = UDim2.new(0,180,0,140); cfgDropMenu.BackgroundColor3 = DARK.dropdown
    cfgDropMenu.BorderSizePixel = 0; cfgDropMenu.ScrollBarThickness = 4
    cfgDropMenu.ScrollBarImageColor3 = DARK.purple; cfgDropMenu.Visible = false; cfgDropMenu.ZIndex = 110
    Instance.new("UICorner", cfgDropMenu).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", cfgDropMenu).Color = DARK.border
    Instance.new("UIListLayout", cfgDropMenu).Padding = UDim.new(0,2)
    local cdmPad = Instance.new("UIPadding", cfgDropMenu)
    cdmPad.PaddingTop = UDim.new(0,4); cdmPad.PaddingBottom = UDim.new(0,4)
    cdmPad.PaddingLeft = UDim.new(0,4); cdmPad.PaddingRight = UDim.new(0,4)

    local function populateConfigDropdown()
        for _, ch in ipairs(cfgDropMenu:GetChildren()) do
            if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
        end
        local configs = getAllConfigs()
        if #configs == 0 then
            local emptyLbl = Instance.new("TextLabel", cfgDropMenu)
            emptyLbl.Size = UDim2.new(1,0,0,28); emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = "No configs found"; emptyLbl.TextColor3 = DARK.subtext
            emptyLbl.Font = FONT; emptyLbl.TextSize = 10; emptyLbl.ZIndex = 111
            cfgDropMenu.CanvasSize = UDim2.new(0,0,0,32)
            return
        end
        cfgDropMenu.CanvasSize = UDim2.new(0,0,0,#configs * 30 + 8)
        for _, cName in ipairs(configs) do
            local b = Instance.new("TextButton", cfgDropMenu)
            b.Size = UDim2.new(1,0,0,28); b.BackgroundColor3 = (selectedConfig == cName) and DARK.itemSel or DARK.item
            b.BackgroundTransparency = (selectedConfig == cName) and 0 or 1
            b.BorderSizePixel = 0; b.Text = "  " .. cName
            b.TextColor3 = (selectedConfig == cName) and DARK.hAccent or DARK.text
            b.TextXAlignment = Enum.TextXAlignment.Left; b.Font = FONT; b.TextSize = 11; b.ZIndex = 111
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
            b.MouseButton1Click:Connect(function()
                selectedConfig = cName
                cfgDropBtn.Text = cName .. "  ▾"
                cfgDropBtn.TextColor3 = DARK.hAccent
                cfgNameBox.Text = cName
                cfgDropMenu.Visible = false
            end)
        end
    end

    cfgDropBtn.MouseButton1Click:Connect(function()
        if cfgDropMenu.Visible then
            cfgDropMenu.Visible = false
        else
            if dropMenu then dropMenu.Visible = false end
            if skillDropMenu then skillDropMenu.Visible = false end
            populateConfigDropdown()
            local absPos = cfgDropBtn.AbsolutePosition
            local mainPos = main.AbsolutePosition
            cfgDropMenu.Position = UDim2.new(0, absPos.X - mainPos.X - 35, 0, absPos.Y - mainPos.Y + 32)
            cfgDropMenu.Visible = true
        end
    end)

    local btnRow = Instance.new("Frame", pages["Misc"])
    btnRow.Size = UDim2.new(1,0,0,36); btnRow.BackgroundTransparency = 1
    local brL = Instance.new("UIListLayout", btnRow)
    brL.FillDirection = Enum.FillDirection.Horizontal; brL.Padding = UDim.new(0,8)

    local btnBg = Color3.fromRGB(32,24,48)
    local btnFont = FONT_BOLD
    local btnSize = 13

    local saveBtn = Instance.new("TextButton", btnRow)
    saveBtn.Size = UDim2.new(0.32, -4, 1, 0); saveBtn.BackgroundColor3 = btnBg; saveBtn.BorderSizePixel = 0
    saveBtn.Text = "💾 Save Config"; saveBtn.TextColor3 = Color3.fromRGB(220,220,235); saveBtn.Font = btnFont; saveBtn.TextSize = btnSize
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", saveBtn).Color = DARK.border

    local loadBtn = Instance.new("TextButton", btnRow)
    loadBtn.Size = UDim2.new(0.32, -4, 1, 0); loadBtn.BackgroundColor3 = btnBg; loadBtn.BorderSizePixel = 0
    loadBtn.Text = "📂 Load Config"; loadBtn.TextColor3 = Color3.fromRGB(220,220,235); loadBtn.Font = btnFont; loadBtn.TextSize = btnSize
    Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", loadBtn).Color = DARK.border

    local delBtn = Instance.new("TextButton", btnRow)
    delBtn.Size = UDim2.new(0.36, -8, 1, 0); delBtn.BackgroundColor3 = btnBg; delBtn.BorderSizePixel = 0
    delBtn.Text = "🗑️ Delete Config"; delBtn.TextColor3 = Color3.fromRGB(220,220,235); delBtn.Font = btnFont; delBtn.TextSize = btnSize
    Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", delBtn).Color = DARK.border

    local ac = addCard(56)
    local acS = addCardText(ac, "⚡ Autoload on Startup", "Active: None")

    local function refreshAutoloadStatus()
        local cur = getAutoloadConfig()
        if cur and cur ~= "" then
            acS.Text = "Active: " .. cur
            acS.TextColor3 = DARK.hAccent
        else
            acS.Text = "Active: None (ปิดอยู่)"
            acS.TextColor3 = DARK.subtext
        end
    end
    refreshAutoloadStatus()

    local setAutoBtn = Instance.new("TextButton", ac)
    setAutoBtn.Size = UDim2.new(0,80,0,28); setAutoBtn.Position = UDim2.new(1,-155,0.5,-14)
    setAutoBtn.BackgroundColor3 = btnBg; setAutoBtn.BorderSizePixel = 0
    setAutoBtn.Text = "Set Auto"; setAutoBtn.TextColor3 = Color3.fromRGB(220,220,235); setAutoBtn.Font = btnFont; setAutoBtn.TextSize = btnSize
    Instance.new("UICorner", setAutoBtn).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", setAutoBtn).Color = DARK.border

    local clearAutoBtn = Instance.new("TextButton", ac)
    clearAutoBtn.Size = UDim2.new(0,60,0,28); clearAutoBtn.Position = UDim2.new(1,-68,0.5,-14)
    clearAutoBtn.BackgroundColor3 = btnBg; clearAutoBtn.BorderSizePixel = 0
    clearAutoBtn.Text = "Clear"; clearAutoBtn.TextColor3 = Color3.fromRGB(220,220,235); clearAutoBtn.Font = btnFont; clearAutoBtn.TextSize = btnSize
    Instance.new("UICorner", clearAutoBtn).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", clearAutoBtn).Color = DARK.border

    saveBtn.MouseButton1Click:Connect(function()
        local name = cfgNameBox.Text
        if saveConfig(name) then
            selectedConfig = name:gsub("[^%w_%-]", "")
            cfgDropBtn.Text = selectedConfig .. "  ▾"
            cfgDropBtn.TextColor3 = DARK.hAccent
            populateConfigDropdown()
        end
    end)

    loadBtn.MouseButton1Click:Connect(function()
        local name = (cfgNameBox.Text ~= "" and cfgNameBox.Text) or selectedConfig
        loadConfig(name)
    end)

    delBtn.MouseButton1Click:Connect(function()
        local name = (cfgNameBox.Text ~= "" and cfgNameBox.Text) or selectedConfig
        if deleteConfig(name) then
            selectedConfig = ""
            cfgDropBtn.Text = "Select Config  ▾"
            cfgDropBtn.TextColor3 = Color3.fromRGB(240,230,255)
            cfgNameBox.Text = ""
            refreshAutoloadStatus()
            populateConfigDropdown()
        end
    end)

    setAutoBtn.MouseButton1Click:Connect(function()
        local name = (cfgNameBox.Text ~= "" and cfgNameBox.Text) or selectedConfig
        if not name or name == "" then
            showNotif("กรุณาเลือกหรือใส่ชื่อ Config ก่อน")
            return
        end
        if not fileExists(CONFIG_FOLDER .. "/" .. name .. ".json") then
            saveConfig(name)
        end
        setAutoloadConfig(name)
        refreshAutoloadStatus()
    end)

    clearAutoBtn.MouseButton1Click:Connect(function()
        clearAutoloadConfig()
        refreshAutoloadStatus()
    end)

    local miscInfo = Instance.new("TextLabel", pages["Misc"])
    miscInfo.Size = UDim2.new(1,0,0,76); miscInfo.BackgroundColor3 = DARK.item; miscInfo.BorderSizePixel = 0
    miscInfo.Text = "  [Config Info]\n" ..
        "  • โฟลเดอร์: 540Cheats_Configs/<name>.json\n" ..
        "  • บันทึกค่า: ฟังก์ชันทั้งหมด, หอคอยที่เลือก, สกิลที่เลือก\n" ..
        "  • Autoload: เมื่อตั้งไว้ จะดึงค่าคอนฟิกนี้มาเปิดทันทีที่รันสคริปต์"
    miscInfo.TextColor3 = Color3.fromRGB(220,220,240); miscInfo.TextXAlignment = Enum.TextXAlignment.Left
    miscInfo.TextYAlignment = Enum.TextYAlignment.Center; miscInfo.Font = FONT_MEDIUM; miscInfo.TextSize = 12
    Instance.new("UICorner", miscInfo).CornerRadius = UDim.new(0,8)

    task.spawn(function()
        task.wait(0.5)
        local auto = getAutoloadConfig()
        if auto and auto ~= "" then
            local path = CONFIG_FOLDER .. "/" .. auto .. ".json"
            if fileExists(path) then
                loadConfig(auto)
                pcall(function() showNotif("Autoloaded Config: " .. auto) end)
            end
        end
    end)
end
pcall(setupMiscTab)

-- ── Webhook tab ─────────────────────────────────────────────────────────────
local function setupWebhookTab()
    local banner = Instance.new("Frame", pages["Webhook"])
    banner.Size = UDim2.new(1, 0, 0, 52)
    banner.BackgroundColor3 = Color3.fromRGB(28, 20, 48)
    banner.BorderSizePixel = 0
    Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 8)
    local bStroke = Instance.new("UIStroke", banner)
    bStroke.Color = DARK.purple; bStroke.Thickness = 1.2

    local bIcon = Instance.new("TextLabel", banner)
    bIcon.Size = UDim2.new(0, 32, 1, 0); bIcon.Position = UDim2.new(0, 10, 0, 0)
    bIcon.BackgroundTransparency = 1; bIcon.Text = "📡"; bIcon.TextSize = 20
    bIcon.Font = FONT

    local bTitle = Instance.new("TextLabel", banner)
    bTitle.Size = UDim2.new(1, -55, 0, 20); bTitle.Position = UDim2.new(0, 45, 0, 8)
    bTitle.BackgroundTransparency = 1; bTitle.Text = "Discord Webhook Notification"
    bTitle.TextColor3 = Color3.new(1, 1, 1); bTitle.TextXAlignment = Enum.TextXAlignment.Left
    bTitle.Font = FONT; bTitle.TextSize = 13

    local bSub = Instance.new("TextLabel", banner)
    bSub.Size = UDim2.new(1, -55, 0, 16); bSub.Position = UDim2.new(0, 45, 0, 28)
    bSub.BackgroundTransparency = 1
    local hasHttp = getHttpRequestFunc() ~= nil
    bSub.Text = (hasHttp and "HTTP Request Supported ✓" or "⚠️ Executor does not support HTTP")
    bSub.TextColor3 = (hasHttp and Color3.fromRGB(100, 255, 140) or DARK.red)
    bSub.TextXAlignment = Enum.TextXAlignment.Left
    bSub.Font = FONT; bSub.TextSize = 10

    local urlCard = Instance.new("Frame", pages["Webhook"])
    urlCard.Size = UDim2.new(1, 0, 0, 80)
    urlCard.BackgroundColor3 = DARK.item
    urlCard.BorderSizePixel = 0
    Instance.new("UICorner", urlCard).CornerRadius = UDim.new(0, 8)

    local urlTitle = Instance.new("TextLabel", urlCard)
    urlTitle.Size = UDim2.new(1, -20, 0, 18); urlTitle.Position = UDim2.new(0, 12, 0, 8)
    urlTitle.BackgroundTransparency = 1; urlTitle.Text = "Discord Webhook URL"
    urlTitle.TextColor3 = DARK.text; urlTitle.TextXAlignment = Enum.TextXAlignment.Left
    urlTitle.Font = FONT_BOLD; urlTitle.TextSize = 14

    local urlBox = Instance.new("TextBox", urlCard)
    urlBox.Size = UDim2.new(1, -24, 0, 34); urlBox.Position = UDim2.new(0, 12, 0, 34)
    urlBox.BackgroundColor3 = Color3.fromRGB(22, 18, 34); urlBox.BorderSizePixel = 0
    urlBox.Text = tostring(CFG.WebhookUrl or "")
    urlBox.PlaceholderText = "วางลิงก์ https://discord.com/api/webhooks/... ที่นี่"
    urlBox.PlaceholderColor3 = DARK.subtext
    urlBox.TextColor3 = Color3.fromRGB(240, 230, 255)
    urlBox.Font = FONT_MEDIUM; urlBox.TextSize = 12; urlBox.ClearTextOnFocus = false
    urlBox.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", urlBox).CornerRadius = UDim.new(0, 6)
    local ubs = Instance.new("UIStroke", urlBox)
    ubs.Color = DARK.purple; ubs.Thickness = 1
    local uPad = Instance.new("UIPadding", urlBox)
    uPad.PaddingLeft = UDim.new(0, 8); uPad.PaddingRight = UDim.new(0, 8)

    urlBox.FocusLost:Connect(function()
        CFG.WebhookUrl = urlBox.Text:gsub("%s+", "")
        showNotif("บันทึก Webhook URL แล้ว")
    end)

    makeButton(pages["Webhook"], "Test Webhook", "ส่งข้อความทดสอบเพื่อเช็คว่าลิงก์เชื่อมต่อได้ถูกต้อง", "Send Test", function()
        sendTestWebhook()
    end)

    makeCfgToggle(pages["Webhook"], "WebhookEnabled", "Enable Webhook", "เปิด/ปิด ระบบแจ้งเตือน Discord ทั้งหมด")
    makeCfgToggle(pages["Webhook"], "WebhookNotifyRareUnit", "Rare Unit Alert", "แจ้งเตือนเมื่อทอยได้ยูนิตระดับหายาก")

    makeSelector(pages["Webhook"], "Minimum Rarity", "ระดับความหายากขั้นต่ำที่จะให้ส่งแจ้งเตือน", {
        { text = "1 in 10,000 (Rare+)", value = 10000 },
        { text = "1 in 100,000 (Epic+)", value = 100000 },
        { text = "1 in 1,000,000 (Legendary+)", value = 1000000 },
        { text = "1 in 10,000,000 (Mythic+)", value = 10000000 },
        { text = "1 in 100,000,000 (Secret+)", value = 100000000 },
        { text = "1 in 1,000,000,000 (Divine+)", value = 1000000000 }
    }, 2, function(val)
        CFG.WebhookMinRarity = val
    end)

    makeCfgToggle(pages["Webhook"], "WebhookNotifyTower", "Tower Completion Alert", "แจ้งเตือนเมื่อจบการลงหอคอยแต่ละรอบ (พร้อมชั้นสูงสุด)")
makeCfgToggle(pages["Webhook"], "WeatherNotifyWebhook", "Weather Event Alert", "ส่งแจ้งเตือนเข้า Discord ทันทีเมื่อเกิดสภาพอากาศพิเศษ (Luck / Cash / Speed Event)")
    makeCfgToggle(pages["Webhook"], "WebhookNotifyStats", "Periodic Stats Report", "ส่งสรุปสถานะการฟาร์ม (เงิน, Rebirth, ยูนิต) ตามเวลา")

    makeSelector(pages["Webhook"], "Report Interval", "ความถี่ในการส่งรายงานสรุปสถิติ", {
        { text = "Every 10 Minutes", value = 10 },
        { text = "Every 15 Minutes", value = 15 },
        { text = "Every 30 Minutes", value = 30 },
        { text = "Every 60 Minutes", value = 60 }
    }, 2, function(val)
        CFG.WebhookStatsInterval = val
    end)
end
-- [TEMPORARILY HIDDEN WEBHOOK TAB]
-- setupWebhookTab()

-- ── Settings tab ──────────────────────────────────────────────────────────────
do
local info=Instance.new("TextLabel",pages["Settings"])
info.Size=UDim2.new(1,0,0,450); info.BackgroundColor3=DARK.item; info.BorderSizePixel=0
info.Text="  CHEAT HUB v24\n\n" ..
    "  Main\n" ..
    "  Auto Collect        — 15 slots\n" ..
    "  Collect Cash Now    — instant 1-time collect\n" ..
    "  Auto Equip Best     — highest income unit\n" ..
    "  Auto Upgrade Skills — no notification spam\n\n" ..
    "  Roll\n" ..
    "  Auto Roll           — 2.6s per roll\n" ..
    "  Auto Rebirth        — on threshold\n" ..
    "  Auto Use Luck       — 19 potions auto-buff maintain\n" ..
    "  Auto Luck on Event  — auto burst best luck on Luck Event\n\n" ..
    "  Tower\n" ..
    "  Dropdown Menu       — clean multi-selection popup\n" ..
    "  Loop Mode           — repeat selected towers endlessly\n" ..
    "  Queue Runner        — 1 run each, from easiest to hardest\n" ..
    "  Menu-Safe Monitor   — unaffected by Daily/popup menus\n\n" ..
    "  Utility\n" ..
    "  AFK Super Saver     — 3D Off + Auto RAM Clean + Mute\n" ..
    "  Hide Game UI        — hide all game GUIs safely\n" ..
    "  Disable 3D Render   — white screen, extreme CPU/RAM save\n" ..
    "  Boost FPS           — remove shadows/particles/materials\n" ..
    "  Anti AFK            — F13 every 60s\n" ..
    "  Auto Quest          — Daily & Weekly\n\n" ..
    "  Misc (Config)\n" ..
    "  Save Profile        — save current settings as name\n" ..
    "  Load Profile        — load and auto-sync all UI\n" ..
    "  Delete Profile      — remove saved config file\n" ..
    "  Autoload            — automatically load on startup\n\n" ..
    "  Hotkeys\n" ..
    "  E=Collect  Q=Roll  X=UI  F1=Show"
info.TextColor3=DARK.text; info.TextXAlignment=Enum.TextXAlignment.Left
info.TextYAlignment=Enum.TextYAlignment.Top; info.Font=FONT; info.TextSize=12
Instance.new("UICorner",info).CornerRadius=UDim.new(0,8)
end

(function()
minimizedLogo=Instance.new("TextButton",gui)
minimizedLogo.Size=UDim2.new(0,50,0,50); minimizedLogo.Position=UDim2.new(0,25,0.5,-25)
minimizedLogo.BackgroundColor3=DARK.bg; minimizedLogo.BackgroundTransparency=0.2
minimizedLogo.BorderSizePixel=0; minimizedLogo.Text=""; minimizedLogo.Visible=false
minimizedLogo.Active=true
Instance.new("UICorner",minimizedLogo).CornerRadius=UDim.new(0,10)
local mls=Instance.new("UIStroke",minimizedLogo); mls.Color=DARK.accent; mls.Thickness=1.5; mls.Transparency=0.3
local mlI=Instance.new("ImageLabel",minimizedLogo)
mlI.Size=UDim2.new(0,36,0,36); mlI.Position=UDim2.new(0.5,-18,0.5,-18)
mlI.BackgroundTransparency=1; mlI.Image="rbxthumb://type=Asset&id=86571453491468&w=420&h=420"; mlI.ScaleType=Enum.ScaleType.Fit

local mDragging, mDragStart, mStartPos, mMoved = false, nil, nil, false
minimizedLogo.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        mDragging=true
        mMoved=false
        mDragStart=i.Position
        mStartPos=minimizedLogo.Position
    end
end)

UIS.InputChanged:Connect(function(i)
    if mDragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-mDragStart
        if math.abs(d.X)>3 or math.abs(d.Y)>3 then
            mMoved=true
        end
        minimizedLogo.Position=UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset+d.X, mStartPos.Y.Scale, mStartPos.Y.Offset+d.Y)
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        mDragging=false
    end
end)

minimizedLogo.MouseButton1Click:Connect(function()
    if not mMoved then
        minimizedLogo.Visible=false
        main.Visible=true
    end
end)

local wm=Instance.new("TextLabel",gui)
wm.Size=UDim2.new(0,320,0,30); wm.Position=UDim2.new(1,-340,1,-50)
wm.BackgroundTransparency=1; wm.Text="540 HUB | discord.gg/540shop"
wm.TextColor3=DARK.accent; wm.TextXAlignment=Enum.TextXAlignment.Right
wm.Font=FONT; wm.TextSize=14; wm.TextTransparency=0.2
wm.TextStrokeTransparency=0.4; wm.TextStrokeColor3=Color3.new(0,0,0); wm.Visible=false
end)()
end
pcall(buildHubUI)

UIS.InputBegan:Connect(function(i,g)
    if i.KeyCode==Enum.KeyCode.B and not UIS:GetFocusedTextBox() then
        pcall(function()
            local Backpack = UIReferences and UIReferences.Menus and UIReferences.Menus:FindFirstChild("Backpack")
            local MenuController = require(RS.Framework.Features.UI.MenuController)
            if Backpack and MenuController then
                if MenuController.ActiveMenu and MenuController.ActiveMenu() == Backpack then
                    MenuController.CloseMenu()
                else
                    MenuController.OpenMenu(Backpack)
                end
            end
        end)
        return
    end
    if i.KeyCode==Enum.KeyCode.E then
        CFG.AutoCollect=not CFG.AutoCollect
        showNotif("Auto Collect: "..(CFG.AutoCollect and "ON" or "OFF")); return end
    if i.KeyCode==Enum.KeyCode.Q then
        CFG.AutoRoll=not CFG.AutoRoll
        showNotif("Auto Roll: "..(CFG.AutoRoll and "ON" or "OFF")); return end
    if i.KeyCode==Enum.KeyCode.X then
        gui.Enabled=not gui.Enabled
        if gui.Enabled then main.Visible=true; minimizedLogo.Visible=false end; return end
    if i.KeyCode==Enum.KeyCode.F1 then
        gui.Enabled=true; main.Visible=true; minimizedLogo.Visible=false; return end
end)

print("[540 HUB] พร้อมใช้งาน ✓")
pcall(function() showNotif("540 HUB พร้อมใช้งานแล้ว ✓") end)

