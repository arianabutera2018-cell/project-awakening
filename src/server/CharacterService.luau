-- Recebe a escolha de personagem do jogador, faz o personagem nascer e renascer.
-- O servidor confere tudo que chega do cliente (nunca confiar cegamente no cliente).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(ReplicatedStorage.Shared.Characters)
local Config = require(ReplicatedStorage.Shared.Config)
local CharacterAppearance = require(script.Parent.CharacterAppearance)

local CharacterService = {}

local lastChoice = {} -- [Player] = os.clock() da última troca

local function spawnAs(player, def)
	if not player.Parent then
		return -- jogador já saiu
	end
	player:SetAttribute("CharacterId", def.Id)
	player:LoadCharacterWithHumanoidDescription(CharacterAppearance.makeDescription(def))

	local character = player.Character
	if not character then
		return
	end
	CharacterAppearance.decorate(character, def)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Once(function()
			task.wait(Config.RespawnDelay)
			-- Só renasce se ainda for o mesmo personagem (o jogador pode ter trocado)
			if player.Parent and player.Character == character then
				local current = Characters.ById[player:GetAttribute("CharacterId")]
				if current then
					spawnAs(player, current)
				end
			end
		end)
	end
end

local function onChoose(player, characterId)
	-- Validação: precisa ser texto e um personagem que existe
	if typeof(characterId) ~= "string" then
		return
	end
	local def = Characters.ById[characterId]
	if not def then
		return
	end
	-- Evita trocas muito rápidas (spam)
	local now = os.clock()
	if lastChoice[player] and now - lastChoice[player] < Config.ChooseCooldown then
		return
	end
	lastChoice[player] = now

	spawnAs(player, def)
end

function CharacterService.start()
	ReplicatedStorage.Remotes.ChooseCharacter.OnServerEvent:Connect(onChoose)
	Players.PlayerRemoving:Connect(function(player)
		lastChoice[player] = nil
	end)
end

return CharacterService
