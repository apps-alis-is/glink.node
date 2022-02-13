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

log_success("Node successfully bootstrapped.")
