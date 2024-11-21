local util = require 'be_cracked.util.fs'
local path = require('be_cracked.util.fs').path

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

function M.get_venv_dir(project_path)
  return os.getenv 'VIRTUAL_ENV' or find_venv_dir(project_path)
end

function M.activate_venv(venv_dir)
  vim.env.VIRTUAL_ENV = venv_dir
  vim.env.PATH = path.join(venv_dir, 'bin') .. ':' .. vim.env.PATH
end

function M.deactivate_venv()
  vim.env.VIRTUAL_ENV = nil
  vim.env.PATH = nil
end

-- Get the provided binary for the active venv or the given project (defaults to cwd)
-- Defaults to the provided binary if no venv is detected or found
function M.get_project_binary(binary, project_path)
  project_path = project_path or vim.fn.getcwd()
  local venv_dir = M.get_venv_dir(project_path)
  if venv_dir then
    local python_path = path.join(venv_dir, 'bin', binary)
    return python_path
  else
    return binary
  end
end

return M
