local python = require 'be_cracked.langs.python'

-- TODO: Guard this behind a relevant condition
local venv_dir = python.get_venv_dir(vim.fn.getcwd())
if venv_dir then
  vim.notify('Using venv at ' .. venv_dir, vim.log.levels.INFO)
  python.activate_venv(venv_dir)
else
  vim.notify('No venv found', vim.log.levels.INFO)
end
