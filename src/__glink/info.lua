local _json = am.options.OUTPUT_FORMAT == "json"

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _appId = am.app.get("id", "unknown")
local _service_name = am.app.get_model("SERVICE_NAME", "unknown")
local _ok, _status, _started = _systemctl.safe_get_service_status(_appId .. "-" .. _service_name)
ami_assert(_ok, "Failed to get status of " .. _appId .. "-" .. _service_name .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)

local _info = {
	gemlinkd = _status,
	started = _started,
	level = "ok",
	synced = false,
	status = "GEMLINK node DOWN",
	version = am.app.get_version(),
	type = am.app.get_type()
}

local function _exec_glink_cli(...)
	local _arg = { "-datadir=data", ... }
	local _rpc_bind = am.app.get_configuration({ "DAEMON_CONFIGURATION", "rpcbind" })
	if type(_rpc_bind) == "string" then
		table.insert(_arg, 1, "-rpcconnect=" .. _rpc_bind)
	end
	local _proc = proc.spawn("bin/gemlink-cli", _arg, { stdio = { stdout = "pipe", stderr = "pipe" }, wait = true })

	local _exit_code = _proc.exit_code
	local _stdout = _proc.stdout_stream:read("a") or ""
	local _stderr = _proc.stderr_stream:read("a") or ""
	return _exit_code, _stdout, _stderr
end

local function _get_glink_cli_result(exit_code, stdout, stderr)
	if exit_code ~= 0 then
		local _error_info = stderr:match("error: (.*)")
		local _ok, _output = hjson.safe_parse(_error_info)
		if _ok then
			return false, _output
		end
		return false, { message = "unknown (internal error)" }
	end

	local _ok, _output = hjson.safe_parse(stdout)
	if _ok then
		return true, _output
	end
	return false, { message = "unknown (internal error)" }
end

local function _get_sync_status(_exit_code, _stdout, _stderr)
	local _success, _output = _get_glink_cli_result(_exit_code, _stdout, _stderr)

	if _success then
		if _output.IsBlockchainSync == true then
			_info.status = "Synced"
			_info.synced = true
		else
			_info.level = "warn"
			_info.status = "Syncing..."
		end
		return
	end

	if type(_stderr) ~= "string" then
		_stderr = ""
	end

	_info.level = "warn"
	_info.status = _stderr:match("GEMLINK is not connected!") or
		_stderr:match("GEMLINK is downloading blocks...") or
		"Unknown error..."
end

local function _get_mn_status(_exit_code, _stdout, _stderr)
	if am.app.get_configuration({ "DAEMON_CONFIGURATION", "masternode" }) == 1 then
		if type(_stdout) ~= "string" then _stdout = "" end
		local _, _output = _get_glink_cli_result(_exit_code, _stdout, _stderr)
		local _mn_status = _output.MasternodeStatus or "Failed to verify masternode status!"
		if _mn_status:match("Masternode successfully started") then
			_info.status = _mn_status
			return
		end

		if type(_stderr) ~= "string" then _stderr = "" end

		local _warn_msg = _mn_status:match("Hot node, waiting for remote activation") or
			_mn_status:match("Node just started, not yet activated")

		_info.level = _warn_msg and "warn" or "error"
		_info.status = _mn_status
	else
		_info.status = "GEMLINK node UP"
	end
end

if _info.gemlinkd == "running" then
	local _exit_code, _stdout, _stderr = _exec_glink_cli("getamiinfo")
	local _success, _output = _get_glink_cli_result(_exit_code, _stdout, _stderr)

	_info.current_block = _success and _output.blocks or "unknown"
	_info.current_block_hash = _success and _output.bestblockhash or "unknown"
	_get_sync_status(_exit_code, _stdout, _stderr)
	_get_mn_status(_exit_code, _stdout, _stderr)
else
	_info.level = "error"
	_info.status = "Node is not running!"
end

if _json then
	print(hjson.stringify_to_json(_info, { indent = false }))
else
	print(hjson.stringify(_info))
end
