--!strict
--[[
	PlayerDataStore
	Wrapper de DataStore con caché en memoria por UserId.

	Responsabilidades:
	- load/save contra DataStoreService con pcall + 3 intentos (backoff 1/2/4).
	- Escrituras con UpdateAsync (no pisar a ciegas con SetAsync).
	- Caché por UserId (number) para lecturas calientes y guardado al salir.
	- Validación de tipos + floor/clamp 0..MAX_STAT_VALUE + migración de versión.

	No crea leaderstats ni otorga moneda: eso es LeaderstatsService.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LeaderboardConfig") :: ModuleScript)

type PlayerData = Config.PlayerData

local PlayerDataStore = {}

local Store = DataStoreService:GetDataStore(Config.STORE_NAME)

--- Caché en memoria indexada por UserId (number, nunca por Player).
local Cache: { [number]: PlayerData } = {}

local function CopyData(data: PlayerData): PlayerData
    return {
        Version = data.Version,
        Coins = data.Coins,
        Wins = data.Wins,
    }
end

local function SanitizeNumber(raw: any): number
    if typeof(raw) ~= "number" then
        return 0
    end
    local asNumber: number = raw
    return Config.ClampStat(asNumber)
end

--[[
	Migra cualquier payload crudo del DataStore al esquema actual.
	- nil / no-tabla -> defaults.
	- Campos desconocidos se descartan; faltantes -> 0.
	- La versión de salida siempre es DATA_VERSION.
]]
local function Migrate(raw: any): PlayerData
    if typeof(raw) ~= "table" then
        return Config.CloneDefaults()
    end
    local rawTable: any = raw
    return {
        Version = Config.DATA_VERSION,
        Coins = SanitizeNumber(rawTable.Coins),
        Wins = SanitizeNumber(rawTable.Wins),
    }
end

local function BackoffDelay(attempt: number): number
    local delays: { number } = Config.BACKOFF_DELAYS
    return delays[attempt] or delays[#delays]
end

--[[
	Lectura con reintentos. Devuelve (true, payload) o (false, nil).
	Nunca hace error: el fallo se reporta y load() usa defaults.
]]
local function GetWithRetry(key: string): (boolean, any)
    local last: any = nil
    local maxRetries: number = Config.MAX_RETRIES
    for attempt = 1, maxRetries do
        local ok: boolean, value: any = pcall(function(): any
            return Store:GetAsync(key)
        end)
        if ok then
            return true, value
        end
        last = value
        if attempt < maxRetries then
            task.wait(BackoffDelay(attempt))
        end
    end
    return false, last
end

--[[
	Escritura con UpdateAsync + reintentos. Devuelve true si persistió.
	Se publica un snapshot inmutable para no compartir la caché con el callback.
]]
local function UpdateWithRetry(key: string, data: PlayerData): boolean
    local snapshot: PlayerData = CopyData(data)
    snapshot.Version = Config.DATA_VERSION
    local maxRetries: number = Config.MAX_RETRIES
    for attempt = 1, maxRetries do
        local ok: boolean = pcall(function()
            Store:UpdateAsync(key, function(_old: any): any
                return snapshot
            end)
        end)
        if ok then
            return true
        end
        if attempt < maxRetries then
            task.wait(BackoffDelay(attempt))
        end
    end
    return false
end

--[[
	Carga los datos del jugador (caché primero, DataStore después).
	Nunca hace error: ante fallo total devuelve defaults versionados.
]]
function PlayerDataStore.load(player: Player): PlayerData
    local userId = player.UserId
    local cached = Cache[userId]
    if cached ~= nil then
        return CopyData(cached)
    end
    local key = Config.GetKey(userId)
    local ok, raw = GetWithRetry(key)
    if ok then
        local data = Migrate(raw)
        Cache[userId] = CopyData(data)
        return CopyData(data)
    else
        warn(("PlayerDataStore: load falló tras reintentos (UserId=%d), usando defaults sin cachear"):format(userId))
        return Config.CloneDefaults()
    end
end

--[[
	Guarda lo que haya en caché para el jugador. Devuelve true si persistió.
	Si no hay caché (jugador nunca cargó), devuelve false sin escribir.
]]
function PlayerDataStore.save(player: Player): boolean
    local userId = player.UserId
    local cached = Cache[userId]
    if cached == nil then
        return false
    end
    local sanitized: PlayerData = {
        Version = Config.DATA_VERSION,
        Coins = Config.ClampStat(cached.Coins),
        Wins = Config.ClampStat(cached.Wins),
    }
    Cache[userId] = CopyData(sanitized)
    return UpdateWithRetry(Config.GetKey(userId), sanitized)
end

--[[
	Lectura caliente de la caché. Devuelve una copia o nil si no hay entrada.
]]
function PlayerDataStore.getCached(userId: number): PlayerData?
    local cached = Cache[userId]
    if cached == nil then
        return nil
    end
    return CopyData(cached)
end

--[[
	Escribe la caché (sanitizando). Lo usa LeaderstatsService tras cada grant
	y el orquestador antes de save() para persistir valores vivos de leaderstats.
]]
function PlayerDataStore.setCached(userId: number, data: PlayerData): ()
    Cache[userId] = {
        Version = Config.DATA_VERSION,
        Coins = Config.ClampStat(data.Coins),
        Wins = Config.ClampStat(data.Wins),
    }
end

--[[
	Libera la caché del jugador. Llamar tras el save de PlayerRemoving.
]]
function PlayerDataStore.clearCache(userId: number): ()
    Cache[userId] = nil
end

return PlayerDataStore
