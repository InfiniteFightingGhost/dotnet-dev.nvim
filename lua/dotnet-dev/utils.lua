local M = {}

---@return string  --returns the root directory taken from the lsp
function M.GetLspCwd()
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

---@param path string where to create the directory
function M.CreateDirectory(path)
	local newFile = vim.split(path, "/", { plain = true })
	local cwd = M.GetLspCwd()
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

---@param command string the command to run
---@param dir string where to run the command
function M.RunCommandInTerminal(command, dir)
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

return M
