local function SaveTemplatesToJsonFile(templates)
	local fileJson = io.open(vim.fn.stdpath("data") .. "/templates.json", "w+")
	if not fileJson then
		return
	end
	fileJson:write(vim.fn.json_encode(templates))
	fileJson:flush()
	fileJson:close()
end

local function GenerateTemplatesFromDotnet()
	local output = vim.system({ "dotnet", "new", "list" }, { text = true }):wait()
	local lines = vim.split(output.stdout, "\n")
	local thingy = vim.split(lines[4], "  ", { plain = true })
	Lengths = { nil }
	Lengths[1] = #thingy[1]
	Lengths[2] = #thingy[2]
	Lengths[3] = #thingy[3]
	Lengths[4] = #thingy[4]
	return lines
end

local function GetTemplatesFromJsonFile()
	local fileJson = io.open(vim.fn.stdpath("data") .. "/templates.json", "r+")
	if not fileJson then
		GetTemplates(GenerateTemplatesFromDotnet())
		return
	end
	local lines = fileJson:read("*a")
	fileJson:close()
	return vim.fn.json_decode(lines)
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
			template.Name, template.Shorthand, template.Languages, template.Tags = string.match(
				line,
				"("
					.. string.rep(".", Lengths[1])
					.. ")  ("
					.. string.rep(".", Lengths[2])
					.. ")  ("
					.. string.rep(".", Lengths[3])
					.. ")  ("
					.. string.rep(".", Lengths[4])
					.. ")"
			)
			print(vim.inspect(template.Name))
			if not Templates then
				Templates = { template }
			end
			table.insert(Templates, template)
		end
	end
	SaveTemplatesToJsonFile(Templates)
end

vim.api.nvim_create_user_command("GetDotnetTemplates", function()
	local lines = GenerateTemplatesFromDotnet()
	GetTemplates(lines)
end, {})

require("dotnet-dev.visual")
GetTemplates(nil)
