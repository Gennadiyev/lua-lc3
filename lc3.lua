local floor,insert = math.floor, table.insert
local LC3 = {}

local utils = {}

function utils.parse2sCompliment(str) -- Parse a string format 2's complement and returns its decimal value
    if type(str) ~= "string" and #str <= 1 then
        print("Attempt to parse an invalid 2's compliment: " .. tostring(str))
        return false
    end
    local dec = 0
    for i = #str, 2, -1 do
        dec = dec + 2 ^ (#str - i) * tonumber(str:sub(i, i))
    end
    dec = dec - 2 ^ (#str - 1) * tonumber(str:sub(1, 1))
    return dec
end

function utils.decToBase(n, b) -- Encodes a decimal to any base
    if type(n) ~= "number" or floor(n) ~= n then
        print("Cannot convert non-integer value: "..tostring(n))
        return false
    end
    if type(b) ~= "number" or b < 0 or b > 36 or b ~= floor(b) then
        print("Cannot convert to non-positive integer base: "..tostring(b))
        return false
    end
    if b == 10 then return tostring(n) end
    local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local t = {}
    local sign = ""
    if n < 0 then
        sign = "-"
        n = -n
    end
    repeat
        local d = (n % b) + 1
        n = floor(n / b)
        insert(t, 1, digits:sub(d,d))
    until n == 0
    return sign .. table.concat(t,""), t
end
    

function utils.encode2sCompliment(dec, digits) -- Encodes a decimal to 2's complement
    if type(digits) ~= "number" or digits <= 1 or digits > 16 or floor(digits) ~= digits then
        print("Cannot encode number to invalid digit count: "..tostring(digits))
        return false
    end
    if type(dec) ~= "number" or math.abs(dec) > 2 ^ (digits - 1) or floor(dec) ~= dec then
        print("Encode target invalid or out-of-range: "..tostring(dec))
        return false
    end
    if dec < 0 then
        local _, v = utils.decToBase(-dec-1, 2)
        for i = 1, #v do
            v[i] = 1 - v[i]
        end
        local s = table.concat(v, '')
        if #s < digits - 1 then
            s = string.rep('1', digits - 1 - #s)..s
        end
        return '1' .. s
    else
        local s = utils.decToBase(dec, 2)
        if #s < digits - 1 then
            s = string.rep('0', digits - 1 - #s)..s
        end
        return '0' .. s
    end
end

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
    lc3[0xfffe] = 0x8000 -- According to the official lc3sim
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
        if type(addr) ~= "number" or floor(addr) ~= addr then
            print("Writing to non-integer memory: " .. tostring(addr))
            return false
        end
        if addr > 0xffff or addr < 0x0000 then
            print("Writing memory out of bounds: " .. tostring(addr))
            return false
        end
        if data ~= "number" or floor(data) ~= data or data < 0 then
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
        if data ~= "number" or floor(data) ~= data or data < 0 then
            print("Data must be a in range 0x0000 ~ 0xffff, but received " .. tostring(data))
            return false
        end
        self[reg] = data
    end
    function lc3:step()
        self.IR = self:getMemory(self.PC)
    end
    return lc3
end

return LC3
