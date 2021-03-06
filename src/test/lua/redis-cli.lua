package.cpath = 'lib/?.so;'

local chuck = require("chuck")
local event_loop = chuck.event_loop.New()
local redis = chuck.redis
local redis_conn


function redis_execute(cmd,...)
	local result = nil
	local execute_return = false
	local ret = redis_conn:Execute(function(reply,err)
		if not err then
			print("Execute ok")
		else
			print("Execute error:" .. err)
		end
		result = reply
		execute_return = true
	end,cmd,...)
	
	if not ret then
		while not execute_return do
			event_loop:Run(100)
		end

		return result
	else
		print("Execute error:" .. ret)
		return nil
	end
end

local function do_command(str)
	local func = load(str)
	if func then
		func()
	end
end

local function read_command()
	local chunk = ""

	local prompt = ">>"

	while true do
		local cmd_line = chuck.Readline(prompt)
		if #cmd_line > 1 then
			if string.byte(cmd_line,#cmd_line) ~= 92 then
				chunk = chunk .. cmd_line
				break
			else
			  	chunk = chunk .. string.sub(cmd_line,1,#cmd_line-1) .. "\n"
				prompt = ">>>"
			end
		else
			break
		end	
	end

	if chunk ~= "" then
		if chunk == "exit" then
			redis_conn = nil
		else
			do_command(chunk)
		end
	end
end


if arg == nil or #arg ~= 2 then
	print("useage:lua redis-cli.lua ip port")
else
   local ip,port = arg[1],arg[2]
   local stop
   redis.Connect_ip4(event_loop,ip,port,function (conn)
   	redis_conn = conn
   	stop = true
   	if not redis_conn then
   		print(string.format("connect to redis server %s:%d failed",ip,port))
   	else
   		print("hello to redis-cli.lua! use \\ to sperate mutil line!use exit to terminate!")
   	end
   end)

   while not stop do
   	event_loop:Run(100)
   end

   while redis_conn do
   		read_command()	
   end
end	


--[[
test
redis_execute("hmset","chaid:1","chainfo","fasdfasfasdfasdfasdfasfasdfasfasdfdsaf","skills","fasfasdfasdfasfasdfasdfasdfcvavasdfasdf")\
result = redis_execute("hmget","chaid:1","chainfo","skills")\
print(result[1],result[2])
]]--