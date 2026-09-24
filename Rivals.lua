--========================================================
-- RIVALS-STYLE AIM ASSIST
-- Camera / center-crosshair targeting
-- For your own Roblox game
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--========================================================
-- SETTINGS
--========================================================

local ENABLED = false

-- Very large targeting area
local FOV_RADIUS = 1500

-- Very large world range
local MAX_DISTANCE = 3000

-- Camera tracking speed
-- 1 = instant
-- 0.5 = very fast
local AIM_STRENGTH = 0.75

-- Keep the same target when possible
-- This prevents target jumping/jitter
local TARGET_STICKINESS = 250

-- Prefer torso at extremely close range
local CLOSE_RANGE = 18

-- Team filtering
local IGNORE_TEAMMATES = true

-- Don't aim through walls
local WALL_CHECK = true

--========================================================
-- VARIABLES
--========================================================

local Camera = workspace.CurrentCamera
local Character
local Humanoid
local RootPart

local CurrentTarget = nil
local CurrentTargetPart = nil

--========================================================
-- CHARACTER UPDATE
--========================================================

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

	CurrentTarget = nil
	CurrentTargetPart = nil
end)

--========================================================
-- GUI
--========================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SolaceAimAssist"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

--========================================================
-- MAIN FRAME
--========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(310, 185)
Main.Position = UDim2.new(0.5, -155, 0.18, 0)
Main.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
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
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--========================================================
-- MINIMIZE
--========================================================

local Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.Size = UDim2.fromOffset(32, 28)
Minimize.Position = UDim2.new(1, -70, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(38, 41, 52)
Minimize.BorderSizePixel = 0
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
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
Close.BackgroundColor3 = Color3.fromRGB(75, 35, 43)
Close.BorderSizePixel = 0
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = Close

--========================================================
-- TOGGLE
--========================================================

local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Size = UDim2.new(1, -28, 0, 45)
Toggle.Position = UDim2.fromOffset(14, 52)
Toggle.BackgroundColor3 = Color3.fromRGB(43, 46, 58)
Toggle.BorderSizePixel = 0
Toggle.Text = "AIM ASSIST  •  OFF"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 15
Toggle.Font = Enum.Font.GothamBold
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 9)
ToggleCorner.Parent = Toggle

--========================================================
-- TARGET STATUS
--========================================================

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -28, 0, 25)
Status.Position = UDim2.fromOffset(14, 105)
Status.BackgroundTransparency = 1
Status.Text = "Target: None"
Status.TextColor3 = Color3.fromRGB(195, 198, 215)
Status.TextSize = 13
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--========================================================
-- SETTINGS TEXT
--========================================================

local SettingsText = Instance.new("TextLabel")
SettingsText.Name = "Settings"
SettingsText.Size = UDim2.new(1, -28, 0, 35)
SettingsText.Position = UDim2.fromOffset(14, 135)
SettingsText.BackgroundTransparency = 1
SettingsText.Text =
	"FOV 1500  •  RANGE 3000\nClose-range targeting: ON"

SettingsText.TextColor3 = Color3.fromRGB(125, 130, 150)
SettingsText.TextSize = 11
SettingsText.Font = Enum.Font.Gotham
SettingsText.TextXAlignment = Enum.TextXAlignment.Left
SettingsText.Parent = Main

--========================================================
-- UI TOGGLE
--========================================================

local function updateUI()
	if ENABLED then
		Toggle.Text = "AIM ASSIST  •  ON"
		Toggle.BackgroundColor3 = Color3.fromRGB(38, 105, 70)
	else
		Toggle.Text = "AIM ASSIST  •  OFF"
		Toggle.BackgroundColor3 = Color3.fromRGB(43, 46, 58)
		Status.Text = "Target: None"
	end
end

Toggle.MouseButton1Click:Connect(function()
	ENABLED = not ENABLED

	if not ENABLED then
		CurrentTarget = nil
		CurrentTargetPart = nil
	end

	updateUI()
end)

--========================================================
-- MINIMIZE
--========================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		Main.Size = UDim2.fromOffset(310, 47)

		Toggle.Visible = false
		Status.Visible = false
		SettingsText.Visible = false

		Minimize.Text = "+"
	else
		Main.Size = UDim2.fromOffset(310, 185)

		Toggle.Visible = true
		Status.Visible = true
		SettingsText.Visible = true

		Minimize.Text = "—"
	end
end)

--========================================================
-- CLOSE
--========================================================

Close.MouseButton1Click:Connect(function()
	ENABLED = false
	CurrentTarget = nil
	CurrentTargetPart = nil

	pcall(function()
		RunService:UnbindFromRenderStep("SolaceAimAssist")
	end)

	ScreenGui:Destroy()
end)

--========================================================
-- DRAGGING
--========================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position

		input.Changed:Connect(function()

			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end

		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,

			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

--========================================================
-- TEAM CHECK
--========================================================

local function isEnemy(player)

	if player == LocalPlayer then
		return false
	end

	if IGNORE_TEAMMATES then

		if LocalPlayer.Team ~= nil
			and player.Team ~= nil
			and LocalPlayer.Team == player.Team then

			return false
		end
	end

	return true
end

--========================================================
-- ALIVE CHECK
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
-- GET AIM PART
--
-- IMPORTANT:
-- At normal/long range:
--     Head is preferred.
--
-- At extremely close range:
--     UpperTorso/Torso is preferred.
--
-- This prevents the camera from behaving badly when
-- somebody is practically standing inside the player.
--========================================================

local function getAimPart(player)

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid = getHumanoid(character)

	if not humanoid then
		return nil
	end

	local targetRoot =
		character:FindFirstChild("HumanoidRootPart")

	if not targetRoot then
		return nil
	end

	local myRoot = RootPart

	if not myRoot then
		return nil
	end

	local distance =
		(targetRoot.Position - myRoot.Position).Magnitude

	-- CLOSE RANGE
	if distance <= CLOSE_RANGE then

		local torso =
			character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")

		if torso and torso:IsA("BasePart") then
			return torso
		end

		return targetRoot
	end

	-- NORMAL RANGE
	local head = character:FindFirstChild("Head")

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
-- VISIBILITY CHECK
--========================================================

local function canSee(part)

	if not WALL_CHECK then
		return true
	end

	if not Camera then
		return false
	end

	if not Character then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()

	params.FilterType = Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		Character,
		Camera
	}

	params.IgnoreWater = true

	local result = workspace:Raycast(
		origin,
		direction,
		params
	)

	if result == nil then
		return true
	end

	return result.Instance:IsDescendantOf(part.Parent)
end

--========================================================
-- SCREEN DISTANCE
--========================================================

local function getScreenDistance(part)

	local viewport = Camera.ViewportSize

	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local screenPosition, visible =
		Camera:WorldToViewportPoint(part.Position)

	if not visible then
		return math.huge
	end

	local screenPoint = Vector2.new(
		screenPosition.X,
		screenPosition.Y
	)

	return (screenPoint - center).Magnitude
end

--========================================================
-- TARGET SCORE
--========================================================

local function getTargetScore(player, part)

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

	local targetRoot =
		player.Character
		and player.Character:FindFirstChild("HumanoidRootPart")

	if not targetRoot then
		return math.huge
	end

	local worldDistance =
		(targetRoot.Position - RootPart.Position).Magnitude

	if worldDistance > MAX_DISTANCE then
		return math.huge
	end

	if not canSee(part) then
		return math.huge
	end

	-- Lower score = better target
	local score = screenDistance

	-- Strong preference for extremely close enemies
	if worldDistance <= CLOSE_RANGE then
		score -= 500
	elseif worldDistance <= 40 then
		score -= 150
	end

	-- Keep current target stable
	if player == CurrentTarget then
		score -= TARGET_STICKINESS
	end

	return score
end

--========================================================
-- FIND BEST TARGET
--========================================================

local function findBestTarget()

	if not Character or not RootPart then
		return nil, nil
	end

	local bestPlayer = nil
	local bestPart = nil
	local bestScore = math.huge

	for _, player in ipairs(Players:GetPlayers()) do

		if isEnemy(player) then

			local part = getAimPart(player)

			if part then

				local score =
					getTargetScore(player, part)

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
-- AIM CAMERA
--========================================================

local function aimAt(part)

	if not part then
		return
	end

	if not Camera then
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

	-- Preserve camera position.
	-- Only rotate the camera toward the target.
	local desired =
		CFrame.lookAt(
			cameraPosition,
			targetPosition
		)

	-- Very aggressive tracking
	Camera.CFrame =
		Camera.CFrame:Lerp(
			desired,
			AIM_STRENGTH
		)
end

--========================================================
-- MAIN AIM LOOP
--========================================================

RunService:BindToRenderStep(
	"SolaceAimAssist",
	Enum.RenderPriority.Camera.Value + 100,
	function()

		if not ENABLED then
			return
		end

		Camera = workspace.CurrentCamera

		if not Camera then
			return
		end

		if not Character
			or not Humanoid
			or Humanoid.Health <= 0
			or not RootPart then

			CurrentTarget = nil
			CurrentTargetPart = nil

			Status.Text = "Target: None"

			return
		end

		-- Find target
		local newTarget, newPart =
			findBestTarget()

		CurrentTarget = newTarget
		CurrentTargetPart = newPart

		-- Aim
		if CurrentTarget
			and CurrentTargetPart then

			-- Re-check that target is still alive
			local targetHumanoid =
				CurrentTarget.Character
				and CurrentTarget.Character:
					FindFirstChildOfClass("Humanoid")

			if targetHumanoid
				and targetHumanoid.Health > 0 then

				aimAt(CurrentTargetPart)

				local targetRoot =
					CurrentTarget.Character:
					FindFirstChild("HumanoidRootPart")

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
					.. math.floor(distance)
					.. " studs"

			else

				CurrentTarget = nil
				CurrentTargetPart = nil
				Status.Text = "Target: None"

			end

		else

			Status.Text = "Target: None"

		end
	end
)

--========================================================
-- INITIALIZE
--========================================================

updateUI()
