-- access filter
require "resty.core"
local redis = require "resty.redis"

local count_cycle = tonumber(os.getenv("COUNT_CYCLE")) or 10
local base_ban_limit = tonumber(os.getenv("BASE_BAN_LIMIT")) or 30
local base_ban_expire = tonumber(os.getenv("BASE_BAN_EXPIRE")) or 600
local super_ban_limit = tonumber(os.getenv("SUPER_BAN_LIMIT")) or 100
local super_expire = tonumber(os.getenv("SUPER_EXPIRE")) or 3600

-- redis
local function close_redis(red)
   if not red then
       return
   end
   local pool_max_idle_time = 10000
   local pool_size = 100
   local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)

   if not ok then
       ngx.log(ngx.ERR, "set redis keepalive error: ", err)
   end
end

-- redis connect
-- if redis connect error, pass request
local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect("192.168.88.73", "6379")
if not ok then
   ngx.log(ngx.ERR, "failed to connect: ", err)
   return
end

-- get remote ip address
-- local tmp_str = "1.1.1.1, 2.2.2.2"
-- if tmp_str ~= nil and string.len(tmp_str) >15  then
--    local from, to, err  = ngx.re.find(tmp_str, ",", "jo")
--    ngx.log(ngx.ERR, "from: ", from, " to: ", to)
--    tmp_str = string.sub(tmp_str, 1, from - 1)
-- end
-- ngx.log(ngx.ERR, "new_str: ", tmp_str)
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
local host = ngx.req.get_headers()["Host"]
local redis_ban_key = "super_blacklist:" .. remote_ip
if base_counts >= super_ban_limit then
   dict:set(filter_key, base_counts, super_expire)
   dict:incr(filter_key, 1)
   local o = red:GET(redis_ban_key)
   if o == ngx.null then
      ngx.log(ngx.ERR, "set redis key: ", redis_ban_key)
      local t_key = host .. ":" .. remote_ip
      red:SET(redis_ban_key, t_key)
      red:EXPIRE(redis_ban_key, super_expire)
   end
   close_redis(red)
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