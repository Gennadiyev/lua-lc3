local lc3utils = {}

local function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function lc3utils.loadHexProgram(lc3, programString, pc) -- Load a program to lc-3
    local lc3NewState = deepcopy(lc3)
    if not(pc) or type(pc) ~= "number" or pc > 0xffff or pc < 0x0000 or math.floor(pc) ~= pc then
        print("Will load program to x3000")
        pc = 0x3000
    end
    -- Remove whitespaces in programString
    programString = string.gsub(programString, "%s", "")
    if #programString % 4 ~= 0 then
        print("The program has length not divisable by 4 and cannot be loaded")
        return false
    end
    local line = 0
    for i = 1, #programString, 4 do
        line = line + 1
        local s = tonumber(programString:sub(i, i + 3), 16)
        if not(s) then
            print(string.format("Cannot load line %d: %s", line, programString:sub(i, i+3)))
            return false
        else
            lc3NewState:setMemory(pc + line - 1, s)
        end
    end
    lc3 = lc3NewState
end

return lc3utils
