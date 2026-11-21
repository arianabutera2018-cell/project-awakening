-- Mostra a descrição de um objeto quando o jogador usa "Examinar" (tecla E, toque ou botão X).
-- O painel aparece no topo da tela para não cobrir o personagem nem os controles do celular.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Parent.Ui)

local ItemInspect = {}

local panel, kindLabel, titleLabel, descLabel, stroke
local showToken = 0

local function hide()
	if panel.Visible then
		local tween = TweenService:Create(panel, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, -10) })
		tween:Play()
		tween.Completed:Once(function()
			panel.Visible = false
		end)
	end
end

local function show(info)
	kindLabel.Text = info.Kind
	kindLabel.TextColor3 = info.Color
	titleLabel.Text = info.Title
	descLabel.Text = info.Description
	stroke.Color = info.Color
	panel.Position = UDim2.new(0.5, 0, 0, -10)
	panel.Visible = true
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 8) }):Play()

	showToken += 1
	local myToken = showToken
	task.delay(Config.InfoPanelSeconds, function()
		if showToken == myToken then
			hide()
		end
	end)
end

local function build(playerGui)
	local gui = Ui.screen("ItemInspect", playerGui, 6)
	panel = Ui.new("TextButton", {
		Name = "InfoPanel",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromScale(0.5, 0.24),
		BackgroundColor3 = Ui.Colors.Panel,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = gui,
	}, {
		Ui.corner(0.12),
		Ui.new("UISizeConstraint", { MinSize = Vector2.new(260, 110), MaxSize = Vector2.new(480, 160) }),
	})
	stroke = Ui.stroke(Ui.Colors.Gold, 2)
	stroke.Parent = panel
	kindLabel = Ui.label("", {
		Position = UDim2.fromScale(0.05, 0.06),
		Size = UDim2.fromScale(0.9, 0.16),
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	}, 14)
	titleLabel = Ui.label("", {
		Position = UDim2.fromScale(0.05, 0.22),
		Size = UDim2.fromScale(0.9, 0.24),
		TextColor3 = Ui.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	}, 24)
	descLabel = Ui.label("", {
		Position = UDim2.fromScale(0.05, 0.48),
		Size = UDim2.fromScale(0.9, 0.36),
		Font = Enum.Font.Gotham,
		TextColor3 = Ui.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = panel,
	}, 16)
	Ui.label("toque para fechar", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.96, 0.97),
		Size = UDim2.fromScale(0.4, 0.1),
		Font = Enum.Font.Gotham,
		TextColor3 = Ui.Colors.TextSoft,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	}, 11)
	panel.Activated:Connect(hide)
end

function ItemInspect.start()
	build(Players.LocalPlayer:WaitForChild("PlayerGui"))
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local model = prompt:FindFirstAncestorWhichIsA("Model")
		local itemId = model and model:GetAttribute("ItemId")
		local info = itemId and ItemInfo[itemId]
		if info then
			show(info)
		end
	end)
end

return ItemInspect
