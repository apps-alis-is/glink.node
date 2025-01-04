local user = am.app.get("user")
ami_assert(type(user) == "string", "User not specified...")

local homedir = user == "root" and "/root" or "/home/" .. user
local ok, paths = fs.safe_read_dir(homedir .. "/.zcash-params", { recurse = true, return_full_paths = true }) --[[@as DirEntry]]
if not ok then
	return -- dir does not exist
end
for _, path in ipairs(paths) do
	local ok, err = fs.safe_remove(path)
	ami_assert(ok, "Failed to remove app data - " .. tostring(err) .. "!")
end
