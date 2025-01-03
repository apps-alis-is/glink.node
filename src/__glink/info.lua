local json = am.options.OUTPUT_FORMAT == "json"

local ok, systemctl = am.plugin.safe_get("systemctl")
ami_assert(ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local app_id = am.app.get("id", "unknown")
local service_name = am.app.get_model("SERVICE_NAME", "unknown")
local ok, status, started = systemctl.safe_get_service_status(app_id .. "-" .. service_name)
ami_assert(ok, "Failed to get status of " .. app_id .. "-" .. service_name .. ".service " .. (status or ""), EXIT_PLUGIN_EXEC_ERROR)

local info = {
	gemlinkd = status,
	started = started,
	level = "ok",
	synced = false,
	status = "GEMLINK node DOWN",
	version = am.app.get_version(),
	type = am.app.get_type()
}

local function exec_glink_cli(...)
	local arg = { "-datadir=data", ... }
	local rpc_bind = am.app.get_configuration({ "DAEMON_CONFIGURATION", "rpcbind" })
	if type(rpc_bind) == "string" then
		table.insert(arg, 1, "-rpcconnect=" .. rpc_bind)
	end
	local proc = proc.spawn("bin/gemlink-cli", arg, { stdio = { stdout = "pipe", stderr = "pipe" }, wait = true })

	local exit_code = proc.exit_code
	local stdout = proc.stdout_stream:read("a") or ""
	local stderr = proc.stderr_stream:read("a") or ""
	return exit_code, stdout, stderr
end

local function get_glink_cli_result(exit_code, stdout, stderr)
	if exit_code ~= 0 then
		local err_info = stderr:match("error: (.*)")
		local ok, output = hjson.safe_parse(err_info)
		if ok then
			return false, output
		end
		return false, { message = "unknown (internal error)" }
	end

	local ok, output = hjson.safe_parse(stdout)
	if ok then
		return true, output
	end
	return false, { message = "unknown (internal error)" }
end

local function get_sync_status(exit_code, stdout, stderr)
	local success, output = get_glink_cli_result(exit_code, stdout, stderr)

	if success then
		if output.IsBlockchainSync == true then
			info.status = "Synced"
			info.synced = true
		else
			info.level = "warn"
			info.status = "Syncing..."
		end
		return
	end

	if type(stderr) ~= "string" then
		stderr = ""
	end

	info.level = "warn"
	info.status = stderr:match("GEMLINK is not connected!") or
		stderr:match("GEMLINK is downloading blocks...") or
		"Unknown error..."
end

local function get_mn_status(exit_code, stdout, stderr)
	if am.app.get_configuration({ "DAEMON_CONFIGURATION", "masternode" }) == 1 then
		if type(stdout) ~= "string" then stdout = "" end
		local _, output = get_glink_cli_result(exit_code, stdout, stderr)
		local mn_status = output.MasternodeStatus or "Failed to verify masternode status!"
		if mn_status:match("Masternode successfully started") then
			info.status = mn_status
			return
		end

		if type(stderr) ~= "string" then stderr = "" end

		local warn_msg = mn_status:match("Hot node, waiting for remote activation") or
			mn_status:match("Node just started, not yet activated")

		info.level = warn_msg and "warn" or "error"
		info.status = mn_status
	else
		info.status = "GEMLINK node UP"
	end
end

if info.gemlinkd == "running" then
	local exit_code, stdout, stderr = exec_glink_cli("getamiinfo")
	local success, output = get_glink_cli_result(exit_code, stdout, stderr)

	info.current_block = success and output.blocks or "unknown"
	info.current_block_hash = success and output.bestblockhash or "unknown"
	get_sync_status(exit_code, stdout, stderr)
	get_mn_status(exit_code, stdout, stderr)
else
	info.level = "error"
	info.status = "Node is not running!"
end

if json then
	print(hjson.stringify_to_json(info, { indent = false }))
else
	print(hjson.stringify(info))
end
