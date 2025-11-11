local M = {}

local components = {}

local function LoadComponents()
	local fileJson, err = io.open("C:/Users/11B_19/plugins/dotnet-dev.nvim/lua/dotnet-dev/all-components.json", "r+")
	if not fileJson then
		print(err)
		return nil
	end
	local lines = fileJson:read("*a")
	fileJson:close()
	components = vim.fn.json_decode(lines)
	return components
end

function M.ReturnAllComponents()
	local result = {}
	for _, value in pairs(components) do
		table.insert(result, value["Name"])
	end
	return result
end

---@param component table
local function ShowComponentProperties(component)
	local name = component.Name
	local categories = {}
	local properties = {}
	for index, category in pairs(component.Categories) do
		for _, item in pairs(category) do
			local component_values = {
				name = item.Name,
				default = item.DefaultValue,
				desc = item.Description,
			}
			if properties == nil then
				properties = component_values
			else
				table.insert(properties, component_values)
			end
		end
		if properties == nil then
			categories = properties
		else
			table.insert(categories, properties)
		end
		properties = {}
	end
	print(vim.inspect(categories))
end

---@param item table
local function PrintInfo(item) end
vim.keymap.set("n", "<leader>om", function()
	vim.ui.select(components, {
		prompt = "WinForms components",
		format_item = function(item)
			return item.Name
		end,
	}, function(choice)
		-- print(vim.inspect(choice.Categories))
		if choice ~= nil then
			ShowComponentProperties(choice)
		end
	end)
end)

LoadComponents()

-- print(vim.inspect(M.ReturnAllComponents()))

return M
