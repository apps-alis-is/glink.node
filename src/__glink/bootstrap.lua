local _tmpFile = os.tmpname()
log_info("Dwonloading bootstrap...")
local _ok, _error = net.safe_download_file("http://bc.gemlink.org/bc.zip", { progressFunction = (function ()
    local _lastWritten = 0
    return function(total, current) 
        local _progress = math.floor(current / total * 100)
        if math.fmod(_progress, 10) == 0 and _lastWritten ~= _progress then 
            _lastWritten = _progress
            io.write(_progress .. "%...")
            io.flush()
            if _progress == 100 then print() end
        end
    end
end)()}, _tmpFile)
if not _ok then
  os.remove(_tmpFile)
  ami_error("Failed to download bootstrap - " .. _error .. "!", EXIT_APP_DOWNLOAD_ERROR)
end
log_info("Extracting bootstrap...")
local _ok = zip.safe_extract(_tmpFile, "data", {flattenRootDir = true})
if not _ok then
  os.remove(_tmpFile)
  ami_error("Failed to extract bootstrap - " .. _error .. "!", EXIT_APP_DOWNLOAD_ERROR)
end

log_success("Adjusting bootstrap owner.")

local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...")

local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))

local DATA_PATH = am.app.get_model("DATA_DIR")
fs.safe_mkdirp(DATA_PATH)

local _ok, _error = fs.safe_chown(DATA_PATH, _uid, _uid, { recurse = true })
if not _ok then
    ami_error("Failed to chown " .. DATA_PATH .. " - " .. (_error or ""))
end

log_success("Node successfully bootstrapped.")
