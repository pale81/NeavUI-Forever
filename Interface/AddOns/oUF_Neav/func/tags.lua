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

    -- Name, colored with C_ColorUtil.WrapTextInColor, which accepts secret names and
    -- colors. Player and party: class color, target of target: unit color (class
    -- color for players), other units: white.

local NAME_WHITE = CreateColor(1, 1, 1)
local NAME_GREEN = CreateColor(0, 1, 0)

local function GetNameColor(unit)
    if unit == "player" or unit:match("party") then
        local _, class = UnitClass(unit)

        if issecretvalue(class) then
            return C_ClassColor.GetClassColor(class)
        elseif class and oUF.colors.class[class] then
            return oUF.colors.class[class]
        else
            return NAME_GREEN
        end
    elseif unit == "targettarget" or unit == "focustarget" then
        return CreateColor(ns.GetUnitColor(unit))
    else
        return NAME_WHITE
    end
end

    -- WoW Forever characters have a surname, UnitName returns it as second value.

local SURNAME_SEPARATOR = Constants.CharacterNameSeparatorConsts and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "

local function GetFullName(unit)
    local name, surname = UnitName(unit)

    if not issecretvalue(surname) and (not surname or surname == "") then
        return name
    elseif issecretvalue(name) or issecretvalue(surname) then
        return format("%s%s%s", name, SURNAME_SEPARATOR, surname)
    end

    return name and name..SURNAME_SEPARATOR..surname
end

tags["neav:name"] = function(unit)
    local name = GetFullName(unit)

    if not issecretvalue(name) then
        name = name or UNKNOWN
        name = (len(name) > 15) and gsub(name, "%s?(.[\128-\191]*)%S+%s", "%1. ") or name
    end

    return C_ColorUtil.WrapTextInColor(name, GetNameColor(unit))
end
events["neav:name"] = "UNIT_NAME_UPDATE UNIT_FACTION"

local timer = {}

tags["neav:afk"] = function(unit)
    local name = UnitName(unit)
    local isAFK = UnitIsAFK(unit)

    if issecretvalue(name) or issecretvalue(isAFK) then
        return
    end

    name = name or UNKNOWN

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
