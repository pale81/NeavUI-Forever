local select = select

if not C_AddOns.IsAddOnLoaded("Blizzard_TimeManager") then
    C_AddOns.LoadAddOn("Blizzard_TimeManager")
end

    -- The default calendar button shows the day with atlas textures, they are replaced by text.

local function SetDateText()
    for _, texture in pairs({
        GameTimeFrame:GetNormalTexture(),
        GameTimeFrame:GetPushedTexture(),
        GameTimeFrame:GetHighlightTexture(),
    }) do
        texture:SetAlpha(0)
    end

    GameTimeFrame:SetText(C_DateAndTime.GetCurrentCalendarTime().monthDay)

    local fontString = GameTimeFrame:GetFontString()
    fontString:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
    fontString:SetShadowOffset(0, 0)
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPRIGHT", GameTimeFrame)
end

hooksecurefunc("GameTimeFrame_SetDate", SetDateText)
SetDateText()

GameTimeFrame:SetParent(Minimap)
GameTimeFrame:SetSize(14, 14)
GameTimeFrame:SetHitRectInsets(0, 0, 0, 0)
GameTimeFrame:ClearAllPoints()
GameTimeFrame:SetPoint("TOPRIGHT", Minimap, -3.5, -3.5)

local classColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

for _, texture in pairs({
    GameTimeCalendarEventAlarmTexture,
    GameTimeCalendarInvitesTexture,
    GameTimeCalendarInvitesGlow,
    TimeManagerAlarmFiredTexture,
}) do
    texture:SetTexture(nil)

    if texture:IsShown() then
        GameTimeFrame:GetFontString():SetTextColor(1, 0, 1)
    else
        GameTimeFrame:GetFontString():SetTextColor(classColor.r, classColor.g, classColor.b)
    end

    hooksecurefunc(texture, "Show", function()
        GameTimeFrame:GetFontString():SetTextColor(1, 0, 1)
    end)

    hooksecurefunc(texture, "Hide", function()
        GameTimeFrame:GetFontString():SetTextColor(classColor.r, classColor.g, classColor.b)
    end)
end
