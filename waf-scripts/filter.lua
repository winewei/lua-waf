-- access filter
require "resty.core"

local count_cycle = tonumber(os.getenv("COUNT_CYCLE")) or 10
local base_ban_limit = tonumber(os.getenv("BASE_BAN_LIMIT")) or 20
local base_ban_expire = tonumber(os.getenv("BASE_BAN_EXPIRE")) or 600
local super_ban_limit = tonumber(os.getenv("SUPER_BAN_LIMIT")) or 500
local super_expire = tonumber(os.getenv("SUPER_EXPIRE")) or 3600

-- get remote ip address
local remote_ip = ngx.req.get_headers()["X-Real-IP"]
if remote_ip == nil then
   remote_ip = ngx.req.get_headers()["x_forwarded_for"]
end
if remote_ip == nil then
   remote_ip = ngx.var.remote_addr
end

local dict = ngx.shared.filter_dict
local filter_key = remote_ip .. ngx.var.uri

dict:safe_add(filter_key, 1, count_cycle)
dict:incr(filter_key, 1)

local base_counts, err = dict:get(filter_key)

-- filter
if base_counts >= super_ban_limit then
   dict:set(filter_key, base_counts, super_expire)
   dict:incr(filter_key, 1)
   ngx.log(ngx.ERR, "super_ban ==> ", "count: ", base_counts, " , key: ", filter_key)
   ngx.exit(403)
elseif base_counts >= base_ban_limit then
   dict:set(filter_key, base_counts, base_ban_expire)
   dict:incr(filter_key, 1)
   ngx.log(ngx.ERR, "base_ban ==> ", "count: ", base_counts, " , key: ", filter_key)
   ngx.exit(403)
else
   dict:incr(filter_key, 1)
end