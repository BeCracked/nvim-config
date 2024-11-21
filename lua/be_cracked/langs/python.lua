local util = require 'lspconfig.util'
local path = require('lspconfig.util').path

local M = {}

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

local function get_venv_dir(project_path)
  return os.getenv 'VIRTUAL_ENV' or find_venv_dir(project_path)
end

local function activate_venv(venv_dir)
  vim.env.VIRTUAL_ENV = venv_dir
  vim.env.PATH = path.join(venv_dir, 'bin') .. ':' .. vim.env.PATH
end

-- Get the ruff binary for the project of the current cwd if any
-- Defaults to "ruff" if no venv is detected or found
function M.get_project_ruff_bin(project_path)
  local venv_dir = get_venv_dir(project_path)
  if venv_dir then
    local ruff_path = path.join(venv_dir, 'bin', 'ruff')
    return ruff_path
  else
    return 'ruff'
  end
end

return M
