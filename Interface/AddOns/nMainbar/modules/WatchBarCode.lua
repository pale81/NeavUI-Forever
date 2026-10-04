local _, nMainbar = ...
local cfg = nMainbar.Config

    -- Status tracking bars (experience, reputation, honor, ...)

for _, container in pairs(StatusTrackingBarManager.barContainers) do
    for barIndex, bar in pairs(container.bars) do
        local text = bar.OverlayFrame and bar.OverlayFrame.Text
        if text then
            text:SetFont(cfg.button.watchbarFont, cfg.button.watchbarFontsize, "OUTLINE")
            text:SetShadowOffset(0, 0)
        end

            -- Alt + click on the reputation bar opens the reputation frame.

        if barIndex == StatusTrackingBarInfo.BarsEnum.Reputation then
            bar:HookScript("OnMouseDown", function(self, button)
                if not nMainbar:IsTaintable() and IsAltKeyDown() then
                    ToggleCharacter("ReputationFrame")
                end
            end)
        end
    end
end
