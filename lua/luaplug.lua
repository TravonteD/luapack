local job = require('luajob')
local api = vim.api
local M = {}
local progress = { 
  started = 0, 
  completed = 0 
}

M.plugins = {}
M.plugin_dir = '~/.local/share/nvim/site'

local buffer = vim.fn.bufnr('luaplug-test', true)
local package_dir = vim.fn.expand(M.plugin_dir) .. '/pack/luaplug'
local opt_dir = package_dir .. '/opt'
local start_dir = package_dir .. '/start'

local display = {
  init = function()
    vim.cmd('vsplit | buffer '..buffer..' | normal! ggdG')
    vim.fn.appendbufline(buffer, 0, "Updating Plugins")
    vim.fn.appendbufline(buffer, 1, "[          ]")
  end,
  update = function()
    local bar
    local percentage = (progress.started/progress.completed)
    if percentage == 1 then
      bar = '=========='
    elseif percentage > 0.9 then
      bar = '========= '
    elseif percentage > 0.8 then
      bar = '========  '
    elseif percentage > 0.7 then
      bar = '=======   '
    elseif percentage > 0.6 then
      bar = '======    '
    elseif percentage > 0.5 then
      bar = '=====     '
    elseif percentage > 0.4 then
      bar = '====      '
    elseif percentage > 0.3 then
      bar = '===       '
    elseif percentage > 0.2 then
      bar = '==        '
    elseif percentage > 0.1 then
      bar = '=         '
    end
    vim.cmd(':1s:.*:Updating Plugins ('..progress.started..'/'..progress.completed..')')
    vim.cmd(':2s:.*:['..bar..']')
    if percentage == 1 then
        vim.fn.append(vim.fn.line('$'), 'Finishing...Done')
    end
  end
}

local function installed_plugins()
  local list = {
    opt = {},
    start = {}
  }
  local opt_plugins = vim.fn.split(vim.fn.system('ls '..opt_dir), '\n')
  local start_plugins = vim.fn.split(vim.fn.system('ls '..start_dir), '\n')
  for _,i in pairs(opt_plugins) do
    list.opt[i] = true
  end
  for _,i in pairs(start_plugins) do
    list.start[i] = true
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

  if vim.fn.isdirectory(package_dir) == 0 then
    local a  = vim.fn.system('mkdir -p '..M.plugin_dir..'/pack/luaplug/{opt,start}')
  end
end

local function runjob(cmd, cwd)
  job:new({
    cmd = cmd,
    cwd = cwd,
    on_exit = function()
      progress.completed = progress.completed + 1
      display.update()
    end
  }).start()
end

local function download_plugin(plugin, install_type)
  local repo = ('https://github.com/'..plugin)
  local cmd = ('git clone --progress '..repo)
  local cwd = (install_type == 'opt') and opt_dir or start_dir
  progress.started = progress.started + 1
  runjob(cmd, cwd)
  vim.fn.append(vim.fn.line('$'), 'Downloading '..plugin..'...')
end

local function update_helptags()
  local list = installed_plugins()
  for item, _ in pairs(list.opt) do
    local dir = opt_dir..'/'..item..'/doc'
    if vim.fn.isdirectory(vim.fn.expand(dir)) == 1 then
      vim.cmd('helptags '..dir)
    end
  end
  for item, _ in pairs(list.start) do
    local dir = start_dir..'/'..item..'/doc'
    if vim.fn.isdirectory(vim.fn.expand(dir)) == 1 then
      vim.cmd('helptags '..dir)
    end
  end
end

local function get_name(plugin)
  return plugin:gsub('.*/', '')
end

local function defined_plugins()
  local result = {}
  for _, plugin in pairs(M.plugins) do
    result[get_name(plugin[1])] = true
  end
  return result
end

function M.update()
  validate_dirs()

  display.init()
  local plugins = installed_plugins()
  for plugin ,_ in pairs(plugins.opt) do
    local cwd = opt_dir..'/'..plugin
    local cmd = 'git pull'
    progress.started = progress.started + 1
    vim.fn.append(vim.fn.line('$'), 'Updating '..plugin..'...')
    runjob(cmd, cwd)
  end
  for plugin ,_ in pairs(plugins.start) do
    local cwd = start_dir..'/'..plugin
    local cmd = 'git pull'
    progress.started = progress.started + 1
    vim.fn.append(vim.fn.line('$'), 'Updating '..plugin..'...')
    runjob(cmd, cwd)
  end
end

function M.clean()
  local defined = defined_plugins()
  local list = installed_plugins()
  local removable = {}

  for item, _ in pairs(list.opt) do
    if not defined[item] then
      table.insert(removable, ('opt/'..item))
    end
  end
  for item, _ in pairs(list.start) do
    if not defined[item] then
      table.insert(removable, ('start/'..item))
    end
  end

  if #removable == 0 then
    print('No plugins to be cleaned')
    return
  end

  local text = table.concat(removable, '\n')
  local choice = vim.fn.input(text..'\nRemove unused plugins? [Y/n]')
  if choice == 'n' then
      print('Aborted...')
      return
  end

  display.init()
  for _, item in pairs(removable) do
      cmd = 'rm -rf '..item
      progress.started = progress.started + 1
      vim.fn.append(vim.fn.line('$'), 'Deleting '..item..'...')
      runjob(cmd, package_dir)
  end
end

function M.install()
  validate_dirs()

  display.init()
  local installed = installed_plugins()
  for _, plugin in pairs(M.plugins) do
    local itype = (plugin[2] and plugin[2] == 'start' and 'start' or 'opt')
    if not installed[itype][get_name(plugin[1])] then
      download_plugin(plugin[1], itype)
    end
  end
  update_helptags()
end

function M.load()
  local installed = installed_plugins()
  for _, plugin in pairs(M.plugins) do
    local itype = (plugin[2] and plugin[2] == 'start' and 'start' or 'opt')
    local name = get_name(plugin[1])
    if installed[itype][name] then
      vim.cmd('packadd '..name)
    end
  end
end

return M
