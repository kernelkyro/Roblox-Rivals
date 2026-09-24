--========================================================
-- RIVALS-STYLE AIM ASSIST + ENEMY ESP
-- YOUR OWN ROBLOX GAME
--
-- Place in:
-- StarterPlayer
--   └─ StarterPlayerScripts
--      └─ AimAssist (LocalScript)
--========================================================

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--========================================================
-- SETTINGS
--========================================================

local AIM_ENABLED = false
local ESP_ENABLED = false

-- Aim area
local FOV_RADIUS = 1500

-- World range
local MAX_AIM_DISTANCE = 3000

-- Original normal aim strength
local AIM_STRENGTH = 0.75

-- Scoped / sniper aim strength
local SCOPED_AIM_STRENGTH = 0.92

-- FOV at or below this means the camera is zoomed/scoped
local SCOPE_FOV_THRESHOLD = 45

-- Long-range aiming
local LONG_RANGE_DISTANCE = 150
local LONG_RANGE_STRENGTH = 0.84

-- Target switching
local TARGET_STICKINESS = 250

-- Close range
local CLOSE_RANGE = 18

-- Teammates are never targeted/highlighted
local IGNORE_TEAMMATES = true

-- Don't aim through walls
local AIM_WALL_CHECK = true

-- ESP
local ESP_FILL_TRANSPARENCY = 0.72
local ESP_OUTLINE_TRANSPARENCY = 0

--========================================================
-- CHARACTER
--========================================================

local Character
local Humanoid
local RootPart

local function updateCharacter()

	Character = LocalPlayer.Character

	if not Character then
		Humanoid = nil
		RootPart = nil
		return
	end

	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	RootPart = Character:FindFirstChild("HumanoidRootPart")
end

updateCharacter()

LocalPlayer.CharacterAdded:Connect(function()

	task.wait(0.25)

	updateCharacter()

end)

--========================================================
-- GUI
--========================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

--========================================================
-- MAIN
--========================================================

local Main = Instance.new("Frame")

Main.Name = "Main"
Main.Size = UDim2.fromOffset(315, 250)
Main.Position = UDim2.new(0.5, -157, 0.18, 0)

Main.BackgroundColor3 =
	Color3.fromRGB(17, 19, 27)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(75, 80, 100)
MainStroke.Parent = Main

--========================================================
-- TITLE
--========================================================

local Title = Instance.new("TextLabel")

Title.Name = "Title"
Title.Size = UDim2.new(1, -90, 0, 42)
Title.Position = UDim2.fromOffset(14, 0)

Title.BackgroundTransparency = 1

Title.Text = "AIM ASSIST"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent = Main

--========================================================
-- MINIMIZE
--========================================================

local Minimize = Instance.new("TextButton")

Minimize.Name = "Minimize"
Minimize.Size = UDim2.fromOffset(32, 28)
Minimize.Position = UDim2.new(1, -70, 0, 7)

Minimize.BackgroundColor3 =
	Color3.fromRGB(38, 41, 52)

Minimize.BorderSizePixel = 0

Minimize.Text = "—"
Minimize.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold

Minimize.Parent = Main

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 7)
MinCorner.Parent = Minimize

--========================================================
-- CLOSE
--========================================================

local Close = Instance.new("TextButton")

Close.Name = "Close"
Close.Size = UDim2.fromOffset(32, 28)
Close.Position = UDim2.new(1, -34, 0, 7)

Close.BackgroundColor3 =
	Color3.fromRGB(75, 35, 43)

Close.BorderSizePixel = 0

Close.Text = "×"
Close.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Close.TextSize = 20
Close.Font = Enum.Font.GothamBold

Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = Close

--========================================================
-- AIM TOGGLE
--========================================================

local AimToggle = Instance.new("TextButton")

AimToggle.Name = "AimToggle"
AimToggle.Size = UDim2.new(1, -28, 0, 43)
AimToggle.Position = UDim2.fromOffset(14, 50)

AimToggle.BackgroundColor3 =
	Color3.fromRGB(43, 46, 58)

AimToggle.BorderSizePixel = 0

AimToggle.Text = "AIM ASSIST  •  OFF"

AimToggle.TextColor3 =
	Color3.fromRGB(255, 255, 255)

AimToggle.TextSize = 15
AimToggle.Font = Enum.Font.GothamBold

AimToggle.Parent = Main

local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius = UDim.new(0, 9)
AimCorner.Parent = AimToggle

--========================================================
-- ESP TOGGLE
--========================================================

local ESPToggle = Instance.new("TextButton")

ESPToggle.Name = "ESPToggle"
ESPToggle.Size = UDim2.new(1, -28, 0, 43)
ESPToggle.Position = UDim2.fromOffset(14, 99)

ESPToggle.BackgroundColor3 =
	Color3.fromRGB(43, 46, 58)

ESPToggle.BorderSizePixel = 0

ESPToggle.Text = "ENEMY ESP  •  OFF"

ESPToggle.TextColor3 =
	Color3.fromRGB(255, 255, 255)

ESPToggle.TextSize = 15
ESPToggle.Font = Enum.Font.GothamBold

ESPToggle.Parent = Main

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 9)
ESPCorner.Parent = ESPToggle

--========================================================
-- STATUS
--========================================================

local Status = Instance.new("TextLabel")

Status.Name = "Status"
Status.Size = UDim2.new(1, -28, 0, 24)
Status.Position = UDim2.fromOffset(14, 151)

Status.BackgroundTransparency = 1

Status.Text = "Target: None"

Status.TextColor3 =
	Color3.fromRGB(195, 198, 215)

Status.TextSize = 13
Status.Font = Enum.Font.Gotham

Status.TextXAlignment =
	Enum.TextXAlignment.Left

Status.Parent = Main

--========================================================
-- SETTINGS TEXT
--========================================================

local SettingsText = Instance.new("TextLabel")

SettingsText.Name = "Settings"
SettingsText.Size = UDim2.new(1, -28, 0, 45)
SettingsText.Position = UDim2.fromOffset(14, 181)

SettingsText.BackgroundTransparency = 1

SettingsText.Text =
	"FOV 1500  •  RANGE 3000\nEnemy-only targeting + ESP"

SettingsText.TextColor3 =
	Color3.fromRGB(125, 130, 150)

SettingsText.TextSize = 11
SettingsText.Font = Enum.Font.Gotham

SettingsText.TextXAlignment =
	Enum.TextXAlignment.Left

SettingsText.Parent = Main

--========================================================
-- UI STATE
--========================================================

local function updateAimUI()

	if AIM_ENABLED then

		AimToggle.Text =
			"AIM ASSIST  •  ON"

		AimToggle.BackgroundColor3 =
			Color3.fromRGB(38, 105, 70)

	else

		AimToggle.Text =
			"AIM ASSIST  •  OFF"

		AimToggle.BackgroundColor3 =
			Color3.fromRGB(43, 46, 58)

	end

end

local function updateESPUI()

	if ESP_ENABLED then

		ESPToggle.Text =
			"ENEMY ESP  •  ON"

		ESPToggle.BackgroundColor3 =
			Color3.fromRGB(38, 105, 70)

	else

		ESPToggle.Text =
			"ENEMY ESP  •  OFF"

		ESPToggle.BackgroundColor3 =
			Color3.fromRGB(43, 46, 58)

	end

end

--========================================================
-- AIM TOGGLE
--========================================================

AimToggle.MouseButton1Click:Connect(function()

	AIM_ENABLED = not AIM_ENABLED

	if not AIM_ENABLED then

		CurrentTarget = nil
		CurrentTargetPart = nil

		Status.Text = "Target: None"

	end

	updateAimUI()

end)

--========================================================
-- ESP TOGGLE
--========================================================

ESPToggle.MouseButton1Click:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	updateESPUI()

end)

--========================================================
-- MINIMIZE
--========================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()

	minimized = not minimized

	if minimized then

		Main.Size =
			UDim2.fromOffset(315, 47)

		AimToggle.Visible = false
		ESPToggle.Visible = false
		Status.Visible = false
		SettingsText.Visible = false

		Minimize.Text = "+"

	else

		Main.Size =
			UDim2.fromOffset(315, 250)

		AimToggle.Visible = true
		ESPToggle.Visible = true
		Status.Visible = true
		SettingsText.Visible = true

		Minimize.Text = "—"

	end

end)

--========================================================
-- DRAGGING
--========================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1

		or input.UserInputType ==
		Enum.UserInputType.Touch then

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

	if not dragging then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement

		or input.UserInputType ==
		Enum.UserInputType.Touch then

		local delta =
			input.Position - dragStart

		Main.Position =
			UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,

				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

	end

end)

--========================================================
-- TARGET VARIABLES
--========================================================

local CurrentTarget = nil
local CurrentTargetPart = nil

--========================================================
-- TEAM CHECK
--========================================================

local function isEnemy(player)

	if not player then
		return false
	end

	if player == LocalPlayer then
		return false
	end

	if not IGNORE_TEAMMATES then
		return true
	end

	--====================================================
	-- NORMAL ROBLOX TEAM SYSTEM
	--====================================================

	local myTeam = LocalPlayer.Team
	local theirTeam = player.Team

	if myTeam ~= nil and theirTeam ~= nil then

		-- Same Team object = teammate
		if myTeam == theirTeam then
			return false
		end

		-- Different Team objects = enemy
		return true
	end

	--====================================================
	-- TEAM COLOR FALLBACK
	--====================================================

	local myTeamColor = LocalPlayer.TeamColor
	local theirTeamColor = player.TeamColor

	if myTeamColor ~= nil
		and theirTeamColor ~= nil then

		if myTeamColor == theirTeamColor then
			return false
		end

		return true
	end

	--====================================================
	-- UNKNOWN TEAM
	--
	-- IMPORTANT:
	-- We do NOT automatically call unknown players
	-- enemies anymore.
	--====================================================

	return false
end

--========================================================
-- TARGET HUMANOID
--========================================================

local function getHumanoid(character)

	if not character then
		return nil
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return nil
	end

	if humanoid.Health <= 0 then
		return nil
	end

	return humanoid
end

--========================================================
-- AIM PART
--========================================================

local function getAimPart(player)

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid =
		getHumanoid(character)

	if not humanoid then
		return nil
	end

	local targetRoot =
		character:FindFirstChild("HumanoidRootPart")

	if not targetRoot then
		return nil
	end

	if not RootPart then
		return nil
	end

	local distance =
		(targetRoot.Position - RootPart.Position).Magnitude

	--====================================================
	-- CLOSE RANGE
	--====================================================

	if distance <= CLOSE_RANGE then

		local torso =
			character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")

		if torso and torso:IsA("BasePart") then
			return torso
		end

		return targetRoot
	end

	--====================================================
	-- NORMAL / LONG RANGE
	--====================================================

	local head =
		character:FindFirstChild("Head")

	if head and head:IsA("BasePart") then
		return head
	end

	local torso =
		character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")

	if torso and torso:IsA("BasePart") then
		return torso
	end

	return targetRoot
end

--========================================================
-- WALL CHECK
--========================================================

local function canSee(part)

	if not AIM_WALL_CHECK then
		return true
	end

	if not Character or not Camera then
		return false
	end

	local origin =
		Camera.CFrame.Position

	local direction =
		part.Position - origin

	local params =
		RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		Character,
		Camera
	}

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

	return result.Instance:IsDescendantOf(
		part.Parent
	)
end

--========================================================
-- SCREEN DISTANCE
--========================================================

local function getScreenDistance(part)

	if not Camera then
		return math.huge
	end

	local viewport =
		Camera.ViewportSize

	local screenCenter =
		Vector2.new(
			viewport.X / 2,
			viewport.Y / 2
		)

	local screenPosition, visible =
		Camera:WorldToViewportPoint(
			part.Position
		)

	if not visible then
		return math.huge
	end

	local point =
		Vector2.new(
			screenPosition.X,
			screenPosition.Y
		)

	return (point - screenCenter).Magnitude
end

--========================================================
-- TARGET SCORE
--========================================================

local function getTargetScore(player, part)

	if not isEnemy(player) then
		return math.huge
	end

	local screenDistance =
		getScreenDistance(part)

	if screenDistance == math.huge then
		return math.huge
	end

	if screenDistance > FOV_RADIUS then
		return math.huge
	end

	if not RootPart then
		return math.huge
	end

	local character =
		player.Character

	if not character then
		return math.huge
	end

	local targetRoot =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not targetRoot then
		return math.huge
	end

	local distance =
		(targetRoot.Position - RootPart.Position).Magnitude

	if distance > MAX_AIM_DISTANCE then
		return math.huge
	end

	if not canSee(part) then
		return math.huge
	end

	--====================================================
	-- BASE SCORE
	--====================================================

	local score = screenDistance

	--====================================================
	-- LONG RANGE PRECISION
	--====================================================

	if distance >= LONG_RANGE_DISTANCE then
		score *= 0.85
	end

	--====================================================
	-- CLOSE RANGE PRIORITY
	--====================================================

	if distance <= CLOSE_RANGE then

		score -= 500

	elseif distance <= 40 then

		score -= 150

	end

	--====================================================
	-- TARGET STICKINESS
	--====================================================

	if player == CurrentTarget then
		score -= TARGET_STICKINESS
	end

	return score
end

--========================================================
-- FIND TARGET
--========================================================

local function findBestTarget()

	if not Character or not RootPart then
		return nil, nil
	end

	local bestPlayer = nil
	local bestPart = nil
	local bestScore = math.huge

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		-- Teammates are filtered here
		-- before any target selection happens.

		if isEnemy(player) then

			local part =
				getAimPart(player)

			if part then

				local score =
					getTargetScore(
						player,
						part
					)

				if score < bestScore then

					bestScore = score
					bestPlayer = player
					bestPart = part

				end

			end

		end

	end

	return bestPlayer, bestPart
end

--========================================================
-- AIM
--========================================================

local function aimAt(part)

	if not part or not Camera then
		return
	end

	local cameraPosition =
		Camera.CFrame.Position

	local targetPosition =
		part.Position

	local direction =
		targetPosition - cameraPosition

	if direction.Magnitude < 0.05 then
		return
	end

	local desired =
		CFrame.lookAt(
			cameraPosition,
			targetPosition
		)

	--====================================================
	-- DEFAULT
	--====================================================

	local strength =
		AIM_STRENGTH

	--====================================================
	-- SNIPER / SCOPED
	--====================================================

	if Camera.FieldOfView <=
		SCOPE_FOV_THRESHOLD then

		strength =
			SCOPED_AIM_STRENGTH

	--====================================================
	-- LONG RANGE
	--====================================================

	elseif direction.Magnitude >=
		LONG_RANGE_DISTANCE then

		strength =
			LONG_RANGE_STRENGTH

	end

	Camera.CFrame =
		Camera.CFrame:Lerp(
			desired,
			strength
		)
end

--========================================================
-- ESP STORAGE
--========================================================

local ESPFolder =
	Instance.new("Folder")

ESPFolder.Name = "EnemyESP"

ESPFolder.Parent = ScreenGui

local ESPObjects = {}

--========================================================
-- CREATE ESP
--========================================================

local function createESP(player)

	if player == LocalPlayer then
		return
	end

	if not isEnemy(player) then
		return
	end

	local character =
		player.Character

	if not character then
		return
	end

	if ESPObjects[player] then
		return
	end

	local highlight =
		Instance.new("Highlight")

	highlight.Name =
		"EnemyHighlight"

	highlight.Adornee =
		character

	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.FillColor =
		Color3.fromRGB(
			255,
			55,
			65
		)

	highlight.OutlineColor =
		Color3.fromRGB(
			255,
			255,
			255
		)

	highlight.FillTransparency =
		ESP_FILL_TRANSPARENCY

	highlight.OutlineTransparency =
		ESP_OUTLINE_TRANSPARENCY

	highlight.Enabled =
		ESP_ENABLED

	highlight.Parent =
		ESPFolder

	ESPObjects[player] =
		highlight
end

--========================================================
-- REMOVE ESP
--========================================================

local function removeESP(player)

	local highlight =
		ESPObjects[player]

	if highlight then

		highlight:Destroy()

		ESPObjects[player] =
			nil

	end

end

--========================================================
-- REFRESH ESP
--========================================================

local function refreshESP()

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then

			if ESP_ENABLED
				and isEnemy(player) then

				local character =
					player.Character

				if character then

					local existing =
						ESPObjects[player]

					if not existing then

						createESP(player)

					else

						existing.Adornee =
							character

						existing.Enabled =
							true

					end

				end

			else

				local existing =
					ESPObjects[player]

				if existing then
					existing.Enabled = false
				end

			end

		end

	end
end

--========================================================
-- PLAYER CONNECTIONS
--========================================================

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()

		task.wait(0.15)

		removeESP(player)

		if ESP_ENABLED
			and isEnemy(player) then

			createESP(player)

		end

	end)

	player.CharacterRemoving:Connect(function()

		removeESP(player)

	end)

end

for _, player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(player)

end

Players.PlayerAdded:Connect(function(player)

	setupPlayer(player)

end)

Players.PlayerRemoving:Connect(function(player)

	removeESP(player)

	if CurrentTarget == player then

		CurrentTarget = nil
		CurrentTargetPart = nil

	end

end)

--========================================================
-- MAIN LOOP
--========================================================

RunService:BindToRenderStep(
	"AimAssistMain",
	Enum.RenderPriority.Camera.Value + 100,
	function()

		Camera =
			workspace.CurrentCamera

		if not Camera then
			return
		end

		--==================================================
		-- AIM
		--==================================================

		if AIM_ENABLED then

			if not Character
				or not Humanoid
				or Humanoid.Health <= 0
				or not RootPart then

				CurrentTarget = nil
				CurrentTargetPart = nil

				Status.Text =
					"Target: None"

			else

				local newTarget,
					newPart =
					findBestTarget()

				CurrentTarget =
					newTarget

				CurrentTargetPart =
					newPart

				if CurrentTarget
					and CurrentTargetPart
					and isEnemy(
						CurrentTarget
					) then

					local targetCharacter =
						CurrentTarget.Character

					local targetHumanoid =
						targetCharacter
						and targetCharacter:
							FindFirstChildOfClass(
								"Humanoid"
							)

					if targetHumanoid
						and targetHumanoid.Health > 0 then

						aimAt(
							CurrentTargetPart
						)

						local targetRoot =
							targetCharacter:
								FindFirstChild(
									"HumanoidRootPart"
								)

						local distance = 0

						if targetRoot then

							distance =
								(
									targetRoot.Position
									- RootPart.Position
								).Magnitude

						end

						Status.Text =
							"Target: "
							.. CurrentTarget.DisplayName
							.. "  •  "
							.. math.floor(
								distance
							)
							.. " studs"

					else

						CurrentTarget = nil
						CurrentTargetPart = nil

						Status.Text =
							"Target: None"

					end

				else

					CurrentTarget = nil
					CurrentTargetPart = nil

					Status.Text =
						"Target: None"

				end

			end

		else

			CurrentTarget = nil
			CurrentTargetPart = nil

			Status.Text =
				"Target: None"

		end

		--==================================================
		-- ESP
		--==================================================

		refreshESP()

	end
)

--========================================================
-- INITIAL STATE
--========================================================

updateAimUI()
updateESPUI()
