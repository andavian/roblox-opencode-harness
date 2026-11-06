--!strict
--[[
	LeaderboardConfig
	Tipos y constantes puras del sistema de leaderboard.

	Sin estado, sin game:GetService, sin efectos secundarios.
	La validación con tipos y los reintentos viven en PlayerDataStore;
	aquí solo hay datos y helpers puros.
]]

export type PlayerData = {
    Version: number,
    Coins: number,
    Wins: number,
}

local LeaderboardConfig = {}

--- Nombre del DataStore global (versionado por sufijo).
LeaderboardConfig.STORE_NAME = "PlayerStats_v1"
--- Versión del esquema de datos. Subir al cambiar el formato.
LeaderboardConfig.DATA_VERSION = 1
--- Intervalo de autosave en segundos.
LeaderboardConfig.AUTOSAVE_INTERVAL_SECONDS = 300
--- Número de intentos por operación de DataStore (1 inicial + reintentos).
LeaderboardConfig.MAX_RETRIES = 3
--- Backoff entre reintentos, indexado por intento (1/2/4 segundos).
LeaderboardConfig.BACKOFF_DELAYS = { 1, 2, 4 }
--- Techo de cada stat (leaderstats usa IntValue; evita desbordes).
LeaderboardConfig.MAX_STAT_VALUE = 999999999
--- Nombres oficiales de leaderstats, en orden de creación.
LeaderboardConfig.LEADERSTATS = { "Coins", "Wins" }

--- Defaults versionados para jugadores nuevos o datos corruptos.
LeaderboardConfig.DEFAULT_DATA = {
    Version = LeaderboardConfig.DATA_VERSION,
    Coins = 0,
    Wins = 0,
}

--[[
	Construye la clave de DataStore para un UserId.
	Formato: "player_<UserId>".
]]
function LeaderboardConfig.GetKey(userId: number): string
    return "player_" .. tostring(userId)
end

--[[
	Devuelve una copia fresca de los defaults.
	Evita mutar DEFAULT_DATA por referencia entre jugadores.
]]
function LeaderboardConfig.CloneDefaults(): PlayerData
    local defaults = LeaderboardConfig.DEFAULT_DATA
    return {
        Version = LeaderboardConfig.DATA_VERSION,
        Coins = defaults.Coins,
        Wins = defaults.Wins,
    }
end

--[[
	Normaliza un número a stat válido: floor + clamp 0..MAX_STAT_VALUE.
	NaN e infinitos se convierten a 0 / techo en vez de propagarse.
]]
function LeaderboardConfig.ClampStat(value: number): number
    if value ~= value then
        return 0
    end
    if value == math.huge then
        return LeaderboardConfig.MAX_STAT_VALUE
    end
    if value == -math.huge then
        return 0
    end
    return math.clamp(math.floor(value), 0, LeaderboardConfig.MAX_STAT_VALUE)
end

return LeaderboardConfig
