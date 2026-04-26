module("luci.controller.dejede.control", package.seeall)

function index()
    entry({"admin","system","control"}, template("dejede/control"), _("Dejede Control Panel"), 90)

    entry({"admin","system","led_off"}, call("led_off")).leaf=true
    entry({"admin","system","led_on"}, call("led_on")).leaf=true
    entry({"admin","system","reboot_router"}, call("reboot_router")).leaf=true
    entry({"admin","system","shutdown_router"}, call("shutdown_router")).leaf=true
    entry({"admin","system","clear_ram"}, call("clear_ram")).leaf=true
    entry({"admin","system","apply_schedule"}, call("apply_schedule")).leaf=true

    -- ✅ FIX TOTAL: PUBLIC API (NO LOGIN)
    entry({"dejede","status"}, call("status_router")).leaf=true
    entry({"dejede","temp"}, call("get_temp")).leaf=true
end

local http = require "luci.http"
local sys = require "luci.sys"

function json(msg)
    http.prepare_content("application/json")
    http.write_json({message=msg})
end

-- LED ON
function led_on()
    os.execute("for i in /sys/class/leds/*; do echo default-on > $i/trigger 2>/dev/null; echo 1 > $i/brightness 2>/dev/null; done")
    json("LED ON")
end

-- LED OFF
function led_off()
    os.execute("for i in /sys/class/leds/*; do echo none > $i/trigger 2>/dev/null; echo 0 > $i/brightness 2>/dev/null; done")
    json("LED OFF")
end

-- REBOOT
function reboot_router()
    json("Rebooting...")
    os.execute("reboot")
end

-- SHUTDOWN
function shutdown_router()
    json("Shutdown...")
    os.execute("poweroff")
end

-- CLEAR RAM
function clear_ram()
    os.execute("sync && echo 3 > /proc/sys/vm/drop_caches")
    json("RAM Cleared")
end

-- SCHEDULE
function apply_schedule()
    os.execute("sed -i '/led_schedule/d' /etc/crontabs/root")

    os.execute("echo '0 21 * * * /bin/sh -c \"for i in /sys/class/leds/*; do echo none > $i/trigger 2>/dev/null; echo 0 > $i/brightness 2>/dev/null; done\" # led_schedule' >> /etc/crontabs/root")

    os.execute("echo '0 5 * * * /bin/sh -c \"for i in /sys/class/leds/*; do echo default-on > $i/trigger 2>/dev/null; echo 1 > $i/brightness 2>/dev/null; done\" # led_schedule' >> /etc/crontabs/root")

    os.execute("/etc/init.d/cron restart")

    json("Schedule Applied: OFF 21:00 | ON 05:00")
end

-- TEMPERATURE (LEBIH KOMPATIBEL)
function get_temp()
    local function read_temp(path)
        local f = io.open(path, "r")
        if f then
            local v = f:read("*all")
            f:close()
            if v then
                local n = tonumber(v)
                if n then
                    return string.format("%.1f°C", n / 1000)
                end
            end
        end
        return "N/A"
    end

    local t1 = read_temp("/sys/devices/platform/soc/a000000.wifi/hwmon/hwmon0/temp1_input")
    local t2 = read_temp("/sys/devices/platform/soc/a800000.wifi/hwmon/hwmon1/temp1_input")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        temperature = "2.4G: " .. t1 .. " | 5G: " .. t2
    })
end

-- STATUS (LEBIH STABIL)
function status_router()
    local sys = require "luci.sys"

    local uptime = sys.uptime()
    uptime = string.format("%dd %dh %dm",
        math.floor(uptime/86400),
        math.floor((uptime/3600)%24),
        math.floor((uptime/60)%60)
    )

    -- ✅ CPU dari /proc/loadavg (AMAN SEMUA DEVICE)
    local load = sys.exec("cat /proc/loadavg | awk '{print $1}'")
    load = load:gsub("\n","")

    -- ✅ MEMORY
    local mem = sys.exec("free | grep Mem")
    local total, used = mem:match("(%d+)%s+(%d+)")

    total = tonumber(total) or 1
    used = tonumber(used) or 0

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        uptime = uptime,
        cpu = load,
        memory_used = used,
        memory_total = total
    })
end
