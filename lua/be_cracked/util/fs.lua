-- Module taken from https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua

local validate = vim.validate
local api = vim.api
local lsp = vim.lsp
local uv = vim.uv or vim.loop
local nvim_eleven = vim.fn.has 'nvim-0.11' == 1

local iswin = uv.os_uname().version:match 'Windows'

local M = {}

function M.bufname_valid(bufname)
  if bufname:match '^/' or bufname:match '^[a-zA-Z]:' or bufname:match '^zipfile://' or bufname:match '^tarfile:' then
    return true
  end
  return false
end

function M.validate_bufnr(bufnr)
  validate {
    bufnr = { bufnr, 'n' },
  }
  return bufnr == 0 and api.nvim_get_current_buf() or bufnr
end

-- Some path utilities
M.path = (function()
  local function escape_wildcards(path)
    return path:gsub('([%[%]%?%*])', '\\%1')
  end

  --- @param path string
  --- @return string
  local function sanitize(path)
    if iswin then
      path = path:sub(1, 1):upper() .. path:sub(2)
      path = path:gsub('\\', '/')
    end
    return path
  end

  --- @param filename string
  --- @return string|false
  local function exists(filename)
    local stat = uv.fs_stat(filename)
    return stat and stat.type or false
  end

  --- @param filename string
  --- @return boolean
  local function is_dir(filename)
    return exists(filename) == 'directory'
  end

  --- @param filename string
  --- @return boolean
  local function is_file(filename)
    return exists(filename) == 'file'
  end

  --- @param path string
  --- @return boolean
  local function is_fs_root(path)
    if iswin then
      return path:match '^%a:$'
    else
      return path == '/'
    end
  end

  --- @param filename string
  --- @return boolean
  local function is_absolute(filename)
    if iswin then
      return filename:match '^%a:' or filename:match '^\\\\'
    else
      return filename:match '^/'
    end
  end

  --- @generic T: string?
  --- @param path T
  --- @return T
  local function dirname(path)
    local strip_dir_pat = '/([^/]+)$'
    local strip_sep_pat = '/$'
    if not path or #path == 0 then
      return path
    end
    local result = path:gsub(strip_sep_pat, ''):gsub(strip_dir_pat, '')
    if #result == 0 then
      if iswin then
        return path:sub(1, 2):upper()
      else
        return '/'
      end
    end
    return result
  end

  local function path_join(...)
    return table.concat(M.tbl_flatten { ... }, '/')
  end

  -- Traverse the path calling cb along the way.
  local function traverse_parents(path, cb)
    path = uv.fs_realpath(path)
    local dir = path
    -- Just in case our algo is buggy, don't infinite loop.
    for _ = 1, 100 do
      dir = dirname(dir)
      if not dir then
        return
      end
      -- If we can't ascend further, then stop looking.
      if cb(dir, path) then
        return dir, path
      end
      if is_fs_root(dir) then
        break
      end
    end
  end

  -- Iterate the path until we find the rootdir.
  local function iterate_parents(path)
    local function it(_, v)
      if v and not is_fs_root(v) then
        v = dirname(v)
      else
        return
      end
      if v and uv.fs_realpath(v) then
        return v, path
      else
        return
      end
    end
    return it, path, path
  end

  local function is_descendant(root, path)
    if not path then
      return false
    end

    local function cb(dir, _)
      return dir == root
    end

    local dir, _ = traverse_parents(path, cb)

    return dir == root
  end

  local path_separator = iswin and ';' or ':'

  return {
    escape_wildcards = escape_wildcards,
    is_dir = is_dir,
    is_file = is_file,
    is_absolute = is_absolute,
    exists = exists,
    dirname = dirname,
    join = path_join,
    sanitize = sanitize,
    traverse_parents = traverse_parents,
    iterate_parents = iterate_parents,
    is_descendant = is_descendant,
    path_separator = path_separator,
  }
end)()

function M.search_ancestors(startpath, func)
  validate { func = { func, 'f' } }
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in M.path.iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

function M.tbl_flatten(t)
  return nvim_eleven and vim.iter(t):flatten(math.huge):totable() or vim.tbl_flatten(t)
end

function M.root_pattern(...)
  local patterns = M.tbl_flatten { ... }
  return function(startpath)
    startpath = M.strip_archive_subpath(startpath)
    for _, pattern in ipairs(patterns) do
      local match = M.search_ancestors(startpath, function(path)
        for _, p in ipairs(vim.fn.glob(M.path.join(M.path.escape_wildcards(path), pattern), true, true)) do
          if M.path.exists(p) then
            return path
          end
        end
      end)

      if match ~= nil then
        return match
      end
    end
  end
end

function M.find_git_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    -- Support git directories and git files (worktrees)
    if M.path.is_dir(M.path.join(path, '.git')) or M.path.is_file(M.path.join(path, '.git')) then
      return path
    end
  end)
end

function M.find_mercurial_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    -- Support Mercurial directories
    if M.path.is_dir(M.path.join(path, '.hg')) then
      return path
    end
  end)
end

function M.find_node_modules_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    if M.path.is_dir(M.path.join(path, 'node_modules')) then
      return path
    end
  end)
end

function M.find_package_json_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    if M.path.is_file(M.path.join(path, 'package.json')) then
      return path
    end
  end)
end

function M.get_active_clients_list_by_ft(filetype)
  local clients = M.get_lsp_clients()
  local clients_list = {}
  for _, client in pairs(clients) do
    local filetypes = client.config.filetypes or {}
    for _, ft in pairs(filetypes) do
      if ft == filetype then
        table.insert(clients_list, client.name)
      end
    end
  end
  return clients_list
end

-- For zipfile: or tarfile: virtual paths, returns the path to the archive.
-- Other paths are returned unaltered.
function M.strip_archive_subpath(path)
  -- Matches regex from zip.vim / tar.vim
  path = vim.fn.substitute(path, 'zipfile://\\(.\\{-}\\)::[^\\\\].*$', '\\1', '')
  path = vim.fn.substitute(path, 'tarfile:\\(.\\{-}\\)::.*$', '\\1', '')
  return path
end

return M
