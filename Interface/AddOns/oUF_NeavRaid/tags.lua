local _, ns = ...

local tags = oUF.Tags.Methods
local events = oUF.Tags.Events
local timer = {}

tags["status:raid"] = function(unit)
    local name = UnitName(unit)
    local isAFK = UnitIsAFK(unit)

        -- Names and the AFK flag can be secret, they can't be used as table keys or
        -- in conditions then.

    if issecretvalue(name) or issecretvalue(isAFK) then
        return
    end

    name = name or UNKNOWN

    if isAFK or not UnitIsConnected(unit) then
        if not timer[name] then
            timer[name] = GetTime()
        end

        local time = GetTime() - timer[name]

        return ns.FormatTime(time)
    elseif timer[name] then
        timer[name] = nil
    end
end
events["status:raid"] = "PLAYER_FLAGS_CHANGED UNIT_CONNECTION"


tags["name:raid"] = function(unit)
    local name = UnitName(unit)

    if issecretvalue(name) then
        return name
    end

    return ns.utf8sub(name or UNKNOWN)
end
events["name:raid"] = "UNIT_NAME_UPDATE"
