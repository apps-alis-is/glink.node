local ami_id = "GEMLINK node"

return {
	title = ami_id,
	base = "__btc/ami.lua",
	commands = {
		info = {
			action = '__glink/info.lua'
		},
		setup = {
			options = {
				configure = {
					description = "Configures application, renders templates and installs services"
				}
			},
			action = function(_options, _, _, _)
				local no_options = #table.keys(_options) == 0
				if no_options or _options.environment then
					am.app.prepare()
				end

				if no_options or not _options["no-validate"] then
					am.execute("validate", { "--platform" })
				end

				if no_options or _options.app then
					am.execute_extension("__btc/download-binaries.lua", { context_fail_exit_code = EXIT_SETUP_ERROR })
				end

				if no_options and not _options["no-validate"] then
					am.execute("validate", { "--configuration" })
				end

				if no_options or _options.configure then
					am.app.render()

					am.execute_extension("__btc/configure.lua", { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
					am.execute_extension("__glink/configure.lua", { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
				end
				log_success("glink node setup complete.")
			end
		},
		bootstrap = {
			description = "ami 'bootstrap' sub command",
			summary = 'Bootstraps the GLINK node',
			action = '__glink/bootstrap.lua',
			context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
		},
		remove = {
			index = 7,
			action = function(_options, _, _, _cli)
				if _options.all then
					am.execute_extension("__btc/remove-all.lua", { context_fail_exit_code = EXIT_RM_ERROR })
					am.execute_extension("__glink/remove-all.lua", { context_fail_exit_code = EXIT_RM_ERROR })
					am.app.remove()
					log_success("Application removed.")
				else
					am.app.remove_data()
					log_success("Application data removed.")
				end
			end
		}
	}
}
