-- access filter
require "resty.core"

local count_cycle = tonumber(os.getenv("COUNT_CYCLE")) or 10
local base_ban_limit = tonumber(os.getenv("BASE_BAN_LIMIT")) or 30
local base_ban_expire = tonumber(os.getenv("BASE_BAN_EXPIRE")) or 600
local super_ban_limit = tonumber(os.getenv("SUPER_BAN_LIMIT")) or 100
local super_expire = tonumber(os.getenv("SUPER_EXPIRE")) or 3600

-- get remote ip address
-- local tmp_str = "1.1.1.1, 2.2.2.2"
-- if tmp_str ~= nil and string.len(tmp_str) >15  then
--    local from, to, err  = ngx.re.find(tmp_str, ",", "jo")
--    ngx.log(ngx.ERR, "from: ", from, " to: ", to)
--    tmp_str = string.sub(tmp_str, 1, from - 1)
-- end
ngx.log(ngx.ERR, "new_str: ", tmp_str)
local remote_ip = ngx.req.get_headers()["x-forwarded-for"]
if remote_ip == nil or string.len(remote_ip) == 0 or remote_ip == "unknown" then
   remote_ip = ngx.var.remote_addr
end
-- split ','
if remote_ip ~= nil and string.len(remote_ip) >15  then
       local index = ngx.re.find(remote_ip, ",", "jo")
       remote_ip = string.sub(remote_ip, 1, index - 1)
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

