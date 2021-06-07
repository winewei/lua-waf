-- access filter
require "resty.core"
local redis = require "resty.redis"

local base_count_ttl = tonumber(os.getenv("BASE_COUNT_TTL")) or 10
local base_ban_limit = tonumber(os.getenv("BASE_BAN_LIMIT")) or 30
local base_ban_ttl = tonumber(os.getenv("BASE_BAN_TTL")) or 600
local super_ban_limit = tonumber(os.getenv("SUPER_BAN_LIMIT")) or 100
local super_ban_ttl = tonumber(os.getenv("SUPER_BAN_TLL")) or 3600
local redishost = os.getenv("REDISHOST") or nil
local redisport = os.getenv("REDISPORT") or "6379"

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
if redishost ~= nil then
   local ok, err = red:connect(redishost, redisport)
   if not ok then
      ngx.log(ngx.ERR, "failed to connect: ", err)
      return
   end
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

dict:safe_add(filter_key, 1, base_count_ttl)

-- save in nginx shared memory
local request_count, err = dict:get(filter_key)

-- filter
local hostname = ngx.var.http_host
local redis_ban_key = "super_blacklist:" .. hostname .. ":".. remote_ip
if request_count >= super_ban_limit then
   dict:set(filter_key, request_count, super_ban_ttl)
   dict:incr(filter_key, 1)

   local set_redis_key = "set_redis_key:" .. redis_ban_key
   local ok, err = dict:get(set_redis_key)
   if redishost ~= nil then
      if ok == nil then
            dict:set(set_redis_key, 1, base_count_ttl)
            ngx.log(ngx.ERR, "set redis key: ", redis_ban_key)
            ngx.log(ngx.ERR, "super_ban ==> ", "count: ", request_count, " , key: ", filter_key)
            red:SET(redis_ban_key, 1)
            red:EXPIRE(redis_ban_key, super_ban_ttl)
      end
      close_redis(red)
   end
   ngx.exit(403)
elseif request_count >= base_ban_limit then
   dict:set(filter_key, request_count, base_ban_ttl)
   dict:incr(filter_key, 1)
   ngx.log(ngx.ERR, "base_ban ==> ", "count: ", request_count, " , key: ", filter_key)
   ngx.exit(403)
else
   dict:incr(filter_key, 1)
end
