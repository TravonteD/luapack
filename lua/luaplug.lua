local job = require('luajob')
local api = vim.api
local M = {}
local progress = {}
local buffer = vim.fn.bufnr('luaplug-test', true)

local function cd(dir)
  vim.cmd('silent cd '..dir)
end

local function package_dir()
  return vim.fn.expand(M.plugin_dir) .. '/pack/luaplug'
end

local function opt_dir()
  return package_dir() .. '/opt'
end

local function start_dir()
  return package_dir() .. '/start'
end

local function installed_plugins()
  local list = {}
  local opt_plugins = vim.fn.split(vim.fn.system('ls '..opt_dir()), '\n')
  local start_plugins = vim.fn.split(vim.fn.system('ls '..start_dir()), '\n')
  for _,i in pairs(opt_plugins) do
    list['opt/'..i] = true
  end
  for _,i in pairs(start_plugins) do
    list['start/'..i] = true
  end
  return list
end

local function validate_dirs()
  if not M.plugins then
    print('No Plugins defined')
    return 
  end

  if vim.fn.isdirectory(vim.fn.expand(M.plugin_dir)) == 0 then
    print('Plugin Dir Does Not Exist')
    return
  end
end

local function runjob(cmd, cwd, line)
  job:new({
    cmd = cmd,
    cwd = cwd,
    on_exit = function(code, signal)
      vim.cmd((line+1)..'s:.*:&Done')
    end
  }).start()
end

local function init_display()
  api.nvim_buf_set_lines(buffer, vim.fn.line('^'), vim.fn.line('$'), false, {})
  vim.cmd('vsplit | buffer '..buffer)
end

local function download_plugin(plugin, install_type, line)
  local repo = ('https://github.com/'..plugin)
  local cmd = ('git clone --progress '..repo)
  local cwd = (install_type == 'opt') and opt_dir() or start_dir()
  runjob(cmd, cwd, line)
end

local function update_helptags()
  cd(package_dir())
  local list = installed_plugins()
  for item, _ in pairs(list) do
     vim.cmd('helptags '..item..'/doc')
  end
end

local function get_name(plugin)
  return plugin:gsub('.*/', '')
end

local function plugin_list()
  local result = {}
  for _, plugin in pairs(M.plugins) do
    local name = get_name(plugin[1])
    if plugin[2] and plugin[2] == 'start' then
      result['start/'..name] = true
    else
      result['opt/'..name] = true
    end
  end
  return result
end


M.plugin_dir = '~/.local/share/nvim/site'

function M.update()
  validate_dirs()

  local plugins = installed_plugins()
  vim.cmd('vsplit | buffer '..buffer)
  for plugin ,_ in pairs(plugins) do
    local line = vim.fn.getbufinfo(buffer)[1].linecount
    vim.fn.append(line, 'Updating '..plugin..'...')
    cwd = package_dir()..'/'..plugin
    cmd = 'git pull'
    runjob(cmd, cwd, line)
  end
end

function M.clean()
  local defined = plugin_list()
  local list = installed_plugins()
  local removable = {}

  for item, _ in pairs(list) do
    if not defined[item] then
      table.insert(removable, item)
    end
  end

  if #removable == 0 then
    print('No plugins to be cleaned')
    return
  end

  local choice = vim.fn.input('Remove unused directories? [Y/n]')
  if choice == 'n' then
      print('Aborted...')
      return
  end

  vim.cmd('vsplit | buffer '..buffer)
  for _, item in pairs(removable) do
      local line = vim.fn.getbufinfo(buffer)[1].linecount
      vim.fn.append(line, 'Removing '..item..'...')
      cmd = 'rm -rf '..item
      runjob(cmd, nil, line)
  end
end

function M.install()
  validate_dirs()

  if vim.fn.isdirectory(package_dir()) == 0 then
    cd(M.plugin_dir)
    local a  = vim.fn.system('mkdir -p pack/luaplug/{opt,start}')
  end

  local installed = installed_plugins()

  vim.cmd('vsplit | buffer '..buffer)
  for _, plugin in pairs(M.plugins) do
    local line = vim.fn.getbufinfo(buffer)[1].linecount
    local itype = (plugin[2] and plugin[2] == 'start' and 'start' or 'opt')
    if installed[itype..'/'..get_name(plugin[1])] then
      goto continue
    end
    vim.fn.append(line, 'Downloading '..plugin[1]..'...')
    download_plugin(plugin[1], itype, line)
    ::continue::
  end
  update_helptags()
end

function M.load()
  local installed = installed_plugins()
  for _, plugin in pairs(M.plugins) do
    local itype = (plugin[2] and plugin[2] == 'start' and 'start' or 'opt')
    local name = get_name(plugin[1])
    if installed[itype..'/'..name] then
      vim.cmd('packadd '..name)
    end
  end
end

return M
