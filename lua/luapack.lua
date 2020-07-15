-- luacheck: globals vim
local Luapack = {}
local buffer = vim.api.nvim_create_buf(false, true)
local statuses = {}
local jobs = {}
local status_count = 0

Luapack.plugins = {}

Luapack.plugin_dir = ('%s/.local/share/nvim/site/pack/luapack/opt/'):format(os.getenv('HOME'))

local function ensure_plugin_dir()
  if vim.fn.isdirectory(Luapack.plugin_dir) == 0 then
    vim.fn.mkdir(Luapack.plugin_dir, 'p')
  end
end

local function installed_plugins()
  return vim.fn.readdir(Luapack.plugin_dir)
end

local function get_repo_name(str)
  return str:gsub('.*/(.*)', '%1')
end

local function get_needed_plugins()
  local already_installed = installed_plugins()
  local to_be_installed = {}
  for _, plugin in ipairs(Luapack.plugins) do
    local needed = false
    for _, x in ipairs(already_installed) do
      if x == get_repo_name(plugin) then
         needed = true
      end
    end
    if not needed then
      table.insert(to_be_installed, plugin)
    end
  end
  return to_be_installed
end

local function redraw()
  local lines = {}
  for plugin, status in pairs(statuses) do
    if status == 'deleting' then
      table.insert(lines, ('Deleting %s'):format(plugin))
      goto continue
    end
    if status == 'updating' then
      table.insert(lines, ('Updating %s'):format(plugin))
      goto continue
    end
    if status == 'downloading' then
      table.insert(lines, ('Downloading %s'):format(plugin))
      goto continue
    end
    if status == 'deleting_done' then
      table.insert(lines, ('Deleting %s...done'):format(plugin))
      goto continue
    end
    if status == 'updating_done' then
      table.insert(lines, ('Updating %s...done'):format(plugin))
      goto continue
    end
    if status == 'downloading_done' then
      table.insert(lines, ('Downloading %s...done'):format(plugin))
      goto continue
    end
    if status == 'error' then
      table.insert(lines, ('Downloading %s...error'):format(plugin))
      goto continue
    end
    :: continue ::
  end
  vim.api.nvim_buf_set_lines(buffer, 0, status_count, false, lines)
end

local function run_cmd(cmd, name)
  local job_id = vim.fn.jobstart(cmd, {
      on_exit = function(id, code, _)
        local name = jobs[id]
        if code == 0 then
          statuses[name] = ('%s_done'):format(statuses[name])
        else
          statuses[name] = 'error'
        end
        redraw()
      end
  })
  jobs[job_id] = name
end

Luapack.install = function()
  ensure_plugin_dir()
  vim.cmd(([[vsplit | b%s]]):format(buffer))
  for _, x in ipairs(get_needed_plugins()) do
      statuses[get_repo_name(x)] = 'downloading'
      status_count = status_count + 1
      redraw()
      local shell_cmd = ('git clone https://github.com/%s %s'):format(x, Luapack.plugin_dir..get_repo_name(x))
      run_cmd(shell_cmd, get_repo_name(x))
  end
end

Luapack.update = function()
  vim.cmd(([[vsplit | b%s]]):format(buffer))
  for _, x in ipairs(installed_plugins()) do
      statuses[get_repo_name(x)] = 'updating'
      status_count = status_count + 1
      redraw()
      local shell_cmd = ('cd %s && git pull'):format(Luapack.plugin_dir..get_repo_name(x))
      run_cmd(shell_cmd, get_repo_name(x))
  end
end

Luapack.clean = function()
  local plugins_to_remove = {}
  for _, plugin in ipairs(installed_plugins()) do
    local to_delete = true
    for _, x in ipairs(plugins) do
      if plugin == get_repo_name(x) then
        to_delete = false
      end
    end
    if to_delete then
      table.insert(plugins_to_remove, plugin)
    end
  end

  vim.cmd(([[vsplit | b%s]]):format(buffer))
  for _, plugin in ipairs(plugins_to_remove) do
    statuses[plugin] = 'deleting'
    status_count = status_count + 1
    redraw()
    local shell_cmd = ('rm -fr %s'):format(Luapack.plugin_dir..plugin)
    run_cmd(shell_cmd, plugin)
  end
end

Luapack.load = function()
  for _, plugin in ipairs(installed_plugins()) do
    vim.cmd(('packadd %s'):format(plugin))
  end
end

return Luapack
