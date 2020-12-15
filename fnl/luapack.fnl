(let [Luapack {:plugins {}
               :plugin_dir (string.format "%s/.local/share/nvim/site/pack/luapack/opt/" (os.getenv "HOME"))}
      buffer (vim.api.nvim_create_buf false true)
      statuses {}
      jobs {}]
  (var status_count 0)

  (fn ensure_plugin_dir []
    (if (= (vim.fn.isdirectory Luapack.plugin_dir) 0)
      (vim.fn.mkdir Luapack.plugin_dir "p")))

  (fn installed_plugins [] 
    (vim.fn.readdir Luapack.plugin_dir))

  (fn get_repo_name [str]
    (str:gsub ".*/(.*)" "%1"))

  (fn get_needed_plugins []
    (let [installed_plugins (installed_plugins)
          plugin_list {}]
      (each [_ plugin (ipairs Luapack.plugins)]
        (var installed? false)
        (each [_ x (ipairs installed_plugins)]
          (if (= x (get_repo_name plugin))
                 (set installed? true)))
        (if installed?
          (tset plugin_list plugin true)
          (tset plugin_list plugin false)))
      plugin_list))

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
          "error" (table.insert lines (string.format "Downloading %s...error" plugin))))
        (vim.api.nvim_buf_set_lines buffer 0 status_count false lines)))

  (fn run_cmd [cmd name]
    (let [job_id (vim.fn.jobstart 
                   cmd 
                   {:on_exit (fn [id code _]
                                (let [name (. jobs id)]
                                  (if (= code 0)
                                    (tset statuses name (string.format "%s_done" (. statuses name)))
                                    (tset statuses name "error"))
                                  (redraw)))})]
      (tset jobs job_id name)))

  (fn load_helptags []
    (each [_ plugin (ipairs (installed_plugins))]
      (let [plugpath (.. Luapack.plugin_dir plugin)
            dir (vim.fn.readdir plugpath)
            doc_path (.. plugpath "/doc")]
        (if (not= (vim.fn.index dir "doc") -1)
          (if (= (vim.fn.index (vim.fn.readdir doc_path) "tags") -1)
            (vim.cmd (string.format "helptags ++t %s" doc_path)))))))

  (fn update_status [name status]
    (tset statuses name status)
    (set status_count (+ status_count 1))
    (redraw))

  (fn open_buffer []
    (vim.cmd (string.format "vsplit | b%s" buffer)))

  (fn Luapack.install []
    (ensure_plugin_dir)
    (open_buffer)
    (each [plugin installed? (pairs (get_needed_plugins))]
      (if installed?
        (update_status (get_repo_name plugin) "installed")
        (do
          (update_status (get_repo_name plugin) "downloading")
          (let [shell_cmd (string.format "git clone https://github.com/%s %s" plugin (.. Luapack.plugin_dir (get_repo_name plugin)))]
            (run_cmd shell_cmd (get_repo_name plugin)))))))

  (fn Luapack.update []
    (open_buffer)
    (each [_ x (ipairs (get_needed_plugins))]
      (update_status (get_repo_name x) "updating")
      (let [shell_cmd (string.format "cd %s && git pull" (.. Luapack.plugin_dir (get_repo_name x)))]
        (run_cmd shell_cmd (get_repo_name x)))))
  
  (fn Luapack.clean []
    (let [plugins_to_remove []]
      (each [_ plugin (ipairs (installed_plugins))]
        (var to_delete true)
        (each [_ x (ipairs Luapack.plugins)]
          (if (= plugin (get_repo_name x))
            (set to_delete false)))
        (if to_delete
          (table.insert plugins_to_remove plugin)))
      (open_buffer)
      (each [_ plugin (ipairs (plugins_to_remove))]
        (update_status plugin "deleting")
        (let [shell_cmd (string.format "rm -fr %s" (.. Luapack.plugin_dir plugin))]
          (run_cmd shell_cmd plugin)))))

  (fn Luapack.load []
    (each [_ plugin (ipairs (installed_plugins))]
      (vim.cmd (string.format "packadd %s" plugin))))
  Luapack)
