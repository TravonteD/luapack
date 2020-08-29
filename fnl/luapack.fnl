(let [Luapack {}
      buffer (vim.api.nvim_create_buf false true)
      statuses {}
      jobs {}]
  (var status_count 0)
  (doto Luapack
        (tset "plugins" {})
        (tset "plugin_dir" (string.format "%s/.local/share/nvim/site/pack/luapack/opt/" (os.getenv "HOME"))))

  (fn ensure_plugin_dir []
    (if (= (vim.fn.isdirectory Luapack.plugin_dir) 0)
      (vim.fn.mkdir Luapack.plugin_dir "p")))

  (fn installed_plugins [] 
    (vim.fn.readdir Luapack.plugin_dir))

  (fn get_repo_name [str]
    (str:gsub ".*/(.*)" "%1"))

  (fn get_needed_plugins []
    (let [already_installed (installed_plugins)
          to_be_installed []]
      (each [_ plugin (ipairs Luapack.plugins)]
        (var needed false)
        (each [_ x (ipairs already_installed)]
          (if (= x (get_repo_name plugin))
                 (set needed true)))
        (if (not needed)
          (table.insert to_be_installed plugin)))
      to_be_installed))

  (fn redraw []
    (let [lines []]
      (each [plugin status (pairs statuses)]
        (match status
          "deleting" (table.insert lines (string.format "Deleting %s" plugin))
          "updating" (table.insert lines (string.format "Updating %s" plugin))
          "downloading" (table.insert lines (string.format "Downloading %s" plugin))
          "deleting_done" (table.insert lines (string.format "Deleting %s...done" plugin))
          "updating_done" (table.insert lines (string.format "Updating %s...done" plugin))
          "downloading_done" (table.insert lines (string.format "Downloading %s...done" plugin))
          "error" (table.insert lines (string.format "Downloading %s...error" plugin)))
        (vim.api.nvim_buf_set_lines buffer 0 status_count false lines))))

  (fn run_cmd [cmd name]
    (let [job_id (vim.fn.jobstart 
                   cmd 
                   {"on_exit" (fn [id code _]
                                (let [name (. jobs id)]
                                  (if (= code 0)
                                    (tset statuses name (string.format "%s_done" (. status "name")))
                                    (tset statuses name "error"))
                                  (redraw)))})]
      (tset jobs job_id name)))

  (fn load_helptags []
    (each [_ plugin (ipairs installed_plugins)]
      (let [plugpath (.. Luapack.plugin_dir plugin)
            dir (vim.fn.readdir plugpath)]
        (if (not= (vim.fn.index dir "doc") -1)
          (if (= (vim.fn.index (vim.fn.readdir (.. plugpath "/doc")) "tags") -1)
            (vim.cmd (string.format "helptags ++t %s" (.. plugpath "/doc"))))))))

  (fn update_status [name status]
    (tset statuses name status)
    (set status_count (+ status_count 1))
    (redraw))

  (fn Luapack.install []
    (ensure_plugin_dir)
    (vim.cmd (string.format "vsplit | b%s" buffer))
    (each [_ x (ipairs (get_needed_plugins))]
      (update_status (get_repo_name x) "downloading")
      (let [shell_cmd (string.format "git clone https://github.com/%s %s" (.. Luapack.plugin_dir (get_repo_name x)))]
        (run_cmd shell_cmd (get_repo_name x)))))

  (fn Luapack.update []
    (vim.cmd (string.format "vsplit | b%s" buffer))
    (each [_ x (ipairs (get_needed_plugins))]
      (update_status (get_repo_name x) "updating")
      (let [shell_cmd (string.format "cd %s && git pull" (.. Luapack.plugin_dir (get_repo_name x)))]
        (run_cmd shell_cmd (get_repo_name x)))))
  
  (fn Luapack.clean []
    (let [plugins_to_remove []]
      (each [_ plugin (ipairs (installed_plugins))]
        (var to_delete true)
        (each [_ x (ipairs plugins)]
          (if (= plugin (get_repo_name x))
            (set to_delete false)))
        (if to_delete
          (table.insert plugins_to_remove plugin)))
      (vim.cmd (string.format "vsplit | b%s" buffer))
      (each [_ plugin (ipairs (plugins_to_remove))]
        (update_status plugin "deleting")
        (let [shell_cmd (string.format "rm -fr %s" (.. Luapack.plugin_dir plugin))]
          (run_cmd shell_cmd plugin)))))

  (fn Luapack.load []
    (each [_ plugin (ipairs (installed_plugins))]
      (vim.cmd (string.format "packadd %s" plugin))))
  Luapack)
