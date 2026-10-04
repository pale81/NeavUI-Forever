
    -- Sets manabar color for default unit frames.

local function CustomManaColor(manaBar)
    local powerType = UnitPowerType(manaBar.unit)

    if powerType == 0 then
        manaBar:SetStatusBarColor(0.0, 0.55, 1.0)
    end
end
hooksecurefunc("UnitFrameManaBar_UpdateType", CustomManaColor)

    -- Set faction colors for Repuation Frame and tracking bar.

local TOOLTIP_FACTION_COLORS = {
    [1] = {r = 1, g = 0, b = 0},
    [2] = {r = 1, g = 0, b = 0},
    [3] = {r = 1, g = 1, b = 0},
    [4] = {r = 1, g = 1, b = 0},
    [5] = {r = 0, g = 1, b = 0},
    [6] = {r = 0, g = 1, b = 0},
    [7] = {r = 0, g = 1, b = 0},
    [8] = {r = 0, g = 1, b = 0},
}

local CUSTOM_FACTION_BAR_COLORS = {
    [1] = {r = 0.63, g = 0, b = 0},
    [2] = {r = 0.63, g = 0, b = 0},
    [3] = {r = 0.63, g = 0, b = 0},
    [4] = {r = 0.82, g = 0.67, b = 0},
    [5] = {r = 0.32, g = 0.67, b = 0},
    [6] = {r = 0.32, g = 0.67, b = 0},
    [7] = {r = 0.32, g = 0.67, b = 0},
    [8] = {r = 0, g = 0.75, b = 0.44},
}

    -- The reputation frame passes FACTION_BAR_COLORS[reaction] to UpdateBarColor.
    -- The status tracking bar uses reaction colored atlases, so it needs no override.

local function GetFactionColorIndex(color)
    for index, factionColor in pairs(FACTION_BAR_COLORS) do
        if factionColor == color then
            return index
        end
    end
end

hooksecurefunc(ReputationBarMixin, "UpdateBarColor", function(self, color)
    local colorIndex = GetFactionColorIndex(color)
    local customColor = colorIndex and CUSTOM_FACTION_BAR_COLORS[colorIndex]

    if customColor then
        self.Fill:SetVertexColor(customColor.r, customColor.g, customColor.b)
    end
end)

    -- Custom unit colors for the unit name line of tooltips.
    -- Overriding GameTooltip_UnitColor would taint the tooltip code, so the color
    -- is applied by a line callback that runs after the default one.

local function GetUnitColor(unit)
    local r, g, b

    if UnitIsDead(unit) or UnitIsGhost(unit) or UnitIsTapDenied(unit) then
        r = 0.5
        g = 0.5
        b = 0.5
    elseif UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if issecretvalue(class) then
            r, g, b = C_ClassColor.GetClassColor(class):GetRGB()
        elseif class then
            r = RAID_CLASS_COLORS[class].r
            g = RAID_CLASS_COLORS[class].g
            b = RAID_CLASS_COLORS[class].b
        else
            if UnitIsFriend(unit, "player") then
                r = 0.60
                g = 0.60
                b = 0.60
            else
                r = 1
                g = 0
                b = 0
            end
        end
    elseif UnitPlayerControlled(unit) then
        local isPVP = UnitIsPVP(unit)
        if UnitCanAttack(unit, "player") then
            if not UnitCanAttack("player", unit) then
                r = 157/255
                g = 197/255
                b = 255/255
            else
                r = 1
                g = 0
                b = 0
            end
        elseif UnitCanAttack("player", unit) then
            r = 1
            g = 1
            b = 0
        elseif not issecretvalue(isPVP) and isPVP then
            r = 0
            g = 1
            b = 0
        else
            r = 157/255
            g = 197/255
            b = 255/255
        end
    else
        local reaction = UnitReaction(unit, "player")

        if not issecretvalue(reaction) and reaction and TOOLTIP_FACTION_COLORS[reaction] then
            r = TOOLTIP_FACTION_COLORS[reaction].r
            g = TOOLTIP_FACTION_COLORS[reaction].g
            b = TOOLTIP_FACTION_COLORS[reaction].b
        else
            r = 157/255
            g = 197/255
            b = 255/255
        end
    end

    return r, g, b
end

    -- Shared with the other NeavUI addons (unit frame name colors), instead of
    -- overriding GameTooltip_UnitColor. The class color can be secret.

Colorz_GetUnitColor = GetUnitColor

TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitName, function(tooltip, lineData)
    local unit = lineData.unitToken
    if not issecretvalue(unit) and unit then
        local r, g, b = GetUnitColor(unit)
        if r then
            lineData.leftColor = CreateColor(r, g, b)
        end
    end
end)

    -- Override the name background on default unit frames.

local function UpdateReputationColor(self)
    if UnitPlayerControlled(self.unit) then
        local r, g, b = GetUnitColor(self.unit)
        if r then
            self.TargetFrameContent.TargetFrameContentMain.ReputationColor:SetVertexColor(r, g, b)
        end
    end
end

for _, frame in ipairs({TargetFrame, FocusFrame}) do
    if frame and frame.CheckFaction then
        hooksecurefunc(frame, "CheckFaction", UpdateReputationColor)
    end
end
