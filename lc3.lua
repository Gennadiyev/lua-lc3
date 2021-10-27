local LC3 = {}

function LC3:new() -- Creates a new `lc-3` instance
    local lc3 = {
        R0 = 0x0000,
        R1 = 0x0000,
        R2 = 0x0000,
        R3 = 0x0000,
        R4 = 0x0000,
        R5 = 0x0000,
        R6 = 0x0000,
        R7 = 0x0000,
        PC = 0x3000,
        IR = 0x0000,
        PSR= 0x8002,
        CC = 'n',
    }
    -- Initialize
    lc3[0xfffe] = 0xffff,
    for i = 0x0000, 0x00fe do
        lc3[i] = 0xfd00
    end
    lc3[0x0020] = 0x0400
    lc3[0x0021] = 0x0430
    lc3[0x0022] = 0x0450
    lc3[0x0023] = 0x04a0
    lc3[0x0024] = 0x04e0
    lc3[0x0025] = 0xfd70
    function lc3:getMemory(addr)
        if type(addr) ~= "number" or math.floor(addr) ~= addr then
            print("Accessing non-integer memory: " .. tostring(addr))
            return false
        end
        if addr > 0xffff or addr < 0x0000 then
            print("Accessing memory out of bounds: " .. tostring(addr))
            return false
        end
        return self[addr] or 0x0000
    end
    function lc3:setMemory(addr, data)
        if type(addr) ~= "number" or math.floor(addr) ~= addr then
            print("Writing to non-integer memory: " .. tostring(addr))
            return false
        end
        if addr > 0xffff or addr < 0x0000 then
            print("Writing memory out of bounds: " .. tostring(addr))
            return false
        end
        if data ~= "number" or math.floor(data) ~= data or data < 0 then
            print("Data must be a in range 0x0000 ~ 0xffff, but received " .. tostring(data))
            return false
        end
        self[addr] = data
        return true
    end
    function lc3:getRegister(reg)
        if type(reg) ~= "string" or not(self[reg]) then
            print("Register doesn't exist: " .. reg)
            return false
        end
        return self[reg]
    end
    function lc3:setRegister(reg, data)
        if type(reg) ~= "string" or not(self[reg]) then
            print("Register doesn't exist: " .. reg)
            return false
        end
        if data ~= "number" or math.floor(data) ~= data or data < 0 then
            print("Data must be a in range 0x0000 ~ 0xffff, but received " .. tostring(data))
            return false
        end
        self[reg] = data
    end
    return lc3
end

return LC3
