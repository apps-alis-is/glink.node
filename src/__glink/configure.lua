local user = am.app.get("user")
ami_assert(type(user) == "string", "User not specified...")

local apt, err = am.plugin.get("apt")
if err then
	log_warn("Failed to load apt plugin!")
end

local ok, _, _, err, dep = apt.install("libgomp1")
if not ok then
	log_warn("Failed to install " .. (dep or '-') .. "! - " .. err)
end

local DATA_PATH = am.app.get_model("DATA_DIR", "data")
fs.mkdirp(DATA_PATH)

local fetch_script_path = "bin/fetch-params.sh"
local ok, err = net.download_file("https://raw.githubusercontent.com/gemlink/gemlink/master/zcutil/fetch-params.sh", fetch_script_path,
	{ follow_redirects = true })
if not ok then
	log_error("Failed to download fetch-params.sh - " .. (err or '-') .. "!")
	return
end

if fs.exists(fetch_script_path) then -- we download only on debian
	log_info("Downloading params... (This may take few minutes.)")
	local proc = proc.spawn("/bin/bash", { fetch_script_path }, {
		stdio = { stderr = "pipe" },
		wait = true,
		env = { HOME = user == "root" and "/root" or "/home/" .. user }
	}) --[[@as SpawnResult]]


	if proc.exit_code ~= 0 then
		local stderr = proc.stderr_stream:read("a") or ""
		ami_error("Failed to fetch params: " .. stderr, proc.exit_code)
	end

	log_success("Sprout parameters downloaded...")
end
