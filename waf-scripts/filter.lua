-- ngx.exit(403)
require "resty.core"

local block_expire = tonumber(os.getenv("BLOCK_EXPIRE"))
local block_limit = tonumber(os.getenv("BLOCK_LIMIT"))

if block_expire == nil then
   block_expire = 30
end

if block_limit == nil then
   block_limit = 20
end

-- get remote ip address
local remote_ip = ngx.req.get_headers()["X-Real-IP"]
if remote_ip == nil then
   remote_ip = ngx.req.get_headers()["x_forwarded_for"]
end
if remote_ip == nil then
   remote_ip = ngx.var.remote_addr
end

local dicts = ngx.shared.filter_dict
local filter_key = remote_ip .. ngx.var.uri
dicts:safe_add(filter_key, 1, block_expire)
dicts:incr(filter_key, 1)

local is_check, err = dicts:get(filter_key)

if is_check > block_limit then
    ngx.exit(403)
end