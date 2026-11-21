-- Animação só visual (no aparelho de cada jogador): itens flutuando e o cristal girando.
-- Usa workspace:BulkMoveTo, que é a forma mais barata de mover várias peças por quadro.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)

local ItemFloat = {}

local entries = {} -- { parts = {...}, offsets = {...}, center = CFrame, phase = number, spin = boolean }

local function register(parts, center, phase, spin)
	local offsets = {}
	for i, p in parts do
		offsets[i] = center:ToObjectSpace(p.CFrame)
	end
	table.insert(entries, { parts = parts, offsets = offsets, center = center, phase = phase, spin = spin })
end

local function addOutline(model, color)
	local h = Instance.new("Highlight")
	h.Name = "ItemOutline"
	h.FillTransparency = 1
	h.OutlineColor = color
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
end

function ItemFloat.start()
	local temple = workspace:WaitForChild("Temple", 15)
	if not temple then
		warn("[Awakening] Cenário 'Temple' não encontrado; animações desligadas")
		return
	end

	local phase = 0
	for _, model in temple:WaitForChild("Interactables"):GetChildren() do
		if model:IsA("Model") and model:GetAttribute("Float") then
			local parts = {}
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(parts, d)
				end
			end
			local center = model:GetBoundingBox()
			register(parts, center, phase, true)
			phase += math.pi / 2
			local info = ItemInfo[model:GetAttribute("ItemId")]
			addOutline(model, if info then info.Color else Color3.new(1, 1, 1))
		end
	end

	for _, d in temple:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Spin") then
			register({ d }, d.CFrame, 0, true)
		end
	end

	local moveParts, moveCFrames = {}, {}
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		table.clear(moveParts)
		table.clear(moveCFrames)
		for _, e in entries do
			local cf = e.center
				* CFrame.new(0, math.sin(t * 1.6 + e.phase) * 0.35, 0)
				* CFrame.Angles(0, if e.spin then t * 0.6 else 0, 0)
			for i, p in e.parts do
				table.insert(moveParts, p)
				table.insert(moveCFrames, cf * e.offsets[i])
			end
		end
		workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return ItemFloat
