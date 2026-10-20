--!strict
--[[
	Leaderboard init.server
	Orquestador del sistema: PlayerAdded -> load + setup, PlayerRemoving ->
	save síncrono, autosave cada 300s y flush en BindToClose (<25s).

	Los requires intra-sistema usan script (hermanos Rojo);
	la config compartida se resuelve vía ReplicatedStorage.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LeaderboardConfig"))
local PlayerDataStore = require(script:WaitForChild("PlayerDataStore"))
local LeaderstatsService = require(script:WaitForChild("LeaderstatsService"))

local BIND_TO_CLOSE_BUDGET_SECONDS = 25

local function LoadAndSetup(player: Player): ()
    local data = PlayerDataStore.load(player)
    -- El jugador pudo salir mientras el load cedía (GetAsync hace yield).
    if player.Parent == nil then
        PlayerDataStore.save(player)
        PlayerDataStore.clearCache(player.UserId)
        return
    end
    LeaderstatsService.setupPlayer(player, data)
end

local function SavePlayer(player: Player): boolean
    -- Sin leaderstats montado no hay valores vivos que sincronizar:
    -- persistir solo la caché buena (o no-op si nunca cargó).
    if player:FindFirstChild("leaderstats") == nil then
        local okNoStats = PlayerDataStore.save(player)
        return okNoStats == true
    end
    local live = LeaderstatsService.toData(player)
    PlayerDataStore.setCached(player.UserId, live)
    local ok = PlayerDataStore.save(player)
    return ok == true
end

Players.PlayerAdded:Connect(function(player: Player)
    task.spawn(function()
        local ok: boolean, err: any = pcall(LoadAndSetup, player)
        if not ok then
            warn(("Leaderboard: load+setup falló para %s: %s"):format(player.Name, tostring(err)))
        end
    end)
end)

-- Guardado síncrono (sin task.spawn): PlayerRemoving debe ceder hasta persistir.
Players.PlayerRemoving:Connect(function(player: Player)
    local ok, err = pcall(SavePlayer, player)
    if not ok then
        warn(("Leaderboard: save falló para %s: %s"):format(player.Name, tostring(err)))
    end
    PlayerDataStore.clearCache(player.UserId)
end)

-- Jugadores ya presentes (ej. Play Solo en Studio donde Added ya disparó).
for _, player in Players:GetPlayers() do
    task.spawn(function()
        local ok: boolean, err: any = pcall(LoadAndSetup, player)
        if not ok then
            warn(("Leaderboard: load+setup falló para %s: %s"):format(player.Name, tostring(err)))
        end
    end)
end

-- Autosave periódico con la caché sincronizada desde los IntValues vivos.
task.spawn(function()
    while true do
        task.wait(Config.AUTOSAVE_INTERVAL_SECONDS)
        for _, player in Players:GetPlayers() do
            local ok, err = pcall(SavePlayer, player)
            if not ok then
                warn(("Leaderboard: autosave falló para %s: %s"):format(player.Name, tostring(err)))
            end
        end
    end
end)

-- Flush final al cerrar el servidor, con techo de 25s.
game:BindToClose(function()
    local deadline = os.clock() + BIND_TO_CLOSE_BUDGET_SECONDS
    for _, player in Players:GetPlayers() do
        if os.clock() >= deadline then
            warn("Leaderboard: BindToClose alcanzó el presupuesto de 25s, saves restantes omitidos")
            break
        end
        pcall(SavePlayer, player)
    end
end)
