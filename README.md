# key-menu.nvim

**key-menu.nvim** is a minimal, unobtrusive key mapping hint window for Neovim.
It pops up next to your cursor, displaying available key bindings and their
descriptions, helping you discover and remember your configuration without
breaking your flow.

## Features

*   Key menu appears next to your cursor, minimizing eye movement.
*   Set your keymaps using the standard `vim.keymap.set` and they'll be detected
*   Add descriptions for groups of mappings (e.g., `<leader>g` for Git).

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "cetanu/key-menu.nvim",
  config = function()
    require("key-menu").setup({
      -- Optional configuration
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "cetanu/key-menu.nvim",
  config = function()
    require("key-menu").setup()
  end,
})
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'cetanu/key-menu.nvim'

" After plug#end()
lua require("key-menu").setup()
```

## Configuration

Initialize the plugin with the `setup` function. The default configuration is shown below:

```lua
require("key-menu").setup({
  -- Currently, no major options are required
})
```

### vim options

The popup delay is controlled by Neovim's built-in `timeoutlen` option.

```lua
-- Wait 300ms before showing the popup
vim.o.timeoutlen = 300
```

## Usage

### Registering the Menu

To enable the key menu for a specific prefix (like your leader key), use `require("key-menu").set`. This acts as a wrapper around `vim.keymap.set` but attaches the menu behavior.

```lua
-- If <Space> is your leader key:
require("key-menu").set("n", "<Space>")
```

Now, when you press `<Space>` and wait for `timeoutlen`, the menu will appear.

### defining Mappings

You define mappings as you normally would using `vim.keymap.set`. The `desc` field is used by `key-menu.nvim` to display the description.

```lua
-- Basic mapping
vim.keymap.set("n", "<Space>w", "<Cmd>w<CR>", { desc = "Save" })
vim.keymap.set("n", "<Space>q", "<Cmd>q<CR>", { desc = "Quit" })

-- Lua callback
local erase_all = function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end
vim.keymap.set("n", "<Space>k", erase_all, { desc = "Erase Buffer" })
```

### Mapping Groups

You can group mappings under a prefix and give that prefix a name.

```lua
-- Define mappings under <Space>g
vim.keymap.set("n", "<Space>gs", "<Cmd>Git status<CR>")
vim.keymap.set("n", "<Space>gc", "<Cmd>Git commit<CR>")

-- Register the group name with key-menu
require("key-menu").set("n", "<Space>g", { desc = "Git" })
```

### Buffer-Local Mappings

Pass `buffer = true` (or a buffer number) to create mappings specific to a buffer.

```lua
-- Create a buffer-local mapping group
require("key-menu").set("n", "<Space>l", { desc = "LSP", buffer = true })

vim.keymap.set("n", "<Space>ld", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = true })
```

### Hiding Mappings

If you have a mapping you don't want to show in the menu, set its description to `"HIDDEN"`.

```lua
vim.keymap.set("n", "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>", { desc = "HIDDEN" })
```

## Built-in Mappings Support

`key-menu.nvim` has experimental support for showing Neovim's built-in mappings (like those starting with `g`).

```lua
require("key-menu").set("n", "g")
```

![g-hint-window](https://user-images.githubusercontent.com/5308024/171311333-f911acea-edd2-4404-b63b-cf095f110e21.png)

## Highlighting

The window look can be customized using standard highlight groups.

*   `KeyMenuNormal`: Background and text of the window.
*   `KeyMenuFloatBorder`: Border of the window.

Example:
```lua
vim.api.nvim_set_hl(0, "KeyMenuNormal", { link = "NormalFloat" })
vim.api.nvim_set_hl(0, "KeyMenuFloatBorder", { link = "FloatBorder" })
```

## Parent

This plugin was forked from [emmanueltouzery/key-menu.nvim](https://github.com/emmanueltouzery/key-menu.nvim) and heavily modified.

## Alternative Plugins

*   [folke/which-key.nvim](https://github.com/folke/which-key.nvim) - A popular, highly configurable alternative.
