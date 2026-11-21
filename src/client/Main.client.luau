-- Ponto de partida do cliente (o aparelho do jogador). Cada parte fica no seu módulo.

local CharacterSelect = require(script.Parent.CharacterSelect)
local ItemInspect = require(script.Parent.ItemInspect)
local ItemFloat = require(script.Parent.ItemFloat)

CharacterSelect.start()
ItemInspect.start()
task.spawn(ItemFloat.start) -- espera o cenário carregar sem travar o resto

print("[Awakening] Cliente iniciado")
