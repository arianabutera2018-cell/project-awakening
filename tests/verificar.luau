--[[
	Verificação automática do protótipo (roda fora do Roblox, com o Lune).

	Uso:
		rojo build build.project.json -o build/ProjectAwakening.rbxl
		lune run tests/verificar.luau

	O que ele confere:
	  1. Todos os scripts em src/ compilam (sem erro de sintaxe).
	  2. O arquivo .rbxl gerado tem as pastas, scripts e objetos esperados.
	  3. Os itens do mapa batem com os textos de ItemInfo.
	  4. A aparência dos personagens pode ser montada sem erro
	     (roda o módulo de verdade num boneco de teste).
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local failures = 0
local function check(ok, message)
	if ok then
		print("  ok   " .. message)
	else
		failures += 1
		print("  FALHA " .. message)
	end
end

-- 1. Compilação ------------------------------------------------------------
print("1) Compilando scripts")
local function walk(dir)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			walk(path)
		elseif string.match(name, "%.luau$") then
			local ok, err = pcall(luau.compile, fs.readFile(path))
			check(ok, path .. (if ok then "" else ("\n        " .. tostring(err))))
		end
	end
end
walk("src")

-- 2. Estrutura do jogo -----------------------------------------------------
print("2) Estrutura do arquivo do jogo")
local placePath = "build/ProjectAwakening.rbxl"
if not fs.isFile(placePath) then
	print("  FALHA arquivo " .. placePath .. " não existe. Rode o rojo build antes.")
	process.exit(1)
end
local game = roblox.deserializePlace(fs.readFile(placePath))

local function find(path)
	local node = game
	for part in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(part)
	end
	return node
end

local expected = {
	{ "ReplicatedStorage.Shared.Characters", "ModuleScript" },
	{ "ReplicatedStorage.Shared.ItemInfo", "ModuleScript" },
	{ "ReplicatedStorage.Shared.Config", "ModuleScript" },
	{ "ReplicatedStorage.Remotes.ChooseCharacter", "RemoteEvent" },
	{ "ServerScriptService.Server.Main", "Script" },
	{ "ServerScriptService.Server.CharacterService", "ModuleScript" },
	{ "ServerScriptService.Server.CharacterAppearance", "ModuleScript" },
	{ "StarterPlayer.StarterPlayerScripts.Client.Main", "LocalScript" },
	{ "StarterPlayer.StarterPlayerScripts.Client.CharacterSelect", "ModuleScript" },
	{ "StarterPlayer.StarterPlayerScripts.Client.ItemInspect", "ModuleScript" },
	{ "Workspace.Temple.SpawnLocation", "SpawnLocation" },
	{ "Workspace.Temple.MenuCamera", "Part" },
	{ "Workspace.Temple.Corridor", "Model" },
	{ "Workspace.Temple.FinalHall", "Model" },
	{ "Lighting.AnimeColor", "ColorCorrectionEffect" },
	{ "Lighting.Glow", "BloomEffect" },
	{ "Lighting.Haze", "Atmosphere" },
}
for _, e in expected do
	local inst = find(e[1])
	check(inst ~= nil and inst.ClassName == e[2], e[1] .. " é " .. e[2])
end

check(find("Players").CharacterAutoLoads == false, "Players.CharacterAutoLoads desligado (personagem só nasce após a escolha)")
check(find("Workspace").StreamingEnabled == false, "Workspace.StreamingEnabled desligado (mapa pequeno)")

-- Contagem de peças (desempenho em celular)
local parts, lights = 0, 0
for _, d in find("Workspace.Temple"):GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	elseif d:IsA("PointLight") then
		lights += 1
	end
end
print(string.format("     cenário: %d peças, %d luzes", parts, lights))
check(parts < 1500, "menos de 1500 peças no cenário")
check(lights <= 30, "no máximo 30 luzes")

-- Orientação: colunas cilíndricas precisam ficar em pé (eixo X do cilindro apontando para cima)
local pillar = find("Workspace.Temple.Corridor.Segment01.Pillar")
check(pillar ~= nil and math.abs(pillar.CFrame.RightVector.Y - 1) < 1e-3, "colunas cilíndricas estão em pé")

-- 3. Itens interativos -----------------------------------------------------
print("3) Objetos interativos")
local env = {
	Color3 = roblox.Color3,
	Vector3 = roblox.Vector3,
	CFrame = roblox.CFrame,
	Enum = roblox.Enum,
}
local function loadModule(path)
	local source = find(path).Source
	return luau.load(source, { debugName = path, environment = env })()
end
local ItemInfo = loadModule("ReplicatedStorage.Shared.ItemInfo")
local found = 0
for _, model in find("Workspace.Temple.Interactables"):GetChildren() do
	local id = model:GetAttribute("ItemId")
	if id then
		found += 1
		check(ItemInfo[id] ~= nil, "item '" .. id .. "' tem descrição em ItemInfo")
		local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
		check(prompt ~= nil, "item '" .. id .. "' tem botão de interação (ProximityPrompt)")
	end
end
check(found == 2, "existem 2 itens examináveis (espada e livro)")

-- 4. Aparência dos personagens ---------------------------------------------
print("4) Montagem da aparência dos personagens")
local Characters = loadModule("ReplicatedStorage.Shared.Characters")
check(#Characters.List == 2, "2 personagens definidos")

-- Ambiente que imita o Roblox o suficiente para rodar CharacterAppearance
local function makeRequire(_caller)
	return function(target)
		local appearanceEnv = {
			game = game,
			script = target,
			require = makeRequire(target),
			Instance = roblox.Instance,
			UDim = roblox.UDim,
			UDim2 = roblox.UDim2,
			Vector2 = roblox.Vector2,
			warn = print,
		}
		for k, v in env do
			appearanceEnv[k] = v
		end
		return luau.load(target.Source, { debugName = target.Name, environment = appearanceEnv })()
	end
end
local appearanceModule = find("ServerScriptService.Server.CharacterAppearance")
local CharacterAppearance = makeRequire(nil)(appearanceModule)

for _, rigType in { "R15", "R6" } do
	for _, def in Characters.List do
		local rig = roblox.Instance.new("Model")
		rig.Name = def.Id
		local head = roblox.Instance.new("Part")
		head.Name = "Head"
		head.Size = if rigType == "R6" then roblox.Vector3.new(2, 1, 1) else roblox.Vector3.new(1.2, 1.2, 1.2)
		head.CFrame = roblox.CFrame.new(0, 4.5, 0)
		head.Parent = rig
		local face = roblox.Instance.new("Decal")
		face.Name = "face"
		face.Parent = head
		for _, name in (if rigType == "R6" then { "Torso" } else { "UpperTorso", "LowerTorso" }) do
			local p = roblox.Instance.new("Part")
			p.Name = name
			p.Size = roblox.Vector3.new(2, if rigType == "R6" then 2 else 1, 1)
			p.Parent = rig
		end

		local descOk, descErr = pcall(CharacterAppearance.makeDescription, def)
		check(descOk, rigType .. " " .. def.Id .. ": HumanoidDescription" .. (if descOk then "" else " -> " .. tostring(descErr)))
		local ok, err = pcall(CharacterAppearance.decorate, rig, def)
		check(ok, rigType .. " " .. def.Id .. ": cabelo, rosto e contorno" .. (if ok then "" else " -> " .. tostring(err)))
		if ok then
			check(head:FindFirstChild("face") == nil, rigType .. " " .. def.Id .. ": rosto padrão removido")
			check(head:FindFirstChild("AnimeFace") ~= nil, rigType .. " " .. def.Id .. ": rosto anime criado")
			check(rig:FindFirstChild("AnimeOutline") ~= nil, rigType .. " " .. def.Id .. ": contorno criado")
			check(rig:FindFirstChild("HairCap") ~= nil, rigType .. " " .. def.Id .. ": cabelo criado")
		end
	end
end

print("")
if failures == 0 then
	print("TUDO CERTO: nenhuma falha encontrada.")
else
	print(string.format("%d FALHA(S) encontrada(s).", failures))
	process.exit(1)
end
