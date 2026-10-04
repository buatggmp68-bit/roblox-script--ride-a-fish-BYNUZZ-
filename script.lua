--==================================================
-- EGG ESP + TP WALK
-- FPS OPTIMIZED / 1 FILE
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local MAX_DISTANCE = 5000

local MIN_TPWALK = 1
local MAX_TPWALK = 500
local DEFAULT_TPWALK = 50

--==================================================
-- EGG LIST
--==================================================

local TARGET_EGGS = {
	["Sovereign Egg"] = Color3.fromRGB(120, 190, 150),
	["Celestial Egg"] = Color3.fromRGB(170, 80, 255),
	["Eternal Egg"] = Color3.fromRGB(255, 60, 60),
	["Coral Reef Egg"] = Color3.fromRGB(0, 220, 255),
	["Glacial Spiral Egg"] = Color3.fromRGB(100, 255, 255),
	["Amethyst Spiral Egg"] = Color3.fromRGB(255, 80, 220),
	["Azure Crown Egg"] = Color3.fromRGB(40, 100, 255),
	["Solar Orbit Egg"] = Color3.fromRGB(255, 180, 0),
}

local EGG_ORDER = {
	"Sovereign Egg",
	"Celestial Egg",
	"Eternal Egg",
	"Coral Reef Egg",
	"Glacial Spiral Egg",
	"Amethyst Spiral Egg",
	"Azure Crown Egg",
	"Solar Orbit Egg",
}

local ALIASES = {
	["Sovereign Egg"] = {"sovereign"},
	["Celestial Egg"] = {"celestial"},
	["Eternal Egg"] = {"eternal"},
	["Coral Reef Egg"] = {"coralreef", "reefegg"},
	["Glacial Spiral Egg"] = {"glacialspiral"},
	["Amethyst Spiral Egg"] = {"amethystspiral"},
	["Azure Crown Egg"] = {"azurecrown"},
	["Solar Orbit Egg"] = {"solarorbit"},
}

--==================================================
-- SETTINGS
--==================================================

local selected = {}

for eggName in pairs(TARGET_EGGS) do
	selected[eggName] = false
end

local espEnabled = true

local tpWalkEnabled = false
local tpWalkValue = DEFAULT_TPWALK

local tracked = {}
local eggModels = {}

--==================================================
-- NORMALIZE
--==================================================

local function normalize(value)
	return tostring(value)
		:lower()
		:gsub("%s+", "")
		:gsub("[_%-%[%]%(%)%.]", "")
end

--==================================================
-- ALIAS CHECK
--==================================================

local function getAliasEggName(name)

	local text = normalize(name)

	for eggName, aliases in pairs(ALIASES) do

		for _, alias in ipairs(aliases) do

			if string.find(
				text,
				normalize(alias),
				1,
				true
			) then
				return eggName
			end
		end
	end

	return nil
end

--==================================================
-- FIND EGG MODEL
--==================================================

local function findEggModel(obj)

	local current = obj

	while current and current ~= Workspace do

		if current:IsA("Model") then

			if current:FindFirstChild("EggRoot")
				or current:FindFirstChild("EggHatchInteraction") then

				return current
			end

			local aliasName =
				getAliasEggName(current.Name)

			if aliasName then
				return current
			end
		end

		current = current.Parent
	end

	return nil
end

--==================================================
-- GET EGG NAME
--==================================================

local function getEggName(egg)

	local direct =
		getAliasEggName(egg.Name)

	if direct then
		return direct
	end

	local current = egg

	for _ = 1, 5 do

		if not current then
			break
		end

		local result =
			getAliasEggName(current.Name)

		if result then
			return result
		end

		current = current.Parent
	end

	local root =
		egg:FindFirstChild("EggRoot")

	if root then

		local result =
			getAliasEggName(root.Name)

		if result then
			return result
		end
	end

	return nil
end

--==================================================
-- GET EGG PART
--==================================================

local function getEggPart(egg)

	local root =
		egg:FindFirstChild("EggRoot")

	if root and root:IsA("BasePart") then
		return root
	end

	if egg.PrimaryPart then
		return egg.PrimaryPart
	end

	for _, child in ipairs(egg:GetChildren()) do

		if child:IsA("BasePart") then
			return child
		end
	end

	return nil
end

--==================================================
-- REGISTER EGG
--==================================================

local function registerEgg(egg)

	if not egg or not egg:IsA("Model") then
		return
	end

	if eggModels[egg] then
		return
	end

	local eggName =
		getEggName(egg)

	if not eggName then
		return
	end

	if not TARGET_EGGS[eggName] then
		return
	end

	eggModels[egg] = eggName
end

--==================================================
-- CREATE ESP
--==================================================

local function createESP(egg)

	if tracked[egg] then
		return
	end

	local eggName =
		eggModels[egg]

	if not eggName then
		return
	end

	if not selected[eggName] then
		return
	end

	local part =
		getEggPart(egg)

	if not part then
		return
	end

	local gui =
		Instance.new("BillboardGui")

	gui.Name = "EggESP"
	gui.Size =
		UDim2.fromOffset(150, 28)

	gui.StudsOffset =
		Vector3.new(0, 2.5, 0)

	gui.AlwaysOnTop = true
	gui.MaxDistance = MAX_DISTANCE
	gui.Adornee = part
	gui.Parent = part

	local label =
		Instance.new("TextLabel")

	label.Name = "EggName"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11

	label.Text = eggName

	label.TextColor3 =
		TARGET_EGGS[eggName]

	label.TextStrokeTransparency = 0.45
	label.Parent = gui

	tracked[egg] = {
		gui = gui,
		label = label,
		part = part,
		eggName = eggName,
	}
end

--==================================================
-- REMOVE ESP
--==================================================

local function removeESP(egg)

	local data =
		tracked[egg]

	if not data then
		return
	end

	if data.gui then
		data.gui:Destroy()
	end

	tracked[egg] = nil
end

local function removeAllESP()

	for egg in pairs(tracked) do
		removeESP(egg)
	end
end

--==================================================
-- INITIAL SCAN
--==================================================

local function initialScan()

	for _, obj in ipairs(
		Workspace:GetDescendants()
	) do

		if obj:IsA("Model") then

			if obj:FindFirstChild("EggRoot")
				or obj:FindFirstChild("EggHatchInteraction")
				or getAliasEggName(obj.Name) then

				registerEgg(obj)
			end
		end
	end
end

--==================================================
-- NEW OBJECT DETECTOR
--==================================================

Workspace.DescendantAdded:Connect(function(obj)

	if obj:IsA("Model") then

		if obj:FindFirstChild("EggRoot")
			or obj:FindFirstChild("EggHatchInteraction")
			or getAliasEggName(obj.Name) then

			task.defer(function()

				registerEgg(obj)

				if espEnabled then
					createESP(obj)
				end
			end)
		end

		return
	end

	if obj.Name == "EggRoot"
		or obj.Name == "EggHatchInteraction" then

		task.defer(function()

			local egg =
				findEggModel(obj)

			if egg then

				registerEgg(egg)

				if espEnabled then
					createESP(egg)
				end
			end
		end)
	end
end)

--==================================================
-- PERIODIC LIGHT UPDATE
--==================================================

task.spawn(function()

	while task.wait(0.5) do

		for egg, eggName in pairs(eggModels) do

			if not egg:IsDescendantOf(Workspace) then

				eggModels[egg] = nil
				removeESP(egg)

				continue
			end

			if selected[eggName]
				and espEnabled then

				if not tracked[egg] then
					createESP(egg)
				end

			else

				if tracked[egg] then
					removeESP(egg)
				end
			end
		end
	end
end)

--==================================================
-- ESP CARRIER UPDATE
--==================================================

task.spawn(function()

	while task.wait(0.15) do

		for egg, data in pairs(tracked) do

			if not egg:IsDescendantOf(Workspace) then

				removeESP(egg)
				continue
			end

			local part =
				getEggPart(egg)

			if part and part ~= data.part then

				data.part = part
				data.gui.Adornee = part
				data.gui.Parent = part
			end

			local current = egg

			local carrier = nil
			local carrierRoot = nil

			while current
				and current ~= Workspace do

				local parent =
					current.Parent

				if parent
					and parent:IsA("Model") then

					local humanoid =
						parent:FindFirstChildOfClass(
							"Humanoid"
						)

					local root =
						parent:FindFirstChild(
							"HumanoidRootPart"
						)

					if humanoid and root then

						local player =
							Players:GetPlayerFromCharacter(
								parent
							)

						if player then
							carrier = player
							carrierRoot = root
							break
						end
					end
				end

				current =
					current.Parent
			end

			if carrier == LocalPlayer then

				data.gui.Enabled = false

			elseif carrier and carrierRoot then

				data.gui.Enabled = true
				data.gui.Adornee = carrierRoot

				data.label.Text =
					data.eggName ..
					" [" ..
					carrier.Name ..
					"]"

			else

				data.gui.Enabled = true
				data.gui.Adornee = data.part
				data.label.Text =
					data.eggName
			end
		end
	end
end)

--==================================================
-- TP WALK
--==================================================

local tpConnection = nil

local function getCharacterRoot(character)

	if not character then
		return nil
	end

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if root then
		return root
	end

	if character:IsA("Model")
		and character.PrimaryPart then

		return character.PrimaryPart
	end

	return nil
end

local function stopTPWalk()

	if tpConnection then

		tpConnection:Disconnect()
		tpConnection = nil
	end
end

local function startTPWalk()

	stopTPWalk()

	if not tpWalkEnabled then
		return
	end

	local lastTime = os.clock()

	tpConnection =
		RunService.Heartbeat:Connect(function()

			if not tpWalkEnabled then
				return
			end

			local character =
				LocalPlayer.Character

			if not character then
				return
			end

			local humanoid =
				character:FindFirstChildOfClass(
					"Humanoid"
				)

			if not humanoid then
				return
			end

			if humanoid.Health <= 0 then
				return
			end

			local root =
				getCharacterRoot(character)

			if not root then
				return
			end

			local now = os.clock()

			local delta =
				now - lastTime

			lastTime = now

			-- Hindari lonjakan kalau FPS drop
			if delta > 0.1 then
				delta = 0.1
			end

			if delta <= 0 then
				return
			end

			local direction =
				humanoid.MoveDirection

			if direction.Magnitude <= 0.01 then
				return
			end

			local distance =
				tpWalkValue * delta

			local movement =
				direction.Unit * distance

			-- TP STEP
			character:PivotTo(
				character:GetPivot() +
				movement
			)
		end)
end

--==================================================
-- CHARACTER RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)

	task.wait(0.5)

	if tpWalkEnabled then
		startTPWalk()
	end
end)

--==================================================
-- GUI
--==================================================

local screenGui =
	Instance.new("ScreenGui")

screenGui.Name =
	"EggESP_Control"

screenGui.ResetOnSpawn = false

screenGui.Parent =
	LocalPlayer:WaitForChild(
		"PlayerGui"
	)

--==================================================
-- OPEN BUTTON
--==================================================

local openButton =
	Instance.new("TextButton")

openButton.Size =
	UDim2.fromOffset(55, 28)

openButton.Position =
	UDim2.new(0, 10, 0.5, -14)

openButton.BackgroundColor3 =
	Color3.fromRGB(30, 30, 30)

openButton.TextColor3 =
	Color3.new(1, 1, 1)

openButton.Text = "EGG"

openButton.Font =
	Enum.Font.GothamBold

openButton.TextSize = 12

openButton.Parent =
	screenGui

Instance.new(
	"UICorner",
	openButton
).CornerRadius =
	UDim.new(0, 6)

--==================================================
-- PANEL
--==================================================

local panel =
	Instance.new("Frame")

panel.Size =
	UDim2.fromOffset(620, 180)

panel.Position =
	UDim2.new(0.5, -310, 0.5, -90)

panel.BackgroundColor3 =
	Color3.fromRGB(25, 25, 25)

panel.Parent =
	screenGui

Instance.new(
	"UICorner",
	panel
).CornerRadius =
	UDim.new(0, 8)

--==================================================
-- TITLE
--==================================================

local title =
	Instance.new("TextLabel")

title.Size =
	UDim2.fromOffset(120, 25)

title.Position =
	UDim2.fromOffset(10, 5)

title.BackgroundTransparency = 1

title.Text = "EGG ESP"

title.TextColor3 =
	Color3.new(1, 1, 1)

title.Font =
	Enum.Font.GothamBold

title.TextSize = 14

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent = panel

--==================================================
-- ESP BUTTON
--==================================================

local espButton =
	Instance.new("TextButton")

espButton.Size =
	UDim2.fromOffset(90, 25)

espButton.Position =
	UDim2.fromOffset(145, 5)

espButton.Font =
	Enum.Font.GothamBold

espButton.TextSize = 11

espButton.Parent = panel

Instance.new(
	"UICorner",
	espButton
).CornerRadius =
	UDim.new(0, 5)

local function updateESPButton()

	if espEnabled then

		espButton.Text = "ESP: ON"

		espButton.BackgroundColor3 =
			Color3.fromRGB(40, 150, 70)

	else

		espButton.Text = "ESP: OFF"

		espButton.BackgroundColor3 =
			Color3.fromRGB(120, 40, 40)
	end
end

updateESPButton()

espButton.MouseButton1Click:Connect(function()

	espEnabled =
		not espEnabled

	if espEnabled then

		for egg in pairs(eggModels) do
			createESP(egg)
		end

	else

		removeAllESP()
	end

	updateESPButton()
end)

--==================================================
-- CLEAR ALL
--==================================================

local clearButton =
	Instance.new("TextButton")

clearButton.Size =
	UDim2.fromOffset(100, 25)

clearButton.Position =
	UDim2.fromOffset(245, 5)

clearButton.Text =
	"CLEAR ALL!!"

clearButton.Font =
	Enum.Font.GothamBold

clearButton.TextSize = 11

clearButton.BackgroundColor3 =
	Color3.fromRGB(150, 50, 50)

clearButton.TextColor3 =
	Color3.new(1, 1, 1)

clearButton.Parent =
	panel

Instance.new(
	"UICorner",
	clearButton
).CornerRadius =
	UDim.new(0, 5)

--==================================================
-- EGG BUTTONS
--==================================================

local eggButtons = {}

local function updateEggButton(eggName)

	local button =
		eggButtons[eggName]

	if not button then
		return
	end

	if selected[eggName] then

		button.BackgroundColor3 =
			TARGET_EGGS[eggName]

		button.TextColor3 =
			Color3.new(0, 0, 0)

	else

		button.BackgroundColor3 =
			Color3.fromRGB(55, 55, 55)

		button.TextColor3 =
			Color3.new(1, 1, 1)
	end
end

for i, eggName in ipairs(EGG_ORDER) do

	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.fromOffset(140, 25)

	local column =
		(i - 1) % 4

	local row =
		math.floor((i - 1) / 4)

	button.Position =
		UDim2.fromOffset(
			10 + column * 150,
			40 + row * 32
		)

	button.Text =
		eggName

	button.Font =
		Enum.Font.GothamBold

	button.TextSize = 10

	button.Parent = panel

	Instance.new(
		"UICorner",
		button
	).CornerRadius =
		UDim.new(0, 5)

	eggButtons[eggName] =
		button

	button.MouseButton1Click:Connect(function()

		selected[eggName] =
			not selected[eggName]

		updateEggButton(eggName)

		if selected[eggName] then

			for egg, eggType in pairs(eggModels) do

				if eggType == eggName then
					createESP(egg)
				end
			end

		else

			for egg, data in pairs(tracked) do

				if data.eggName == eggName then
					removeESP(egg)
				end
			end
		end
	end)

	updateEggButton(eggName)
end

clearButton.MouseButton1Click:Connect(function()

	for eggName in pairs(TARGET_EGGS) do

		selected[eggName] = false

		updateEggButton(eggName)
	end

	removeAllESP()
end)

--==================================================
-- TP WALK TITLE
--==================================================

local tpTitle =
	Instance.new("TextLabel")

tpTitle.Size =
	UDim2.fromOffset(70, 22)

tpTitle.Position =
	UDim2.fromOffset(10, 110)

tpTitle.BackgroundTransparency = 1

tpTitle.Text = "TP WALK"

tpTitle.TextColor3 =
	Color3.new(1, 1, 1)

tpTitle.Font =
	Enum.Font.GothamBold

tpTitle.TextSize = 11

tpTitle.Parent = panel

--==================================================
-- TP WALK BUTTON
--==================================================

local tpButton =
	Instance.new("TextButton")

tpButton.Size =
	UDim2.fromOffset(85, 22)

tpButton.Position =
	UDim2.fromOffset(80, 110)

tpButton.Font =
	Enum.Font.GothamBold

tpButton.TextSize = 10

tpButton.Parent = panel

Instance.new(
	"UICorner",
	tpButton
).CornerRadius =
	UDim.new(0, 5)

local function updateTPButton()

	if tpWalkEnabled then

		tpButton.Text =
			"TP: ON"

		tpButton.BackgroundColor3 =
			Color3.fromRGB(40, 150, 70)

	else

		tpButton.Text =
			"TP: OFF"

		tpButton.BackgroundColor3 =
			Color3.fromRGB(120, 40, 40)
	end
end

updateTPButton()

tpButton.MouseButton1Click:Connect(function()

	tpWalkEnabled =
		not tpWalkEnabled

	if tpWalkEnabled then
		startTPWalk()
	else
		stopTPWalk()
	end

	updateTPButton()
end)

--==================================================
-- TP WALK VALUE
--==================================================

local tpLabel =
	Instance.new("TextLabel")

tpLabel.Size =
	UDim2.fromOffset(60, 22)

tpLabel.Position =
	UDim2.fromOffset(175, 110)

tpLabel.BackgroundTransparency = 1

tpLabel.TextColor3 =
	Color3.new(1, 1, 1)

tpLabel.Font =
	Enum.Font.GothamBold

tpLabel.TextSize = 11

tpLabel.Text =
	tostring(tpWalkValue)

tpLabel.Parent = panel

--==================================================
-- TP WALK SLIDER
--==================================================

local slider =
	Instance.new("Frame")

slider.Size =
	UDim2.fromOffset(400, 10)

slider.Position =
	UDim2.fromOffset(220, 116)

slider.BackgroundColor3 =
	Color3.fromRGB(65, 65, 65)

slider.Parent = panel

Instance.new(
	"UICorner",
	slider
).CornerRadius =
	UDim.new(1, 0)

local fill =
	Instance.new("Frame")

fill.Size =
	UDim2.new(0, 0, 1, 0)

fill.BackgroundColor3 =
	Color3.fromRGB(70, 170, 255)

fill.Parent = slider

Instance.new(
	"UICorner",
	fill
).CornerRadius =
	UDim.new(1, 0)

local knob =
	Instance.new("Frame")

knob.Size =
	UDim2.fromOffset(16, 16)

knob.AnchorPoint =
	Vector2.new(0.5, 0.5)

knob.Position =
	UDim2.new(0, 0, 0.5, 0)

knob.BackgroundColor3 =
	Color3.new(1, 1, 1)

knob.Parent = slider

Instance.new(
	"UICorner",
	knob
).CornerRadius =
	UDim.new(1, 0)

--==================================================
-- SLIDER INPUT
--==================================================

local draggingSlider = false

local function setTPWalkFromX(x)

	local width =
		slider.AbsoluteSize.X

	if width <= 0 then
		return
	end

	local relative =
		math.clamp(
			x - slider.AbsolutePosition.X,
			0,
			width
		)

	local percent =
		relative / width

	tpWalkValue =
		math.clamp(
			math.floor(
				MIN_TPWALK +
				percent *
				(MAX_TPWALK - MIN_TPWALK) +
				0.5
			),
			MIN_TPWALK,
			MAX_TPWALK
		)

	tpLabel.Text =
		tostring(tpWalkValue)

	fill.Size =
		UDim2.new(
			percent,
			0,
			1,
			0
		)

	knob.Position =
		UDim2.new(
			percent,
			0,
			0.5,
			0
		)
end

slider.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingSlider = true

		setTPWalkFromX(
			input.Position.X
		)
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not draggingSlider then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		setTPWalkFromX(
			input.Position.X
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingSlider = false
	end
end)

--==================================================
-- INITIAL SLIDER
--==================================================

do

	local percent =
		(tpWalkValue - MIN_TPWALK)
		/
		(MAX_TPWALK - MIN_TPWALK)

	fill.Size =
		UDim2.new(
			percent,
			0,
			1,
			0
		)

	knob.Position =
		UDim2.new(
			percent,
			0,
			0.5,
			0
		)

	tpLabel.Text =
		tostring(tpWalkValue)
end

--==================================================
-- OPEN / CLOSE
--==================================================

openButton.MouseButton1Click:Connect(function()

	panel.Visible =
		not panel.Visible
end)

--==================================================
-- DRAG PANEL
--==================================================

local draggingPanel = false
local dragStart
local startPos

panel.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingPanel = true

		dragStart =
			input.Position

		startPos =
			panel.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not draggingPanel then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		local delta =
			input.Position -
			dragStart

		panel.Position =
			UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingPanel = false
	end
end)

--==================================================
-- START
--==================================================

task.wait(1)

initialScan()

print("================================")
print("EGG ESP FPS OPTIMIZED")
print("ALL BUTTON : REMOVED")
print("CLEAR ALL  : ACTIVE")
print("TP WALK    : 1 - 500")
print("================================")
