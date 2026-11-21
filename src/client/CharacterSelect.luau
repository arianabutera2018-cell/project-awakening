-- Tela de escolha de personagem + botão "Trocar personagem" durante o jogo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Characters = require(ReplicatedStorage.Shared.Characters)
local Ui = require(script.Parent.Ui)
local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer
local chooseRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChooseCharacter")

local CharacterSelect = {}

local menuGui, hudGui, backButton

-- Retrato simples desenhado com formas 2D (provisório, não é arte final).
local function buildPortrait(def)
	local portrait = Ui.new("Frame", {
		Name = "Portrait",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.05),
		Size = UDim2.fromScale(0.8, 0.5),
		BackgroundColor3 = Ui.Colors.PanelLight,
		ClipsDescendants = true,
	}, {
		Ui.corner(0.1),
		Ui.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		Ui.new("UIGradient", {
			Color = ColorSequence.new(def.Accent:Lerp(Color3.new(1, 1, 1), 0.3), Ui.Colors.PanelLight),
			Rotation = 90,
		}),
	})
	local function shape(name, pos, size, color, rot, round, z)
		return Ui.new("Frame", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = pos,
			Size = size,
			Rotation = rot or 0,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z or 2,
			Parent = portrait,
		}, { Ui.corner(round or 0.5) })
	end
	local s = UDim2.fromScale
	-- Ombros e roupa
	shape("Body", s(0.5, 1.02), s(0.78, 0.36), def.Outfit, 0, 0.4, 2)
	shape("Collar", s(0.5, 0.86), s(0.3, 0.06), def.Accent, 0, 0.5, 3)
	-- Cabelo de trás
	if def.HairStyle == "Long" then
		shape("HairLong", s(0.5, 0.62), s(0.74, 0.72), def.Hair, 0, 0.35, 2)
	else
		for i, r in { -40, -15, 15, 40 } do
			shape("Spike" .. i, s(0.32 + i * 0.07, 0.2), s(0.12, 0.3), def.Hair, r, 0.3, 2)
		end
	end
	shape("HairCap", s(0.5, 0.4), s(0.66, 0.5), def.Hair, 0, 0.5, 3)
	-- Rosto
	shape("Face", s(0.5, 0.56), s(0.5, 0.5), def.Skin, 0, 0.45, 4)
	shape("Bangs", s(0.5, 0.36), s(0.56, 0.18), def.Hair, 0, 0.5, 5)
	for _, x in { 0.4, 0.6 } do
		local eye = shape("Eye", s(x, 0.58), s(0.1, 0.14), Color3.fromRGB(30, 22, 40), 0, 0.45, 5)
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = s(0.5, 0.6),
			Size = s(0.75, 0.7),
			BackgroundColor3 = def.Eyes,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = eye,
		}, { Ui.corner(0.5) })
		Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = s(0.35, 0.3),
			Size = s(0.35, 0.28),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 7,
			Parent = eye,
		}, { Ui.corner(0.5) })
	end
	shape("Mouth", s(0.5, 0.72), s(0.06, 0.015), Color3.fromRGB(150, 70, 80), 0, 0.5, 5)
	return portrait
end

local function buildCard(def, onChosen)
	local card = Ui.new("TextButton", {
		Name = def.Id,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(0.44, 1),
		BackgroundColor3 = Ui.Colors.Panel,
		BackgroundTransparency = 0.08,
	}, {
		Ui.corner(0.06),
		Ui.stroke(def.Accent, 2),
		Ui.new("UISizeConstraint", { MaxSize = Vector2.new(300, 420) }),
		buildPortrait(def),
		Ui.label(def.DisplayName, {
			Position = UDim2.fromScale(0.05, 0.57),
			Size = UDim2.fromScale(0.9, 0.12),
		}, 34),
		Ui.label(def.Role, {
			Position = UDim2.fromScale(0.05, 0.69),
			Size = UDim2.fromScale(0.9, 0.07),
			TextColor3 = def.Accent,
			Font = Enum.Font.GothamMedium,
		}, 18),
		Ui.label(def.Tagline, {
			Position = UDim2.fromScale(0.08, 0.76),
			Size = UDim2.fromScale(0.84, 0.08),
			TextColor3 = Ui.Colors.TextSoft,
			Font = Enum.Font.Gotham,
		}, 15),
		Ui.new("TextLabel", {
			Name = "PlayTag",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.fromScale(0.7, 0.09),
			BackgroundColor3 = def.Accent,
			Text = "JOGAR",
			TextColor3 = Ui.Colors.Panel,
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
		}, { Ui.corner(0.4), Ui.new("UITextSizeConstraint", { MaxTextSize = 20 }) }),
	})
	local scale = Ui.new("UIScale", { Parent = card })
	card.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1.04 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	card.Activated:Connect(function()
		onChosen(def)
	end)
	return card
end

local function setMenuVisible(visible)
	menuGui.Enabled = visible
	hudGui.Enabled = not visible
	backButton.Visible = visible and player.Character ~= nil
	if visible then
		CameraController.showMenuView()
	end
end

local function buildMenu(playerGui)
	menuGui = Ui.screen("CharacterSelect", playerGui, 10)
	Ui.new("Frame", {
		Name = "Shade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(14, 8, 28),
		BackgroundTransparency = 0.25,
		Parent = menuGui,
	}, {
		Ui.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.5, 0.75),
				NumberSequenceKeypoint.new(1, 0.1),
			}),
			Rotation = 90,
		}),
	})
	Ui.label("PROJECT: AWAKENING", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.03),
		Size = UDim2.fromScale(0.9, 0.09),
		TextColor3 = Ui.Colors.Gold,
		Font = Enum.Font.GothamBlack,
		Parent = menuGui,
	}, 48)
	Ui.label("Protótipo v0 — escolha seu personagem", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.fromScale(0.9, 0.05),
		TextColor3 = Ui.Colors.TextSoft,
		Font = Enum.Font.GothamMedium,
		Parent = menuGui,
	}, 22)

	local row = Ui.new("Frame", {
		Name = "Cards",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.86, 0.66),
		BackgroundTransparency = 1,
		Parent = menuGui,
	}, {
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.04, 0),
		}),
	})
	for _, def in Characters.List do
		buildCard(def, function(chosen)
			chooseRemote:FireServer(chosen.Id)
		end).Parent = row
	end

	Ui.label("Personagens provisórios: os modelos anime finais ainda serão criados.", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.985),
		Size = UDim2.fromScale(0.9, 0.04),
		TextColor3 = Ui.Colors.TextSoft,
		Font = Enum.Font.Gotham,
		Parent = menuGui,
	}, 16)

	backButton = Ui.new("TextButton", {
		Name = "Back",
		Position = UDim2.new(1, -12, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(110, 40),
		BackgroundColor3 = Ui.Colors.PanelLight,
		Text = "Voltar",
		TextColor3 = Ui.Colors.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Visible = false,
		Parent = menuGui,
	}, { Ui.corner(0.3), Ui.stroke(Ui.Colors.Gold, 1.5) })
	backButton.Activated:Connect(function()
		setMenuVisible(false)
	end)
end

-- Botão pequeno no canto superior direito: longe do joystick (esquerda) e do pulo (direita, embaixo).
local function buildHud(playerGui)
	hudGui = Ui.screen("Hud", playerGui, 5)
	hudGui.Enabled = false
	local button = Ui.new("TextButton", {
		Name = "SwitchCharacter",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(150, 38),
		BackgroundColor3 = Ui.Colors.Panel,
		BackgroundTransparency = 0.2,
		Text = "Trocar personagem",
		TextColor3 = Ui.Colors.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Parent = hudGui,
	}, { Ui.corner(0.3), Ui.stroke(Ui.Colors.Gold, 1.5) })
	button.Activated:Connect(function()
		setMenuVisible(true)
	end)
end

function CharacterSelect.start()
	local playerGui = player:WaitForChild("PlayerGui")
	buildMenu(playerGui)
	buildHud(playerGui)
	setMenuVisible(true)

	player.CharacterAdded:Connect(function(character)
		setMenuVisible(false)
		CameraController.followCharacter(character)
	end)
end

return CharacterSelect
