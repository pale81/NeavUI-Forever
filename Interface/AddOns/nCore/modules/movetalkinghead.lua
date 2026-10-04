local _, nCore = ...

function nCore:MoveTalkingHeads()
    if not nCoreDB.MoveTalkingHeads then return end

    local L = nCore.L

    local location = {"LEFT", UIParent, "LEFT", 0, 0}
    local AlertFrameAnchor = nCore:CreateAnchor("AlertFrame", 570, 155, location)

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" then
            AlertFrame:ClearAllPoints()
            AlertFrame:SetParent(AlertFrameAnchor)
            AlertFrame:SetPoint("BOTTOM", AlertFrameAnchor)
        end
    end)

        -- The talking head frame is positioned with Edit Mode.

    SlashCmdList["AlertFrameAnchor_AnchorToggle"] = function()
        if InCombatLockdown() then
            print(L.CombatWarning)
            return
        end
        if not AlertFrameAnchor:IsShown() then
            AlertFrameAnchor:Show()
        else
            AlertFrameAnchor:Hide()
        end
    end
    SLASH_AlertFrameAnchor_AnchorToggle1 = "/alertframemover"
end
