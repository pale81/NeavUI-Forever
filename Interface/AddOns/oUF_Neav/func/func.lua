
local _, ns = ...
local config = ns.Config

local select = select

local fmod = math.fmod
local floor = math.floor
local gsub = string.gsub
local format = string.format

local day, hour, minute = 86400, 3600, 60

    -- Red - yellow - green gradient for 0 - 1.

local function ColorGradient(perc)
    if perc >= 1 then
        return 0, 1, 0
    elseif perc <= 0 then
        return 1, 0, 0
    elseif perc < 0.5 then
        return 1, perc * 2, 0
    else
        return (1 - perc) * 2, 1, 0
    end
end

local function FormatValue(value)
    if value < 1e3 then
        return floor(value)
    elseif value >= 1e12 then
        return string.format("%.3ft", value/1e12)
    elseif value >= 1e9 then
        return string.format("%.3fb", value/1e9)
    elseif value >= 1e6 then
        return string.format("%.2fm", value/1e6)
    elseif value >= 1e3 then
        return string.format("%.1fk", value/1e3)
    end
end

local function DeficitValue(value)
    if value == 0 then
        return ""
    else
        return "-"..FormatValue(value)
    end
end

ns.cUnit = function(unit)
    if unit:match("vehicle") then
        return "player"
    elseif unit:match("party%d") then
        return "party"
    elseif unit:match("arena%d") then
        return "arena"
    elseif unit:match("boss%d") then
        return "boss"
    elseif unit:match("partypet%d") then
        return "pet"
    else
        return unit
    end
end

ns.FormatTime = function(time)
    if time >= day then
        return format("%dd", floor(time/day + 0.5))
    elseif time>= hour then
        return format("%dh", floor(time/hour + 0.5))
    elseif time >= minute then
        return format("%dm", floor(time/minute + 0.5))
    end

    return format("%d", fmod(time, minute))
end

local function GetUnitStatus(unit)
    if UnitIsDead(unit) then
        return DEAD
    elseif UnitIsGhost(unit) then
        return "Ghost"
    elseif not UnitIsConnected(unit) then
        return PLAYER_OFFLINE
    else
        return ""
    end
end

local function GetFormattedText(text, cur, max, alt)
    local perc = (cur/max)*100

    if alt then
        text = gsub(text, "$alt", ((alt > 0) and format("%s", FormatValue(alt)) or ""))
    end

    local r, g, b = ColorGradient(perc / 100)
    text = gsub(text, "$cur", format("%s", (cur > 0 and FormatValue(cur)) or ""))
    text = gsub(text, "$max", format("%s", FormatValue(max)))
    text = gsub(text, "$deficit", format("%s", DeficitValue(max-cur)))
    text = gsub(text, "$perc", format("%d", perc).."%%")
    text = gsub(text, "$smartperc", format("%d", perc))
    text = gsub(text, "$smartcolorperc", format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, perc))
    text = gsub(text, "$colorperc", format("|cff%02x%02x%02x%d", r*255, g*255, b*255, perc).."%%|r")

    return text
end

    -- Health and power values can be secret in restricted content. Secret values can't be
    -- compared or used in arithmetic, so the tag string is turned into a format string and
    -- the values are formatted with secret-safe API (string.format accepts secret values).

local SECRET_TAGS = {"$smartcolorperc", "$colorperc", "$smartperc", "$perc", "$deficit", "$cur", "$max", "$alt"}

local function GetSecretFormattedText(text, values)
    local args = {}

    text = gsub(text, "%%", "%%%%")

    local position = 1
    local formatString = ""

    while position <= #text do
        local found

        if text:sub(position, position) == "$" then
            for _, tag in ipairs(SECRET_TAGS) do
                if text:sub(position, position + #tag - 1) == tag then
                    found = tag
                    break
                end
            end
        end

        if found then
            formatString = formatString.."%s"
            args[#args + 1] = values[found] or ""
            position = position + #found
        else
            formatString = formatString..text:sub(position, position)
            position = position + 1
        end
    end

    return format(formatString, unpack(args))
end

local function GetSecretHealthValues(unit, cur, max)
    local perc = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)

    return {
        ["$cur"] = AbbreviateNumbers(cur),
        ["$max"] = AbbreviateNumbers(max),
        ["$deficit"] = C_StringUtil.TruncateWhenZero(UnitHealthMissing(unit, true)),
        ["$perc"] = format("%d%%", perc),
        ["$smartperc"] = format("%d", perc),
        ["$colorperc"] = format("%d%%", perc),
        ["$smartcolorperc"] = format("%d", perc),
    }
end

local function GetSecretPowerValues(unit, cur, max)
    local perc = UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100)

    return {
        ["$cur"] = AbbreviateNumbers(cur),
        ["$max"] = AbbreviateNumbers(max),
        ["$deficit"] = C_StringUtil.TruncateWhenZero(UnitPowerMissing(unit)),
        ["$perc"] = format("%d%%", perc),
        ["$smartperc"] = format("%d", perc),
        ["$colorperc"] = format("%d%%", perc),
        ["$smartcolorperc"] = format("%d", perc),
        ["$alt"] = "",
    }
end

ns.GetHealthText = function(unit, cur, max)
    local uconf = config.units[ns.cUnit(unit)]

    if not issecretvalue(cur) and not cur then
        cur = UnitHealth(unit)
        max = UnitHealthMax(unit)
    end

    if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
        return GetUnitStatus(unit)
    end

    if issecretvalue(cur) or issecretvalue(max) then
        local values = GetSecretHealthValues(unit, cur, max)
        return GetSecretFormattedText(uconf and uconf.healthTag or "$cur/$max", values)
    end

    local healthString
    if cur == max and uconf and uconf.healthTagFull then
        healthString = GetFormattedText(uconf.healthTagFull, cur, max)
    elseif uconf and uconf.healthTag then
        healthString = GetFormattedText(uconf.healthTag, cur, max)
    else
        if cur == max then
            healthString = FormatValue(cur)
        else
            healthString = FormatValue(cur).."/"..FormatValue(max)
        end
    end

    return healthString
end

ns.GetPowerText = function(unit, cur, max)
    local uconf = config.units[ns.cUnit(unit)]

    if not issecretvalue(cur) and not cur then
        cur = UnitPower(unit)
        max = UnitPowerMax(unit)
    end

    if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
        return ""
    end

    local powerType = UnitPowerType(unit)
    local hasMana = powerType == Enum.PowerType.Mana and not UnitHasVehicleUI(unit)

    if issecretvalue(cur) or issecretvalue(max) then
        local values = GetSecretPowerValues(unit, cur, max)
        local tag = uconf and ((not hasMana and uconf.powerTagNoMana) or uconf.powerTag) or "$cur/$max"
        return GetSecretFormattedText(tag, values)
    end

    local alt = UnitPower(unit, ALTERNATE_POWER_INDEX)
    if issecretvalue(alt) then
        alt = nil
    end

    local powerString
    if max == 0 then
        powerString = ""
    elseif not hasMana and uconf and uconf.powerTagNoMana then
        powerString = GetFormattedText(uconf.powerTagNoMana, cur, max, alt)
    elseif (cur == max) and uconf and uconf.powerTagFull then
        powerString = GetFormattedText(uconf.powerTagFull, cur, max, alt)
    elseif uconf and uconf.powerTag then
        powerString = GetFormattedText(uconf.powerTag, cur, max, alt)
    else
        if cur == max then
            powerString = FormatValue(cur)
        else
            powerString = FormatValue(cur).."/"..FormatValue(max)
        end
    end

    return powerString
end

    -- Class colors for players, reaction colors otherwise (from !Colorz, the default
    -- UI colors without it). The returned color can be secret.

ns.GetUnitColor = function(unit)
    if Colorz_GetUnitColor then
        return Colorz_GetUnitColor(unit)
    end

    return GameTooltip_UnitColor(unit)
end

    -- oUF 14 keeps the unit in frame.__unit, the default UnitFrame_OnEnter reads
    -- frame.unit and would call GameTooltip:SetUnit(nil).

ns.UnitFrame_OnEnter = function(self)
    local unit = self.__unit
    if not unit then
        return
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetUnit(unit)
end

ns.MultiCheck = function(what, ...)
    for i = 1, select("#", ...) do
        if what == select(i, ...) then
            return true
        end
    end

    return false
end

ns.utf8sub = function(string, index)
    local bytes = string:len()
    if bytes <= index then
        return string
    else
        local length, currentIndex = 0, 1

        while currentIndex <= bytes do
            length = length + 1
            local char = string:byte(currentIndex)

            if char > 240 then
                currentIndex = currentIndex + 4
            elseif char > 225 then
                currentIndex = currentIndex + 3
            elseif char > 192 then
                currentIndex = currentIndex + 2
            else
                currentIndex = currentIndex + 1
            end

            if length == index then
                break
            end
        end

        if length == index and currentIndex <= bytes then
            return string:sub(1, currentIndex - 1)
        else
            return string
        end
    end
end
