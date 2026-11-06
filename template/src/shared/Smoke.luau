--!strict
--[[
    Smoke
    Módulo de humo mínimo para que el scaffold tenga al menos un archivo
    Luau real y luau-lsp pueda analizar src/ sin fallar.
]]

local Smoke = {}

function Smoke.hello(): string
    return "smoke"
end

return Smoke
