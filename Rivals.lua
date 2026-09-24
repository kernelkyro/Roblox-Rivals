--========================================================--
--                  AIM + ENEMY ESP                      --
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================================================--
-- SETTINGS
--========================================================--

local FOV_RADIUS = 1500
local MAX_AIM_DISTANCE = 3000
local AIM_STRENGTH = 0.75
local TARGET_STICKINESS = 250
local CLOSE_RANGE = 18

local AIM_ENABLED = true
local ESP_ENABLED = true

local AIM_WALL_CHECK = true

--========================================================--
-- TEAM DETECTION
--========================================================--

--========================================================--
-- TEAM DETECTION
--========================================================--

local function isEnemy(player)
	if not player then
		return false
	end

	-- Never target yourself
	if player == LocalPlayer then
		return false
	end

	--====================================================--
	-- PRIMARY CHECK: ROBLOX TEAM
	--====================================================--

	local myTeam = LocalPlayer.Team
	local theirTeam = player.Team

	if myTeam ~= nil and theirTeam ~= nil then
		return myTeam ~= theirTeam
	end

	--====================================================--
	-- SECONDARY CHECK: TEAM COLOR
	--====================================================--

	local myTeamColor = LocalPlayer.TeamColor
	local theirTeamColor = player.TeamColor

	if myTeamColor ~= nil and theirTeamColor ~= nil then
		if myTeamColor ~= BrickColor.White()
			and theirTeamColor ~= BrickColor.White() then

			return myTeamColor ~= theirTeamColor
		end
	end

	--====================================================--
	-- NO RELIABLE TEAM INFORMATION
	--====================================================--

	-- Do NOT assume they are an enemy.
	-- This prevents unknown players from being targeted.
	return false
end

	--====================================================--
	-- 1. NORMAL ROBLOX TEAM
	--====================================================--

	if player.Team ~= nil then
		return "TEAM:" .. tostring(player.Team)
	end

	--====================================================--
	-- 2. TEAM COLOR
	--====================================================--

	if player.TeamColor ~= nil then
		return "COLOR:" .. tostring(player.TeamColor)
	end

	--====================================================--
	-- 3. PLAYER ATTRIBUTES
	--====================================================--

	local attribute = getAttributeValue(player, TEAM_ATTRIBUTE_NAMES)

	if attribute ~= nil then
		return "ATTR:" .. normalize(attribute)
	end

	--====================================================--
	-- 4. PLAYER VALUE OBJECTS
	--====================================================--

	local value = getValueObject(player, TEAM_VALUE_NAMES)

	if value ~= nil then
		return "VALUE:" .. normalize(value)
	end

	--====================================================--
	-- 5. CHARACTER ATTRIBUTES
	--====================================================--

	if player.Character then
		local characterAttribute =
			getAttributeValue(player.Character, TEAM_ATTRIBUTE_NAMES)

		if characterAttribute ~= nil then
			return "CHARATTR:" .. normalize(characterAttribute)
		end

		local characterValue =
			getValueObject(player.Character, TEAM_VALUE_NAMES)

		if characterValue ~= nil then
			return "CHARVALUE:" .. normalize(characterValue)
		end
	end

	return nil
end

local function getExplicitEnemyState(player)
	if not player then
		return nil
	end

	local value = getAttributeValue(player, ENEMY_ATTRIBUTE_NAMES)

	if value ~= nil then
		if typeof(value) == "boolean" then
			return value
		end

		local normalized = normalize(value)

		if normalized == "true"
			or normalized == "yes"
			or normalized == "1" then
			return true
		end

		if normalized == "false"
			or normalized == "no"
			or normalized == "0" then
			return false
		end
	end

	local valueObject = getValueObject(player, ENEMY_ATTRIBUTE_NAMES)

	if valueObject ~= nil and typeof(valueObject) == "boolean" then
		return valueObject
	end

	return nil
end

local function isEnemy(player)
	if not player then
		return false
	end

	if player == LocalPlayer then
		return false
	end

	--====================================================--
	-- EXPLICIT ENEMY / TEAMMATE FLAGS
	--====================================================--

	local explicitEnemy = getExplicitEnemyState(player)

	if explicitEnemy ~= nil then
		return explicitEnemy
	end

	--====================================================--
	-- COMPARE TEAM IDENTITIES
	--====================================================--

	local myTeam = getTeamIdentity(LocalPlayer)
	local theirTeam = getTeamIdentity(player)

	if myTeam ~= nil and theirTeam ~= nil then
		return myTeam ~= theirTeam
	end

	--====================================================--
	-- FALLBACK
	--====================================================--

	-- If the game gives us no usable team information,
	-- don't automatically assume this player is an enemy.
	--
	-- This prevents the script from deliberately targeting
	-- teammates when the game's custom team system cannot
	-- be identified.

	return false
end

--========================================================--
-- CHARACTER HELPERS
--========================================================--

local function getRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
end

local function getHumanoid(character)
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
	if not player.Character then
		return false
	end

	local humanoid = getHumanoid(player.Character)

	if not humanoid then
		return false
	end

	return humanoid.Health > 0
end

local function getAimPart(player)
	local character = player.Character

	if not character then
		return nil
	end

	local root = getRoot(character)

	if not root then
		return nil
	end

	local distance =
		(LocalPlayer.Character
		and getRoot(LocalPlayer.Character)
		and (root.Position - getRoot(LocalPlayer.Character).Position).Magnitude)
		or math.huge

	-- Close range: favor torso/root
	if distance <= CLOSE_RANGE then
		return character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("HumanoidRootPart")
			or character:FindFirstChild("Head")
	end

	-- Normal range: favor head
	return character:FindFirstChild("Head")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

--========================================================--
-- SCREEN DISTANCE
--========================================================--

local function getScreenDistance(worldPosition)
	local screenPosition, visible =
		Camera:WorldToViewportPoint(worldPosition)

	if not visible then
		return math.huge
	end

	local viewport = Camera.ViewportSize

	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local point = Vector2.new(
		screenPosition.X,
		screenPosition.Y
	)

	return (point - center).Magnitude
end

--========================================================--
-- WALL CHECK
--========================================================--

local function hasLineOfSight(part)
	if not AIM_WALL_CHECK then
		return true
	end

	if not part then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()

	params.FilterType = Enum.RaycastFilterType.Exclude

	local filter = {}

	if LocalPlayer.Character then
		table.insert(filter, LocalPlayer.Character)
	end

	table.insert(filter, Camera)

	params.FilterDescendantsInstances = filter
	params.IgnoreWater = true

	local result =
		workspace:Raycast(
			origin,
			direction,
			params
		)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(part.Parent)
end

--========================================================--
-- TARGET SELECTION
--========================================================--

local CurrentTarget = nil

local function getBestTarget()
	local bestPlayer = nil
	local bestPart = nil
	local bestScore = math.huge

	for _, player in ipairs(Players:GetPlayers()) do

		if isEnemy(player) and isAlive(player) then

			local part = getAimPart(player)

			if part then

				local distanceFromCamera =
					(Camera.CFrame.Position - part.Position).Magnitude

				if distanceFromCamera <= MAX_AIM_DISTANCE then

					local screenDistance =
						getScreenDistance(part.Position)

					if screenDistance <= FOV_RADIUS then

						if hasLineOfSight(part) then

							-- Give the current target some stickiness
							local score = screenDistance

							if player == CurrentTarget then
								score -= TARGET_STICKINESS
							end

							if score < bestScore then
								bestScore = score
								bestPlayer = player
								bestPart = part
							end
						end
					end
				end
			end
		end
	end

	return bestPlayer, bestPart
end

--========================================================--
-- ESP
--========================================================--

local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "EnemyESP"
ESP_FOLDER.Parent = workspace

local highlights = {}

local function removeESP(player)
	local highlight = highlights[player]

	if highlight then
		highlight:Destroy()
		highlights[player] = nil
	end
end

local function createESP(player)
	if player == LocalPlayer then
		return
	end

	if not ESP_ENABLED then
		removeESP(player)
		return
	end

	if not isEnemy(player) then
		removeESP(player)
		return
	end

	if not player.Character then
		removeESP(player)
		return
	end

	local highlight = highlights[player]

	if not highlight then
		highlight = Instance.new("Highlight")

		highlight.Name = "EnemyHighlight"

		highlight.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0

		highlight.Parent = ESP_FOLDER

		highlights[player] = highlight
	end

	highlight.Adornee = player.Character

	-- Red enemy appearance
	highlight.FillColor = Color3.fromRGB(255, 60, 60)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

	highlight.Enabled = true
end

local function refreshESP()
	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then
			createESP(player)
		end
	end

	for player in pairs(highlights) do
		if not player.Parent then
			removeESP(player)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)

	if CurrentTarget == player then
		CurrentTarget = nil
	end
end)

--========================================================--
-- GUI
--========================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(240, 150)
Main.Position = UDim2.new(0, 25, 0.5, -75)

Main.BackgroundColor3 =
	Color3.fromRGB(20, 20, 28)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1
Stroke.Transparency = 0.35
Stroke.Parent = Main

--========================================================--
-- TITLE
--========================================================--

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 0, 35)
Title.Position = UDim2.fromOffset(12, 5)

Title.BackgroundTransparency = 1

Title.Text = "AIM ASSIST"
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.new(1, 1, 1)

Title.TextXAlignment = Enum.TextXAlignment.Left

Title.Parent = Main

--========================================================--
-- MINIMIZE
--========================================================--

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(30, 30)
Minimize.Position = UDim2.new(1, -68, 0, 5)

Minimize.BackgroundTransparency = 1
Minimize.Text = "—"

Minimize.TextSize = 24
Minimize.Font = Enum.Font.GothamBold
Minimize.TextColor3 = Color3.new(1, 1, 1)

Minimize.Parent = Main

--========================================================--
-- CLOSE
--========================================================--

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -35, 0, 5)

Close.BackgroundTransparency = 1
Close.Text = "×"

Close.TextSize = 25
Close.Font = Enum.Font.GothamBold
Close.TextColor3 = Color3.fromRGB(255, 90, 90)

Close.Parent = Main

--========================================================--
-- AIM BUTTON
--========================================================--

local AimButton = Instance.new("TextButton")
AimButton.Size = UDim2.new(1, -24, 0, 40)
AimButton.Position = UDim2.fromOffset(12, 45)

AimButton.Font = Enum.Font.GothamBold
AimButton.TextSize = 15

AimButton.TextColor3 = Color3.new(1, 1, 1)

AimButton.Parent = Main

local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius = UDim.new(0, 8)
AimCorner.Parent = AimButton

--========================================================--
-- ESP BUTTON
--========================================================--

local ESPButton = Instance.new("TextButton")
ESPButton.Size = UDim2.new(1, -24, 0, 40)
ESPButton.Position = UDim2.fromOffset(12, 95)

ESPButton.Font = Enum.Font.GothamBold
ESPButton.TextSize = 15

ESPButton.TextColor3 = Color3.new(1, 1, 1)

ESPButton.Parent = Main

local ESPButtonCorner = Instance.new("UICorner")
ESPButtonCorner.CornerRadius = UDim.new(0, 8)
ESPButtonCorner.Parent = ESPButton

--========================================================--
-- BUTTON UPDATE
--========================================================--

local function updateButtons()

	if AIM_ENABLED then
		AimButton.Text = "AIM ASSIST  •  ON"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(45, 150, 85)
	else
		AimButton.Text = "AIM ASSIST  •  OFF"
		AimButton.BackgroundColor3 =
			Color3.fromRGB(60, 60, 70)
	end

	if ESP_ENABLED then
		ESPButton.Text = "ENEMY ESP  •  ON"
		ESPButton.BackgroundColor3 =
			Color3.fromRGB(45, 110, 180)
	else
		ESPButton.Text = "ENEMY ESP  •  OFF"
		ESPButton.BackgroundColor3 =
			Color3.fromRGB(60, 60, 70)
	end
end

updateButtons()

--========================================================--
-- BUTTON EVENTS
--========================================================--

AimButton.MouseButton1Click:Connect(function()
	AIM_ENABLED = not AIM_ENABLED

	if not AIM_ENABLED then
		CurrentTarget = nil
	end

	updateButtons()
end)

ESPButton.MouseButton1Click:Connect(function()
	ESP_ENABLED = not ESP_ENABLED

	if not ESP_ENABLED then
		for player in pairs(highlights) do
			removeESP(player)
		end
	end

	updateButtons()
end)

--========================================================--
-- MINIMIZE
--========================================================--

local minimized = false

Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	AimButton.Visible = not minimized
	ESPButton.Visible = not minimized

	if minimized then
		Main.Size = UDim2.fromOffset(240, 45)
	else
		Main.Size = UDim2.fromOffset(240, 150)
	end
end)

--========================================================--
-- CLOSE
--========================================================--

Close.MouseButton1Click:Connect(function()
	for player in pairs(highlights) do
		removeESP(player)
	end

	ESP_FOLDER:Destroy()
	ScreenGui:Destroy()
end)

--========================================================--
-- DRAGGING
--========================================================--

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
	local delta = input.Position - dragStart

	Main.Position =
		UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
end

Main.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position

		input.Changed:Connect(function()

			if input.UserInputState ==
				Enum.UserInputState.End then

				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if dragging then

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			updateDrag(input)
		end
	end
end)

--========================================================--
-- MAIN AIM LOOP
--========================================================--

local espTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)

	--====================================================--
	-- AIM
	--====================================================--

	if AIM_ENABLED then

		local target, targetPart = getBestTarget()

		if target and targetPart then

			CurrentTarget = target

			local cameraPosition = Camera.CFrame.Position

			local desired =
				CFrame.lookAt(
					cameraPosition,
					targetPart.Position
				)

			Camera.CFrame =
				Camera.CFrame:Lerp(
					desired,
					AIM_STRENGTH
				)

		else
			CurrentTarget = nil
		end
	else
		CurrentTarget = nil
	end

	--====================================================--
	-- ESP
	--====================================================--

	espTimer += deltaTime

	if espTimer >= 0.15 then
		espTimer = 0

		if ESP_ENABLED then
			refreshESP()
		end
	end
end)

--========================================================--
-- RESPAWN / CHARACTER CHANGES
--========================================================--

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.5)

		if ESP_ENABLED then
			createESP(player)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do

	if player ~= LocalPlayer then

		player.CharacterAdded:Connect(function()
			task.wait(0.5)

			if ESP_ENABLED then
				createESP(player)
			end
		end)

	end
end
