local M = {}

local BUILDCOMMAND = "dotnet build"
local RUNCOMMAND = "dotnet run"
local ADDPROJECTCOMMAND = "dotnet new"
local defaults = {
	defaultProjectDirectory = "~/Projects",
	menuBorder = "rounded",
	menuSize = {
		height = 20,
		width = 50,
	},
	inputWidth = 30,
	inputBorder = "rounded",
}
---@return string  --returns the root directory taken from the lsp
local function GetLspCwd()
	local winnr = vim.fn.winnr()
	local tabnr = vim.fn.tabpagenr()
	local lsp_dir = vim.lsp.buf.list_workspace_folders()[1]
	return lsp_dir or vim.fn.getcwd(winnr, tabnr)
end

---@param namespace string
---@param name string
local function GenerateCSBoilerplate(namespace, name)
	return {
		"namespace " .. namespace,
		"{",
		"  internal class " .. name,
		"  {",
		"    ",
		"  }",
		"}",
	}
end

---@param cwd string
---@return string
local function GetNamespace(cwd, directoriesFromCwd) -- #TODO make this function work
	local path = vim.split(cwd, "/", { plain = true })
	if #directoriesFromCwd == 1 then
		return path[#path]
	end
	local directories = {}
	for index, value in ipairs(directoriesFromCwd) do
		if index ~= #directoriesFromCwd then
			table.insert(directories, value)
		else
			break
		end
		return path[#path] .. "." .. table.concat(directories, ".")
	end
end

---@param name string
local function MakeFile(name)
	if name ~= nil then
		local newFile = vim.split(name, "/", { plain = true })
		local cwd = GetLspCwd()

		if newFile[#newFile] == "" then
			local dir = ""
			if table.concat(newFile, "/", 1, #newFile - 2) ~= "" then
				dir = table.concat(newFile, "/", 1, #newFile - 2)
			end
			dir = cwd .. "/" .. dir
			if vim.fn.finddir(newFile[#newFile - 1], dir) == "" then
				vim.fn.mkdir(name, "p")
			else
				print("There already exists a directory with name: " .. newFile[#newFile - 1])
			end
		else
			local fileName = newFile[#newFile]
			local dir = ""
			if table.concat(newFile, "/", 1, #newFile - 1) ~= "" then
				dir = table.concat(newFile, "/", 1, #newFile - 1)
			end
			dir = cwd .. "/" .. dir
			print(dir)
			if vim.fn.findfile(fileName, dir) == "" then
				vim.cmd("e " .. cwd .. "/" .. name)
				vim.cmd("write ++p")
				local namespace = GetNamespace(cwd, newFile)

				local projectName, _ = newFile[#newFile]:match("([^.]*).(.*)")
				vim.api.nvim_put(GenerateCSBoilerplate(namespace, projectName), "l", false, false)
			else
				print("There already exists a file with name: " .. fileName)
			end
		end
	end
end

local function BuildProject()
	local dir = GetLspCwd()
	return BUILDCOMMAND, dir
end

local function RunProject()
	local dir = GetLspCwd()
	return RUNCOMMAND, dir
end

---@param command string the command to run
---@param dir string where to run the command
local function RunCommandInTerminal(command, dir)
	-- create a scratch buffer used to emulate the terminal
	local bufnr = vim.api.nvim_create_buf(true, false)

	-- set the current buffer to the buffer we created
	vim.api.nvim_set_current_buf(bufnr)

	--exececute the dotnet command in that buffer
	vim.fn.jobstart(command, {
		term = true,
		cwd = dir,
	})
end

--has to take in name of the project and the template name for it

---@param action integer the id of the command to run
function ChooseAction(action)
	if action == 1 then
		RunCommandInTerminal(RunProject())
	elseif action == 2 then
		RunCommandInTerminal(BuildProject())
	elseif action == 3 then
		GetUserFileOrDirectory()
	elseif action == 4 then
		ChooseTemplate(1)
	elseif action == 5 then
		ChooseTemplate(2)
	end
end

local function CreateMenu()
	local Menu = require("nui.menu")

	local menu = Menu({
		position = "50%",
		size = defaults.menuSize,

		border = {
			style = defaults.menuBorder,
			text = {
				top = "[Choose an action]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		lines = {
			Menu.item("Run project", { id = 1 }),
			Menu.item("Build project", { id = 2 }),
			Menu.item("New file", { id = 3 }),
			Menu.item("New project", { id = 4 }),
			Menu.item("Add project", { id = 5 }),
		},

		max_width = 20,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>", "q" },
			submit = { "<CR>", "<Space>", "i", "a" },
		},
		on_close = function()
			print("Menu Closed!")
		end,
		on_submit = function(item)
			ChooseAction(item.id)
		end,
	})

	-- mount the component
	menu:mount()
end

function GetUserFileOrDirectory()
	local Input = require("nui.input")
	local event = require("nui.utils.autocmd").event

	local input = Input({
		position = "50%",
		size = {
			width = 30,
		},
		border = {
			style = "rounded",
			text = {
				top = "<New file(dir ends with /)>",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		prompt = "> ",
		default_value = "NewFile.cs",
		on_close = function() end,
		on_submit = function(value)
			MakeFile(value)
		end,
	})

	-- mount/open the component
	input:mount()
	--
	-- unmount component when cursor leaves buffer
	input:on(event.BufLeave, function()
		input:unmount()
	end)
end

function ChooseTemplate(option)
	local templatesFromFile = vim.fn.readfile(vim.fn.stdpath("data") .. "/templates.txt")

	local templates = {}
	for index, item in ipairs(templatesFromFile) do
		if item ~= "" then
			templates[index] = {
				templateName = string.sub(item, 1, 44),
				templateShorthand = string.sub(item, 47, 72),
				templateLanguages = string.sub(item, 75, 84),
				templateTags = string.sub(item, 87, 118),
			}
		end
	end
	local template = ""
	vim.ui.select(templates, {
		prompt = "Select template",
		format_item = function(item)
			return item.templateName .. " " .. item.templateLanguages
		end,
	}, function(choice)
		if choice ~= nil then
			template = vim.fn.trim(choice.templateShorthand)
			GetProjectName(template, option)
		end
	end)
end

---@param template string
---@param projectName string
function AddProject(template, projectName)
	local command = ADDPROJECTCOMMAND .. " " .. template .. " -n " .. projectName .. " --force"
	-- print(command, 2)
	RunCommandInTerminal(command, GetLspCwd())
end

---@param template string
---@param projectName string
---@param dir string
function CreateNewProject(template, projectName, dir)
	local command = ADDPROJECTCOMMAND .. " " .. template .. " -n " .. projectName .. " --force"
	RunCommandInTerminal(command, vim.fn.expand(dir))
end

function GetProjectName(template, option)
	local Input = require("nui.input")
	local event = require("nui.utils.autocmd").event

	local input = Input({
		position = "50%",
		size = {
			width = 30,
		},
		border = {
			style = "rounded",
			text = {
				top = "Enter project name",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		prompt = "> ",
		-- default_value = "Console app",
		on_close = function() end,
		on_submit = function(value)
			if option == 2 then
				AddProject(template, value)
			else
				GetProjectDirectory(template, value)
			end
		end,
	})

	-- mount/open the component
	input:mount()

	-- unmount component when cursor leaves buffer
	input:on(event.BufLeave, function()
		input:unmount()
	end)
end

function GetProjectDirectory(template, name)
	local Input = require("nui.input")
	local event = require("nui.utils.autocmd").event

	local input = Input({
		position = "50%",
		size = {
			width = 30,
		},
		border = {
			style = "rounded",
			text = {
				top = "Enter project directory",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		prompt = "> ",
		default_value = defaults.defaultProjectDirectory,
		on_close = function() end,
		on_submit = function(value)
			CreateNewProject(template, name, value)
		end,
	})

	-- mount/open the component
	input:mount()

	-- unmount component when cursor leaves buffer
	input:on(event.BufLeave, function()
		input:unmount()
	end)
end
--OW for the pain that this plugin has caused me
vim.keymap.set("n", "<leader>ow", function()
	CreateMenu()
end, { desc = "Open the dotnet dev menu" })

return M
