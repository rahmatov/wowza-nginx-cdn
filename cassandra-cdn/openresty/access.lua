--fast concaternation of strings
function listvalues(s)
    local t = { }
    for k,v in ipairs(s) do
        t[#t+1] = tostring(v)
    end
    return table.concat(t)
end

--read request
ngx.req.read_body()
 
--connect to redis
local redis = require "resty.redis"
local red = redis.new()
red.connect(red, '127.0.0.1', '6379')

--get variables from url         
local Token = ngx.var.arg_h

--search in redis for active session         
--when user logs for the first time we set token in redis from login php script
local UserSessions = red:get(Token)
UserSessions = tonumber(UserSessions)

local hasValidToken = 0
if UserSessions >= 1 then
    hasValidToken = 1
end

--disconnect user if not supply correct data
if Token == nil or hasValidToken == 0 then
    ngx.say("No valid token. Get out!")
    ngx.say(Token)
    ngx.say(UserSessions)
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

local MaxSessions=600

if UserSessions > MaxSessions then
    ngx.say(listvalues{"Too many connections: ", UserSessions, " of ",MaxSessions, " allowed for this time period for this token!"})
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

UserSessions=tonumber(UserSessions + 1)

--increment user sessions number
local ok, err = red:set(Token, UserSessions)
if not ok then
    ngx.say("failed to increment user sessions: ", err)
    return
end

-- put it into the connection pool of size 1000,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 1000)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
