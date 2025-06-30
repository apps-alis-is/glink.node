local tmp_file = os.tmpname()
log_info("Downloading bootstrap...")
local ok, err = net.download_file("https://bc.gemlink.org/download/bc.zip", tmp_file, {
	follow_redirects = true,
	progress_function = (function()
		local last_written = 0
		return function(total, current)
			local progress = math.floor(current / total * 100)
			if math.fmod(progress, 10) == 0 and last_written ~= progress then
				last_written = progress
				io.write(progress .. "%...")
				io.flush()
				if progress == 100 then print() end
			end
		end
	end)()
})
if not ok then
	os.remove(tmp_file)
	ami_error("Failed to download bootstrap - " .. err .. "!", EXIT_APP_DOWNLOAD_ERROR)
end

log_info("Extracting bootstrap...")
local ok, err = zip.extract(tmp_file, "data", { flatten_root_dir = true })
os.remove(tmp_file)
ami_assert(ok, "Failed to extract bootstrap - " .. (err or "") .. "!", EXIT_APP_DOWNLOAD_ERROR)

log_info("Adjusting bootstrap owner.")
local user = am.app.get("user")
ami_assert(type(user) == "string", "User not specified...")

local uid, err = fs.getuid(user)
ami_assert(uid, "Failed to get " .. user .. "uid - " .. tostring(err))

local DATA_PATH = am.app.get_model("DATA_DIR")
fs.mkdirp(DATA_PATH)

local ok, err = fs.chown(DATA_PATH, uid, uid, { recurse = true })
if not ok then
	ami_error("Failed to chown " .. DATA_PATH .. " - " .. (err or ""))
end

log_success("Node successfully bootstrapped.")
