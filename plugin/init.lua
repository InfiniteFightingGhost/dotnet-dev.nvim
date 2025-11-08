Templates = { nil }

local function SaveTemplatesToJsonFile(templates)
	local fileJson = io.open(vim.fn.stdpath("data") .. "/templates.json", "w+")
	if not fileJson then
		return
	end
	fileJson:write(vim.fn.json_encode(templates))
	fileJson:flush()
	fileJson:close()
end

local function GetTemplatesFromJsonFile()
	local fileJson = io.open(vim.fn.stdpath("data") .. "/templates.json", "r+")
	if not fileJson then
		return
	end
	local lines = fileJson:read("*a")
	fileJson:close()
	return vim.fn.json_decode(lines)
end

function GenerateTemplatesFromDotnet()
	local output = vim.system({ "dotnet", "new", "list" }, { text = true }):wait()
	local index = -1
	local lines = vim.split(output.stdout, "\n")
	for i, line in ipairs(lines) do
		if line == nil then
			break
		end
		if vim.startswith(line, "-") then
			index = i
			break
		end
	end
	Lengths = { nil }
	for _, item in ipairs(vim.split(lines[index], "  ", { plain = true })) do
		table.insert(Lengths, #item)
	end
	return lines
end

---@param lines string[]|nil
function GetTemplates(lines)
	Templates = { nil }
	if not lines then
		Templates = GetTemplatesFromJsonFile()
		return
	end
	for i = 5, #lines, 1 do
		local line = lines[i]
		if line ~= "" then
			local template = {
				Name = "",
				Shorthand = "",
				Languages = "",
				Tags = "",
			}
			local curr = Lengths[1]
			template.Name = string.sub(line, 1, curr)
			curr = curr + 3 + Lengths[2]
			template.Shorthand = string.sub(line, curr - Lengths[2], curr)
			curr = curr + 2 + Lengths[3]
			template.Languages = string.sub(line, curr - Lengths[3], curr)
			curr = curr + 2 + Lengths[4]
			template.Tags = string.sub(line, curr - Lengths[4], curr)
			-- template.Name, template.Shorthand, template.Languages, template.Tags = string.gmatch(line, "(.{" .. Lengths[1] .. "]})-(.{" .. Lengths[2] .. "]})-(.{" .. Lengths[3] .. "]})-(.{" .. Lengths[4] .. "]})")
			-- Idk if this works, but the first is cleaner anyway
			if not Templates then
				Templates = { template }
			end
			table.insert(Templates, template)
		end
	end
	-- print(vim.inspect(Templates))
	SaveTemplatesToJsonFile(Templates)
end

vim.api.nvim_create_user_command("GetDotnetTemplates", function()
	local lines = GenerateTemplatesFromDotnet()
	print(vim.inspect(lines))
	GetTemplates(lines)
end, {})

GetTemplates(nil)
