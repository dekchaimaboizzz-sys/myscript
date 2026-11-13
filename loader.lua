--!nocheck
if _G.SerennityHubCleanup then
	pcall(_G.SerennityHubCleanup)
	_G.SerennityHubCleanup = nil
end
--[[
	================================================================================
	SERENNITY HUB — OFFICIAL STANDALONE UI TEMPLATE (ALL-BLUE EDITION • 100% EXACT)
	================================================================================
	• Extracted 1:1 from Serennity Hub Production Scripts (Hunting Together & Fishing Master)
	• 100% Identical Fonts (Ubuntu Bold/Medium + LumiKeepFont Metatable Guard)
	• 100% Identical S-Logo Loader (96x96 EditableImage + PNG getcustomasset + SVG Fallback)
	• 100% Identical Window Layout (880x556 + Responsive Mobile UIScale + 240px Sidebar)
	• 100% Identical Controls (Toggle, Slider, SingleDropdown, MultiDropdown, TextBox, Keybind, Button, ButtonRow, InfoParagraph)
	• Built-in Settings Tab (Config Save/Load/Delete, Auto Load, Auto Execute, Rejoin, Anti-AFK, Boost FPS, Keybind)
	• Built-in Private Owner Cloud Telemetry (Serennity Hub Dashboard)
	================================================================================
]]
local Instance = (function()
	local rawInst = Instance
	local rawNew = rawInst.new
	return setmetatable({
		new = function(className: string, parent: Instance?)
			local obj = rawNew(className)
			pcall(function()
				if obj:IsA("ScreenGui") then
					obj.AutoLocalize = false
				elseif obj:IsA("GuiObject") then
					obj.AutoLocalize = false
					obj:SetAttribute("LumiNoTranslate", true)
					obj:SetAttribute("LumiNoPixelFont", true)
					obj:SetAttribute("LumiKeepFont", true)
					obj:SetAttribute("LumiKeepText", true)
					obj:SetAttribute("LumiKeepColor", true)
					obj:SetAttribute("LumiKeepLight", true)
					obj:SetAttribute("LumiKeepRound", true)
					obj:SetAttribute("LumiNoLine", true)
					obj:SetAttribute("LumiSkipIcon", true)
				end
			end)
			if parent ~= nil then
				obj.Parent = parent
			end
			return obj
		end,
	}, { __index = rawInst })
end)()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = nil
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)


--====================================================================--
-- CLEANUP PREVIOUS INSTANCE (Hot-Reload Safe)
--====================================================================--
if _G.SerennityHubCleanup then
	pcall(_G.SerennityHubCleanup)
end
if _G.SerennityHuntingCleanup then
	pcall(_G.SerennityHuntingCleanup)
end
pcall(function()
	for _, ch in ipairs(PlayerGui:GetChildren()) do
		if ch:IsA("ScreenGui") and ch.Name == "SerennityHubGui" then
			ch:Destroy()
		end
	end
end)

local Connections: { RBXScriptConnection } = {}
local ScriptAlive = true
local RtState: { [string]: any } = {}

-- Live Session Stats Tracker
RtState.SessionStats = {
	StartTime = os.time(),
	TotalRolls = 0,
	TotalItemsAcquired = 0,
	InitialMoney = nil,
	InitialCandy = nil,
	InitialPumpkins = nil,
	InitialGems = nil,
	RecentRarePulls = {},
	AcquiredItemsFeed = {},
}
local notify: (string, string, number?) -> ()

local AllTogglesRegistry: { [string]: any } = {}
local TotState: any = nil

local function formatNumber(n: number?): string
	if not n or type(n) ~= "number" then return "0" end
	local formatted = tostring(math.floor(n))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

local function formatMoneyShort(n: number?): string
	if not n or type(n) ~= "number" then return "$0" end
	if n < 1000 then return "$" .. tostring(math.floor(n)) end
	local suffixes = { "", "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
	local idx = 1
	local val = n
	while val >= 1000 and idx < #suffixes do
		val = val / 1000
		idx = idx + 1
	end
	return string.format("$%.2f%s", val, suffixes[idx])
end

local function unwrap(v: any): any
	if v == nil then return nil end
	if type(v) == "function" or type(v) == "table" or typeof(v) == "userdata" then
		local ok, res = pcall(v)
		if ok and res ~= nil then
			if type(res) == "function" or (type(res) == "table" and getmetatable(res)) or typeof(res) == "userdata" then
				local ok2, res2 = pcall(res)
				if ok2 and res2 ~= nil then return res2 end
			end
			return res
		end
	end
	return v
end

local function fireCommSignal(serviceName: string, signalName: string, ...)
	local args = { ... }
	local fired = false
	pcall(function()
		local pkgs = ReplicatedStorage:FindFirstChild("Packages")
		if pkgs and pkgs:FindFirstChild("Network") then
			local netMod = require(pkgs.Network)
			if netMod and netMod.ClientComm then
				local comm = netMod.ClientComm.new(ReplicatedStorage.Network, false, serviceName)
				local sig = comm:GetSignal(signalName)
				if sig and sig.Fire then
					sig:Fire(table.unpack(args))
					fired = true
				end
			end
		end
	end)
	if not fired then
		pcall(function()
			local net = ReplicatedStorage:FindFirstChild("Network")
			if net then
				local svc = net:FindFirstChild(serviceName)
				if svc then
					local re = svc:FindFirstChild("RE")
					if re then
						local sig = re:FindFirstChild(signalName)
						if sig and sig:IsA("RemoteEvent") then
							sig:FireServer(table.unpack(args))
							fired = true
						end
					end
				end
			end
	end)
	end
	return fired
end

local function getPlayerCandy(): number
	local candy = 0
	pcall(function()
		local EntryController = require(ReplicatedStorage.Framework.Features.Inventory.EntryController)
		if EntryController and EntryController.GetAmount then
			candy = EntryController.GetAmount("Candy") or 0
		end
	end)
	return candy
end

local function getPlayerPumpkins(): number
	local pumpkins = 0
	pcall(function()
		local EntryController = require(ReplicatedStorage.Framework.Features.Inventory.EntryController)
		if EntryController and EntryController.GetAmount then
			pumpkins = EntryController.GetAmount("Pumpkins") or EntryController.GetAmount("Pumpkin") or 0
		end
	end)
	if pumpkins == 0 then
		pcall(function()
			local Framework = ReplicatedStorage:FindFirstChild("Framework")
			local Features = Framework and Framework:FindFirstChild("Features")
			local DataPkg = Features and Features:FindFirstChild("Data")
			local DC = (DataPkg and DataPkg:FindFirstChild("DataController") and require(DataPkg.DataController)) or nil
			if DC and DC.Inventory then
				local rawInv = (type(DC.Inventory) == "function" and DC.Inventory()) or DC.Inventory
				if rawInv and rawInv["Pumpkins"] then
					local it = (type(rawInv["Pumpkins"]) == "function" and rawInv["Pumpkins"]()) or rawInv["Pumpkins"]
					if it and it.amount then pumpkins = it.amount end
				elseif rawInv and rawInv["Pumpkin"] then
					local it = (type(rawInv["Pumpkin"]) == "function" and rawInv["Pumpkin"]()) or rawInv["Pumpkin"]
					if it and it.amount then pumpkins = it.amount end
				end
			end
		end)
	end
	return pumpkins
end

-- Global Helper: Check if player is currently in an active Tower session
local function isPlayerInTower(): (boolean, number)
	local inRun = false
	local curFloor = 1
	pcall(function()
		local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local rootGui = pg and pg:FindFirstChild("Root")
		local towerGui = rootGui and rootGui:FindFirstChild("Tower")
		if towerGui then
			local hiddenBtn = towerGui:FindFirstChild("Hidden")
			local screen = towerGui:FindFirstChild("Screen")
			local isScreenVisible = (screen and screen.Visible == true)
			local isHiddenActive = (hiddenBtn and hiddenBtn.Visible == true and hiddenBtn:FindFirstChild("Label") and tostring(hiddenBtn.Label.Text):find("Floor") ~= nil)

			if isScreenVisible or isHiddenActive then
				inRun = true
				if isHiddenActive and hiddenBtn:FindFirstChild("Label") then
					local num = tostring(hiddenBtn.Label.Text):match("(%d+)")
					if num then curFloor = tonumber(num) or curFloor end
				elseif screen and screen:FindFirstChild("Floor") then
					local num = tostring(screen.Floor.Text):match("(%d+)")
					if num then curFloor = tonumber(num) or curFloor end
				end
			end
		end
	end)
	return inRun, curFloor
end

local function getTowerActiveState(): boolean
	local inRun, _ = isPlayerInTower()
	if inRun then return true end

	local guv = getupvalue or (debug and debug.getupvalue)
	local guvs = getupvalues or (debug and debug.getupvalues)
	local TowerCtrl = nil
	pcall(function()
		local fw = ReplicatedStorage:FindFirstChild("Framework")
		local feat = fw and fw:FindFirstChild("Features")
		local tw = feat and feat:FindFirstChild("Towers")
		if tw and tw:FindFirstChild("TowerController") then
			TowerCtrl = require(tw.TowerController)
		end
	end)

	if guv and TowerCtrl and TowerCtrl.startTower then
		local ok, val = pcall(guv, TowerCtrl.startTower, 1)
		if ok and type(val) == "boolean" then
			return val
		end
	end

	if guvs and TowerCtrl and TowerCtrl.startTower then
		local ok, uvs = pcall(guvs, TowerCtrl.startTower)
		if ok and type(uvs) == "table" then
			if type(uvs[1]) == "boolean" then
				return uvs[1]
			elseif type(uvs["u8"]) == "boolean" then
				return uvs["u8"]
			end
		end
	end

	return inRun
end


--====================================================================--
-- MAP & VERSION CONFIGURATION (แก้ชื่อแมพและค่า DefaultConfig ตรงนี้)
--====================================================================--
local CurrentMapName = "Net a Fish!" -- <-- Anime Dice Map
local SCRIPT_VERSION = "v1.0"          -- <-- เวอร์ชันของสคริปต์ (อัปเป็น v1.1, v1.2, ... ทุกครั้งที่อัปเดต)
local DISCORD_INVITE = "https://discord.gg/3K6BSxhAkn"
local CurrentStatusText = "Idle (All Toggles OFF)"

-- กฎเหล็ก: ปุ่ม Toggle ทุกอันต้องเริ่มต้นเป็น false (OFF) เสมอ ห้ามเปิดเองตอนรันสคริปต์!
local DefaultConfig: { [string]: any } = {
	-- Auto Farm & Economy
	AutoCollectMoney = false,
	CollectInterval = 1,
	AutoEquipBest = false,
	EquipInterval = 1,

	-- Level Up System
	AutoLevelUp = false,
	LevelUpPlots = {},
	TargetLevel = 2,

	-- Roll & Dice
	AutoRoll = false,
	FastRoll = false,
	RollInterval = 0.15,
	AutoBuyBestDice = false,
	AutoEquipBestDice = false,

	-- Unit Evolution: Traits & Grades
	SelectedTraitGradeUnit = "Empty (Plot 1)",
	SelectedTraitUnit = "Empty (Plot 1)",
	SelectedGradeUnit = "Empty (Plot 1)",
	SelectedQuirkUnit = "Empty (Plot 1)",
	AutoRerollTrait = false,
	TargetTrait = "Genesis (120.0x All)",
	AutoUpgradeGrade = false,
	TargetGrade = "Grade Ω (250.0x)",
	AutoTeleportToStation = false,
	HideStationUI = false,

	-- Unit Evolution: Quirks
	AutoRerollQuirk = false,
	TargetQuirk = "Sovereign",
	AutoProtectSecretQuirks = false,

	-- Unit Evolution: Aura Fusing
	AutoFuseUnits = false,
	FuseMinChance = "1",
	FuseMaxChance = "100M",
	FuseSkipLocked = true,
	ExcludeFusedOutputs = true,

	-- Inventory & Sell: Smart Auto Sell
	AutoSellTrash = false,
	SellBelowChance = "100k",
	NeverSellLocked = true,

	-- Inventory & Sell: Gear & Auto Boosts
	AutoEquipBestGear = false,
	AutoUseLuckBoosts = false,
	AutoUseIncomeBoosts = false,
	AutoUseDamageBoosts = false,
	AutoUseShadowSpeedBoosts = false,
	PotionBatchAmount = "1",

	-- Awakening & Potions: Topic 1 - Unit Awakening
	AutoAwakenUnits = false,
	AutoAwakenAllPlotUnits = false,
	SelectedAwakenUnit = "Best Owned Unit",
	TargetAwakenStars = "5 Stars (Max - 10x Income / 5x Combat)",
	AutoTeleportToAwakenStation = false,
	HideAwakeningUI = false,

	-- Awakening & Potions: Topic 2 - Potion Fusing
	AutoFusePotions = false,
	TargetPotionTypes = {}, -- legacy
	PotionCategory = "All Categories",
	SelectedPotionType = "All Potions",
	MaxPotionTier = "Tier IV (Max)",
	AutoTeleportToPotionStation = false,
	HidePotionFusingUI = false,

	-- Battle Towers: Game Main Towers
	SelectedTower = "None",
	SelectedTowers = {},
	AutoPlayTower = false,
	AutoTowerQueue = false,
	LoopTower = false,
	HideTowerBattleUI = false,
	HideGameUI = false,
	AutoClearTowerFloor = false,
	TargetTowerFloor = 100,
	AutoExitOnTargetFloor = false,

	-- Autumn Event Automation
	AutoCollectApples = false,
	AutoUpgradeAppleOrchard = false,
	SelectedAppleBoardUpgrades = {
		["Juicy Apples"] = true,
		["Faster Growth"] = true,
		["Bigger Harvest"] = true,
		["Lucky Apples"] = true,
		["Long Reach"] = true,
		["Double Pick"] = true,
		["Apple Combo"] = true,
		["Leaf Picker"] = true,
		["Apple Shower"] = true,
		["Rare Shine"] = true,
		["Mega Apples"] = true,
		["Apple Frenzy"] = true,
		["Orchard Mastery"] = true,
	},
	AutoUpgradeAppleTree = false,
	AutoRollLeafDice = false,
	AutoSellLeafDiceUnits = false,
	AutoClaimAutumnQuests = false,
	AutoClaimAutumnBonus = false,
	AutoBuyAppleShop = false,
	SelectedAppleShopItems = {},

	-- Autumn Event Battle Towers (100% Dedicated Event System)
	SelectedEventTower = "None",
	SelectedEventTowers = {},
	AutoPlayEventTower = false,
	AutoEventTowerQueue = false,
	LoopEventTower = false,
	HideEventTowerBattleUI = false,
	AutoClearEventTowerFloor = false,
	TargetEventTowerFloor = 100,
	AutoExitOnEventTargetFloor = false,

	-- Progression & Meta: Rebirth & Skill Tree
	AutoRebirth = false,
	TargetRebirth = 19,
	AutoAssignRebirthStats = false,
	SelectedRebirthStat = "Luck",
	AutoUnlockTreeUpgrades = false,
	TreeUpgradeMode = "All Branches",
	TreeSelectedBranches = {},

	-- Progression & Meta: Quests & Free Rewards
	AutoClaimDailyRewards = false,
	AutoClaimGroupRewards = false,
	AutoClaimOfflineEarnings = false,
	AutoClaimQuests = false,
	AutoRedeemCodes = false,
	AutoClaimHalloweenQuests = false,
	AutoUseHalloweenPotions = false,
	AutoUseTowerPotions = false,
	Disable3DRendering = false,

	-- Unit Protection & Auto Lock
	AutoLockHighRarities = false,
	AutoLockGodTraits = false,
	AutoLockSecretQuirks = false,

	-- AFK Dashboard Mode
	EnableAfkDashboard = false,

	-- Server & Reconnect
	AutoReconnectOnKick = false,

	-- Weather & Smart Rolling
	RollOnlyDuringEvents = false,
	AllowedWeatherEvents = {},

	-- Auto Spins & Exchange
	AutoUseDailyJackpots = false,
	AutoUseLuckySpins = false,
	AutoUseJackpotSpins = false,
	AutoUseMegaJackpots = false,
	AutoUseHalloweenSpins = false,

	-- Player Utilities & Movement
	EnableCustomWalkSpeed = false,
	CustomWalkSpeed = 16,
	EnableCustomJumpPower = false,
	CustomJumpPower = 50,
	InfiniteJump = false,

	-- Discord Webhook Notifications
	WebhookUrl = "",
	WebhookNotifyRarity = false,
	WebhookNotifyGodTraits = false,
	WebhookNotifyRebirth = false,
	WebhookNotifyTowerFloor = false,

	-- System Settings
	AntiAFK = true,
	Rejoin = false,
	BoostFPS = false,
	MenuKeybind = "RightControl",
}

local Cfg: { [string]: any } = {}
for k, v in pairs(DefaultConfig) do
	if type(v) == "table" then
		Cfg[k] = table.clone(v)
	else
		Cfg[k] = v
	end
end

-- ฟังก์ชันเช็คว่าผู้เล่นมีสถานะพิเศษในแมพหรือไม่ (แก้เงื่อนไขตามแมพนั้นๆ ได้)
RtState.IsAccountPremium = function(): boolean
	return LocalPlayer:GetAttribute("Premium") == true
		or LocalPlayer:GetAttribute("VIP") == true
		or false
end

-- ฟังก์ชันหยุดการทำงานทั้งหมดทันทีเมื่อผู้ใช้กดปิด Toggle (0.00s Instant Stop)
local function stopAllActiveMovementAndCombat()
	pcall(function()
						local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local existingBv = hrp:FindFirstChild("TotAntiGrav")
					if existingBv then existingBv:Destroy() end
				end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:Move(Vector3.zero, false)
		end
	end)
end

local IsMobileDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local ClientDeviceType = IsMobileDevice and "Mobile" or "PC"

local Theme = {
	WindowBg = Color3.fromRGB(13, 18, 28),
	SidebarBg = Color3.fromRGB(11, 16, 25),       -- #0B1019 Dark navy background
	CardBg = Color3.fromRGB(18, 25, 38),
	ControlBg = Color3.fromRGB(12, 17, 26),
	ActiveTabBg = Color3.fromRGB(26, 41, 66),     -- #1A2942 Active item background
	HoverTabBg = Color3.fromRGB(19, 30, 48),
	BadgeBg = Color3.fromRGB(24, 40, 66),
	Stroke = Color3.fromRGB(32, 46, 70),
	ActiveStroke = Color3.fromRGB(58, 98, 160),
	AccentBlue = Color3.fromRGB(101, 191, 255),   -- #65BFFF Subtle blue accent
	AccentDeep = Color3.fromRGB(52, 126, 232),
	SliderThumb = Color3.fromRGB(122, 188, 255),
	ToggleOffBg = Color3.fromRGB(32, 43, 60),
	ToggleOffKnob = Color3.fromRGB(120, 138, 164),
	ToggleOnKnob = Color3.fromRGB(12, 20, 34),
	TextPrimary = Color3.fromRGB(240, 245, 255),  -- #F0F5FF Active icon and text
	TextSecondary = Color3.fromRGB(214, 228, 248),
	SidebarText = Color3.fromRGB(168, 184, 208),  -- #A8B8D0 Sidebar text
	TextMuted = Color3.fromRGB(127, 147, 174),    -- #7F93AE Inactive icons
	OnlineGreen = Color3.fromRGB(67, 181, 129),
}

local FontBold = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold)
local FontSemiBold = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.SemiBold)
local FontMedium = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Medium)

--====================================================================--
-- CUSTOM SVG VECTOR ICON ENGINE (18x18 • 1.8px Stroke • Round Caps/Joins)
-- Pure Editable SVG Vector Paths • Zero Emojis • Zero Unicode Symbols
--====================================================================--

local CustomSvgDefinitions: { [string]: string } = {
	-- 1. Main: Minimal four-panel dashboard symbol
	main = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<rect x="3.0" y="3.0" width="7.2" height="7.2" rx="2.0" />
	<rect x="13.8" y="3.0" width="7.2" height="7.2" rx="2.0" />
	<rect x="3.0" y="13.8" width="7.2" height="7.2" rx="2.0" />
	<rect x="13.8" y="13.8" width="7.2" height="7.2" rx="2.0" />
</svg>]],

	-- 2. Rod & Skills: Recognizable fishing rod with curved fishing line and small hook
	rod_skills = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 3.5 20.5 L 16.5 3.5" />
	<path d="M 5.5 15.2 L 8.8 18.5" />
	<circle cx="9.5" cy="16.2" r="2.0" />
	<path d="M 16.5 3.5 C 19.6 6.2 19.8 10.4 18.5 14.5" />
	<path d="M 18.5 14.5 L 18.5 17.0 C 18.5 19.4 14.6 19.4 14.6 17.0 L 16.2 17.9" />
</svg>]],

	-- 3. Quests: Custom compass / target quest marker icon
	quests = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<circle cx="12.0" cy="12.0" r="8.5" />
	<path d="M 12.0 2.2 L 12.0 4.4 M 12.0 19.6 L 12.0 21.8 M 2.2 12.0 L 4.4 12.0 M 19.6 12.0 L 21.8 12.0" />
	<path d="M 15.6 8.4 L 13.4 13.4 L 8.4 15.6 L 10.6 10.6 Z" />
</svg>]],

	-- 4. Gacha & Roll: Custom faceted gem / crystal icon
	gacha = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 7.4 4.0 L 16.6 4.0 L 21.0 9.6 L 12.0 20.4 L 3.0 9.6 Z" />
	<path d="M 3.0 9.6 L 21.0 9.6" />
	<path d="M 7.4 4.0 L 9.2 9.6 L 12.0 20.4 L 14.8 9.6 L 16.6 4.0" />
</svg>]],

	-- 5. Settings: Minimal six-tooth gear icon with a clean circular center
	settings = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<circle cx="12.0" cy="12.0" r="3.2" />
	<path d="M 10.1 5.5 L 10.2 2.8 L 13.8 2.8 L 13.9 5.5 L 16.7 7.1 L 19.1 5.8 L 20.9 8.9 L 18.6 10.4 L 18.6 13.6 L 20.9 15.1 L 19.1 18.2 L 16.7 16.9 L 13.9 18.5 L 13.8 21.2 L 10.2 21.2 L 10.1 18.5 L 7.3 16.9 L 4.9 18.2 L 3.1 15.1 L 5.4 13.6 L 5.4 10.4 L 3.1 8.9 L 4.9 5.8 L 7.3 7.1 Z" />
</svg>]],

	-- Additional UI Vector Icons
	search = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<circle cx="10.5" cy="10.5" r="6.2" />
	<path d="M 15.1 15.1 L 20.2 20.2" />
</svg>]],

	collapse = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 14.5 4.0 L 20.0 4.0 L 20.0 9.5 M 20.0 4.0 L 13.8 10.2 M 9.5 20.0 L 4.0 20.0 L 4.0 14.5 M 4.0 20.0 L 10.2 13.8" />
</svg>]],

	chevron_right = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 9.0 6.0 L 15.0 12.0 L 9.0 18.0" />
</svg>]],

	check = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 5.0 12.5 L 9.6 17.0 L 19.0 7.5" />
</svg>]],

	auto_fish = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<circle cx="12.0" cy="4.8" r="2.0" />
	<path d="M 12.0 6.8 L 12.0 15.2 C 12.0 20.0 18.2 20.0 18.2 14.8 L 18.2 12.4 L 15.8 14.6 M 4.5 14.2 L 8.5 14.2 M 3.5 18.0 L 7.8 18.0" />
</svg>]],

	sell_lock = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<rect x="5.0" y="10.5" width="14.0" height="10.0" rx="2.5" />
	<path d="M 8.2 10.5 L 8.2 7.4 C 8.2 4.6 15.8 4.6 15.8 7.4 L 15.8 10.5 M 12.0 14.2 L 12.0 17.0" />
</svg>]],

	skill_book = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<rect x="4.5" y="3.5" width="15.0" height="17.0" rx="2.2" />
	<path d="M 8.2 3.5 L 8.2 20.5 M 11.5 8.5 L 16.2 8.5 M 11.5 12.5 L 15.2 12.5" />
</svg>]],

	rod_quest = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 12.0 3.0 L 19.2 6.0 L 19.2 12.2 C 19.2 16.6 15.9 19.6 12.0 21.2 C 8.1 19.6 4.8 16.6 4.8 12.2 L 4.8 6.0 Z" />
	<path d="M 8.8 15.2 L 15.2 8.8 M 12.2 8.8 L 15.2 8.8 L 15.2 11.8" />
</svg>]],

	daily_star = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 12.0 3.2 L 14.6 8.6 L 20.5 9.5 L 16.2 13.7 L 17.2 19.6 L 12.0 16.8 L 6.8 19.6 L 7.8 13.7 L 3.5 9.5 L 9.4 8.6 Z" />
</svg>]],

	unit_crest = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 12.0 3.0 L 19.8 7.5 L 19.8 16.5 L 12.0 21.0 L 4.2 16.5 L 4.2 7.5 Z" />
	<path d="M 12.0 8.2 L 15.8 12.0 L 12.0 15.8 L 8.2 12.0 Z" />
</svg>]],

	ocean_chest = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<rect x="3.5" y="8.5" width="17.0" height="11.5" rx="2.2" />
	<path d="M 3.5 12.8 L 20.5 12.8 M 6.5 8.5 C 6.5 5.2 17.5 5.2 17.5 8.5 M 12.0 11.2 L 12.0 14.8" />
</svg>]],

	aura_sparkle = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 11.5 3.5 L 13.8 9.8 L 20.0 12.0 L 13.8 14.2 L 11.5 20.5 L 9.2 14.2 L 3.0 12.0 L 9.2 9.8 Z" />
	<path d="M 18.5 3.5 L 18.5 7.5 M 16.5 5.5 L 20.5 5.5" />
</svg>]],

	dragon_crest = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 12.0 4.0 L 16.5 8.5 L 21.0 6.2 L 18.6 14.6 L 12.0 20.2 L 5.4 14.6 L 3.0 6.2 L 7.5 8.5 Z" />
	<path d="M 12.0 9.2 L 14.6 13.0 L 12.0 16.4 L 9.4 13.0 Z" />
</svg>]],

	raid_swords = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 14.5 17.5 L 3.0 6.0 L 3.0 3.0 L 6.0 3.0 L 17.5 14.5 M 13.0 19.0 L 19.0 13.0 M 16.0 16.0 L 20.0 20.0 M 19.0 21.0 L 21.0 19.0" />
	<path d="M 14.5 6.5 L 18.0 3.0 L 21.0 3.0 L 21.0 6.0 L 17.5 9.5 M 5.0 13.0 L 11.0 19.0 M 8.0 16.0 L 4.0 20.0 M 3.0 19.0 L 5.0 21.0" />
</svg>]],

	reroll_bolt = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 13.2 3.0 L 5.5 13.2 L 11.5 13.2 L 10.2 21.0 L 18.5 10.6 L 12.5 10.6 Z" />
</svg>]],

	keybind = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<rect x="3.0" y="5.5" width="18.0" height="13.0" rx="2.5" />
	<path d="M 7.0 9.5 L 8.5 9.5 M 11.2 9.5 L 12.8 9.5 M 15.5 9.5 L 17.0 9.5 M 7.0 13.2 L 8.5 13.2 M 15.5 13.2 L 17.0 13.2 M 9.5 15.0 L 14.5 15.0" />
</svg>]],

	vehicle = [[
<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
	<path d="M 3.0 13.5 L 6.0 7.5 L 15.5 7.5 L 18.5 11.5 L 21.0 12.2 L 21.0 16.5 L 3.0 16.5 Z" />
	<circle cx="7.2" cy="17.5" r="2.2" />
	<circle cx="16.8" cy="17.5" r="2.2" />
</svg>]],
}

local function resolveSvgIconId(rawIdOrTitle: string?): string
	local key = string.lower(tostring(rawIdOrTitle or "main"))
	if CustomSvgDefinitions[key] then
		return key
	end
	if string.find(key, "main") then return "main" end
	if string.find(key, "vehicle") or string.find(key, "boat") or string.find(key, "truck") or string.find(key, "sail") then return "vehicle" end
	if string.find(key, "rod quest") then return "rod_quest" end
	if string.find(key, "rod") then return "rod_skills" end
	if string.find(key, "daily") then return "daily_star" end
	if string.find(key, "quest") or string.find(key, "island") then return "quests" end
	if string.find(key, "gacha") then return "gacha" end
	if string.find(key, "setting") or string.find(key, "config") then return "settings" end
	if string.find(key, "fish") then return "auto_fish" end
	if string.find(key, "sell") or string.find(key, "lock") then return "sell_lock" end
	if string.find(key, "skill book") or string.find(key, "auto skill") then return "skill_book" end
	if string.find(key, "reroll") then return "reroll_bolt" end
	if string.find(key, "unit") then return "unit_crest" end
	if string.find(key, "ocean") or string.find(key, "chest") then return "ocean_chest" end
	if string.find(key, "aura") then return "aura_sparkle" end
	if string.find(key, "raid") or string.find(key, "dungeon") then return "raid_swords" end
	if string.find(key, "dragon") or string.find(key, "boss") then return "dragon_crest" end
	if string.find(key, "keybind") or string.find(key, "system") then return "keybind" end
	return "main"
end

-- Reusable Custom SVG Vector Icon Component
local function createCustomSvgIcon(
	parent: Instance,
	iconName: string,
	iconSize: number?,
	initialColor: Color3?,
	position: UDim2?
)
	local sz = iconSize or 18
	local curColor = initialColor or Theme.TextMuted
	local strokePx = math.clamp(1.8 * (sz / 18), 1.4, 2.2)

	local container = Instance.new("Frame")
	container.Name = "SvgIcon_" .. tostring(iconName)
	container.Size = UDim2.fromOffset(sz, sz)
	container.Position = position or UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = parent

	local strokeTargets: { UIStroke } = {}
	local fillTargets: { Frame } = {}

	local function drawVectorSegment(x0: number, y0: number, x1: number, y1: number)
		local px0 = (x0 / 24) * sz
		local py0 = (y0 / 24) * sz
		local px1 = (x1 / 24) * sz
		local py1 = (y1 / 24) * sz
		local dx = px1 - px0
		local dy = py1 - py0
		local dist = math.sqrt(dx * dx + dy * dy)
		if dist < 0.05 then
			return
		end

		local seg = Instance.new("Frame")
		seg.AnchorPoint = Vector2.new(0.5, 0.5)
		seg.Position = UDim2.fromOffset((px0 + px1) * 0.5, (py0 + py1) * 0.5)
		seg.Size = UDim2.fromOffset(dist + strokePx * 0.85, strokePx)
		seg.Rotation = math.deg(math.atan2(dy, dx))
		seg.BackgroundColor3 = curColor
		seg.BorderSizePixel = 0
		seg.Parent = container

		local cap = Instance.new("UICorner")
		cap.CornerRadius = UDim.new(1, 0)
		cap.Parent = seg

		table.insert(fillTargets, seg)
	end

	local function parseAndRenderSvgPath(d: string)
		local cleanD = string.gsub(d, "([A-Za-z])", " %1 ")
		cleanD = string.gsub(cleanD, ",", " ")
		local tokens = {}
		for tok in string.gmatch(cleanD, "%S+") do
			table.insert(tokens, tok)
		end

		local i = 1
		local curX, curY = 0, 0
		local startX, startY = 0, 0
		local cmd = "M"

		while i <= #tokens do
			local t = tokens[i]
			if string.match(t, "^[A-Za-z]$") then
				cmd = t
				i += 1
			end

			if cmd == "M" then
				local nx = tonumber(tokens[i]) or 0
				local ny = tonumber(tokens[i + 1]) or 0
				curX, curY = nx, ny
				startX, startY = nx, ny
				i += 2
				cmd = "L"
			elseif cmd == "L" then
				local nx = tonumber(tokens[i]) or 0
				local ny = tonumber(tokens[i + 1]) or 0
				drawVectorSegment(curX, curY, nx, ny)
				curX, curY = nx, ny
				i += 2
			elseif cmd == "H" then
				local nx = tonumber(tokens[i]) or 0
				drawVectorSegment(curX, curY, nx, curY)
				curX = nx
				i += 1
			elseif cmd == "V" then
				local ny = tonumber(tokens[i]) or 0
				drawVectorSegment(curX, curY, curX, ny)
				curY = ny
				i += 1
			elseif cmd == "C" then
				local x1 = tonumber(tokens[i]) or 0
				local y1 = tonumber(tokens[i + 1]) or 0
				local x2 = tonumber(tokens[i + 2]) or 0
				local y2 = tonumber(tokens[i + 3]) or 0
				local ex = tonumber(tokens[i + 4]) or 0
				local ey = tonumber(tokens[i + 5]) or 0
				local steps = 7
				local prevX, prevY = curX, curY
				for s = 1, steps do
					local u = s / steps
					local inv = 1 - u
					local bx = (inv ^ 3) * curX + 3 * (inv ^ 2) * u * x1 + 3 * inv * (u ^ 2) * x2 + (u ^ 3) * ex
					local by = (inv ^ 3) * curY + 3 * (inv ^ 2) * u * y1 + 3 * inv * (u ^ 2) * y2 + (u ^ 3) * ey
					drawVectorSegment(prevX, prevY, bx, by)
					prevX, prevY = bx, by
				end
				curX, curY = ex, ey
				i += 6
			elseif cmd == "Q" then
				local x1 = tonumber(tokens[i]) or 0
				local y1 = tonumber(tokens[i + 1]) or 0
				local ex = tonumber(tokens[i + 2]) or 0
				local ey = tonumber(tokens[i + 3]) or 0
				local steps = 6
				local prevX, prevY = curX, curY
				for s = 1, steps do
					local u = s / steps
					local inv = 1 - u
					local bx = (inv ^ 2) * curX + 2 * inv * u * x1 + (u ^ 2) * ex
					local by = (inv ^ 2) * curY + 2 * inv * u * y1 + (u ^ 2) * ey
					drawVectorSegment(prevX, prevY, bx, by)
					prevX, prevY = bx, by
				end
				curX, curY = ex, ey
				i += 4
			elseif cmd == "Z" or cmd == "z" then
				drawVectorSegment(curX, curY, startX, startY)
				curX, curY = startX, startY
			else
				i += 1
			end
		end
	end

	local function buildIconGeometry(targetIconName: string)
		for _, ch in ipairs(container:GetChildren()) do
			ch:Destroy()
		end
		table.clear(strokeTargets)
		table.clear(fillTargets)

		local resolved = resolveSvgIconId(targetIconName)
		local svgMarkup = CustomSvgDefinitions[resolved] or CustomSvgDefinitions.main

		-- Parse <rect ... /> elements
		for rectTag in string.gmatch(svgMarkup, "<rect[^/>]+/>") do
			local x = tonumber(string.match(rectTag, 'x="([^"]+)"')) or 0
			local y = tonumber(string.match(rectTag, 'y="([^"]+)"')) or 0
			local w = tonumber(string.match(rectTag, 'width="([^"]+)"')) or 0
			local h = tonumber(string.match(rectTag, 'height="([^"]+)"')) or 0
			local rx = tonumber(string.match(rectTag, 'rx="([^"]+)"')) or 0

			local rf = Instance.new("Frame")
			rf.Position = UDim2.fromOffset((x / 24) * sz, (y / 24) * sz)
			rf.Size = UDim2.fromOffset((w / 24) * sz, (h / 24) * sz)
			rf.BackgroundTransparency = 1
			rf.BorderSizePixel = 0
			rf.Parent = container

			if rx > 0 then
				local rc = Instance.new("UICorner")
				rc.CornerRadius = UDim.new(0, math.max(1, math.floor((rx / 24) * sz + 0.5)))
				rc.Parent = rf
			end

			local rs = Instance.new("UIStroke")
			rs.Color = curColor
			rs.Thickness = strokePx
			rs.LineJoinMode = Enum.LineJoinMode.Round
			rs.Parent = rf
			table.insert(strokeTargets, rs)
		end

		-- Parse <circle ... /> elements
		for circleTag in string.gmatch(svgMarkup, "<circle[^/>]+/>") do
			local cx = tonumber(string.match(circleTag, 'cx="([^"]+)"')) or 12
			local cy = tonumber(string.match(circleTag, 'cy="([^"]+)"')) or 12
			local r = tonumber(string.match(circleTag, 'r="([^"]+)"')) or 4

			local cf = Instance.new("Frame")
			cf.Position = UDim2.fromOffset(((cx - r) / 24) * sz, ((cy - r) / 24) * sz)
			cf.Size = UDim2.fromOffset(((r * 2) / 24) * sz, ((r * 2) / 24) * sz)
			cf.BackgroundTransparency = 1
			cf.BorderSizePixel = 0
			cf.Parent = container

			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(1, 0)
			cc.Parent = cf

			local cs = Instance.new("UIStroke")
			cs.Color = curColor
			cs.Thickness = strokePx
			cs.Parent = cf
			table.insert(strokeTargets, cs)
		end

		-- Parse <path d="..." /> elements
		for pathD in string.gmatch(svgMarkup, '<path[^>]-d="([^"]+)"') do
			parseAndRenderSvgPath(pathD)
		end
	end

	buildIconGeometry(iconName)

	local iconController = {
		Frame = container,
	}

	function iconController:SetColor(newColor: Color3, tweenSec: number?)
		curColor = newColor
		if tweenSec and tweenSec > 0 then
			local ti = TweenInfo.new(tweenSec)
			for _, st in ipairs(strokeTargets) do
				TweenService:Create(st, ti, { Color = newColor }):Play()
			end
			for _, fl in ipairs(fillTargets) do
				TweenService:Create(fl, ti, { BackgroundColor3 = newColor }):Play()
			end
		else
			for _, st in ipairs(strokeTargets) do
				st.Color = newColor
			end
			for _, fl in ipairs(fillTargets) do
				fl.BackgroundColor3 = newColor
			end
		end
	end

	function iconController:SetIcon(newIconName: string)
		buildIconGeometry(newIconName)
	end

	function iconController:SetRotation(deg: number, tweenSec: number?)
		if tweenSec and tweenSec > 0 then
			TweenService:Create(container, TweenInfo.new(tweenSec), { Rotation = deg }):Play()
		else
			container.Rotation = deg
		end
	end

	return iconController
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SerennityHubGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Forward declarations for in-card Real-Time Live Status Boxes
local traitLiveH: TextLabel?, traitLiveBuff: TextLabel?, traitLiveSub: TextLabel? = nil, nil, nil
local gradeLiveH: TextLabel?, gradeLiveBuff: TextLabel?, gradeLiveSub: TextLabel? = nil, nil, nil
local quirkLiveH: TextLabel?, quirkLiveBuff: TextLabel?, quirkLiveSub: TextLabel? = nil, nil, nil

local NumberFormatter = nil
pcall(function()
	NumberFormatter = require(ReplicatedStorage.Packages.NumberFormatter)
end)

local function formatMoney(val: any): string
	local n = tonumber(val) or 0
	if n < 0 then n = 0 end
	if NumberFormatter and NumberFormatter.FormatCompact then
		local ok, res = pcall(NumberFormatter.FormatCompact, n)
		if ok and res and type(res) == "string" and res ~= "" then
			return res
		end
	end
	local suffixes = {
		{ 1e33, "dc" }, { 1e30, "no" }, { 1e27, "oc" }, { 1e24, "sp" }, { 1e21, "sx" },
		{ 1e18, "qi" }, { 1e15, "qa" }, { 1e12, "t" }, { 1e9, "b" }, { 1e6, "m" }, { 1e3, "k" }
	}
	for _, s in ipairs(suffixes) do
		if n >= s[1] then
			local formatted = string.format("%.2f%s", n / s[1], s[2])
			return formatted:gsub("%.00", ""):gsub("(%d+%.%d)0", "%1")
		end
	end
	return string.format("%d", n)
end

local chanceMultipliers = {
	k = 1e3, m = 1e6, b = 1e9, t = 1e12,
	qa = 1e15, q = 1e15, qi = 1e18, sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33,
	ud = 1e36, dd = 1e39, td = 1e42, qad = 1e45, qid = 1e48, sxd = 1e51, spd = 1e54, ocd = 1e57, nod = 1e60,
	vg = 1e63, uvg = 1e66, dvg = 1e69, tvg = 1e72, qavg = 1e75, qivg = 1e78, sxvg = 1e81, spvg = 1e84, ocvg = 1e87, novg = 1e90,
	tg = 1e93, utg = 1e96, dtg = 1e99, ttg = 1e102, qatg = 1e105, qitg = 1e108, sxtg = 1e111, sptg = 1e114, octg = 1e117, notg = 1e120,
	qag = 1e123, qig = 1e153, sxg = 1e183, spg = 1e213, ocg = 1e243, nog = 1e273, cent = 1e303
}

local function parseChance(val: any, defaultVal: number): number
	if type(val) == "number" then return val end
	if not val or val == "" then return defaultVal end
	local clean = tostring(val):gsub("1%s*in%s*", ""):gsub("[%$,%s]", ""):lower()
	local direct = tonumber(clean)
	if direct then return direct end
	local num, suffix = clean:match("^([%d%.]+)%s*([a-z]+)$")
	if not num then return defaultVal end
	local n = tonumber(num) or defaultVal
	if suffix and chanceMultipliers[suffix] then
		n = n * chanceMultipliers[suffix]
	end
	return n
end

local function getUnitChance(item: any): number
	if not item or type(item) ~= "table" then return 0 end
	local uName = item.name or ""
	local reg = nil
	pcall(function()
		reg = require(ReplicatedStorage.Framework.Features.Inventory.EntryRegistry)
	end)
	if not reg then
		pcall(function()
			reg = require(ReplicatedStorage.Framework.EntryRegistry)
		end)
	end
	if reg and reg.getEntryConfig then
		local ok, cfg = pcall(reg.getEntryConfig, uName)
		if ok and cfg and cfg.chance then
			if type(cfg.chance) == "function" then
				local ok2, val = pcall(cfg.chance, item.attributes or {})
				if ok2 and type(val) == "number" then return val end
			elseif type(cfg.chance) == "number" then
				return cfg.chance
			end
		end
	end
	return 0
end

local QUIRK_BUFF_INFO = {
	["Sovereign"] = { buff = "All Stats Buff (Secret)", color = Color3.fromRGB(0, 220, 255) },
	["Fortune's Favor"] = { buff = "Luck + Rolls Buff (Secret)", color = Color3.fromRGB(255, 120, 255) },
	["Midas Touch"] = { buff = "Money Buff (Secret)", color = Color3.fromRGB(255, 215, 0) },
	["Prodigy"] = { buff = "Trait Luck Buff (Secret)", color = Color3.fromRGB(180, 100, 255) },
	["Tycoon"] = { buff = "Money Multiplier (Secret)", color = Color3.fromRGB(60, 240, 140) },
	["Gifted III"] = { buff = "+100% Trait Luck (Tier III)", color = Color3.fromRGB(100, 220, 255) },
	["Gifted II"] = { buff = "+50% Trait Luck (Tier II)", color = Color3.fromRGB(80, 200, 240) },
	["Gifted I"] = { buff = "+20% Trait Luck (Tier I)", color = Color3.fromRGB(140, 180, 220) },
	["Fortune III"] = { buff = "+100% Luck (Tier III)", color = Color3.fromRGB(255, 215, 0) },
	["Fortune II"] = { buff = "+50% Luck (Tier II)", color = Color3.fromRGB(255, 235, 100) },
	["Fortune I"] = { buff = "+20% Luck (Tier I)", color = Color3.fromRGB(220, 220, 140) },
	["Wealth III"] = { buff = "+100% Income (Tier III)", color = Color3.fromRGB(80, 240, 140) },
	["Wealth II"] = { buff = "+50% Income (Tier II)", color = Color3.fromRGB(100, 220, 150) },
	["Wealth I"] = { buff = "+20% Income (Tier I)", color = Color3.fromRGB(160, 200, 170) },
	["Swift III"] = { buff = "+100% Roll Speed (Tier III)", color = Color3.fromRGB(255, 120, 120) },
	["Swift II"] = { buff = "+50% Roll Speed (Tier II)", color = Color3.fromRGB(255, 160, 160) },
	["Swift I"] = { buff = "+20% Roll Speed (Tier I)", color = Color3.fromRGB(220, 180, 180) },
	["Refined III"] = { buff = "Refined Buff (Tier III)", color = Color3.fromRGB(200, 140, 255) },
	["Refined II"] = { buff = "Refined Buff (Tier II)", color = Color3.fromRGB(180, 150, 240) },
	["Refined I"] = { buff = "Refined Buff (Tier I)", color = Color3.fromRGB(170, 170, 200) },
	["None"] = { buff = "No Quirk", color = Color3.fromRGB(160, 160, 160) }
}

-- Buff Reference Dictionaries for Real-Time Visuals
local TRAIT_BUFF_INFO = {
	["Genesis"] = { buff = "+12,000% (120x All)", color = Color3.fromRGB(255, 60, 60) },
	["Paradox"] = { buff = "+5,750% (57.5x All)", color = Color3.fromRGB(180, 70, 255) },
	["Eternal"] = { buff = "+3,000% (30x All)", color = Color3.fromRGB(100, 220, 255) },
	["Transcendent"] = { buff = "+1,500% (15x All)", color = Color3.fromRGB(255, 215, 0) },
	["Monarch"] = { buff = "+800% (8x All)", color = Color3.fromRGB(255, 170, 0) },
	["Shogun"] = { buff = "+500% (5x All)", color = Color3.fromRGB(230, 100, 255) },
	["Samurai"] = { buff = "+300% (3x All)", color = Color3.fromRGB(80, 200, 255) },
	["Money III"] = { buff = "+100% (2x Income)", color = Color3.fromRGB(62, 247, 130) },
	["Money II"] = { buff = "+50% (1.5x Income)", color = Color3.fromRGB(62, 247, 130) },
	["Money I"] = { buff = "+20% (1.2x Income)", color = Color3.fromRGB(62, 247, 130) },
	["Damage III"] = { buff = "+100% (2x Damage)", color = Color3.fromRGB(62, 232, 247) },
	["Damage II"] = { buff = "+50% (1.5x Damage)", color = Color3.fromRGB(62, 232, 247) },
	["Damage I"] = { buff = "+20% (1.2x Damage)", color = Color3.fromRGB(62, 232, 247) },
	["Health III"] = { buff = "+100% (2x Health)", color = Color3.fromRGB(247, 62, 62) },
	["Health II"] = { buff = "+50% (1.5x Health)", color = Color3.fromRGB(247, 62, 62) },
	["Health I"] = { buff = "+20% (1.2x Health)", color = Color3.fromRGB(247, 62, 62) },
	["None"] = { buff = "No Trait", color = Color3.fromRGB(160, 160, 160) }
}

local GRADE_BUFF_INFO = {
	["Ω"] = { buff = "250x Multiplier", color = Color3.fromRGB(255, 60, 60) },
	["∞"] = { buff = "100x Multiplier", color = Color3.fromRGB(255, 80, 255) },
	["神"] = { buff = "50x Multiplier", color = Color3.fromRGB(255, 170, 0) },
	["Z+"] = { buff = "25x Multiplier", color = Color3.fromRGB(255, 215, 0) },
	["Z"] = { buff = "15x Multiplier", color = Color3.fromRGB(255, 235, 120) },
	["S+"] = { buff = "10x Multiplier", color = Color3.fromRGB(160, 80, 255) },
	["S"] = { buff = "7x Multiplier", color = Color3.fromRGB(140, 100, 240) },
	["A+"] = { buff = "4.5x Multiplier", color = Color3.fromRGB(60, 220, 120) },
	["A"] = { buff = "3x Multiplier", color = Color3.fromRGB(80, 200, 100) },
	["B"] = { buff = "1.75x Multiplier", color = Color3.fromRGB(80, 160, 240) },
	["C"] = { buff = "1.25x Multiplier", color = Color3.fromRGB(180, 180, 180) },
	["D"] = { buff = "1.1x Multiplier", color = Color3.fromRGB(140, 140, 140) }
}

-- [REALTIME ROLL VISUAL HUD] In-card live status with optional screen HUD fallback
local RollHUD = Instance.new("Frame")
RollHUD.Name = "SerennityRollHUD"
RollHUD.Size = UDim2.new(0, 360, 0, 72)
RollHUD.Position = UDim2.new(0.5, -180, 0, 18)
RollHUD.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
RollHUD.BackgroundTransparency = 0.08
RollHUD.BorderSizePixel = 0
RollHUD.Visible = false
RollHUD.Parent = ScreenGui
local rhCorner = Instance.new("UICorner"); rhCorner.CornerRadius = UDim.new(0, 8); rhCorner.Parent = RollHUD
local rhStroke = Instance.new("UIStroke"); rhStroke.Color = Color3.fromRGB(45, 95, 175); rhStroke.Thickness = 1.2; rhStroke.Parent = RollHUD

local rhTitle = Instance.new("TextLabel")
rhTitle.Size = UDim2.new(1, -20, 0, 18); rhTitle.Position = UDim2.new(0, 10, 0, 6)
rhTitle.BackgroundTransparency = 1; rhTitle.FontFace = FontBold; rhTitle.TextSize = 13
rhTitle.TextColor3 = Color3.fromRGB(130, 190, 255); rhTitle.TextXAlignment = Enum.TextXAlignment.Left
rhTitle.Text = "⚡ Auto Rolling Unit Evolution"; rhTitle.Parent = RollHUD

local rhBuff = Instance.new("TextLabel")
rhBuff.Size = UDim2.new(1, -20, 0, 22); rhBuff.Position = UDim2.new(0, 10, 0, 25)
rhBuff.BackgroundTransparency = 1; rhBuff.FontFace = FontBold; rhBuff.TextSize = 15
rhBuff.TextColor3 = Color3.fromRGB(255, 255, 255); rhBuff.TextXAlignment = Enum.TextXAlignment.Left
rhBuff.Text = "Current Buff: None"; rhBuff.Parent = RollHUD

local rhSub = Instance.new("TextLabel")
rhSub.Size = UDim2.new(1, -20, 0, 18); rhSub.Position = UDim2.new(0, 10, 0, 48)
rhSub.BackgroundTransparency = 1; rhSub.FontFace = FontMedium; rhSub.TextSize = 12
rhSub.TextColor3 = Color3.fromRGB(180, 185, 200); rhSub.TextXAlignment = Enum.TextXAlignment.Left
rhSub.Text = "Target: None | Rerolls Remaining: 0"; rhSub.Parent = RollHUD

local function updateLiveRollHUD(mode: string, unitName: string, plotNum: string, currentBuffName: string, targetName: string, currencyCount: number)
	if mode == "Trait" then
		local info = TRAIT_BUFF_INFO and TRAIT_BUFF_INFO[currentBuffName] or { buff = currentBuffName, color = Color3.fromRGB(255, 255, 255) }
		if traitLiveH and traitLiveBuff and traitLiveSub then
			traitLiveH.Text = string.format("Auto Rerolling Trait • %s (Plot %s)", unitName or "Unit", plotNum or "1")
			traitLiveBuff.Text = string.format("Current Trait: %s (%s)", currentBuffName, info.buff)
			traitLiveBuff.TextColor3 = info.color or Color3.fromRGB(255, 255, 255)
			traitLiveSub.Text = string.format("Target: %s • Rerolls Left: %d", targetName or "None", currencyCount or 0)
		end
	elseif mode == "Grade" then
		local info = GRADE_BUFF_INFO and GRADE_BUFF_INFO[currentBuffName] or { buff = currentBuffName, color = Color3.fromRGB(255, 255, 255) }
		if gradeLiveH and gradeLiveBuff and gradeLiveSub then
			gradeLiveH.Text = string.format("Auto Upgrading Grade • %s (Plot %s)", unitName or "Unit", plotNum or "1")
			gradeLiveBuff.Text = string.format("Current Grade: %s (%s)", currentBuffName, info.buff)
			gradeLiveBuff.TextColor3 = info.color or Color3.fromRGB(255, 255, 255)
			gradeLiveSub.Text = string.format("Target: %s • Gems Left: %d", targetName or "None", currencyCount or 0)
		end
	elseif mode == "Quirk" then
		local info = QUIRK_BUFF_INFO and QUIRK_BUFF_INFO[currentBuffName] or { buff = currentBuffName, color = Color3.fromRGB(255, 255, 255) }
		if quirkLiveH and quirkLiveBuff and quirkLiveSub then
			quirkLiveH.Text = string.format("Auto Rerolling Quirk • %s (Plot %s)", unitName or "Unit", plotNum or "1")
			quirkLiveBuff.Text = string.format("Current Quirk: %s (%s)", currentBuffName, info.buff)
			quirkLiveBuff.TextColor3 = info.color or Color3.fromRGB(255, 255, 255)
			quirkLiveSub.Text = string.format("Target: %s • Cash Left: $%s", targetName or "None", formatMoney(currencyCount))
		end
	end
end

local function hideLiveRollHUD(mode: string?)
	if RollHUD then RollHUD.Visible = false end
	if not mode or mode == "Trait" then
		if traitLiveH and traitLiveBuff and traitLiveSub then
			if not (traitLiveH.Text and traitLiveH.Text:find("Complete")) then
				local uKey, uData = getSelectedUnitData(Cfg.SelectedTraitUnit or Cfg.SelectedTraitGradeUnit)
				local uName = uData and getUnitName(uData) or "None"
				local curTrait = uData and getAttr(uData, "trait", "None") or "None"
				local trInfo = TRAIT_BUFF_INFO and TRAIT_BUFF_INFO[curTrait] or { buff = curTrait, color = Color3.fromRGB(220, 225, 235) }
				local rerolls = 0
				if EntryController and EntryController.GetAmount then
					pcall(function() rerolls = EntryController.GetAmount("Trait Reroll") or 0 end)
				end
				traitLiveH.Text = string.format("Live Trait Roll • Idle (%s)", uName)
				traitLiveBuff.Text = string.format("Current Trait: %s (%s)", curTrait, trInfo.buff)
				traitLiveBuff.TextColor3 = trInfo.color or Color3.fromRGB(220, 225, 235)
				traitLiveSub.Text = string.format("Target: %s • Rerolls: %d", Cfg.TargetTrait or "None", rerolls)
			end
		end
	end
	if not mode or mode == "Grade" then
		if gradeLiveH and gradeLiveBuff and gradeLiveSub then
			if not (gradeLiveH.Text and gradeLiveBuff.Text:find("Complete")) then
				local uKey, uData = getSelectedUnitData(Cfg.SelectedGradeUnit or Cfg.SelectedTraitGradeUnit)
				local uName = uData and getUnitName(uData) or "None"
				local curGrade = uData and getAttr(uData, "grade", "D") or "D"
				local grInfo = GRADE_BUFF_INFO and GRADE_BUFF_INFO[curGrade] or { buff = curGrade, color = Color3.fromRGB(220, 225, 235) }
				local gems = 0
				if EntryController and EntryController.GetAmount then
					pcall(function() gems = EntryController.GetAmount("Gems") or 0 end)
				end
				gradeLiveH.Text = string.format("Live Grade Upgrade • Idle (%s)", uName)
				gradeLiveBuff.Text = string.format("Current Grade: %s (%s)", curGrade, grInfo.buff)
				gradeLiveBuff.TextColor3 = grInfo.color or Color3.fromRGB(220, 225, 235)
				gradeLiveSub.Text = string.format("Target: %s • Gems: %d", Cfg.TargetGrade or "None", gems)
			end
		end
	end
	if not mode or mode == "Quirk" then
		if quirkLiveH and quirkLiveBuff and quirkLiveSub then
			if not (quirkLiveH.Text and quirkLiveBuff.Text:find("Complete")) then
				local uKey, uData = getSelectedUnitData(Cfg.SelectedQuirkUnit)
				local uName = uData and getUnitName(uData) or "None"
				local curQuirk = uData and getAttr(uData, "quirk", "None") or "None"
				local qInfo = QUIRK_BUFF_INFO and QUIRK_BUFF_INFO[curQuirk] or { buff = curQuirk, color = Color3.fromRGB(220, 225, 235) }
				local myMoney = (DataController and DataController.Money and DataController.Money()) or 0
				quirkLiveH.Text = string.format("Live Quirk Roll • Idle (%s)", uName)
				quirkLiveBuff.Text = string.format("Current Quirk: %s (%s)", curQuirk, qInfo.buff)
				quirkLiveBuff.TextColor3 = qInfo.color or Color3.fromRGB(220, 225, 235)
				quirkLiveSub.Text = string.format("Target: %s • Cash: $%s", Cfg.TargetQuirk or "None", formatMoney(myMoney))
			end
		end
	end
end

-- ====================================================================
-- [SERENNITY AFK DASHBOARD & LIVE BACKPACK DROPS STREAM]
-- Fullscreen Pitch-Black (0,0,0) OLED • All-In-One Unified Backpack Drops Feed
-- Every Item, Trait, Potion, Token & Drop with Asset Image, Quantity & Category
-- ====================================================================
local AfkOverlay = Instance.new("Frame")
AfkOverlay.Name = "SerennityAfkOverlay"
AfkOverlay.Size = UDim2.new(1, 0, 1, 0)
AfkOverlay.Position = UDim2.new(0, 0, 0, 0)
AfkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
AfkOverlay.BackgroundTransparency = 0
AfkOverlay.BorderSizePixel = 0
AfkOverlay.ZIndex = 8000
AfkOverlay.Visible = false
AfkOverlay.Parent = ScreenGui

local afkHud = Instance.new("Frame")
afkHud.Name = "AfkHudCard"
afkHud.Size = UDim2.new(0, 720, 0, 520)
afkHud.Position = UDim2.new(0.5, 0, 0.5, 0)
afkHud.AnchorPoint = Vector2.new(0.5, 0.5)
afkHud.BackgroundColor3 = Theme.WindowBg
afkHud.BorderSizePixel = 0
afkHud.ClipsDescendants = true
afkHud.ZIndex = 8001
afkHud.Parent = AfkOverlay

do
	local hudCorner = Instance.new("UICorner"); hudCorner.CornerRadius = UDim.new(0, 12); hudCorner.Parent = afkHud
	local hudStroke = Instance.new("UIStroke"); hudStroke.Color = Theme.Stroke; hudStroke.Thickness = 1.2; hudStroke.Parent = afkHud
end

-- Responsive Scale for smaller mobile/tablet screens
do
	local afkScale = Instance.new("UIScale")
	afkScale.Name = "AfkResponsiveScale"
	afkScale.Scale = 1
	afkScale.Parent = afkHud

	local function updateAfkScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then return end
		local s = 1
		if vp.X < 750 or vp.Y < 550 then
			s = math.clamp(math.min((vp.X - 24) / 720, (vp.Y - 24) / 520), 0.45, 1)
		end
		afkScale.Scale = s
	end
	updateAfkScale()
	if workspace.CurrentCamera then
		table.insert(Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAfkScale))
	end
end

-- 1. Brand Header Row (Height: 52px)
local afkTopRow = Instance.new("Frame")
afkTopRow.Name = "BrandHeader"
afkTopRow.Size = UDim2.new(1, 0, 0, 52)
afkTopRow.Position = UDim2.new(0, 0, 0, 0)
afkTopRow.BackgroundColor3 = Theme.SidebarBg
afkTopRow.BorderSizePixel = 0
afkTopRow.ZIndex = 8002
afkTopRow.Parent = afkHud

do
	local topCorner = Instance.new("UICorner"); topCorner.CornerRadius = UDim.new(0, 12); topCorner.Parent = afkTopRow
	local topFiller = Instance.new("Frame")
	topFiller.Size = UDim2.new(1, 0, 0, 14); topFiller.Position = UDim2.new(0, 0, 1, -14)
	topFiller.BackgroundColor3 = Theme.SidebarBg; topFiller.BorderSizePixel = 0; topFiller.ZIndex = 8002; topFiller.Parent = afkTopRow

	local topDivider = Instance.new("Frame")
	topDivider.Size = UDim2.new(1, 0, 0, 1); topDivider.Position = UDim2.new(0, 0, 1, -1)
	topDivider.BackgroundColor3 = Theme.Stroke; topDivider.BorderSizePixel = 0; topDivider.ZIndex = 8003; topDivider.Parent = afkTopRow
end

local afkLogoIcon = createCustomSvgIcon(afkTopRow, "main", 22, Theme.AccentBlue, UDim2.new(0, 18, 0.5, -11))

local afkBrandBox = Instance.new("Frame")
afkBrandBox.Size = UDim2.new(0.55, 0, 1, 0); afkBrandBox.Position = UDim2.new(0, 48, 0, 0)
afkBrandBox.BackgroundTransparency = 1; afkBrandBox.ZIndex = 8003; afkBrandBox.Parent = afkTopRow

local afkTitle = Instance.new("TextLabel")
afkTitle.Size = UDim2.new(1, 0, 0, 20); afkTitle.Position = UDim2.new(0, 0, 0, 9)
afkTitle.BackgroundTransparency = 1; afkTitle.FontFace = FontBold; afkTitle.TextSize = 14
afkTitle.TextColor3 = Theme.TextPrimary; afkTitle.TextXAlignment = Enum.TextXAlignment.Left
afkTitle.Text = "SERENNITY HUB"; afkTitle.ZIndex = 8004; afkTitle.Parent = afkBrandBox

local afkSubTitle = Instance.new("TextLabel")
afkSubTitle.Size = UDim2.new(1, 0, 0, 14); afkSubTitle.Position = UDim2.new(0, 0, 0, 28)
afkSubTitle.BackgroundTransparency = 1; afkSubTitle.FontFace = FontMedium; afkSubTitle.TextSize = 10
afkSubTitle.TextColor3 = Theme.TextMuted; afkSubTitle.TextXAlignment = Enum.TextXAlignment.Left
afkSubTitle.Text = "AFK AUTOMATION ENGINE | BACKPACK DROPS STREAM"; afkSubTitle.ZIndex = 8004; afkSubTitle.Parent = afkBrandBox

-- Right Status Badge
local afkLivePill = Instance.new("Frame")
afkLivePill.Size = UDim2.new(0, 130, 0, 26); afkLivePill.Position = UDim2.new(1, -146, 0.5, -13)
afkLivePill.BackgroundColor3 = Theme.BadgeBg; afkLivePill.BorderSizePixel = 0; afkLivePill.ZIndex = 8003; afkLivePill.Parent = afkTopRow
do
	local lpCorner = Instance.new("UICorner"); lpCorner.CornerRadius = UDim.new(0, 6); lpCorner.Parent = afkLivePill
	local lpStroke = Instance.new("UIStroke"); lpStroke.Color = Theme.ActiveStroke; lpStroke.Thickness = 1; lpStroke.Parent = afkLivePill
end

local afkDot = Instance.new("Frame")
afkDot.Size = UDim2.new(0, 8, 0, 8); afkDot.Position = UDim2.new(0, 10, 0.5, -4)
afkDot.BackgroundColor3 = Theme.OnlineGreen; afkDot.BorderSizePixel = 0; afkDot.ZIndex = 8004; afkDot.Parent = afkLivePill
do local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = afkDot end

local lpText = Instance.new("TextLabel")
lpText.Size = UDim2.new(1, -26, 1, 0); lpText.Position = UDim2.new(0, 24, 0, 0)
lpText.BackgroundTransparency = 1; lpText.FontFace = FontBold; lpText.TextSize = 10
lpText.TextColor3 = Theme.OnlineGreen; lpText.TextXAlignment = Enum.TextXAlignment.Left
lpText.Text = "ENGINE ACTIVE"; lpText.ZIndex = 8004; lpText.Parent = afkLivePill

-- 2. Sub-Header: Current Activity & Quick Overview (Height: 64px)
local subRow = Instance.new("Frame")
subRow.Size = UDim2.new(1, -32, 0, 64)
subRow.Position = UDim2.new(0, 16, 0, 60)
subRow.BackgroundTransparency = 1
subRow.ZIndex = 8002
subRow.Parent = afkHud

-- Current Task Box (Left 50%)
local afkActBox = Instance.new("Frame")
afkActBox.Size = UDim2.new(0.50, -4, 1, 0)
afkActBox.Position = UDim2.new(0, 0, 0, 0)
afkActBox.BackgroundColor3 = Theme.CardBg
afkActBox.BorderSizePixel = 0
afkActBox.ZIndex = 8003
afkActBox.Parent = subRow
do
	local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0, 8); ac.Parent = afkActBox
	local as = Instance.new("UIStroke"); as.Color = Theme.Stroke; as.Thickness = 1; as.Parent = afkActBox
end

local actSub = Instance.new("TextLabel")
actSub.Size = UDim2.new(1, -20, 0, 14); actSub.Position = UDim2.new(0, 12, 0, 8)
actSub.BackgroundTransparency = 1; actSub.FontFace = FontBold; actSub.TextSize = 10
actSub.TextColor3 = Theme.AccentBlue; actSub.TextXAlignment = Enum.TextXAlignment.Left
actSub.Text = "CURRENT AUTOMATION TASK"; actSub.ZIndex = 8004; actSub.Parent = afkActBox

local afkActivityText = Instance.new("TextLabel")
afkActivityText.Size = UDim2.new(1, -20, 0, 32); afkActivityText.Position = UDim2.new(0, 12, 0, 24)
afkActivityText.BackgroundTransparency = 1; afkActivityText.FontFace = FontSemiBold or FontBold; afkActivityText.TextSize = 13
afkActivityText.TextColor3 = Theme.TextPrimary; afkActivityText.TextXAlignment = Enum.TextXAlignment.Left
afkActivityText.TextTruncate = Enum.TextTruncate.AtEnd; afkActivityText.Text = "Initializing Hub Automation Engine..."
afkActivityText.ZIndex = 8004; afkActivityText.Parent = afkActBox

-- Quick Overview Stats Box (Right 50%)
local afkQuickStatsBox = Instance.new("Frame")
afkQuickStatsBox.Size = UDim2.new(0.50, -4, 1, 0)
afkQuickStatsBox.Position = UDim2.new(0.50, 4, 0, 0)
afkQuickStatsBox.BackgroundColor3 = Theme.CardBg
afkQuickStatsBox.BorderSizePixel = 0
afkQuickStatsBox.ZIndex = 8003
afkQuickStatsBox.Parent = subRow
do
	local qc = Instance.new("UICorner"); qc.CornerRadius = UDim.new(0, 8); qc.Parent = afkQuickStatsBox
	local qs = Instance.new("UIStroke"); qs.Color = Theme.Stroke; qs.Thickness = 1; qs.Parent = afkQuickStatsBox
end

local qStatTimeRolls = Instance.new("TextLabel")
qStatTimeRolls.Size = UDim2.new(1, -20, 0, 16); qStatTimeRolls.Position = UDim2.new(0, 12, 0, 8)
qStatTimeRolls.BackgroundTransparency = 1; qStatTimeRolls.FontFace = FontBold; qStatTimeRolls.TextSize = 11
qStatTimeRolls.TextColor3 = Theme.TextPrimary; qStatTimeRolls.TextXAlignment = Enum.TextXAlignment.Left
qStatTimeRolls.Text = "TIME: 00:00:00  |  ROLLS: 0"; qStatTimeRolls.ZIndex = 8004; qStatTimeRolls.Parent = afkQuickStatsBox

local qStatEconomy = Instance.new("TextLabel")
qStatEconomy.Size = UDim2.new(1, -20, 0, 16); qStatEconomy.Position = UDim2.new(0, 12, 0, 26)
qStatEconomy.BackgroundTransparency = 1; qStatEconomy.FontFace = FontBold; qStatEconomy.TextSize = 11
qStatEconomy.TextColor3 = Theme.AccentBlue; qStatEconomy.TextXAlignment = Enum.TextXAlignment.Left
qStatEconomy.Text = "CASH: $0  |  CANDY: 0  |  PUMPKIN: 0"; qStatEconomy.ZIndex = 8004; qStatEconomy.Parent = afkQuickStatsBox

local qStatItemsLogged = Instance.new("TextLabel")
qStatItemsLogged.Size = UDim2.new(1, -20, 0, 14); qStatItemsLogged.Position = UDim2.new(0, 12, 0, 44)
qStatItemsLogged.BackgroundTransparency = 1; qStatItemsLogged.FontFace = FontMedium; qStatItemsLogged.TextSize = 10
qStatItemsLogged.TextColor3 = Theme.OnlineGreen; qStatItemsLogged.TextXAlignment = Enum.TextXAlignment.Left
qStatItemsLogged.Text = "Backpack Items Logged: 0"; qStatItemsLogged.ZIndex = 8004; qStatItemsLogged.Parent = afkQuickStatsBox

-- 3. Main Central Panel: LIVE INVENTORY & DROPS FEED (Height: 334px)
local feedCard = Instance.new("Frame")
feedCard.Name = "LiveFeedCard"
feedCard.Size = UDim2.new(1, -32, 0, 334)
feedCard.Position = UDim2.new(0, 16, 0, 130)
feedCard.BackgroundColor3 = Theme.CardBg
feedCard.BorderSizePixel = 0
feedCard.ZIndex = 8002
feedCard.Parent = afkHud
do
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 8); fc.Parent = feedCard
	local fs = Instance.new("UIStroke"); fs.Color = Theme.Stroke; fs.Thickness = 1; fs.Parent = feedCard
end

-- Feed Header Bar
local feedHdr = Instance.new("Frame")
feedHdr.Size = UDim2.new(1, 0, 0, 32)
feedHdr.Position = UDim2.new(0, 0, 0, 0)
feedHdr.BackgroundTransparency = 1
feedHdr.ZIndex = 8003
feedHdr.Parent = feedCard

local feedTitleIcon = createCustomSvgIcon(feedHdr, "backpack", 15, Theme.AccentBlue, UDim2.new(0, 12, 0.5, -7))

local feedTitle = Instance.new("TextLabel")
feedTitle.Size = UDim2.new(0.5, 0, 1, 0); feedTitle.Position = UDim2.new(0, 34, 0, 0)
feedTitle.BackgroundTransparency = 1; feedTitle.FontFace = FontBold; feedTitle.TextSize = 11
feedTitle.TextColor3 = Theme.AccentBlue; feedTitle.TextXAlignment = Enum.TextXAlignment.Left
feedTitle.Text = "LIVE INVENTORY & BACKPACK DROPS FEED"; feedTitle.ZIndex = 8004; feedTitle.Parent = feedHdr

local feedSubtitle = Instance.new("TextLabel")
feedSubtitle.Size = UDim2.new(0.45, 0, 1, 0); feedSubtitle.Position = UDim2.new(0.55, -12, 0, 0)
feedSubtitle.BackgroundTransparency = 1; feedSubtitle.FontFace = FontMedium; feedSubtitle.TextSize = 10
feedSubtitle.TextColor3 = Theme.TextMuted; feedSubtitle.TextXAlignment = Enum.TextXAlignment.Right
feedSubtitle.Text = "Sorted: Rarest to Easiest (High Rarity at Top)"; feedSubtitle.ZIndex = 8004; feedSubtitle.Parent = feedHdr

local feedDivider = Instance.new("Frame")
feedDivider.Size = UDim2.new(1, 0, 0, 1); feedDivider.Position = UDim2.new(0, 0, 0, 32)
feedDivider.BackgroundColor3 = Theme.Stroke; feedDivider.BorderSizePixel = 0
feedDivider.ZIndex = 8003; feedDivider.Parent = feedCard

local feedScrollFrame = Instance.new("ScrollingFrame")
feedScrollFrame.Name = "FeedScrollFrame"
feedScrollFrame.Size = UDim2.new(1, -16, 1, -40)
feedScrollFrame.Position = UDim2.new(0, 8, 0, 36)
feedScrollFrame.BackgroundTransparency = 1
feedScrollFrame.BorderSizePixel = 0
feedScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
feedScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
feedScrollFrame.ScrollBarThickness = 4
feedScrollFrame.ScrollBarImageColor3 = Theme.AccentBlue
feedScrollFrame.ZIndex = 8003
feedScrollFrame.Parent = feedCard

local feedLayout = Instance.new("UIListLayout")
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feedScrollFrame

local emptyNotice = Instance.new("TextLabel")
emptyNotice.Size = UDim2.new(1, -20, 0, 60)
emptyNotice.Position = UDim2.new(0, 10, 0, 30)
emptyNotice.BackgroundTransparency = 1
emptyNotice.FontFace = FontMedium
emptyNotice.TextSize = 12
emptyNotice.TextColor3 = Theme.TextMuted
emptyNotice.TextXAlignment = Enum.TextXAlignment.Center
emptyNotice.Text = "Awaiting items entering backpack... All drops, gems, potions, and traits will stack here live."
emptyNotice.ZIndex = 8004
emptyNotice.Parent = feedScrollFrame

-- 4. Bottom Action Bar (Height: 44px)
local afkBottom = Instance.new("Frame")
afkBottom.Size = UDim2.new(1, -32, 0, 44)
afkBottom.Position = UDim2.new(0, 16, 0, 470)
afkBottom.BackgroundColor3 = Theme.SidebarBg
afkBottom.BorderSizePixel = 0
afkBottom.ZIndex = 8002
afkBottom.Parent = afkHud

do
	local btc = Instance.new("UICorner"); btc.CornerRadius = UDim.new(0, 8); btc.Parent = afkBottom
	local bts = Instance.new("UIStroke"); bts.Color = Theme.Stroke; bts.Thickness = 1; bts.Parent = afkBottom
end

local gpuDot = Instance.new("Frame")
gpuDot.Size = UDim2.new(0, 7, 0, 7); gpuDot.Position = UDim2.new(0, 14, 0.5, -3)
gpuDot.BackgroundColor3 = Theme.OnlineGreen; gpuDot.BorderSizePixel = 0; gpuDot.ZIndex = 8003; gpuDot.Parent = afkBottom
do local gdc = Instance.new("UICorner"); gdc.CornerRadius = UDim.new(1, 0); gdc.Parent = gpuDot end

local gpuSaverLbl = Instance.new("TextLabel")
gpuSaverLbl.Size = UDim2.new(0.55, 0, 1, 0); gpuSaverLbl.Position = UDim2.new(0, 28, 0, 0)
gpuSaverLbl.BackgroundTransparency = 1; gpuSaverLbl.FontFace = FontMedium; gpuSaverLbl.TextSize = 11
gpuSaverLbl.TextColor3 = Theme.TextMuted; gpuSaverLbl.TextXAlignment = Enum.TextXAlignment.Left
gpuSaverLbl.Text = "GPU Saver Active: 3D View Suspended (~0% GPU)"; gpuSaverLbl.ZIndex = 8003; gpuSaverLbl.Parent = afkBottom

local resumeBtn = Instance.new("TextButton")
resumeBtn.Size = UDim2.new(0, 180, 0, 30); resumeBtn.Position = UDim2.new(1, -188, 0.5, -15)
resumeBtn.BackgroundColor3 = Theme.ActiveTabBg; resumeBtn.BorderSizePixel = 0
resumeBtn.FontFace = FontBold; resumeBtn.TextSize = 12; resumeBtn.TextColor3 = Theme.TextPrimary
resumeBtn.Text = "Resume Normal View"; resumeBtn.AutoButtonColor = false
resumeBtn.ZIndex = 8003; resumeBtn.Parent = afkBottom
do
	local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(0, 6); rbc.Parent = resumeBtn
	local rbs = Instance.new("UIStroke"); rbs.Color = Theme.ActiveStroke; rbs.Thickness = 1; rbs.Parent = resumeBtn
end

resumeBtn.MouseEnter:Connect(function()
	TweenService:Create(resumeBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.AccentDeep }):Play()
end)
resumeBtn.MouseLeave:Connect(function()
	TweenService:Create(resumeBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ActiveTabBg }):Play()
end)

-- Item Visual Resolver: Maps item names and attributes to Asset IDs, Rarity Colors, and Categories
local STATIC_TRAITS_MAP: { [string]: { image: string, color: Color3 } } = {
	["Money I"] = { image = "rbxassetid://70874047229796", color = Color3.fromRGB(62, 247, 130) },
	["Money II"] = { image = "rbxassetid://70874047229796", color = Color3.fromRGB(62, 247, 130) },
	["Money III"] = { image = "rbxassetid://70874047229796", color = Color3.fromRGB(62, 247, 130) },
	["Damage I"] = { image = "rbxassetid://131558804248228", color = Color3.fromRGB(62, 232, 247) },
	["Damage II"] = { image = "rbxassetid://131558804248228", color = Color3.fromRGB(62, 232, 247) },
	["Damage III"] = { image = "rbxassetid://131558804248228", color = Color3.fromRGB(62, 232, 247) },
	["Health I"] = { image = "rbxassetid://133414513790368", color = Color3.fromRGB(247, 62, 62) },
	["Health II"] = { image = "rbxassetid://133414513790368", color = Color3.fromRGB(247, 62, 62) },
	["Health III"] = { image = "rbxassetid://133414513790368", color = Color3.fromRGB(247, 62, 62) },
	["Samurai"] = { image = "rbxassetid://109755978073160", color = Color3.fromRGB(255, 100, 200) },
	["Shogun"] = { image = "rbxassetid://107848009601242", color = Color3.fromRGB(255, 180, 50) },
	["Monarch"] = { image = "rbxassetid://94472950521546", color = Color3.fromRGB(255, 215, 0) },
	["Transcendent"] = { image = "rbxassetid://94482517013105", color = Color3.fromRGB(168, 85, 247) },
	["Eternal"] = { image = "rbxassetid://80533862199326", color = Color3.fromRGB(236, 72, 153) },
	["Paradox"] = { image = "rbxassetid://76606151010034", color = Color3.fromRGB(56, 189, 248) },
	["Genesis"] = { image = "rbxassetid://111080270382451", color = Color3.fromRGB(250, 204, 21) },
}

local STATIC_BOOSTS_MAP: { [string]: { image: string, color: Color3, category: string } } = {
	["Luck I"] = { image = "rbxassetid://126009168341802", color = Color3.fromRGB(59, 130, 246), category = "Luck Boost" },
	["Luck II"] = { image = "rbxassetid://75353331495067", color = Color3.fromRGB(147, 51, 234), category = "Luck Boost" },
	["Luck III"] = { image = "rbxassetid://92709571106091", color = Color3.fromRGB(234, 179, 8), category = "Luck Boost" },
	["Luck IV"] = { image = "rbxassetid://74528032328971", color = Color3.fromRGB(168, 85, 247), category = "Luck Boost" },
	["Damage I"] = { image = "rbxassetid://91064280744896", color = Color3.fromRGB(59, 130, 246), category = "Damage Boost" },
	["Damage II"] = { image = "rbxassetid://97991264995149", color = Color3.fromRGB(147, 51, 234), category = "Damage Boost" },
	["Damage III"] = { image = "rbxassetid://139127586148739", color = Color3.fromRGB(234, 179, 8), category = "Damage Boost" },
	["Damage IV"] = { image = "rbxassetid://124248089768913", color = Color3.fromRGB(168, 85, 247), category = "Damage Boost" },
	["Income I"] = { image = "rbxassetid://72776880170280", color = Color3.fromRGB(59, 130, 246), category = "Income Boost" },
	["Income II"] = { image = "rbxassetid://88337416473582", color = Color3.fromRGB(147, 51, 234), category = "Income Boost" },
	["Income III"] = { image = "rbxassetid://100967496166946", color = Color3.fromRGB(234, 179, 8), category = "Income Boost" },
	["Income IV"] = { image = "rbxassetid://71030031819395", color = Color3.fromRGB(168, 85, 247), category = "Income Boost" },
	["Dragon Luck I"] = { image = "rbxassetid://87616934203950", color = Color3.fromRGB(59, 130, 246), category = "Dragon Luck Boost" },
	["Dragon Luck II"] = { image = "rbxassetid://99863437690202", color = Color3.fromRGB(147, 51, 234), category = "Dragon Luck Boost" },
	["Dragon Luck III"] = { image = "rbxassetid://86490467990819", color = Color3.fromRGB(234, 179, 8), category = "Dragon Luck Boost" },
	["Dragon Income I"] = { image = "rbxassetid://91319131683884", color = Color3.fromRGB(59, 130, 246), category = "Dragon Income Boost" },
	["Dragon Income II"] = { image = "rbxassetid://92752999565075", color = Color3.fromRGB(147, 51, 234), category = "Dragon Income Boost" },
	["Dragon Income III"] = { image = "rbxassetid://83934872161149", color = Color3.fromRGB(234, 179, 8), category = "Dragon Income Boost" },
	["Dragon Damage I"] = { image = "rbxassetid://103618586298967", color = Color3.fromRGB(59, 130, 246), category = "Dragon Damage Boost" },
	["Dragon Damage II"] = { image = "rbxassetid://75738046060321", color = Color3.fromRGB(147, 51, 234), category = "Dragon Damage Boost" },
	["Dragon Damage III"] = { image = "rbxassetid://114909463872265", color = Color3.fromRGB(234, 179, 8), category = "Dragon Damage Boost" },
	["Cursed Luck I"] = { image = "rbxassetid://100506001615475", color = Color3.fromRGB(59, 130, 246), category = "Cursed Luck Boost" },
	["Cursed Luck II"] = { image = "rbxassetid://98368833852227", color = Color3.fromRGB(147, 51, 234), category = "Cursed Luck Boost" },
	["Cursed Luck III"] = { image = "rbxassetid://138327799553970", color = Color3.fromRGB(234, 179, 8), category = "Cursed Luck Boost" },
	["Cursed Damage I"] = { image = "rbxassetid://74314181400095", color = Color3.fromRGB(59, 130, 246), category = "Cursed Damage Boost" },
	["Cursed Damage II"] = { image = "rbxassetid://73729220272647", color = Color3.fromRGB(147, 51, 234), category = "Cursed Damage Boost" },
	["Cursed Damage III"] = { image = "rbxassetid://116840238545552", color = Color3.fromRGB(234, 179, 8), category = "Cursed Damage Boost" },
	["Cursed Income I"] = { image = "rbxassetid://102272409484179", color = Color3.fromRGB(59, 130, 246), category = "Cursed Income Boost" },
	["Cursed Income II"] = { image = "rbxassetid://118683090847343", color = Color3.fromRGB(147, 51, 234), category = "Cursed Income Boost" },
	["Cursed Income III"] = { image = "rbxassetid://132182466275117", color = Color3.fromRGB(234, 179, 8), category = "Cursed Income Boost" },
	["Pirate Luck I"] = { image = "rbxassetid://87647792270354", color = Color3.fromRGB(59, 130, 246), category = "Pirate Luck Boost" },
	["Pirate Luck II"] = { image = "rbxassetid://88524601819688", color = Color3.fromRGB(147, 51, 234), category = "Pirate Luck Boost" },
	["Pirate Luck III"] = { image = "rbxassetid://81131117349638", color = Color3.fromRGB(234, 179, 8), category = "Pirate Luck Boost" },
	["Pirate Damage I"] = { image = "rbxassetid://110474297461834", color = Color3.fromRGB(59, 130, 246), category = "Pirate Damage Boost" },
	["Pirate Damage II"] = { image = "rbxassetid://120039777861808", color = Color3.fromRGB(147, 51, 234), category = "Pirate Damage Boost" },
	["Pirate Damage III"] = { image = "rbxassetid://100395451538949", color = Color3.fromRGB(234, 179, 8), category = "Pirate Damage Boost" },
	["Pirate Income I"] = { image = "rbxassetid://134454684564051", color = Color3.fromRGB(59, 130, 246), category = "Pirate Income Boost" },
	["Pirate Income II"] = { image = "rbxassetid://75058558364274", color = Color3.fromRGB(147, 51, 234), category = "Pirate Income Boost" },
	["Pirate Income III"] = { image = "rbxassetid://138611133430140", color = Color3.fromRGB(234, 179, 8), category = "Pirate Income Boost" },
	["Leaf Luck I"] = { image = "rbxassetid://81375812736333", color = Color3.fromRGB(59, 130, 246), category = "Leaf Luck Boost" },
	["Leaf Luck II"] = { image = "rbxassetid://107900801454860", color = Color3.fromRGB(147, 51, 234), category = "Leaf Luck Boost" },
	["Leaf Luck III"] = { image = "rbxassetid://120778051194708", color = Color3.fromRGB(234, 179, 8), category = "Leaf Luck Boost" },
	["Leaf Damage I"] = { image = "rbxassetid://139901293809137", color = Color3.fromRGB(59, 130, 246), category = "Leaf Damage Boost" },
	["Leaf Damage II"] = { image = "rbxassetid://101841030954042", color = Color3.fromRGB(147, 51, 234), category = "Leaf Damage Boost" },
	["Leaf Damage III"] = { image = "rbxassetid://116745926384748", color = Color3.fromRGB(234, 179, 8), category = "Leaf Damage Boost" },
	["Leaf Income I"] = { image = "rbxassetid://120199096197634", color = Color3.fromRGB(59, 130, 246), category = "Leaf Income Boost" },
	["Leaf Income II"] = { image = "rbxassetid://135769032673258", color = Color3.fromRGB(147, 51, 234), category = "Leaf Income Boost" },
	["Leaf Income III"] = { image = "rbxassetid://84242998508765", color = Color3.fromRGB(234, 179, 8), category = "Leaf Income Boost" },
	["Slayer Luck I"] = { image = "rbxassetid://116585279235730", color = Color3.fromRGB(59, 130, 246), category = "Slayer Luck Boost" },
	["Slayer Luck II"] = { image = "rbxassetid://110215189910403", color = Color3.fromRGB(147, 51, 234), category = "Slayer Luck Boost" },
	["Slayer Luck III"] = { image = "rbxassetid://118240903204500", color = Color3.fromRGB(234, 179, 8), category = "Slayer Luck Boost" },
	["Slayer Damage I"] = { image = "rbxassetid://125575626198323", color = Color3.fromRGB(59, 130, 246), category = "Slayer Damage Boost" },
	["Slayer Damage II"] = { image = "rbxassetid://103841993089758", color = Color3.fromRGB(147, 51, 234), category = "Slayer Damage Boost" },
	["Slayer Damage III"] = { image = "rbxassetid://82137546772010", color = Color3.fromRGB(234, 179, 8), category = "Slayer Damage Boost" },
	["Slayer Income I"] = { image = "rbxassetid://87689706812810", color = Color3.fromRGB(59, 130, 246), category = "Slayer Income Boost" },
	["Slayer Income II"] = { image = "rbxassetid://100533784344078", color = Color3.fromRGB(147, 51, 234), category = "Slayer Income Boost" },
	["Slayer Income III"] = { image = "rbxassetid://87366684529105", color = Color3.fromRGB(234, 179, 8), category = "Slayer Income Boost" },
	["Shadow Luck I"] = { image = "rbxassetid://78701399340266", color = Color3.fromRGB(59, 130, 246), category = "Shadow Luck Boost" },
	["Shadow Luck II"] = { image = "rbxassetid://103856152314967", color = Color3.fromRGB(147, 51, 234), category = "Shadow Luck Boost" },
	["Shadow Luck III"] = { image = "rbxassetid://75734267140538", color = Color3.fromRGB(234, 179, 8), category = "Shadow Luck Boost" },
	["Shadow Luck IV"] = { image = "rbxassetid://94296630318833", color = Color3.fromRGB(168, 85, 247), category = "Shadow Luck Boost" },
	["Shadow Speed I"] = { image = "rbxassetid://79674741859925", color = Color3.fromRGB(59, 130, 246), category = "Shadow Speed Boost" },
	["Shadow Speed II"] = { image = "rbxassetid://85024556032727", color = Color3.fromRGB(147, 51, 234), category = "Shadow Speed Boost" },
	["Shadow Speed III"] = { image = "rbxassetid://111681475094233", color = Color3.fromRGB(234, 179, 8), category = "Shadow Speed Boost" },
	["Shadow Speed IV"] = { image = "rbxassetid://102340763188146", color = Color3.fromRGB(168, 85, 247), category = "Shadow Speed Boost" },
	["Shadow Income I"] = { image = "rbxassetid://77076474324258", color = Color3.fromRGB(59, 130, 246), category = "Shadow Income Boost" },
	["Shadow Income II"] = { image = "rbxassetid://88200233448907", color = Color3.fromRGB(147, 51, 234), category = "Shadow Income Boost" },
	["Shadow Income III"] = { image = "rbxassetid://93205591268313", color = Color3.fromRGB(234, 179, 8), category = "Shadow Income Boost" },
	["Shadow Income IV"] = { image = "rbxassetid://108245763440733", color = Color3.fromRGB(168, 85, 247), category = "Shadow Income Boost" },
}

local STATIC_ITEMS_MAP: { [string]: { image: string, color: Color3, category: string } } = {
	["Candy"] = { image = "rbxassetid://120877992828065", color = Color3.fromRGB(249, 115, 22), category = "Halloween Token" },
	["Wrapped Candy"] = { image = "rbxassetid://120877992828065", color = Color3.fromRGB(249, 115, 22), category = "Halloween Token" },
	["Pumpkins"] = { image = "rbxassetid://80162736209889", color = Color3.fromRGB(234, 88, 12), category = "Event Currency" },
	["Pumpkin"] = { image = "rbxassetid://80162736209889", color = Color3.fromRGB(234, 88, 12), category = "Event Currency" },
	["Candy Corn"] = { image = "rbxassetid://132107252624406", color = Color3.fromRGB(255, 205, 90), category = "Event Item" },
	["Treat Bag"] = { image = "rbxassetid://92943944224011", color = Color3.fromRGB(255, 140, 30), category = "Event Item" },
	["Mega Haul"] = { image = "rbxassetid://125957632952702", color = Color3.fromRGB(255, 215, 50), category = "Event Item" },
	["Gems"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(56, 189, 248), category = "Celestial Gem" },
	["Cursed Gems"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(168, 85, 247), category = "Tower Gem" },
	["Dragon Gems"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(234, 179, 8), category = "Tower Gem" },
	["Slayer Gems"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(239, 68, 68), category = "Tower Gem" },
	["Sea Gems"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(59, 130, 246), category = "Tower Gem" },
	["Shinobi Gems"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(34, 197, 94), category = "Tower Gem" },
	["Trait Reroll"] = { image = "rbxassetid://133531024200552", color = Color3.fromRGB(168, 85, 247), category = "Celestial Token" },
	["Shaman Rerolls"] = { image = "rbxassetid://133531024200552", color = Color3.fromRGB(168, 85, 247), category = "Tower Token" },
	["Tickets"] = { image = "rbxassetid://84743623119270", color = Color3.fromRGB(234, 179, 8), category = "Quest Ticket" },
	["Dragon Coins"] = { image = "rbxassetid://84743623119270", color = Color3.fromRGB(234, 179, 8), category = "Tower Token" },
	["Pirate Doubloons"] = { image = "rbxassetid://84743623119270", color = Color3.fromRGB(234, 179, 8), category = "Tower Token" },
	["Chakra Scrolls"] = { image = "rbxassetid://133531024200552", color = Color3.fromRGB(59, 130, 246), category = "Tower Token" },
	["Nichirin Ore"] = { image = "rbxassetid://84743623119270", color = Color3.fromRGB(239, 68, 68), category = "Tower Ore" },
	["Shadow Crystals"] = { image = "rbxassetid://99406696477560", color = Color3.fromRGB(147, 51, 234), category = "Tower Crystal" },
	["Reset Token"] = { image = "rbxassetid://101679148964814", color = Color3.fromRGB(239, 68, 68), category = "Token" },
	["Pumpkin Spin"] = { image = "rbxassetid://97482937162629", color = Color3.fromRGB(249, 115, 22), category = "Exotic Spin" },
	["Lucky Spin"] = { image = "rbxassetid://97482937162629", color = Color3.fromRGB(234, 179, 8), category = "Exotic Spin" },
	["Pumpkin Jackpot"] = { image = "rbxassetid://129145738343812", color = Color3.fromRGB(168, 85, 247), category = "Celestial Jackpot" },
	["Witch's Jackpot"] = { image = "rbxassetid://100241954744329", color = Color3.fromRGB(139, 92, 246), category = "Haunted Jackpot" },
	["Candy Pot I"] = { image = "rbxassetid://123977897053182", color = Color3.fromRGB(236, 72, 153), category = "Event Potion" },
	["Candy Pot II"] = { image = "rbxassetid://123977897053182", color = Color3.fromRGB(236, 72, 153), category = "Event Potion" },
	["Candy Pot III"] = { image = "rbxassetid://123977897053182", color = Color3.fromRGB(236, 72, 153), category = "Event Potion" },
	["Pumpkin Pot I"] = { image = "rbxassetid://90066474435593", color = Color3.fromRGB(249, 115, 22), category = "Event Potion" },
	["Pumpkin Pot II"] = { image = "rbxassetid://90066474435593", color = Color3.fromRGB(249, 115, 22), category = "Event Potion" },
	["Pumpkin Pot III"] = { image = "rbxassetid://90066474435593", color = Color3.fromRGB(249, 115, 22), category = "Event Potion" },
	["Haunted Potion"] = { image = "rbxassetid://115051956572391", color = Color3.fromRGB(168, 85, 247), category = "Mythical Potion" },
	["Spooky Luck I"] = { image = "rbxassetid://119447993534216", color = Color3.fromRGB(59, 130, 246), category = "Event Potion" },
	["Spooky Luck II"] = { image = "rbxassetid://127348452874831", color = Color3.fromRGB(168, 85, 247), category = "Event Potion" },
	["Spooky Luck III"] = { image = "rbxassetid://138543115145061", color = Color3.fromRGB(234, 179, 8), category = "Event Potion" },
	["Pumpkin Head"] = { image = "rbxassetid://80162736209889", color = Color3.fromRGB(234, 88, 12), category = "Haunted Gear" },
	["Mummy Wraps"] = { image = "rbxassetid://119732725297538", color = Color3.fromRGB(200, 200, 200), category = "Haunted Gear" },
	["Vampire Cape"] = { image = "rbxassetid://125389611748300", color = Color3.fromRGB(180, 40, 40), category = "Haunted Gear" },
	["Reaper's Scythe"] = { image = "rbxassetid://89778905553569", color = Color3.fromRGB(140, 40, 220), category = "Haunted Gear" },
	["Ghost Wisps"] = { image = "rbxassetid://115051956572391", color = Color3.fromRGB(100, 200, 255), category = "Haunted Gear" },
	["Candy Bucket"] = { image = "rbxassetid://92943944224011", color = Color3.fromRGB(255, 140, 30), category = "Haunted Gear" },
	["Monarch's Coat"] = { image = "", color = Color3.fromRGB(234, 179, 8), category = "Legendary Gear" },
	["Igras's Helm"] = { image = "", color = Color3.fromRGB(168, 85, 247), category = "Abyssal Gear" },
	["Jinwoo's Daggers"] = { image = "", color = Color3.fromRGB(147, 51, 234), category = "Rare Gear" },
}

local function getItemVisual(itemName: string, attributes: { [string]: any }?, customCategory: string?): (string, Color3, string)
	local pcallOk, img, col, cat = pcall(function()
		-- 1. Unit Trait Resolution
		if customCategory == "Unit Trait" and STATIC_TRAITS_MAP[itemName] then
			local t = STATIC_TRAITS_MAP[itemName]
			return t.image, t.color, "Unit Trait"
		end

		-- If it's a Unit that dropped with a trait attribute
		if attributes and attributes.trait and attributes.trait ~= "" then
			local tr = attributes.trait
			if STATIC_TRAITS_MAP[tr] then
				local t = STATIC_TRAITS_MAP[tr]
				return t.image, t.color, string.format("Unit [%s]", tr)
			end
		end

		-- 2. Dynamic EntryRegistry lookup (Game official catalog resolution first)
		local EntryReg = nil
		pcall(function()
			local invPkg = ReplicatedStorage.Framework.Features.Inventory
			if invPkg:FindFirstChild("EntryRegistry") then
				EntryReg = require(invPkg.EntryRegistry)
			end
		end)
		if EntryReg and EntryReg.getEntryConfig then
			local cfg = EntryReg.getEntryConfig(itemName)
			if cfg then
				local imgAsset = cfg.image or ""
				local r = cfg.rarity or "Common"
				local k = cfg.kind or "Item"
				local c = Theme.AccentBlue
				if r == "Celestial" or r == "Secret" or r == "Mythical" or r == "Heavenly" then
					c = Color3.fromRGB(168, 85, 247)
				elseif r == "Legendary" then
					c = Color3.fromRGB(234, 179, 8)
				elseif r == "Epic" then
					c = Color3.fromRGB(147, 51, 234)
				elseif r == "Rare" then
					c = Color3.fromRGB(59, 130, 246)
				end
				if k == "Gear" then
					return "GEAR_3D", c, string.format("%s Gear", r)
				end
				if imgAsset ~= "" then
					return imgAsset, c, string.format("%s %s", r, k)
				end
			end
		end

		-- 3. Tower Boost Potions
		if STATIC_BOOSTS_MAP[itemName] then
			local b = STATIC_BOOSTS_MAP[itemName]
			return b.image, b.color, b.category
		end

		-- 4. Core Tokens, Currencies & Event Items
		if STATIC_ITEMS_MAP[itemName] then
			local itm = STATIC_ITEMS_MAP[itemName]
			return itm.image, itm.color, itm.category
		end

		-- 5. Trait lookup if itemName matches trait
		if STATIC_TRAITS_MAP[itemName] then
			local t = STATIC_TRAITS_MAP[itemName]
			return t.image, t.color, "Unit Trait"
		end

		-- Check if it exists in Assets.Gears
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local gears = assets and assets:FindFirstChild("Gears")
		if gears and gears:FindFirstChild(itemName) then
			return "GEAR_3D", Color3.fromRGB(234, 179, 8), "Gear"
		end

		-- 6. Character / Unit Fallback with anime unit icon
		return "rbxassetid://131133222141302", Color3.fromRGB(147, 51, 234), customCategory or "Unit"
	end)

	if pcallOk and img and img ~= "" then
		return img, col, cat
	end
	return "rbxassetid://131133222141302", Color3.fromRGB(147, 51, 234), customCategory or "Item"
end
-- Stacked Item Feed System (Sorted by Rarity: Rarest to Easiest)
local feedRowMap: { [string]: {
	row: Frame,
	qtyBadge: Frame,
	qtyText: TextLabel,
	timeLbl: TextLabel,
	amount: number,
	time: string,
	rank: number,
} } = {}
local feedTieBreak = 0
local recentDropDedupe: { [string]: number } = {}

-- Helper: Compute unique item key
local function getFeedItemKey(itemName: string, attributes: { [string]: any }?): string
	if attributes and attributes.trait and attributes.trait ~= "" then
		return string.format("%s [%s]", itemName, attributes.trait)
	end
	return itemName
end

-- Helper: Calculate rarity rank for sorting (Highest/Rarest = 20, Lowest/Common = 1)
local function getItemRarityRank(itemKey: string, customCategory: string?): number
	-- 1. God Traits & High Traits
	if customCategory == "Unit Trait" or STATIC_TRAITS_MAP[itemKey] then
		if itemKey == "Genesis" then return 20
		elseif itemKey == "Paradox" then return 19
		elseif itemKey == "Eternal" then return 18
		elseif itemKey == "Transcendent" then return 17
		elseif itemKey == "Monarch" then return 16
		elseif itemKey == "Shogun" then return 15
		elseif itemKey == "Samurai" then return 14
		elseif itemKey:find("III") then return 5
		elseif itemKey:find("II") then return 4
		elseif itemKey:find("I") then return 3
		end
		return 4
	end

	-- 2. Haunted & Special Jackpots
	if (customCategory and customCategory:find("Haunted")) or itemKey:find("Witch") or itemKey:find("Haunted") then
		return 15
	end

	-- 3. Celestial Tokens, Currencies & Gems
	if (customCategory and (customCategory:find("Celestial") or customCategory:find("Gem") or customCategory:find("Tower")))
		or itemKey == "Gems" or itemKey == "Trait Reroll" or itemKey == "Tickets" or itemKey == "Reset Token"
		or itemKey:find("Gems") or itemKey:find("Reroll") or itemKey:find("Coins") or itemKey:find("Doubloon") or itemKey:find("Scroll") then
		return 12
	end

	-- 4. Exotic Spins
	if (customCategory and customCategory:find("Exotic")) or itemKey:find("Spin") or itemKey:find("Jackpot") then
		return 10
	end

	-- 5. Gear Items
	if (customCategory and customCategory:find("Gear")) or itemKey:find("Head") or itemKey:find("Wraps") or itemKey:find("Cape") or itemKey:find("Scythe") or itemKey:find("Wisps") or itemKey:find("Bucket") or itemKey:find("Coat") or itemKey:find("Helm") or itemKey:find("Daggers") then
		return 8
	end

	-- 6. Event Tokens (Candy, Pumpkins)
	if itemKey == "Pumpkins" or itemKey == "Pumpkin" or itemKey == "Candy" or itemKey == "Wrapped Candy" then
		return 7
	end

	-- 7. Boost Potions by Tier
	if itemKey:find(" IV") or (customCategory and customCategory:find("Mythical")) then
		return 6 -- Mythical
	elseif itemKey:find(" III") or (customCategory and customCategory:find("Legendary")) then
		return 5 -- Legendary
	elseif itemKey:find(" II") or (customCategory and customCategory:find("Epic")) then
		return 4 -- Epic
	elseif itemKey:find(" I") or (customCategory and customCategory:find("Rare")) then
		return 3 -- Rare
	end

	return 2 -- Common / Default
end

-- Compute LayoutOrder: Rarest items receive lowest (most negative) order to place them at the top
local function computeRarityLayoutOrder(rank: number): number
	feedTieBreak = (feedTieBreak + 1) % 10000
	return - (rank * 100000) - feedTieBreak
end

-- Function to inject or update a stacked item row in the feed UI
local function recordFeedItemUI(itemKey: string, amt: number, img: string, col: Color3, cat: string, timeStr: string)
	if not feedScrollFrame then return end
	if emptyNotice and emptyNotice.Visible then
		emptyNotice.Visible = false
	end

	local rank = getItemRarityRank(itemKey, cat)
	local layoutOrder = computeRarityLayoutOrder(rank)

	local existing = feedRowMap[itemKey]
	if existing and existing.row and existing.row.Parent then
		-- Update existing stacked row in-place
		existing.amount = existing.amount + amt
		existing.time = timeStr
		existing.rank = rank
		existing.row.LayoutOrder = layoutOrder
		existing.qtyText.Text = "x" .. formatNumber(existing.amount)
		existing.timeLbl.Text = timeStr

		-- Flash badge gently to visually indicate the stack increase
		pcall(function()
			existing.qtyBadge.BackgroundColor3 = Color3.fromRGB(30, 70, 45)
			task.delay(0.35, function()
				if existing and existing.qtyBadge and existing.qtyBadge.Parent then
					existing.qtyBadge.BackgroundColor3 = Theme.BadgeBg
				end
			end)
		end)
		return
	end

	-- Create new stacked item row
	local row = Instance.new("Frame")
	row.Name = "DropItem_" .. string.gsub(itemKey, "[^%w_]", "_")
	row.Size = UDim2.new(1, -6, 0, 44)
	row.BackgroundColor3 = Theme.CardBg
	row.BorderSizePixel = 0
	row.ZIndex = 8004
	row.LayoutOrder = layoutOrder
	row.Parent = feedScrollFrame

	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row
	local rs = Instance.new("UIStroke"); rs.Color = Theme.Stroke; rs.Thickness = 1; rs.Parent = row

	-- Icon Box (32x32)
	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, 32, 0, 32)
	iconBox.Position = UDim2.new(0, 6, 0.5, -16)
	iconBox.BackgroundColor3 = Theme.ControlBg
	iconBox.BorderSizePixel = 0
	iconBox.ZIndex = 8005
	iconBox.Parent = row
	local ibc = Instance.new("UICorner"); ibc.CornerRadius = UDim.new(0, 6); ibc.Parent = iconBox
	local ibs = Instance.new("UIStroke"); ibs.Color = col or Theme.Stroke; ibs.Thickness = 1; ibs.Parent = iconBox

	local rendered3D = false
	pcall(function()
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local gears = assets and assets:FindFirstChild("Gears")
		local gearTemplate = gears and gears:FindFirstChild(itemKey)
		if gearTemplate or img == "GEAR_3D" then
			local targetTemplate = gearTemplate or (gears and gears:FindFirstChild(itemKey))
			if targetTemplate then
				local vp = Instance.new("ViewportFrame")
				vp.Size = UDim2.new(1, -4, 1, -4)
				vp.Position = UDim2.new(0, 2, 0, 2)
				vp.BackgroundTransparency = 1
				vp.Ambient = Color3.fromRGB(180, 180, 180)
				vp.LightColor = Color3.fromRGB(255, 255, 255)
				vp.LightDirection = Vector3.new(-0.35, -1, -0.75)
				vp.ZIndex = 8006
				vp.Parent = iconBox

				local model = Instance.new("Model")
				for _, desc in ipairs(targetTemplate:GetDescendants()) do
					if desc:IsA("BasePart") then
						local partClone = desc:Clone()
						partClone.Anchored = true
						partClone.CanCollide = false
						partClone.CFrame = desc.CFrame
						partClone.Parent = model
						if not model.PrimaryPart then
							model.PrimaryPart = partClone
						end
					end
				end
				model.Parent = vp

				local cam = Instance.new("Camera")
				cam.FieldOfView = 30
				cam.Parent = vp
				vp.CurrentCamera = cam

				local cf, size = model:GetBoundingBox()
				local maxDim = math.max(size.X, size.Y, size.Z)
				if maxDim < 0.1 then maxDim = 1 end
				local dist = maxDim / (2 * math.tan(math.rad(cam.FieldOfView / 2))) * 1.25
				cam.CFrame = CFrame.new(cf.Position + Vector3.new(0, 0.1, dist), cf.Position)
				rendered3D = true
			end
		end
	end)

	if not rendered3D and img and img ~= "" and img ~= "GEAR_3D" then
		local imgLbl = Instance.new("ImageLabel")
		imgLbl.Size = UDim2.new(1, -4, 1, -4)
		imgLbl.Position = UDim2.new(0, 2, 0, 2)
		imgLbl.BackgroundTransparency = 1
		imgLbl.Image = img
		imgLbl.ZIndex = 8006
		imgLbl.Parent = iconBox
	elseif not rendered3D then
		local fbDot = Instance.new("Frame")
		fbDot.Size = UDim2.new(0, 10, 0, 10)
		fbDot.Position = UDim2.new(0.5, -5, 0.5, -5)
		fbDot.BackgroundColor3 = col or Theme.AccentBlue
		fbDot.BorderSizePixel = 0
		fbDot.ZIndex = 8006
	fbDot.Parent = iconBox
		local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = fbDot
	end

	-- Text Info Stack
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.58, 0, 0, 18)
	nameLbl.Position = UDim2.new(0, 46, 0, 5)
	nameLbl.BackgroundTransparency = 1
	nameLbl.FontFace = FontBold
	nameLbl.TextSize = 13
	nameLbl.TextColor3 = Theme.TextPrimary
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Text = itemKey
	nameLbl.ZIndex = 8005
	nameLbl.Parent = row

	local catLbl = Instance.new("TextLabel")
	catLbl.Size = UDim2.new(0.58, 0, 0, 14)
	catLbl.Position = UDim2.new(0, 46, 0, 23)
	catLbl.BackgroundTransparency = 1
	catLbl.FontFace = FontMedium
	catLbl.TextSize = 10
	catLbl.TextColor3 = col or Theme.TextMuted
	catLbl.TextXAlignment = Enum.TextXAlignment.Left
	catLbl.TextTruncate = Enum.TextTruncate.AtEnd
	catLbl.Text = cat
	catLbl.ZIndex = 8005
	catLbl.Parent = row

	-- Quantity Badge (e.g. x1, x2, x10)
	local qtyBadge = Instance.new("Frame")
	qtyBadge.Size = UDim2.new(0, 58, 0, 24)
	qtyBadge.Position = UDim2.new(1, -125, 0.5, -12)
	qtyBadge.BackgroundColor3 = Theme.BadgeBg
	qtyBadge.BorderSizePixel = 0
	qtyBadge.ZIndex = 8005
	qtyBadge.Parent = row
	local qbc = Instance.new("UICorner"); qbc.CornerRadius = UDim.new(0, 5); qbc.Parent = qtyBadge
	local qbs = Instance.new("UIStroke"); qbs.Color = Theme.ActiveStroke; qbs.Thickness = 1; qbs.Parent = qtyBadge

	local qtyText = Instance.new("TextLabel")
	qtyText.Size = UDim2.new(1, 0, 1, 0)
	qtyText.BackgroundTransparency = 1
	qtyText.FontFace = FontBold
	qtyText.TextSize = 11
	qtyText.TextColor3 = Theme.OnlineGreen
	qtyText.Text = "x" .. formatNumber(amt)
	qtyText.ZIndex = 8006
	qtyText.Parent = qtyBadge

	-- Time text
	local timeLbl = Instance.new("TextLabel")
	timeLbl.Size = UDim2.new(0, 55, 1, 0)
	timeLbl.Position = UDim2.new(1, -62, 0, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.FontFace = FontMedium
	timeLbl.TextSize = 10
	timeLbl.TextColor3 = Theme.TextMuted
	timeLbl.TextXAlignment = Enum.TextXAlignment.Right
	timeLbl.Text = timeStr
	timeLbl.ZIndex = 8005
	timeLbl.Parent = row

	feedRowMap[itemKey] = {
		row = row,
		qtyBadge = qtyBadge,
		qtyText = qtyText,
		timeLbl = timeLbl,
		amount = amt,
		time = timeStr,
		rank = rank,
	}

	-- Keep maximum 100 unique item rows in DOM
	local count = 0
	for _ in pairs(feedRowMap) do count = count + 1 end
	if count > 100 then
		local oldestKey = nil
		local maxOrder = -math.huge
		for k, v in pairs(feedRowMap) do
			if v.row and v.row.LayoutOrder > maxOrder then
				maxOrder = v.row.LayoutOrder
				oldestKey = k
			end
		end
		if oldestKey and feedRowMap[oldestKey] then
			pcall(function() feedRowMap[oldestKey].row:Destroy() end)
			feedRowMap[oldestKey] = nil
		end
	end
end

-- Central Recorder for Acquired Items (Stacked View)
RtState.RecordAcquiredItem = function(itemName: string, amount: number?, attributes: { [string]: any }?, customCategory: string?)
	if not itemName or itemName == "" or itemName == "EntryTemplate" then return end
	local amt = math.max(1, amount or 1)
	local itemKey = getFeedItemKey(itemName, attributes)
	local nowClock = os.clock()

	-- 0.15s deduplication protection against simultaneous duplicate engine hooks
	local dedupeKey = string.format("%s_%d", itemKey, amt)
	if recentDropDedupe[dedupeKey] and (nowClock - recentDropDedupe[dedupeKey]) < 0.15 then
		return
	end
	recentDropDedupe[dedupeKey] = nowClock

	local img, col, cat = getItemVisual(itemName, attributes, customCategory)
	local timeStr = os.date("%H:%M:%S")

	RtState.SessionStats.TotalItemsAcquired = (RtState.SessionStats.TotalItemsAcquired or 0) + amt

	-- Maintain session stats stacked table
	local foundEntry = nil
	for _, entry in ipairs(RtState.SessionStats.AcquiredItemsFeed) do
		if entry.key == itemKey then
			foundEntry = entry
			break
		end
	end
	if foundEntry then
		foundEntry.amount = foundEntry.amount + amt
		foundEntry.time = timeStr
		foundEntry.timestamp = nowClock
	else
		local entry = {
			key = itemKey,
			name = itemKey,
			amount = amt,
			image = img,
			category = cat,
			color = col,
			time = timeStr,
			timestamp = nowClock,
		}
		table.insert(RtState.SessionStats.AcquiredItemsFeed, 1, entry)
		if #RtState.SessionStats.AcquiredItemsFeed > 100 then
			table.remove(RtState.SessionStats.AcquiredItemsFeed, 101)
		end
	end

	pcall(function()
		recordFeedItemUI(itemKey, amt, img, col, cat, timeStr)
		if qStatItemsLogged then
			qStatItemsLogged.Text = string.format("Backpack Items Logged: %s", formatNumber(RtState.SessionStats.TotalItemsAcquired or 0))
		end
	end)
end

-- Global Hook: Intercept TowerRewards and auto-collect drops into Live Feed without screen freeze
pcall(function()
	local feat = ReplicatedStorage:FindFirstChild("Framework") and ReplicatedStorage.Framework:FindFirstChild("Features")
	local uiMod = feat and feat:FindFirstChild("UI")
	local MenuController = uiMod and uiMod:FindFirstChild("MenuController") and require(uiMod.MenuController)
	local UIReferences = uiMod and uiMod:FindFirstChild("UIReferences") and require(uiMod.UIReferences)
	local notifs = feat and feat:FindFirstChild("Notifications")
	local EntryDropCtrl = notifs and notifs:FindFirstChild("EntryDropController") and require(notifs.EntryDropController)

	if MenuController and MenuController.OpenMenu and not MenuController._serennityTowerHooked then
		local origOpen = MenuController.OpenMenu
		MenuController._serennityTowerHooked = true
		-- Helper: Map EntryIcon image/model to actual item name
		local function resolveRewardItemInfo(iconObj: Instance): (string?, number)
			local realName = nil
			local amt = 1

			-- Read quantity
			local topLbl = iconObj:FindFirstChild("TopLabel") or iconObj:FindFirstChild("Amount", true) or iconObj:FindFirstChild("Count", true)
			if topLbl and topLbl:IsA("TextLabel") and topLbl.Text ~= "" then
				local n = tostring(topLbl.Text):match("(%d+)")
				if n then amt = tonumber(n) or 1 end
			end

			-- Match 3D model in ViewportFrame (Units/Gear)
			local vp = iconObj:FindFirstChild("ViewportFrame")
			if vp then
				for _, ch in ipairs(vp:GetChildren()) do
					if ch:IsA("Model") and ch.Name ~= "WorldModel" and ch.Name ~= "" and ch.Name ~= "EntryTemplate" then
						realName = ch.Name
						break
					end
				end
			end

			-- Match Image asset to EntryRegistry
			if not realName or realName == "EntryTemplate" then
				local imgLbl = iconObj:FindFirstChild("ImageLabel") or iconObj:FindFirstChildOfClass("ImageLabel")
				if imgLbl and imgLbl.Image and imgLbl.Image ~= "" then
					local targetImg = tostring(imgLbl.Image)
					pcall(function()
						local reg = require(ReplicatedStorage.Framework.Features.Inventory.EntryRegistry)
						for eName, eData in pairs(reg.allEntries()) do
							if eData.image and tostring(eData.image) == targetImg then
								realName = eName
								break
							end
						end
					end)
				end
			end

			-- Check child TextLabels
			if not realName or realName == "EntryTemplate" then
				for _, desc in ipairs(iconObj:GetDescendants()) do
					if desc:IsA("TextLabel") and desc.Name ~= "TopLabel" and desc.Text ~= "" and not desc.Text:find("^x%d+") and desc.Text ~= "EntryTemplate" then
						realName = desc.Text
						break
					end
				end
			end

			return realName, amt
		end

		MenuController.OpenMenu = function(menu)
			-- Suppress Traits, Grades, Quirks, Awakening, PotionFusing popup menus
			if menu and typeof(menu) == "Instance" then
				local mName = menu.Name
				local shouldSuppress = false
				if (mName == "Traits" or mName == "Grades" or mName == "Quirks") and (Cfg.AutoRerollTrait or Cfg.AutoUpgradeGrade or Cfg.AutoRerollQuirk or Cfg.HideStationUI) then
					shouldSuppress = true
				elseif mName == "Awakening" and (Cfg.HideAwakeningUI or Cfg.AutoAwakenUnits or Cfg.AutoAwakenAllPlotUnits or RtState._isAwakeningBackground) then
					shouldSuppress = true
				elseif mName == "PotionFusing" and (Cfg.HidePotionFusingUI or Cfg.AutoFusePotions) then
					shouldSuppress = true
				end
				if shouldSuppress then
					if menu:IsA("GuiObject") then menu.Visible = false end
					task.defer(function()
						pcall(function()
							if MenuController.ActiveMenu and MenuController.ActiveMenu() == menu then
								MenuController.CloseMenu()
							end
							local cam = workspace.CurrentCamera
							local blur = cam and cam:FindFirstChild("blur")
							if blur then blur.Size = 0 end
							local cc = cam and cam:FindFirstChild("cc")
							if cc then cc.Brightness = 0 end
							local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
							local rMenus = pg and pg:FindFirstChild("Root") and pg.Root:FindFirstChild("Menus")
							local cover = rMenus and rMenus:FindFirstChild("Cover")
							if cover then
								cover.Visible = false
								cover.BackgroundTransparency = 1
							end
						end)
					end)
					return
				end
			end

			if (Cfg.AutoPlayTower or Cfg.AutoTowerQueue or Cfg.AutoPlayEventTower or Cfg.AutoEventTowerQueue) and menu and typeof(menu) == "Instance" and menu.Name == "TowerRewards" then
				if menu:IsA("GuiObject") then menu.Visible = false end
				RtState._towerFinishedSignal = os.clock()
				pcall(function()
					if menu:FindFirstChild("Content") and menu.Content:FindFirstChild("ScrollingFrame") then
						for _, item in ipairs(menu.Content.ScrollingFrame:GetChildren()) do
							if item:IsA("GuiObject") and item.Name ~= "UIGridLayout" and item.Name ~= "UIPadding" then
								local rName, rAmt = resolveRewardItemInfo(item)
								if rName and rName ~= "" and rName ~= "EntryTemplate" then
									task.spawn(function()
										pcall(function()
											if RtState and RtState.RecordAcquiredItem then
												RtState.RecordAcquiredItem(rName, rAmt, nil, "Tower Drop")
											end
											if RtState and RtState.RecordTowerSessionDrop then
												RtState.RecordTowerSessionDrop(rName, rAmt)
											end
											if RtState and RtState.RecordEventTowerSessionDrop then
												RtState.RecordEventTowerSessionDrop(rName, rAmt)
											end
										end)
									end)
								end
							end
						end
					end
				end)
				task.delay(0.5, function()
					pcall(function()
						if MenuController.ActiveMenu and MenuController.ActiveMenu() == menu then
							MenuController.CloseMenu()
						end
					end)
				end)
				return
			end
			return origOpen(menu)
		end
	end
end)

-- Global Hook: Auto-Hide In-Game Station Menus (Traits, Grades, Quirks, Awakening, PotionFusing)
pcall(function()
	local pg = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5)
	local root = pg and pg:WaitForChild("Root", 5)
	local menus = root and root:WaitForChild("Menus", 5)
	if menus then
		for _, mName in ipairs({"Traits", "Grades", "Quirks", "Awakening", "PotionFusing"}) do
			local m = menus:FindFirstChild(mName)
			if m and m:IsA("GuiObject") then
				local shouldHideInit = false
				if (mName == "Traits" or mName == "Grades" or mName == "Quirks") and (Cfg.AutoRerollTrait or Cfg.AutoUpgradeGrade or Cfg.AutoRerollQuirk or Cfg.HideStationUI) then
					shouldHideInit = true
				elseif mName == "Awakening" and (Cfg.HideAwakeningUI or Cfg.AutoAwakenUnits or Cfg.AutoAwakenAllPlotUnits or RtState._isAwakeningBackground) then
					shouldHideInit = true
				elseif mName == "PotionFusing" and (Cfg.HidePotionFusingUI or Cfg.AutoFusePotions) then
					shouldHideInit = true
				end
				if shouldHideInit and m.Visible == true then
					m.Visible = false
				end

				m:GetPropertyChangedSignal("Visible"):Connect(function()
					local shouldHide = false
					if (mName == "Traits" or mName == "Grades" or mName == "Quirks") and (Cfg.AutoRerollTrait or Cfg.AutoUpgradeGrade or Cfg.AutoRerollQuirk or Cfg.HideStationUI) then
						shouldHide = true
					elseif mName == "Awakening" and (Cfg.HideAwakeningUI or Cfg.AutoAwakenUnits or Cfg.AutoAwakenAllPlotUnits or RtState._isAwakeningBackground) then
						shouldHide = true
					elseif mName == "PotionFusing" and (Cfg.HidePotionFusingUI or Cfg.AutoFusePotions) then
						shouldHide = true
					end
					if shouldHide and m.Visible == true then
						m.Visible = false
						task.defer(function()
							pcall(function()
								local feat = ReplicatedStorage:FindFirstChild("Framework") and ReplicatedStorage.Framework:FindFirstChild("Features")
								local mc = feat and feat:FindFirstChild("UI") and feat.UI:FindFirstChild("MenuController") and require(feat.UI.MenuController)
								if mc and mc.ActiveMenu and mc.ActiveMenu() == m then
									mc.CloseMenu()
								end
								local cam = workspace.CurrentCamera
								local blur = cam and cam:FindFirstChild("blur")
								if blur then blur.Size = 0 end
								local cc = cam and cam:FindFirstChild("cc")
								if cc then cc.Brightness = 0 end
								local cover = menus and menus:FindFirstChild("Cover")
								if cover then
									cover.Visible = false
									cover.BackgroundTransparency = 1
								end
							end)
						end)
					end
				end)
			end
		end
	end
end)

-- Global Hook: Auto-Hide Tower Battle UI & 'Hide' Button completely
pcall(function()
	local pg = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5)
	local root = pg and pg:WaitForChild("Root", 5)
	local towerGui = root and root:WaitForChild("Tower", 5)
	local screen = towerGui and towerGui:FindFirstChild("Screen")
	local bg = towerGui and towerGui:FindFirstChild("Background")
	local hiddenBtn = towerGui and towerGui:FindFirstChild("Hidden")
	local feat = ReplicatedStorage:FindFirstChild("Framework") and ReplicatedStorage.Framework:FindFirstChild("Features")
	local HUDController = feat and feat:FindFirstChild("UI") and feat.UI:FindFirstChild("HUDController") and require(feat.UI.HUDController)
	local RunService = game:GetService("RunService")

	local function shouldHideTowerUI()
		return (Cfg.HideTowerBattleUI or Cfg.HideEventTowerBattleUI or Cfg.AutoTowerQueue or Cfg.AutoPlayTower or Cfg.AutoPlayEventTower or Cfg.AutoEventTowerQueue or Cfg.AutoPlayHauntedHouse or Cfg.EnableAfkDashboard)
	end

	if screen then
		screen:GetPropertyChangedSignal("Visible"):Connect(function()
			if shouldHideTowerUI() and screen.Visible == true then
				screen.Visible = false
				if HUDController and not Cfg.EnableAfkDashboard then pcall(function() HUDController.showAll("inTower") end) end
			end
		end)
	end
	if bg then
		bg:GetPropertyChangedSignal("Visible"):Connect(function()
			if shouldHideTowerUI() and bg.Visible == true then
				bg.Visible = false
				if HUDController and not Cfg.EnableAfkDashboard then pcall(function() HUDController.showAll("inTower") end) end
			end
		end)
	end
	if hiddenBtn then
		hiddenBtn:GetPropertyChangedSignal("Position"):Connect(function()
			if shouldHideTowerUI() and hiddenBtn.Position ~= UDim2.new(0, -9999, 0, -9999) then
				hiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
				hiddenBtn.Visible = false
			end
		end)
		hiddenBtn:GetPropertyChangedSignal("Visible"):Connect(function()
			if shouldHideTowerUI() and hiddenBtn.Visible == true then
				hiddenBtn.Visible = false
				hiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
			end
		end)
	end

	-- Continuous Frame Enforcement: Ensure 'Hide' button and cards are NEVER left stuck on screen
	RunService.Heartbeat:Connect(function()
		if shouldHideTowerUI() then
			if screen and screen.Visible == true then screen.Visible = false end
			if bg and bg.Visible == true then bg.Visible = false end
			if hiddenBtn then
				if hiddenBtn.Visible == true then hiddenBtn.Visible = false end
				if hiddenBtn.Position ~= UDim2.new(0, -9999, 0, -9999) then
					hiddenBtn.Position = UDim2.new(0, -9999, 0, -9999)
				end
			end
			if HUDController and not Cfg.EnableAfkDashboard then
				pcall(function() HUDController.showAll("inTower") end)
			end
		end
	end)
end)

-- Hook game's native EntryDropController to catch all live drops (Tower floor rewards, quests, etc.)
pcall(function()
	local feat = ReplicatedStorage:FindFirstChild("Framework") and ReplicatedStorage.Framework:FindFirstChild("Features")
	local notifs = feat and feat:FindFirstChild("Notifications")
	local edcMod = notifs and notifs:FindFirstChild("EntryDropController")
	if edcMod then
		local EntryDropController = require(edcMod)
		if EntryDropController and EntryDropController.Play and not EntryDropController._serennityHooked then
			local origPlay = EntryDropController.Play
			EntryDropController._serennityHooked = true
			EntryDropController.Play = function(name, amount)
				pcall(function()
					if name and name ~= "" and name ~= "EntryTemplate" then
						if RtState and RtState.RecordAcquiredItem then
							RtState.RecordAcquiredItem(name, amount, nil, "Tower Drop")
						end
						if RtState and RtState.RecordTowerSessionDrop then
							RtState.RecordTowerSessionDrop(name, amount)
						end
						if RtState and RtState.RecordEventTowerSessionDrop then
							RtState.RecordEventTowerSessionDrop(name, amount)
						end
					end
				end)
				return origPlay(name, amount)
			end
		end
	end
end)

local hiddenGameGuis: { ScreenGui } = {}
local childAddedConn: RBXScriptConnection? = nil

RtState.SetAfkDashboard = function(enabled: boolean)
	Cfg.EnableAfkDashboard = enabled
	AfkOverlay.Visible = enabled

	if RtState.MainWindow then
		RtState.MainWindow.Visible = not enabled
	end
	if RtState.FloatingBtn then
		RtState.FloatingBtn.Visible = not enabled
	end

	-- Sync toggle switch in Settings tab if available
	if AllTogglesRegistry and AllTogglesRegistry["EnableAfkDashboard"] then
		AllTogglesRegistry["EnableAfkDashboard"]:UpdateState(enabled, false)
	end

	-- Fullscreen Blackout: Hide all other ScreenGuis in PlayerGui
	if enabled then
		hiddenGameGuis = {}
		for _, ch in ipairs(PlayerGui:GetChildren()) do
			if ch:IsA("ScreenGui") and ch ~= ScreenGui and ch.Enabled == true then
				ch.Enabled = false
				table.insert(hiddenGameGuis, ch)
			end
		end
		if childAddedConn then childAddedConn:Disconnect(); childAddedConn = nil end
		childAddedConn = PlayerGui.ChildAdded:Connect(function(newChild)
			if newChild:IsA("ScreenGui") and newChild ~= ScreenGui then
				task.wait()
				if AfkOverlay.Visible == true and newChild.Enabled == true then
					newChild.Enabled = false
					table.insert(hiddenGameGuis, newChild)
				end
			end
		end)
	else
		if childAddedConn then
			childAddedConn:Disconnect()
			childAddedConn = nil
		end
		for _, ch in ipairs(hiddenGameGuis) do
			if ch and ch.Parent then
				pcall(function() ch.Enabled = true end)
			end
		end
		hiddenGameGuis = {}
	end

	-- 3D Rendering Suspension (GPU Saver)
	pcall(function()
		local RunService = game:GetService("RunService")
		RunService:Set3dRenderingEnabled(not enabled)
	end)

	notify("AFK Mode", enabled and "Pitch-black AFK Dashboard active (3D suspended)." or "Normal view and Game UIs restored.", 2.5)
end

resumeBtn.Activated:Connect(function()
	RtState.SetAfkDashboard(false)
end)

-- Live Inventory Snapshot & Watcher Engine
local lastInvSnapshot: { [string]: { name: string, amount: number, trait: string? } } = {}
local invWatcherInitialized = false

local function scanInventoryForNewDrops()
	local Framework = ReplicatedStorage:FindFirstChild("Framework")
	local Features = Framework and Framework:FindFirstChild("Features")
	local DataPkg = Features and Features:FindFirstChild("Data")
	local DC = (DataPkg and DataPkg:FindFirstChild("DataController") and require(DataPkg.DataController)) or nil
	if not DC or not DC.Inventory then return end

	pcall(function()
		local rawInv = (type(DC.Inventory) == "function" and DC.Inventory()) or DC.Inventory
		if type(rawInv) ~= "table" then return end

		for key, itemGetter in pairs(rawInv) do
			local it = (type(itemGetter) == "function" and itemGetter()) or itemGetter
			if it and type(it) == "table" and it.name then
				local curAmt = it.amount or 1
				local itAttr = it.attributes or {}
				local curTrait = itAttr.trait or ""
				local prev = lastInvSnapshot[key]

				if not invWatcherInitialized then
					lastInvSnapshot[key] = { name = it.name, amount = curAmt, trait = curTrait }
				else
					if not prev then
						RtState.RecordAcquiredItem(it.name, curAmt, itAttr)
						lastInvSnapshot[key] = { name = it.name, amount = curAmt, trait = curTrait }
					else
						if curAmt > prev.amount then
							local diff = curAmt - prev.amount
							RtState.RecordAcquiredItem(it.name, diff, itAttr)
							prev.amount = curAmt
						end
						if curTrait ~= "" and curTrait ~= prev.trait then
							RtState.RecordAcquiredItem(curTrait, 1, { trait = curTrait }, "Unit Trait")
							prev.trait = curTrait
						end
					end
				end
			end
		end
		invWatcherInitialized = true
	end)
end

-- AFK Dashboard Live Updater Thread (Every 0.4s)
task.spawn(function()
	local lastCandyVal = nil
	local lastPumpVal = nil

	while ScriptAlive do
		-- Always scan inventory so no drops are missed even if dashboard is briefly closed
		scanInventoryForNewDrops()

		-- Track Candy & Pumpkins additions
		pcall(function()
			local curCandy = (getPlayerCandy and getPlayerCandy()) or 0
			local curPump = (getPlayerPumpkins and getPlayerPumpkins()) or 0

			if lastCandyVal == nil then
				lastCandyVal = curCandy
			elseif curCandy > lastCandyVal then
				local diff = curCandy - lastCandyVal
				RtState.RecordAcquiredItem("Candy", diff, nil, "Halloween Token")
				lastCandyVal = curCandy
			end

			if lastPumpVal == nil then
				lastPumpVal = curPump
			elseif curPump > lastPumpVal then
				local diff = curPump - lastPumpVal
				RtState.RecordAcquiredItem("Pumpkins", diff, nil, "Event Currency")
				lastPumpVal = curPump
			end
		end)

		if AfkOverlay.Visible == true then
			pcall(function()
				-- 1. Format Time
				local elapsed = os.time() - (RtState.SessionStats.StartTime or os.time())
				local hrs = math.floor(elapsed / 3600)
				local mins = math.floor((elapsed % 3600) / 60)
				local secs = elapsed % 60
				local timeStr = string.format("%02d:%02d:%02d", hrs, mins, secs)

				-- 2. Rolls
				local rollsStr = formatNumber(RtState.SessionStats.TotalRolls or 0)
				qStatTimeRolls.Text = string.format("TIME: %s  |  ROLLS: %s", timeStr, rollsStr)

				-- 3. Economy (Cash, Candy & Pumpkins)
				local curCandy = (getPlayerCandy and getPlayerCandy()) or 0
				local curPump = (getPlayerPumpkins and getPlayerPumpkins()) or 0
				local Framework = ReplicatedStorage:FindFirstChild("Framework")
				local Features = Framework and Framework:FindFirstChild("Features")
				local DataPkg = Features and Features:FindFirstChild("Data")
				local DC = (DataPkg and DataPkg:FindFirstChild("DataController") and require(DataPkg.DataController)) or nil

				local curCash = (DC and DC.Money and DC.Money()) or 0
				if RtState.SessionStats.InitialMoney == nil then RtState.SessionStats.InitialMoney = curCash end
				if RtState.SessionStats.InitialCandy == nil then RtState.SessionStats.InitialCandy = curCandy end
				if RtState.SessionStats.InitialPumpkins == nil then RtState.SessionStats.InitialPumpkins = curPump end

				local dCash = math.max(0, curCash - RtState.SessionStats.InitialMoney)
				local dCandy = math.max(0, curCandy - RtState.SessionStats.InitialCandy)
				local dPump = math.max(0, curPump - RtState.SessionStats.InitialPumpkins)

				local cashFmt = (dCash > 0 and ("+" .. formatMoneyShort(dCash))) or "$0"
				local candyFmt = (dCandy > 0 and ("+" .. formatNumber(dCandy))) or "0"
				local pumpFmt = (dPump > 0 and ("+" .. formatNumber(dPump))) or "0"
				qStatEconomy.Text = string.format("CASH: %s  |  CANDY: %s  |  PUMPKIN: %s", cashFmt, candyFmt, pumpFmt)

				-- 4. Total Logged Items
				qStatItemsLogged.Text = string.format("Backpack Items Logged: %s", formatNumber(RtState.SessionStats.TotalItemsAcquired or 0))

				-- 5. Dynamic Current Activity Text
				if Cfg.AutoAwakenUnits or Cfg.AutoAwakenAllPlotUnits then
					afkActivityText.Text = "Awakening & Potions | Auto Awakening Units..."
				elseif Cfg.AutoFusePotions then
					afkActivityText.Text = "Awakening & Potions | Auto Fusing Potions..."
				elseif Cfg.AutoPlayTower or Cfg.AutoPlayEventTower then
					local isEv = Cfg.AutoPlayEventTower
					local tName = isEv and tostring(Cfg.SelectedEventTower or "Harvest Fields") or tostring(Cfg.SelectedTower or "Dragon Tower")
					local inTow, curFlr = isPlayerInTower()
					local tPrefix = isEv and "Autumn Event Towers" or "Battle Towers"
					if inTow then
						afkActivityText.Text = string.format("%s | %s [Floor %d] | Battling...", tPrefix, tName, curFlr or 1)
					else
						afkActivityText.Text = string.format("%s | %s | Equipping Team & Entering...", tPrefix, tName)
					end
				elseif Cfg.AutoRoll then
					local modeStr = Cfg.FastRoll and "Fast Roll Mode" or "Standard Speed"
					afkActivityText.Text = string.format("Auto Rolling Dice | %s | Target Rarities Configured", modeStr)
				elseif Cfg.AutoRebirth then
					local tReb = Cfg.TargetRebirth or 19
					afkActivityText.Text = string.format("Rebirth & Progression | Auto Leveling to Rebirth %d", tReb)
				else
					afkActivityText.Text = "Hub Automation Standby | Plot Farming & Passive Boosts Active"
				end
			end)
		end
		task.wait(0.4)
	end
end)

local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 270, 0, 260)
ToastContainer.Position = UDim2.new(1, -286, 1, -276)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui
do
	local tl = Instance.new("UIListLayout")
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.VerticalAlignment = Enum.VerticalAlignment.Bottom
	tl.Padding = UDim.new(0, 8)
	tl.Parent = ToastContainer
end

notify = function(title: string, msg: string, duration: number?)
	pcall(function()
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = Theme.CardBg
		card.BorderSizePixel = 0
		card.Parent = ToastContainer
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = card
		local s = Instance.new("UIStroke"); s.Color = Theme.AccentBlue; s.Thickness = 1.2; s.Parent = card
		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.new(1, -20, 0, 20); tLbl.Position = UDim2.new(0, 10, 0, 6)
		tLbl.BackgroundTransparency = 1; tLbl.FontFace = FontBold; tLbl.TextSize = 13
		tLbl.TextColor3 = Theme.AccentBlue; tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.TextTruncate = Enum.TextTruncate.AtEnd; tLbl.Text = title; tLbl.Parent = card
		local mLbl = Instance.new("TextLabel")
		mLbl.Size = UDim2.new(1, -20, 0, 22); mLbl.Position = UDim2.new(0, 10, 0, 26)
		mLbl.BackgroundTransparency = 1; mLbl.FontFace = FontMedium; mLbl.TextSize = 12
		mLbl.TextColor3 = Theme.TextSecondary; mLbl.TextXAlignment = Enum.TextXAlignment.Left
		mLbl.TextTruncate = Enum.TextTruncate.AtEnd; mLbl.Text = msg; mLbl.Parent = card
		task.delay(duration or 3, function()
			if card and card.Parent then card:Destroy() end
		end)
	end)
end

local function sendDiscordWebhookEmbed(title: string, description: string, color: number?, fields: { { name: string, value: string, inline: boolean? } }?): boolean
	local url = Cfg.WebhookUrl
	if not url or url == "" or not string.find(url, "https://") then return false end
	local payload = {
		username = "Serennity Hub • Anime Dice",
		avatar_url = "https://raw.githubusercontent.com/oc9085817-svg/icon/main/icon.png",
		embeds = {
			{
				title = title,
				description = description,
				color = color or 5793266,
				fields = fields or {},
				footer = {
					text = "Serennity Hub • Player: " .. tostring(LocalPlayer.DisplayName or LocalPlayer.Name),
				},
				timestamp = DateTime.now():ToIsoDate(),
			}
		}
	}
	local json = HttpService:JSONEncode(payload)
	local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
	if req then
		task.spawn(pcall, req, {
			Url = url,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = json,
		})
		return true
	end
	return false
end
RtState.SendDiscordWebhook = sendDiscordWebhookEmbed

-- Floating Button (Mobile + PC - Always accessible on screen for Mobile & Tablet users!)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "SerennityFloatBtn"
FloatingBtn.Size = UDim2.new(0, 52, 0, 52)
FloatingBtn.Position = UDim2.new(0, 24, 0, 24)
FloatingBtn.BackgroundColor3 = Theme.WindowBg
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Text = ""
FloatingBtn.AutoButtonColor = false
FloatingBtn.Visible = true
FloatingBtn.Parent = ScreenGui
RtState.FloatingBtn = FloatingBtn
do
	local fbCorner = Instance.new("UICorner"); fbCorner.CornerRadius = UDim.new(0, 12); fbCorner.Parent = FloatingBtn
	local fbStroke = Instance.new("UIStroke"); fbStroke.Color = Theme.AccentBlue; fbStroke.Transparency = 0.25; fbStroke.Thickness = 1.4; fbStroke.Parent = FloatingBtn
end

local CustomLogoAsset = ""
local CustomLogoContent = nil
local applyCrossPlatformLogo = nil
;(function()
	local logoFile = "serennity_logo_v4.png"
	local rgbaB64File = "serennity_logo_96x96.b64"
	local b64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local b64Lut = {}
	for i = 1, #b64Chars do
		b64Lut[string.byte(b64Chars, i)] = i - 1
	end

	-- Pure-Luau Base64 decoder (never uses crypt.base64decode because Android JNI NewStringUTF corrupts 0x00 bytes in binary PNGs!)
	local function decodeBase64Pure(b64: string): string
		local clean = string.gsub(b64, "[^%w%+%/%=]", "")
		local out = table.create(math.floor(#clean * 3 / 4))
		local outIdx = 0
		for i = 1, #clean, 4 do
			local c1, c2, c3, c4 = string.byte(clean, i, i + 3)
			local v1 = b64Lut[c1] or 0
			local v2 = b64Lut[c2] or 0
			local v3 = b64Lut[c3] or 0
			local v4 = b64Lut[c4] or 0
			local n = bit32.bor(bit32.lshift(v1, 18), bit32.lshift(v2, 12), bit32.lshift(v3, 6), v4)
			outIdx += 1
			out[outIdx] = string.char(bit32.band(bit32.rshift(n, 16), 0xFF))
			if c3 and c3 ~= 61 then
				outIdx += 1
				out[outIdx] = string.char(bit32.band(bit32.rshift(n, 8), 0xFF))
			end
			if c4 and c4 ~= 61 then
				outIdx += 1
				out[outIdx] = string.char(bit32.band(n, 0xFF))
			end
		end
		return table.concat(out)
	end

	local function buildEditableLogoContent(rawRgbaB64: string)
		local clean = string.gsub(rawRgbaB64, "[^%w%+%/%=]", "")
		local totalBytes = 96 * 96 * 4
		local buf = buffer.create(totalBytes)
		local outOffset = 0
		for i = 1, #clean, 4 do
			local c1, c2, c3, c4 = string.byte(clean, i, i + 3)
			local v1 = b64Lut[c1] or 0
			local v2 = b64Lut[c2] or 0
			local v3 = b64Lut[c3] or 0
			local v4 = b64Lut[c4] or 0
			local n = bit32.bor(bit32.lshift(v1, 18), bit32.lshift(v2, 12), bit32.lshift(v3, 6), v4)
			if outOffset < totalBytes then
				buffer.writeu8(buf, outOffset, bit32.band(bit32.rshift(n, 16), 0xFF))
				outOffset += 1
			end
			if c3 and c3 ~= 61 and outOffset < totalBytes then
				buffer.writeu8(buf, outOffset, bit32.band(bit32.rshift(n, 8), 0xFF))
				outOffset += 1
			end
			if c4 and c4 ~= 61 and outOffset < totalBytes then
				buffer.writeu8(buf, outOffset, bit32.band(n, 0xFF))
				outOffset += 1
			end
		end
		if outOffset < totalBytes then
			return nil
		end
		local AS = game:GetService("AssetService")
		local ei = AS:CreateEditableImage({ Size = Vector2.new(96, 96) })
		ei:WritePixelsBuffer(Vector2.zero, Vector2.new(96, 96), buf)
		return Content.fromObject(ei)
	end

	-- 1. Try cached EditableImage (100% native on Android, iOS, and PC without getcustomasset!)
	pcall(function()
		if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(rgbaB64File) then
			local cachedB64 = readfile(rgbaB64File)
			if type(cachedB64) == "string" and #cachedB64 >= 48000 then
				CustomLogoContent = buildEditableLogoContent(cachedB64)
			end
		end
	end)

	-- 2. Try cached getcustomasset if valid PNG (69,156 bytes) is already on disk
	if not CustomLogoContent and typeof(getcustomasset) == "function" then
		pcall(function()
			local validCached = false
			for _, candidate in ipairs({ logoFile, "serennity_logo_v3.png" }) do
				if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(candidate) then
					local raw = readfile(candidate)
					if type(raw) == "string" and #raw == 69156 and string.sub(raw, 1, 4) == "\137PNG" then
						local okA, resA = pcall(getcustomasset, candidate)
						if okA and type(resA) == "string" and resA ~= "" then
							CustomLogoAsset = resA
							validCached = true
							break
						end
					end
				end
			end
			if not validCached then
				CustomLogoAsset = ""
			end
		end)
	end

	applyCrossPlatformLogo = function(fbImg: ImageLabel, sideImg: ImageLabel)
		if CustomLogoContent then
			pcall(function()
				fbImg.ImageContent = CustomLogoContent
				sideImg.ImageContent = CustomLogoContent
			end)
			return
		end
		task.spawn(function()
			-- Download & apply native 96x96 RGBA EditableImage (works on all Android & PC executors)
			local appliedEditable = false
			pcall(function()
				local rawRgbaB64 = game:HttpGet("https://pastefy.app/cM3JgxLc/raw")
				if type(rawRgbaB64) == "string" and #rawRgbaB64 >= 48000 then
					if typeof(writefile) == "function" then
						pcall(writefile, rgbaB64File, rawRgbaB64)
					end
					local contentObj = buildEditableLogoContent(rawRgbaB64)
					if contentObj then
						CustomLogoContent = contentObj
						fbImg.ImageContent = contentObj
						sideImg.ImageContent = contentObj
						appliedEditable = true
					end
				end
			end)
			if appliedEditable then
				return
			end
			-- Fallback: pure-Luau PNG download + getcustomasset
			if typeof(getcustomasset) == "function" and CustomLogoAsset == "" then
				pcall(function()
					local rawB64 = game:HttpGet("https://pastefy.app/7Rg2zUmZ/raw")
					if type(rawB64) == "string" and #rawB64 > 1000 then
						local pngBytes = decodeBase64Pure(rawB64)
						if type(pngBytes) == "string" and #pngBytes == 69156 and string.sub(pngBytes, 1, 4) == "\137PNG" then
							if typeof(writefile) == "function" then
								pcall(writefile, logoFile, pngBytes)
							end
							local okA, resA = pcall(getcustomasset, logoFile)
							if okA and type(resA) == "string" and resA ~= "" then
								CustomLogoAsset = resA
								fbImg.Image = resA
								sideImg.Image = resA
							end
						end
					end
				end)
			end
			task.wait(0.8)
			if not fbImg.IsLoaded and not CustomLogoContent then
				createCustomSvgIcon(FloatingBtn, "raid_swords", 24, Theme.AccentBlue, UDim2.new(0.5, -12, 0.5, -12))
				createCustomSvgIcon(sideImg.Parent, "raid_swords", 28, Theme.AccentBlue, UDim2.new(0, 22, 0, 24))
			end
		end)
	end
end)()

RtState.CustomLogoAsset = CustomLogoAsset
RtState.CustomLogoContent = CustomLogoContent
RtState.ApplyCrossPlatformLogo = applyCrossPlatformLogo
local fbLogo = Instance.new("ImageLabel")
fbLogo.Name = "FloatLogo"
fbLogo.Size = UDim2.new(1, -8, 1, -8)
fbLogo.Position = UDim2.new(0, 4, 0, 4)
fbLogo.BackgroundTransparency = 1
fbLogo.ScaleType = Enum.ScaleType.Fit
fbLogo.Image = RtState.CustomLogoAsset
fbLogo.Parent = FloatingBtn

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 880, 0, 556)
MainWindow.Position = UDim2.new(0.5, -440, 0.5, -278)
MainWindow.BackgroundColor3 = Theme.WindowBg
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui
RtState.MainWindow = MainWindow
do
	local mwCorner = Instance.new("UICorner"); mwCorner.CornerRadius = UDim.new(0, 12); mwCorner.Parent = MainWindow
	local mwStroke = Instance.new("UIStroke"); mwStroke.Color = Theme.Stroke; mwStroke.Thickness = 1.2; mwStroke.Parent = MainWindow
end

local function makeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	table.insert(Connections, dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragHandle:SetAttribute("_WasDragged", false)
			dragStart = input.Position
			startPos = targetFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end))
	table.insert(Connections, dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and dragStart and startPos then
			local delta = input.Position - dragStart
			if delta.Magnitude > 14 then dragHandle:SetAttribute("_WasDragged", true) end
			local rawX = startPos.X.Offset + delta.X
			local rawY = startPos.Y.Offset + delta.Y
			local cam = workspace.CurrentCamera
			if cam and cam.ViewportSize.X > 0 and cam.ViewportSize.Y > 0 then
				local vp = cam.ViewportSize
				local absW = math.max(48, targetFrame.AbsoluteSize.X)
				local absH = math.max(48, targetFrame.AbsoluteSize.Y)
				local baseX = startPos.X.Scale * vp.X
				local baseY = startPos.Y.Scale * vp.Y
				local minX = (targetFrame == FloatingBtn) and 4 or (-absW + 80)
				local maxX = (targetFrame == FloatingBtn) and (vp.X - absW - 4) or (vp.X - 80)
				local minY = 4
				local maxY = (targetFrame == FloatingBtn) and (vp.Y - absH - 4) or (vp.Y - 48)
				rawX = math.clamp(baseX + rawX, minX, math.max(minX, maxX)) - baseX
				rawY = math.clamp(baseY + rawY, minY, math.max(minY, maxY)) - baseY
			end
			targetFrame.Position = UDim2.new(startPos.X.Scale, rawX, startPos.Y.Scale, rawY)
		end
	end))
end

makeDraggable(FloatingBtn, FloatingBtn)

;(function()
	local mwScale = Instance.new("UIScale")
	mwScale.Name = "ResponsiveScale"
	mwScale.Scale = 1
	mwScale.Parent = MainWindow
	local lastScale = 1
	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then return end
		local newScale = 1
		if vp.X < 910 or vp.Y < 580 then
			newScale = math.clamp(math.min((vp.X - 20) / 880, (vp.Y - 20) / 556), 0.45, 1)
		end
		if math.abs(newScale - lastScale) > 0.01 then
			lastScale = newScale
			mwScale.Scale = newScale
			MainWindow.Position = UDim2.new(0.5, -math.floor(440 * newScale), 0.5, -math.floor(278 * newScale))
		end
	end
	updateScale()
	if workspace.CurrentCamera then
		table.insert(Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
	end
end)()

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 240, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow
do
	local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0, 12); sbCorner.Parent = Sidebar
	local sbDiv = Instance.new("Frame")
	sbDiv.Size = UDim2.new(0, 1, 1, 0); sbDiv.Position = UDim2.new(1, -1, 0, 0)
	sbDiv.BackgroundColor3 = Theme.Stroke; sbDiv.BorderSizePixel = 0; sbDiv.Parent = Sidebar

	local BrandHeader = Instance.new("Frame")
	BrandHeader.Name = "BrandHeader"
	BrandHeader.Size = UDim2.new(1, 0, 0, 76)
	BrandHeader.BackgroundTransparency = 1
	BrandHeader.Parent = Sidebar
	makeDraggable(BrandHeader, MainWindow)

	local LogoImage = Instance.new("ImageLabel")
	LogoImage.Name = "SerennityLogo"
	LogoImage.Size = UDim2.new(0, 48, 0, 48)
	LogoImage.Position = UDim2.new(0, 12, 0, 14)
	LogoImage.BackgroundTransparency = 1
	LogoImage.ScaleType = Enum.ScaleType.Fit
	LogoImage.Image = RtState.CustomLogoAsset
	LogoImage.Parent = BrandHeader
	if type(RtState.ApplyCrossPlatformLogo) == "function" then
		RtState.ApplyCrossPlatformLogo(fbLogo, LogoImage)
	end

	local MapTitleLabel = Instance.new("TextLabel")
	MapTitleLabel.Name = "MapTitleLabel"
	MapTitleLabel.Size = UDim2.new(1, -74, 0, 22)
	MapTitleLabel.Position = UDim2.new(0, 66, 0, 15)
	MapTitleLabel.BackgroundTransparency = 1
	MapTitleLabel.FontFace = FontBold
	MapTitleLabel.TextSize = 14
	MapTitleLabel.TextColor3 = Theme.TextPrimary
	MapTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	MapTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	MapTitleLabel.Text = CurrentMapName
	MapTitleLabel.Parent = BrandHeader

	local HubSubLabel = Instance.new("TextLabel")
	HubSubLabel.Name = "HubSubLabel"
	HubSubLabel.Size = UDim2.new(1, -72, 0, 20)
	HubSubLabel.Position = UDim2.new(0, 66, 0, 39)
	HubSubLabel.BackgroundTransparency = 1
	HubSubLabel.FontFace = FontMedium
	HubSubLabel.TextSize = 13
	HubSubLabel.TextColor3 = Theme.AccentBlue
	HubSubLabel.TextXAlignment = Enum.TextXAlignment.Left
	HubSubLabel.TextTruncate = Enum.TextTruncate.AtEnd
	HubSubLabel.Text = "Serennity Hub * v1.0 [ Private ]"
	HubSubLabel.Parent = BrandHeader
	RtState.HubSubLabelRef = HubSubLabel
end

local NavListFrame = Instance.new("ScrollingFrame")
NavListFrame.Name = "NavList"
NavListFrame.Size = UDim2.new(1, -24, 1, -162)
NavListFrame.Position = UDim2.new(0, 12, 0, 80)
NavListFrame.BackgroundTransparency = 1
NavListFrame.BorderSizePixel = 0
NavListFrame.ScrollBarThickness = 0
NavListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
NavListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavListFrame.Parent = Sidebar
do
	local nl = Instance.new("UIListLayout")
	nl.SortOrder = Enum.SortOrder.LayoutOrder
	nl.Padding = UDim.new(0, 6)
	nl.Parent = NavListFrame
end

do
	local UserCard = Instance.new("Frame")
	UserCard.Name = "UserCard"
	UserCard.Size = UDim2.new(1, -24, 0, 62)
	UserCard.Position = UDim2.new(0, 12, 1, -74)
	UserCard.BackgroundColor3 = Theme.CardBg
	UserCard.BorderSizePixel = 0
	UserCard.Parent = Sidebar
	local ucC = Instance.new("UICorner"); ucC.CornerRadius = UDim.new(0, 10); ucC.Parent = UserCard
	local ucS = Instance.new("UIStroke"); ucS.Color = Theme.Stroke; ucS.Thickness = 1; ucS.Parent = UserCard

	local AvatarImg = Instance.new("ImageLabel")
	AvatarImg.Name = "AvatarImg"
	AvatarImg.Size = UDim2.new(0, 38, 0, 38)
	AvatarImg.Position = UDim2.new(0, 10, 0.5, -19)
	AvatarImg.BackgroundColor3 = Theme.ControlBg
	AvatarImg.BorderSizePixel = 0
	AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
	AvatarImg.Parent = UserCard
	local avC = Instance.new("UICorner"); avC.CornerRadius = UDim.new(1, 0); avC.Parent = AvatarImg

	local OnlineDot = Instance.new("Frame")
	OnlineDot.Size = UDim2.new(0, 10, 0, 10)
	OnlineDot.Position = UDim2.new(0, 38, 0.5, 9)
	OnlineDot.BackgroundColor3 = Theme.OnlineGreen
	OnlineDot.BorderSizePixel = 0
	OnlineDot.Parent = UserCard
	local odC = Instance.new("UICorner"); odC.CornerRadius = UDim.new(1, 0); odC.Parent = OnlineDot
	local odS = Instance.new("UIStroke"); odS.Color = Theme.CardBg; odS.Thickness = 1.5; odS.Parent = OnlineDot

	local UcTitle = Instance.new("TextLabel")
	UcTitle.Size = UDim2.new(1, -78, 0, 20); UcTitle.Position = UDim2.new(0, 56, 0, 10)
	UcTitle.BackgroundTransparency = 1; UcTitle.FontFace = FontBold; UcTitle.TextSize = 15
	UcTitle.TextColor3 = Theme.TextPrimary; UcTitle.TextXAlignment = Enum.TextXAlignment.Left
	UcTitle.TextTruncate = Enum.TextTruncate.AtEnd; UcTitle.Text = LocalPlayer.DisplayName
	UcTitle.Parent = UserCard

	local UcSub = Instance.new("TextLabel")
	UcSub.Name = "UcSub"
	UcSub.Size = UDim2.new(1, -78, 0, 18); UcSub.Position = UDim2.new(0, 56, 0, 33)
	UcSub.BackgroundTransparency = 1; UcSub.FontFace = FontMedium; UcSub.TextSize = 13
	UcSub.TextColor3 = Theme.AccentBlue; UcSub.TextXAlignment = Enum.TextXAlignment.Left
	UcSub.TextTruncate = Enum.TextTruncate.AtEnd
	UcSub.Text = (RtState.IsAccountPremium() and "Map Premium" or "Standard") .. " | " .. ClientDeviceType
	UcSub.Parent = UserCard
	RtState.UcSubLabelRef = UcSub

	createCustomSvgIcon(UserCard, "chevron_right", 16, Theme.TextMuted, UDim2.new(1, -24, 0.5, -8))
end

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -240, 1, 0)
ContentArea.Position = UDim2.new(0, 240, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainWindow

RtState.ActiveTabIconCtrl = nil
RtState.ActiveTabTitleLabel = nil
RtState.SearchBox = nil
local function setWindowVisible(vis: boolean)
	if AfkOverlay.Visible == true and vis == true then
		return
	end
	MainWindow.Visible = vis
	FloatingBtn.Visible = not AfkOverlay.Visible
end

do
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 58)
	TopBar.BackgroundTransparency = 1
	TopBar.Parent = ContentArea
	makeDraggable(TopBar, MainWindow)

	local TopBarDivider = Instance.new("Frame")
	TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
	TopBarDivider.Position = UDim2.new(0, 0, 1, -1)
	TopBarDivider.BackgroundColor3 = Theme.Stroke
	TopBarDivider.BorderSizePixel = 0
	TopBarDivider.Parent = TopBar

	RtState.ActiveTabIconCtrl = createCustomSvgIcon(TopBar, "main", 18, Theme.AccentBlue, UDim2.new(0, 24, 0.5, -9))
	RtState.ActiveTabTitleLabel = Instance.new("TextLabel")
	RtState.ActiveTabTitleLabel.Size = UDim2.new(0, 240, 0, 26)
	RtState.ActiveTabTitleLabel.Position = UDim2.new(0, 50, 0.5, -13)
	RtState.ActiveTabTitleLabel.BackgroundTransparency = 1
	RtState.ActiveTabTitleLabel.FontFace = FontBold
	RtState.ActiveTabTitleLabel.TextSize = 19
	RtState.ActiveTabTitleLabel.TextColor3 = Theme.TextPrimary
	RtState.ActiveTabTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	RtState.ActiveTabTitleLabel.Text = "Main & Stage"
	RtState.ActiveTabTitleLabel.Parent = TopBar

	local SearchFrame = Instance.new("Frame")
	SearchFrame.Name = "SearchFrame"
	SearchFrame.Size = UDim2.new(0, 210, 0, 34)
	SearchFrame.Position = UDim2.new(1, -264, 0.5, -17)
	SearchFrame.BackgroundColor3 = Theme.SidebarBg
	SearchFrame.BorderSizePixel = 0
	SearchFrame.Parent = TopBar

	local sfCorner = Instance.new("UICorner")
	sfCorner.CornerRadius = UDim.new(0, 7)
	sfCorner.Parent = SearchFrame

	local sfStroke = Instance.new("UIStroke")
	sfStroke.Color = Theme.Stroke
	sfStroke.Thickness = 1
	sfStroke.Parent = SearchFrame

	local SearchIconCtrl = createCustomSvgIcon(SearchFrame, "search", 16, Theme.TextMuted, UDim2.new(0, 10, 0.5, -8))

	RtState.SearchBox = Instance.new("TextBox")
	RtState.SearchBox.Name = "SearchBox"
	RtState.SearchBox.Size = UDim2.new(1, -38, 1, 0)
	RtState.SearchBox.Position = UDim2.new(0, 32, 0, 0)
	RtState.SearchBox.BackgroundTransparency = 1
	RtState.SearchBox.FontFace = FontMedium
	RtState.SearchBox.TextSize = 13
	RtState.SearchBox.TextColor3 = Theme.TextPrimary
	RtState.SearchBox.PlaceholderText = "Search"
	RtState.SearchBox.PlaceholderColor3 = Theme.TextMuted
	RtState.SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	RtState.SearchBox.ClearTextOnFocus = false
	RtState.SearchBox.Text = ""
	RtState.SearchBox.Parent = SearchFrame

	RtState.SearchBox.Focused:Connect(function()
		sfStroke.Color = Theme.AccentBlue
		SearchIconCtrl:SetColor(Theme.AccentBlue, 0.14)
	end)
	RtState.SearchBox.FocusLost:Connect(function()
		sfStroke.Color = Theme.Stroke
		SearchIconCtrl:SetColor(Theme.TextMuted, 0.14)
	end)

	local CollapseBtn = Instance.new("TextButton")
	CollapseBtn.Name = "CollapseBtn"
	CollapseBtn.Size = UDim2.new(0, 30, 0, 30)
	CollapseBtn.Position = UDim2.new(1, -42, 0.5, -15)
	CollapseBtn.BackgroundTransparency = 1
	CollapseBtn.Text = ""
	CollapseBtn.AutoButtonColor = false
	CollapseBtn.Parent = TopBar
	local CollapseIconCtrl = createCustomSvgIcon(CollapseBtn, "collapse", 18, Theme.TextMuted, UDim2.new(0.5, -9, 0.5, -9))
	CollapseBtn.MouseEnter:Connect(function()
		CollapseIconCtrl:SetColor(Theme.TextPrimary, 0.12)
	end)
	CollapseBtn.MouseLeave:Connect(function()
		CollapseIconCtrl:SetColor(Theme.TextMuted, 0.12)
	end)

	CollapseBtn.MouseButton1Click:Connect(function()
		setWindowVisible(false)
	end)
end

RtState.LastFloatingBtnToggleClock = 0
local function onFloatingBtnActivated()
	if AfkOverlay.Visible == true then return end
	if FloatingBtn:GetAttribute("_WasDragged") then
		FloatingBtn:SetAttribute("_WasDragged", false)
		return
	end
	local now = os.clock()
	if now - (RtState.LastFloatingBtnToggleClock or 0) < 0.35 then
		return
	end
	RtState.LastFloatingBtnToggleClock = now
	setWindowVisible(not MainWindow.Visible)
end

FloatingBtn.MouseButton1Click:Connect(onFloatingBtnActivated)
table.insert(Connections, FloatingBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		task.defer(onFloatingBtnActivated)
	end
end))

RtState.IsBindingKey = false

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
	if RtState.IsBindingKey or IsMobileDevice or gp then return end
	if AfkOverlay.Visible == true then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local keyName = input.KeyCode.Name
		if keyName == (Cfg.MenuKeybind or "RightControl") then
			setWindowVisible(not MainWindow.Visible)
		end
	end
end))

RtState.TabsRegistry = {}
RtState.AllSearchableCards = {}
RtState.CurrentSelectedTab = nil

local function createTab(tabName: string, iconId: string)
	local resolvedIcon = resolveSvgIconId(iconId ~= "" and iconId or tabName)
	local navBtn = Instance.new("TextButton")
	navBtn.Name = "Tab_" .. tabName
	navBtn.Size = UDim2.new(1, 0, 0, 42)
	navBtn.BackgroundColor3 = Theme.ActiveTabBg
	navBtn.BackgroundTransparency = 1
	navBtn.BorderSizePixel = 0
	navBtn.AutoButtonColor = false
	navBtn.Text = ""
	navBtn.Parent = NavListFrame
	local nbC = Instance.new("UICorner"); nbC.CornerRadius = UDim.new(0, 8); nbC.Parent = navBtn
	local nbS = Instance.new("UIStroke"); nbS.Color = Theme.ActiveStroke; nbS.Thickness = 1; nbS.Transparency = 1; nbS.Parent = navBtn
	local nbIcon = createCustomSvgIcon(navBtn, resolvedIcon, 18, Theme.TextMuted, UDim2.new(0, 14, 0.5, -9))
	local nbTitle = Instance.new("TextLabel")
	nbTitle.Size = UDim2.new(1, -48, 1, 0); nbTitle.Position = UDim2.new(0, 42, 0, 0)
	nbTitle.BackgroundTransparency = 1; nbTitle.FontFace = FontMedium; nbTitle.TextSize = 15
	nbTitle.TextColor3 = Theme.SidebarText; nbTitle.TextXAlignment = Enum.TextXAlignment.Left
	nbTitle.TextTruncate = Enum.TextTruncate.AtEnd; nbTitle.Text = tabName; nbTitle.Parent = navBtn

	local page = Instance.new("Frame")
	page.Name = "Page_" .. tabName
	page.Size = UDim2.new(1, 0, 1, -58); page.Position = UDim2.new(0, 0, 0, 58)
	page.BackgroundTransparency = 1; page.Visible = false; page.Parent = ContentArea

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ColumnsScroll"
	scroll.Size = UDim2.new(1, -44, 1, -28); scroll.Position = UDim2.new(0, 22, 0, 14)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2
	scroll.ScrollBarImageColor3 = Theme.AccentBlue; scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = page

	local leftCol = Instance.new("Frame")
	leftCol.Name = "LeftColumn"; leftCol.Size = UDim2.new(0.5, -8, 0, 0)
	leftCol.BackgroundTransparency = 1; leftCol.AutomaticSize = Enum.AutomaticSize.Y; leftCol.Parent = scroll
	local lLay = Instance.new("UIListLayout"); lLay.SortOrder = Enum.SortOrder.LayoutOrder; lLay.Padding = UDim.new(0, 14); lLay.Parent = leftCol

	local rightCol = Instance.new("Frame")
	rightCol.Name = "RightColumn"; rightCol.Size = UDim2.new(0.5, -8, 0, 0); rightCol.Position = UDim2.new(0.5, 8, 0, 0)
	rightCol.BackgroundTransparency = 1; rightCol.AutomaticSize = Enum.AutomaticSize.Y; rightCol.Parent = scroll
	local rLay = Instance.new("UIListLayout"); rLay.SortOrder = Enum.SortOrder.LayoutOrder; rLay.Padding = UDim.new(0, 14); rLay.Parent = rightCol

	local function updateScrollCanvas()
		local maxH = math.max(lLay.AbsoluteContentSize.Y, rLay.AbsoluteContentSize.Y)
		if maxH > 0 then
			scroll.CanvasSize = UDim2.new(0, 0, 0, maxH + 40)
		end
	end
	lLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollCanvas)
	rLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollCanvas)

	local entry = { Name = tabName, Page = page, Left = leftCol, Right = rightCol, NavBtn = navBtn, NavStroke = nbS, NavIcon = nbIcon, NavTitle = nbTitle, Icon = resolvedIcon }
	function entry:Select()
		RtState.CurrentSelectedTab = entry
		RtState.ActiveTabIconCtrl:SetIcon(resolvedIcon)
		RtState.ActiveTabIconCtrl:SetColor(Theme.AccentBlue)
		RtState.ActiveTabTitleLabel.Text = tabName
		for _, other in ipairs(RtState.TabsRegistry) do
			local isMe = (other == entry)
			other.Page.Visible = isMe
			other.NavBtn.BackgroundColor3 = Theme.ActiveTabBg
			other.NavBtn.BackgroundTransparency = isMe and 0 or 1
			other.NavStroke.Transparency = isMe and 0 or 1
			other.NavIcon:SetColor(isMe and Theme.TextPrimary or Theme.TextMuted, 0.14)
			other.NavTitle.TextColor3 = isMe and Theme.TextPrimary or Theme.SidebarText
			other.NavTitle.FontFace = isMe and FontBold or FontMedium
		end
		task.defer(function()
			if scroll and scroll.Parent then
				updateScrollCanvas()
				local curPos = scroll.CanvasPosition
				scroll.CanvasPosition = Vector2.new(0, 1)
				scroll.CanvasPosition = curPos
			end
		end)
	end

	navBtn.MouseEnter:Connect(function()
		if RtState.CurrentSelectedTab ~= entry then
			TweenService:Create(navBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Theme.HoverTabBg,
				BackgroundTransparency = 0.35,
			}):Play()
			nbIcon:SetColor(Theme.AccentBlue, 0.12)
			TweenService:Create(nbTitle, TweenInfo.new(0.12), { TextColor3 = Theme.TextPrimary }):Play()
		end
	end)

	navBtn.MouseLeave:Connect(function()
		if RtState.CurrentSelectedTab ~= entry then
			TweenService:Create(navBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Theme.ActiveTabBg,
				BackgroundTransparency = 1,
			}):Play()
			nbIcon:SetColor(Theme.TextMuted, 0.12)
			TweenService:Create(nbTitle, TweenInfo.new(0.12), { TextColor3 = Theme.SidebarText }):Play()
		end
	end)

	navBtn.MouseButton1Click:Connect(function() entry:Select() end)
	table.insert(RtState.TabsRegistry, entry)
	return entry
end

AllTogglesRegistry = AllTogglesRegistry or {}
local AllSlidersRegistry = {}
local AllDropdownsRegistry = {}

local function createSectionCard(parentColumn: Frame, cardTitle: string, cardIcon: string, defaultExpanded: boolean?)
	local isExpanded = (defaultExpanded ~= false)
	local resolvedCardIcon = resolveSvgIconId(cardIcon ~= "" and cardIcon or cardTitle)

	local card = Instance.new("Frame")
	card.Name = "Card_" .. cardTitle
	card.Size = UDim2.new(1, 0, 0, 46)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.CardBg
	card.BorderSizePixel = 0
	card.Parent = parentColumn
	local cC = Instance.new("UICorner"); cC.CornerRadius = UDim.new(0, 10); cC.Parent = card
	local cS = Instance.new("UIStroke"); cS.Color = Theme.Stroke; cS.Thickness = 1; cS.Parent = card

	local cardLay = Instance.new("UIListLayout")
	cardLay.SortOrder = Enum.SortOrder.LayoutOrder
	cardLay.Padding = UDim.new(0, 0)
	cardLay.Parent = card

	local headerBtn = Instance.new("TextButton")
	headerBtn.Name = "Header"
	headerBtn.LayoutOrder = 1
	headerBtn.Size = UDim2.new(1, 0, 0, 46)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text = ""
	headerBtn.AutoButtonColor = false
	headerBtn.Parent = card

	local hIconCtrl = createCustomSvgIcon(headerBtn, resolvedCardIcon, 18, Theme.AccentBlue, UDim2.new(0, 16, 0.5, -9))

	local hTitle = Instance.new("TextLabel")
	hTitle.Name = "CardTitle"
	hTitle.Size = UDim2.new(1, -96, 1, 0)
	hTitle.Position = UDim2.new(0, 42, 0, 0)
	hTitle.BackgroundTransparency = 1
	hTitle.FontFace = FontBold
	hTitle.TextSize = 15
	hTitle.TextColor3 = Theme.TextPrimary
	hTitle.TextXAlignment = Enum.TextXAlignment.Left
	hTitle.TextTruncate = Enum.TextTruncate.AtEnd
	hTitle.Text = cardTitle
	hTitle.Parent = headerBtn

	local popHolder = Instance.new("Frame")
	popHolder.Size = UDim2.new(0, 14, 0, 12)
	popHolder.Position = UDim2.new(1, -48, 0.5, -6)
	popHolder.BackgroundTransparency = 1
	popHolder.Parent = headerBtn

	local popOuter = Instance.new("Frame")
	popOuter.Size = UDim2.new(0, 11, 0, 9)
	popOuter.Position = UDim2.new(0, 0, 0, 1)
	popOuter.BackgroundTransparency = 1
	popOuter.Parent = popHolder
	local poCorner = Instance.new("UICorner"); poCorner.CornerRadius = UDim.new(0, 2); poCorner.Parent = popOuter
	local poStroke = Instance.new("UIStroke"); poStroke.Color = Theme.TextMuted; poStroke.Thickness = 1.1; poStroke.Parent = popOuter

	local popInner = Instance.new("Frame")
	popInner.Size = UDim2.new(0, 5, 0, 4)
	popInner.Position = UDim2.new(0, 7, 0, 6)
	popInner.BackgroundColor3 = Theme.CardBg
	popInner.Parent = popHolder
	local piCorner = Instance.new("UICorner"); piCorner.CornerRadius = UDim.new(0, 1); piCorner.Parent = popInner
	local piStroke = Instance.new("UIStroke"); piStroke.Color = Theme.TextMuted; piStroke.Thickness = 1.1; piStroke.Parent = popInner

	local chevronCtrl = createCustomSvgIcon(headerBtn, "chevron_right", 16, Theme.TextMuted, UDim2.new(1, -27, 0.5, -8))
	chevronCtrl:SetRotation(isExpanded and 90 or 0)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.LayoutOrder = 2
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.Visible = isExpanded
	body.Parent = card

	local div = Instance.new("Frame")
	div.Size = UDim2.new(1, -28, 0, 1)
	div.Position = UDim2.new(0, 14, 0, 0)
	div.BackgroundColor3 = Theme.Stroke
	div.BorderSizePixel = 0
	div.Parent = body

	local items = Instance.new("Frame")
	items.Name = "Items"
	items.Size = UDim2.new(1, 0, 0, 0)
	items.AutomaticSize = Enum.AutomaticSize.Y
	items.BackgroundTransparency = 1
	items.Parent = body

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.Parent = items

	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 10)
	lay.Parent = items

	local function updateCardLayout()
		if not card or not card.Parent then return end
		local contentH = lay.AbsoluteContentSize.Y
		if isExpanded and contentH > 0 then
			local totalBodyH = contentH + 24
			items.Size = UDim2.new(1, 0, 0, totalBodyH)
			body.Size = UDim2.new(1, 0, 0, totalBodyH)
			card.Size = UDim2.new(1, 0, 0, 46 + totalBodyH)
		elseif not isExpanded then
			items.Size = UDim2.new(1, 0, 0, 0)
			body.Size = UDim2.new(1, 0, 0, 0)
			card.Size = UDim2.new(1, 0, 0, 46)
		end
	end
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCardLayout)

	headerBtn.MouseEnter:Connect(function()
		hIconCtrl:SetColor(Theme.TextPrimary, 0.12)
		chevronCtrl:SetColor(Theme.TextPrimary, 0.12)
	end)
	headerBtn.MouseLeave:Connect(function()
		hIconCtrl:SetColor(Theme.AccentBlue, 0.12)
		chevronCtrl:SetColor(Theme.TextMuted, 0.12)
	end)
	headerBtn.MouseButton1Click:Connect(function()
		isExpanded = not isExpanded
		body.Visible = isExpanded
		chevronCtrl:SetRotation(isExpanded and 90 or 0, 0.15)
		updateCardLayout()
	end)

	local searchKeywords = { string.lower(cardTitle) }
	table.insert(RtState.AllSearchableCards, {
		Card = card,
		Keywords = searchKeywords,
	})

	local api = {}

	function api:AddToggle(configKey: string, labelText: string, defaultVal: boolean, callback: ((boolean) -> ())?)
		table.insert(searchKeywords, string.lower(labelText))
		local state = (defaultVal == true)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 28); row.BackgroundTransparency = 1; row.Parent = items
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -54, 1, 0); lbl.BackgroundTransparency = 1
		lbl.FontFace = FontMedium; lbl.TextSize = 14; lbl.TextColor3 = Theme.TextSecondary
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = labelText; lbl.Parent = row

		local switchBtn = Instance.new("TextButton")
		switchBtn.Name = "Toggle_" .. configKey
		switchBtn.Size = UDim2.new(0, 42, 0, 22); switchBtn.Position = UDim2.new(1, -42, 0.5, -11)
		switchBtn.BackgroundColor3 = state and Theme.AccentBlue or Theme.ToggleOffBg
		switchBtn.BorderSizePixel = 0; switchBtn.Text = ""; switchBtn.AutoButtonColor = false; switchBtn.Parent = row
		local swC = Instance.new("UICorner"); swC.CornerRadius = UDim.new(1, 0); swC.Parent = switchBtn

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 16, 0, 16)
		knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		knob.BackgroundColor3 = state and Theme.ToggleOnKnob or Theme.ToggleOffKnob
		knob.BorderSizePixel = 0; knob.Parent = switchBtn
		local knC = Instance.new("UICorner"); knC.CornerRadius = UDim.new(1, 0); knC.Parent = knob

		local tObj = {}
		function tObj:UpdateState(newVal: boolean, fireCb: boolean?)
			state = (newVal == true)
			Cfg[configKey] = state
			TweenService:Create(switchBtn, TweenInfo.new(0.16), {
				BackgroundColor3 = state and Theme.AccentBlue or Theme.ToggleOffBg,
			}):Play()
			TweenService:Create(knob, TweenInfo.new(0.16), {
				Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
				BackgroundColor3 = state and Theme.ToggleOnKnob or Theme.ToggleOffKnob,
			}):Play()
			if fireCb and callback then
				task.spawn(callback, state)
			end
		end
		function tObj:SetLabel(newText: string)
			lbl.Text = newText
		end
		switchBtn.MouseButton1Click:Connect(function()
			tObj:UpdateState(not state, true)
		end)
		AllTogglesRegistry[configKey] = tObj
		return tObj
	end

	function api:AddSlider(
		configKey: string,
		labelText: string,
		minVal: number,
		maxVal: number,
		defaultVal: number,
		step: number?,
		suffix: string?,
		callback: ((number) -> ())?
	)
		table.insert(searchKeywords, string.lower(labelText))
		local stepVal = step or 1
		local unitSuffix = suffix or ""
		local curVal = math.clamp(tonumber(defaultVal) or minVal, minVal, maxVal)
		Cfg[configKey] = curVal

		local function formatVal(v: number): string
			if stepVal < 0.1 then
				return string.format("%.2f%s", v, unitSuffix)
			elseif stepVal < 1 then
				return string.format("%.1f%s", v, unitSuffix)
			end
			return string.format("%d%s", math.floor(v + 0.5), unitSuffix)
		end

		local box = Instance.new("Frame")
		box.Name = "Slider_" .. configKey
		box.Size = UDim2.new(1, 0, 0, 42)
		box.BackgroundTransparency = 1
		box.Parent = items

		local topRow = Instance.new("Frame")
		topRow.Size = UDim2.new(1, 0, 0, 20)
		topRow.BackgroundTransparency = 1
		topRow.Parent = box

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -68, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.FontFace = FontMedium
		lbl.TextSize = 14
		lbl.TextColor3 = Theme.TextSecondary
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = labelText
		lbl.Parent = topRow

		local valLbl = Instance.new("TextLabel")
		valLbl.Name = "ValueLabel"
		valLbl.Size = UDim2.new(0, 64, 1, 0)
		valLbl.Position = UDim2.new(1, -64, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.FontFace = FontBold
		valLbl.TextSize = 13
		valLbl.TextColor3 = Theme.AccentBlue
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.Text = formatVal(curVal)
		valLbl.Parent = topRow

		local trackBtn = Instance.new("TextButton")
		trackBtn.Name = "Track_" .. configKey
		trackBtn.Size = UDim2.new(1, 0, 0, 14)
		trackBtn.Position = UDim2.new(0, 0, 0, 24)
		trackBtn.BackgroundTransparency = 1
		trackBtn.Text = ""
		trackBtn.AutoButtonColor = false
		trackBtn.Parent = box

		local trackBg = Instance.new("Frame")
		trackBg.Size = UDim2.new(1, 0, 0, 6)
		trackBg.Position = UDim2.new(0, 0, 0.5, -3)
		trackBg.BackgroundColor3 = Theme.ControlBg
		trackBg.BorderSizePixel = 0
		trackBg.Parent = trackBtn
		local tbC = Instance.new("UICorner"); tbC.CornerRadius = UDim.new(1, 0); tbC.Parent = trackBg
		local tbS = Instance.new("UIStroke"); tbS.Color = Theme.Stroke; tbS.Thickness = 1; tbS.Parent = trackBg

		local initAlpha = math.clamp((curVal - minVal) / math.max(0.0001, maxVal - minVal), 0, 1)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(initAlpha, 0, 1, 0)
		fill.BackgroundColor3 = Theme.AccentBlue
		fill.BorderSizePixel = 0
		fill.Parent = trackBg
		local flC = Instance.new("UICorner"); flC.CornerRadius = UDim.new(1, 0); flC.Parent = fill

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.new(0, 12, 0, 12)
		thumb.AnchorPoint = Vector2.new(0.5, 0.5)
		thumb.Position = UDim2.new(initAlpha, 0, 0.5, 0)
		thumb.BackgroundColor3 = Theme.TextPrimary
		thumb.BorderSizePixel = 0
		thumb.Parent = trackBg
		local thC = Instance.new("UICorner"); thC.CornerRadius = UDim.new(1, 0); thC.Parent = thumb

		local sObj = {}
		function sObj:SetValue(newVal: number, fireCb: boolean?)
			local snapped = minVal + math.floor(((newVal - minVal) / stepVal) + 0.5) * stepVal
			if stepVal < 1 then
				snapped = tonumber(string.format("%.2f", snapped)) or snapped
			end
			curVal = math.clamp(snapped, minVal, maxVal)
			Cfg[configKey] = curVal
			local alpha = math.clamp((curVal - minVal) / math.max(0.0001, maxVal - minVal), 0, 1)
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
			valLbl.Text = formatVal(curVal)
			if fireCb and callback then
				task.spawn(callback, curVal)
			end
		end
		function sObj:SetLabel(newText: string)
			lbl.Text = newText
		end

		local dragging = false
		local function updateFromX(screenX: number)
			local absPos = trackBg.AbsolutePosition.X
			local absSize = math.max(1, trackBg.AbsoluteSize.X)
			local alpha = math.clamp((screenX - absPos) / absSize, 0, 1)
			local raw = minVal + alpha * (maxVal - minVal)
			sObj:SetValue(raw, true)
		end

		trackBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromX(input.Position.X)
			end
		end)
		table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromX(input.Position.X)
			end
		end))
		table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		AllSlidersRegistry[configKey] = sObj
		return sObj
	end

	function api:AddSingleDropdown(configKey: string, labelText: string, options: { string }, defaultSelected: string, callback: ((string) -> ())?)
		table.insert(searchKeywords, string.lower(labelText))
		local currentVal = defaultSelected or options[1] or ""
		local isOpen = false
		local wrapper = Instance.new("Frame")
		wrapper.Size = UDim2.new(1, 0, 0, 32); wrapper.AutomaticSize = Enum.AutomaticSize.Y
		wrapper.BackgroundTransparency = 1; wrapper.Parent = items

		local topRow = Instance.new("Frame")
		topRow.Size = UDim2.new(1, 0, 0, 32); topRow.BackgroundTransparency = 1; topRow.Parent = wrapper
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.42, -6, 1, 0); lbl.BackgroundTransparency = 1
		lbl.FontFace = FontMedium; lbl.TextSize = 14; lbl.TextColor3 = Theme.TextSecondary
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = labelText; lbl.Parent = topRow

		local dropBtn = Instance.new("TextButton")
		dropBtn.Size = UDim2.new(0.58, 0, 0, 30); dropBtn.Position = UDim2.new(0.42, 0, 0.5, -15)
		dropBtn.BackgroundColor3 = Theme.ControlBg; dropBtn.BorderSizePixel = 0
		dropBtn.Text = ""; dropBtn.AutoButtonColor = false; dropBtn.Parent = topRow
		local dbC = Instance.new("UICorner"); dbC.CornerRadius = UDim.new(0, 6); dbC.Parent = dropBtn
		local dbS = Instance.new("UIStroke"); dbS.Color = Theme.Stroke; dbS.Thickness = 1; dbS.Parent = dropBtn

		local sumText = Instance.new("TextLabel")
		sumText.Size = UDim2.new(1, -26, 1, 0); sumText.Position = UDim2.new(0, 10, 0, 0)
		sumText.BackgroundTransparency = 1; sumText.FontFace = FontMedium; sumText.TextSize = 12
		sumText.TextColor3 = Theme.TextPrimary; sumText.TextXAlignment = Enum.TextXAlignment.Left
		sumText.TextTruncate = Enum.TextTruncate.AtEnd; sumText.Text = currentVal; sumText.Parent = dropBtn

		local arrowCtrl = createCustomSvgIcon(dropBtn, "chevron_right", 14, Theme.TextMuted, UDim2.new(1, -21, 0.5, -7))
		arrowCtrl:SetRotation(90)

		local listFrame = Instance.new("ScrollingFrame")
		listFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 29 + 10, 175))
		listFrame.Position = UDim2.new(0, 0, 0, 36)
		listFrame.BackgroundColor3 = Theme.ControlBg; listFrame.BorderSizePixel = 0
		listFrame.ScrollBarThickness = 3; listFrame.ScrollBarImageColor3 = Theme.AccentBlue
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 0); listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		listFrame.Visible = false; listFrame.Parent = wrapper
		local lfC = Instance.new("UICorner"); lfC.CornerRadius = UDim.new(0, 6); lfC.Parent = listFrame
		local lfS = Instance.new("UIStroke"); lfS.Color = Theme.Stroke; lfS.Thickness = 1; lfS.Parent = listFrame
		local lfP = Instance.new("UIPadding")
		lfP.PaddingTop = UDim.new(0, 5); lfP.PaddingBottom = UDim.new(0, 5)
		lfP.PaddingLeft = UDim.new(0, 6); lfP.PaddingRight = UDim.new(0, 6); lfP.Parent = listFrame
		local lfL = Instance.new("UIListLayout"); lfL.SortOrder = Enum.SortOrder.LayoutOrder; lfL.Padding = UDim.new(0, 3); lfL.Parent = listFrame

		local function rebuild(optsList: { string }?, selOverride: string?)
			if type(optsList) == "table" then
				options = optsList
			end
			if type(selOverride) == "string" and #selOverride > 0 then
				currentVal = selOverride
			elseif #options > 0 then
				local found = false
				for _, o in ipairs(options) do
					if o == currentVal then found = true; break end
				end
				if not found then
					currentVal = options[1]
				end
			end
			sumText.Text = currentVal
			listFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 29 + 10, 175))
			for _, ch in ipairs(listFrame:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			for idx, opt in ipairs(options) do
				local isMe = (opt == currentVal)
				local ob = Instance.new("TextButton")
				ob.LayoutOrder = idx; ob.Size = UDim2.new(1, -4, 0, 26)
				ob.BackgroundColor3 = Theme.ActiveTabBg; ob.BackgroundTransparency = isMe and 0.2 or 1
				ob.BorderSizePixel = 0; ob.AutoButtonColor = false; ob.Text = ""; ob.Parent = listFrame
				local obC = Instance.new("UICorner"); obC.CornerRadius = UDim.new(0, 5); obC.Parent = ob
				local ot = Instance.new("TextLabel")
				ot.Size = UDim2.new(1, -28, 1, 0); ot.Position = UDim2.new(0, 10, 0, 0)
				ot.BackgroundTransparency = 1; ot.FontFace = FontMedium; ot.TextSize = 13
				ot.TextColor3 = isMe and Theme.AccentBlue or Theme.TextSecondary
				ot.TextXAlignment = Enum.TextXAlignment.Left; ot.TextTruncate = Enum.TextTruncate.AtEnd
				ot.Text = opt; ot.Parent = ob

				local checkDot = Instance.new("Frame")
				checkDot.Size = UDim2.new(0, 7, 0, 7)
				checkDot.Position = UDim2.new(1, -16, 0.5, -3)
				checkDot.BackgroundColor3 = Theme.AccentBlue
				checkDot.BorderSizePixel = 0
				checkDot.Visible = isMe
				checkDot.Parent = ob
				local cdCorner = Instance.new("UICorner")
				cdCorner.CornerRadius = UDim.new(1, 0)
				cdCorner.Parent = checkDot

				ob.MouseButton1Click:Connect(function()
					currentVal = opt
					if configKey ~= "" then
						Cfg[configKey] = currentVal
					end
					sumText.Text = currentVal
					isOpen = false
					listFrame.Visible = false
					arrowCtrl:SetRotation(90, 0.14)
					rebuild()
					if callback then task.spawn(callback, currentVal) end
				end)
			end
		end
		rebuild()
		dropBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			listFrame.Visible = isOpen
			arrowCtrl:SetRotation(isOpen and -90 or 90, 0.14)
		end)
		local dObj = {
			SetSelected = function(_, val: string)
				currentVal = val
				if configKey ~= "" then
					Cfg[configKey] = val
				end
				sumText.Text = val
				rebuild(nil, val)
			end,
			SetOptions = function(_, newOptions: { string }, newSelected: string?)
				rebuild(newOptions, newSelected)
			end,
			GetSelected = function(): string
				return currentVal
			end,
		}
		if configKey ~= "" then
			AllDropdownsRegistry[configKey] = dObj
		end
		return dObj
	end


	function api:AddMultiDropdown(configKey: string, labelText: string, options: { string }, defaultSelectedMap: { [string]: boolean }?, callback: (({ [string]: boolean }) -> ())?)
		table.insert(searchKeywords, string.lower(labelText))
		local selected = {}
		for _, opt in ipairs(options) do
			selected[opt] = (type(defaultSelectedMap) == "table" and defaultSelectedMap[opt] == true) or false
		end
		local isOpen = false

		local wrapper = Instance.new("Frame")
		wrapper.Size = UDim2.new(1, 0, 0, 32)
		wrapper.AutomaticSize = Enum.AutomaticSize.Y
		wrapper.BackgroundTransparency = 1
		wrapper.Parent = items

		local topRow = Instance.new("Frame")
		topRow.Size = UDim2.new(1, 0, 0, 32)
		topRow.BackgroundTransparency = 1
		topRow.Parent = wrapper

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.42, -6, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.FontFace = FontMedium
		lbl.TextSize = 14
		lbl.TextColor3 = Theme.TextSecondary
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = labelText
		lbl.Parent = topRow

		local dropBtn = Instance.new("TextButton")
		dropBtn.Size = UDim2.new(0.58, 0, 0, 30)
		dropBtn.Position = UDim2.new(0.42, 0, 0.5, -15)
		dropBtn.BackgroundColor3 = Theme.ControlBg
		dropBtn.BorderSizePixel = 0
		dropBtn.Text = ""
		dropBtn.AutoButtonColor = false
		dropBtn.Parent = topRow

		local dbCorner = Instance.new("UICorner")
		dbCorner.CornerRadius = UDim.new(0, 6)
		dbCorner.Parent = dropBtn

		local dbStroke = Instance.new("UIStroke")
		dbStroke.Color = Theme.Stroke
		dbStroke.Thickness = 1
		dbStroke.Parent = dropBtn

		local sumText = Instance.new("TextLabel")
		sumText.Size = UDim2.new(1, -28, 1, 0)
		sumText.Position = UDim2.new(0, 10, 0, 0)
		sumText.BackgroundTransparency = 1
		sumText.FontFace = FontMedium
		sumText.TextSize = 13
		sumText.TextColor3 = Theme.TextPrimary
		sumText.TextXAlignment = Enum.TextXAlignment.Left
		sumText.TextTruncate = Enum.TextTruncate.AtEnd
		sumText.Parent = dropBtn

		local arrowCtrl = createCustomSvgIcon(dropBtn, "chevron_right", 14, Theme.TextMuted, UDim2.new(1, -21, 0.5, -7))
		arrowCtrl:SetRotation(90)

		local function refreshSummary()
			local activeList = {}
			for _, opt in ipairs(options) do
				if selected[opt] then
					table.insert(activeList, opt)
				end
			end
			if #activeList == 0 then
				sumText.Text = "None"
			elseif #activeList <= 2 then
				sumText.Text = table.concat(activeList, ", ")
			else
				sumText.Text = string.format("%s, %s +%d", activeList[1], activeList[2], #activeList - 2)
			end
		end
		refreshSummary()

		local listFrame = Instance.new("Frame")
		listFrame.Size = UDim2.new(1, 0, 0, 0)
		listFrame.Position = UDim2.new(0, 0, 0, 36)
		listFrame.AutomaticSize = Enum.AutomaticSize.Y
		listFrame.BackgroundColor3 = Theme.ControlBg
		listFrame.BorderSizePixel = 0
		listFrame.Visible = false
		listFrame.Parent = wrapper

		local lfCorner = Instance.new("UICorner")
		lfCorner.CornerRadius = UDim.new(0, 6)
		lfCorner.Parent = listFrame

		local lfStroke = Instance.new("UIStroke")
		lfStroke.Color = Theme.Stroke
		lfStroke.Thickness = 1
		lfStroke.Parent = listFrame

		local lfPadding = Instance.new("UIPadding")
		lfPadding.PaddingTop = UDim.new(0, 6)
		lfPadding.PaddingBottom = UDim.new(0, 6)
		lfPadding.PaddingLeft = UDim.new(0, 6)
		lfPadding.PaddingRight = UDim.new(0, 6)
		lfPadding.Parent = listFrame

		local lfLayout = Instance.new("UIListLayout")
		lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
		lfLayout.Padding = UDim.new(0, 4)
		lfLayout.Parent = listFrame

		local filterBar = Instance.new("Frame")
		filterBar.LayoutOrder = 1
		filterBar.Size = UDim2.new(1, 0, 0, 26)
		filterBar.BackgroundTransparency = 1
		filterBar.Visible = #options > 6
		filterBar.Parent = listFrame

		local filterBox = Instance.new("TextBox")
		filterBox.Size = UDim2.new(1, -86, 1, 0)
		filterBox.BackgroundColor3 = Theme.SidebarBg
		filterBox.BorderSizePixel = 0
		filterBox.FontFace = FontMedium
		filterBox.TextSize = 12
		filterBox.TextColor3 = Theme.TextPrimary
		filterBox.PlaceholderText = "Search..."
		filterBox.PlaceholderColor3 = Theme.TextMuted
		filterBox.TextXAlignment = Enum.TextXAlignment.Left
		filterBox.ClearTextOnFocus = false
		filterBox.Text = ""
		filterBox.Parent = filterBar
		local fbC = Instance.new("UICorner")
		fbC.CornerRadius = UDim.new(0, 5)
		fbC.Parent = filterBox
		local fbP = Instance.new("UIPadding")
		fbP.PaddingLeft = UDim.new(0, 8)
		fbP.PaddingRight = UDim.new(0, 6)
		fbP.Parent = filterBox

		local btnAll = Instance.new("TextButton")
		btnAll.Size = UDim2.new(0, 38, 1, 0)
		btnAll.Position = UDim2.new(1, -80, 0, 0)
		btnAll.BackgroundColor3 = Theme.ActiveTabBg
		btnAll.BorderSizePixel = 0
		btnAll.FontFace = FontBold
		btnAll.TextSize = 11
		btnAll.TextColor3 = Theme.AccentBlue
		btnAll.Text = "All"
		btnAll.Parent = filterBar
		local baC = Instance.new("UICorner")
		baC.CornerRadius = UDim.new(0, 5)
		baC.Parent = btnAll

		local btnClr = Instance.new("TextButton")
		btnClr.Size = UDim2.new(0, 38, 1, 0)
		btnClr.Position = UDim2.new(1, -38, 0, 0)
		btnClr.BackgroundColor3 = Theme.SidebarBg
		btnClr.BorderSizePixel = 0
		btnClr.FontFace = FontBold
		btnClr.TextSize = 11
		btnClr.TextColor3 = Theme.TextSecondary
		btnClr.Text = "Clear"
		btnClr.Parent = filterBar
		local bcC = Instance.new("UICorner")
		bcC.CornerRadius = UDim.new(0, 5)
		bcC.Parent = btnClr

		local optScroll = Instance.new("ScrollingFrame")
		optScroll.LayoutOrder = 2
		optScroll.Size = UDim2.new(1, 0, 0, math.min(#options * 29, 175))
		optScroll.BackgroundTransparency = 1
		optScroll.BorderSizePixel = 0
		optScroll.ScrollBarThickness = 3
		optScroll.ScrollBarImageColor3 = Theme.AccentBlue
		optScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		optScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		optScroll.Parent = listFrame

		local osLayout = Instance.new("UIListLayout")
		osLayout.SortOrder = Enum.SortOrder.LayoutOrder
		osLayout.Padding = UDim.new(0, 3)
		osLayout.Parent = optScroll

		local optUIs = {}

		local function applyFilter()
			local q = string.lower(string.gsub(filterBox.Text or "", "^%s*(.-)%s*$", "%1"))
			local visCount = 0
			for _, opt in ipairs(options) do
				local ui = optUIs[opt]
				if ui then
					local vis = (q == "") or (string.find(string.lower(opt), q, 1, true) ~= nil)
					ui.btn.Visible = vis
					if vis then
						visCount += 1
					end
				end
			end
			optScroll.Size = UDim2.new(1, 0, 0, math.clamp(visCount * 29, 29, 175))
		end

		local function rebuildMultiOptions(newOpts: { string })
			options = newOpts
			for _, ch in ipairs(optScroll:GetChildren()) do
				if ch:IsA("TextButton") then
					ch:Destroy()
				end
			end
			table.clear(optUIs)
			filterBar.Visible = #options > 6

			for idx, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.LayoutOrder = idx
				optBtn.Size = UDim2.new(1, -4, 0, 26)
				optBtn.BackgroundColor3 = Theme.ActiveTabBg
				optBtn.BackgroundTransparency = selected[opt] and 0.2 or 1
				optBtn.BorderSizePixel = 0
				optBtn.AutoButtonColor = false
				optBtn.Text = ""
				optBtn.Parent = optScroll

				local obCorner = Instance.new("UICorner")
				obCorner.CornerRadius = UDim.new(0, 5)
				obCorner.Parent = optBtn

				local obText = Instance.new("TextLabel")
				obText.Size = UDim2.new(1, -22, 1, 0)
				obText.Position = UDim2.new(0, 8, 0, 0)
				obText.BackgroundTransparency = 1
				obText.FontFace = FontMedium
				obText.TextSize = 11
				obText.TextColor3 = selected[opt] and Theme.AccentBlue or Theme.TextSecondary
				obText.TextXAlignment = Enum.TextXAlignment.Left
				obText.TextTruncate = Enum.TextTruncate.AtEnd
				obText.Text = opt
				obText.Parent = optBtn

				local checkDot = Instance.new("Frame")
				checkDot.Size = UDim2.new(0, 7, 0, 7)
				checkDot.Position = UDim2.new(1, -16, 0.5, -3)
				checkDot.BackgroundColor3 = Theme.AccentBlue
				checkDot.BorderSizePixel = 0
				checkDot.Visible = selected[opt] == true
				checkDot.Parent = optBtn
				local cdCorner = Instance.new("UICorner")
				cdCorner.CornerRadius = UDim.new(1, 0)
				cdCorner.Parent = checkDot

				optUIs[opt] = { btn = optBtn, text = obText, dot = checkDot }

				optBtn.MouseButton1Click:Connect(function()
					selected[opt] = not selected[opt]
					optBtn.BackgroundTransparency = selected[opt] and 0.2 or 1
					obText.TextColor3 = selected[opt] and Theme.AccentBlue or Theme.TextSecondary
					checkDot.Visible = selected[opt] == true
					refreshSummary()
					if configKey ~= "" then Cfg[configKey] = table.clone(selected) end; if callback then task.spawn(callback, selected) end
				end)
			end
			applyFilter()
			refreshSummary()
		end

		rebuildMultiOptions(options)

		filterBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

		btnAll.MouseButton1Click:Connect(function()
			for _, opt in ipairs(options) do
				local ui = optUIs[opt]
				if ui and ui.btn.Visible then
					selected[opt] = true
					ui.btn.BackgroundTransparency = 0.2
					ui.text.TextColor3 = Theme.AccentBlue
					ui.dot.Visible = true
				end
			end
			refreshSummary()
			if configKey ~= "" then Cfg[configKey] = table.clone(selected) end; if callback then task.spawn(callback, selected) end
		end)

		btnClr.MouseButton1Click:Connect(function()
			for _, opt in ipairs(options) do
				selected[opt] = false
				local ui = optUIs[opt]
				if ui then
					ui.btn.BackgroundTransparency = 1
					ui.text.TextColor3 = Theme.TextSecondary
					ui.dot.Visible = false
				end
			end
			refreshSummary()
			if configKey ~= "" then Cfg[configKey] = table.clone(selected) end; if callback then task.spawn(callback, selected) end
		end)

		dropBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			if isOpen then
				optScroll.CanvasPosition = Vector2.new(0, 0)
			end
			listFrame.Visible = isOpen
			arrowCtrl:SetRotation(isOpen and -90 or 90, 0.14)
		end)

		local multiDropObj = {}
		function multiDropObj:UpdateSelection(newMap: { [string]: boolean })
			for _, opt in ipairs(options) do
				local isSel = (newMap and newMap[opt] == true) or false
				selected[opt] = isSel
				local ui = optUIs[opt]
				if ui then
					ui.btn.BackgroundTransparency = isSel and 0.2 or 1
					ui.text.TextColor3 = isSel and Theme.AccentBlue or Theme.TextSecondary
					ui.dot.Visible = isSel
				end
			end
			refreshSummary()
		end
		function multiDropObj:SetOptions(newOpts: { string }, newMap: { [string]: boolean }?)
			table.clear(selected)
			if newMap then
				for k, v in pairs(newMap) do
					if v then
						selected[k] = true
					end
				end
			end
			rebuildMultiOptions(newOpts)
		end
		function multiDropObj:GetSelection(): { [string]: boolean }
			return selected
		end
		if configKey ~= "" then AllDropdownsRegistry[configKey] = multiDropObj end; return multiDropObj
	end

	function api:AddTextBox(labelText: string, placeholderText: string, defaultText: string?, callback: ((string) -> ())?)
		table.insert(searchKeywords, string.lower(labelText))
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
		row.Parent = items

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.42, -6, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.FontFace = FontMedium
		lbl.TextSize = 14
		lbl.TextColor3 = Theme.TextSecondary
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = labelText
		lbl.Parent = row

		local boxBg = Instance.new("Frame")
		boxBg.Size = UDim2.new(0.58, 0, 0, 30)
		boxBg.Position = UDim2.new(0.42, 0, 0.5, -15)
		boxBg.BackgroundColor3 = Theme.ControlBg
		boxBg.BorderSizePixel = 0
		boxBg.Parent = row
		local bbCorner = Instance.new("UICorner"); bbCorner.CornerRadius = UDim.new(0, 6); bbCorner.Parent = boxBg
		local bbStroke = Instance.new("UIStroke"); bbStroke.Color = Theme.Stroke; bbStroke.Thickness = 1; bbStroke.Parent = boxBg

		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, -20, 1, 0)
		inputBox.Position = UDim2.new(0, 10, 0, 0)
		inputBox.BackgroundTransparency = 1
		inputBox.FontFace = FontMedium
		inputBox.TextSize = 13
		inputBox.TextColor3 = Theme.TextPrimary
		inputBox.PlaceholderText = placeholderText
		inputBox.PlaceholderColor3 = Theme.TextMuted
		inputBox.TextXAlignment = Enum.TextXAlignment.Left
		inputBox.ClearTextOnFocus = false
		inputBox.Text = defaultText or ""
		inputBox.Parent = boxBg

		inputBox.Focused:Connect(function()
			bbStroke.Color = Theme.AccentBlue
		end)
		inputBox.FocusLost:Connect(function()
			bbStroke.Color = Theme.Stroke
			if callback then
				callback(inputBox.Text)
			end
		end)
		inputBox:GetPropertyChangedSignal("Text"):Connect(function()
			if callback then
				callback(inputBox.Text)
			end
		end)

		local tbObj = {}
		function tbObj:GetText(): string
			return inputBox.Text
		end
		function tbObj:SetText(txt: string)
			inputBox.Text = txt
		end
		return tbObj
	end

	function api:AddKeybind(labelText: string, defaultKeyName: string, callback: ((string) -> ())?)
		table.insert(searchKeywords, string.lower(labelText))
		local currentKey = defaultKeyName or "RightControl"

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
		row.Parent = items

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.52, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.FontFace = FontMedium
		lbl.TextSize = 14
		lbl.TextColor3 = Theme.TextSecondary
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = labelText
		lbl.Parent = row

		local keyBtn = Instance.new("TextButton")
		keyBtn.Size = UDim2.new(0.48, 0, 0, 30)
		keyBtn.Position = UDim2.new(0.52, 0, 0.5, -15)
		keyBtn.BackgroundColor3 = Theme.ControlBg
		keyBtn.BorderSizePixel = 0
		keyBtn.FontFace = FontBold
		keyBtn.TextSize = 13
		keyBtn.TextColor3 = Theme.AccentBlue
		keyBtn.Text = "[" .. currentKey .. "]"
		keyBtn.AutoButtonColor = false
		keyBtn.Parent = row

		local kbCorner = Instance.new("UICorner"); kbCorner.CornerRadius = UDim.new(0, 6); kbCorner.Parent = keyBtn
		local kbStroke = Instance.new("UIStroke"); kbStroke.Color = Theme.Stroke; kbStroke.Thickness = 1; kbStroke.Parent = keyBtn

		keyBtn.MouseButton1Click:Connect(function()
			if RtState.IsBindingKey then return end
			RtState.IsBindingKey = true
			keyBtn.Text = "[Press Key...]"
			keyBtn.TextColor3 = Theme.TextPrimary
			kbStroke.Color = Theme.AccentBlue

			local bindConn
			bindConn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.Touch
					or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape) then
					bindConn:Disconnect()
					keyBtn.Text = "[" .. currentKey .. "]"
					keyBtn.TextColor3 = Theme.AccentBlue
					kbStroke.Color = Theme.Stroke
					task.delay(0.15, function()
						RtState.IsBindingKey = false
					end)
					return
				end
				if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
					bindConn:Disconnect()
					if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
						currentKey = "None"
					else
						currentKey = input.KeyCode.Name
					end
					keyBtn.Text = "[" .. currentKey .. "]"
					keyBtn.TextColor3 = Theme.AccentBlue
					kbStroke.Color = Theme.Stroke
					task.delay(0.15, function()
						RtState.IsBindingKey = false
					end)
					if callback then
						task.spawn(callback, currentKey)
					end
				end
			end)
			table.insert(Connections, bindConn)
		end)

		return {
			SetKey = function(_, newKey: string)
				currentKey = newKey
				keyBtn.Text = "[" .. currentKey .. "]"
			end,
		}
	end

	function api:AddButton(btnText: string, callback: () -> ())
		table.insert(searchKeywords, string.lower(btnText))
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundColor3 = Theme.ActiveTabBg; btn.BorderSizePixel = 0
		btn.FontFace = FontBold; btn.TextSize = 13; btn.TextColor3 = Theme.TextPrimary
		btn.TextTruncate = Enum.TextTruncate.AtEnd; btn.Text = btnText
		btn.AutoButtonColor = false; btn.Parent = items
		local bC = Instance.new("UICorner"); bC.CornerRadius = UDim.new(0, 7); bC.Parent = btn
		local bS = Instance.new("UIStroke"); bS.Color = Theme.ActiveStroke; bS.Thickness = 1; bS.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(34, 54, 88) }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ActiveTabBg }):Play()
		end)
		btn.MouseButton1Click:Connect(function()
			if callback then task.spawn(callback) end
		end)
		return btn
	end

	function api:AddButtonRow(leftText: string, leftCb: () -> (), rightText: string, rightCb: () -> ())
		table.insert(searchKeywords, string.lower(leftText))
		table.insert(searchKeywords, string.lower(rightText))
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
		row.Parent = items

		local function makeHalfBtn(txt: string, posScale: number, posOff: number, cb: () -> ())
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0.5, -4, 1, 0)
			btn.Position = UDim2.new(posScale, posOff, 0, 0)
			btn.BackgroundColor3 = Theme.ActiveTabBg
			btn.BorderSizePixel = 0
			btn.FontFace = FontBold
			btn.TextSize = 13
			btn.TextColor3 = Theme.TextPrimary
			btn.TextTruncate = Enum.TextTruncate.AtEnd
			btn.Text = txt
			btn.AutoButtonColor = false
			btn.Parent = row
			local bC = Instance.new("UICorner"); bC.CornerRadius = UDim.new(0, 7); bC.Parent = btn
			local bS = Instance.new("UIStroke"); bS.Color = Theme.ActiveStroke; bS.Thickness = 1; bS.Parent = btn
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(34, 54, 88) }):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ActiveTabBg }):Play()
			end)
			btn.MouseButton1Click:Connect(function()
				if cb then task.spawn(cb) end
			end)
		end

		makeHalfBtn(leftText, 0, 0, leftCb)
		makeHalfBtn(rightText, 0.5, 4, rightCb)
	end

	function api:AddInfoParagraph(headerText: string, bodyText: string)
		table.insert(searchKeywords, string.lower(headerText))
		local box = Instance.new("Frame")
		box.Size = UDim2.new(1, 0, 0, 58); box.AutomaticSize = Enum.AutomaticSize.Y
		box.BackgroundColor3 = Theme.ControlBg; box.BorderSizePixel = 0; box.Parent = items
		local bxC = Instance.new("UICorner"); bxC.CornerRadius = UDim.new(0, 7); bxC.Parent = box
		local bxS = Instance.new("UIStroke"); bxS.Color = Theme.Stroke; bxS.Thickness = 1; bxS.Parent = box
		local pad2 = Instance.new("UIPadding")
		pad2.PaddingTop = UDim.new(0, 10); pad2.PaddingBottom = UDim.new(0, 12)
		pad2.PaddingLeft = UDim.new(0, 12); pad2.PaddingRight = UDim.new(0, 12); pad2.Parent = box
		local lay2 = Instance.new("UIListLayout"); lay2.SortOrder = Enum.SortOrder.LayoutOrder; lay2.Padding = UDim.new(0, 6); lay2.Parent = box

		local hLbl = Instance.new("TextLabel")
		hLbl.LayoutOrder = 1
		hLbl.Size = UDim2.new(1, 0, 0, 18)
		hLbl.BackgroundTransparency = 1; hLbl.FontFace = FontBold; hLbl.TextSize = 14
		hLbl.TextColor3 = Theme.AccentBlue; hLbl.TextXAlignment = Enum.TextXAlignment.Left
		hLbl.TextTruncate = Enum.TextTruncate.AtEnd; hLbl.TextWrapped = false; hLbl.Text = headerText; hLbl.Parent = box

		local bLbl = Instance.new("TextLabel")
		bLbl.LayoutOrder = 2
		bLbl.Size = UDim2.new(1, 0, 0, 16); bLbl.AutomaticSize = Enum.AutomaticSize.Y
		bLbl.BackgroundTransparency = 1; bLbl.FontFace = FontMedium; bLbl.TextSize = 13; bLbl.LineHeight = 1.25
		bLbl.TextColor3 = Theme.TextSecondary; bLbl.TextXAlignment = Enum.TextXAlignment.Left
		bLbl.TextWrapped = true; bLbl.Text = bodyText; bLbl.Parent = box

		local function updateBoxSize()
			local bh = lay2.AbsoluteContentSize.Y + 22
			if bh > 40 then
				box.Size = UDim2.new(1, 0, 0, bh)
			end
		end
		lay2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateBoxSize)
		bLbl:GetPropertyChangedSignal("TextBounds"):Connect(function()
			bLbl.Size = UDim2.new(1, 0, 0, math.max(16, bLbl.TextBounds.Y))
			updateBoxSize()
		end)
		return hLbl, bLbl
	end

	function api:AddLiveStatusBox(headerText: string, buffText: string, subText: string)
		table.insert(searchKeywords, string.lower(headerText))
		local box = Instance.new("Frame")
		box.Size = UDim2.new(1, 0, 0, 74); box.AutomaticSize = Enum.AutomaticSize.Y
		box.BackgroundColor3 = Theme.ControlBg; box.BorderSizePixel = 0; box.Parent = items
		local bxC = Instance.new("UICorner"); bxC.CornerRadius = UDim.new(0, 7); bxC.Parent = box
		local bxS = Instance.new("UIStroke"); bxS.Color = Theme.Stroke; bxS.Thickness = 1; bxS.Parent = box
		local pad2 = Instance.new("UIPadding")
		pad2.PaddingTop = UDim.new(0, 9); pad2.PaddingBottom = UDim.new(0, 11)
		pad2.PaddingLeft = UDim.new(0, 12); pad2.PaddingRight = UDim.new(0, 12); pad2.Parent = box
		local lay2 = Instance.new("UIListLayout"); lay2.SortOrder = Enum.SortOrder.LayoutOrder; lay2.Padding = UDim.new(0, 4); lay2.Parent = box

		local hLbl = Instance.new("TextLabel")
		hLbl.LayoutOrder = 1; hLbl.Size = UDim2.new(1, 0, 0, 18)
		hLbl.BackgroundTransparency = 1; hLbl.FontFace = FontBold; hLbl.TextSize = 13
		hLbl.TextColor3 = Theme.AccentBlue; hLbl.TextXAlignment = Enum.TextXAlignment.Left
		hLbl.TextTruncate = Enum.TextTruncate.AtEnd; hLbl.TextWrapped = false; hLbl.Text = headerText; hLbl.Parent = box

		local buffLbl = Instance.new("TextLabel")
		buffLbl.LayoutOrder = 2; buffLbl.Size = UDim2.new(1, 0, 0, 20)
		buffLbl.BackgroundTransparency = 1; buffLbl.FontFace = FontBold; buffLbl.TextSize = 15
		buffLbl.TextColor3 = Color3.fromRGB(255, 255, 255); buffLbl.TextXAlignment = Enum.TextXAlignment.Left
		buffLbl.TextTruncate = Enum.TextTruncate.AtEnd; buffLbl.TextWrapped = false; buffLbl.Text = buffText; buffLbl.Parent = box

		local subLbl = Instance.new("TextLabel")
		subLbl.LayoutOrder = 3; subLbl.Size = UDim2.new(1, 0, 0, 16); subLbl.AutomaticSize = Enum.AutomaticSize.Y
		subLbl.BackgroundTransparency = 1; subLbl.FontFace = FontMedium; subLbl.TextSize = 12; subLbl.LineHeight = 1.2
		subLbl.TextColor3 = Theme.TextSecondary; subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.TextWrapped = true; subLbl.Text = subText; subLbl.Parent = box

		return hLbl, buffLbl, subLbl
	end

	return api
end

RtState.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(string.gsub(RtState.SearchBox.Text or "", "^%s*(.-)%s*$", "%1"))
	for _, entry in ipairs(RtState.AllSearchableCards) do
		if q == "" then
			entry.Card.Visible = true
		else
			local matched = false
			for _, kw in ipairs(entry.Keywords) do
				if string.find(kw, q, 1, true) then
					matched = true
					break
				end
			end
			entry.Card.Visible = matched
		end
	end
end)

--====================================================================--
-- TABS & CARDS EXAMPLE (แก้ไข/เพิ่ม Tab และ Card ของแมพใหม่ตรงนี้ได้เลย)
-- ไอคอนที่มีให้ใช้: "main", "quests", "raid_swords", "dragon_crest", "daily_star",
-- "unit_crest", "rod_skills", "rod_quest", "auto_fish", "sell_lock", "skill_book",
-- "gacha", "ocean_chest", "aura_sparkle", "reroll_bolt", "vehicle", "keybind", "settings"
--====================================================================--
RtState.TabMain = createTab("Main", "main")
RtState.TabReward = createTab("Reward", "daily_star")
RtState.TabUpgrade = createTab("Upgrade", "reroll_bolt")
RtState.TabSettings = createTab("Settings", "settings")


--====================================================================--
-- [TAB 1: MAIN (NET A FISH - AUTO THROW, REEL ON FULL & AUTO MINIGAME)]
--====================================================================--
do
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local ThrowNet = Remotes:WaitForChild("ThrowNet")
	local ReelIn = Remotes:WaitForChild("ReelIn")
	local SellFish = Remotes:WaitForChild("SellFish")
	local NetFull = Remotes:FindFirstChild("NetFull")
	local FishingShared = nil
	pcall(function()
		FishingShared = require(ReplicatedStorage:WaitForChild("FishingShared"))
	end)

	-- Event Remotes
	local MegEvent = Remotes:WaitForChild("MegEvent")
	local BloopEvent = Remotes:WaitForChild("BloopEvent")
	local BossEvent = Remotes:WaitForChild("BossEvent")
	local PirateEvent = Remotes:FindFirstChild("PirateEvent")
	pcall(function() LocalPlayer:SetAttribute("Set_Cutscenes", false) end)

	-- Config Defaults
	Cfg.AutoFishFull = (Cfg.AutoFishFull == true)
	Cfg.AutoSellOnReel = (Cfg.AutoSellOnReel ~= false)
	Cfg.AutoMinigame = (Cfg.AutoMinigame == true)
	Cfg.MinigameDiff = Cfg.MinigameDiff or "EXTREME"
	Cfg.AutoCollectReward = (Cfg.AutoCollectReward ~= false)

	-- Event Config Defaults
	Cfg.AutoEventsMaster = (Cfg.AutoEventsMaster ~= false)
	Cfg.AutoMeg = (Cfg.AutoMeg ~= false)
	Cfg.AutoBloop = (Cfg.AutoBloop ~= false)
	Cfg.AutoKraken = (Cfg.AutoKraken ~= false)
	Cfg.AutoPirate = (Cfg.AutoPirate ~= false)
	Cfg.AutoClaimEventLoot = (Cfg.AutoClaimEventLoot ~= false)

	-- Plot Config Defaults
	Cfg.AutoCollectPlotMoney = (Cfg.AutoCollectPlotMoney ~= false)
	Cfg.PlotCollectInterval = Cfg.PlotCollectInterval or 5

	-- Fishing Helpers
	local function getNetCapacity()
		local castHUD = PlayerGui:FindFirstChild("CastHUD")
		if not castHUD then return nil, nil end
		local card = castHUD:FindFirstChild("Card")
		if not card or not card.Visible then return nil, nil end
		for _, desc in ipairs(card:GetDescendants()) do
			if desc:IsA("TextLabel") and string.find(desc.Text, "^%d+%s*/%s*%d+$") then
				local c, m = string.match(desc.Text, "(%d+)%s*/%s*(%d+)")
				if c and m then return tonumber(c), tonumber(m) end
			end
		end
		return nil, nil
	end

	local function isFishingActive()
		local castHUD = PlayerGui:FindFirstChild("CastHUD")
		if not castHUD then return false end
		local card = castHUD:FindFirstChild("Card")
		return (card and card.Visible == true)
	end

	local serverFullTriggered = false
	if NetFull then
		NetFull.OnClientEvent:Connect(function()
			serverFullTriggered = true
		end)
	end

	-- Card 1: Fishing Automation (Left Column)
	local FishCard = createSectionCard(RtState.TabMain.Left, "Fishing Automation", "fish")
	RtState.StatusTitleLbl, RtState.StatusBodyLbl = FishCard:AddInfoParagraph(
		"Status: Idle",
		"Net: Waiting..."
	)

	FishCard:AddToggle("AutoFishFull", "Auto Fish Until Full & Reel", Cfg.AutoFishFull, function(val)
		Cfg.AutoFishFull = val
		if not val then
			if RtState.StatusTitleLbl then RtState.StatusTitleLbl.Text = "Status: Idle (OFF)" end
			if RtState.StatusBodyLbl then RtState.StatusBodyLbl.Text = "Net: Waiting..." end
		end
	end)

	FishCard:AddToggle("AutoSellOnReel", "Auto Sell After Reel", Cfg.AutoSellOnReel, function(val)
		Cfg.AutoSellOnReel = val
	end)

	FishCard:AddButton("Throw Net Now", function()
		pcall(function() ThrowNet:FireServer() end)
	end)

	FishCard:AddButton("Reel In Now", function()
		pcall(function() ReelIn:FireServer() end)
	end)

	-- Card 2: Event Automation (Left Column, Under Fishing)
	local EventCard = createSectionCard(RtState.TabMain.Left, "Event Automation", "sparkles")
	RtState.EventStatusTitleLbl, RtState.EventStatusBodyLbl = EventCard:AddInfoParagraph(
		"Event: Checking...",
		"Up Next: Waiting..."
	)

	EventCard:AddToggle("AutoEventsMaster", "Auto All Events (Master)", Cfg.AutoEventsMaster ~= false, function(val)
		Cfg.AutoEventsMaster = val
		if not val and RtState.EventStatusTitleLbl then
			RtState.EventStatusTitleLbl.Text = "Event: Idle (OFF)"
		end
	end)

	EventCard:AddToggle("AutoMeg", "Auto Megalodon (Spear Gun)", Cfg.AutoMeg ~= false, function(val)
		Cfg.AutoMeg = val
	end)

	EventCard:AddToggle("AutoBloop", "Auto The Bloop (Spear Gun)", Cfg.AutoBloop ~= false, function(val)
		Cfg.AutoBloop = val
	end)

	EventCard:AddToggle("AutoKraken", "Auto The Kraken (Net / Dock)", Cfg.AutoKraken ~= false, function(val)
		Cfg.AutoKraken = val
	end)

	EventCard:AddToggle("AutoPirate", "Auto Pirate Raid (Net Ships)", Cfg.AutoPirate ~= false, function(val)
		Cfg.AutoPirate = val
	end)

	EventCard:AddToggle("AutoClaimEventLoot", "Auto Claim Boss & Raid Loot", Cfg.AutoClaimEventLoot ~= false, function(val)
		Cfg.AutoClaimEventLoot = val
	end)

	-- Card 3: Minigame Automation (Right Column)
	local MiniGameCard = createSectionCard(RtState.TabMain.Right, "Minigame Automation", "gacha")
	RtState.MgStatusTitleLbl, RtState.MgStatusBodyLbl = MiniGameCard:AddInfoParagraph(
		"Minigame: Idle",
		"Difficulty: " .. tostring(Cfg.MinigameDiff)
	)

	MiniGameCard:AddToggle("AutoMinigame", "Auto Play All Minigames", Cfg.AutoMinigame, function(val)
		Cfg.AutoMinigame = val
		if not val then
			if RtState.MgStatusTitleLbl then RtState.MgStatusTitleLbl.Text = "Minigame: Idle (OFF)" end
		end
	end)

	local diffOptions = {"EASY", "MEDIUM", "HARD", "HARDCORE", "EXTREME"}
	MiniGameCard:AddSingleDropdown("MinigameDiff", "Select Difficulty", diffOptions, Cfg.MinigameDiff or "EXTREME", function(val)
		Cfg.MinigameDiff = val
		if RtState.MgStatusBodyLbl then
			RtState.MgStatusBodyLbl.Text = "Difficulty: " .. tostring(val)
		end
	end)

	MiniGameCard:AddToggle("AutoCollectReward", "Auto Collect Rewards", Cfg.AutoCollectReward, function(val)
		Cfg.AutoCollectReward = val
	end)

	-- Card 4: Plot Automation (Right Column, Under Minigames)
	local PlotCard = createSectionCard(RtState.TabMain.Right, "Plot Automation", "sell_lock")
	RtState.PlotStatusTitleLbl, RtState.PlotStatusBodyLbl = PlotCard:AddInfoParagraph(
		"Plot Status: Active",
		"Pedestals: 13 Total"
	)

	PlotCard:AddToggle("AutoCollectPlotMoney", "Auto Collect Plot Money", Cfg.AutoCollectPlotMoney ~= false, function(val)
		Cfg.AutoCollectPlotMoney = val
		if not val and RtState.PlotStatusTitleLbl then
			RtState.PlotStatusTitleLbl.Text = "Plot: Idle (OFF)"
		end
	end)

	PlotCard:AddSlider("PlotCollectInterval", "Collect Interval", 2, 30, Cfg.PlotCollectInterval or 5, 1, "s", function(val)
		Cfg.PlotCollectInterval = val
	end)

	local function collectPlotMoney(force: boolean?) end

	PlotCard:AddButton("Collect Plot Money Now", function()
		task.spawn(function()
			if collectPlotMoney then
				collectPlotMoney(true)
			end
		end)
	end)

	local vim = game:GetService("VirtualInputManager")
	local numKeyMap = {
		[1] = Enum.KeyCode.One,
		[2] = Enum.KeyCode.Two,
		[3] = Enum.KeyCode.Three,
		[4] = Enum.KeyCode.Four,
		[5] = Enum.KeyCode.Five
	}

	local function pressKey(kc: Enum.KeyCode)
		pcall(function()
			vim:SendKeyEvent(true, kc, false, game)
			task.wait(0.02)
			vim:SendKeyEvent(false, kc, false, game)
		end)
	end

	local function clickGuiBtn(btn: Instance?)
		if not btn then return end
		pcall(function()
			if btn:IsA("GuiButton") then
				for _, c in ipairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
				for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
				for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
			end
			for _, desc in ipairs(btn:GetDescendants()) do
				if desc:IsA("GuiButton") then
					for _, c in ipairs(getconnections(desc.MouseButton1Down)) do c:Fire() end
					for _, c in ipairs(getconnections(desc.MouseButton1Click)) do c:Fire() end
					for _, c in ipairs(getconnections(desc.Activated)) do c:Fire() end
				end
			end
		end)
	end

	-- Plot Money Collection Helpers
	local function getMyBase()
		local bases = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Bases")
		if not bases then return nil end
		for _, base in ipairs(bases:GetChildren()) do
			if base:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
				return base
			end
		end
		return nil
	end

	local function getMySpearGunPos()
		local myBase = getMyBase()
		if not myBase then return nil end
		local sg = myBase:FindFirstChild("SpearGun")
		if not sg then return nil end
		local p = sg:GetAttribute("GunPivot")
		if typeof(p) == "CFrame" then return p.Position end
		return sg:GetPivot().Position
	end

	local isCollectingPlot = false
	collectPlotMoney = function(force: boolean?)
		if isCollectingPlot then return end
		if not force and Cfg.AutoCollectPlotMoney == false then return end

		local myBase = getMyBase()
		if not myBase then
			if RtState.PlotStatusTitleLbl then
				RtState.PlotStatusTitleLbl.Text = "Plot: Base Not Found"
			end
			return
		end

		local pedestals = myBase:FindFirstChild("Pedestals")
		if not pedestals then return end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end

		-- Check if minigame is actively playing
		local mgUI = PlayerGui:FindFirstChild("MiniGameUI")
		if mgUI then
			for _, ch in ipairs(mgUI:GetChildren()) do
				if ch.Name == "Window" and ch.Visible then
					local b = ch:FindFirstChild("Body")
					if b and (b:FindFirstChild("Area") or b:FindFirstChild("Bottom") or b:FindFirstChild("PlayButton")) then
						return
					end
				end
			end
		end

		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local CollectPadReq = Remotes and Remotes:FindFirstChild("CollectPadReq")

		local toCollect = {}
		local totalPeds = 0
		for _, ped in ipairs(pedestals:GetChildren()) do
			totalPeds = totalPeds + 1
			local collect = ped:FindFirstChild("Collect")
			local pad = collect and collect:FindFirstChild("Pad")
			local label = collect and collect:FindFirstChild("LabelAnchor") and collect.LabelAnchor:FindFirstChild("CollectInfo")
			local amtLbl = label and label:FindFirstChild("Amount")
			local amtText = amtLbl and amtLbl.Text or ""
			if pad and amtText ~= "" and amtText ~= "$0" then
				table.insert(toCollect, {
					ped = ped,
					pad = pad,
					slot = ped:GetAttribute("Slot") or totalPeds,
					amt = amtText
				})
			end
		end

		if #toCollect == 0 then
			if RtState.PlotStatusTitleLbl then
				RtState.PlotStatusTitleLbl.Text = "Plot: All Collected ($0)"
			end
			if RtState.PlotStatusBodyLbl then
				RtState.PlotStatusBodyLbl.Text = string.format("Base: %s | Pedestals: %d", myBase.Name, totalPeds)
			end
			return
		end

		isCollectingPlot = true
		if RtState.PlotStatusTitleLbl then
			RtState.PlotStatusTitleLbl.Text = string.format("Plot: Collecting %d Pedestals...", #toCollect)
		end

		local savedCF = hrp.CFrame
		local cam = workspace.CurrentCamera
		local savedCamCF = cam and cam.CFrame

		-- 1. Anti-Trip & Anti-Ragdoll setup
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum.PlatformStand = false
			hum.Sit = false
		end)

		-- 2. Freeze camera in place so screen never shakes or jerks
		if cam and savedCamCF then
			pcall(function()
				cam.CameraType = Enum.CameraType.Scriptable
				cam.CFrame = savedCamCF
			end)
		end

		-- 3. Temporarily disable part collisions so character never trips on ped geometry
		local collParts = {}
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				table.insert(collParts, p)
				p.CanCollide = false
			end
		end

		local collectedCount = 0

		-- 4. Blazing Fast TP Sweep (0.045s per pedestal, hovering 1.8 studs above pad)
		for _, item in ipairs(toCollect) do
			if not ScriptAlive or not hrp or not hrp.Parent then break end

			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(item.pad.Position + Vector3.new(0, 1.8, 0))

			if CollectPadReq and item.slot then
				pcall(function() CollectPadReq:FireServer(item.slot) end)
			end
			task.wait(0.045)
			collectedCount = collectedCount + 1
		end

		-- 5. Restore original position, velocity, and upright state
		if hrp and hrp.Parent then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = savedCF
		end

		for _, p in ipairs(collParts) do
			if p.Parent then p.CanCollide = true end
		end

		pcall(function()
			hum.PlatformStand = false
			hum.Sit = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)

		-- 6. Restore camera view
		if cam and savedCamCF then
			pcall(function()
				cam.CFrame = savedCamCF
				cam.CameraType = Enum.CameraType.Custom
			end)
		end

		if RtState.PlotStatusTitleLbl then
			RtState.PlotStatusTitleLbl.Text = string.format("Plot: Collected %d Pedestals!", collectedCount)
		end
		if RtState.PlotStatusBodyLbl then
			RtState.PlotStatusBodyLbl.Text = string.format("Base: %s | Last Sweep: %s", myBase.Name, os.date("%X"))
		end

		isCollectingPlot = false
	end

	-- 1. Main Fishing Automation Thread (Throw Net -> Wait for Full -> Reel In)
	task.spawn(function()
		while ScriptAlive do
			if Cfg.AutoFishFull then
				local isMegActive = (workspace:GetAttribute("MegActive") == true and Cfg.AutoMeg ~= false)
				local isBloopActive = (workspace:GetAttribute("BloopActive") == true and Cfg.AutoBloop ~= false)
				local inTurret = (LocalPlayer:GetAttribute("TurretMode") == true)

				if isMegActive or isBloopActive or inTurret then
					task.wait(0.5)
				else
					if not isFishingActive() then
					if RtState.StatusTitleLbl then
						RtState.StatusTitleLbl.Text = "Status: Throwing Net..."
					end
					pcall(function() ThrowNet:FireServer() end)
					serverFullTriggered = false
					task.wait(1.0)
				else
					local cur, max = getNetCapacity()
					if cur and max then
						local pct = math.floor((cur / math.max(1, max)) * 100)
						if RtState.StatusTitleLbl then
							RtState.StatusTitleLbl.Text = string.format("Status: Fishing (%d%%)", pct)
						end
						if RtState.StatusBodyLbl then
							RtState.StatusBodyLbl.Text = string.format("Capacity: %d / %d (%d%%)", cur, max, pct)
						end

						if cur >= max or serverFullTriggered then
							if RtState.StatusTitleLbl then
								RtState.StatusTitleLbl.Text = "Status: Net Full! Reeling In..."
							end
							pcall(function() ReelIn:FireServer() end)
							serverFullTriggered = false
							task.wait(0.5)

							if Cfg.AutoSellOnReel then
								if RtState.StatusTitleLbl then
									RtState.StatusTitleLbl.Text = "Status: Selling fish..."
								end
								pcall(function() SellFish:FireServer() end)
								task.wait(0.5)
							end

							if Cfg.AutoCollectPlotMoney ~= false then
								task.defer(function()
									pcall(function() collectPlotMoney(false) end)
								end)
							end
							task.wait(1.0)
						end
					else
						if serverFullTriggered then
							pcall(function() ReelIn:FireServer() end)
							serverFullTriggered = false
							task.wait(1.0)
						end
					end
				end
				end
			end
			task.wait(0.25)
		end
	end)

	-- 2. Minigame Auto-Solver Thread (100% Precision via Simulation Synchronization & Memory Extraction)
	task.spawn(function()
		local lastReelHit = 0
		local lastSpotSwing = { 0, 0, 0, 0, 0 }
		local lastBaitSolvedRound = -1

		while ScriptAlive do
			if Cfg.AutoMinigame then
				local mgUI = PlayerGui:FindFirstChild("MiniGameUI")
				if mgUI then
					local inviteWin, gameWin = nil, nil
					for _, ch in ipairs(mgUI:GetChildren()) do
						if ch.Name == "Window" then
							local b = ch:FindFirstChild("Body")
							if b then
								if b:FindFirstChild("PlayButton") then
									inviteWin = ch
								elseif b:FindFirstChild("Area") or b:FindFirstChild("Bottom") or b:FindFirstChild("Result") then
									gameWin = ch
								end
							end
						end
					end

					-- Phase 1: Invite / Difficulty Dialog
					if inviteWin and inviteWin.Visible then
						local b = inviteWin.Body
						local playBtn = b:FindFirstChild("PlayButton")
						if playBtn and playBtn.Visible then
							local target = string.upper(Cfg.MinigameDiff or "EXTREME")
							local diffMap = {
								EASY = "DiffEasy",
								MEDIUM = "DiffMedium",
								HARD = "DiffHard",
								HARDCORE = "DiffHardcore",
								EXTREME = "DiffExtreme"
							}
							local btnName = diffMap[target] or "DiffExtreme"
							local diffBtn = b:FindFirstChild(btnName, true)
							if diffBtn then
								clickGuiBtn(diffBtn)
								task.wait(0.12)
							end

							if RtState.MgStatusTitleLbl then
								RtState.MgStatusTitleLbl.Text = "Minigame: Starting " .. target
							end
							clickGuiBtn(playBtn)
							task.wait(0.4)
						end
					end

					-- Phase 2: Active Gameplay or Result Dialog
					if gameWin and gameWin.Visible then
						local body = gameWin.Body
						local resultFrame = body:FindFirstChild("Result")

						-- A. Post-game Results Screen (Claim)
						if resultFrame and resultFrame.Visible then
							lastBaitSolvedRound = -1
							if Cfg.AutoCollectReward then
								local collectBtn = resultFrame:FindFirstChild("Collect", true)
								if collectBtn and collectBtn.Visible then
									if RtState.MgStatusTitleLbl then
										RtState.MgStatusTitleLbl.Text = "Minigame: Claiming Reward!"
									end
									clickGuiBtn(collectBtn)
									task.wait(0.6)
								end
							end
						else
							-- B. Live Minigame Execution
							local area = body:FindFirstChild("Area")
							local bottom = body:FindFirstChild("Bottom")

							if area and area.Visible then
								-- 1) Minigame: Perfect Reel
								local reelBtn = (bottom and bottom:FindFirstChild("ReelButton", true)) or body:FindFirstChild("ReelButton", true)
								if reelBtn and reelBtn.Visible then
									if RtState.MgStatusTitleLbl then
										RtState.MgStatusTitleLbl.Text = "Playing: Perfect Reel (100% Perfect)..."
									end

									local pressFn = nil
									local reelSim = nil
									local sessionObj = nil

									local rBtn = reelBtn:IsA("GuiButton") and reelBtn or reelBtn:FindFirstChildWhichIsA("GuiButton")
									if rBtn then
										for _, c in ipairs(getconnections(rBtn.MouseButton1Down)) do
											if c.Function then
												pressFn = c.Function
												for _, uv in pairs(getupvalues(c.Function)) do
													if type(uv) == "table" and uv.press and uv.xAt and uv.zc and uv.zw then
														reelSim = uv
													elseif type(uv) == "table" and uv.now and uv.live ~= nil then
														sessionObj = uv
													end
												end
											end
										end
									end

									if not pressFn then
										local fullBtn = area:FindFirstChildWhichIsA("TextButton")
										if fullBtn then
											for _, c in ipairs(getconnections(fullBtn.MouseButton1Down)) do
												if c.Function then
													pressFn = c.Function
													for _, uv in pairs(getupvalues(c.Function)) do
														if type(uv) == "table" and uv.press and uv.xAt and uv.zc and uv.zw then
															reelSim = uv
														elseif type(uv) == "table" and uv.now and uv.live ~= nil then
															sessionObj = uv
														end
													end
												end
											end
										end
									end

									if reelSim and sessionObj and (not sessionObj.over or not sessionObj.over()) and sessionObj.live then
										local curTime = sessionObj.now()
										local canHit = (not reelSim.lockUntil) or (curTime >= reelSim.lockUntil)
										if canHit then
											local sDist = (reelSim.seenDist and reelSim.seenDist(curTime)) or 999
											local curX = reelSim.xAt(curTime)
											local instDist = math.abs(curX - reelSim.zc)
											local hitThreshold = reelSim.zw * 0.15

											if sDist <= hitThreshold or instDist <= hitThreshold then
												if pressFn then pcall(function() pressFn() end) end
												clickGuiBtn(reelBtn)
												pressKey(Enum.KeyCode.Space)
											end
										end
									else
										local track, needle, goldZone = nil, nil, nil
										for _, desc in ipairs(area:GetDescendants()) do
											if desc:IsA("Frame") and desc.Size.Y.Offset >= 50 and desc.Size.Y.Offset <= 60 and desc.AbsoluteSize.X > 200 then
												track = desc
												break
											end
										end

										if track then
											for _, ch in ipairs(track:GetChildren()) do
												if ch:IsA("Frame") then
													if ch.Size.X.Offset >= 4 and ch.Size.X.Offset <= 16 then
														needle = ch
													elseif ch.BackgroundColor3.G > ch.BackgroundColor3.R and ch.BackgroundColor3.G > ch.BackgroundColor3.B then
														for _, sub in ipairs(ch:GetChildren()) do
															if sub:IsA("Frame") and sub.BackgroundColor3.R > 0.8 and sub.BackgroundColor3.G > 0.7 then
																goldZone = sub
															end
														end
													end
												end
											end
										end

										if needle and goldZone then
											local nX = needle.AbsolutePosition.X + needle.AbsoluteSize.X / 2
											local zMin = goldZone.AbsolutePosition.X
											local zMax = goldZone.AbsolutePosition.X + goldZone.AbsoluteSize.X
											if nX >= (zMin - 4) and nX <= (zMax + 4) then
												if (os.clock() - lastReelHit) >= 0.28 then
													lastReelHit = os.clock()
													clickGuiBtn(reelBtn)
													pressKey(Enum.KeyCode.Space)
												end
											end
										end
									end
								end

								-- 2) Minigame: Fish Frenzy (Jump)
								local spot1 = area:FindFirstChild("Spot1")
								if spot1 then
									local swingFn = nil
									local jumpSim = nil
									local sessionObj = nil

									local sBtn = spot1:IsA("GuiButton") and spot1 or spot1:FindFirstChildWhichIsA("GuiButton")
									if sBtn then
										for _, c in ipairs(getconnections(sBtn.MouseButton1Click)) do
											if c.Function then
												for _, uv in pairs(getupvalues(c.Function)) do
													if type(uv) == "function" then
														swingFn = uv
														for _, subUv in pairs(getupvalues(uv)) do
															if type(subUv) == "table" and subUv.spots and subUv.swing then
																jumpSim = subUv
															elseif type(subUv) == "table" and subUv.now and subUv.live ~= nil then
																sessionObj = subUv
															end
														end
													end
												end
											end
										end
									end

									local hitAny = false
									local now = os.clock()

									if jumpSim and jumpSim.spots then
										for i = 1, 5 do
											local sp = jumpSim.spots[i]
											if sp and sp.item and not sp.item.gone then
												if sp.item.kind ~= "boot" then
													if (now - (lastSpotSwing[i] or 0)) >= 0.28 then
														lastSpotSwing[i] = now
														hitAny = true
														if swingFn then pcall(function() swingFn(i) end) end
														local uiSpot = area:FindFirstChild("Spot" .. i)
														if uiSpot then clickGuiBtn(uiSpot) end
														if numKeyMap[i] then pressKey(numKeyMap[i]) end
													end
												end
											end
										end
									else
										for i = 1, 5 do
											local sp = area:FindFirstChild("Spot" .. i)
											if sp and sp.Visible then
												local hasFish = false
												local isBoot = false
												for _, desc in ipairs(sp:GetDescendants()) do
													if desc:IsA("TextLabel") and desc.Visible and desc.TextTransparency < 0.4 then
														local txt = desc.Text
														if string.find(txt, "👢") or string.find(string.lower(txt), "boot") then
															isBoot = true
															break
														elseif string.find(txt, "🐟") or string.find(txt, "🐠") or string.find(txt, "🐡") then
															hasFish = true
														end
													end
												end

												if hasFish and not isBoot then
													if (now - (lastSpotSwing[i] or 0)) >= 0.28 then
														lastSpotSwing[i] = now
														hitAny = true
														clickGuiBtn(sp)
														if numKeyMap[i] then pressKey(numKeyMap[i]) end
													end
												end
											end
										end
									end

									if hitAny and RtState.MgStatusTitleLbl then
										RtState.MgStatusTitleLbl.Text = "Playing: Fish Frenzy (100% No Boots)..."
									end
								end

								-- 3) Minigame: Bait Memory (Lures - 100% Exact Memory Sequence Reader)
								local bait1 = area:FindFirstChild("Bait1", true)
								if bait1 then
									local u168Fn = nil
									local bBtn = bait1:IsA("GuiButton") and bait1 or bait1:FindFirstChildWhichIsA("GuiButton")
									if bBtn then
										for _, c in ipairs(getconnections(bBtn.MouseButton1Click)) do
											if c.Function then
												local uv1 = getupvalue(c.Function, 1)
												if type(uv1) == "function" then
													u168Fn = uv1
													break
												end
											end
										end
									end

									if u168Fn then
										local isTurn = getupvalue(u168Fn, 1) -- u159 (true = YOUR TURN)
										local sessionObj = getupvalue(u168Fn, 2)
										local seqTable = getupvalue(u168Fn, 3) -- u157 (exact secret sequence array)
										local curStep = getupvalue(u168Fn, 4) -- u160 (current step the game expects)
										local isOver = sessionObj and sessionObj.over and sessionObj.over()

										if isTurn == true and not isOver and type(seqTable) == "table" and type(curStep) == "number" then
											if curStep >= 1 and curStep <= #seqTable then
												local targetBait = seqTable[curStep]
												if targetBait and targetBait >= 1 and targetBait <= 4 then
													if RtState.MgStatusTitleLbl then
														RtState.MgStatusTitleLbl.Text = string.format("Bait Memory: Step %d/%d (Bait %d)", curStep, #seqTable, targetBait)
													end
													pcall(function() u168Fn(targetBait) end)
													task.wait(0.28)
												end
											end
										else
											if RtState.MgStatusTitleLbl then
												RtState.MgStatusTitleLbl.Text = "Bait Memory: Watching fish..."
											end
										end
									end
								end
							end
						end
					end
				end
			end
			if gameWin and gameWin.Visible then
				task.wait(0.01)
			else
				task.wait(0.04)
			end
		end
	end)

	-- 3. All-Events Automation Thread (Kraken, Megalodon, Bloop, Pirate Raid, Wave Rush, Weather)
	task.spawn(function()
		local lastSpearFire = 0
		local lastTurretEnterAttempt = 0
		local megWasActive = false
		local bloopWasActive = false
		local bossWasActive = false
		local savedFishingCF = nil

		while ScriptAlive do
			if Cfg.AutoEventsMaster ~= false then
				local serverTime = workspace:GetServerTimeNow()
				local isBossActive = (workspace:GetAttribute("BossActive") == true)
				local isMegActive = (workspace:GetAttribute("MegActive") == true)
				local isBloopActive = (workspace:GetAttribute("BloopActive") == true)
				local isPirateActive = (workspace:GetAttribute("PirateActive") == true)
				local isWaveActive = (workspace:GetAttribute("WaveRush") == true or workspace:GetAttribute("WaveActive") == true)
				local riverEvent = workspace:GetAttribute("RiverEvent")

				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				-- Determine Current Active Event
				local activeName = "None"
				if isMegActive then activeName = "Megalodon"
				elseif isBloopActive then activeName = "The Bloop"
				elseif isBossActive then activeName = "The Kraken"
				elseif isPirateActive then activeName = "Pirate Raid"
				elseif isWaveActive then activeName = "Wave Rush"
				elseif riverEvent and #riverEvent > 0 then activeName = riverEvent
				end

				-- Determine Next Event & Time
				local nextName = "None"
				local nextTime = 999999
				local function checkNext(name, attr)
					local t = workspace:GetAttribute(attr)
					if t and (t - serverTime) > 0 and (t - serverTime) < nextTime then
						nextTime = t - serverTime
						nextName = name
					end
				end
				checkNext("Kraken", "BossNext")
				checkNext("Megalodon", "MegNext")
				checkNext("The Bloop", "BloopNext")
				checkNext("Pirate Raid", "PirateNext")
				checkNext("Wave Rush", "NextWaveRush")
				checkNext("River Event", "NextRiverEvent")

				if RtState.EventStatusTitleLbl then
					RtState.EventStatusTitleLbl.Text = "Event: " .. activeName
				end
				if RtState.EventStatusBodyLbl then
					if nextTime < 999999 then
						local m = math.floor(nextTime / 60)
						local s = math.floor(nextTime % 60)
						RtState.EventStatusBodyLbl.Text = string.format("Up Next: %s in %d:%02d", nextName, m, s)
					else
						RtState.EventStatusBodyLbl.Text = "Up Next: Waiting..."
					end
				end

				local myBase = getMyBase()
				local sg = myBase and myBase:FindFirstChild("SpearGun")
				local gunPivot = sg and sg:GetPivot()
				local gunPos = gunPivot and gunPivot.Position or (hrp and hrp.Position)

				-- 1) MEGALODON (Spear Gun Boss - Turret Mode + Math-calculated Trajectory)
				if isMegActive and Cfg.AutoMeg ~= false then
					megWasActive = true
					local inTurret = (LocalPlayer:GetAttribute("TurretMode") == true)

					if not inTurret then
						if hrp and not savedFishingCF then
							savedFishingCF = hrp.CFrame
						end

						if isFishingActive() then
							pcall(function() ReelIn:FireServer() end)
						end

						if sg and hrp and hum and hum.Health > 0 then
							local p = sg:GetAttribute("GunPivot")
							local gPos = typeof(p) == "CFrame" and p.Position or sg:GetPivot().Position
							local fwdAttr = sg:GetAttribute("Fwd")
							local fwd = typeof(fwdAttr) == "Vector3" and Vector3.new(fwdAttr.X, 0, fwdAttr.Z).Unit or sg:GetPivot().LookVector
							local standPos = Vector3.new(gPos.X, hrp.Position.Y, gPos.Z) - fwd * 4.5
							local standCF = CFrame.lookAt(standPos, standPos + fwd)

							if (hrp.Position - standPos).Magnitude > 6 then
								pcall(function()
									hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
									hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
									hum:ChangeState(Enum.HumanoidStateType.GettingUp)
									hrp.AssemblyLinearVelocity = Vector3.zero
									hrp.AssemblyAngularVelocity = Vector3.zero
									hrp.CFrame = standCF
								end)
							end
						end

						local turretBtn = nil
						local banner = PlayerGui:FindFirstChild("MegBannerUI")
						if banner then
							turretBtn = banner:FindFirstChild("TurretGo", true)
						end
						if not turretBtn then
							turretBtn = PlayerGui:FindFirstChild("TurretGo", true)
						end
						if turretBtn and turretBtn.Visible then
							clickGuiBtn(turretBtn)
						end

						if (os.clock() - lastTurretEnterAttempt) >= 0.6 then
							lastTurretEnterAttempt = os.clock()
							pcall(function() MegEvent:FireServer("enter") end)
						end

						if RtState.EventStatusBodyLbl then
							RtState.EventStatusBodyLbl.Text = "Status: Entering Spear Gun Turret..."
						end
					else
						local startT = workspace:GetAttribute("MegStart") or serverTime
						local elapsed = math.max(0, serverTime - startT)
						local megPos = nil
						if FishingShared and FishingShared.MegPos then
							pcall(function() megPos = FishingShared.MegPos(elapsed) end)
						end
						if not megPos then
							local localMeg = workspace:FindFirstChild("MegalodonLocal")
							local root = localMeg and localMeg:FindFirstChild("Root", true)
							if root and root:IsA("BasePart") then
								megPos = root.Position
							end
						end

						if megPos and gunPos then
							local dist = (megPos - gunPos).Magnitude
							local maxRange = (FishingShared and FishingShared.Megalodon and FishingShared.Megalodon.Range) or 200
							local cd = (FishingShared and FishingShared.Megalodon and FishingShared.Megalodon.Cooldown) or 2.0

							if dist <= maxRange then
								if (os.clock() - lastSpearFire) >= (cd + 0.05) then
									lastSpearFire = os.clock()
									pcall(function() MegEvent:FireServer("fire", megPos) end)
									if RtState.EventStatusBodyLbl then
										RtState.EventStatusBodyLbl.Text = string.format("Spear: FIRED Meg! (Dist: %.0f, CD: %.1f)", dist, cd)
									end
								else
									if RtState.EventStatusBodyLbl then
										local rem = math.max(0, (cd + 0.05) - (os.clock() - lastSpearFire))
										RtState.EventStatusBodyLbl.Text = string.format("Spear: Reloading (%.1fs) | Dist: %.0f", rem, dist)
									end
								end
							else
								if RtState.EventStatusBodyLbl then
									RtState.EventStatusBodyLbl.Text = string.format("Target: Out of Range (Dist: %.0f > %d)", dist, maxRange)
								end
							end
						end
					end
				else
					if megWasActive then
						megWasActive = false
						if LocalPlayer:GetAttribute("TurretMode") == true then
							pcall(function() MegEvent:FireServer("leave") end)
						end
						if Cfg.AutoClaimEventLoot ~= false then
							pcall(function() MegEvent:FireServer("closed") end)
							local endUI = PlayerGui:FindFirstChild("MegEndUI")
							if endUI then pcall(function() endUI:Destroy() end) end
						end
						if savedFishingCF and hrp and hum and hum.Health > 0 then
							pcall(function()
								hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
								hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
								hum:ChangeState(Enum.HumanoidStateType.GettingUp)
								hrp.AssemblyLinearVelocity = Vector3.zero
								hrp.AssemblyAngularVelocity = Vector3.zero
								hrp.CFrame = savedFishingCF
							end)
							savedFishingCF = nil
						end
					end
				end

				-- 2) THE BLOOP (Spear Gun Boss - Turret Mode + Math-calculated Trajectory)
				if isBloopActive and Cfg.AutoBloop ~= false then
					bloopWasActive = true
					local inTurret = (LocalPlayer:GetAttribute("TurretMode") == true)

					if not inTurret then
						if hrp and not savedFishingCF then
							savedFishingCF = hrp.CFrame
						end

						if isFishingActive() then
							pcall(function() ReelIn:FireServer() end)
						end

						if sg and hrp and hum and hum.Health > 0 then
							local p = sg:GetAttribute("GunPivot")
							local gPos = typeof(p) == "CFrame" and p.Position or sg:GetPivot().Position
							local fwdAttr = sg:GetAttribute("Fwd")
							local fwd = typeof(fwdAttr) == "Vector3" and Vector3.new(fwdAttr.X, 0, fwdAttr.Z).Unit or sg:GetPivot().LookVector
							local standPos = Vector3.new(gPos.X, hrp.Position.Y, gPos.Z) - fwd * 4.5
							local standCF = CFrame.lookAt(standPos, standPos + fwd)

							if (hrp.Position - standPos).Magnitude > 6 then
								pcall(function()
									hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
									hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
									hum:ChangeState(Enum.HumanoidStateType.GettingUp)
									hrp.AssemblyLinearVelocity = Vector3.zero
									hrp.AssemblyAngularVelocity = Vector3.zero
									hrp.CFrame = standCF
								end)
							end
						end

						local turretBtn = nil
						local banner = PlayerGui:FindFirstChild("BloopBannerUI")
						if banner then
							turretBtn = banner:FindFirstChild("TurretGo", true)
						end
						if not turretBtn then
							turretBtn = PlayerGui:FindFirstChild("TurretGo", true)
						end
						if turretBtn and turretBtn.Visible then
							clickGuiBtn(turretBtn)
						end

						if (os.clock() - lastTurretEnterAttempt) >= 0.6 then
							lastTurretEnterAttempt = os.clock()
							pcall(function() BloopEvent:FireServer("enter") end)
						end

						if RtState.EventStatusBodyLbl then
							RtState.EventStatusBodyLbl.Text = "Status: Entering Spear Gun Turret..."
						end
					else
						local startT = workspace:GetAttribute("BloopStart") or serverTime
						local elapsed = math.max(0, serverTime - startT)
						local bloopPos = nil
						if FishingShared and FishingShared.BloopPos then
							pcall(function() bloopPos = FishingShared.BloopPos(elapsed) end)
						end
						if not bloopPos then
							local localBloop = workspace:FindFirstChild("BloopLocal")
							local root = localBloop and localBloop:FindFirstChild("Root", true)
							if root and root:IsA("BasePart") then
								bloopPos = root.Position
							end
						end

						if bloopPos and gunPos then
							local dist = (bloopPos - gunPos).Magnitude
							local maxRange = (FishingShared and FishingShared.Bloop and FishingShared.Bloop.Range) or 230
							local cd = (FishingShared and FishingShared.Bloop and FishingShared.Bloop.Cooldown) or 2.0

							if dist <= maxRange then
								if (os.clock() - lastSpearFire) >= (cd + 0.05) then
									lastSpearFire = os.clock()
									pcall(function() BloopEvent:FireServer("fire", bloopPos) end)
									if RtState.EventStatusBodyLbl then
										RtState.EventStatusBodyLbl.Text = string.format("Spear: FIRED Bloop! (Dist: %.0f, CD: %.1f)", dist, cd)
									end
								else
									if RtState.EventStatusBodyLbl then
										local rem = math.max(0, (cd + 0.05) - (os.clock() - lastSpearFire))
										RtState.EventStatusBodyLbl.Text = string.format("Spear: Reloading (%.1fs) | Dist: %.0f", rem, dist)
									end
								end
							else
								if RtState.EventStatusBodyLbl then
									RtState.EventStatusBodyLbl.Text = string.format("Target: Out of Range (Dist: %.0f > %d)", dist, maxRange)
								end
							end
						end
					end
				else
					if bloopWasActive then
						bloopWasActive = false
						if LocalPlayer:GetAttribute("TurretMode") == true then
							pcall(function() BloopEvent:FireServer("leave") end)
						end
						if Cfg.AutoClaimEventLoot ~= false then
							pcall(function() BloopEvent:FireServer("closed") end)
							local endUI = PlayerGui:FindFirstChild("BloopEndUI")
							if endUI then pcall(function() endUI:Destroy() end) end
						end
						if savedFishingCF and hrp and hum and hum.Health > 0 then
							pcall(function()
								hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
								hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
								hum:ChangeState(Enum.HumanoidStateType.GettingUp)
								hrp.AssemblyLinearVelocity = Vector3.zero
								hrp.AssemblyAngularVelocity = Vector3.zero
								hrp.CFrame = savedFishingCF
							end)
							savedFishingCF = nil
						end
					end
				end

				-- 3) THE KRAKEN / HOLLOW KING (Dock Net Boss - River Deployed Net Hits Kraken)
				if isBossActive and Cfg.AutoKraken ~= false then
					bossWasActive = true
					if not isFishingActive() then
						pcall(function() ThrowNet:FireServer() end)
						task.wait(0.5)
					else
						local cur, max = getNetCapacity()
						if cur and max and cur >= max then
							pcall(function() ReelIn:FireServer() end)
							task.wait(0.5)
							if Cfg.AutoSellOnReel then
								pcall(function() SellFish:FireServer() end)
								task.wait(0.5)
							end
							pcall(function() ThrowNet:FireServer() end)
						end
					end
				else
					if bossWasActive then
						bossWasActive = false
						if Cfg.AutoClaimEventLoot ~= false then
							pcall(function() BossEvent:FireServer("closed") end)
						end
					end
				end

				-- 4) PIRATE RAID (Net Ships for Chests)
				if isPirateActive and Cfg.AutoPirate ~= false then
					if not isFishingActive() then
						pcall(function() ThrowNet:FireServer() end)
						task.wait(0.5)
					else
						local cur, max = getNetCapacity()
						if cur and max and cur >= max then
							pcall(function() ReelIn:FireServer() end)
							task.wait(0.5)
							if Cfg.AutoSellOnReel then
								pcall(function() SellFish:FireServer() end)
								task.wait(0.5)
							end
							pcall(function() ThrowNet:FireServer() end)
						end
					end
				end

				-- 5) AUTO CLAIM EVENT REWARDS (Only when events are inactive)
				if Cfg.AutoClaimEventLoot ~= false and not isBossActive and not isMegActive and not isBloopActive and not isPirateActive then
					local pGui = PlayerGui
					for _, g in ipairs(pGui:GetChildren()) do
						if g:IsA("ScreenGui") and (g.Name == "PirateEndUI" or g.Name == "EventRecapUI" or string.find(g.Name, "EndUI") or g.Name == "CrateOpenUI") then
							local okBtn = g:FindFirstChild("PirateEndOK", true) or g:FindFirstChild("OK", true) or g:FindFirstChild("Collect", true) or g:FindFirstChild("Claim", true)
							if okBtn and okBtn:IsA("GuiButton") and okBtn.Visible then
								clickGuiBtn(okBtn)
							end
						end
					end
				end
			end
			task.wait(0.25)
		end
	end)

	-- 4. Plot Auto-Collection Background Thread
	task.spawn(function()
		while ScriptAlive do
			local interval = math.clamp(tonumber(Cfg.PlotCollectInterval) or 5, 2, 60)
			task.wait(interval)
			if Cfg.AutoCollectPlotMoney ~= false then
				pcall(function() collectPlotMoney(false) end)
			end
		end
	end)

	-- 5. Auto-Dismiss Popups, Crate Reveals & Dialogs Engine (Instant Reactive & Polling)
	local function checkAndDismissPopups()
		pcall(function()
			local pGui = PlayerGui

			-- A. CrateOpenUI ("YOU GOT PET / FISH!", "AWESOME!" Button)
			local crateUI = pGui:FindFirstChild("CrateOpenUI")
			if crateUI and crateUI.Enabled then
				for _, b in ipairs(crateUI:GetDescendants()) do
					if b:IsA("GuiButton") then
						clickGuiBtn(b)
					end
				end
				crateUI.Enabled = false
			end

			-- B. RebirthUnlocksUI ("REBIRTH X", "AWESOME!" Button)
			local rebirthUnl = pGui:FindFirstChild("RebirthUnlocksUI")
			if rebirthUnl then
				for _, b in ipairs(rebirthUnl:GetDescendants()) do
					if b:IsA("GuiButton") or b.Name == "UnlocksOk" then
						clickGuiBtn(b)
					end
				end
				rebirthUnl.Enabled = false
				pcall(function() rebirthUnl:Destroy() end)
			end

			-- B. Generic Reward / Reveal / End Dialogs
			for _, g in ipairs(pGui:GetChildren()) do
				if g:IsA("ScreenGui") and g ~= ScreenGui and g.Enabled then
					local gName = g.Name
					if gName == "CrateOpenUI" or gName == "EventRecapUI" or gName == "PirateEndUI" 
						or gName == "MegEndUI" or gName == "BloopEndUI" or gName == "AFKSummaryUI" 
						or gName == "OfflinePromoUI" or gName == "AutoThrowPromo" or gName == "PassOffer" 
						or gName == "RebirthOfferUI" or string.find(gName, "EndUI") or string.find(gName, "Promo") then
						
						for _, desc in ipairs(g:GetDescendants()) do
							if desc:IsA("GuiButton") and desc.Visible then
								local txt = ""
								if desc:IsA("TextButton") then
									txt = desc.Text
								else
									local lbl = desc:FindFirstChildWhichIsA("TextLabel", true)
									if lbl then txt = lbl.Text end
								end

								local u = string.upper(txt)
								if u:find("AWESOME") or u == "OK" or u:find("CLAIM") or u:find("COLLECT") or u == "CLOSE" or u == "DISMISS" or u == "X" or u:find("NO THANKS") or u:find("LATER") or desc.Name == "Button" or desc.Name == "PirateEndOK" then
									clickGuiBtn(desc)
								end
							end
						end
					else
						-- Check any stray buttons that say "AWESOME!"
						for _, desc in ipairs(g:GetDescendants()) do
							if desc:IsA("GuiButton") and desc.Visible then
								local txt = ""
								if desc:IsA("TextButton") then
									txt = desc.Text
								else
									local lbl = desc:FindFirstChildWhichIsA("TextLabel", true)
									if lbl then txt = lbl.Text end
								end
								if string.upper(txt):find("AWESOME") then
									clickGuiBtn(desc)
								end
							end
						end
					end
				end
			end
		end)
	end

	-- Reactive hook for CrateOpenUI
	pcall(function()
		local crateUI = PlayerGui:WaitForChild("CrateOpenUI", 10)
		if crateUI then
			table.insert(Connections, crateUI:GetPropertyChangedSignal("Enabled"):Connect(function()
				if crateUI.Enabled then
					task.wait(0.08)
					checkAndDismissPopups()
				end
			end))
		end
	end)

	-- Reactive hook for new ScreenGuis added
	table.insert(Connections, PlayerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child ~= ScreenGui then
			task.wait(0.08)
			checkAndDismissPopups()
		end
	end))

	-- Fast polling heartbeat loop
	task.spawn(function()
		while ScriptAlive do
			checkAndDismissPopups()
			task.wait(0.3)
		end
	end)
end

--====================================================================--
-- [TAB 2: REWARD (DAILY LOGIN, PLAYTIME GIFTS, LUCKY SPIN, CONTRACTS & PASS)]
--====================================================================--
do
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local RewardsRemote = Remotes:WaitForChild("Rewards")
	local RetentionRemote = Remotes:WaitForChild("Retention")
	local ContractsRemote = Remotes:WaitForChild("Contracts")
	local ChallengeRemote = Remotes:WaitForChild("Challenge")
	local SeasonPassRemote = Remotes:WaitForChild("SeasonPass")

	-- Config Defaults for Reward Automation
	Cfg.AutoClaimDailyMaster = (Cfg.AutoClaimDailyMaster ~= false)
	Cfg.AutoClaimDailyLogin = (Cfg.AutoClaimDailyLogin ~= false)
	Cfg.AutoClaimPlaytimeGifts = (Cfg.AutoClaimPlaytimeGifts ~= false)
	Cfg.AutoLuckySpin = (Cfg.AutoLuckySpin ~= false)
	Cfg.AutoClaimOffline = (Cfg.AutoClaimOffline ~= false)

	Cfg.AutoClaimSeasonPass = (Cfg.AutoClaimSeasonPass ~= false)
	Cfg.AutoPassAscension = (Cfg.AutoPassAscension == true)

	Cfg.AutoContractsMaster = (Cfg.AutoContractsMaster ~= false)
	Cfg.AutoClaimContracts = (Cfg.AutoClaimContracts ~= false)
	Cfg.AutoClaimDailyChallenge = (Cfg.AutoClaimDailyChallenge ~= false)
	Cfg.AutoRerollWait = (Cfg.AutoRerollWait == true)

	-- ================================================================
	-- LEFT COLUMN: Daily Rewards, Free Gifts, Lucky Wheel & Season Pass
	-- ================================================================

	-- Card 1: Daily & Playtime Rewards
	local DailyCard = createSectionCard(RtState.TabReward.Left, "Daily & Playtime Rewards", "daily_star")
	RtState.DailyStatusTitleLbl, RtState.DailyStatusBodyLbl = DailyCard:AddInfoParagraph(
		"Daily: Loading...",
		"Playtime: Checking gifts..."
	)

	DailyCard:AddToggle("AutoClaimDailyMaster", "Auto Claim All Daily & Gifts", Cfg.AutoClaimDailyMaster ~= false, function(val)
		Cfg.AutoClaimDailyMaster = val
		if not val then
			if RtState.DailyStatusTitleLbl then RtState.DailyStatusTitleLbl.Text = "Daily: Idle (OFF)" end
		end
	end)

	DailyCard:AddToggle("AutoClaimDailyLogin", "Auto Claim Daily Login (Streak)", Cfg.AutoClaimDailyLogin ~= false, function(val)
		Cfg.AutoClaimDailyLogin = val
	end)

	DailyCard:AddToggle("AutoClaimPlaytimeGifts", "Auto Claim Playtime Gifts (1 to 7)", Cfg.AutoClaimPlaytimeGifts ~= false, function(val)
		Cfg.AutoClaimPlaytimeGifts = val
	end)

	DailyCard:AddToggle("AutoLuckySpin", "Auto Spin Lucky Wheel (Every 30m)", Cfg.AutoLuckySpin ~= false, function(val)
		Cfg.AutoLuckySpin = val
	end)

	DailyCard:AddToggle("AutoClaimOffline", "Auto Claim Offline Welcome Cash", Cfg.AutoClaimOffline ~= false, function(val)
		Cfg.AutoClaimOffline = val
	end)

	local function claimAllDailyRoutine()
		notify("Daily Rewards", "Claiming all available daily & gifts...", 2.5)
		task.spawn(function()
			pcall(function() RewardsRemote:InvokeServer("claimDaily") end)
			pcall(function() RewardsRemote:InvokeServer("claimOffline") end)
			pcall(function()
				local st = RewardsRemote:InvokeServer("state")
				if st and type(st.gifts) == "table" then
					for idx, g in ipairs(st.gifts) do
						if g.ready and not g.claimed then
							RewardsRemote:InvokeServer("claimGift", idx)
							task.wait(0.2)
						end
					end
				end
			end)
			pcall(function()
				local st = RetentionRemote:InvokeServer("state")
				if st and st.spin and (st.spin.spins or 0) > 0 then
					RetentionRemote:InvokeServer("spin")
				end
			end)
			notify("Daily Rewards", "Daily claim sweep complete!", 2.5)
		end)
	end

	DailyCard:AddButton("Claim All Daily & Gifts Now", function()
		claimAllDailyRoutine()
	end)

	-- Card 2: Season Pass Automation
	local PassCard = createSectionCard(RtState.TabReward.Left, "Season Pass (Harvest Tide)", "ocean_chest")
	RtState.PassStatusTitleLbl, RtState.PassStatusBodyLbl = PassCard:AddInfoParagraph(
		"Season Pass: Loading...",
		"Tiers: Checking..."
	)

	PassCard:AddToggle("AutoClaimSeasonPass", "Auto Claim Pass Tiers", Cfg.AutoClaimSeasonPass ~= false, function(val)
		Cfg.AutoClaimSeasonPass = val
		if not val then
			if RtState.PassStatusTitleLbl then RtState.PassStatusTitleLbl.Text = "Season Pass: Idle (OFF)" end
		end
	end)

	PassCard:AddToggle("AutoPassAscension", "Auto Ascend Pass on Max Tier", Cfg.AutoPassAscension == true, function(val)
		Cfg.AutoPassAscension = val
	end)

	local function claimPassRoutine()
		notify("Season Pass", "Claiming unlocked pass tiers...", 2.5)
		task.spawn(function()
			local ok, res = pcall(function() return SeasonPassRemote:InvokeServer("claimAll") end)
			if ok and res and res.state then
				if Cfg.AutoPassAscension and res.state.canAsc then
					pcall(function() SeasonPassRemote:InvokeServer("ascend") end)
					notify("Season Pass", "Season Pass Ascended!", 3.0)
				else
					notify("Season Pass", "Claimed all unlocked tiers!", 2.5)
				end
			end
		end)
	end

	PassCard:AddButton("Claim All Pass Tiers Now", function()
		claimPassRoutine()
	end)

	-- ================================================================
	-- RIGHT COLUMN: Quests, Contracts, Challenges & Promo Codes
	-- ================================================================

	-- Card 3: Quests & Contracts Automation
	local QuestCard = createSectionCard(RtState.TabReward.Right, "Quests & Contracts", "quests")
	RtState.QuestStatusTitleLbl, RtState.QuestStatusBodyLbl = QuestCard:AddInfoParagraph(
		"Contracts: Loading...",
		"Challenges: Checking..."
	)

	QuestCard:AddToggle("AutoContractsMaster", "Auto Claim Contracts & Challenges", Cfg.AutoContractsMaster ~= false, function(val)
		Cfg.AutoContractsMaster = val
		if not val then
			if RtState.QuestStatusTitleLbl then RtState.QuestStatusTitleLbl.Text = "Contracts: Idle (OFF)" end
		end
	end)

	QuestCard:AddToggle("AutoClaimContracts", "Auto Claim Completed Contracts", Cfg.AutoClaimContracts ~= false, function(val)
		Cfg.AutoClaimContracts = val
	end)

	QuestCard:AddToggle("AutoClaimDailyChallenge", "Auto Claim Daily Challenge", Cfg.AutoClaimDailyChallenge ~= false, function(val)
		Cfg.AutoClaimDailyChallenge = val
	end)

	QuestCard:AddToggle("AutoRerollWait", "Auto Reroll Cooldown Contracts", Cfg.AutoRerollWait == true, function(val)
		Cfg.AutoRerollWait = val
	end)

	local function claimContractsRoutine()
		notify("Contracts", "Claiming completed contracts...", 2.5)
		task.spawn(function()
			pcall(function()
				local st = ContractsRemote:InvokeServer("state")
				if st and type(st.list) == "table" then
					for idx, c in ipairs(st.list) do
						if c.done then
							ContractsRemote:InvokeServer("claim", idx)
							task.wait(0.2)
						elseif Cfg.AutoRerollWait and c.k == "wait" and (c.rerollIn or 0) <= 0 then
							ContractsRemote:InvokeServer("reroll", idx)
							task.wait(0.2)
						end
					end
				end
			end)
			pcall(function()
				local st = ChallengeRemote:InvokeServer("state")
				if st and type(st.tiers) == "table" then
					for idx, t in ipairs(st.tiers) do
						if t.done and not t.claimed then
							ChallengeRemote:InvokeServer("claim", idx)
							task.wait(0.2)
						end
					end
				end
			end)
			notify("Contracts", "Contracts & Challenges sweep complete!", 2.5)
		end)
	end

	QuestCard:AddButton("Claim Completed Contracts Now", function()
		claimContractsRoutine()
	end)

	-- Card 4: Promo Codes (Redeem)
	local CodeCard = createSectionCard(RtState.TabReward.Right, "Redeem Promo Codes", "keybind")
	RtState.PromoCodeBoxAPI = CodeCard:AddTextBox("Promo Code", "Enter promo code here...", "")
	RtState.CodeStatusTitleLbl, RtState.CodeStatusBodyLbl = CodeCard:AddInfoParagraph(
		"Code Status: Ready",
		"Type code and click Redeem Code below."
	)

	CodeCard:AddButton("Redeem Code", function()
		local code = RtState.PromoCodeBoxAPI:GetText()
		if not code or #code == 0 then
			notify("Promo Code", "Please enter a code first.", 2.5)
			return
		end
		pcall(function()
			local ok, res = pcall(function() return RewardsRemote:InvokeServer("redeem", code) end)
			if ok and type(res) == "table" then
				local msg = res.msg or (res.ok and "Code redeemed successfully!" or "Code is invalid or expired.")
				if RtState.CodeStatusTitleLbl then
					RtState.CodeStatusTitleLbl.Text = res.ok and "Code: Success! 🎉" or "Code: Failed"
				end
				if RtState.CodeStatusBodyLbl then
					RtState.CodeStatusBodyLbl.Text = msg
				end
				notify("Promo Code", msg, 3.5)
				if res.ok then RtState.PromoCodeBoxAPI:SetText("") end
			else
				notify("Promo Code", "Server error while redeeming.", 3.0)
			end
		end)
	end)

	-- ================================================================
	-- BACKGROUND REWARD & QUEST AUTOMATION LOOP
	-- ================================================================
	task.spawn(function()
		while ScriptAlive do
			task.wait(6.0)

			-- 1. Daily & Playtime Rewards
			if Cfg.AutoClaimDailyMaster ~= false then
				pcall(function()
					local st = RewardsRemote:InvokeServer("state")
					if st then
						if Cfg.AutoClaimDailyLogin ~= false and st.daily and st.daily.claimable then
							RewardsRemote:InvokeServer("claimDaily")
						end

						local claimedCount = 0
						local readyCount = 0
						if type(st.gifts) == "table" then
							for idx, g in ipairs(st.gifts) do
								if g.claimed then claimedCount = claimedCount + 1 end
								if g.ready and not g.claimed then
									readyCount = readyCount + 1
									if Cfg.AutoClaimPlaytimeGifts ~= false then
										RewardsRemote:InvokeServer("claimGift", idx)
										task.wait(0.2)
									end
								end
							end
						end

						if Cfg.AutoClaimOffline ~= false then
							pcall(function() RewardsRemote:InvokeServer("claimOffline") end)
						end

						local spinReady = 0
						local retSt = RetentionRemote:InvokeServer("state")
						if retSt and retSt.spin then
							spinReady = retSt.spin.spins or 0
							if Cfg.AutoLuckySpin ~= false and spinReady > 0 then
								RetentionRemote:InvokeServer("spin")
								spinReady = 0
							end
						end

						if RtState.DailyStatusTitleLbl then
							local dayNum = st.daily and (st.daily.day or 1) or 1
							local streak = st.daily and (st.daily.streak or 1) or 1
							local status = (st.daily and st.daily.claimable) and "Ready to Claim!" or "Claimed"
							RtState.DailyStatusTitleLbl.Text = string.format("Daily: Day %d (Streak: %d) • %s", dayNum, streak, status)
						end
						if RtState.DailyStatusBodyLbl then
							RtState.DailyStatusBodyLbl.Text = string.format("Gifts: %d/7 Claimed | Spin Wheel: %d Ready", claimedCount, spinReady)
						end
					end
				end)
			end

			-- 2. Season Pass
			if Cfg.AutoClaimSeasonPass ~= false then
				pcall(function()
					local st = SeasonPassRemote:InvokeServer("state")
					if st then
						local curTier = st.tier or 0
						local curXp = st.xp or 0
						local canAsc = st.canAsc == true

						SeasonPassRemote:InvokeServer("claimAll")

						if Cfg.AutoPassAscension and canAsc then
							SeasonPassRemote:InvokeServer("ascend")
						end

						if RtState.PassStatusTitleLbl then
							RtState.PassStatusTitleLbl.Text = string.format("Pass: Tier %d / 50 • %s", curTier, st.name or "Harvest Tide")
						end
						if RtState.PassStatusBodyLbl then
							RtState.PassStatusBodyLbl.Text = string.format("XP: %s | Ascend: %s", tostring(curXp), canAsc and "READY!" or "Max Needed")
						end
					end
				end)
			end

			-- 3. Contracts & Challenges
			if Cfg.AutoContractsMaster ~= false then
				pcall(function()
					local cSt = ContractsRemote:InvokeServer("state")
					local readyContracts = 0
					local doneTotal = cSt and (cSt.done or 0) or 0
					local activeDesc = "None"

					if cSt and type(cSt.list) == "table" then
						for idx, c in ipairs(cSt.list) do
							if c.done then
								readyContracts = readyContracts + 1
								if Cfg.AutoClaimContracts ~= false then
									ContractsRemote:InvokeServer("claim", idx)
									task.wait(0.2)
								end
							else
								if c.text and #c.text > 0 and c.k ~= "wait" then
									activeDesc = c.text
								end
							end
							if Cfg.AutoRerollWait and c.k == "wait" and (c.rerollIn or 0) <= 0 then
								ContractsRemote:InvokeServer("reroll", idx)
								task.wait(0.2)
							end
						end
					end

					local chSt = ChallengeRemote:InvokeServer("state")
					local chTiersDone = 0
					if chSt and type(chSt.tiers) == "table" then
						for idx, t in ipairs(chSt.tiers) do
							if t.done then
								chTiersDone = chTiersDone + 1
								if not t.claimed and Cfg.AutoClaimDailyChallenge ~= false then
									ChallengeRemote:InvokeServer("claim", idx)
									task.wait(0.2)
								end
							end
						end
					end

					if RtState.QuestStatusTitleLbl then
						RtState.QuestStatusTitleLbl.Text = string.format("Contracts: %d Claimed (Done: %d)", readyContracts, doneTotal)
					end
					if RtState.QuestStatusBodyLbl then
						RtState.QuestStatusBodyLbl.Text = string.format("Challenge: %d/3 Tiers | %s", chTiersDone, activeDesc)
					end
				end)
			end
		end
	end)
end
--====================================================================--
-- [TAB 3: UPGRADE (AUTO REBIRTH, AUTO BUY NET & POTION AUTOMATION)]
--====================================================================--
do
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local FishingShared = require(ReplicatedStorage:WaitForChild("FishingShared"))
	local RebirthRequest = Remotes:WaitForChild("RebirthRequest")
	local BuyItem = Remotes:WaitForChild("BuyItem")
	local PotionsRemote = Remotes:WaitForChild("Potions")
	local GetData = Remotes:WaitForChild("GetData")

	-- Config Defaults for Upgrade Automation
	Cfg.AutoRebirth = (Cfg.AutoRebirth ~= false)
	if not Cfg.TargetRebirth or Cfg.TargetRebirth == 19 then
		Cfg.TargetRebirth = 60
	else
		Cfg.TargetRebirth = tonumber(Cfg.TargetRebirth) or 60
	end
	Cfg.AutoEquipBest = (Cfg.AutoEquipBest ~= false)
	Cfg.AutoBuyNet = (Cfg.AutoBuyNet ~= false)
	Cfg.AutoUseAllPotions = (Cfg.AutoUseAllPotions ~= false)
	Cfg.AutoBuyPotions = (Cfg.AutoBuyPotions ~= false)
	Cfg.ServerAutoPotion = (Cfg.ServerAutoPotion ~= false)
	Cfg.AutoBuyPerks = (Cfg.AutoBuyPerks == true)

	-- Format helper for compact cash display
	local function formatCash(val: number): string
		if not val or val == 0 then return "$0" end
		local sfx = {"", "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
		local idx = 1
		local n = val
		while n >= 1000 and idx < #sfx do
			n = n / 1000
			idx = idx + 1
		end
		if idx == 1 then
			return string.format("$%d", n)
		else
			return string.format("$%.2f%s", n, sfx[idx])
		end
	end

	local function formatTime(sec: number): string
		if not sec or sec <= 0 then return "0m" end
		local h = math.floor(sec / 3600)
		local m = math.floor((sec % 3600) / 60)
		if h > 0 then
			return string.format("%dh %02dm", h, m)
		else
			return string.format("%dm", m)
		end
	end

	-- ================================================================
	-- LEFT COLUMN: Rebirth Automation & Net Progression
	-- ================================================================

	-- Card 1: Rebirth Automation
	local RebirthCard = createSectionCard(RtState.TabUpgrade.Left, "Rebirth Automation", "reroll_bolt")
	RtState.RebirthStatusTitleLbl, RtState.RebirthStatusBodyLbl = RebirthCard:AddInfoParagraph(
		"Rebirth: Checking status...",
		"Requirements: Inspecting..."
	)

	RebirthCard:AddToggle("AutoRebirth", "Auto Rebirth When Ready", Cfg.AutoRebirth ~= false, function(val)
		Cfg.AutoRebirth = val
		if not val and RtState.RebirthStatusTitleLbl then
			RtState.RebirthStatusTitleLbl.Text = "Rebirth: Idle (OFF)"
		end
	end)

	RebirthCard:AddSlider("TargetRebirth", "Target Rebirth Limit", 1, 60, Cfg.TargetRebirth or 60, 1, "", function(val)
		Cfg.TargetRebirth = val
	end)

	RebirthCard:AddToggle("AutoEquipBest", "Auto Equip Best Showcase Fish", Cfg.AutoEquipBest ~= false, function(val)
		Cfg.AutoEquipBest = val
		if val then
			pcall(function() Remotes.BestSetup:FireServer() end)
		end
	end)

	RebirthCard:AddButton("Equip Best Showcase Now", function()
		pcall(function()
			Remotes.BestSetup:FireServer()
			notify("Showcase", "Equipped highest income fish!", 2.5)
		end)
	end)

	RebirthCard:AddButton("Rebirth Now (Manual Trigger)", function()
		task.spawn(function()
			local data = GetData:InvokeServer()
			local canRb, nextReq = FishingShared.CanRebirth(data)
			if canRb then
				notify("Rebirth", "Initiating Rebirth...", 3)
				RebirthRequest:FireServer()
				-- Immediately dismiss popup and equip best
				task.spawn(function()
					for _ = 1, 20 do
						task.wait(0.15)
						local pGui = LocalPlayer:WaitForChild("PlayerGui", 5)
						local unl = pGui and pGui:FindFirstChild("RebirthUnlocksUI")
						if unl then
							for _, b in ipairs(unl:GetDescendants()) do
								if b:IsA("GuiButton") or b.Name == "UnlocksOk" then
									pcall(function()
										for _, conn in ipairs(getconnections and getconnections(b.MouseButton1Click) or {}) do conn:Fire() end
										for _, conn in ipairs(getconnections and getconnections(b.Activated) or {}) do conn:Fire() end
									end)
								end
							end
							unl.Enabled = false
							pcall(function() unl:Destroy() end)
							break
						end
					end
					if Cfg.AutoEquipBest ~= false then
						pcall(function() Remotes.BestSetup:FireServer() end)
					end
				end)
			else
				local reqCash = nextReq and nextReq.Cash and formatCash(nextReq.Cash) or "?"
				notify("Rebirth", "Requirements not met! Needs " .. reqCash, 3.5)
			end
		end)
	end)

	-- Card 2: Net Upgrades
	local NetCard = createSectionCard(RtState.TabUpgrade.Left, "Net Progression", "fish")
	RtState.NetStatusTitleLbl, RtState.NetStatusBodyLbl = NetCard:AddInfoParagraph(
		"Net: Checking current tier...",
		"Next Tier: Inspecting shop..."
	)

	NetCard:AddToggle("AutoBuyNet", "Auto Buy Next Net Tier", Cfg.AutoBuyNet ~= false, function(val)
		Cfg.AutoBuyNet = val
		if not val and RtState.NetStatusTitleLbl then
			RtState.NetStatusTitleLbl.Text = "Net: Idle (OFF)"
		end
	end)

	NetCard:AddButton("Buy Next Net Now", function()
		task.spawn(function()
			local data = GetData:InvokeServer()
			local curTier = data.NetTier or 1
			local nextTier = curTier + 1
			if nextTier > #FishingShared.Nets then
				notify("Net Upgrade", "Max Net Tier already reached!", 3)
				return
			end
			local nextNet = FishingShared.Nets[nextTier]
			local ok, msg = FishingShared.NetRebirthOk(data, nextTier)
			if not ok then
				notify("Net Locked", "Rebirth requirement: " .. tostring(msg), 3.5)
				return
			end
			if (data.Cash or 0) < (nextNet.Cost or 0) then
				notify("Net Locked", "Need " .. formatCash(nextNet.Cost), 3.5)
				return
			end
			BuyItem:FireServer("Net", nextTier)
			notify("Net Upgrade", "Purchased " .. tostring(nextNet.Name) .. "!", 3)
		end)
	end)

	-- ================================================================
	-- RIGHT COLUMN: Potion Automation & Perks
	-- ================================================================

	-- Card 3: Potion Automation
	local PotionCard = createSectionCard(RtState.TabUpgrade.Right, "Potion Automation", "aura_sparkle")
	RtState.PotionStatusTitleLbl, RtState.PotionStatusBodyLbl = PotionCard:AddInfoParagraph(
		"Potions: Scanning active buffs...",
		"Stock: Checking refresh..."
	)

	PotionCard:AddToggle("AutoUseAllPotions", "Auto Use All Potions", Cfg.AutoUseAllPotions ~= false, function(val)
		Cfg.AutoUseAllPotions = val
		if val then
			task.spawn(function()
				local res = PotionsRemote:InvokeServer("useAll")
				local count = (res and res.drank) or 0
				notify("Potions", string.format("Auto Use All: drank %d potion(s)!", count), 2.5)
			end)
		end
	end)

	PotionCard:AddToggle("AutoBuyPotions", "Auto Buy Stock Potions (Shop)", Cfg.AutoBuyPotions ~= false, function(val)
		Cfg.AutoBuyPotions = val
	end)

	PotionCard:AddToggle("ServerAutoPotion", "Keep Server Auto-Potion Active", Cfg.ServerAutoPotion ~= false, function(val)
		Cfg.ServerAutoPotion = val
		if val then
			pcall(function() PotionsRemote:InvokeServer("auto", true) end)
		end
	end)

	PotionCard:AddButton("Use All Potions Now (Drink All)", function()
		task.spawn(function()
			local res = PotionsRemote:InvokeServer("useAll")
			local count = (res and res.drank) or 0
			notify("Potions", string.format("Drank %d potion(s) from cooler!", count), 3)
		end)
	end)

	PotionCard:AddButton("Buy All Stock Potions Now", function()
		task.spawn(function()
			local potState = PotionsRemote:InvokeServer("state")
			local data = GetData:InvokeServer()
			local boughtCount = 0
			if potState and potState.stock then
				for slotIdx, s in ipairs(potState.stock) do
					if not s.bought and (data.Cash or 0) >= (s.price or 0) then
						local ok = pcall(function() PotionsRemote:InvokeServer("buy", slotIdx) end)
						if ok then boughtCount = boughtCount + 1 end
						task.wait(0.2)
					end
				end
			end
			if Cfg.AutoUseAllPotions ~= false then
				pcall(function() PotionsRemote:InvokeServer("useAll") end)
			end
			notify("Potion Shop", string.format("Bought %d stock potion(s)!", boughtCount), 3)
		end)
	end)

	-- Card 4: Skill Perks
	local PerkCard = createSectionCard(RtState.TabUpgrade.Right, "Perk Upgrades (Skills)", "rod_skills")
	RtState.PerkStatusTitleLbl, RtState.PerkStatusBodyLbl = PerkCard:AddInfoParagraph(
		"Perks: Ready",
		"Upgrades: Fishing, Market, Showcase"
	)

	PerkCard:AddToggle("AutoBuyPerks", "Auto Buy Affordable Perks", Cfg.AutoBuyPerks == true, function(val)
		Cfg.AutoBuyPerks = val
	end)

	PerkCard:AddButton("Upgrade All Affordable Perks Now", function()
		task.spawn(function()
			local data = GetData:InvokeServer()
			local upgraded = 0
			if FishingShared.Upgrades then
				for _, u in ipairs(FishingShared.Upgrades) do
					local curLvl = data.Upgrades and data.Upgrades[u.Id] or 0
					if not u.MaxLevel or curLvl < u.MaxLevel then
						local ok = FishingShared.UpgradeLevelOk(data, u, curLvl + 1)
						local cost = FishingShared.UpgradeCost and FishingShared.UpgradeCost(u.Id, curLvl)
						if ok and cost and (data.Cash or 0) >= cost then
							BuyItem:FireServer("Upgrade", u.Id)
							upgraded = upgraded + 1
							task.wait(0.1)
						end
					end
				end
			end
			notify("Perks", string.format("Upgraded %d perk(s)!", upgraded), 3)
		end)
	end)

	-- ================================================================
	-- BACKGROUND WORKER: Upgrade, Net & Potion Loop (Every 3.5s)
	-- ================================================================
	task.spawn(function()
		task.wait(3.5)
		local lastPotionCheck = 0
		local lastPerkCheck = 0
		local lastBestSetup = 0

		while true do
			task.wait(3.5)

			local success, err = pcall(function()
				local data = GetData:InvokeServer()
				if not data then return end

				local curRb = data.Rebirths or 0
				local targetRb = tonumber(Cfg.TargetRebirth) or 60
				local curCash = data.Cash or 0

				-- 1. REBIRTH CHECK & STATUS
				local canRb, nextReq = FishingShared.CanRebirth(data)
				local rankName = FishingShared.Ranks and FishingShared.Ranks[curRb] and FishingShared.Ranks[curRb].Name or "Unknown"
				local nextRankName = nextReq and nextReq.Name or "Max"

				if RtState.RebirthStatusTitleLbl then
					RtState.RebirthStatusTitleLbl.Text = string.format("Rebirth: %d / %d • Rank: %s", curRb, targetRb, rankName)
				end

				if RtState.RebirthStatusBodyLbl then
					if curRb >= FishingShared.MaxRebirth then
						RtState.RebirthStatusBodyLbl.Text = "MAX REBIRTH REACHED (Rank: " .. rankName .. ")"
					elseif canRb then
						RtState.RebirthStatusBodyLbl.Text = string.format("Next: %s • STATUS: READY TO REBIRTH!", nextRankName)
					else
						local reqCash = nextReq and nextReq.Cash or 0
						local pct = reqCash > 0 and math.clamp((curCash / reqCash) * 100, 0, 100) or 100
						RtState.RebirthStatusBodyLbl.Text = string.format("Next: %s • Cash: %s / %s (%.1f%%)", nextRankName, formatCash(curCash), formatCash(reqCash), pct)
					end
				end

				if Cfg.AutoRebirth ~= false and curRb < targetRb and canRb then
					RebirthRequest:FireServer()
					notify("Auto Rebirth", string.format("Rebirthed to %d! Multipliers boosted.", curRb + 1), 3.5)

					-- Instantly dismiss the RebirthUnlocksUI popup and equip best showcase
					task.spawn(function()
						for _ = 1, 20 do
							task.wait(0.15)
							local pGui = LocalPlayer:WaitForChild("PlayerGui", 5)
							local unl = pGui and pGui:FindFirstChild("RebirthUnlocksUI")
							if unl then
								for _, b in ipairs(unl:GetDescendants()) do
									if b:IsA("GuiButton") or b.Name == "UnlocksOk" then
										pcall(function()
											for _, conn in ipairs(getconnections and getconnections(b.MouseButton1Click) or {}) do conn:Fire() end
											for _, conn in ipairs(getconnections and getconnections(b.Activated) or {}) do conn:Fire() end
										end)
									end
								end
								unl.Enabled = false
								pcall(function() unl:Destroy() end)
								break
							end
						end
						-- Auto Equip Best Showcase Fish after Rebirth
						if Cfg.AutoEquipBest ~= false then
							pcall(function() Remotes.BestSetup:FireServer() end)
						end
					end)

					task.wait(1.5)
					return
				end

				-- 2. NET CHECK & STATUS
				local curNetTier = data.NetTier or 1
				local nextNetTier = curNetTier + 1
				local curNet = FishingShared.Nets and FishingShared.Nets[curNetTier]
				local nextNet = FishingShared.Nets and FishingShared.Nets[nextNetTier]

				if RtState.NetStatusTitleLbl then
					RtState.NetStatusTitleLbl.Text = string.format("Current Net: #%d %s", curNetTier, curNet and curNet.Name or "Default")
				end

				if RtState.NetStatusBodyLbl then
					if not nextNet then
						RtState.NetStatusBodyLbl.Text = "MAX NET TIER REACHED • Top Net Equipped"
					else
						local ok, rbReq = FishingShared.NetRebirthOk(data, nextNetTier)
						if not ok then
							RtState.NetStatusBodyLbl.Text = string.format("Next: #%d %s (%s) • LOCKED (Req Rebirth %s)", nextNetTier, nextNet.Name, formatCash(nextNet.Cost), tostring(rbReq))
						elseif curCash < (nextNet.Cost or 0) then
							local pct = nextNet.Cost > 0 and math.clamp((curCash / nextNet.Cost) * 100, 0, 100) or 0
							RtState.NetStatusBodyLbl.Text = string.format("Next: #%d %s (%s) • Cash: %.1f%%", nextNetTier, nextNet.Name, formatCash(nextNet.Cost), pct)
						else
							RtState.NetStatusBodyLbl.Text = string.format("Next: #%d %s (%s) • READY TO BUY!", nextNetTier, nextNet.Name, formatCash(nextNet.Cost))
						end
					end
				end

				if Cfg.AutoBuyNet ~= false and nextNet then
					local ok = FishingShared.NetRebirthOk(data, nextNetTier)
					if ok and curCash >= (nextNet.Cost or 0) then
						BuyItem:FireServer("Net", nextNetTier)
						notify("Auto Buy Net", string.format("Upgraded to Net #%d %s!", nextNetTier, nextNet.Name), 3)
						task.wait(0.5)
					end
				end

				-- 3. POTION AUTOMATION CHECK (Every ~5s)
				if os.clock() - lastPotionCheck >= 5 then
					lastPotionCheck = os.clock()

					if Cfg.ServerAutoPotion ~= false then
						pcall(function() PotionsRemote:InvokeServer("auto", true) end)
					end

					local potState = PotionsRemote:InvokeServer("state")
					if potState then
						-- Auto Buy Shop Potions
						if Cfg.AutoBuyPotions ~= false and potState.stock then
							for slotIdx, s in ipairs(potState.stock) do
								if not s.bought and curCash >= (s.price or 0) then
									pcall(function() PotionsRemote:InvokeServer("buy", slotIdx) end)
									task.wait(0.2)
								end
							end
						end

						-- Auto Use All Potions (Cooler & Inventory)
						if Cfg.AutoUseAllPotions ~= false then
							pcall(function()
								PotionsRemote:InvokeServer("useAll")
							end)
						end

						-- Update Labels
						local activeList = {}
						local now = os.time()
						if potState.active then
							for kind, act in pairs(potState.active) do
								local exp = type(act) == "table" and (act.e or act.left or act.expires) or (type(act) == "number" and act or 0)
								local leftSec = (exp > now) and (exp - now) or (type(act) == "table" and act.left or 0)
								if leftSec > 0 then
									table.insert(activeList, string.format("%s: %s", tostring(kind), formatTime(leftSec)))
								end
							end
						end

						if RtState.PotionStatusTitleLbl then
							local autoStr = potState.auto and "ON" or "OFF"
							RtState.PotionStatusTitleLbl.Text = string.format("Active Potions: %d Active • Server Auto: %s", #activeList, autoStr)
						end

						if RtState.PotionStatusBodyLbl then
							if #activeList > 0 then
								RtState.PotionStatusBodyLbl.Text = table.concat(activeList, " | ")
							else
								local refIn = potState.refreshIn and formatTime(potState.refreshIn) or "..."
								RtState.PotionStatusBodyLbl.Text = string.format("No active buffs • Next stock refresh in: %s", refIn)
							end
						end
					end
				end

				-- 4. PERK UPGRADES CHECK (Every ~10s if enabled)
				if Cfg.AutoBuyPerks == true and FishingShared.Upgrades and (os.clock() - lastPerkCheck >= 10) then
					lastPerkCheck = os.clock()
					for _, u in ipairs(FishingShared.Upgrades) do
						local curLvl = data.Upgrades and data.Upgrades[u.Id] or 0
						if not u.MaxLevel or curLvl < u.MaxLevel then
							local ok = FishingShared.UpgradeLevelOk(data, u, curLvl + 1)
							local cost = FishingShared.UpgradeCost and FishingShared.UpgradeCost(u.Id, curLvl)
							if ok and cost and curCash >= cost then
								BuyItem:FireServer("Upgrade", u.Id)
								task.wait(0.1)
							end
						end
					end
				end

				-- 5. AUTO EQUIP BEST SHOWCASE FISH (Every ~10s if enabled)
				if Cfg.AutoEquipBest ~= false and (os.clock() - lastBestSetup >= 10) then
					lastBestSetup = os.clock()
					pcall(function() Remotes.BestSetup:FireServer() end)
				end
			end)

			if not success and err then
				-- Silently caught to maintain 100% stability
			end
		end
	end)
end
-- [TAB 8: SETTINGS — CONFIG MANAGER, AUTO LOAD, AUTO EXECUTE & KEYBIND]
--====================================================================--
RtState.ConfigRootFolder = "SerennityHub"
RtState.ConfigSubFolder = "SerennityHub/Configs_" .. tostring(game.PlaceId or "Template")
RtState.SystemSettingsPath = "SerennityHub/settings_" .. tostring(game.PlaceId or "Template") .. ".json"

RtState.SystemSettings = {
	AutoLoadConfig = false,
	SelectedConfig = "default",
	AutoExecute = false,
	Rejoin = false,
	MenuKeybind = "RightControl",
}

RtState.MenuKeybindPickerAPI = nil
RtState.ConfigDropdownAPI = nil
RtState.SettingsHeaderLbl = nil
RtState.SettingsBodyLbl = nil
RtState.HasQueuedTeleportPayload = false
RtState.LastVirtualUserPulseClock = 0
RtState.LastAutoReconnectAttemptClock = 0

do
	RtState.EnsureConfigFolders = function()
		pcall(function()
			if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
				if not isfolder(RtState.ConfigRootFolder) then
					makefolder(RtState.ConfigRootFolder)
				end
				if not isfolder(RtState.ConfigSubFolder) then
					makefolder(RtState.ConfigSubFolder)
				end
			end
		end)
	end

	RtState.SaveSystemSettings = function()
		RtState.EnsureConfigFolders()
		pcall(function()
			if typeof(writefile) == "function" then
				writefile(RtState.SystemSettingsPath, HttpService:JSONEncode(RtState.SystemSettings))
			end
		end)
	end

	RtState.LoadSystemSettings = function()
		RtState.EnsureConfigFolders()
		pcall(function()
			if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(RtState.SystemSettingsPath) then
				local decoded = HttpService:JSONDecode(readfile(RtState.SystemSettingsPath))
				if type(decoded) == "table" then
					if type(decoded.AutoLoadConfig) == "boolean" then
						RtState.SystemSettings.AutoLoadConfig = decoded.AutoLoadConfig
					end
					if type(decoded.SelectedConfig) == "string" and #decoded.SelectedConfig > 0 then
						RtState.SystemSettings.SelectedConfig = decoded.SelectedConfig
					end
					if type(decoded.AutoExecute) == "boolean" then
						RtState.SystemSettings.AutoExecute = decoded.AutoExecute
					end
					if type(decoded.Rejoin) == "boolean" then
						RtState.SystemSettings.Rejoin = decoded.Rejoin
						Cfg.Rejoin = decoded.Rejoin
					end
					if type(decoded.MenuKeybind) == "string" and #decoded.MenuKeybind > 0 then
						RtState.SystemSettings.MenuKeybind = decoded.MenuKeybind
						Cfg.MenuKeybind = decoded.MenuKeybind
					end
				end
			end
		end)
	end

	RtState.SanitizeConfigName = function(raw: string): string
		local clean = string.gsub(raw or "", '[<>:"/\\|%?%*%c]', "")
		clean = string.gsub(clean, "^%s*(.-)%s*$", "%1")
		return clean
	end

	RtState.GetSavedConfigNames = function(): { string }
		RtState.EnsureConfigFolders()
		local names = {}
		pcall(function()
			if typeof(listfiles) == "function" then
				for _, fpath in ipairs(listfiles(RtState.ConfigSubFolder)) do
					local fname = string.match(fpath, "([^/\\]+)%.json$")
					if fname and #fname > 0 then
						table.insert(names, fname)
					end
				end
			end
		end)
		table.sort(names)
		if #names == 0 then
			table.insert(names, "default")
		end
		return names
	end

	RtState.ApplyBoostFPS = function(enabled: boolean, showToast: boolean?)
		pcall(function()
			local Lighting = game:GetService("Lighting")
			Lighting.GlobalShadows = not enabled
			if enabled then
				Lighting.FogEnd = 9e9
			end
			for _, eff in ipairs(Lighting:GetChildren()) do
				if eff:IsA("PostEffect") then
					eff.Enabled = not enabled
				end
			end
			if enabled and not RtState.IsRunningBoostFpsScan then
				RtState.IsRunningBoostFpsScan = true
				task.spawn(function()
					pcall(function()
						for i, inst in ipairs(workspace:GetDescendants()) do
							if not ScriptAlive or not Cfg.BoostFPS then break end
							if inst:IsA("BasePart") then
								inst.CastShadow = false
							elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
								inst.Enabled = false
							end
							if i % 1500 == 0 then
								task.wait()
							end
						end
					end)
					RtState.IsRunningBoostFpsScan = false
				end)
			end
		end)
		if showToast then
			notify("Boost FPS", enabled and "Boost FPS enabled." or "Boost FPS disabled.", 2.5)
		end
	end

	RtState.RefreshSettingsStatusBox = function()
		local isPrem = RtState.IsAccountPremium()
		local premBadge = isPrem and "Map Premium" or "Standard"
		if RtState.HubSubLabelRef then
			RtState.HubSubLabelRef.Text = "Serennity Hub * v1.0 [ Private ]"
		end
		if RtState.UcSubLabelRef then
			RtState.UcSubLabelRef.Text = premBadge .. " • " .. tostring(ClientDeviceType)
		end
		if RtState.SettingsHeaderLbl and RtState.SettingsBodyLbl then
			RtState.SettingsHeaderLbl.Text = "Config: " .. tostring(RtState.SystemSettings.SelectedConfig) .. " • " .. premBadge
			local rejoinStatus = (Cfg.Rejoin == true or RtState.SystemSettings.Rejoin == true) and "ON" or "OFF"
			if not IsMobileDevice then
				RtState.SettingsBodyLbl.Text = string.format(
					"Auto Load: %s • Auto Execute: %s • Rejoin: %s\nAnti AFK: %s • Boost FPS: %s • Key: [%s]",
					RtState.SystemSettings.AutoLoadConfig and "ON" or "OFF",
					RtState.SystemSettings.AutoExecute and "ON" or "OFF",
					rejoinStatus,
					(Cfg.AntiAFK == true) and "ON" or "OFF",
					(Cfg.BoostFPS == true) and "ON" or "OFF",
					tostring(Cfg.MenuKeybind or "RightControl")
				)
			else
				RtState.SettingsBodyLbl.Text = string.format(
					"Auto Load: %s • Auto Execute: %s • Rejoin: %s\nAnti AFK: %s • Boost FPS: %s • Mode: Touch UI",
					RtState.SystemSettings.AutoLoadConfig and "ON" or "OFF",
					RtState.SystemSettings.AutoExecute and "ON" or "OFF",
					rejoinStatus,
					(Cfg.AntiAFK == true) and "ON" or "OFF",
					(Cfg.BoostFPS == true) and "ON" or "OFF"
				)
			end
		end
	end

	RtState.WriteConfigToFile = function(cfgName: string): boolean
		local clean = RtState.SanitizeConfigName(cfgName)
		if #clean == 0 then return false end
		RtState.EnsureConfigFolders()
		local payload = {}
		for k, defaultVal in pairs(DefaultConfig) do
			local curVal = Cfg[k]
			if type(defaultVal) == "boolean" then
				payload[k] = (curVal == true)
			elseif type(defaultVal) == "number" then
				payload[k] = tonumber(curVal) or defaultVal
			elseif type(defaultVal) == "string" then
				payload[k] = type(curVal) == "string" and curVal or defaultVal
			elseif type(defaultVal) == "table" then
				payload[k] = type(curVal) == "table" and table.clone(curVal) or table.clone(defaultVal)
			end
		end
		if typeof(writefile) ~= "function" then return false end
		local ok = pcall(function()
			writefile(RtState.ConfigSubFolder .. "/" .. clean .. ".json", HttpService:JSONEncode(payload))
		end)
		return ok
	end

	RtState.SyncAllUIFromConfig = function()
		for k, tObj in pairs(AllTogglesRegistry) do
			if k == "AutoLoadConfig" then
				tObj:UpdateState(RtState.SystemSettings.AutoLoadConfig == true, false)
			elseif k == "AutoExecute" then
				tObj:UpdateState(RtState.SystemSettings.AutoExecute == true, false)
			elseif k == "Rejoin" then
				local rVal = (Cfg.Rejoin == true) or (RtState.SystemSettings.Rejoin == true)
				Cfg.Rejoin = rVal
				RtState.SystemSettings.Rejoin = rVal
				tObj:UpdateState(rVal, false)
			elseif DefaultConfig[k] ~= nil then
				tObj:UpdateState(Cfg[k] == true, false)
			end
		end
		for k, sObj in pairs(AllSlidersRegistry) do
			if type(Cfg[k]) == "number" then
				sObj:SetValue(Cfg[k], false)
			end
		end
		for k, dObj in pairs(AllDropdownsRegistry) do
			if type(Cfg[k]) == "string" and dObj.SetSelected then
				dObj:SetSelected(Cfg[k])
			elseif type(Cfg[k]) == "table" and dObj.UpdateSelection then
				dObj:UpdateSelection(Cfg[k])
			end
		end
		if RtState.MenuKeybindPickerAPI and type(Cfg.MenuKeybind) == "string" then
			RtState.MenuKeybindPickerAPI:SetKey(Cfg.MenuKeybind)
		end
		if Cfg.BoostFPS == true then
			RtState.ApplyBoostFPS(true, false)
		end
		RtState.RefreshSettingsStatusBox()
	end

	RtState.LoadConfigFromFile = function(cfgName: string, silent: boolean?): boolean
		local clean = RtState.SanitizeConfigName(cfgName)
		if #clean == 0 then return false end
		RtState.EnsureConfigFolders()
		local path = RtState.ConfigSubFolder .. "/" .. clean .. ".json"
		if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return false end
		local okExists, exists = pcall(isfile, path)
		if not okExists or not exists then return false end
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)
		if not ok or type(decoded) ~= "table" then return false end

		for k, defaultVal in pairs(DefaultConfig) do
			local loadedVal = decoded[k]
			if type(defaultVal) == "boolean" and type(loadedVal) == "boolean" then
				Cfg[k] = loadedVal
			elseif type(defaultVal) == "number" and type(loadedVal) == "number" then
				Cfg[k] = loadedVal
			elseif type(defaultVal) == "string" and type(loadedVal) == "string" and #loadedVal > 0 then
				Cfg[k] = loadedVal
			elseif type(defaultVal) == "table" and type(loadedVal) == "table" then
				Cfg[k] = table.clone(loadedVal)
			end
		end
		RtState.SyncAllUIFromConfig()
		if not silent then
			notify("Config Loaded", "Loaded config '" .. clean .. "'.", 2.5)
		end
		return true
	end

	RtState.DeleteConfigFile = function(cfgName: string, silent: boolean?): boolean
		local clean = RtState.SanitizeConfigName(cfgName)
		if #clean == 0 then return false end
		local path = RtState.ConfigSubFolder .. "/" .. clean .. ".json"
		local deleted = false
		pcall(function()
			if typeof(isfile) == "function" and typeof(delfile) == "function" and isfile(path) then
				delfile(path)
				deleted = true
			end
		end)
		if deleted then
			local list = RtState.GetSavedConfigNames()
			RtState.SystemSettings.SelectedConfig = list[1] or "default"
			RtState.SaveSystemSettings()
			if RtState.ConfigDropdownAPI then
				RtState.ConfigDropdownAPI:SetOptions(list, RtState.SystemSettings.SelectedConfig)
			end
			RtState.RefreshSettingsStatusBox()
			if not silent then
				notify("Config Deleted", "Deleted config '" .. clean .. "'.", 2.5)
			end
		end
		return deleted
	end

	RtState.LoadSystemSettings()
	RtState.ExistingConfigList = RtState.GetSavedConfigNames()
	pcall(function()
		if typeof(isfile) == "function" and not isfile(RtState.ConfigSubFolder .. "/default.json") then
			RtState.WriteConfigToFile("default")
			RtState.ExistingConfigList = RtState.GetSavedConfigNames()
		end
	end)

	-- [SETTINGS LEFT COLUMN: Configuration Manager]
	RtState.ConfigCard = createSectionCard(RtState.TabSettings.Left, "Configuration", "settings", true)
	RtState.ConfigNameBoxAPI = RtState.ConfigCard:AddTextBox("Config Name", "Enter config name...", "")
	RtState.ConfigDropdownAPI = RtState.ConfigCard:AddSingleDropdown("", "Config List", RtState.ExistingConfigList, RtState.SystemSettings.SelectedConfig, function(sel)
		RtState.SystemSettings.SelectedConfig = sel
		RtState.SaveSystemSettings()
		RtState.RefreshSettingsStatusBox()
	end)

	RtState.ConfigCard:AddButton("Create Config", function()
		local rawName = RtState.ConfigNameBoxAPI:GetText()
		local clean = RtState.SanitizeConfigName(rawName)
		if #clean == 0 then
			notify("Create Config", "Please enter a config name first.", 2.5)
			return
		end
		if RtState.WriteConfigToFile(clean) then
			RtState.SystemSettings.SelectedConfig = clean
			RtState.SaveSystemSettings()
			RtState.ConfigDropdownAPI:SetOptions(RtState.GetSavedConfigNames(), clean)
			RtState.ConfigNameBoxAPI:SetText("")
			RtState.RefreshSettingsStatusBox()
			notify("Config Created", "Created and saved config '" .. clean .. "'.", 2.5)
		end
	end)

	RtState.ConfigCard:AddButton("Load Config", function()
		local target = RtState.ConfigDropdownAPI:GetSelected()
		if RtState.LoadConfigFromFile(target, false) then
			RtState.SystemSettings.SelectedConfig = target
			RtState.SaveSystemSettings()
			RtState.RefreshSettingsStatusBox()
		else
			notify("Load Failed", "Config file '" .. tostring(target) .. "' not found.", 2.5)
		end
	end)

	RtState.ConfigCard:AddButton("Overwrite Config", function()
		local target = RtState.ConfigDropdownAPI:GetSelected()
		if RtState.WriteConfigToFile(target) then
			RtState.RefreshSettingsStatusBox()
			notify("Config Overwritten", "Overwrote config '" .. tostring(target) .. "'.", 2.5)
		end
	end)

	RtState.ConfigCard:AddButton("Delete Config", function()
		local target = RtState.ConfigDropdownAPI:GetSelected()
		RtState.DeleteConfigFile(target, false)
	end)

	RtState.ConfigCard:AddButton("Refresh Configs", function()
		local list = RtState.GetSavedConfigNames()
		RtState.ConfigDropdownAPI:SetOptions(list, RtState.SystemSettings.SelectedConfig)
		RtState.RefreshSettingsStatusBox()
		notify("Configs Refreshed", "Refreshed config list (" .. tostring(#list) .. " files).", 2.5)
	end)

	RtState.ConfigCard:AddToggle("AutoLoadConfig", "Auto Load Config", RtState.SystemSettings.AutoLoadConfig, function(val)
		RtState.SystemSettings.AutoLoadConfig = val
		RtState.SaveSystemSettings()
		RtState.RefreshSettingsStatusBox()
		notify("Auto Load Config", val and ("Auto Load enabled: '" .. tostring(RtState.SystemSettings.SelectedConfig) .. "'") or "Auto Load Config disabled.", 2.5)
	end)

	-- ====================================================================
	-- [SETTINGS LEFT COLUMN CARD 2: DISCORD WEBHOOK]
	-- ====================================================================
	local WebhookCard = createSectionCard(RtState.TabSettings.Left, "Discord Webhook", "settings")

	WebhookCard:AddTextBox("WebhookUrl", "Enter Webhook URL...", Cfg.WebhookUrl or "")

	WebhookCard:AddToggle("WebhookNotifyRarity", "Notify High Rarities (Divine+)", Cfg.WebhookNotifyRarity, function(val)
		Cfg.WebhookNotifyRarity = val
		notify("Discord Webhook", val and "Rarity notifications enabled." or "Rarity notifications disabled.", 2.0)
	end)

	WebhookCard:AddToggle("WebhookNotifyGodTraits", "Notify God Traits & Secret Quirks", Cfg.WebhookNotifyGodTraits, function(val)
		Cfg.WebhookNotifyGodTraits = val
		notify("Discord Webhook", val and "Trait/Quirk notifications enabled." or "Trait/Quirk notifications disabled.", 2.0)
	end)

	WebhookCard:AddToggle("WebhookNotifyRebirth", "Notify Rebirth Level Ups", Cfg.WebhookNotifyRebirth, function(val)
		Cfg.WebhookNotifyRebirth = val
		notify("Discord Webhook", val and "Rebirth notifications enabled." or "Rebirth notifications disabled.", 2.0)
	end)

	WebhookCard:AddToggle("WebhookNotifyTowerFloor", "Notify Tower Floor Clears", Cfg.WebhookNotifyTowerFloor, function(val)
		Cfg.WebhookNotifyTowerFloor = val
		notify("Discord Webhook", val and "Tower notifications enabled." or "Tower notifications disabled.", 2.0)
	end)

	WebhookCard:AddButton("Send Test Webhook Now", function()
		if not Cfg.WebhookUrl or Cfg.WebhookUrl == "" or not string.find(Cfg.WebhookUrl, "https://") then
			notify("Discord Webhook", "Please enter a valid Discord Webhook URL first!", 3.0)
			return
		end
		local sent = sendDiscordWebhookEmbed(
			"🔔 Serennity Hub • Test Notification",
			"Discord Webhook connection verified successfully for **Anime Dice**!",
			65280,
			{
				{ name = "Player", value = tostring(LocalPlayer.DisplayName) .. " (@" .. tostring(LocalPlayer.Name) .. ")", inline = true },
				{ name = "Game Place ID", value = tostring(game.PlaceId), inline = true },
				{ name = "Job ID", value = tostring(game.JobId), inline = false },
			}
		)
		notify("Discord Webhook", sent and "Test webhook dispatched!" or "Failed to send (check executor HTTP support).", 3.0)
	end)

	-- [SETTINGS RIGHT COLUMN: System & Keybind]
	RtState.SystemCard = createSectionCard(RtState.TabSettings.Right, "System & Keybind", "keybind", true)

	if not IsMobileDevice then
		RtState.MenuKeybindPickerAPI = RtState.SystemCard:AddKeybind("UI Toggle Keybind", Cfg.MenuKeybind or "RightControl", function(newKey)
			Cfg.MenuKeybind = newKey
			RtState.SystemSettings.MenuKeybind = newKey
			RtState.SaveSystemSettings()
			RtState.RefreshSettingsStatusBox()
			notify("Keybind Updated", "UI toggle key set to [" .. tostring(newKey) .. "].", 2.5)
		end)
	end

	RtState.SystemCard:AddToggle("AntiAFK", "Anti AFK", Cfg.AntiAFK ~= false, function(val)
		Cfg.AntiAFK = val
		RtState.RefreshSettingsStatusBox()
		notify("Anti AFK", val and "Anti AFK enabled." or "Anti AFK disabled.", 2.0)
	end)

	RtState.SystemCard:AddToggle("AutoExecute", "Auto Execute", RtState.SystemSettings.AutoExecute, function(val)
		RtState.SystemSettings.AutoExecute = val
		RtState.SaveSystemSettings()
		RtState.RefreshSettingsStatusBox()
		notify("Auto Execute", val and "Auto Execute enabled." or "Auto Execute disabled.", 2.5)
	end)

	RtState.SystemCard:AddToggle("Rejoin", "Rejoin", RtState.SystemSettings.Rejoin == true, function(val)
		Cfg.Rejoin = val
		RtState.SystemSettings.Rejoin = val
		RtState.SaveSystemSettings()
		RtState.RefreshSettingsStatusBox()
		notify("Rejoin", val and "Auto Rejoin enabled." or "Auto Rejoin disabled.", 2.5)
	end)

	RtState.SystemCard:AddToggle("Disable3DRendering", "GPU Saver (Disable 3D View)", Cfg.Disable3DRendering, function(val)
		Cfg.Disable3DRendering = val
		pcall(function()
			local RunService = game:GetService("RunService")
			RunService:Set3dRenderingEnabled(not val)
		end)
		notify("GPU Saver", val and "3D Rendering disabled (GPU usage ~0%)." or "3D Rendering restored.", 2.5)
	end)

	local _hiddenGameUIsMap = {}
	local function toggleHideGameUI(enable: boolean)
		Cfg.HideGameUI = enable
		pcall(function()
			if not PlayerGui then return end
			if enable then
				_hiddenGameUIsMap = {}
				for _, g in ipairs(PlayerGui:GetChildren()) do
					if g:IsA("ScreenGui") and g ~= ScreenGui and g.Enabled == true then
						_hiddenGameUIsMap[g] = true
						g.Enabled = false
					end
				end
			else
				for g, _ in pairs(_hiddenGameUIsMap) do
					if g and g.Parent then
						pcall(function() g.Enabled = true end)
					end
				end
				_hiddenGameUIsMap = {}
			end
		end)
		notify("Game UI", enable and "All in-game GUIs hidden." or "All in-game GUIs restored.", 2.0)
	end

	RtState.SystemCard:AddToggle("HideGameUI", "Hide In-Game UI (Clean Screen)", Cfg.HideGameUI, function(val)
		toggleHideGameUI(val)
	end)

	RtState.SystemCard:AddToggle("EnableAfkDashboard", "AFK Black Screen & Live HUD", Cfg.EnableAfkDashboard, function(val)
		if RtState.SetAfkDashboard then
			RtState.SetAfkDashboard(val)
		end
	end)

	RtState.SystemCard:AddToggle("AutoReconnectOnKick", "Auto Reconnect On Disconnect", Cfg.AutoReconnectOnKick, function(val)
		Cfg.AutoReconnectOnKick = val
		notify("Auto Reconnect", val and "Auto reconnect on error enabled." or "Auto reconnect on error disabled.", 2.0)
	end)

	local function performServerHop()
		pcall(function()
			local HttpService = game:GetService("HttpService")
			local placeId = game.PlaceId
			local curJob = game.JobId
			local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
			if req then
				local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(placeId))
				local res = req({ Url = url, Method = "GET" })
				if res and res.Body then
					local data = HttpService:JSONDecode(res.Body)
					if data and data.data then
						for _, srv in ipairs(data.data) do
							if srv.id ~= curJob and srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers and srv.playing > 1 then
								TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
								return
							end
						end
					end
				end
			end
			TeleportService:Teleport(placeId, LocalPlayer)
		end)
	end

	RtState.SystemCard:AddButton("Rejoin Current Server Now", function()
		pcall(function()
			notify("Rejoin", "Reconnecting to current server...", 2.0)
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
	end)

	RtState.SystemCard:AddButton("Server Hop (New Server) Now", function()
		task.spawn(function()
			notify("Server Hop", "Searching for optimal public server...", 2.5)
			performServerHop()
		end)
	end)

	RtState.SystemCard:AddToggle("BoostFPS", "Boost FPS", false, function(val)
		Cfg.BoostFPS = val
		RtState.RefreshSettingsStatusBox()
		RtState.ApplyBoostFPS(val, true)
	end)

	RtState.SystemCard:AddButton("Clean Map VFX & Lag Now", function()
		RtState.ApplyBoostFPS(true, true)
	end)

	RtState.SystemCard:AddButton("Copy Serennity Hub Discord Link", function()
		if typeof(setclipboard) == "function" then
			pcall(setclipboard, DISCORD_INVITE)
		end
		notify("Discord Link Copied", "Copied " .. DISCORD_INVITE .. " to clipboard.", 2.5)
	end)

	RtState.SettingsHeaderLbl, RtState.SettingsBodyLbl = RtState.SystemCard:AddInfoParagraph(
		"Config: " .. tostring(RtState.SystemSettings.SelectedConfig),
		"Loading settings..."
	)


	RtState.RefreshSettingsStatusBox()

	if RtState.SystemSettings.AutoLoadConfig and RtState.SystemSettings.SelectedConfig then
		local okLoad, didLoad = pcall(RtState.LoadConfigFromFile, RtState.SystemSettings.SelectedConfig, true)
		if okLoad and didLoad then
			notify("Auto Load Config", "Auto-loaded config '" .. tostring(RtState.SystemSettings.SelectedConfig) .. "'.", 2.5)
		end
	end
end

if RtState.TabsRegistry[1] then
	RtState.TabsRegistry[1]:Select()
end

task.defer(function()
	task.wait(0.2)
	for _, tabEntry in ipairs(RtState.TabsRegistry) do
		if tabEntry.Page then
			local sc = tabEntry.Page:FindFirstChild("ColumnsScroll")
			if sc and sc:IsA("ScrollingFrame") then
				local lc = sc:FindFirstChild("LeftColumn")
				local rc = sc:FindFirstChild("RightColumn")
				local ll = lc and lc:FindFirstChildOfClass("UIListLayout")
				local rl = rc and rc:FindFirstChildOfClass("UIListLayout")
				local maxH = math.max(ll and ll.AbsoluteContentSize.Y or 0, rl and rl.AbsoluteContentSize.Y or 0)
				if maxH > 0 then
					sc.CanvasSize = UDim2.new(0, 0, 0, maxH + 40)
				end
			end
		end
	end
end)

--====================================================================--
-- ANTI-AFK & AUTO-RECONNECT SYSTEM (Multi-layered: getconnections + Reactive Idled + Game Input/Move Pulse + Map AFK Dismiss + Periodic Heartbeat)
--====================================================================--
local vim = game:GetService("VirtualInputManager")

local function dismissMapAFK()
	local afkScreen = PlayerGui:FindFirstChild("AFKModeScreen")
	if (afkScreen and afkScreen.Enabled == true) or LocalPlayer:GetAttribute("AFKScreen") == true then
		pcall(function()
			RunService:Set3dRenderingEnabled(true)
		end)
		pcall(function()
			LocalPlayer:SetAttribute("AFKScreen", nil)
		end)
		pcall(function()
			local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local AFKState = Remotes and Remotes:FindFirstChild("AFKState")
			if AFKState then
				AFKState:FireServer(false)
			end
		end)
		if afkScreen then
			afkScreen.Enabled = false
			local backBtn = afkScreen:FindFirstChild("AFKBack", true) or afkScreen:FindFirstChild("BACK TO GAME", true)
			if backBtn and backBtn:IsA("GuiButton") then
				pcall(function()
					for _, c in ipairs(getconnections(backBtn.MouseButton1Click)) do c:Fire() end
					for _, c in ipairs(getconnections(backBtn.Activated)) do c:Fire() end
				end)
			end
		end
		pcall(function()
			vim:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
			task.wait(0.02)
			vim:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
		end)
	end
end

local function sendAntiAFKPulse()
	-- 1. Roblox Engine Idled bypass
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:Button2Down(Vector2.zero)
		task.wait(0.05)
		VirtualUser:Button2Up(Vector2.zero)
	end)

	-- 2. Game-level UserInputService InputBegan pulse (resets map's 5-minute AFK timer)
	pcall(function()
		vim:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
		task.wait(0.02)
		vim:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
	end)

	-- 3. Game-level Humanoid micro-move pulse (resets MoveDirection check in AFKModeClient)
	pcall(function()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum:Move(Vector3.new(0.001, 0, 0), false)
			task.wait(0.02)
			hum:Move(Vector3.zero, false)
		end
	end)

	-- 4. Active dismissal check in case AFK screen ever opened
	dismissMapAFK()
end

-- Layer 1: Bypass Roblox engine's default Idled connections if exploit supports it
pcall(function()
	if typeof(getconnections) == "function" then
		for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
			if typeof(conn.Disable) == "function" then
				conn:Disable()
			elseif typeof(conn.Disconnect) == "function" then
				conn:Disconnect()
			end
		end
	end
end)

-- Neutralize game's built-in 16-minute auto-reconnect (which forces a server reload and unloads injected scripts)
pcall(function()
	LocalPlayer:SetAttribute("Set_StayAFK", false)
	local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local keepScript = pScripts and pScripts:FindFirstChild("AFKKeepClient")
	if keepScript then
		keepScript.Disabled = true
	end
end)

-- Layer 2: Reactive handler if Idled signal fires
table.insert(Connections, LocalPlayer.Idled:Connect(function()
	if Cfg.AntiAFK ~= false or Cfg.Rejoin == true or (RtState.SystemSettings and RtState.SystemSettings.Rejoin == true) then
		sendAntiAFKPulse()
	end
end))

-- Layer 2.1: Reactive dismissal if map sets AFKScreen attribute or enables AFKModeScreen
table.insert(Connections, LocalPlayer:GetAttributeChangedSignal("AFKScreen"):Connect(function()
	if Cfg.AntiAFK ~= false and LocalPlayer:GetAttribute("AFKScreen") == true then
		dismissMapAFK()
	end
end))

pcall(function()
	local afkScreen = PlayerGui:FindFirstChild("AFKModeScreen")
	if afkScreen then
		table.insert(Connections, afkScreen:GetPropertyChangedSignal("Enabled"):Connect(function()
			if Cfg.AntiAFK ~= false and afkScreen.Enabled == true then
				dismissMapAFK()
			end
		end))
	end
end)

-- Layer 3: Active Periodic Heartbeat Loop (every 30s) keeping both Roblox and Map timers at 0
task.spawn(function()
	while ScriptAlive do
		if Cfg.AntiAFK ~= false then
			sendAntiAFKPulse()
		end
		task.wait(30)
	end
end)

-- Layer 4: Auto-reconnect / Auto-rejoin on disconnect screen
local function handleDisconnectReconnect()
	if Cfg.AutoReconnectOnKick == true or Cfg.Rejoin == true or (RtState.SystemSettings and RtState.SystemSettings.Rejoin == true) then
		task.wait(1.5)
		pcall(function()
			if #Players:GetPlayers() <= 1 then
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end)
	end
end

table.insert(Connections, GuiService.ErrorMessageChanged:Connect(function()
	handleDisconnectReconnect()
end))

pcall(function()
	local CoreGui = game:GetService("CoreGui")
	local promptOverlay = CoreGui:FindFirstChild("RobloxPromptGui") and CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
	if promptOverlay then
		table.insert(Connections, promptOverlay.ChildAdded:Connect(function(child)
			if child.Name == "ErrorPrompt" then
				handleDisconnectReconnect()
			end
		end))
	end
end)

--====================================================================--
-- PRIVATE OWNER DASHBOARD TELEMETRY (ห้ามลบเด็ดขาด • สำหรับส่งสถานะเข้า Dashboard เจ้าของ)
--====================================================================--
;(function()
	local httpRequestFn = (typeof(request) == "function" and request)
		or (typeof(http_request) == "function" and http_request)
		or (type(syn) == "table" and typeof(syn.request) == "function" and syn.request)
		or (type(fluxus) == "table" and typeof(fluxus.request) == "function" and fluxus.request)
		or (type(http) == "table" and typeof(http.request) == "function" and http.request)
		or nil

	local _ep = string.char(104,116,116,112,115,58,47,47,115,101,114,101,110,110,105,116,121,45,104,117,98,46,115,105,114,97,110,121,97,45,55,55,52,52,46,119,111,114,107,101,114,115,46,100,101,118)
	local rawUid = tonumber(LocalPlayer and LocalPlayer.UserId) or 0
	local hashedNum = bit32.bxor(rawUid, 0x5A3C9E) % 0xFFFFFF
	local userHash = string.format("USR-%06X", hashedNum)
	local placeIdStr = tostring(game.PlaceId or 0)
	local isMob = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
	local devTag = isMob and "MOB" or "PC"
	local devStr = isMob and "Mobile (Touch)" or "PC"
	local exStr = "Unknown"
	pcall(function()
		if typeof(identifyexecutor) == "function" then
			exStr = tostring((identifyexecutor()))
		elseif typeof(getexecutorname) == "function" then
			exStr = tostring((getexecutorname()))
		end
	end)
	local execTag = string.gsub(exStr, "[^%w]", "")
	local sessionId = string.format("%s-%s-%s-%s", userHash, placeIdStr, devTag, string.sub(execTag, 1, 8))

	local function _enc(str)
		local ok, res = pcall(function()
			return HttpService:UrlEncode(tostring(str or ""))
		end)
		if ok and type(res) == "string" then
			return res
		end
		return string.gsub(tostring(str or ""), "[^%w%-_%.]", "_")
	end

	local function _ping(isInit)
		if not ScriptAlive then return end
		local curState = tostring(CurrentStatusText or "Idle")
		local mapStr = tostring(CurrentMapName or "Unknown Map")
		local sentOk = false
		pcall(function()
			local q = string.format(
				"%s/api/ping?s=%s&u=%s&p=%s&m=%s&d=%s&e=%s&v=%s&st=%s&i=%s&_t=%d",
				_ep,
				_enc(sessionId),
				_enc(userHash),
				_enc(placeIdStr),
				_enc(mapStr),
				_enc(devStr),
				_enc(exStr),
				_enc(SCRIPT_VERSION),
				_enc(curState),
				isInit and "1" or "0",
				os.time()
			)
			local r = game:HttpGet(q)
			if type(r) == "string" and #r > 0 then
				sentOk = true
			end
		end)
		if not sentOk and httpRequestFn then
			pcall(function()
				httpRequestFn({
					Url = _ep .. "/api/heartbeat",
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = HttpService:JSONEncode({
						sessionId = sessionId,
						userHash = userHash,
						placeId = placeIdStr,
						mapName = mapStr,
						device = devStr,
						executor = exStr,
						scriptVersion = SCRIPT_VERSION,
						state = curState,
						isInit = (isInit == true),
					}),
				})
			end)
		end
	end

	table.insert(Connections, Players.PlayerRemoving:Connect(function(plr)
		if plr == LocalPlayer then
			pcall(function()
				game:HttpGet(string.format("%s/api/leave?s=%s&_t=%d", _ep, _enc(sessionId), os.time()))
			end)
		end
	end))

	task.spawn(function()
		_ping(true)
		while ScriptAlive and ScreenGui and ScreenGui.Parent do
			task.wait(180)
			if ScriptAlive then
				_ping(false)
			end
		end
	end)
end)()

_G.SerennityHubCleanup = function()
	ScriptAlive = false
	stopAllActiveMovementAndCombat()
	for _, conn in ipairs(Connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(Connections)
	if ScreenGui and ScreenGui.Parent then
		ScreenGui:Destroy()
	end
end

notify("Serennity Hub • " .. SCRIPT_VERSION, CurrentMapName .. " loaded successfully.", 3.5)

if RtState.MainWindow then
	RtState.MainWindow.Visible = true
end
