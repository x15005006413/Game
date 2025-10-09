local skynet = require "skynet"

local debug_port = tonumber(skynet.getenv("debug_console_port")) or 4040

skynet.start(function()
    skynet.error("[main.lua] start")

    if not skynet.getenv "daemon" then
        -- 不是 daemon 模式启动则开启 console 服务
		local console = skynet.newservice("console")
	end
    -- 开启 debug console 服务
    skynet.newservice("debug_console", debug_port)

    -- main 服务只作为入口，启动完所需的服务后就可以退出
    skynet.exit()
end)
