--// RIVALS-STYLE AIM ASSIST
--// Place this LocalScript inside:
--// StarterPlayer > StarterPlayerScripts

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local AIM_ENABLED = false

-- Extremely large FOV
local FOV_RADIUS = 1000

-- Extremely large world range
local MAX_AIM_DISTANCE = 2000

-- Lower = faster/more aggressive tracking
local AIM_SMOOTHNESS = 0.12

-- Target preference
local TARGET_HEAD = true

-- Team filtering
local IGNORE_TEAMMATES = true

-- Wall checking
local REQUIRE_LINE_OF_SIGHT = true

--==================================================
-- CHARACTER
--==================================================

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
	task.wait(0.5)
	updateCharacter()
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(300, 190)
Main.Position = UDim2.new(0.5, -150, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(70, 75, 95)
Stroke.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 0, 45)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--==================================================
-- MINIMIZE
--==================================================

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(34, 30)
Minimize.Position = UDim2.new(1, -74, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.BorderSizePixel = 0
Minimize.Parent = Main

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 7)
MinCorner.Parent = Minimize

--==================================================
-- CLOSE
--==================================================

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(34, 30)
Close.Position = UDim2.new(1, -38, 0, 7)
Close.BackgroundColor3 = Color3.fromRGB(80, 35, 42)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 21
Close.Font = Enum.Font.GothamBold
Close.BorderSizePixel = 0
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = Close

--==================================================
-- TOGGLE
--==================================================

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -30, 0, 48)
Toggle.Position = UDim2.fromOffset(15, 55)
Toggle.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
Toggle.BorderSizePixel = 0
Toggle.Text = "AIM ASSIST  •  OFF"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 16
Toggle.Font = Enum.Font.GothamBold
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 9)
ToggleCorner.Parent = Toggle

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -30, 0, 25)
Status.Position = UDim2.fromOffset(15, 110)
Status.BackgroundTransparency = 1
Status.Text = "Target: None"
Status.TextColor3 = Color3.fromRGB(190, 195, 210)
Status.TextSize = 14
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--==================================================
-- INFO
--==================================================

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -30, 0, 35)
Info.Position = UDim2.fromOffset(15, 140)
Info.BackgroundTransparency = 1
Info.Text = "FOV: 1000  •  Range: 2000 studs"
Info.TextColor3 = Color3.fromRGB(130, 135, 155)
Info.TextSize = 12
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.Parent = Main

--==================================================
-- TOGGLE FUNCTION
--==================================================

local function updateToggle()
	if AIM_ENABLED then
		Toggle.Text = "AIM ASSIST  •  ON"
		Toggle.BackgroundColor3 = Color3.fromRGB(45, 100, 70)
	else
		Toggle.Text = "AIM ASSIST  •  OFF"
		Toggle.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
		Status.Text = "Target: None"
	end
end

Toggle.MouseButton1Click:Connect(function()
	AIM_ENABLED = not AIM_ENABLED
	updateToggle()
end)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		Main.Size = UDim2.fromOffset(300, 48)

		Toggle.Visible = false
		Status.Visible = false
		Info.Visible = false

		Minimize.Text = "+"
	else
		Main.Size = UDim2.fromOffset(300, 190)

		Toggle.Visible = true
		Status.Visible = true
		Info.Visible = true

		Minimize.Text = "—"
	end
end)

--==================================================
-- CLOSE
--==================================================

Close.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
	local delta = input.Position - dragStart

	Main.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end

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
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then
		updateDrag(input)
	end
end)

--==================================================
-- TEAM CHECK
--==================================================

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

--==================================================
-- CHARACTER VALIDATION
--==================================================

local function getTargetPart(character)
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	-- Head first
	if TARGET_HEAD then
		local head = character:FindFirstChild("Head")

		if head and head:IsA("BasePart") then
			return head
		end
	end

	-- Torso fallback
	local torso =
		character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")

	if torso and torso:IsA("BasePart") then
		return torso
	end

	return nil
end

--==================================================
-- LINE OF SIGHT
--==================================================

local function hasLineOfSight(targetPart)
	if not REQUIRE_LINE_OF_SIGHT then
		return true
	end

	if not Character then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = targetPart.Position - origin

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

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(targetPart.Parent)
end

--==================================================
-- TARGET FINDING
--==================================================

local function getBestTarget()
	if not Character or not RootPart then
		return nil
	end

	local viewportSize = Camera.ViewportSize

	local screenCenter = Vector2.new(
		viewportSize.X / 2,
		viewportSize.Y / 2
	)

	local bestTarget = nil
	local bestScore = math.huge

	for _, player in ipairs(Players:GetPlayers()) do

		if isEnemy(player) then

			local character = player.Character
			local targetPart = getTargetPart(character)

			if targetPart then

				local distance = (
					targetPart.Position - RootPart.Position
				).Magnitude

				if distance <= MAX_AIM_DISTANCE then

					local screenPosition, onScreen =
						Camera:WorldToViewportPoint(targetPart.Position)

					if onScreen then

						local screenDistance =
							(Vector2.new(
								screenPosition.X,
								screenPosition.Y
							) - screenCenter).Magnitude

						if screenDistance <= FOV_RADIUS then

							if hasLineOfSight(targetPart) then

								-- Distance is slightly considered so
								-- extremely close targets behave correctly.
								local closeBonus = 0

								if distance <= 12 then
									closeBonus = -250
								elseif distance <= 30 then
									closeBonus = -100
								end

								local score =
									screenDistance + closeBonus

								if score < bestScore then
									bestScore = score
									bestTarget = {
										Player = player,
										Part = targetPart,
										Distance = distance
									}
								end
							end
						end
					end
				end
			end
		end
	end

	return bestTarget
end

--==================================================
-- AIM
--==================================================

local currentTarget = nil

local function aimAt(targetPart)
	if not targetPart then
		return
	end

	if not Camera then
		return
	end

	local cameraPosition = Camera.CFrame.Position
	local targetPosition = targetPart.Position

	-- Direct look-at makes close targets reliable.
	local desiredCFrame = CFrame.lookAt(
		cameraPosition,
		targetPosition
	)

	Camera.CFrame = Camera.CFrame:Lerp(
		desiredCFrame,
		AIM_SMOOTHNESS
	)
end

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
	"AimAssist_Render",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		if not AIM_ENABLED then
			currentTarget = nil
			return
		end

		if not Character
			or not Humanoid
			or Humanoid.Health <= 0
			or not RootPart then

			currentTarget = nil
			Status.Text = "Target: None"
			return
		end

		-- Find the best target every frame.
		-- This keeps the system responsive when enemies
		-- move, jump, or suddenly get close.
		currentTarget = getBestTarget()

		if currentTarget
			and currentTarget.Part
			and currentTarget.Part.Parent then

			aimAt(currentTarget.Part)

			Status.Text =
				"Target: "
				.. currentTarget.Player.DisplayName
				.. "  •  "
				.. math.floor(currentTarget.Distance)
				.. " studs"

		else
			Status.Text = "Target: None"
		end
	end
)

--==================================================
-- CLEANUP
--==================================================

ScreenGui.Destroying:Connect(function()
	pcall(function()
		RunService:UnbindFromRenderStep("AimAssist_Render")
	end)
end)

--==================================================
-- INITIAL STATE
--==================================================

updateToggle()
