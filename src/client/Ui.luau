-- Pequenos ajudantes para montar interfaces por código, com o mesmo visual em tudo.

local Ui = {}

Ui.Colors = {
	Panel = Color3.fromRGB(24, 18, 40),
	PanelLight = Color3.fromRGB(46, 36, 74),
	Text = Color3.fromRGB(250, 246, 255),
	TextSoft = Color3.fromRGB(196, 186, 220),
	Gold = Color3.fromRGB(255, 205, 90),
	Accent = Color3.fromRGB(255, 110, 170),
}

-- Cria uma instância com propriedades e filhos: Ui.new("Frame", { Size = ... }, { filhos })
function Ui.new(className, props, children)
	local inst = Instance.new(className)
	for key, value in props or {} do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Ui.corner(scale)
	return Ui.new("UICorner", { CornerRadius = UDim.new(scale or 0.12, 0) })
end

function Ui.stroke(color, thickness)
	return Ui.new("UIStroke", {
		Color = color or Ui.Colors.Gold,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Ui.label(text, props, maxTextSize)
	local base = {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Ui.Colors.Text,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextWrapped = true,
	}
	for k, v in props or {} do
		base[k] = v
	end
	return Ui.new("TextLabel", base, { Ui.new("UITextSizeConstraint", { MaxTextSize = maxTextSize or 32 }) })
end

-- Tela base: respeita a área segura do celular (notch e barra do Roblox).
function Ui.screen(name, playerGui, order)
	return Ui.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 0,
		Parent = playerGui,
	})
end

return Ui
