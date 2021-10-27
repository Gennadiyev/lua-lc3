local lc3Factory, utils = require("lc3")
local lc3 = lc3Factory:new()
local lc3Utils = require("lc3-utils")
local json = require("json")

local fibProgram = io.open("tests/fibonacci-lc3.hex", "r"):read("*a")
lc3 = lc3Utils.loadHexProgram(
    lc3,
    fibProgram,
    0x3000
)

lc3:setMemory(0x3014, 0x0008)

while true do
    local l = io.read()
    if l == "" then
        lc3:step()
        local t = lc3:getState()
        print(string.format("R0=x%04x\tR1=x%04x\tR2=x%04x\tR3=x%04x\nR4=x%04x\tR5=x%04x\tR6=x%04x\tR7=x%04x\nPC=x%04x\tIR=x%04x\tCC=%s",
            t.R0, t.R1, t.R2, t.R3, t.R4, t.R5, t.R6, t.R7, t.PC, t.IR, t.CC))
        print(string.format("\nx3015: x%04x\n", lc3:getMemory(0x3015)))
    end
end
