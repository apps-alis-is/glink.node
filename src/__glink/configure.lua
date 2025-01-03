local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...")

local _ok, _apt = am.plugin.safe_get("apt")
if not _ok then
	log_warn("Failed to load apt plugin!")
end

local _ok, _, _, _error, _dep = _apt.install("libgomp1")
if not _ok then
	log_warn("Failed to install " .. (_dep or '-') .. "! - " .. _error)
end

local DATA_PATH = am.app.get_model("DATA_DIR", "data")
fs.safe_mkdirp(DATA_PATH)

local _fetchScriptPath = "bin/fetch-params.sh"
local _ok, _error = net.safe_download_file("https://raw.githubusercontent.com/gemlink/gemlink/master/zcutil/fetch-params.sh", _fetchScriptPath,
	{ follow_redirects = true })
if not _ok then
	log_error("Failed to download fetch-params.sh - " .. (_error or '-') .. "!")
	return
end

if fs.exists(_fetchScriptPath) then -- we download only on debian
	log_info("Downloading params... (This may take few minutes.)")
	local _proc = proc.spawn("/bin/bash", { _fetchScriptPath }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = _user == "root" and "/root" or "/home/" .. _user }
	}) --[[@as SpawnResult]]


	if _proc.exit_code ~= 0 then
		local _stderr = _proc.stderr_stream:read("a") or ""
		ami_error("Failed to fetch params: " .. _stderr, _proc.exit_code)
	end

	log_success("Sprout parameters downloaded...")
end
