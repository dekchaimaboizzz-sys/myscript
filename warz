-- Warz ESP + Aimbot — Executor Version
-- Features: 2D Boxes, Skeleton, Names, FOV Circle, Smooth Aimbot
-- Drawing API based — paste into executor while in-game

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ── CLEANUP PREVIOUS ────────────────────────────────────────
pcall(function()
	local oldGui = game:GetService("CoreGui"):FindFirstChild("WarzUtil_GUI")
	if oldGui then oldGui:Destroy() end
end)

if _G.WarzESP_Cleanup then
	pcall(_G.WarzESP_Cleanup)
end

-- ── CONFIG ──────────────────────────────────────────────────
local CFG = {
	-- ESP
	ESP_Enabled     = false,
	ESP_Boxes       = true,
	ESP_Skeleton    = true,
	ESP_Names       = true,
	ESP_HealthBar   = true,
	ESP_MaxDist     = 1000,
	ESP_Tracers     = false,

	-- Aimbot
	AIM_Enabled     = false,
	AIM_FOV         = 200,
	AIM_Smooth      = 5,
	AIM_Part        = "Head",
	AIM_ShowFOV     = true,
	AIM_TeamCheck   = true,
	AIM_DeadCheck   = true,
	AIM_VisCheck    = false,

	-- Colors
	COL_Enemy       = Color3.fromRGB(255, 50, 50),
	COL_Teammate    = Color3.fromRGB(50, 255, 100),
	COL_Target      = Color3.fromRGB(255, 200, 50),
	COL_Boss        = Color3.fromRGB(200, 50, 255),
	COL_Dead        = Color3.fromRGB(120, 120, 120),
	COL_Skeleton    = Color3.fromRGB(255, 255, 255),
	COL_FOV         = Color3.fromRGB(255, 255, 255),
}

-- ── STATE ───────────────────────────────────────────────────
local espCache = {}
local renderConn = nil
local aimTarget = nil
local aimLocked = false
local rightMouseDown = false
local lockedPlayer = nil

local MAX_SKELETON_LINES = 30

-- ── FOV CIRCLE ──────────────────────────────────────────────
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = CFG.AIM_FOV
fovCircle.Color = CFG.COL_FOV
fovCircle.Thickness = 1.5
fovCircle.Transparency = 0.6
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.Visible = false

-- ── HELPER FUNCTIONS ────────────────────────────────────────
local function getLocalRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function isTeammate(player)
	if not player or not LocalPlayer then return false end

	local myClan = LocalPlayer:GetAttribute("ClanId")
	local myParty = LocalPlayer:GetAttribute("WarzPartyId")
	local myRoom = LocalPlayer:GetAttribute("ClanRoom")

	if myClan and myClan ~= "" then
		local theirClan = player:GetAttribute("ClanId")
		local theirRoom = player:GetAttribute("ClanRoom")
		if theirClan == myClan and myRoom and myRoom ~= "" and theirRoom == myRoom then
			return true
		end
	end

	if myParty and myParty ~= "" then
		if player:GetAttribute("WarzPartyId") == myParty then
			return true
		end
	end

	return false
end

local function isDead(character)
	if not character then return true end
	if character:GetAttribute("WarzDead") then return true end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return true end
	return false
end

local function getHealth(character)
	if not character then return 0, 100 end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then return hum.Health, hum.MaxHealth end
	return 0, 100
end

local function getWeapon(character)
	if not character then return "" end
	local held = character:GetAttribute("HeldWeapon")
	if held and held ~= "" then return held end
	local wh = character:FindFirstChild("WorldHeld")
	if wh then
		local wId = wh:GetAttribute("WeaponId")
		if wId then return wId end
	end
	return ""
end

local function worldToScreen(pos)
	local vec, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function getCharacterColor(player, character, espType)
	if isDead(character) then
		return CFG.COL_Dead
	end

	if espType == "boss" then return CFG.COL_Boss end
	if espType == "target" or espType == "dummy" then return CFG.COL_Target end

	if player and isTeammate(player) then
		return CFG.COL_Teammate
	end

	return CFG.COL_Enemy
end

-- (Authoritative animated head position and aimbot targeting are defined below with HeroVisualsLocal)

-- ── SKELETON ─────────────────────────────────────────────────
-- Warz uses a Biped rig with bones named Bip01_*.
-- The game creates Parts inside a "WarzHitboxes" Folder under each
-- character, each Part named after its bone and Welded to HumanoidRootPart,
-- with its position updated every frame via BoneWorld() in WarzHitboxes.lua.
-- We read those Part positions directly — they are the actual bone world
-- positions, animated and replicated, with no lag or bind-pose issues.
--
-- Connections are taken directly from the cylinder (capsule) pairs in
-- WarzHitboxes.lua u10 table: {parent_bone → child_bone}.

-- Warz Biped connections: {partNameInWarzHitboxes, childPartName}
-- "Cylinder" parts use {name, child} from u10 in WarzHitboxes.lua
-- "Ball" parts are the joint endpoints from u8
local WARZ_SKEL_PAIRS = {
	-- spine / neck / head
	{"Bip01_Pelvis",    "Bip01_Spine"},
	{"Bip01_Spine",     "Bip01_Spine1"},
	{"Bip01_Spine1",    "Bip01_Spine2"},
	{"Bip01_Spine2",    "Bip01_Neck"},
	{"Bip01_Neck",      "Bip01_Head"},
	-- left arm
	{"Bip01_Spine2",    "Bip01_L_UpperArm"},
	{"Bip01_L_UpperArm","Bip01_L_Forearm"},
	{"Bip01_L_Forearm", "Bip01_L_Hand"},
	-- right arm
	{"Bip01_Spine2",    "Bip01_R_UpperArm"},
	{"Bip01_R_UpperArm","Bip01_R_Forearm"},
	{"Bip01_R_Forearm", "Bip01_R_Hand"},
	-- left leg
	{"Bip01_Pelvis",    "Bip01_L_Thigh"},
	{"Bip01_L_Thigh",   "Bip01_L_Calf"},
	{"Bip01_L_Calf",    "Bip01_L_Foot"},
	-- right leg
	{"Bip01_Pelvis",    "Bip01_R_Thigh"},
	{"Bip01_R_Thigh",   "Bip01_R_Calf"},
	{"Bip01_R_Calf",    "Bip01_R_Foot"},
}

-- R15 fallback
local R15_PAIRS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

-- R6 fallback
local R6_PAIRS = {
	{"Head","Torso"},
	{"Torso","Left Arm"},{"Torso","Right Arm"},
	{"Torso","Left Leg"},{"Torso","Right Leg"},
}

-- ── VISUAL RIG FINDER (HeroVisualsLocal) ──────────────────────
-- Warz renders visual models inside workspace.HeroVisualsLocal.
-- Folders are named "<HeroId>_<CharacterName>" (e.g. "Drift_Manop2018").
local cachedVisualHolders = {}
local cachedHeadBones = {}

local function findVisualHolder(character)
	if not character then return nil end
	local hvl = Workspace:FindFirstChild("HeroVisualsLocal")
	if not hvl then return nil end

	local charName = character.Name
	local cached = cachedVisualHolders[charName]
	if cached and cached.Parent == hvl then
		return cached
	end

	-- Look for folder named "*_<charName>"
	local suffix = "_" .. charName
	for _, folder in ipairs(hvl:GetChildren()) do
		if folder.Name == charName or string.sub(folder.Name, -#suffix) == suffix then
			cachedVisualHolders[charName] = folder
			return folder
		end
	end

	return nil
end

local function getBoneConnections(character)
	local connections = {}

	-- ── Pass 1: Actual Animated Bones from HeroVisualsLocal ──────
	local visualHolder = findVisualHolder(character)
	if visualHolder then
		local bonePos = {}
		local headWorldPos = nil
		for _, bone in ipairs(visualHolder:GetDescendants()) do
			if bone:IsA("Bone") then
				local ok, cf = pcall(function() return bone.TransformedWorldCFrame end)
				if ok and cf then
					if bone.Name == "Bip01_Head" then
						local headCenter = (cf * CFrame.new(0.35, 0, 0)).Position
						bonePos[bone.Name] = headCenter
						headWorldPos = headCenter
					else
						bonePos[bone.Name] = cf.Position
					end
				end
			end
		end

		if bonePos["Bip01_Pelvis"] or bonePos["Bip01_Spine"] then
			for _, pair in ipairs(WARZ_SKEL_PAIRS) do
				local fromPos = bonePos[pair[1]]
				local toPos   = bonePos[pair[2]]
				if fromPos and toPos then
					table.insert(connections, { from = fromPos, to = toPos })
				end
			end
			if #connections > 0 then return connections, headWorldPos end
		end
	end

	-- ── Pass 2: WarzHitboxes folder fallback ─────────────────────
	local hitboxFolder = character:FindFirstChild("WarzHitboxes")
	if hitboxFolder then
		local bonePos = {}
		local headWorldPos = nil
		for _, part in ipairs(hitboxFolder:GetDescendants()) do
			if part:IsA("BasePart") then
				bonePos[part.Name] = part.Position
				if part.Name == "Bip01_Head" then
					headWorldPos = part.Position
				end
			end
		end

		if bonePos["Bip01_Pelvis"] or bonePos["Bip01_Spine"] then
			for _, pair in ipairs(WARZ_SKEL_PAIRS) do
				local fromPos = bonePos[pair[1]]
				local toPos   = bonePos[pair[2]]
				if fromPos and toPos then
					table.insert(connections, { from = fromPos, to = toPos })
				end
			end
			if #connections > 0 then return connections, headWorldPos end
		end
	end

	-- ── Pass 3: R15 / R6 standard rig fallback ───────────────────
	local partPos = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") then
			partPos[child.Name] = child.Position
		end
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") then
			for _, grand in ipairs(child:GetChildren()) do
				if grand:IsA("BasePart") and not partPos[grand.Name] then
					partPos[grand.Name] = grand.Position
				end
			end
		end
	end

	local pairs_to_use
	if partPos["UpperTorso"] then
		pairs_to_use = R15_PAIRS
	elseif partPos["Torso"] then
		pairs_to_use = R6_PAIRS
	else
		local rootPos = partPos["HumanoidRootPart"]
		if rootPos then
			for name, pos in pairs(partPos) do
				if name ~= "HumanoidRootPart" then
					table.insert(connections, { from = rootPos, to = pos })
				end
			end
		end
		return connections, partPos["Head"]
	end

	for _, pair in ipairs(pairs_to_use) do
		local fromPos, toPos = partPos[pair[1]], partPos[pair[2]]
		if fromPos and toPos then
			table.insert(connections, { from = fromPos, to = toPos })
		end
	end

	return connections, partPos["Head"]
end

-- ── AUTHORITATIVE HEAD & AIMBOT TARGETING ───────────────────
-- Authoritative Warz head mesh (P_Head) has size (0.504, 0.697, 0.633) studs.
-- 0.34 studs is the exact half-height/extent, tightly wrapping the skull & helmet.
local HEAD_RADIUS_WORLD = 0.34

-- 1. Animated Warz Head Position
-- Strictly uses the live animated Bip01_Head bone from HeroVisualsLocal transformed CFrame.
-- Never falls back to static R15 Head, neck, torso, or HipHeight.
local function getAnimatedHeadPosition(character)
	if not character then return nil end

	-- Fast path: directly access the active animated head bone for this character
	local bone = cachedHeadBones[character]
	if bone and bone.Parent and bone:IsDescendantOf(Workspace) then
		local ok, cf = pcall(function() return bone.TransformedWorldCFrame end)
		if ok and cf then
			return (cf * CFrame.new(0.35, 0, 0)).Position
		end
	end

	-- Fresh lookup from HeroVisualsLocal
	local visualHolder = findVisualHolder(character)
	if visualHolder then
		local headBone = visualHolder:FindFirstChild("Bip01_Head", true)
		if headBone and headBone:IsA("Bone") then
			cachedHeadBones[character] = headBone
			local ok, cf = pcall(function() return headBone.TransformedWorldCFrame end)
			if ok and cf then
				return (cf * CFrame.new(0.35, 0, 0)).Position
			end
		end
	end

	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Bone") and (desc.Name == "Bip01_Head" or desc.Name == "Head") then
			cachedHeadBones[character] = desc
			local ok, cf = pcall(function() return desc.TransformedWorldCFrame end)
			if ok and cf then
				return (cf * CFrame.new(0.35, 0, 0)).Position
			end
		end
	end

	return nil
end

local getHeadBonePosition = getAnimatedHeadPosition

-- 2. Authoritative Head Circle Data (Center + Screen-space Radius)
-- Pipeline: Animated Warz Head Position -> World-to-Screen -> Head Circle Center
-- This is the SINGLE shared definition for both Head Circle ESP and Head Aim Targeting.
local function getHeadCircleData(character, player)
	if not character then return nil end

	local headWorldPos = getAnimatedHeadPosition(character)
	if not headWorldPos then return nil end

	local headScreen, headOn, depth = worldToScreen(headWorldPos)
	if not headOn or not depth or depth <= 0.1 then return nil end

	-- True perspective projection of a sphere of radius HEAD_RADIUS_WORLD at distance depth:
	-- radius = (HEAD_RADIUS_WORLD * focalLength) / depth
	-- Matches visible head geometry regardless of camera FOV, scope zoom, or screen resolution.
	local vfovRad = math.rad(Camera.FieldOfView)
	local focalLength = (Camera.ViewportSize.Y * 0.5) / math.tan(vfovRad * 0.5)
	local radius = (HEAD_RADIUS_WORLD * focalLength) / depth
	radius = math.clamp(radius, 2, 200)

	return {
		worldPos = headWorldPos,
		screenPos = headScreen,
		radius = radius,
	}
end

-- 3. Aimbot Target Position
-- For Head: Center of Head Circle is the target point. No torso/neck/R15 drift.
local function getAimPosition(character, player)
	if not character then return nil, nil, nil end

	local partName = CFG.AIM_Part

	if partName == "Head" then
		local headData = getHeadCircleData(character, player)
		if not headData then
			return nil, nil, nil
		end
		return headData.worldPos, headData.screenPos, headData.radius
	end

	-- Non-head parts: find BasePart by name
	local namedPart = character:FindFirstChild(partName)
	if namedPart and namedPart:IsA("BasePart") then
		local sPos, onScreen = worldToScreen(namedPart.Position)
		return namedPart.Position, (onScreen and sPos or nil), nil
	end
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name == partName then
			local sPos, onScreen = worldToScreen(desc.Position)
			return desc.Position, (onScreen and sPos or nil), nil
		end
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if root then
		local sPos, onScreen = worldToScreen(root.Position)
		return root.Position, (onScreen and sPos or nil), nil
	end
	return nil, nil, nil
end

local BOX_PADDING = 3

local function getBoundingBox(character, player, preConnections, preHeadData)
	if not character then return nil end

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local hasPoints = false

	-- 1. Animated Skeleton Screen Positions (authoritative primary source)
	local connections = preConnections
	if not connections then
		connections = getBoneConnections(character)
	end

	if connections and #connections > 0 then
		for _, conn in ipairs(connections) do
			local fromScreen, fromOn = worldToScreen(conn.from)
			if fromOn then
				hasPoints = true
				if fromScreen.X < minX then minX = fromScreen.X end
				if fromScreen.Y < minY then minY = fromScreen.Y end
				if fromScreen.X > maxX then maxX = fromScreen.X end
				if fromScreen.Y > maxY then maxY = fromScreen.Y end
			end

			local toScreen, toOn = worldToScreen(conn.to)
			if toOn then
				hasPoints = true
				if toScreen.X < minX then minX = toScreen.X end
				if toScreen.Y < minY then minY = toScreen.Y end
				if toScreen.X > maxX then maxX = toScreen.X end
				if toScreen.Y > maxY then maxY = toScreen.Y end
			end
		end
	end

	-- 2. Include Head Circle bounds so the box fully contains the visible head
	local headData = preHeadData
	if not headData then
		headData = getHeadCircleData(character, player)
	end

	if headData and headData.screenPos then
		hasPoints = true
		local hx = headData.screenPos.X
		local hy = headData.screenPos.Y
		local hr = headData.radius

		if (hx - hr) < minX then minX = hx - hr end
		if (hx + hr) > maxX then maxX = hx + hr end
		if (hy - hr) < minY then minY = hy - hr end
		if (hy + hr) > maxY then maxY = hy + hr end
	end

	if not hasPoints or minX >= maxX or minY >= maxY then
		return nil
	end

	-- Small configurable padding so lines never touch the box edge
	minX = minX - BOX_PADDING
	maxX = maxX + BOX_PADDING
	minY = minY - BOX_PADDING
	maxY = maxY + BOX_PADDING

	return {
		topLeft     = Vector2.new(minX, minY),
		topRight    = Vector2.new(maxX, minY),
		bottomLeft  = Vector2.new(minX, maxY),
		bottomRight = Vector2.new(maxX, maxY),
	}
end

-- ── DRAWING OBJECT CREATION ─────────────────────────────────
local function newLine(color, thickness)
	local l = Drawing.new("Line")
	l.Color = color or Color3.new(1, 1, 1)
	l.Thickness = thickness or 1
	l.Transparency = 1
	l.Visible = false
	return l
end

local function newText(color, size)
	local t = Drawing.new("Text")
	t.Color = color or Color3.new(1, 1, 1)
	t.Size = size or 13
	t.Center = true
	t.Outline = true
	t.OutlineColor = Color3.fromRGB(0, 0, 0)
	t.Font = Drawing.Fonts.Gotham or 2
	t.Visible = false
	return t
end

local function newCircle(color, thickness, radius)
	local c = Drawing.new("Circle")
	c.Color = color or Color3.new(1, 1, 1)
	c.Thickness = thickness or 1.5
	c.Transparency = 1
	c.Radius = radius or 6
	c.Filled = false
	c.NumSides = 24
	c.Visible = false
	return c
end

-- ── ESP CACHE PER ENTITY ────────────────────────────────────
local function createESPData()
	local data = {}

	data.boxTop    = newLine(CFG.COL_Enemy, 1.5)
	data.boxBottom = newLine(CFG.COL_Enemy, 1.5)
	data.boxLeft   = newLine(CFG.COL_Enemy, 1.5)
	data.boxRight  = newLine(CFG.COL_Enemy, 1.5)

	data.nameText  = newText(Color3.new(1, 1, 1), 13)
	data.distText  = newText(Color3.fromRGB(200, 200, 200), 11)

	data.healthBarBg  = newLine(Color3.fromRGB(0, 0, 0), 4)
	data.healthBarFg  = newLine(Color3.fromRGB(0, 255, 0), 2)

	data.tracerLine = newLine(Color3.new(1, 1, 1), 1)

	data.skelLines = {}
	for i = 1, MAX_SKELETON_LINES do
		data.skelLines[i] = newLine(CFG.COL_Skeleton, 1.5)
	end

	data.headCircle = newCircle(CFG.COL_Skeleton, 1.5, 6)

	return data
end

local function hideESPData(data)
	if not data then return end
	data.boxTop.Visible = false
	data.boxBottom.Visible = false
	data.boxLeft.Visible = false
	data.boxRight.Visible = false
	data.nameText.Visible = false
	data.distText.Visible = false
	data.healthBarBg.Visible = false
	data.healthBarFg.Visible = false
	data.tracerLine.Visible = false

	for i = 1, MAX_SKELETON_LINES do
		data.skelLines[i].Visible = false
	end

	if data.headCircle then
		data.headCircle.Visible = false
	end
end

local function destroyESPData(data)
	if not data then return end

	pcall(function() data.boxTop:Remove() end)
	pcall(function() data.boxBottom:Remove() end)
	pcall(function() data.boxLeft:Remove() end)
	pcall(function() data.boxRight:Remove() end)
	pcall(function() data.nameText:Remove() end)
	pcall(function() data.distText:Remove() end)
	pcall(function() data.healthBarBg:Remove() end)
	pcall(function() data.healthBarFg:Remove() end)
	pcall(function() data.tracerLine:Remove() end)

	for i = 1, MAX_SKELETON_LINES do
		pcall(function() data.skelLines[i]:Remove() end)
	end

	if data.headCircle then
		pcall(function() data.headCircle:Remove() end)
	end
end

-- ── ESP UPDATE PER ENTITY ───────────────────────────────────
local function updateEntityESP(key, character, player, espType)
	if not character or not character.Parent then
		if espCache[key] then
			hideESPData(espCache[key].draw)
		end
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root then
		if espCache[key] then hideESPData(espCache[key].draw) end
		return
	end

	if not espCache[key] then
		espCache[key] = {
			draw = createESPData(),
			character = character,
			player = player,
			espType = espType,
		}
	end

	local data = espCache[key].draw
	local localRoot = getLocalRoot()

	local dist = localRoot and (root.Position - localRoot.Position).Magnitude or 0

	if dist > CFG.ESP_MaxDist then
		hideESPData(data)
		return
	end

	local _, onScreen = worldToScreen(root.Position)
	if not onScreen then
		hideESPData(data)
		return
	end

	local color = getCharacterColor(player, character, espType)
	local dead = isDead(character)

	local connections = nil
	local headData = nil
	if CFG.ESP_Boxes or CFG.ESP_Skeleton then
		connections = getBoneConnections(character)
		headData = getHeadCircleData(character, player)
	end

	-- ── Bounding Box ────────────────────────────────────────
	local bbox = nil
	if CFG.ESP_Boxes then
		bbox = getBoundingBox(character, player, connections, headData)
		if bbox then
			data.boxTop.From    = bbox.topLeft
			data.boxTop.To      = bbox.topRight
			data.boxTop.Color   = color
			data.boxTop.Visible = true

			data.boxBottom.From    = bbox.bottomLeft
			data.boxBottom.To      = bbox.bottomRight
			data.boxBottom.Color   = color
			data.boxBottom.Visible = true

			data.boxLeft.From    = bbox.topLeft
			data.boxLeft.To      = bbox.bottomLeft
			data.boxLeft.Color   = color
			data.boxLeft.Visible = true

			data.boxRight.From    = bbox.topRight
			data.boxRight.To      = bbox.bottomRight
			data.boxRight.Color   = color
			data.boxRight.Visible = true

			-- ── Health Bar (left side of box) ───────────────
			if CFG.ESP_HealthBar then
				local hp, maxHp = getHealth(character)
				local ratio = math.clamp(hp / math.max(maxHp, 1), 0, 1)
				local boxH = bbox.bottomLeft.Y - bbox.topLeft.Y

				local barX = bbox.topLeft.X - 5
				local barTop = bbox.topLeft.Y
				local barBot = bbox.bottomLeft.Y

				data.healthBarBg.From = Vector2.new(barX, barTop)
				data.healthBarBg.To   = Vector2.new(barX, barBot)
				data.healthBarBg.Visible = true

				local fillBot = barBot
				local fillTop = barBot - (boxH * ratio)

				local barColor
				if ratio > 0.5 then
					barColor = Color3.fromRGB(0, 255, 0)
				elseif ratio > 0.25 then
					barColor = Color3.fromRGB(255, 255, 0)
				else
					barColor = Color3.fromRGB(255, 0, 0)
				end

				data.healthBarFg.From  = Vector2.new(barX, fillTop)
				data.healthBarFg.To    = Vector2.new(barX, fillBot)
				data.healthBarFg.Color = barColor
				data.healthBarFg.Visible = true
			else
				data.healthBarBg.Visible = false
				data.healthBarFg.Visible = false
			end
		else
			data.boxTop.Visible = false
			data.boxBottom.Visible = false
			data.boxLeft.Visible = false
			data.boxRight.Visible = false
			data.healthBarBg.Visible = false
			data.healthBarFg.Visible = false
		end
	else
		data.boxTop.Visible = false
		data.boxBottom.Visible = false
		data.boxLeft.Visible = false
		data.boxRight.Visible = false
		data.healthBarBg.Visible = false
		data.healthBarFg.Visible = false
	end

	-- ── Name + Distance ─────────────────────────────────────
	if CFG.ESP_Names then
		local screenPos, nameOnScreen
		if bbox then
			screenPos = Vector2.new((bbox.topLeft.X + bbox.topRight.X) / 2, bbox.topLeft.Y - 14)
			nameOnScreen = true
		else
			local headPos = (headData and headData.worldPos) or (root.Position + Vector3.new(0, 3.5, 0))
			screenPos, nameOnScreen = worldToScreen(headPos)
			if screenPos then
				screenPos = screenPos - Vector2.new(0, 10)
			end
		end

		if nameOnScreen and screenPos then
			local displayName
			if player then
				displayName = player.DisplayName ~= "" and player.DisplayName or player.Name
			else
				displayName = character.Name
			end

			local weapon = getWeapon(character)
			local nameStr = displayName
			if dead then nameStr = nameStr .. " [DEAD]" end

			data.nameText.Text = nameStr
			data.nameText.Position = screenPos - Vector2.new(0, 2)
			data.nameText.Color = color
			data.nameText.Visible = true

			local distStr = "[" .. string.format("%.0f", dist) .. "m]"
			if weapon ~= "" then
				distStr = distStr .. " " .. weapon
			end

			data.distText.Text = distStr
			data.distText.Position = screenPos + Vector2.new(0, 14)
			data.distText.Color = Color3.fromRGB(200, 200, 200)
			data.distText.Visible = true
		else
			data.nameText.Visible = false
			data.distText.Visible = false
		end
	else
		data.nameText.Visible = false
		data.distText.Visible = false
	end

	-- ── Skeleton ────────────────────────────────────────────
	if CFG.ESP_Skeleton and connections then
		local count = math.min(#connections, MAX_SKELETON_LINES)

		for i = 1, count do
			local conn = connections[i]
			local fromScreen, fromOn = worldToScreen(conn.from)
			local toScreen, toOn = worldToScreen(conn.to)

			if fromOn and toOn then
				data.skelLines[i].From  = fromScreen
				data.skelLines[i].To    = toScreen
				data.skelLines[i].Color = CFG.COL_Skeleton
				data.skelLines[i].Visible = true
			else
				data.skelLines[i].Visible = false
			end
		end

		for i = count + 1, MAX_SKELETON_LINES do
			data.skelLines[i].Visible = false
		end

		-- ── Head Skeleton Circle ────────────────────────────
		if data.headCircle then
			if headData then
				data.headCircle.Position = headData.screenPos
				data.headCircle.Radius = headData.radius
				data.headCircle.Color = CFG.COL_Skeleton
				data.headCircle.Visible = true
			else
				data.headCircle.Visible = false
			end
		end
	else
		for i = 1, MAX_SKELETON_LINES do
			data.skelLines[i].Visible = false
		end
		if data.headCircle then
			data.headCircle.Visible = false
		end
	end

	-- ── Tracer ──────────────────────────────────────────────
	if CFG.ESP_Tracers then
		local screenPos, tOnScreen = worldToScreen(root.Position)
		if tOnScreen then
			local viewSize = Camera.ViewportSize
			data.tracerLine.From    = Vector2.new(viewSize.X / 2, viewSize.Y)
			data.tracerLine.To      = screenPos
			data.tracerLine.Color   = color
			data.tracerLine.Visible = true
		else
			data.tracerLine.Visible = false
		end
	else
		data.tracerLine.Visible = false
	end
end

-- ── AIMBOT ──────────────────────────────────────────────────
local function getClosestTarget()
	local screenCenter = Camera.ViewportSize / 2
	local centerVec = Vector2.new(screenCenter.X, screenCenter.Y)
	local closest = nil
	local closestDist = CFG.AIM_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if CFG.AIM_TeamCheck and isTeammate(player) then continue end

		local character = player.Character
		if not character then continue end
		if CFG.AIM_DeadCheck and isDead(character) then continue end

		local aimPos, aimScreenPos = getAimPosition(character, player)
		if not aimPos then continue end

		local screenPos = aimScreenPos
		if not screenPos then
			local sPos, onScreen = worldToScreen(aimPos)
			if not onScreen then continue end
			screenPos = sPos
		end

		-- STRICT: Head targeting must be constrained to the actual Head Circle
		if CFG.AIM_Part == "Head" then
			local headData = getHeadCircleData(character, player)
			if not headData then continue end
			if (screenPos - headData.screenPos).Magnitude > headData.radius then
				continue
			end
			-- The center of the Head Circle is authoritative
			screenPos = headData.screenPos
		end

		local distToCenter = (screenPos - centerVec).Magnitude
		if distToCenter < closestDist then
			closestDist = distToCenter
			closest = {
				player = player,
				character = character,
				position = aimPos,
				screenPos = screenPos,
			}
		end
	end

	return closest
end

local function isLockedTargetValid()
	if not lockedPlayer then return false end
	local character = lockedPlayer.Character
	if not character or not character.Parent then return false end
	if CFG.AIM_DeadCheck and isDead(character) then return false end

	local aimPos, aimScreenPos = getAimPosition(character, lockedPlayer)
	if not aimPos then return false end

	local screenPos = aimScreenPos
	if not screenPos then
		local sPos, onScreen = worldToScreen(aimPos)
		if not onScreen then return false end
		screenPos = sPos
	end

	-- STRICT: Target point must not be outside the Head Circle
	if CFG.AIM_Part == "Head" then
		local headData = getHeadCircleData(character, lockedPlayer)
		if not headData then return false end
		if (screenPos - headData.screenPos).Magnitude > headData.radius then
			return false
		end
	end

	return true
end

local function doAim()
	if not CFG.AIM_Enabled then return end
	if not rightMouseDown then
		lockedPlayer = nil
		aimTarget = nil
		return
	end
	if guiOpen then return end

	-- keep locked target if still valid
	if lockedPlayer and isLockedTargetValid() then
		local character = lockedPlayer.Character
		local aimPos, aimScreenPos = getAimPosition(character, lockedPlayer)
		local screenPos = aimScreenPos
		if not screenPos then
			local sPos, onScreen = worldToScreen(aimPos)
			if not onScreen then
				lockedPlayer = nil
				aimTarget = nil
				return
			end
			screenPos = sPos
		end

		if CFG.AIM_Part == "Head" then
			local headData = getHeadCircleData(character, lockedPlayer)
			if not headData then
				lockedPlayer = nil
				aimTarget = nil
				return
			end
			if (screenPos - headData.screenPos).Magnitude > headData.radius then
				lockedPlayer = nil
				aimTarget = nil
				return
			end
			screenPos = headData.screenPos
		end

		aimTarget = {
			player = lockedPlayer,
			character = character,
			position = aimPos,
			screenPos = screenPos,
		}
	else
		-- find new closest target
		local target = getClosestTarget()
		if not target then
			lockedPlayer = nil
			aimTarget = nil
			return
		end
		lockedPlayer = target.player
		aimTarget = target
	end

	local screenCenter = Camera.ViewportSize / 2
	local centerVec = Vector2.new(screenCenter.X, screenCenter.Y)
	local delta = aimTarget.screenPos - centerVec
	local moveX = delta.X / CFG.AIM_Smooth
	local moveY = delta.Y / CFG.AIM_Smooth

	pcall(function()
		mousemoverel(moveX, moveY)
	end)

	pcall(function()
		if not mousemoverel then
			Input.MoveMouse(moveX, moveY)
		end
	end)
end

-- ── MAIN RENDER LOOP ────────────────────────────────────────
local function mainLoop()
	-- Update FOV circle
	if CFG.AIM_ShowFOV and CFG.AIM_Enabled then
		local center = Camera.ViewportSize / 2
		fovCircle.Position = Vector2.new(center.X, center.Y)
		fovCircle.Radius = CFG.AIM_FOV
		fovCircle.Color = CFG.COL_FOV
		fovCircle.Visible = true
	else
		fovCircle.Visible = false
	end

	if CFG.ESP_Enabled then
		-- Players
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local key = "p_" .. player.UserId
				pcall(function()
					updateEntityESP(key, player.Character, player, "player")
				end)
			end
		end

		-- Workspace folders
		for _, info in ipairs({
			{"Targets", CFG.COL_Target, "target"},
			{"WarzDummies", CFG.COL_Target, "dummy"},
			{"WarzBoss", CFG.COL_Boss, "boss"},
		}) do
			local folder = Workspace:FindFirstChild(info[1])
			if folder then
				for _, child in ipairs(folder:GetChildren()) do
					if child:IsA("Model") then
						local key = "w_" .. info[1] .. "_" .. child:GetDebugId()
						pcall(function()
							updateEntityESP(key, child, nil, info[3])
						end)
					end
				end
			end
		end
	else
		for key, cached in pairs(espCache) do
			hideESPData(cached.draw)
		end
	end

	-- Cleanup stale
	for key, cached in pairs(espCache) do
		if cached.character and (not cached.character.Parent) then
			hideESPData(cached.draw)
			destroyESPData(cached.draw)
			if cachedHeadBones then cachedHeadBones[cached.character] = nil end
			espCache[key] = nil
		end
	end

	-- Aimbot
	if CFG.AIM_Enabled then
		pcall(doAim)
	end
end

-- ── RENDER BINDING (Post-Animator & Post-Camera for 0-frame latency) ──
-- WarzCamera runs at Last.Value - 2. WarzAnimator runs at Last.Value - 1.
-- Binding at Last.Value + 1 ensures both Camera CFrame and animated bones
-- are already 100% updated for the exact current frame being rendered,
-- eliminating any 1-frame lag behind head movement or camera rotation.
local boundSuccess = pcall(function()
	RunService:BindToRenderStep("WarzESP_Render", Enum.RenderPriority.Last.Value + 1, function()
		pcall(mainLoop)
	end)
end)

if not boundSuccess then
	renderConn = RunService.RenderStepped:Connect(function()
		pcall(mainLoop)
	end)
end

-- ── GLOBAL CLEANUP ──────────────────────────────────────────
_G.WarzESP_Cleanup = function()
	pcall(function()
		RunService:UnbindFromRenderStep("WarzESP_Render")
	end)
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end

	for key, cached in pairs(espCache) do
		destroyESPData(cached.draw)
		espCache[key] = nil
	end

	pcall(function() fovCircle:Remove() end)
	cachedVisualHolders = {}
	cachedHeadBones = {}
end

-- ── GUI ─────────────────────────────────────────────────────
local guiParent = (syn and syn.protect_gui) and game:GetService("CoreGui") or gethui and gethui() or game:GetService("CoreGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WarzUtil_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = guiParent

pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screenGui)
	end
end)

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.fromOffset(220, 380)
mainFrame.Position = UDim2.new(0, 10, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 50, 50)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.2
mainStroke.Parent = mainFrame

-- Title
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
titleBar.BackgroundTransparency = 0.5
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = mainFrame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "WARZ UTILITY"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.Parent = titleBar

-- Drag
local dragging, dragStart, startPos = false, nil, nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ── GUI BUILDER HELPERS ─────────────────────────────────────
local yOffset = 36

local function addSectionLabel(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.9, 0, 0, 18)
	label.Position = UDim2.new(0.05, 0, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 150, 50)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = mainFrame
	yOffset = yOffset + 20
end

local function addToggle(label, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 24)
	container.Position = UDim2.new(0.05, 0, 0, yOffset)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(0.7, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Text = label
	txt.TextColor3 = Color3.fromRGB(200, 200, 220)
	txt.Font = Enum.Font.Gotham
	txt.TextSize = 11
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Parent = container

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.28, 0, 0.85, 0)
	btn.Position = UDim2.new(0.72, 0, 0.075, 0)
	btn.BackgroundColor3 = default and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(80, 40, 40)
	btn.BorderSizePixel = 0
	btn.Text = default and "ON" or "OFF"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.AutoButtonColor = true
	btn.Parent = container

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	local state = default

	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(80, 40, 40)
		callback(state)
	end)

	yOffset = yOffset + 26
	return btn
end

local function addSlider(label, min, max, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 28)
	container.Position = UDim2.new(0.05, 0, 0, yOffset)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(0.55, 0, 0.5, 0)
	txt.BackgroundTransparency = 1
	txt.Text = label .. ": " .. tostring(default)
	txt.TextColor3 = Color3.fromRGB(200, 200, 220)
	txt.Font = Enum.Font.Gotham
	txt.TextSize = 10
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Parent = container

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(0.9, 0, 0, 6)
	sliderBg.Position = UDim2.new(0.05, 0, 0.7, 0)
	sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = container

	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

	local ratio = (default - min) / (max - min)

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBg

	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

	-- Minus button
	local minusBtn = Instance.new("TextButton")
	minusBtn.Size = UDim2.fromOffset(20, 14)
	minusBtn.Position = UDim2.new(0.6, 0, 0, 0)
	minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	minusBtn.BorderSizePixel = 0
	minusBtn.Text = "-"
	minusBtn.TextColor3 = Color3.new(1, 1, 1)
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 12
	minusBtn.Parent = container
	Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 3)

	-- Plus button
	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.fromOffset(20, 14)
	plusBtn.Position = UDim2.new(0.6, 24, 0, 0)
	plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	plusBtn.BorderSizePixel = 0
	plusBtn.Text = "+"
	plusBtn.TextColor3 = Color3.new(1, 1, 1)
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 12
	plusBtn.Parent = container
	Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 3)

	-- Value label
	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.fromOffset(40, 14)
	valLabel.Position = UDim2.new(0.6, 48, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = tostring(default)
	valLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 10
	valLabel.Parent = container

	local currentVal = default

	local function updateSlider(newVal)
		currentVal = math.clamp(newVal, min, max)
		local r = (currentVal - min) / (max - min)
		sliderFill.Size = UDim2.new(r, 0, 1, 0)
		valLabel.Text = tostring(math.floor(currentVal))
		txt.Text = label .. ": " .. tostring(math.floor(currentVal))
		callback(currentVal)
	end

	local step = math.max(1, (max - min) / 20)

	minusBtn.MouseButton1Click:Connect(function()
		updateSlider(currentVal - step)
	end)

	plusBtn.MouseButton1Click:Connect(function()
		updateSlider(currentVal + step)
	end)

	yOffset = yOffset + 32
end

local function addCycleButton(label, options, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 24)
	container.Position = UDim2.new(0.05, 0, 0, yOffset)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(0.55, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Text = label
	txt.TextColor3 = Color3.fromRGB(200, 200, 220)
	txt.Font = Enum.Font.Gotham
	txt.TextSize = 11
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.Parent = container

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.42, 0, 0.85, 0)
	btn.Position = UDim2.new(0.58, 0, 0.075, 0)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	btn.BorderSizePixel = 0
	btn.Text = default
	btn.TextColor3 = Color3.fromRGB(255, 180, 100)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = container

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	local idx = 1
	for i, v in ipairs(options) do
		if v == default then idx = i break end
	end

	btn.MouseButton1Click:Connect(function()
		idx = idx % #options + 1
		btn.Text = options[idx]
		callback(options[idx])
	end)

	yOffset = yOffset + 26
end

local function addSpacer(h)
	yOffset = yOffset + (h or 4)
end

-- ── BUILD GUI ───────────────────────────────────────────────
addSectionLabel("═══ ESP ═══")

local espToggleBtn = addToggle("ESP", CFG.ESP_Enabled, function(v)
	CFG.ESP_Enabled = v
end)

addToggle("Boxes", CFG.ESP_Boxes, function(v) CFG.ESP_Boxes = v end)
addToggle("Skeleton", CFG.ESP_Skeleton, function(v) CFG.ESP_Skeleton = v end)
addToggle("Names", CFG.ESP_Names, function(v) CFG.ESP_Names = v end)
addToggle("Health Bar", CFG.ESP_HealthBar, function(v) CFG.ESP_HealthBar = v end)
addToggle("Tracers", CFG.ESP_Tracers, function(v) CFG.ESP_Tracers = v end)

addSpacer(4)
addSectionLabel("═══ AIMBOT ═══")

local aimToggleBtn = addToggle("Aimbot", CFG.AIM_Enabled, function(v)
	CFG.AIM_Enabled = v
end)

addToggle("Show FOV", CFG.AIM_ShowFOV, function(v) CFG.AIM_ShowFOV = v end)

addSlider("FOV", 50, 500, CFG.AIM_FOV, function(v) CFG.AIM_FOV = v end)
addSlider("Smooth", 1, 20, CFG.AIM_Smooth, function(v) CFG.AIM_Smooth = v end)

addCycleButton("Aim Part", {"Head", "HumanoidRootPart"}, CFG.AIM_Part, function(v) CFG.AIM_Part = v end)
addToggle("Team Check", CFG.AIM_TeamCheck, function(v) CFG.AIM_TeamCheck = v end)

addSpacer(4)

-- Hotkey info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.9, 0, 0, 30)
infoLabel.Position = UDim2.new(0.05, 0, 0, yOffset)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Insert=ESP | RAlt=Aim Toggle\nRClick=Lock | Home/RShift=GUI"
infoLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 9
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextWrapped = true
infoLabel.Parent = mainFrame

yOffset = yOffset + 34

-- Resize frame to fit content
mainFrame.Size = UDim2.fromOffset(220, yOffset + 4)

-- ── MOUSE UNLOCK/LOCK ───────────────────────────────────────
local guiOpen = true

local function unlockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function lockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

local function toggleGUI()
	guiOpen = not guiOpen
	mainFrame.Visible = guiOpen
	if guiOpen then
		unlockMouse()
	else
		lockMouse()
		-- force lock again after short delay in case game overrides
		task.delay(0.1, function()
			if not guiOpen then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false
			end
		end)
	end
end

-- ── KEYBOARD HOTKEYS ────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
	-- Home / RightShift always work even when game processes input
	if input.KeyCode == Enum.KeyCode.Home or input.KeyCode == Enum.KeyCode.RightShift then
		toggleGUI()
		return
	end

	-- Right mouse button for aimbot lock
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseDown = true
	end

	if gp then return end

	if input.KeyCode == Enum.KeyCode.Insert then
		CFG.ESP_Enabled = not CFG.ESP_Enabled
	end

	if input.KeyCode == Enum.KeyCode.RightAlt then
		CFG.AIM_Enabled = not CFG.AIM_Enabled
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseDown = false
		lockedPlayer = nil
		aimTarget = nil
	end
end)

-- ── PLAYER EVENTS ───────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	local key = "p_" .. player.UserId
	if espCache[key] then
		hideESPData(espCache[key].draw)
		destroyESPData(espCache[key].draw)
		espCache[key] = nil
	end
	if player.Character and cachedHeadBones then
		cachedHeadBones[player.Character] = nil
	end
	if cachedVisualHolders then
		cachedVisualHolders[player.Name] = nil
	end
end)

-- ── DONE ────────────────────────────────────────────────────
print("[WarzUtil] Loaded — Insert=ESP | RightAlt=Aimbot | Home=GUI")
