
local _, nTooltip = ...
local cfg = nTooltip.Config

if not cfg.healthbar.showHealthValue then
    return
end

local select = select
local tonumber = tonumber

local modf = math.modf
local gsub = string.gsub
local format = string.format

local bar = GameTooltipStatusBar
bar.Text = bar:CreateFontString(nil, "OVERLAY")
bar.Text:SetPoint("CENTER", bar, cfg.healthbar.textPos, 0, 1)

if cfg.healthbar.showOutline then
    bar.Text:SetFont(cfg.healthbar.font, cfg.healthbar.fontSize, "THINOUTLINE")
    bar.Text:SetShadowOffset(0, 0)
else
    bar.Text:SetFont(cfg.healthbar.font, cfg.healthbar.fontSize)
    bar.Text:SetShadowOffset(1, -1)
end

local function ColorGradient(perc, ...)
    if perc >= 1 then
        local r, g, b = select(select("#", ...) - 2, ...)
        return r, g, b
    elseif perc <= 0 then
        local r, g, b = ...
        return r, g, b
    end

    local num = select("#", ...) / 3

    local segment, relperc = modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

    return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function FormatValue(value)
    if value >= 1e6 then
        return tonumber(format("%.1f", value/1e6)).."m"
    elseif value >= 1e3 then
        return tonumber(format("%.1f", value/1e3)).."k"
    else
        return value
    end
end

local function DeficitValue(value)
    if value == 0 then
        return ""
    else
        return "-"..FormatValue(value)
    end
end

local function GetHealthTag(text, cur, max)
    local perc = format("%d", (cur/max)*100)

    if max == 1 then
        return perc
    end

    local r, g, b = ColorGradient(cur/max, 1, 0, 0, 1, 1, 0, 0, 1, 0)
    text = gsub(text, "$cur", format("%s", FormatValue(cur)))
    text = gsub(text, "$max", format("%s", FormatValue(max)))
    text = gsub(text, "$deficit", format("%s", DeficitValue(max-cur)))
    text = gsub(text, "$perc", format("%d", perc).."%%")
    text = gsub(text, "$smartperc", format("%d", perc))
    text = gsub(text, "$smartcolorperc", format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, perc))
    text = gsub(text, "$colorperc", format("|cff%02x%02x%02x%d", r*255, g*255, b*255, perc).."%%|r")

    return text
end

    -- The status bar only holds the (possibly secret) health percentage, so the text
    -- is built from the tooltip unit. A separate frame does the updates to keep this
    -- code out of the status bar's secure update path.

local function UpdateHealthText()
    local _, unit = GameTooltip:GetUnit()

    if not bar:IsShown() or not unit or issecretvalue(unit) or not UnitExists(unit) then
        bar.Text:SetText("")
        return
    end

    local value, max = UnitHealth(unit), UnitHealthMax(unit)

    if issecretvalue(value) or issecretvalue(max) then
        bar.Text:SetText(format("%s / %s", AbbreviateNumbers(value), AbbreviateNumbers(max)))
        return
    end

    if (value <= 0) or (value > max) or (max <= 1) then
        bar.Text:SetText("")
        return
    end

    if value >= max then
        bar.Text:SetText(GetHealthTag(cfg.healthbar.healthFullFormat, value, max))
    else
        bar.Text:SetText(GetHealthTag(cfg.healthbar.healthFormat, value, max))
    end
end

local updater = CreateFrame("Frame", nil, GameTooltip)
updater.elapsed = 0
updater:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed

    if self.elapsed >= 0.1 then
        self.elapsed = 0
        UpdateHealthText()
    end
end)

GameTooltip:HookScript("OnTooltipCleared", function()
    bar.Text:SetText("")
end)
