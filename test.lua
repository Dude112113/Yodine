-- used to test yolol parser when developing stuff for it

--[[
function debug.relabelDbgFilter(ruleName)
	local bl = {
		Sp=true
	}
	return bl[ruleName] ~= true and #ruleName > 1
end
--]]

local re = require "relabel"
local yolol = require "yolol"
-- local yololVM = require "yololVM"

local input = [[
a% %
]]
local result = yolol.parse(input)

print("Took " .. tostring(result.totalParseTime) .. "s odd to parse.")

print()
local errors = {}
for i, line in ipairs(result.program.lines) do
	for _, err in ipairs(line.metadata.errors) do
		table.insert(errors, err)
	end
end
if #errors > 0 then
	print(tostring(#errors) .. " errors reported.")
	for i, v in ipairs(errors) do
		local ln, col = re.calcline(input, v.pos)
		print(tostring(ln) .. ":" .. tostring(col) .. " " .. v.msg)
	end
else
	print("No errors reported.")
end
print()
if result ~= nil then
	print("Parsed data.")
	print("AST")
	yolol.helpers.printAST(result.program, "   |")
	print()
	print("Checking and calculating any statment expression's.")
	for i, line in pairs(result.program.lines) do
		if line.code ~= nil and #line.code == 1 then
			local v = line.code[1]
			if type(v) == "table" and v.type == "expression" then
				local ok, calcResult = pcall(yolol.helpers.calc, v.expression)
				if not ok then
					calcResult = calcResult:gsub(".*:%d+:", ""):gsub("^ *", "")
				end
				print("Calc ln " .. yolol.helpers.strValueFromType(i) .. ":", tostring(calcResult))
			end
		end
	end
	-- print(); print(yolol.helpers.serializeTable(result.ast))
else
	print("No parsed data.")
end

-- local vm = yololVM.new(nil, result.program.lines)

-- print("Running in VM (external variables will raise errors)")
-- local start = os.clock()
-- for i=1,#vm.lines*1 do
-- 	i = i + 1
-- 	vm:step()
-- end
-- local finish = os.clock()
-- print("Took " .. tostring(finish - start) .. "s to run.")

-- print("Errors")
-- for ln, errors in ipairs(vm.errors) do
-- 	for _, err in ipairs(errors) do
-- 		print("Error on line: " .. tostring(ln))
-- 		print(err.msg)
-- 	end
-- end

-- if vm.variables.result ~= nil then
-- 	print("VM `Result` variable: " .. yolol.helpers.strValueFromType(vm.variables.result))
-- end

print("Exit.")
os.exit()
