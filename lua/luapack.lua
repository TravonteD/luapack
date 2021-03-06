local Luapack = {plugin_dir = string.format("%s/.local/share/nvim/site/pack/luapack/opt/", os.getenv("HOME")), plugins = {}}
local buffer = vim.api.nvim_create_buf(false, true)
local statuses = {}
local jobs = {}
local status_count = 0
local function ensure_plugin_dir()
  if (vim.fn.isdirectory(Luapack.plugin_dir) == 0) then
    return vim.fn.mkdir(Luapack.plugin_dir, "p")
  end
end
local function installed_plugins()
  return vim.fn.readdir(Luapack.plugin_dir)
end
local function get_repo_name(str)
  return str:gsub(".*/(.*)", "%1")
end
local function get_needed_plugins()
  local installed_plugins0 = installed_plugins()
  local plugin_list = {}
  for _, plugin in ipairs(Luapack.plugins) do
    local installed_3f = false
    for _0, x in ipairs(installed_plugins0) do
      if (x == get_repo_name(plugin)) then
        installed_3f = true
      end
    end
    if installed_3f then
      plugin_list[plugin] = true
    else
      plugin_list[plugin] = false
    end
  end
  return plugin_list
end
local function redraw()
  local lines = {}
  for plugin, status in pairs(statuses) do
    local _0_0 = status
    if (_0_0 == "installed") then
      table.insert(lines, string.format("Installing %s...already installed", plugin))
    elseif (_0_0 == "removing") then
      table.insert(lines, string.format("Removing %s", plugin))
    elseif (_0_0 == "updating") then
      table.insert(lines, string.format("Updating %s", plugin))
    elseif (_0_0 == "installing") then
      table.insert(lines, string.format("Installing %s", plugin))
    elseif (_0_0 == "removing_done") then
      table.insert(lines, string.format("Removing %s...done", plugin))
    elseif (_0_0 == "updating_done") then
      table.insert(lines, string.format("Updating %s...done", plugin))
    elseif (_0_0 == "installing_done") then
      table.insert(lines, string.format("Installing %s...done", plugin))
    elseif (_0_0 == "error") then
      table.insert(lines, string.format("Installing %s...error", plugin))
    end
  end
  return vim.api.nvim_buf_set_lines(buffer, 0, status_count, false, lines)
end
local function run_cmd(cmd, name)
  local job_id = nil
  local function _0_(id, code, _)
    print(vim.inspect(id))
    local name0 = jobs[id]
    if (code == 0) then
      statuses[name0] = string.format("%s_done", statuses[name0])
    else
      statuses[name0] = "error"
    end
    return redraw()
  end
  job_id = vim.fn.jobstart(cmd, {on_exit = _0_})
  jobs[job_id] = name
  return nil
end
local function load_helptags()
  for _, plugin in ipairs(installed_plugins()) do
    local plugpath = (Luapack.plugin_dir .. plugin)
    local dir = vim.fn.readdir(plugpath)
    local doc_path = (plugpath .. "/doc")
    if (vim.fn.index(dir, "doc") ~= -1) then
      if (vim.fn.index(vim.fn.readdir(doc_path), "tags") == -1) then
        vim.cmd(string.format("helptags ++t %s", doc_path))
      end
    end
  end
  return nil
end
local function update_status(name, status)
  statuses[name] = status
  status_count = (status_count + 1)
  return redraw()
end
local function open_buffer()
  return vim.cmd(string.format("vsplit | b%s", buffer))
end
local function install_plugin(plugin)
  update_status(get_repo_name(plugin), "installing")
  local shell_cmd = string.format("git clone https://github.com/%s %s", plugin, (Luapack.plugin_dir .. get_repo_name(plugin)))
  return run_cmd(shell_cmd, get_repo_name(plugin))
end
local function update_plugin(plugin)
  update_status(get_repo_name(plugin), "updating")
  local shell_cmd = string.format("cd %s && git pull", (Luapack.plugin_dir .. get_repo_name(plugin)))
  return run_cmd(shell_cmd, get_repo_name(plugin))
end
Luapack.install = function()
  ensure_plugin_dir()
  open_buffer()
  for plugin, installed_3f in pairs(get_needed_plugins()) do
    if installed_3f then
      update_status(get_repo_name(plugin), "installed")
    else
      install_plugin(plugin)
    end
  end
  return nil
end
Luapack.update = function()
  open_buffer()
  for plugin, installed_3f in pairs(get_needed_plugins()) do
    if installed_3f then
      update_plugin(plugin)
    else
      install_plugin(plugin)
    end
  end
  return nil
end
Luapack.clean = function()
  local plugins_to_remove = {}
  for _, plugin in ipairs(installed_plugins()) do
    local to_delete = true
    for _0, x in ipairs(Luapack.plugins) do
      if (plugin == get_repo_name(x)) then
        to_delete = false
      end
    end
    if to_delete then
      table.insert(plugins_to_remove, plugin)
    end
  end
  open_buffer()
  for _, plugin in ipairs(plugins_to_remove) do
    update_status(plugin, "removing")
    local shell_cmd = string.format("rm -fr %s", (Luapack.plugin_dir .. plugin))
    run_cmd(shell_cmd, plugin)
  end
  return nil
end
Luapack.load = function()
  for _, plugin in ipairs(installed_plugins()) do
    pcall(vim.cmd, string.format("packadd %s", plugin))
  end
  return nil
end
return Luapack
