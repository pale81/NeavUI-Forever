local _, nMinimap = ...
local cfg = nMinimap.Config

    -- Capture bars and other world state widgets are shown in the "below minimap"
    -- widget container, which is placed by the right managed frame layout.

local container = UIWidgetBelowMinimapContainerFrame

local function AnchorBelowMinimap(self, _, relativeTo)
    if relativeTo ~= Minimap then
        self:ClearAllPoints()
        self:SetPoint("TOP", Minimap, "BOTTOM", 0, cfg.tab.showBelowMinimap and -30 or -10)
    end
end

hooksecurefunc(container, "SetPoint", AnchorBelowMinimap)
AnchorBelowMinimap(container)
