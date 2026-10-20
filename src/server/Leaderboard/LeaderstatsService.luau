--!strict
--[[
	LeaderstatsService
	Crea y sincroniza el Folder "leaderstats" nativo (IntValue Coins, Wins).

	Solo corre en servidor: grantCoins/grantWin mutan IntValues y la caché,
	pero nunca leen input del cliente (no hay RemoteEvents en este MVP).
	Toda validación de rangos vive aquí + ClampStat de la config.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LeaderboardConfig") :: ModuleScript)
local LeaderboardFolder = script.Parent :: Instance
local PlayerDataStore = require(LeaderboardFolder:WaitForChild("PlayerDataStore") :: ModuleScript)

type PlayerData = Config.PlayerData

local LeaderstatsService = {}

local function FindStat(player: Player, statName: string): IntValue?
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats == nil or not leaderstats:IsA("Folder") then
        return nil
    end
    local stat = leaderstats:FindFirstChild(statName)
    if stat == nil or not stat:IsA("IntValue") then
        return nil
    end
    return stat
end

local function EnsureStat(folder: Folder, statName: string): IntValue
    local existing = folder:FindFirstChild(statName)
    if existing ~= nil and existing:IsA("IntValue") then
        return existing
    end
    if existing ~= nil then
        existing:Destroy()
    end
    local created = Instance.new("IntValue")
    created.Name = statName
    created.Value = 0
    created.Parent = folder
    return created
end

--[[
	Monto válido: número finito, floor, > 0 y <= MAX_STAT_VALUE.
	Devuelve nil si el input es inválido (tipos, NaN, infinitos, <= 0).
]]
local function SanitizeAmount(raw: any): number?
    if typeof(raw) ~= "number" then
        return nil
    end
    local amount: number = raw
    if amount ~= amount then
        return nil
    end
    if amount == math.huge or amount == -math.huge then
        return nil
    end
    local floored = math.floor(amount)
    if floored <= 0 then
        return nil
    end
    if floored > Config.MAX_STAT_VALUE then
        return Config.MAX_STAT_VALUE
    end
    return floored
end

local function SyncCache(player: Player, coins: number, wins: number): ()
    PlayerDataStore.setCached(player.UserId, {
        Version = Config.DATA_VERSION,
        Coins = coins,
        Wins = wins,
    })
end

--[[
	Crea (o reutiliza) leaderstats y aplica los valores de data.
	Idempotente: llamar dos veces no duplica instancias.
]]
function LeaderstatsService.setupPlayer(player: Player, data: PlayerData): Folder
    local leaderstats = player:FindFirstChild("leaderstats")
    local folder: Folder
    if leaderstats ~= nil and leaderstats:IsA("Folder") then
        folder = leaderstats
    else
        if leaderstats ~= nil then
            leaderstats:Destroy()
        end
        folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player
    end
    local coinsValue = EnsureStat(folder, "Coins")
    local winsValue = EnsureStat(folder, "Wins")
    local coins = Config.ClampStat(data.Coins)
    local wins = Config.ClampStat(data.Wins)
    coinsValue.Value = coins
    winsValue.Value = wins
    return folder
end

--[[
	Lee los IntValues vivos y devuelve un PlayerData sanitizado.
	Si falta leaderstats o un stat, ese campo se reporta como 0.
]]
function LeaderstatsService.toData(player: Player): PlayerData
    local coins = 0
    local wins = 0
    local coinsStat = FindStat(player, "Coins")
    if coinsStat ~= nil then
        coins = Config.ClampStat(coinsStat.Value)
    end
    local winsStat = FindStat(player, "Wins")
    if winsStat ~= nil then
        wins = Config.ClampStat(winsStat.Value)
    end
    return {
        Version = Config.DATA_VERSION,
        Coins = coins,
        Wins = wins,
    }
end

--[[
	Suma amount a Coins (servidor únicamente). Devuelve false si el monto
	es inválido o si el jugador no tiene leaderstats montado.
]]
function LeaderstatsService.grantCoins(player: Player, amount: number): boolean
    local valid = SanitizeAmount(amount)
    if valid == nil then
        return false
    end
    local stat = FindStat(player, "Coins")
    if stat == nil then
        return false
    end
    local nextValue = stat.Value + valid
    if nextValue > Config.MAX_STAT_VALUE then
        nextValue = Config.MAX_STAT_VALUE
    end
    stat.Value = nextValue
    local winsStat = FindStat(player, "Wins")
    local wins = 0
    if winsStat ~= nil then
        wins = Config.ClampStat(winsStat.Value)
    end
    SyncCache(player, nextValue, wins)
    return true
end

--[[
	Suma una victoria (o amount si se indica). Servidor únicamente.
]]
function LeaderstatsService.grantWin(player: Player, amount: number?): boolean
    local count: number = amount or 1
    local valid = SanitizeAmount(count)
    if valid == nil then
        return false
    end
    local stat = FindStat(player, "Wins")
    if stat == nil then
        return false
    end
    local nextValue = stat.Value + valid
    if nextValue > Config.MAX_STAT_VALUE then
        nextValue = Config.MAX_STAT_VALUE
    end
    stat.Value = nextValue
    local coinsStat = FindStat(player, "Coins")
    local coins = 0
    if coinsStat ~= nil then
        coins = Config.ClampStat(coinsStat.Value)
    end
    SyncCache(player, coins, nextValue)
    return true
end

return LeaderstatsService
