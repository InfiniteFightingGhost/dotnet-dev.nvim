local output = vim.system({ "dotnet", "new", "list" }, { text = true }):wait()
local file = io.open(vim.fn.stdpath("data") .. "/templates.txt", "w+")
if file ~= nil then
	local index = -1
	local lines = vim.split(output.stdout, "\n")
	for i, line in ipairs(lines) do
		if line == nil then
			break
		end
		if vim.startswith(line, "------") then
			index = i
			break
		end
	end
	local result = ""
	for i = index + 1, #lines, 1 do
		result = result .. lines[i] .. "\n"
	end
	local lengths = { nil }
	for _, item in ipairs(vim.split(lines[index], "  ", { plain = true })) do
		table.insert(lengths, #item)
	end
	local lengthFile = io.open(vim.fn.stdpath("data") .. "lengths.txt", "w+")
	if lengthFile ~= nil then
		lengthFile:write(table.concat(lengths, "|"))
		lengthFile:flush()
		lengthFile:close()
	end
	file:write(result)
	file:flush()
	file:close()
end
