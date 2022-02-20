am.app.set_model({
	DAEMON_URL = "https://github.com/gemlink/gemlink/releases/download/v4.0.5/gemlink-ubuntu-4.0.5.zip",
	DAEMON_CONFIGURATION = {
		server = (type(am.app.get_configuration("NODE_PRIVKEY") == "string") or am.app.get_configuration("SERVER")) and 1 or nil,
		listen = (type(am.app.get_configuration("NODE_PRIVKEY") == "string") or am.app.get_configuration("SERVER")) and 1 or nil,
		masternodeprivkey = am.app.get_configuration("NODE_PRIVKEY"),
		masternode = am.app.get_configuration("NODE_PRIVKEY") and 1 or nil
	},
	DAEMON_NAME = "gemlinkd",
	CLI_NAME = "gemlink-cli",
	CONF_NAME = "gemlink.conf",
	CONF_SOURCE = "__btc/assets/daemon.conf",
	SERVICE_NAME = "gemlinkd"
},
	{ merge = true, overwrite = true }
)
