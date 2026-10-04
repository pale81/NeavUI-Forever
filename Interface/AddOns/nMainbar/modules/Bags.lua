local _, nMainbar = ...
local cfg = nMainbar.Config

if not cfg.showPicomenu then
    return
end

    -- Saved Variable Setup

if BagsShown == nil then
    BagsShown = false
end

    -- The bag bar and the micro menu are placed with Edit Mode. They are only made
    -- invisible and click-through, because hiding Edit Mode systems doesn't stick.

local function SetFrameShown(frame, shown)
    frame:SetAlpha(shown and 1 or 0)

    for _, child in pairs({frame:GetChildren()}) do
        if child.EnableMouse then
            child:EnableMouse(shown)
        end
    end
end

    -- The picomenu replaces the micro menu.

SetFrameShown(MicroMenuContainer, false)

local function UpdateBags()
    SetFrameShown(BagsBar, BagsShown)
end

    -- Used to toggle bag with keybind or slash command /neavbag.

function nMainbar_ToggleBags()
    BagsShown = not BagsShown
    UpdateBags()
end

    -- Hides or shows bags on start up depending on saved variable.

local addon = CreateFrame("Frame")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function()
    UpdateBags()
    SetFrameShown(MicroMenuContainer, false)
end)

        -- Slash Command

SlashCmdList["nBag_Toggle"] = function()
    nMainbar_ToggleBags()
end
SLASH_nBag_Toggle1 = "/neavbag"
