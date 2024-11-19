local util = require 'lspconfig.util'
local path = require('lspconfig.util').path

-- Find .venv folder in ancestors
local function find_venv_dir(startpath)
  local ancestor = util.search_ancestors(startpath, function(current_path)
    if path.is_dir(path.join(current_path, '.venv')) then
      return current_path
    end
  end)
  if not ancestor then
    return nil
  end
  return path.join(ancestor, '.venv')
end

local function get_project_venv_dir()
  return os.getenv 'VIRTUAL_ENV' or find_venv_dir(vim.fn.getcwd())
end

local function activate_venv(venv_dir)
  vim.env.VIRTUAL_ENV = venv_dir
  vim.env.PATH = path.join(venv_dir, 'bin') .. ':' .. vim.env.PATH
end

local venv = get_project_venv_dir()
if venv then
  activate_venv(venv)
end

print(path.join(venv, 'bin', 'ruff'))
local function config()
  require('lspconfig').ruff.setup {
    init_options = {
      settings = {
        nativeServer = 'auto',
        args = {},
      },
    },
  }
end

return {
  'astral-sh/ruff-lsp',
  version = '*',
  dependencies = {},
  config = config,
}
