# dotnet-dev.nvim

A Neovim plugin for interacting with the `dotnet` CLI, written in Lua.

## Features

*   Run and build .NET projects.
*   Create new .NET projects and files from templates.
*   A simple and intuitive UI for selecting actions and templates.

## Installation

### [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "InfiniteFightingGhost/dotnet-dev.nvim",
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "InfiniteFightingGhost/dotnet-dev.nvim"
```

## Usage

The plugin provides a single command that opens a menu for all available actions:

```vim
:DotnetDev
```

You can also map this to a keybinding in your `init.lua` or `init.vim`:

```lua
vim.keymap.set("n", "<leader>ow", "<cmd>DotnetDev<cr>", { desc = "Open the dotnet dev menu" })
```

The menu allows you to:

*   **Run project:** Executes `dotnet run` in the project's root directory.
*   **Build project:** Executes `dotnet build` in the project's root directory.
*   **New file:** Creates a new C# file with a basic class structure.
*   **New project:** Creates a new .NET project from a template in a specified directory.
*   **Add project:** Adds a new .NET project from a template to the current solution.

## Configuration

The plugin comes with the following default configuration. You can override these values by passing a table to the `setup` function.

```lua
-- init.lua
require('dotnet-dev').setup({
  defaultProjectDirectory = "~/Projects",
  menuBorder = "rounded",
  menuSize = {
    height = 20,
    width = 50,
  },
  inputWidth = 30,
  inputBorder = "rounded",
})
```

