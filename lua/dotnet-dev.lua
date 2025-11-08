local M = {}

local BUILDCOMMAND = "dotnet build"
local RUNCOMMAND = "dotnet run"
local ADDPROJECTCOMMAND = "dotnet new"
local TESTCOMMAND = "dotnet test"
local ADDREFERENCE = "dotnet add reference"
local REMOVEREFERENCE = "dotnet remove reference"
local CLEANCOMMAND = "dotnet clean"

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
	-- local dirs = vim.lsp.buf.list_workspace_folders()
	-- if not dirs[1] then
	-- 	for path, type in vim.fs.dir(vim.fn.getcwd()) do
	-- 		print(path, type)
	-- 		if not dirs then
	-- 			dirs = { path }
	-- 		else
	-- 			table.insert(dirs, path)
	-- 		end
	-- 	end
	-- end
	-- if not dirs[2] then
	-- 	return dirs[1]
	-- else
	-- 	return UserPickDir(dirs)
	-- end
	return vim.lsp.buf.list_workspace_folders()[1] or vim.fn.getcwd()
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
---@param directoriesFromCwd table
---@return string
local function GetNamespace(cwd, directoriesFromCwd)
	local path = vim.split(cwd, "/", { plain = true })
	local namespace = { path[#path] }
	for i = 1, #directoriesFromCwd - 1 do
		table.insert(namespace, directoriesFromCwd[i])
	end
	return table.concat(namespace, ".")
end

---@param path string
local function CreateDirectory(path)
	local newFile = vim.split(path, "/", { plain = true })
	local cwd = GetLspCwd()
	local dir = ""
	if table.concat(newFile, "/", 1, #newFile - 2) ~= "" then
		dir = table.concat(newFile, "/", 1, #newFile - 2)
	end
	dir = cwd .. "/" .. dir
	if vim.fn.finddir(newFile[#newFile - 1], dir) == "" then
		vim.fn.mkdir(path, "p")
	else
		print("There already exists a directory with name: " .. newFile[#newFile - 1])
	end
end

---@param name string
local function CreateNewFile(name)
	local newFile = vim.split(name, "/", { plain = true })
	local cwd = GetLspCwd()
	local fileName = newFile[#newFile]
	local dir = ""
	if table.concat(newFile, "/", 1, #newFile - 1) ~= "" then
		dir = table.concat(newFile, "/", 1, #newFile - 1)
	end
	dir = cwd .. "/" .. dir
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

---@param name string
local function MakeFile(name)
	if name == nil or name == "" then
		return
	end

	if name:sub(-1) == "/" then
		CreateDirectory(name)
	else
		CreateNewFile(name)
	end
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

local function GetUserFileOrDirectory()
	vim.ui.input({
		prompt = "<New file(dir ends with /)>",
		default = "NewFile.cs",
		completion = "file",
	}, function(value)
		MakeFile(value)
	end)
end

---@param template string
---@param projectName string
---@param dir string
local function CreateDotnetProject(template, projectName, dir)
	local command = ADDPROJECTCOMMAND .. " " .. template .. " -n " .. projectName .. " --force"
	RunCommandInTerminal(command, vim.fn.expand(dir))
end

local function GetProjectName(template, option)
	vim.ui.input({
		prompt = "<Enter project name>",
		default = "ConsoleApp",
		-- completion = "-completion=dir",
	}, function(value)
		if option == 2 then
			local dir = GetLspCwd()
			local thingy = vim.split(dir, "/", { plain = true })
			dir = table.concat(thingy, "/", 1, #thingy - 1)
			CreateDotnetProject(template, value, dir)
		else
			GetProjectDirectory(template, value)
		end
	end)
end

local function ChooseTemplate(option)
	vim.ui.select(Templates, {
		prompt = "Select template",
		format_item = function(item)
			return item.Name .. " " .. item.Languages
		end,
	}, function(choice)
		if choice ~= nil then
			Template = vim.fn.trim(choice.Shorthand)
			GetProjectName(Template, option)
		end
	end)
end

---@param dir string
---@param removing boolean|nil
local function FindProjectsInPath(dir, removing)
	local allProjects = { nil }
	local curr = vim.split(dir, "/", { plain = true })
	dir = vim.fn.fnamemodify(dir, ":h")
	for name, type in vim.fs.dir(dir) do
		if type == "directory" and name ~= curr[#curr] then
			for recName in vim.fs.dir(dir .. "/" .. name) do
				if vim.endswith(recName, ".csproj") then
					if not allProjects then
						allProjects = { recName }
					else
						if removing then
							table.insert(allProjects, name .. "/" .. recName)
						else
							table.insert(allProjects, name)
						end
					end
				end
			end
		end
	end
	return allProjects
end

---@param dir string
local function AddProjectReference(dir)
	local allProjects = FindProjectsInPath(dir)
	vim.ui.select(allProjects, {
		prompt = "Pick project to add",
	}, function(choice)
		RunCommandInTerminal(ADDREFERENCE .. " " .. "../" .. choice, dir)
	end)
end

---@param dir string
local function RemoveProjectReference(dir)
	local allProjects = FindProjectsInPath(dir, true)
	vim.ui.select(allProjects, {
		prompt = "Pick project to add",
	}, function(choice)
		RunCommandInTerminal(REMOVEREFERENCE .. " " .. "../" .. choice, dir)
	end)
end

---@param action integer the id of the command to run
local function ChooseAction(action)
	local dir = GetLspCwd()
	print(dir, "action")
	if action == 1 then
		RunCommandInTerminal(RUNCOMMAND, dir)
	elseif action == 2 then
		RunCommandInTerminal(BUILDCOMMAND, dir)
	elseif action == 3 then
		GetUserFileOrDirectory()
	elseif action == 4 then
		ChooseTemplate(1)
	elseif action == 5 then
		ChooseTemplate(2)
	elseif action == 6 then
		RunCommandInTerminal(TESTCOMMAND, dir)
	elseif action == 7 then
		AddProjectReference(dir)
	elseif action == 8 then
		RemoveProjectReference(dir)
	elseif action == 9 then
		RunCommandInTerminal(CLEANCOMMAND, dir)
	end
end

local function CreateMenu()
	local lines = {
		{ name = "Run project", id = 1 },
		{ name = "Build project", id = 2 },
		{ name = "New file", id = 3 },
		{ name = "New project", id = 4 },
		{ name = "Add project", id = 5 },
		{ name = "Run tests", id = 6 },
		{ name = "Add project reference", id = 7 },
		{ name = "Remove project reference", id = 8 },
		{ name = "Clean project", id = 9 },
	}
	vim.ui.select(lines, {
		prompt = "Select action",
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice ~= nil then
			ChooseAction(choice.id)
		end
	end)
end

function GetProjectDirectory(template, name)
	require("telescope.builtin").find_files({
		prompt = "Select project directory",
		find_command = { "fd", "--type", "d" },
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = require("telescope.actions.state").get_selected_entry()
				require("telescope.actions").close(prompt_bufnr)
				vim.fn.mkdir(selection.value .. "/" .. name)
				CreateDotnetProject(template, name, selection.value .. "/" .. name)
			end)
			return true
		end,
	})
end

vim.api.nvim_create_user_command("DotnetDev", function()
	CreateMenu()
end, {})

--OW for the pain that this plugin has caused me
vim.keymap.set("n", "<leader>ow", function()
	CreateMenu()
end, { desc = "Open the dotnet dev menu" })

M.setup = function(opts)
	vim.tbl_deep_extend("force", defaults, opts)
end
return M
