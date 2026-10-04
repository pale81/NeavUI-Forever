local _, ns = ...

local len = string.len
local gsub = string.gsub
local format = string.format
local floor = math.floor

local tags = oUF.Tags.Methods
local events = oUF.Tags.Events

    -- Tag values can be secret in restricted content. Secret values can't be compared or
    -- used in arithmetic, so they are only passed to secret-safe API (e.g. string.format).

local function FormatValue(value)
    if value >= 1e6 then
        return tonumber(format("%.1f", value/1e6)).."m"
    elseif value >= 1e3 then
        return tonumber(format("%.1f", value/1e3)).."k"
    else
        return value
    end
end

tags["neav:AdditionalPower"] = function(unit)
    local min, max = UnitPower(unit, Enum.PowerType.Mana), UnitPowerMax(unit, Enum.PowerType.Mana)

    if issecretvalue(min) or issecretvalue(max) then
        return format("%s/%s", AbbreviateNumbers(min), AbbreviateNumbers(max))
    elseif min == max then
        return FormatValue(min)
    else
        return FormatValue(min).."/"..FormatValue(max)
    end
end
events["neav:AdditionalPower"] = "UNIT_POWER_UPDATE UNIT_DISPLAYPOWER UNIT_MAXPOWER"

tags["neav:pvptimer"] = function(unit)
    if not IsPVPTimerRunning() or GetPVPTimer() == 301000 or GetPVPTimer() == 999 then
        return ""
    end

    return ns.FormatTime(floor(GetPVPTimer()/1000))
end
events["neav:pvptimer"] = "PLAYER_ENTERING_WORLD PLAYER_FLAGS_CHANGED"

tags["neav:level"] = function(unit)
    local r, g, b
    local targetEffectiveLevel = UnitEffectiveLevel(unit)

    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        targetEffectiveLevel = UnitBattlePetLevel(unit)
        r, g, b = 1.0, 0.82, 0.0
    elseif targetEffectiveLevel > 0 then
        if UnitCanAttack("player", unit) then
            local color = GetCreatureDifficultyColor(targetEffectiveLevel)
            r, g, b = color.r, color.g, color.b
        else
            r, g, b = 1.0, 0.82, 0.0
        end
    else
        r, g, b = 1, 0, 0
        targetEffectiveLevel = "??"
    end

    return format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, targetEffectiveLevel)
end
events["neav:level"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"

    -- Name color. Used as "[neav:namecolor][neav:name]|r", because a (possibly secret)
    -- name can't be concatenated with the color code.

tags["neav:namecolor"] = function(unit)
    if unit == "player" or unit:match("party") then
        local _, class = UnitClass(unit)

        if class then
            if issecretvalue(class) then
                return C_ClassColor.GetClassColor(class):GenerateHexColorMarkup()
            else
                return oUF.colors.class[class]:GenerateHexColorMarkup()
            end
        else
            return "|cff00ff00"
        end
    elseif unit == "targettarget" or unit == "focustarget" or unit:match("arena(%d)target") then
        local r, g, b = UnitSelectionColor(unit)
        return format("|cff%02x%02x%02x", r*255, g*255, b*255)
    else
        return "|cffffffff"
    end
end
events["neav:namecolor"] = "UNIT_NAME_UPDATE UNIT_FACTION"

tags["neav:name"] = function(unit)
    local name = UnitName(unit) or UNKNOWN

    if issecretvalue(name) then
        return name
    end

    return (len(name) > 15) and gsub(name, "%s?(.[\128-\191]*)%S+%s", "%1. ") or name
end
events["neav:name"] = "UNIT_NAME_UPDATE"

local timer = {}

tags["neav:afk"] = function(unit)
    local name = UnitName(unit) or UNKNOWN
    local isAFK = UnitIsAFK(unit)

    if issecretvalue(name) or issecretvalue(isAFK) then
        return
    end

    if isAFK then
        if not timer[name] then
            timer[name] = GetTime()
        end

        local time = (GetTime() - timer[name])

        return ns.FormatTime(time)
    elseif timer[name] then
        timer[name] = nil
    end
end
events["neav:afk"] = "PLAYER_FLAGS_CHANGED"
