--!nonstrict

local busy = false
local actions = {
    status = true, launch = true, ["open-videos"] = true, ["save-replay"] = true,
    ["toggle-record"] = true, ["toggle-replay"] = true, ["toggle-stream"] = true,
}

local function run(action)
    if busy or not actions[action] then return end
    busy = true
    chiroptera.state.set("busy", true)
    local argv = {
        chiroptera.expandPath(chiroptera.getConfig("python_executable")),
        chiroptera.pluginDir() .. "/obs_control.py", action,
    }
    if chiroptera.getConfig("auto_close_managed_obs") then table.insert(argv, "--auto-close") end
    if chiroptera.getConfig("open_videos_after_stop") then table.insert(argv, "--open-videos") end
    local accepted = chiroptera.runAsync(argv, function(result)
        busy = false
        chiroptera.state.set("busy", false)
        local data = chiroptera.json.decode(result.stdout or "")
        if type(data) ~= "table" then
            data = { connected = false, error = chiroptera.tr("helper-failed") }
        end
        chiroptera.state.set("status", data)
        if action ~= "status" then
            chiroptera.notify("OBS Control", data.error or data.message or chiroptera.tr("done"))
        end
    end, 30000)
    if not accepted then
        busy = false
        chiroptera.state.set("busy", false)
        chiroptera.state.set("status", { connected = false, error = chiroptera.tr("helper-failed") })
    end
end

chiroptera.setUpdateInterval(chiroptera.getConfig("poll_interval_ms"))
chiroptera.state.watch("action", run)

function update() run("status") end
function onIpc(event, _payload) run(event) end

run("status")
