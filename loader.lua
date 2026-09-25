-- 540CHEATS v24 GUI | Cheat Hub (Loop Towers Mode Added)

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer
local RS           = game:GetService("ReplicatedStorage")

local function waitForLoad()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(2)
end
waitForLoad()

-- ── Game Modules ──────────────────────────────────────────────────────────────
local RealUpgrades      = require(RS.Framework.Features.Upgrades.Upgrades)
local RealTreeStructure = require(RS.Framework.Features.Upgrades.TreeStructure)
local RealTowers        = require(RS.Framework.Features.Towers.Towers)
local TowerCtrl         = require(RS.Framework.Features.Towers.TowerController)
local UIReferences      = require(RS.Framework.Features.UI.UIReferences)
local HUDController     = require(RS.Framework.Features.UI.HUDController)
local UnitUtil          = nil; pcall(function() UnitUtil = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitUtil) end)
local PlotConfig        = nil; pcall(function() PlotConfig = require(RS.Framework.Features.Plot.PlotConfig) end)
local PlotController    = nil; pcall(function() PlotController = require(RS.Framework.Features.Plot.PlotController) end)

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

-- ── Remotes ───────────────────────────────────────────────────────────────────
local NetRoot = RS:WaitForChild("Network", 15)
assert(NetRoot, "[HUB] ไม่เจอ Network folder")

local function RE(svc, name)
    return NetRoot:WaitForChild(svc,10):WaitForChild("RE",10):WaitForChild(name,10)
end
local function RF(svc, name)
    return NetRoot:WaitForChild(svc,10):WaitForChild("RF",10):WaitForChild(name,10)
end
local function REroot(name)
    return NetRoot:WaitForChild("RE",10):WaitForChild(name,10)
end

local CollectBalance = RE("PlotService",     "CollectBalance")
local EquipBest      = RE("PlotService",     "EquipBest")
local LevelUpSlot    = RE("PlotService",     "LevelUpSlot")
local RebirthSignal  = RE("RebirthService",  "Rebirth")
local QuestSignal    = RE("QuestService",    "Claim")
local BuyDice        = RE("DiceShopService", "BuyDice")
local EquipDice      = RE("DiceShopService", "EquipDice")
local RollDice       = RF("RollService",     "RollDice")
local BuyUpgrade     = REroot("BuyUpgrade")
local CancelTower    = RF("Towers",          "CancelTower")
local EquipBestTeam  = RE("Towers",          "EquipBestTowerTeam")
local UseBoost       = nil
pcall(function() UseBoost = RE("BoostService", "Use") end)
if not UseBoost then
    pcall(function()
        local ClientComm = require(RS.Packages.Network).ClientComm
        local bComm = ClientComm.new(RS.Network, false, "BoostService")
        UseBoost = bComm:GetSignal("Use")
    end)
end

print("[HUB] Remotes OK")

local UPGRADE_PRICES = {}
local UPGRADE_PARENT = {}
for name, data in pairs(RealUpgrades) do
    if name ~= "Start" and data.price then
        UPGRADE_PRICES[name] = data.price
        local parent = RealTreeStructure.GetParent(name)
        if parent then UPGRADE_PARENT[name] = parent end
    end
end

local ALL_TOWERS = {}
for name, data in pairs(RealTowers.GetAll()) do
    table.insert(ALL_TOWERS, {
        name       = name,
        order      = data.order or 99,
        difficulty = (data.difficulty and data.difficulty.name) or "Normal"
    })
end
table.sort(ALL_TOWERS, function(a,b) return a.order < b.order end)

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

-- ── Luck Potions Definition (19 Potions across 6 Categories) ──────────────────
local LUCK_CATEGORIES = {
    {
        id = "Luck",
        name = "Standard Luck",
        sub = "Luck I - IV (1.25x - 4.25x)",
        items = {"Luck IV", "Luck III", "Luck II", "Luck I"}
    },
    {
        id = "Dragon Luck",
        name = "Dragon Luck",
        sub = "Dragon Luck I - III (1.25x - 2.0x)",
        items = {"Dragon Luck III", "Dragon Luck II", "Dragon Luck I"}
    },
    {
        id = "Cursed Luck",
        name = "Cursed Luck",
        sub = "Cursed Luck I - III (1.25x - 2.0x)",
        items = {"Cursed Luck III", "Cursed Luck II", "Cursed Luck I"}
    },
    {
        id = "Pirate Luck",
        name = "Pirate Luck",
        sub = "Pirate Luck I - III (1.5x - 3.0x)",
        items = {"Pirate Luck III", "Pirate Luck II", "Pirate Luck I"}
    },
    {
        id = "Leaf Luck",
        name = "Leaf Luck",
        sub = "Leaf Luck I - III (2.0x - 4.0x)",
        items = {"Leaf Luck III", "Leaf Luck II", "Leaf Luck I"}
    },
    {
        id = "Slayer Luck",
        name = "Slayer Luck",
        sub = "Slayer Luck I - III (2.0x - 4.0x)",
        items = {"Slayer Luck III", "Slayer Luck II", "Slayer Luck I"}
    },
}
local SelectedLuckCategories = {}
for _, cat in ipairs(LUCK_CATEGORIES) do
    SelectedLuckCategories[cat.id] = true
end

-- ── Constants ─────────────────────────────────────────────────────────────────
local REBIRTH_COSTS = {
    [1]=50000,[2]=5000000,[3]=500000000,[4]=50000000000,
    [5]=5000000000000,[6]=500000000000000,[7]=1e16,
    [8]=1e18,[9]=1e20,[10]=1e22,[11]=1e24,[12]=1e26,[13]=1e28,
}
local QUEST_PERIODS = {
    Daily  = {"Playtime","Rolls","Towers","UnitsSold"},
    Weekly = {"Playtime","Rolls","Towers","UnitsSold"},
}
local DICE_LIST = {
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

local SLOT_COUNT   = 15
local ROLL_DELAY   = 2.6
local COLLECT_LOOP = 1
local EQUIP_LOOP   = 5
local REBIRTH_LOOP = 2
local QUEST_LOOP   = 30
local DICE_LOOP    = 5
local UPGRADE_LOOP = 3
local PLOT_UPGRADE_LOOP = 0.3

local CFG = {
    AutoCollect      = false,
    AutoEquip        = false,
    AutoRoll         = false,
    FastAutoRoll     = false,
    RollDelay        = 0.1,
    SkipCutscene     = true,
    AutoRebirth      = false,
    AntiAFK          = false,
    AutoQuest        = false,
    AutoBuyDice      = false,
    AutoEquipDice    = false,
    AutoUpgrade      = false,
    AutoTowerQueue   = false,
    LoopTower        = false,
    EquipTeamBefore  = true,
    AutoUpgradePlot  = false,
    PlotTargetLvl    = 50,
    PlotUpgradeMode  = "Equal",
    BoostFPS         = false,
    Disable3DRender  = false,
    SuperRAMSaver    = false,
    HideGameUI       = false,
    AutoUseLuck      = false,
    AutoLuckOnEvent  = false,
}

local FONT = Enum.Font.RobotoMono
local DARK = {
    bg      = Color3.fromRGB(12,12,15),
    sidebar = Color3.fromRGB(15,15,20),
    header  = Color3.fromRGB(18,18,24),
    hAccent = Color3.fromRGB(0,200,255),
    item    = Color3.fromRGB(25,25,30),
    itemSel = Color3.fromRGB(42,30,62),
    text    = Color3.fromRGB(220,220,230),
    subtext = Color3.fromRGB(130,130,145),
    accent  = Color3.fromRGB(0,200,255),
    border  = Color3.fromRGB(35,35,45),
    tOn     = Color3.fromRGB(0,150,255),
    tOff    = Color3.fromRGB(45,45,55),
    purple  = Color3.fromRGB(150,105,255),
    red     = Color3.fromRGB(200,55,65),
    dropdown= Color3.fromRGB(20,20,26),
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

-- ── Cheat functions ───────────────────────────────────────────────────────────
local function collectAll()
    for s=1,SLOT_COUNT do
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

    local candidates = {}
    for s = 1, SLOT_COUNT do
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
local showNotif = nil

local function updateRunBtnText()
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

local function runSingleTower(towerName, curIndex, totalCount, loopCount)
    if CFG.EquipTeamBefore then
        pcall(function() EquipBestTeam:FireServer() end)
        task.wait(0.5)
    end

    TowerScreen.Visible = false
    TowerBg.Visible = false

    local ok, started = pcall(function() return TowerCtrl.startTower(towerName) end)
    if not ok or not started then
        print("[TOWER] ไม่สามารถเริ่มได้:", towerName)
        task.wait(2)
        return false
    end

    local loopStr = CFG.LoopTower and string.format("Loop #%d · ", loopCount) or ""

    if tBannerTitle and tBannerSub then
        tBannerTitle.Text = string.format("⚔️ [%d/%d] %s", curIndex, totalCount, towerName)
        tBannerSub.Text   = loopStr .. "Floor 1 · กำลังต่อสู้..."
    end

    task.spawn(function()
        for _ = 1, 10 do
            if HiddenBtn.Visible then
                if firesignal then
                    firesignal(HiddenBtn.Activated)
                else
                    HiddenBtn:Activate()
                end
                break
            end
            task.wait(0.1)
        end
        pcall(function()
            HUDController.showAll("inTower")
            TowerScreen.Visible = false
            TowerBg.Visible = false
            HiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
        end)
    end)

    local deadline = tick() + 900
    task.wait(1.5)
    
    while CFG.AutoTowerQueue and tick() < deadline do
        local txt = HiddenBtn.Label.Text
        local isStillPlaying = (txt ~= "Hide") or (txt:match("Floor"))
        
        if not isStillPlaying then
            task.wait(0.8)
            txt = HiddenBtn.Label.Text
            if (txt == "Hide") and not (txt:match("Floor")) then
                break
            end
        end

        local floorNum = txt:match("Floor (%d+)")
        if not floorNum and TowerScreen:FindFirstChild("Floor") then
            floorNum = TowerScreen.Floor.Text:match("Floor (%d+)")
        end
        if floorNum and tBannerSub then
            tBannerSub.Text = string.format("%sFloor %s · กำลังต่อสู้...", loopStr, floorNum)
        end
        task.wait(0.5)
    end

    if not CFG.AutoTowerQueue then
        pcall(function() CancelTower:InvokeServer() end)
    end

    print("[TOWER] จบ:", towerName)
    task.wait(2)
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
        if tBannerTitle then tBannerTitle.Text = "⚠️ No Towers Selected" end
        if tBannerSub then tBannerSub.Text = "กรุณากดปุ่ม Select Towers เพื่อเลือกหอคอยก่อนเริ่ม" end
        return
    end

    CFG.AutoTowerQueue = true
    isTowerBusy = true
    updateRunBtnText()

    if tBannerTitle then
        tBannerTitle.Text = string.format("⚔️ [1/%d] Preparing...", #queue)
    end
    if tBannerSub then
        tBannerSub.Text = "กำลังเข้าสู่หอคอย..."
    end

    _towerQueueThread = task.spawn(function()
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

        CFG.AutoTowerQueue = false
        isTowerBusy = false
        updateRunBtnText()

        if tBannerTitle then tBannerTitle.Text = "✅ Completed All Rounds" end
        if tBannerSub then tBannerSub.Text = "ลงเสร็จสิ้นทุกรอบแล้ว พร้อมเริ่มใหม่" end
    end)
end

local function stopTowerQueue()
    CFG.AutoTowerQueue = false
    if _towerQueueThread then
        task.cancel(_towerQueueThread)
        _towerQueueThread = nil
    end
    pcall(function() CancelTower:InvokeServer() end)
    isTowerBusy = false
    updateRunBtnText()

    if tBannerTitle then tBannerTitle.Text = "⏹ Queue Cancelled" end
    if tBannerSub then tBannerSub.Text = "หยุดการทำงานแล้ว พร้อมเริ่มรอบใหม่" end
end

-- ── Luck Potions Logic ────────────────────────────────────────────────────────
local EntryRegistry = nil
pcall(function() EntryRegistry = require(RS.Framework.Features.Inventory.EntryRegistry) end)

local function getLuckPotionsInInventory()
    local DC = getDC()
    if not DC or not DC.Inventory then return {}, 0 end
    local inv = DC.Inventory() or {}
    local counts = {}
    local total = 0
    for _, cat in ipairs(LUCK_CATEGORIES) do
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

local function getActiveLuckInfo()
    local DC = getDC()
    if not DC or not DC.ActiveEntries then return {} end
    local act = DC.ActiveEntries() or {}
    local now = workspace:GetServerTimeNow()
    local activeMap = {}

    for actKey, actData in pairs(act) do
        local cfg = nil
        if EntryRegistry and EntryRegistry.getEntryConfig then
            pcall(function() cfg = EntryRegistry.getEntryConfig(actData.name or actKey) end)
        end
        if cfg and cfg.kind == "Boost" and cfg.category and cfg.category:find("Luck") then
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

local function autoUseLuckPotions()
    local DC = getDC()
    if not DC or not DC.Inventory then return end
    local inv = DC.Inventory() or {}
    local activeMap = getActiveLuckInfo()

    for _, cat in ipairs(LUCK_CATEGORIES) do
        if SelectedLuckCategories[cat.id] ~= false then
            local curActive = activeMap[cat.id]
            -- If active buff has 3s or less remaining, consume the best potion in this category
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

local function useBestLuckNow(forceAllCategories)
    local DC = getDC()
    if not DC or not DC.Inventory then
        pcall(function() showNotif("ไม่สามารถอ่านข้อมูล Inventory ได้") end)
        return 0
    end
    local inv = DC.Inventory() or {}
    local usedCount = 0

    for _, cat in ipairs(LUCK_CATEGORIES) do
        if forceAllCategories or (SelectedLuckCategories[cat.id] ~= false) then
            for _, potionName in ipairs(cat.items) do
                local itemEntry = inv[potionName]
                local amt = itemEntry and itemEntry.amount or 0
                if amt > 0 then
                    fireUseBoost(potionName)
                    usedCount = usedCount + 1
                    task.wait(0.05)
                    break
                end
            end
        end
    end
    if not forceAllCategories then
        if usedCount > 0 then
            pcall(function() showNotif("⚡ กดใช้น้ำยาโชคระดับสูงสุด " .. usedCount .. " หมวดหมู่แล้ว ✓") end)
        else
            pcall(function() showNotif("ไม่มีน้ำยาโชคในหมวดหมู่ที่เลือกอยู่ในกระเป๋า") end)
        end
    end
    return usedCount
end

-- ── Weather (Server Event) Observer ───────────────────────────────────────────
local currentServerWeather = nil
local lastHandledWeatherStart = nil

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
                task.spawn(checkEventAutoLuck)
            else
                lastHandledWeatherStart = nil
            end
        end)
    end)
end
task.spawn(setupWeatherListener)

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
    if CFG.AutoEquip then pcall(function() EquipBest:FireServer() end) end
end end)
task.spawn(function()
    while true do
        local delayTime = 2.6
        if CFG.FastAutoRoll then
            delayTime = CFG.RollDelay or 0.1
        elseif CFG.AutoRoll then
            delayTime = CFG.RollDelay or 2.6
        end
        task.wait(math.max(0.05, delayTime))
        if CFG.FastAutoRoll or CFG.AutoRoll then
            pcall(function() RollDice:InvokeServer() end)
        end
    end
end)
task.spawn(function() while true do task.wait(REBIRTH_LOOP)
    if CFG.AutoRebirth then tryRebirth() end
end end)
task.spawn(function() while true do task.wait(QUEST_LOOP)
    if CFG.AutoQuest then claimAllQuests() end
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
    if CFG.AutoUseLuck then pcall(autoUseLuckPotions) end
end end)
task.spawn(function() while true do task.wait(60)
    if CFG.AntiAFK then
        pcall(function()
            VIM:SendKeyEvent(true,Enum.KeyCode.F13,false,game)
            task.wait(0.05)
            VIM:SendKeyEvent(false,Enum.KeyCode.F13,false,game)
        end)
    end
end end)

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

local targetParent = LP:WaitForChild("PlayerGui")
pcall(function()
    if gethui then
        targetParent = gethui()
    end
end)

gui=Instance.new("ScreenGui")
gui.Name="540CHEATS_v24"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=targetParent

notif=Instance.new("TextLabel",gui)
notif.Size=UDim2.new(0,300,0,32); notif.Position=UDim2.new(0.5,-150,0,-40)
notif.BackgroundColor3=DARK.bg; notif.BackgroundTransparency=0.15
notif.TextColor3=DARK.accent; notif.Font=FONT; notif.TextSize=13; notif.Visible=false
Instance.new("UICorner",notif).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",notif).Color=DARK.accent

showNotif = function(text)
    notif.Text="  > "..text; notif.Visible=true
    TweenService:Create(notif,TweenInfo.new(0.3),{Position=UDim2.new(0.5,-150,0,20)}):Play()
    task.delay(1.5,function()
        TweenService:Create(notif,TweenInfo.new(0.3),{Position=UDim2.new(0.5,-150,0,-40)}):Play()
        task.wait(0.4); notif.Visible=false end)
end

main=Instance.new("Frame")
main.Size=UDim2.new(0,640,0,500); main.Position=UDim2.new(0.5,-320,0.5,-250)
main.BackgroundColor3=DARK.bg; main.BorderSizePixel=0; main.Active=true; main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
Instance.new("UIStroke",main).Color=DARK.border

local HH=54
do
local header=Instance.new("Frame",main)
header.Size=UDim2.new(1,0,0,HH); header.BackgroundColor3=DARK.header; header.BorderSizePixel=0
Instance.new("UICorner",header).CornerRadius=UDim.new(0,12)
local hBot=Instance.new("Frame",header)
hBot.Size=UDim2.new(1,0,0,12); hBot.Position=UDim2.new(0,0,1,-12)
hBot.BackgroundColor3=DARK.header; hBot.BorderSizePixel=0
local aL=Instance.new("Frame",header)
aL.Size=UDim2.new(1,-24,0,1); aL.Position=UDim2.new(0,12,1,-1)
aL.BackgroundColor3=DARK.hAccent; aL.BorderSizePixel=0; aL.BackgroundTransparency=0.5

local dragging,dragStart,startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; startPos=main.Position end end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

local logoBg=Instance.new("Frame",header)
logoBg.Size=UDim2.new(0,34,0,34); logoBg.Position=UDim2.new(0,14,0,10)
logoBg.BackgroundColor3=Color3.fromRGB(25,25,35); logoBg.BorderSizePixel=0
Instance.new("UICorner",logoBg).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",logoBg).Color=DARK.hAccent
local hIcon=Instance.new("ImageLabel",logoBg)
hIcon.Size=UDim2.new(0,26,0,26); hIcon.Position=UDim2.new(0.5,-13,0.5,-13)
hIcon.BackgroundTransparency=1; hIcon.Image="rbxassetid://86571453491468"; hIcon.ScaleType=Enum.ScaleType.Fit

local hT=Instance.new("TextLabel",header)
hT.Size=UDim2.new(0,200,0,18); hT.Position=UDim2.new(0,58,0,10)
hT.BackgroundTransparency=1; hT.Text="CHEAT HUB"
hT.TextColor3=Color3.new(1,1,1); hT.TextXAlignment=Enum.TextXAlignment.Left
hT.Font=FONT; hT.TextSize=14
local hS=Instance.new("TextLabel",header)
hS.Size=UDim2.new(0,200,0,14); hS.Position=UDim2.new(0,58,0,29)
hS.BackgroundTransparency=1; hS.Text="discord.gg/540shop"
hS.TextColor3=DARK.subtext; hS.TextXAlignment=Enum.TextXAlignment.Left
hS.Font=FONT; hS.TextSize=10

local bCont=Instance.new("Frame",header)
bCont.Size=UDim2.new(0,68,0,30); bCont.Position=UDim2.new(1,-80,0,12); bCont.BackgroundTransparency=1
local minBtn=Instance.new("TextButton",bCont)
minBtn.Size=UDim2.new(0,30,1,0); minBtn.BackgroundColor3=Color3.fromRGB(28,38,55)
minBtn.BorderSizePixel=0; minBtn.Text="—"; minBtn.TextColor3=Color3.fromRGB(200,210,230)
minBtn.Font=FONT; minBtn.TextSize=16
Instance.new("UICorner",minBtn).CornerRadius=UDim.new(0,6)
minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(0,120,200),TextColor3=Color3.new(1,1,1)}):Play() end)
minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(28,38,55),TextColor3=Color3.fromRGB(200,210,230)}):Play() end)
minBtn.MouseButton1Click:Connect(function() main.Visible=false; minimizedLogo.Visible=true end)
local closeBtn=Instance.new("TextButton",bCont)
closeBtn.Size=UDim2.new(0,30,1,0); closeBtn.Position=UDim2.new(0,38,0,0)
closeBtn.BackgroundColor3=Color3.fromRGB(55,28,34); closeBtn.BorderSizePixel=0
closeBtn.Text="×"; closeBtn.TextColor3=Color3.fromRGB(230,180,190)
closeBtn.Font=FONT; closeBtn.TextSize=18
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(200,50,60),TextColor3=Color3.new(1,1,1)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(55,28,34),TextColor3=Color3.fromRGB(230,180,190)}):Play() end)
closeBtn.MouseButton1Click:Connect(function()
    for k, _ in pairs(CFG) do CFG[k]=false end
    stopTowerQueue()
    pcall(function() gui:Destroy() end) end)
end

local sidebar=Instance.new("Frame",main)
sidebar.Size=UDim2.new(0,160,1,-HH); sidebar.Position=UDim2.new(0,0,0,HH)
sidebar.BackgroundColor3=DARK.sidebar; sidebar.BorderSizePixel=0

local tabs={}; local pages={}
local tabCont=Instance.new("Frame",sidebar)
tabCont.Size=UDim2.new(1,0,1,-90); tabCont.BackgroundTransparency=1
Instance.new("UIListLayout",tabCont).Padding=UDim.new(0,2)
local tp=Instance.new("UIPadding",tabCont)
tp.PaddingTop=UDim.new(0,12); tp.PaddingLeft=UDim.new(0,10); tp.PaddingRight=UDim.new(0,10)

local function createTab(name,icon)
    local btn=Instance.new("TextButton",tabCont)
    btn.Size=UDim2.new(1,0,0,34); btn.BackgroundColor3=DARK.item
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0; btn.Text=""
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    local ico=Instance.new("TextLabel",btn)
    ico.Size=UDim2.new(0,22,0,34); ico.Position=UDim2.new(0,8,0,0)
    ico.BackgroundTransparency=1; ico.Text=icon; ico.TextColor3=DARK.subtext
    ico.TextXAlignment=Enum.TextXAlignment.Left; ico.Font=FONT; ico.TextSize=14
    local lbl=Instance.new("TextLabel",btn)
    lbl.Size=UDim2.new(1,-36,1,0); lbl.Position=UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=DARK.subtext
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Font=FONT; lbl.TextSize=12
    local page=Instance.new("ScrollingFrame",main)
    page.Size=UDim2.new(1,-180,1,-HH-20); page.Position=UDim2.new(0,170,0,HH+10)
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=DARK.accent
    page.CanvasSize=UDim2.new(0,0,0,0); page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.Visible=false
    Instance.new("UIListLayout",page).Padding=UDim.new(0,8)
    local pp=Instance.new("UIPadding",page); pp.PaddingTop=UDim.new(0,5); pp.PaddingRight=UDim.new(0,8)
    tabs[name]=btn; pages[name]=page
    btn.MouseButton1Click:Connect(function()
        for n,t in pairs(tabs) do
            t.BackgroundTransparency=1; pages[n].Visible=false
            t:FindFirstChild("TextLabel").TextColor3=DARK.subtext end
        btn.BackgroundTransparency=0; btn.BackgroundColor3=DARK.item
        page.Visible=true; lbl.TextColor3=Color3.new(1,1,1); ico.TextColor3=DARK.accent end)
end

createTab("Main","🏠"); createTab("Roll","🎲"); createTab("Skill","⚡")
createTab("Tower","🏰"); createTab("Utility","⚙️"); createTab("Misc","💾"); createTab("Settings","🛠️")
tabs["Main"].BackgroundTransparency=0; tabs["Main"].BackgroundColor3=DARK.item
pages["Main"].Visible=true
tabs["Main"]:FindFirstChild("TextLabel").TextColor3=Color3.new(1,1,1)

do
local uPanel=Instance.new("Frame",sidebar)
uPanel.Size=UDim2.new(1,-20,0,60); uPanel.Position=UDim2.new(0,10,1,-70)
uPanel.BackgroundColor3=DARK.item; uPanel.BorderSizePixel=0
Instance.new("UICorner",uPanel).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",uPanel).Color=DARK.border
local uAv=Instance.new("ImageLabel",uPanel)
uAv.Size=UDim2.new(0,40,0,40); uAv.Position=UDim2.new(0,10,0.5,-20)
uAv.BackgroundColor3=Color3.fromRGB(30,30,40); uAv.BorderSizePixel=0
Instance.new("UICorner",uAv).CornerRadius=UDim.new(1,0)
Instance.new("UIStroke",uAv).Color=DARK.accent
local uNm=Instance.new("TextLabel",uPanel)
uNm.Size=UDim2.new(1,-60,0,16); uNm.Position=UDim2.new(0,58,0,10)
uNm.BackgroundTransparency=1; uNm.Text=LP.Name; uNm.TextColor3=Color3.new(1,1,1)
uNm.TextXAlignment=Enum.TextXAlignment.Left; uNm.Font=FONT; uNm.TextSize=11; uNm.TextTruncate=Enum.TextTruncate.AtEnd
local uId=Instance.new("TextLabel",uPanel)
uId.Size=UDim2.new(1,-60,0,14); uId.Position=UDim2.new(0,58,0,28)
uId.BackgroundTransparency=1; uId.Text="ID: "..LP.UserId
uId.TextColor3=DARK.subtext; uId.TextXAlignment=Enum.TextXAlignment.Left; uId.Font=FONT; uId.TextSize=10
task.spawn(function()
    local ok,t=pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
    if ok and t then uAv.Image=t end end)
end

local function makeToggle(parent,label,sublabel,initial,cb)
    local h=sublabel and 52 or 36
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-60,0,18); l.Position=UDim2.new(0,14,0,sublabel and 7 or 9)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT; l.TextSize=12
    if sublabel then
        local s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-60,0,14); s.Position=UDim2.new(0,14,0,28)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT; s.TextSize=10
    end
    local sw=Instance.new("Frame",c)
    sw.Size=UDim2.new(0,38,0,20); sw.Position=UDim2.new(1,-50,0.5,-10)
    sw.BackgroundColor3=initial and DARK.tOn or DARK.tOff; sw.BorderSizePixel=0
    Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
    local k=Instance.new("Frame",sw)
    k.Size=UDim2.new(0,14,0,14)
    k.Position=initial and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,3,0.5,-7)
    k.BackgroundColor3=Color3.new(1,1,1); k.BorderSizePixel=0
    Instance.new("UICorner",k).CornerRadius=UDim.new(1,0)
    local st=initial
    local function setVisual(val)
        st = (val == true)
        sw.BackgroundColor3 = st and DARK.tOn or DARK.tOff
        TweenService:Create(k,TweenInfo.new(0.15),{
            Position=st and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
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
    local h=sublabel and 52 or 36
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-105,0,18); l.Position=UDim2.new(0,14,0,sublabel and 7 or 9)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT; l.TextSize=12
    if sublabel then
        local s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-105,0,14); s.Position=UDim2.new(0,14,0,28)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT; s.TextSize=10
    end

    local actionBtn=Instance.new("TextButton",c)
    actionBtn.Size=UDim2.new(0,75,0,28); actionBtn.Position=UDim2.new(1,-87,0.5,-14)
    actionBtn.BackgroundColor3=Color3.fromRGB(32,24,48); actionBtn.BorderSizePixel=0
    actionBtn.Text=btnText or "Collect"; actionBtn.TextColor3=Color3.fromRGB(240,230,255)
    actionBtn.Font=FONT; actionBtn.TextSize=11
    Instance.new("UICorner",actionBtn).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",actionBtn)
    stroke.Color=DARK.purple; stroke.Thickness=1.2

    local busy=false
    actionBtn.MouseButton1Click:Connect(function()
        if busy then return end
        busy=true
        TweenService:Create(actionBtn,TweenInfo.new(0.08),{BackgroundColor3=DARK.purple,TextColor3=Color3.new(1,1,1)}):Play()
        task.wait(0.1)
        TweenService:Create(actionBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(32,24,48),TextColor3=Color3.fromRGB(240,230,255)}):Play()
        pcall(cb)
        task.wait(0.2)
        busy=false
    end)
    return c
end

local function makeInput(parent,label,sublabel,defaultVal,cb)
    local h=sublabel and 52 or 36
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-105,0,18); l.Position=UDim2.new(0,14,0,sublabel and 7 or 9)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT; l.TextSize=12
    if sublabel then
        local s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-105,0,14); s.Position=UDim2.new(0,14,0,28)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT; s.TextSize=10
    end

    local tb=Instance.new("TextBox",c)
    tb.Size=UDim2.new(0,75,0,28); tb.Position=UDim2.new(1,-87,0.5,-14)
    tb.BackgroundColor3=Color3.fromRGB(32,24,48); tb.BorderSizePixel=0
    tb.Text=tostring(defaultVal or ""); tb.TextColor3=Color3.fromRGB(240,230,255)
    tb.Font=FONT; tb.TextSize=11; tb.ClearTextOnFocus=false
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",tb)
    stroke.Color=DARK.purple; stroke.Thickness=1.2

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
    local h=sublabel and 52 or 36
    local c=Instance.new("Frame",parent)
    c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=DARK.item; c.BorderSizePixel=0
    Instance.new("UICorner",c).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",c)
    l.Size=UDim2.new(1,-170,0,18); l.Position=UDim2.new(0,14,0,sublabel and 7 or 9)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=DARK.text
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=FONT; l.TextSize=12
    local s=nil
    if sublabel then
        local sLbl=Instance.new("TextLabel",c)
        sLbl.Size=UDim2.new(1,-170,0,14); sLbl.Position=UDim2.new(0,14,0,28)
        sLbl.BackgroundTransparency=1; sLbl.Text=sublabel; sLbl.TextColor3=DARK.subtext
        sLbl.TextXAlignment=Enum.TextXAlignment.Left; sLbl.Font=FONT; sLbl.TextSize=10
        s = sLbl
    end

    local selBtn=Instance.new("TextButton",c)
    selBtn.Size=UDim2.new(0,145,0,28); selBtn.Position=UDim2.new(1,-155,0.5,-14)
    selBtn.BackgroundColor3=Color3.fromRGB(32,24,48); selBtn.BorderSizePixel=0
    selBtn.Font=FONT; selBtn.TextSize=11; selBtn.TextColor3=Color3.fromRGB(240,230,255)
    Instance.new("UICorner",selBtn).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",selBtn)
    stroke.Color=DARK.purple; stroke.Thickness=1.2

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

local plotLvlBox, setPlotMode, setRollDelay
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
makeCfgToggle(pages["Main"],"AutoEquip","Auto Equip Best","เลือกสวมใส่ยูนิตที่ทำรายได้สูงสุดอัตโนมัติ")
end
setupMainTab()

-- ── Roll tab ──────────────────────────────────────────────────────────────────
local function setupRollTab()
makeCfgToggle(pages["Roll"],"FastAutoRoll","Fast Auto Roll","ทอยลูกเต๋าแบบเร็วพิเศษ ยิงคำสั่งรัวตาม Cooldown เซิร์ฟเวอร์")
local _, srd = makeSelector(pages["Roll"],"Roll Delay","ปรับความเร็วการส่งคำสั่งทอยลูกเต๋า",{
    { text = "0.1s (Ultra Fast)", value = 0.1, sub = "ยิงรัวทุก 0.1s ทันทีที่เซิร์ฟเวอร์พร้อม (~1.2s-2.5s)" },
    { text = "0.2s (Fast)",       value = 0.2, sub = "ยิงทุก 0.2s รวดเร็วและลดโหลดส่งข้อมูล" },
    { text = "0.5s (Medium)",     value = 0.5, sub = "ทอยเร็วปานกลางทุก 0.5s" },
    { text = "1.0s (Normal)",     value = 1.0, sub = "ทอยทุก 1 วินาที" },
    { text = "2.6s (Default)",    value = 2.6, sub = "ทอยตามความเร็วพื้นฐานเดิมของเกม" },
}, 1, function(val) CFG.RollDelay = val end)
setRollDelay = srd
makeCfgToggle(pages["Roll"],"SkipCutscene","Skip Roll Cutscene (Fast)","ข้ามฉากคัตซีนแรร์ ไม่ล็อกมุมกล้อง ไม่เสียเวลาคัตซีน")
makeCfgToggle(pages["Roll"],"AutoRoll","Normal Auto Roll","ทอยลูกเต๋าแบบปกติ (ดีเลย์ 2.6 วินาที)")
makeCfgToggle(pages["Roll"],"AutoBuyDice","Auto Buy Best Dice","ซื้อลูกเต๋าที่มีค่าโชคสูงสุดอัตโนมัติ")
makeCfgToggle(pages["Roll"],"AutoEquipDice","Auto Equip Best Dice","สวมใส่ลูกเต๋าที่ดีที่สุดอัตโนมัติ")
makeCfgToggle(pages["Roll"],"AutoRebirth","Auto Rebirth","รีเบิร์ธอัตโนมัติเมื่อเงินถึงเกณฑ์ที่กำหนด")
makeCfgToggle(pages["Roll"],"AutoUseLuck","Auto Use Luck Potions","กดใช้น้ำยาโชคอัตโนมัติเมื่อเวลาบัฟหมด")
makeCfgToggle(pages["Roll"],"AutoLuckOnEvent","Auto Luck on Luck Event","เมื่อ Luck Event เซิร์ฟเวอร์เริ่ม จะกดใช้น้ำยาโชคทุกชนิด (Tier สูงสุด) ทันทีอย่างละ 1 ครั้ง", function(val)
    if val then
        task.spawn(checkEventAutoLuck)
    end
end)

local luckDropCard=Instance.new("Frame",pages["Roll"])
luckDropCard.Size=UDim2.new(1,0,0,96); luckDropCard.BackgroundColor3=DARK.item; luckDropCard.BorderSizePixel=0
Instance.new("UICorner",luckDropCard).CornerRadius=UDim.new(0,8)

local lTitle=Instance.new("TextLabel",luckDropCard)
lTitle.Size=UDim2.new(1,-170,0,18); lTitle.Position=UDim2.new(0,14,0,7)
lTitle.BackgroundTransparency=1; lTitle.Text="🧪 Luck Potions Manager (19 Items)"
lTitle.TextColor3=DARK.text; lTitle.TextXAlignment=Enum.TextXAlignment.Left; lTitle.Font=FONT; lTitle.TextSize=12

local lSub=Instance.new("TextLabel",luckDropCard)
lSub.Size=UDim2.new(1,-170,0,14); lSub.Position=UDim2.new(0,14,0,26)
lSub.BackgroundTransparency=1; lSub.Text="เลือกหมวดหมู่น้ำยาโชคที่ต้องการใช้งาน"
lSub.TextColor3=DARK.subtext; lSub.TextXAlignment=Enum.TextXAlignment.Left; lSub.Font=FONT; lSub.TextSize=10

local lStatusLbl=Instance.new("TextLabel",luckDropCard)
lStatusLbl.Size=UDim2.new(1,-170,0,20); lStatusLbl.Position=UDim2.new(0,14,0,48)
lStatusLbl.BackgroundTransparency=1; lStatusLbl.Text="Active: ตรวจสอบสถานะ..."
lStatusLbl.TextColor3=Color3.fromRGB(80,255,160); lStatusLbl.TextXAlignment=Enum.TextXAlignment.Left; lStatusLbl.Font=FONT; lStatusLbl.TextSize=10

local lEventLbl=Instance.new("TextLabel",luckDropCard)
lEventLbl.Size=UDim2.new(1,-28,0,18); lEventLbl.Position=UDim2.new(0,14,0,70)
lEventLbl.BackgroundTransparency=1; lEventLbl.Text="🌟 Server Event: ติดตามสถานะอีเวนต์..."
lEventLbl.TextColor3=DARK.hAccent; lEventLbl.TextXAlignment=Enum.TextXAlignment.Left; lEventLbl.Font=FONT; lEventLbl.TextSize=10

luckDropBtn=Instance.new("TextButton",luckDropCard)
luckDropBtn.Size=UDim2.new(0,145,0,28); luckDropBtn.Position=UDim2.new(1,-155,0,8)
luckDropBtn.BackgroundColor3=Color3.fromRGB(32,24,48); luckDropBtn.BorderSizePixel=0
luckDropBtn.Text="All Potions (6/6)  ▾"; luckDropBtn.TextColor3=Color3.fromRGB(240,230,255)
luckDropBtn.Font=FONT; luckDropBtn.TextSize=11
Instance.new("UICorner",luckDropBtn).CornerRadius=UDim.new(0,6)
local luckDropBtnStroke=Instance.new("UIStroke",luckDropBtn)
luckDropBtnStroke.Color=DARK.purple; luckDropBtnStroke.Thickness=1.2

local useNowBtn=Instance.new("TextButton",luckDropCard)
useNowBtn.Size=UDim2.new(0,145,0,24); useNowBtn.Position=UDim2.new(1,-155,0,44)
useNowBtn.BackgroundColor3=Color3.fromRGB(40,30,55); useNowBtn.BorderSizePixel=0
useNowBtn.Text="⚡ Use Best Now"; useNowBtn.TextColor3=Color3.fromRGB(255,215,80)
useNowBtn.Font=FONT; useNowBtn.TextSize=10
Instance.new("UICorner",useNowBtn).CornerRadius=UDim.new(0,6)
local unbStroke=Instance.new("UIStroke",useNowBtn); unbStroke.Color=DARK.border

useNowBtn.MouseButton1Click:Connect(function()
    useBestLuckNow()
end)

local LUCK_ITEM_H = 34
local LUCK_PADDING = 2
local totalLuckHeight = #LUCK_CATEGORIES * (LUCK_ITEM_H + LUCK_PADDING) + 10

luckDropMenu=Instance.new("ScrollingFrame",main)
luckDropMenu.Size=UDim2.new(0,225,0,math.min(220, totalLuckHeight))
luckDropMenu.BackgroundColor3=DARK.dropdown
luckDropMenu.BorderSizePixel=0; luckDropMenu.ScrollBarThickness=4
luckDropMenu.ScrollBarImageColor3=DARK.purple; luckDropMenu.Visible=false; luckDropMenu.ZIndex=100
luckDropMenu.CanvasSize=UDim2.new(0, 0, 0, totalLuckHeight)
luckDropMenu.AutomaticCanvasSize=Enum.AutomaticSize.None
Instance.new("UICorner",luckDropMenu).CornerRadius=UDim.new(0,8)
local ldmStroke=Instance.new("UIStroke",luckDropMenu); ldmStroke.Color=DARK.border; ldmStroke.Thickness=1.5
local ldList=Instance.new("UIListLayout",luckDropMenu); ldList.Padding=UDim.new(0,LUCK_PADDING)
local ldPad=Instance.new("UIPadding",luckDropMenu)
ldPad.PaddingTop=UDim.new(0,5); ldPad.PaddingBottom=UDim.new(0,5)
ldPad.PaddingLeft=UDim.new(0,5); ldPad.PaddingRight=UDim.new(0,5)

updateLuckDropBtnText = function()
    local count=0
    for _,sel in pairs(SelectedLuckCategories) do if sel then count=count+1 end end
    if count==0 then
        luckDropBtn.Text="All Potions (0/6)  ▾"
        luckDropBtn.TextColor3=Color3.fromRGB(240,230,255)
    elseif count==#LUCK_CATEGORIES then
        luckDropBtn.Text="All Potions (6/6)  ▾"
        luckDropBtn.TextColor3=DARK.hAccent
    else
        luckDropBtn.Text=string.format("Selected (%d/%d)  ▾", count, #LUCK_CATEGORIES)
        luckDropBtn.TextColor3=DARK.hAccent
    end
end
updateLuckDropBtnText()

local function toggleLuckDropdown()
    if luckDropMenu.Visible then
        luckDropMenu.Visible=false
    else
        if dropMenu then dropMenu.Visible=false end
        if skillDropMenu then skillDropMenu.Visible=false end
        local absPos=luckDropBtn.AbsolutePosition
        local mainPos=main.AbsolutePosition
        luckDropMenu.Position=UDim2.new(0, absPos.X-mainPos.X-75, 0, absPos.Y-mainPos.Y+32)
        luckDropMenu.Visible=true
    end
end
luckDropBtn.MouseButton1Click:Connect(toggleLuckDropdown)

refreshLuckOpts = {}
for _, cat in ipairs(LUCK_CATEGORIES) do
    local opt=Instance.new("TextButton",luckDropMenu)
    opt.Size=UDim2.new(1,0,0,LUCK_ITEM_H); opt.BackgroundColor3=DARK.item; opt.BackgroundTransparency=1
    opt.BorderSizePixel=0; opt.Text=""; opt.ZIndex=101
    Instance.new("UICorner",opt).CornerRadius=UDim.new(0,6)

    local chk=Instance.new("TextLabel",opt)
    chk.Size=UDim2.new(0,18,1,0); chk.Position=UDim2.new(0,6,0,0)
    chk.BackgroundTransparency=1; chk.Text="○"; chk.TextColor3=DARK.subtext
    chk.Font=FONT; chk.TextSize=12; chk.ZIndex=102

    local oName=Instance.new("TextLabel",opt)
    oName.Size=UDim2.new(1,-28,0,16); oName.Position=UDim2.new(0,26,0,2)
    oName.BackgroundTransparency=1; oName.Text=cat.name; oName.TextColor3=DARK.text
    oName.TextXAlignment=Enum.TextXAlignment.Left; oName.Font=FONT; oName.TextSize=11; oName.ZIndex=102

    local oSub=Instance.new("TextLabel",opt)
    oSub.Size=UDim2.new(1,-28,0,14); oSub.Position=UDim2.new(0,26,0,18)
    oSub.BackgroundTransparency=1; oSub.Text=cat.sub; oSub.TextColor3=DARK.subtext
    oSub.TextXAlignment=Enum.TextXAlignment.Left; oSub.Font=FONT; oSub.TextSize=9; oSub.ZIndex=102

    local function refreshOpt()
        local isSel=SelectedLuckCategories[cat.id]==true
        chk.Text=isSel and "●" or "○"
        chk.TextColor3=isSel and DARK.hAccent or DARK.subtext
        oName.TextColor3=isSel and Color3.new(1,1,1) or DARK.text
        opt.BackgroundTransparency=isSel and 0 or 1
        opt.BackgroundColor3=isSel and DARK.itemSel or DARK.item
    end
    refreshOpt()
    table.insert(refreshLuckOpts, refreshOpt)

    opt.MouseButton1Click:Connect(function()
        SelectedLuckCategories[cat.id]=not SelectedLuckCategories[cat.id]
        refreshOpt()
        updateLuckDropBtnText()
    end)
end

task.spawn(function()
    while true do
        task.wait(1.5)
        pcall(function()
            local activeMap = getActiveLuckInfo()
            local activeParts = {}
            for _, cat in ipairs(LUCK_CATEGORIES) do
                local cur = activeMap[cat.id]
                if cur and cur.remaining > 0 then
                    table.insert(activeParts, cur.name .. " (" .. cur.remaining .. "s)")
                end
            end
            if #activeParts > 0 then
                lStatusLbl.Text = "Active: " .. table.concat(activeParts, ", ")
                lStatusLbl.TextColor3 = Color3.fromRGB(80,255,160)
            else
                lStatusLbl.Text = "Active: ไม่มีน้ำยาทำงานอยู่ (Idle)"
                lStatusLbl.TextColor3 = DARK.subtext
            end

            local counts, total = getLuckPotionsInInventory()
            lSub.Text = "มีน้ำยาในกระเป๋า: " .. total .. " ชิ้น (เลือกเปิด/ปิดตามหมวด)"

            if currentServerWeather and currentServerWeather.name then
                local now = workspace:GetServerTimeNow()
                local started = currentServerWeather.startedAt or now
                local dur = currentServerWeather.duration or 300
                local rem = math.max(0, math.floor(dur - (now - started)))
                lEventLbl.Text = "🌟 Server Event: " .. tostring(currentServerWeather.name) .. " (เหลือ " .. rem .. "s)"
                lEventLbl.TextColor3 = Color3.fromRGB(255,215,80)
            else
                lEventLbl.Text = "🌟 Server Event: ไม่มีอีเวนต์ในเซิร์ฟเวอร์ขณะนี้ (Idle)"
                lEventLbl.TextColor3 = DARK.subtext
            end

            if CFG.AutoLuckOnEvent then
                checkEventAutoLuck()
            end
        end)
    end
end)


end
setupRollTab()

-- ── Skill tab ─────────────────────────────────────────────────────────────────
local function setupSkillTab()
makeCfgToggle(pages["Skill"],"AutoUpgrade","Auto Upgrade Skills","อัปเกรด Skill Tree ตามสายที่เลือกอัตโนมัติ")

local skillDropCard=Instance.new("Frame",pages["Skill"])
skillDropCard.Size=UDim2.new(1,0,0,52); skillDropCard.BackgroundColor3=DARK.item; skillDropCard.BorderSizePixel=0
Instance.new("UICorner",skillDropCard).CornerRadius=UDim.new(0,8)

local sTitle=Instance.new("TextLabel",skillDropCard)
sTitle.Size=UDim2.new(1,-170,0,18); sTitle.Position=UDim2.new(0,14,0,7)
sTitle.BackgroundTransparency=1; sTitle.Text="Select Skill Branches"
sTitle.TextColor3=DARK.text; sTitle.TextXAlignment=Enum.TextXAlignment.Left; sTitle.Font=FONT; sTitle.TextSize=12

local sSub=Instance.new("TextLabel",skillDropCard)
sSub.Size=UDim2.new(1,-170,0,14); sSub.Position=UDim2.new(0,14,0,28)
sSub.BackgroundTransparency=1; sSub.Text="เลือกสายสกิลที่ต้องการให้อัปเกรด (เลือกได้หลายสาย)"
sSub.TextColor3=DARK.subtext; sSub.TextXAlignment=Enum.TextXAlignment.Left; sSub.Font=FONT; sSub.TextSize=10

skillDropBtn=Instance.new("TextButton",skillDropCard)
skillDropBtn.Size=UDim2.new(0,145,0,28); skillDropBtn.Position=UDim2.new(1,-155,0.5,-14)
skillDropBtn.BackgroundColor3=Color3.fromRGB(32,24,48); skillDropBtn.BorderSizePixel=0
skillDropBtn.Text="Select Branches  ▾"; skillDropBtn.TextColor3=Color3.fromRGB(240,230,255)
skillDropBtn.Font=FONT; skillDropBtn.TextSize=11
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
setupSkillTab()

-- ── Tower tab ─────────────────────────────────────────────────────────────────
local function setupTowerTab()
local towerBanner=Instance.new("Frame",pages["Tower"])
towerBanner.Size=UDim2.new(1,0,0,52); towerBanner.BackgroundColor3=Color3.fromRGB(38,18,68); towerBanner.BorderSizePixel=0
Instance.new("UICorner",towerBanner).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",towerBanner).Color=DARK.purple
tBannerTitle=Instance.new("TextLabel",towerBanner)
tBannerTitle.Size=UDim2.new(1,-20,0,18); tBannerTitle.Position=UDim2.new(0,14,0,7)
tBannerTitle.BackgroundTransparency=1; tBannerTitle.TextColor3=Color3.new(1,1,1)
tBannerTitle.TextXAlignment=Enum.TextXAlignment.Left; tBannerTitle.Font=FONT; tBannerTitle.TextSize=12
tBannerTitle.Text="🏰 Tower Queue System"

tBannerSub=Instance.new("TextLabel",towerBanner)
tBannerSub.Size=UDim2.new(1,-20,0,14); tBannerSub.Position=UDim2.new(0,14,0,28)
tBannerSub.BackgroundTransparency=1; tBannerSub.TextColor3=Color3.fromRGB(190,155,255)
tBannerSub.TextXAlignment=Enum.TextXAlignment.Left; tBannerSub.Font=FONT; tBannerSub.TextSize=10
tBannerSub.Text="เลือกหอคอยที่ต้องการแล้วกดเริ่มลงได้ทันที"

local dropCard=Instance.new("Frame",pages["Tower"])
dropCard.Size=UDim2.new(1,0,0,52); dropCard.BackgroundColor3=DARK.item; dropCard.BorderSizePixel=0
Instance.new("UICorner",dropCard).CornerRadius=UDim.new(0,8)

local dTitle=Instance.new("TextLabel",dropCard)
dTitle.Size=UDim2.new(1,-170,0,18); dTitle.Position=UDim2.new(0,14,0,7)
dTitle.BackgroundTransparency=1; dTitle.Text="Select Towers"
dTitle.TextColor3=DARK.text; dTitle.TextXAlignment=Enum.TextXAlignment.Left; dTitle.Font=FONT; dTitle.TextSize=12

local dSub=Instance.new("TextLabel",dropCard)
dSub.Size=UDim2.new(1,-170,0,14); dSub.Position=UDim2.new(0,14,0,28)
dSub.BackgroundTransparency=1; dSub.Text="เลือกหอคอยที่ต้องการลง (เลือกได้หลายหอคอย)"
dSub.TextColor3=DARK.subtext; dSub.TextXAlignment=Enum.TextXAlignment.Left; dSub.Font=FONT; dSub.TextSize=10

dropBtn=Instance.new("TextButton",dropCard)
dropBtn.Size=UDim2.new(0,145,0,28); dropBtn.Position=UDim2.new(1,-155,0.5,-14)
dropBtn.BackgroundColor3=Color3.fromRGB(32,24,48); dropBtn.BorderSizePixel=0
dropBtn.Text="Select Towers  ▾"; dropBtn.TextColor3=Color3.fromRGB(240,230,255)
dropBtn.Font=FONT; dropBtn.TextSize=11
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
towerRunBtn.TextColor3=Color3.new(1,1,1); towerRunBtn.Font=FONT; towerRunBtn.TextSize=12
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
setupTowerTab()

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

makeCfgToggle(pages["Utility"],"SuperRAMSaver","AFK Super Saver (1+2+3)","กดทีเดียว: ปิด 3D จอขาว + ล้างขยะ RAM ทุก 60s + ปิดเสียง", function(v) toggleSuperRAMSaver(v) end)
makeCfgToggle(pages["Utility"],"HideGameUI","Hide Game UI (4)","ซ่อน UI เกมทั้งหมด (ยกเว้น Cheat Hub) ลดภาระ CPU/RAM", function(v) toggleHideGameUI(v) end)
makeCfgToggle(pages["Utility"],"Disable3DRender","Disable 3D Rendering","ปิดภาพ 3D (จอขาว) ประหยัด CPU & RAM เหมาะกับ AFK", function(v) toggle3DRendering(v) end)
makeCfgToggle(pages["Utility"],"BoostFPS","Boost FPS","ลดเอฟเฟกต์/กราฟิกและแสงเงา เพิ่มความลื่นไหลและ FPS", function(v) toggleBoostFPS(v) end)
makeCfgToggle(pages["Utility"],"AntiAFK","Anti AFK","ป้องกันการหลุดจากการอยู่เฉยๆ (กด F13 อัตโนมัติ)")
makeCfgToggle(pages["Utility"],"AutoQuest","Auto Claim Quests","รับของรางวัลเควสทั้งหมดอัตโนมัติ")

end
setupUtilityTab()

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
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Font = FONT; t.TextSize = 12
        if sub then
            local s = Instance.new("TextLabel", card)
            s.Size = UDim2.new(1,-170,0,14); s.Position = UDim2.new(0,14,0,28)
            s.BackgroundTransparency = 1; s.Text = sub; s.TextColor3 = DARK.subtext
            s.TextXAlignment = Enum.TextXAlignment.Left; s.Font = FONT; s.TextSize = 10
            return s
        end
    end

    local mh = addCard(52)
    local mhT = Instance.new("TextLabel", mh)
    mhT.Size = UDim2.new(1,-20,0,18); mhT.Position = UDim2.new(0,14,0,8); mhT.BackgroundTransparency = 1; mhT.Text = "Config System (Profile Manager)"; mhT.TextColor3 = DARK.text; mhT.TextXAlignment = Enum.TextXAlignment.Left; mhT.Font = FONT; mhT.TextSize = 12
    local mhS = Instance.new("TextLabel", mh)
    mhS.Size = UDim2.new(1,-20,0,14); mhS.Position = UDim2.new(0,14,0,28); mhS.BackgroundTransparency = 1; mhS.Text = "บันทึก โหลด ลบ และตั้งค่า Autoload การตั้งค่าทั้งหมด"; mhS.TextColor3 = DARK.subtext; mhS.TextXAlignment = Enum.TextXAlignment.Left; mhS.Font = FONT; mhS.TextSize = 10

    local nc = addCard(52)
    addCardText(nc, "Config Name", "พิมพ์ชื่อโปรไฟล์ที่ต้องการบันทึก")
    local cfgNameBox = Instance.new("TextBox", nc)
    cfgNameBox.Size = UDim2.new(0,145,0,28); cfgNameBox.Position = UDim2.new(1,-155,0.5,-14)
    cfgNameBox.BackgroundColor3 = Color3.fromRGB(32,24,48); cfgNameBox.BorderSizePixel = 0
    cfgNameBox.Text = "default"; cfgNameBox.TextColor3 = Color3.fromRGB(240,230,255)
    cfgNameBox.Font = FONT; cfgNameBox.TextSize = 11; cfgNameBox.ClearTextOnFocus = false
    Instance.new("UICorner", cfgNameBox).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", cfgNameBox).Color = DARK.purple

    local dc = addCard(52)
    addCardText(dc, "Select Profile", "เลือกไฟล์คอนฟิกจากรายการที่มี")
    cfgDropBtn = Instance.new("TextButton", dc)
    cfgDropBtn.Size = UDim2.new(0,145,0,28); cfgDropBtn.Position = UDim2.new(1,-155,0.5,-14)
    cfgDropBtn.BackgroundColor3 = Color3.fromRGB(32,24,48); cfgDropBtn.BorderSizePixel = 0
    cfgDropBtn.Text = "Select Config  ▾"; cfgDropBtn.TextColor3 = Color3.fromRGB(240,230,255)
    cfgDropBtn.Font = FONT; cfgDropBtn.TextSize = 11
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
    local btnFont = Enum.Font.SourceSans
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
    miscInfo.TextColor3 = DARK.subtext; miscInfo.TextXAlignment = Enum.TextXAlignment.Left
    miscInfo.TextYAlignment = Enum.TextYAlignment.Center; miscInfo.Font = FONT; miscInfo.TextSize = 11
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
setupMiscTab()

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

do
minimizedLogo=Instance.new("TextButton",gui)
minimizedLogo.Size=UDim2.new(0,50,0,50); minimizedLogo.Position=UDim2.new(0.5,-25,0.5,-25)
minimizedLogo.BackgroundColor3=DARK.bg; minimizedLogo.BackgroundTransparency=0.2
minimizedLogo.BorderSizePixel=0; minimizedLogo.Text=""; minimizedLogo.Visible=false
Instance.new("UICorner",minimizedLogo).CornerRadius=UDim.new(0,10)
local mls=Instance.new("UIStroke",minimizedLogo); mls.Color=DARK.accent; mls.Thickness=1.5; mls.Transparency=0.3
local mlI=Instance.new("ImageLabel",minimizedLogo)
mlI.Size=UDim2.new(0,36,0,36); mlI.Position=UDim2.new(0.5,-18,0.5,-18)
mlI.BackgroundTransparency=1; mlI.Image="rbxassetid://86571453491468"; mlI.ScaleType=Enum.ScaleType.Fit
minimizedLogo.MouseButton1Click:Connect(function() minimizedLogo.Visible=false; main.Visible=true end)

local wm=Instance.new("TextLabel",gui)
wm.Size=UDim2.new(0,320,0,30); wm.Position=UDim2.new(1,-340,1,-50)
wm.BackgroundTransparency=1; wm.Text="CHEAT HUB | discord.gg/540shop"
wm.TextColor3=DARK.accent; wm.TextXAlignment=Enum.TextXAlignment.Right
wm.Font=FONT; wm.TextSize=14; wm.TextTransparency=0.2
wm.TextStrokeTransparency=0.4; wm.TextStrokeColor3=Color3.new(0,0,0)
end

UIS.InputBegan:Connect(function(i,g)
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

print("[CHEAT HUB v24] พร้อมใช้งาน ✓")
pcall(function() showNotif("CHEAT HUB v24 พร้อมใช้งานแล้ว") end)

