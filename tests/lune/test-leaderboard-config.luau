--!strict
--[[
	test-leaderboard-config
	Tests puros de LeaderboardConfig (módulo sin game:/Instance/task).

	Se ejecuta al hacer require desde run-all.luau y acumula
	aserciones en ./assert. Cada assert lleva mensaje único.
]]

local Config = require("../../src/shared/LeaderboardConfig")
local Assert = require("./assert")

-- Constantes del esquema --
Assert.assertEquals(Config.STORE_NAME, "PlayerStats_v1", "const STORE_NAME es PlayerStats_v1")
Assert.assertEquals(Config.DATA_VERSION, 1, "const DATA_VERSION es 1")
Assert.assertEquals(Config.AUTOSAVE_INTERVAL_SECONDS, 300, "const AUTOSAVE_INTERVAL_SECONDS es 300")
Assert.assertEquals(Config.MAX_RETRIES, 3, "const MAX_RETRIES es 3")
Assert.assertTableEquals(Config.BACKOFF_DELAYS, { 1, 2, 4 }, "const BACKOFF_DELAYS es {1,2,4}")
Assert.assertEquals(Config.MAX_STAT_VALUE, 999999999, "const MAX_STAT_VALUE es 999999999")
Assert.assertTableEquals(Config.LEADERSTATS, { "Coins", "Wins" }, "const LEADERSTATS es {Coins,Wins}")

-- GetKey --
Assert.assertEquals(Config.GetKey(123), "player_123", "GetKey(123) es player_123")
Assert.assertEquals(Config.GetKey(0), "player_0", "GetKey(0) es player_0")
Assert.assertEquals(Config.GetKey(1), "player_1", "GetKey(1) es player_1")

-- CloneDefaults: valores --
local clone = Config.CloneDefaults()
Assert.assertEquals(clone.Version, Config.DATA_VERSION, "CloneDefaults Version es DATA_VERSION")
Assert.assertEquals(clone.Coins, 0, "CloneDefaults Coins es 0")
Assert.assertEquals(clone.Wins, 0, "CloneDefaults Wins es 0")
Assert.assertTableEquals(
    clone,
    { Version = Config.DATA_VERSION, Coins = 0, Wins = 0 },
    "CloneDefaults tabla iguala defaults versionados"
)

-- CloneDefaults: copia profunda (no alias de DEFAULT_DATA ni entre clones) --
Assert.assertTrue(clone ~= (Config.DEFAULT_DATA :: any), "CloneDefaults no aliasa DEFAULT_DATA")
local cloneA = Config.CloneDefaults()
local cloneB = Config.CloneDefaults()
Assert.assertTrue((cloneA :: any) ~= (cloneB :: any), "CloneDefaults dos clones son tablas distintas")
cloneA.Coins = 999
Assert.assertEquals(cloneB.Coins, 0, "CloneDefaults mutar un clon no afecta a otro")
Assert.assertEquals(Config.DEFAULT_DATA.Coins, 0, "CloneDefaults mutar un clon no afecta a DEFAULT_DATA")

-- ClampStat: floor + clamp 0..MAX --
Assert.assertEquals(Config.ClampStat(5.9), 5, "ClampStat 5.9 floorea a 5")
Assert.assertEquals(Config.ClampStat(-10), 0, "ClampStat -10 clamp a 0")
Assert.assertEquals(Config.ClampStat(0), 0, "ClampStat 0 queda en 0")
Assert.assertEquals(Config.ClampStat(Config.MAX_STAT_VALUE), Config.MAX_STAT_VALUE, "ClampStat MAX queda en MAX")
Assert.assertEquals(
    Config.ClampStat(Config.MAX_STAT_VALUE + 5000),
    Config.MAX_STAT_VALUE,
    "ClampStat MAX+5000 clamp a MAX"
)
Assert.assertEquals(Config.ClampStat(0 / 0), 0, "ClampStat NaN va a 0")
Assert.assertEquals(Config.ClampStat(math.huge), Config.MAX_STAT_VALUE, "ClampStat inf va a MAX")
Assert.assertEquals(Config.ClampStat(-math.huge), 0, "ClampStat -inf va a 0")

return nil
