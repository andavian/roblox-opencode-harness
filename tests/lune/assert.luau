--!strict
--[[
	assert
	Mini-harness de aserciones para tests Lune (sin TestEZ ni Wally).

	Uso:
		local Assert = require("./assert")
		Assert.assertEquals(1 + 1, 2, "suma básica")
		Assert.summary() -- imprime resumen, devuelve nº de fallos
]]

local Assert = {}

local passed = 0
local failed = 0
local failures: { string } = {}

local function record(ok: boolean, message: string, detail: string?): ()
    if ok then
        passed += 1
        print("ok - " .. message)
    else
        failed += 1
        local line = "FAIL - " .. message
        if detail ~= nil then
            line ..= " | " .. detail
        end
        table.insert(failures, line)
        print(line)
    end
end

local function toDetail(actual: any, expected: any): string
    return "esperado=" .. tostring(expected) .. " actual=" .. tostring(actual)
end

--[[
	Compara con == (números, strings, booleanos).
]]
function Assert.assertEquals(actual: any, expected: any, message: string): ()
    record(actual == expected, message, toDetail(actual, expected))
end

--[[
	Exige valor verdadero.
]]
function Assert.assertTrue(value: boolean, message: string): ()
    record(value == true, message, "esperado=true actual=" .. tostring(value))
end

local function tablesEqual(a: any, b: any): boolean
    if a == b then
        return true
    end
    if typeof(a) ~= "table" or typeof(b) ~= "table" then
        return false
    end
    local aTable: { [any]: any } = a
    local bTable: { [any]: any } = b
    for key, aValue in aTable do
        local bValue = bTable[key]
        if bValue == nil and aValue ~= nil then
            return false
        end
        if not tablesEqual(aValue, bValue) then
            return false
        end
    end
    for key, _ in bTable do
        if aTable[key] == nil then
            return false
        end
    end
    return true
end

--[[
	Compara tablas por contenido (recursivo, orden-independiente en dicts).
]]
function Assert.assertTableEquals(actual: any, expected: any, message: string): ()
    local ok = tablesEqual(actual, expected)
    local detail: string? = nil
    if not ok then
        detail = "tablas distintas (ver FAIL anterior o inspeccionar valores)"
    end
    record(ok, message, detail)
end

--[[
	Devuelve (passed, failed) acumulados.
]]
function Assert.results(): (number, number)
    return passed, failed
end

--[[
	Imprime resumen y devuelve el nº de fallos (para exit code).
]]
function Assert.summary(): number
    print(`-- resumen: PASS {passed} / FAIL {failed} --`)
    if failed > 0 then
        print("fallos:")
        for _, line in failures do
            print("  " .. line)
        end
    end
    return failed
end

return Assert
