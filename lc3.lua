if _G._VERSION ~= "Lua 5.4" and _G._VERSION ~= "Lua 5.3" then
    print("LC-3 does not support lua version < 5.3")
    return false
end

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
    if type(digits) ~= "number" or digits <= 1 or digits > 32 or floor(digits) ~= digits then
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
        if type(data) ~= "number" or floor(data) ~= data then
            print("Data must be a in range 0x0000 ~ 0xffff, but received " .. tostring(data))
            return false
        end
        if data > 0xffff or data < 0x0000 then
            data = utils.parse2sCompliment(utils.encode2sCompliment(data, 21):sub(-16, -1))
        end
        self[addr] = floor(data)
        return true
    end
    function lc3:getRegister(reg)
        if type(reg) ~= "string" or not(self[reg]) then
            print("Register doesn't exist: " .. tostring(reg))
            return false
        end
        return self[reg]
    end
    function lc3:setRegister(reg, data)
        if type(reg) ~= "string" or not(self[reg]) then
            print("Register doesn't exist: " .. tostring(reg))
            return false
        end
        if type(data) ~= "number" or floor(data) ~= data then
            print("Data must be a in range 0x0000 ~ 0xffff, but received " .. tostring(data))
            return false
        end
        if data > 0xffff or data < 0x0000 then
            data = utils.parse2sCompliment(utils.encode2sCompliment(data, 21):sub(-16, -1))
        end
        self[reg] = floor(data)
    end
    function lc3:step()
        self.IR = self:getMemory(self.PC)
        self.PC = self.PC + 1
        local s = self.IR
        local s, t = utils.decToBase(s, 2) -- s = "0101010010100000", t = {'0', '1', '0', '1', ..., '0', '0'}
        s = string.rep('0', 16 - #s) .. s
        local opcode = s:sub(1, 4)
        local function toReg(s)
            return 'R'..tonumber(s, 2)
        end
        local function sub(str, id)
            return str:sub(id, id)
        end
        local function updateCC(value)
            print(value)
            local seg = 0x7fff
            if value > seg then
                self.CC = 'n'
            elseif value == 0 then
                self.CC = 'z'
            else
                self.CC = 'p'
            end
        end
        if opcode == "0001" then
            -- ADD
            if sub(s, 11) == '0' then
                -- ADD R1, R2, R3
                local dst = toReg(s:sub(5, 7))
                local src1 = toReg(s:sub(8, 10))
                local src2 = toReg(s:sub(14, 16))
                local res = self:getRegister(src1) + self:getRegister(src2)
                self:setRegister(dst, res)
                updateCC(self:getRegister(dst))
            else
                -- ADD R1, R2, #-1
                local dst = toReg(s:sub(5, 7))
                local src = toReg(s:sub(8, 10))
                local imm = utils.parse2sCompliment(s:sub(12, 16))
                local res = self:getRegister(src) + imm
                self:setRegister(dst, res)
                updateCC(self:getRegister(dst))
            end
        elseif opcode == "0101" then
            -- AND
            if sub(s, 11) == '0' then
                -- ADD R1, R2, R3
                local dst = toReg(s:sub(5, 7))
                local src1 = toReg(s:sub(8, 10))
                local src2 = toReg(s:sub(14, 16))
                local res = self:getRegister(src1) & self:getRegister(src2)
                self:setRegister(dst, res)
                updateCC(self:getRegister(dst))
            else
                -- ADD R1, R2, #-1
                local dst = toReg(s:sub(5, 7))
                local src = toReg(s:sub(8, 10))
                local imm = utils.parse2sCompliment(s:sub(12, 16))
                local res = self:getRegister(src) & imm
                self:setRegister(dst, res)
                updateCC(self:getRegister(dst))
            end
        elseif opcode == "0000" then
            -- BR
            if (sub(s, 5) == '1' and self.CC == 'n') or (sub(s, 6) == '1' and self.CC == 'z') or (sub(s, 7) == '1' and self.CC == 'p') then
                self.PC = self.PC + utils.parse2sCompliment(s:sub(8, 16))
            end
        elseif opcode == "1100" then
            -- JMP

        elseif opcode == "0100" then
            -- JSR / JSRR

        elseif opcode == "0010" then
            -- LD

        elseif opcode == "1010" then
            -- LDI

        elseif opcode == "0110" then
            -- LDR
            local baseR = toReg(s:sub(8, 10))
            local dst = toReg(s:sub(5, 7))
            local offset = utils.parse2sCompliment(s:sub(11, 16))
            local mem = self:getMemory(self:getRegister(baseR) + offset)
            self:setRegister(dst, mem)
            updateCC(self:getRegister(dst))
        elseif opcode == "1110" then
            -- LEA
            local offset = utils.parse2sCompliment(s:sub(8, 16))
            local dst = toReg(s:sub(5, 7))
            local res = self.PC + offset
            self:setRegister(dst, res)
            updateCC(self:getRegister(dst))
        elseif opcode == "1001" then
            -- NOT
            local dst = toReg(s:sub(5, 7))
            local src = toReg(s:sub(8, 10))
            local res = tonumber(0xffff - self:getRegister(src))
            self:setRegister(dst, res)
            updateCC(self:getRegister(dst))
        elseif opcode == "1100" then
            -- RET

        elseif opcode == "1000" then
            -- RTI

        elseif opcode == "0011" then
            -- ST
            local src = toReg(s:sub(5, 7))
            local offset = utils.parse2sCompliment(s:sub(8, 16))
            local res = self:getMemory(src)
            self:setMemory(self.PC + offset, res)
        elseif opcode == "1011" then
            -- STI
            local src = toReg(s:sub(5, 7))
            local offset = utils.parse2sCompliment(s:sub(8, 16))
            local res = self:getRegister(src)
            local addr = self:getMemory(self.PC + offset)
            self:setMemory(addr, res)
        elseif opcode == "0111" then
            -- STR

        elseif opcode == "1111" then
            -- TRAP
            local trapvec = utils.parse2sCompliment(s:sub(9, 16))
            if trapvec == 0x25 then
                print("Program halted")
                os.exit()
            end
        elseif opcode == "1101" then
            -- Reserved

        end
    end
    function lc3:getState()
        return {
            R0 = self.R0,
            R1 = self.R1,
            R2 = self.R2,
            R3 = self.R3,
            R4 = self.R4,
            R5 = self.R5,
            R6 = self.R6,
            R7 = self.R7,
            PC = self.PC,
            IR = self.IR,
            PSR= self.PSR,
            CC = self.CC
        }
    end
    return lc3
end

return LC3, utils
