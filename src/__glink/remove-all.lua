local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...")

local _homedir = _user == "root" and "/root" or "/home/" .. _user
local _ok, _paths = fs.safe_read_dir(_homedir .. "/.zcash-params", { recurse = true, return_full_paths = true }) --[[@as DirEntry]]
if not _ok then
	return -- dir does not exist
end
for _, path in ipairs(_paths) do
	local _ok, _error = fs.safe_remove(path)
	ami_assert(_ok, "Failed to remove app data - " .. tostring(_error) .. "!")
end
