-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
local keymap = vim.keymap.set

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
keymap('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
keymap('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
keymap('n', '<C-A-left>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
keymap('n', '<C-A-right>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
keymap('n', '<C-A-down>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
keymap('n', '<C-A-up>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Keymaps for better default experience
-- Remap for dealing with word wrap
keymap('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- Remap for dealing with word wrap
keymap('n', 'Up', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap('n', 'Down', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Visual Mode ]]

-- Stay in indent mode
keymap({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
keymap('v', '<', '<gv', { silent = true })
keymap('v', '>', '>gv', { silent = true })

-- Better paste - keep register
keymap('v', 'p', '"_dP', { silent = true })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
