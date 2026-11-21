-- Monta a aparência PROVISÓRIA dos personagens:
-- cores do corpo, cabelo feito de peças, olhos desenhados e contorno estilo anime.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CharacterAppearance = {}

-- Cria a "descrição" usada pelo Roblox para montar o corpo (sem roupas nem acessórios do avatar do jogador).
function CharacterAppearance.makeDescription(def)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = def.Skin
	desc.TorsoColor = def.Outfit
	desc.LeftArmColor = def.Outfit
	desc.RightArmColor = def.Outfit
	desc.LeftLegColor = def.Pants
	desc.RightLegColor = def.Pants
	desc.HeightScale = def.Scale.Height
	desc.WidthScale = def.Scale.Width
	desc.DepthScale = def.Scale.Depth
	desc.HeadScale = def.Scale.Head
	return desc
end

-- Peça decorativa presa (soldada) a uma parte do corpo.
local function attach(parentPart, name, size, offset, color, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = parentPart.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parentPart
	weld.Part1 = p
	weld.Parent = p
	p.Parent = parentPart.Parent
	return p
end

local function cf(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

-- Cabelo. Medidas relativas à altura da cabeça (h), para funcionar em R6 e R15.
-- Na cabeça, -Z é a frente (para onde o rosto olha).
local function buildHair(head, def)
	local h = head.Size.Y
	local hair, shine = def.Hair, def.HairShine
	local ball = Enum.PartType.Ball
	local v = Vector3.new

	attach(head, "HairCap", v(1.32, 1.05, 1.32) * h, cf(0, 0.22 * h, 0.06 * h), hair, ball)

	if def.HairStyle == "Spiky" then
		-- Pontas espetadas para trás e para cima
		local spikes = {
			{ 0, 0.62, 0.28, -35, 0, 0 },
			{ 0.38, 0.5, 0.36, -45, 0, -30 },
			{ -0.38, 0.5, 0.36, -45, 0, 30 },
			{ 0.22, 0.25, 0.62, -75, 0, -20 },
			{ -0.22, 0.25, 0.62, -75, 0, 20 },
			{ 0, 0.1, 0.66, -95, 0, 0 },
		}
		for i, s in spikes do
			attach(head, "HairSpike" .. i, v(0.34, 0.75, 0.34) * h, cf(s[1] * h, s[2] * h, s[3] * h, s[4], s[5], s[6]), hair)
		end
		-- Franja na testa
		for i, x in { -0.34, 0, 0.34 } do
			attach(head, "HairBang" .. i, v(0.36, 0.5, 0.2) * h, cf(x * h, 0.32 * h, -0.56 * h, 12, 0, x * -40), hair)
		end
		-- Lenço vermelho no pescoço
		local torso = head.Parent:FindFirstChild("UpperTorso") or head.Parent:FindFirstChild("Torso")
		if torso then
			local ts = torso.Size
			attach(torso, "Scarf", v(ts.X * 1.05, 0.35 * h, ts.Z * 1.25), cf(0, ts.Y / 2 - 0.1 * h, 0), def.Accent)
			attach(torso, "ScarfTail", v(0.3 * h, 1.1 * h, 0.12 * h), cf(0.25 * ts.X, ts.Y / 2 - 0.6 * h, ts.Z * 0.62, 10, 0, -12), def.Accent)
		end
	else
		-- Cabelo longo com franja e mechas laterais
		attach(head, "HairBack", v(1.25, 2.0, 0.45) * h, cf(0, -0.45 * h, 0.5 * h, 6, 0, 0), hair)
		attach(head, "HairBackTip", v(1.0, 0.6, 0.4) * h, cf(0, -1.5 * h, 0.58 * h, 6, 0, 0), shine)
		for _, side in { -1, 1 } do
			attach(head, "HairSide", v(0.28, 1.35, 0.36) * h, cf(side * 0.62 * h, -0.2 * h, -0.18 * h, 0, 0, side * -4), hair)
		end
		for i, x in { -0.36, -0.12, 0.14, 0.38 } do
			attach(head, "HairBang" .. i, v(0.3, 0.55, 0.18) * h, cf(x * h, 0.3 * h, -0.57 * h, 10, 0, x * -30), hair)
		end
		-- Laço
		attach(head, "BowLeft", v(0.5, 0.36, 0.16) * h, cf(-0.28 * h, 0.55 * h, 0.6 * h, 0, 0, 20), def.Accent)
		attach(head, "BowRight", v(0.5, 0.36, 0.16) * h, cf(0.28 * h, 0.55 * h, 0.6 * h, 0, 0, -20), def.Accent)
		attach(head, "BowKnot", v(0.2, 0.2, 0.2) * h, cf(0, 0.55 * h, 0.64 * h), def.Accent, Enum.PartType.Ball)
		-- Faixa na cintura
		local lower = head.Parent:FindFirstChild("LowerTorso") or head.Parent:FindFirstChild("Torso")
		if lower then
			local ls = lower.Size
			attach(lower, "Sash", v(ls.X * 1.06, 0.3 * h, ls.Z * 1.2), cf(0, ls.Y * 0.25, 0), def.Accent)
		end
	end

	-- Brilho no topo do cabelo (detalhe típico de anime)
	attach(head, "HairShine", v(0.7, 0.12, 0.3) * h, cf(-0.18 * h, 0.66 * h, -0.2 * h, -20, 0, 10), shine)
end

-- Rosto desenhado com interface 2D presa à frente da cabeça (olhos grandes de anime).
local function buildFace(head, def)
	for _, child in head:GetChildren() do
		if child:IsA("Decal") then
			child:Destroy() -- remove o rosto padrão do Roblox
		end
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "AnimeFace"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(200, 200)
	gui.LightInfluence = 0.4
	gui.Parent = head

	local function frame(name, pos, size, color, round, parent)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = pos
		f.Size = size
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		if round then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(round, 0)
			c.Parent = f
		end
		f.Parent = parent or gui
		return f
	end

	local dark = Color3.fromRGB(30, 22, 40)
	for _, x in { 0.32, 0.68 } do
		local eye = frame("Eye", UDim2.fromScale(x, 0.56), UDim2.fromScale(0.17, 0.24), dark, 0.45)
		frame("Iris", UDim2.fromScale(0.5, 0.58), UDim2.fromScale(0.78, 0.72), def.Eyes, 0.5, eye)
		frame("Shine", UDim2.fromScale(0.36, 0.3), UDim2.fromScale(0.34, 0.26), Color3.new(1, 1, 1), 0.5, eye)
		frame("Brow", UDim2.fromScale(x, 0.36), UDim2.fromScale(0.16, 0.035), def.Hair, 0.5)
	end
	frame("Mouth", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.08, 0.025), Color3.fromRGB(150, 70, 80), 0.5)
end

-- Contorno escuro ao redor do personagem (imita o traço de desenho anime).
local function addOutline(character)
	local h = Instance.new("Highlight")
	h.Name = "AnimeOutline"
	h.FillTransparency = 1
	h.OutlineTransparency = 0.1
	h.OutlineColor = Config.OutlineColor
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = character
end

function CharacterAppearance.decorate(character, def)
	local head = character:FindFirstChild("Head")
	if not head then
		warn("[Awakening] Personagem sem cabeça; aparência não aplicada")
		return
	end
	buildFace(head, def)
	buildHair(head, def)
	addOutline(character)
end

return CharacterAppearance
