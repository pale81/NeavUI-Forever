local _, nMinimap = ...
local cfg = nMinimap.Config

local cluster = MinimapCluster

    -- A "new" mail notification

    -- The mail frame calls GetParent():Layout() on mail updates, so it needs a
    -- parent with a Layout method.

local mailHolder = CreateFrame("Frame", nil, Minimap)
mailHolder:SetAllPoints(Minimap)
mailHolder.Layout = function() end

local mailFrame = cluster.IndicatorFrame.MailFrame
mailFrame:SetParent(mailHolder)
mailFrame:SetSize(14, 14)
mailFrame:ClearAllPoints()
mailFrame:SetPoint("BOTTOMRIGHT", Minimap, -4, 5)

for _, region in pairs({
    mailFrame.MailIcon,
    mailFrame.NewMailFlipbook,
    mailFrame.MailReminderFlipbook,
}) do
    region:SetAlpha(0)
end

local MiniMapMailFrame_Text = mailFrame:CreateFontString(nil, "OVERLAY")
MiniMapMailFrame_Text:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
MiniMapMailFrame_Text:SetPoint("BOTTOMRIGHT", mailFrame)
MiniMapMailFrame_Text:SetTextColor(1, 0, 1)
MiniMapMailFrame_Text:SetText("N")

    -- Garrison/expansion landing page button

ExpansionLandingPageMinimapButton:HookScript("OnShow", function(self)
    self:ClearAllPoints()
    self:SetPoint("BOTTOMLEFT", Minimap, 0, 0)
    self:SetScale(0.7)
end)

    -- Hide all unwanted things

for _, frame in pairs({
    cluster.BorderTop,
    cluster.ZoneTextButton,
    cluster.Tracking,
    cluster.DielFrame,
    MinimapCompassTexture,
    MinimapCompassTextureUnderlay,
}) do
    frame:SetAlpha(0)

    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
end

    -- The zoom buttons are shown on mouseover by default.

for _, button in pairs({Minimap.ZoomIn, Minimap.ZoomOut}) do
    button:SetAlpha(0)
    button:EnableMouse(false)
end

    -- Hide the durability frame (the armored man)

DurabilityFrame:SetAlpha(0)
DurabilityFrame:UnregisterAllEvents()

    -- Smaller Vehicle/Mount Seat Indicator

VehicleSeatIndicator:SetScale(.75)

    -- New position and size. Edit Mode positions the MinimapCluster, so the minimap
    -- is moved out of it.

cluster:EnableMouse(false)

Minimap:SetParent(UIParent)
Minimap:SetScale(cfg.scale)
Minimap:SetFrameStrata("LOW")
Minimap:ClearAllPoints()
Minimap:SetPoint(unpack(cfg.location))

    -- Square minimap and create a border

function GetMinimapShape()
    return "SQUARE"
end

local function SetSquareMask()
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
end

SetSquareMask()
CVarCallbackRegistry:RegisterCallback("rotateMinimap", SetSquareMask, nMinimap)

Minimap:CreateBeautyBorder(11)
Minimap:SetBeautyBorderPadding(1)

    -- Mousewheel zooming is handled by the default UI.
    -- Right click opens the tracking menu.

Minimap:HookScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        cluster.Tracking.Button:OpenMenu()
    end
end)

    -- Skin the ticket status frame

TicketStatusFrame:ClearAllPoints()
TicketStatusFrame:SetPoint("BOTTOMRIGHT", UIParent, -25, -33)
TicketStatusFrameButton:HookScript("OnShow", function(self)
    if not self.SetBackdrop then
        Mixin(self, BackdropTemplateMixin)
    end

    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        insets = {
            left = 3,
            right = 3,
            top = 3,
            bottom = 3
        }
    })
    self:SetBackdropColor(0, 0, 0, 0.5)
    self:CreateBeautyBorder(12)
end)

local function GetZoneColor()
    local zoneType = C_PvP.GetZonePVPInfo()
    if zoneType == "sanctuary" then
        return 0.4, 0.8, 0.94
    elseif zoneType == "arena" then
        return 1, 0.1, 0.1
    elseif zoneType == "friendly" then
        return 0.1, 1, 0.1
    elseif zoneType == "hostile" then
        return 1, 0.1, 0.1
    elseif zoneType == "contested" then
        return 1, 0.8, 0
    else
        return 1, 1, 1
    end
end

    -- Mouseover zone text

if cfg.mouseover.zoneText then
    local MainZone = Minimap:CreateFontString(nil, "OVERLAY")
    MainZone:SetFont(STANDARD_TEXT_FONT, 15, "THINOUTLINE")
    MainZone:SetPoint("TOP", Minimap, 0, -22)
    MainZone:SetTextColor(1, 1, 1)
    MainZone:SetAlpha(0)
    MainZone:SetSize(130, 32)
    MainZone:SetJustifyV("BOTTOM")
    MainZone:SetWordWrap(true)
    MainZone:SetNonSpaceWrap(true)
    MainZone:SetMaxLines(2)

    local SubZone = Minimap:CreateFontString(nil, "OVERLAY")
    SubZone:SetFont(STANDARD_TEXT_FONT, 13, "THINOUTLINE")
    SubZone:SetPoint("TOP", MainZone, "BOTTOM", 0, -1)
    SubZone:SetTextColor(1, 1, 1)
    SubZone:SetAlpha(0)
    SubZone:SetSize(130, 26)
    SubZone:SetJustifyV("TOP")
    SubZone:SetWordWrap(true)
    SubZone:SetNonSpaceWrap(true)
    SubZone:SetMaxLines(2)

    Minimap:HookScript("OnEnter", function(self)
        if not IsShiftKeyDown() then
            SubZone:SetTextColor(GetZoneColor())
            SubZone:SetText(GetSubZoneText())
            securecall("UIFrameFadeIn", SubZone, 0.15, SubZone:GetAlpha(), 1)

            MainZone:SetTextColor(GetZoneColor())
            MainZone:SetText(GetRealZoneText())
            securecall("UIFrameFadeIn", MainZone, 0.15, MainZone:GetAlpha(), 1)
        end
    end)

    Minimap:HookScript("OnLeave", function(self)
        securecall("UIFrameFadeOut", SubZone, 0.15, SubZone:GetAlpha(), 0)
        securecall("UIFrameFadeOut", MainZone, 0.15, MainZone:GetAlpha(), 0)
    end)
end
