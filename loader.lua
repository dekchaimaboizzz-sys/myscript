-- 540CHEATS v24 GUI | Cheat Hub (Loop Towers Mode Added)

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
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

local TowerScreen       = UIReferences.Root.Tower.Screen
local TowerBg           = TowerScreen.Parent.Background
local HiddenBtn         = TowerScreen.Parent.Hidden

pcall(function()
    HUDController.showAll("inTower")
    TowerScreen.Visible = false
    TowerBg.Visible = false
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

print("[HUB] Remotes OK")

local UPGRADE_PRICES = {}
local UPGRADE_PARENT = {}
for name, data in RealUpgrades do
    if name ~= "Start" and data.price then
        UPGRADE_PRICES[name] = data.price
        local parent = RealTreeStructure.GetParent(name)
        if parent then UPGRADE_PARENT[name] = parent end
    end
end

local ALL_TOWERS = {}
for name, data in RealTowers.GetAll() do
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
    for period,ids in QUEST_PERIODS do
        local qd; pcall(function() qd=DC.Quests[period]() end)
        if not qd then continue end
        for _,id in ids do
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
    for _,d in DICE_LIST do
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
    for upgName,price in UPGRADE_PRICES do
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

TowerScreen:GetPropertyChangedSignal("Visible"):Connect(function()
    if CFG.AutoTowerQueue and TowerScreen.Visible then
        TowerScreen.Visible = false
        pcall(function() HUDController.showAll("inTower") end)
    end
end)

TowerBg:GetPropertyChangedSignal("Visible"):Connect(function()
    if CFG.AutoTowerQueue and TowerBg.Visible then
        TowerBg.Visible = false
    end
end)

HiddenBtn:GetPropertyChangedSignal("Position"):Connect(function()
    if CFG.AutoTowerQueue and HiddenBtn.Position ~= UDim2.new(0, -9999, 0, -9999) then
        HiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
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

-- ── Background loops ──────────────────────────────────────────────────────────
task.spawn(function() while true do task.wait(COLLECT_LOOP)
    if CFG.AutoCollect then collectAll() end
end end)
task.spawn(function() while true do task.wait(EQUIP_LOOP)
    if CFG.AutoEquip then pcall(function() EquipBest:FireServer() end) end
end end)
task.spawn(function() while true do task.wait(ROLL_DELAY)
    if CFG.AutoRoll then pcall(function() RollDice:InvokeServer() end) end
end end)
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
task.spawn(function() while true do task.wait(60)
    if CFG.AntiAFK then
        pcall(function()
            VIM:SendKeyEvent(true,Enum.KeyCode.F13,false,game)
            task.wait(0.05)
            VIM:SendKeyEvent(false,Enum.KeyCode.F13,false,game)
        end)
    end
end end)

-- ============================================================
-- ===== UI =====
-- ============================================================
local gui,main,minimizedLogo,notif

gui=Instance.new("ScreenGui")
gui.Name="540CHEATS_v24"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=LP:WaitForChild("PlayerGui")

main=Instance.new("Frame")
main.Size=UDim2.new(0,640,0,500); main.Position=UDim2.new(0.5,-320,0.5,-250)
main.BackgroundColor3=DARK.bg; main.BorderSizePixel=0; main.Active=true; main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
Instance.new("UIStroke",main).Color=DARK.border

local HH=54
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
    for k in CFG do CFG[k]=false end
    stopTowerQueue()
    pcall(function() gui:Destroy() end) end)

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
createTab("Tower","🏰"); createTab("Utility","⚙️"); createTab("Settings","🛠️")
tabs["Main"].BackgroundTransparency=0; tabs["Main"].BackgroundColor3=DARK.item
pages["Main"].Visible=true
tabs["Main"]:FindFirstChild("TextLabel").TextColor3=Color3.new(1,1,1)

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
        s=Instance.new("TextLabel",c)
        s.Size=UDim2.new(1,-170,0,14); s.Position=UDim2.new(0,14,0,28)
        s.BackgroundTransparency=1; s.Text=sublabel; s.TextColor3=DARK.subtext
        s.TextXAlignment=Enum.TextXAlignment.Left; s.Font=FONT; s.TextSize=10
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
    return c
end

-- ── Main tab ─────────────────────────────────────────────────────────────────
makeToggle(pages["Main"],"Auto Collect","เก็บเงินอัตโนมัติจากทุก Plot (15 ช่อง)", CFG.AutoCollect, function(v) CFG.AutoCollect=v end)
makeButton(pages["Main"],"Collect Cash Now","กดเพื่อเก็บเงินจากทุกช่องทันที 1 ครั้ง","Collect",function()
    collectAll()
end)
makeToggle(pages["Main"],"Auto Upgrade Plot Lvl","อัปเกรดเลเวลยูนิตใน Plot อัตโนมัติ", CFG.AutoUpgradePlot, function(v) CFG.AutoUpgradePlot=v end)
makeInput(pages["Main"],"Target Plot Level","ตั้งเป้าหมายเลเวลที่ต้องการอัปเกรด (เช่น 50)", CFG.PlotTargetLvl, function(val) CFG.PlotTargetLvl=val end)
makeSelector(pages["Main"],"Upgrade Mode","อัปเกรดเฉลี่ยทุกตัวใน Plot ให้เลเวลเท่าๆ กัน",{
    { text = "Equal (Balanced)",  value = "Equal",  sub = "อัปเกรดเฉลี่ยทุกตัวใน Plot ให้เลเวลเท่าๆ กัน" },
    { text = "Focus (One by One)", value = "Single", sub = "อัปเกรดทีละตัวใน Plot ให้ถึงเป้าหมายก่อน" },
}, 1, function(val) CFG.PlotUpgradeMode=val end)
makeToggle(pages["Main"],"Auto Equip Best","เลือกสวมใส่ยูนิตที่ทำรายได้สูงสุดอัตโนมัติ", CFG.AutoEquip, function(v) CFG.AutoEquip=v end)

-- ── Roll tab ──────────────────────────────────────────────────────────────────
makeToggle(pages["Roll"],"Auto Roll","ทอยลูกเต๋าอัตโนมัติทุก 2.6 วินาที", CFG.AutoRoll, function(v) CFG.AutoRoll=v end)
makeToggle(pages["Roll"],"Auto Buy Best Dice","ซื้อลูกเต๋าที่มีค่าโชคสูงสุดอัตโนมัติ", CFG.AutoBuyDice, function(v) CFG.AutoBuyDice=v end)
makeToggle(pages["Roll"],"Auto Equip Best Dice","สวมใส่ลูกเต๋าที่ดีที่สุดอัตโนมัติ", CFG.AutoEquipDice, function(v) CFG.AutoEquipDice=v end)
makeToggle(pages["Roll"],"Auto Rebirth","รีเบิร์ธอัตโนมัติเมื่อเงินถึงเกณฑ์ที่กำหนด", CFG.AutoRebirth, function(v) CFG.AutoRebirth=v end)

-- ── Skill tab ─────────────────────────────────────────────────────────────────
makeToggle(pages["Skill"],"Auto Upgrade Skills","อัปเกรด Skill Tree ตามสายที่เลือกอัตโนมัติ", CFG.AutoUpgrade, function(v) CFG.AutoUpgrade=v end)

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

local skillDropBtn=Instance.new("TextButton",skillDropCard)
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

local skillDropMenu=Instance.new("ScrollingFrame",main)
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

local function updateSkillDropBtnText()
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
    refreshOpt()
end
updateSkillDropBtnText()

-- ── Tower tab ─────────────────────────────────────────────────────────────────
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

local dropBtn=Instance.new("TextButton",dropCard)
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

local dropMenu=Instance.new("ScrollingFrame",main)
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

local function updateDropBtnText()
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
end

main.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        local mPos=UIS:GetMouseLocation()
        if dropMenu and dropMenu.Visible then
            local dPos=dropMenu.AbsolutePosition
            local dSize=dropMenu.AbsoluteSize
            local bPos=dropBtn.AbsolutePosition
            local bSize=dropBtn.AbsoluteSize
            local inMenu = (mPos.X>=dPos.X and mPos.X<=dPos.X+dSize.X and mPos.Y>=dPos.Y and mPos.Y<=dPos.Y+dSize.Y)
            local inBtn  = (mPos.X>=bPos.X and mPos.X<=bPos.X+bSize.X and mPos.Y>=bPos.Y and mPos.Y<=bPos.Y+bSize.Y)
            if not inMenu and not inBtn then
                dropMenu.Visible=false
            end
        end
        if skillDropMenu and skillDropMenu.Visible then
            local dPos=skillDropMenu.AbsolutePosition
            local dSize=skillDropMenu.AbsoluteSize
            local bPos=skillDropBtn.AbsolutePosition
            local bSize=skillDropBtn.AbsoluteSize
            local inMenu = (mPos.X>=dPos.X and mPos.X<=dPos.X+dSize.X and mPos.Y>=dPos.Y and mPos.Y<=dPos.Y+dSize.Y)
            local inBtn  = (mPos.X>=bPos.X and mPos.X<=bPos.X+bSize.X and mPos.Y>=bPos.Y and mPos.Y<=bPos.Y+bSize.Y)
            if not inMenu and not inBtn then
                skillDropMenu.Visible=false
            end
        end
    end
end)

makeToggle(pages["Tower"],"Loop Towers","วนลงหอคอยที่เลือกซ้ำเรื่อยๆ แบบอัตโนมัติ",
    CFG.LoopTower, function(v)
        CFG.LoopTower=v
        updateRunBtnText()
    end)

makeToggle(pages["Tower"],"Equip Best Team First","สวมใส่ทีมที่ดีที่สุดก่อนเข้าหอคอยทุกรอบ",
    CFG.EquipTeamBefore, function(v) CFG.EquipTeamBefore=v end)

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

-- ── Utility tab ───────────────────────────────────────────────────────────────
makeToggle(pages["Utility"],"Anti AFK","ป้องกันการหลุดจากการอยู่เฉยๆ (กด F13 อัตโนมัติ)", CFG.AntiAFK, function(v) CFG.AntiAFK=v end)
makeToggle(pages["Utility"],"Auto Claim Quests","รับของรางวัลเควสทั้งหมดอัตโนมัติ", CFG.AutoQuest, function(v) CFG.AutoQuest=v end)

-- ── Settings tab ──────────────────────────────────────────────────────────────
local info=Instance.new("TextLabel",pages["Settings"])
info.Size=UDim2.new(1,0,0,380); info.BackgroundColor3=DARK.item; info.BorderSizePixel=0
info.Text="  CHEAT HUB v24\n\n" ..
    "  Main\n" ..
    "  Auto Collect        — 15 slots\n" ..
    "  Collect Cash Now    — instant 1-time collect\n" ..
    "  Auto Equip Best     — highest income unit\n" ..
    "  Auto Upgrade Skills — no notification spam\n\n" ..
    "  Roll\n" ..
    "  Auto Roll           — 2.6s per roll\n" ..
    "  Auto Rebirth        — on threshold\n\n" ..
    "  Tower\n" ..
    "  Dropdown Menu       — clean multi-selection popup\n" ..
    "  Loop Mode           — repeat selected towers endlessly\n" ..
    "  Queue Runner        — 1 run each, from easiest to hardest\n" ..
    "  Menu-Safe Monitor   — unaffected by Daily/popup menus\n\n" ..
    "  Utility\n" ..
    "  Anti AFK            — F13 every 60s\n" ..
    "  Auto Quest          — Daily & Weekly\n\n" ..
    "  Hotkeys\n" ..
    "  E=Collect  Q=Roll  X=UI  F1=Show"
info.TextColor3=DARK.text; info.TextXAlignment=Enum.TextXAlignment.Left
info.TextYAlignment=Enum.TextYAlignment.Top; info.Font=FONT; info.TextSize=12
Instance.new("UICorner",info).CornerRadius=UDim.new(0,8)

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
