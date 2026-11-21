-- Câmera: vista cinematográfica no menu e terceira pessoa durante o jogo.
-- A câmera de terceira pessoa é a do próprio Roblox (funciona com mouse, toque e controle).
-- O zoom mínimo e máximo é configurado no StarterPlayer (default.project.json).

local RunService = game:GetService("RunService")

local CameraController = {}

local menuConnection = nil

local function stopMenuDrift()
	if menuConnection then
		menuConnection:Disconnect()
		menuConnection = nil
	end
end

function CameraController.showMenuView()
	local camera = workspace.CurrentCamera
	local temple = workspace:WaitForChild("Temple", 10)
	local anchor = temple and temple:FindFirstChild("MenuCamera")
	local base = if anchor then anchor.CFrame else CFrame.new(14, 9, 32) * CFrame.Angles(math.rad(-8), math.rad(25), 0)

	stopMenuDrift()
	camera.CameraType = Enum.CameraType.Scriptable
	local start = os.clock()
	-- Movimento lento de "respiração" da câmera enquanto o menu está aberto
	menuConnection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		camera.CFrame = base * CFrame.new(math.sin(t * 0.25) * 1.5, math.sin(t * 0.4) * 0.4, 0)
	end)
end

function CameraController.followCharacter(character)
	stopMenuDrift()
	local camera = workspace.CurrentCamera
	local humanoid = character:WaitForChild("Humanoid", 10)
	camera.CameraType = Enum.CameraType.Custom
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

return CameraController
