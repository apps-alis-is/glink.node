am.app.set_model({
	DAEMON_URL = "https://github.com/gemlink/gemlink/releases/download/v4.2.2/gemlink-ubuntu-4.2.2.zip",
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
	SERVICE_NAME = "gemlinkd",
	ADD_NODES = {
		"15.235.142.201",
		"193.25.2.237"
	 }
},
	{ merge = true, overwrite = true }
)
