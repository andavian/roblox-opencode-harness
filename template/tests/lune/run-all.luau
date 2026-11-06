--!strict
--[[
	run-all
	Punto de entrada del harness Lune: ejecuta todos los tests,
	imprime "PASS n / FAIL m" y sale con código 1 si hay fallos
	(o si no se ejecutó ningún test).
]]

local Process = require("@lune/process")
local Assert = require("./assert")

require("./test-smoke")

local passed, failed = Assert.results()
print(`PASS {passed} / FAIL {failed}`)
Assert.summary()

if failed > 0 then
    Process.exit(1)
end
if passed == 0 then
    print("FAIL - no se ejecutó ningún test")
    Process.exit(1)
end
