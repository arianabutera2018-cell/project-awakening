-- Personagens PROVISÓRIOS do protótipo.
-- São feitos com o corpo padrão do Roblox + cores + cabelo montado com peças simples.
-- Servem para testar escolha, câmera e movimento. Os modelos anime finais virão depois.

local Characters = {}

Characters.List = {
	{
		Id = "Ren",
		DisplayName = "Ren",
		Role = "Opção masculina",
		Tagline = "Espírito calmo, passos rápidos.",
		HairStyle = "Spiky",
		Skin = Color3.fromRGB(255, 226, 204),
		Hair = Color3.fromRGB(44, 50, 92),
		HairShine = Color3.fromRGB(96, 116, 196),
		Eyes = Color3.fromRGB(64, 150, 255),
		Outfit = Color3.fromRGB(40, 58, 112),
		Pants = Color3.fromRGB(32, 30, 48),
		Accent = Color3.fromRGB(226, 64, 58),
		Scale = { Height = 1.0, Width = 1.0, Depth = 1.0, Head = 1.05 },
	},
	{
		Id = "Akari",
		DisplayName = "Akari",
		Role = "Opção feminina",
		Tagline = "Olhar atento, coração determinado.",
		HairStyle = "Long",
		Skin = Color3.fromRGB(255, 230, 214),
		Hair = Color3.fromRGB(238, 104, 160),
		HairShine = Color3.fromRGB(255, 176, 210),
		Eyes = Color3.fromRGB(150, 90, 230),
		Outfit = Color3.fromRGB(236, 238, 250),
		Pants = Color3.fromRGB(46, 70, 104),
		Accent = Color3.fromRGB(64, 200, 200),
		Scale = { Height = 0.95, Width = 0.92, Depth = 0.95, Head = 1.08 },
	},
}

Characters.ById = {}
for _, def in Characters.List do
	Characters.ById[def.Id] = def
end

return Characters
