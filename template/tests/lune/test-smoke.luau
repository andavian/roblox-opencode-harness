--!strict
--[[
	test-smoke
	Test de humo puro: no usa game:, Instance ni task.
	Solo verifica que el harness de aserciones funciona.
]]

local Assert = require("./assert")

Assert.assertEquals(1 + 1, 2, "suma básica funciona")

return nil
