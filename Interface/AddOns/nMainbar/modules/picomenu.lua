local _, nMainbar = ...
local cfg = nMainbar.Config

if not cfg.showPicomenu then
    return
end

    -- Pico Menu

local PICOMENU_TEXTURE = "Interface\\AddOns\\nMainbar\\Media\\picomenu\\"

    -- The entries open the same panels as the (hidden) micro menu buttons. Buttons that
    -- don't exist in this client or are disabled (e.g. by game rules) are skipped.

local microButtons = {
    "CharacterMicroButton",
    "ProfessionMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "PlayerSpellsMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "HelpMicroButton",
    "StoreMicroButton",
}

    -- Third-party addons

local addonEntries = {
    {
        text = "NeavRaid",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("oUF_NeavRaid")
        end,
        func = function()
            SlashCmdList["oUF_Neav_Raid_AnchorToggle"]("toggle")
        end,
    },
    {
        text = "VuhDo",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("VuhDo")
        end,
        func = function()
            SlashCmdList["VUHDO"]("toggle")
        end,
    },
    {
        text = "Grid",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Grid") or C_AddOns.IsAddOnLoaded("Grid2")
        end,
        func = function()
            if C_AddOns.IsAddOnLoaded("Grid2") then
                ToggleFrame(Grid2LayoutFrame)
            elseif C_AddOns.IsAddOnLoaded("Grid") then
                ToggleFrame(GridLayoutFrame)
            end
        end,
    },
    {
        text = "Omen",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Omen")
        end,
        func = function()
            if IsShiftKeyDown() then
                Omen:Toggle()
            else
                Omen:ShowConfig()
            end
        end,
    },
    {
        text = "PhoenixStyle",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("PhoenixStyle")
        end,
        func = function()
            ToggleFrame(PSFmain1)
            ToggleFrame(PSFmain2)
            ToggleFrame(PSFmain3)
        end,
    },
    {
        text = "DBM",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("DBM-Core")
        end,
        func = function()
            DBM:LoadGUI()
        end,
    },
    {
        text = "Skada",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Skada")
        end,
        func = function()
            Skada:ToggleWindow()
        end,
    },
    {
        text = "Recount",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Recount")
        end,
        func = function()
            ToggleFrame(Recount.MainWindow)
            if Recount.MainWindow:IsShown() then
                Recount:RefreshMainWindow()
            end
        end,
    },
    {
        text = "TinyDPS",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("TinyDPS")
        end,
        func = function()
            ToggleFrame(tdpsFrame)
        end,
    },
    {
        text = "Numeration",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Numeration")
        end,
        func = function()
            if not IsShiftKeyDown() then
                Numeration:ToggleVisibility()
            else
                StaticPopup_Show("RESET_DATA")
            end
        end,
    },
    {
        text = "AtlasLoot",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("AtlasLoot")
        end,
        func = function()
            AtlasLoot.GUI:Toggle()
        end,
    },
    {
        text = "Altoholic",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Altoholic")
        end,
        func = function()
            ToggleFrame(AltoholicFrame)
        end,
    },
    {
        text = "Details",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("Details")
        end,
        func = function()
            if not IsShiftKeyDown() then
                _detalhes:ToggleWindow(1)
                _detalhes:ToggleWindow(2)
            else
                _detalhes.tabela_historico:resetar()
            end
        end,
    },
    {
        text = "BigWigs",
        isLoaded = function()
            return C_AddOns.IsAddOnLoaded("BigWigs")
        end,
        func = function()
            if BigWigsOptions then
                BigWigsOptions:Open()
            else
                C_AddOns.LoadAddOn("BigWigs_Options")
                BigWigsOptions:Open()
            end
        end,
    },
}

local function GetMicroButtonText(button)
    local text = button.tooltipText or button:GetName()

        -- Remove the key binding.
    return (text:gsub("%s*|c%x%x%x%x%x%x%x%x%(.-%)|r", ""))
end

local function GeneratePicoMenu(owner, rootDescription)
    rootDescription:CreateTitle(MAINMENU_BUTTON)

    for _, buttonName in ipairs(microButtons) do
        local button = _G[buttonName]

        if button and button:IsShown() and button:IsEnabled() then
            rootDescription:CreateButton(GetMicroButtonText(button), function()
                button:Click()
            end)
        end
    end

    local loadedAddons = {}
    for _, entry in ipairs(addonEntries) do
        if entry.isLoaded() then
            table.insert(loadedAddons, entry)
        end
    end

    if #loadedAddons > 0 then
        rootDescription:CreateDivider()

        local addonMenu = rootDescription:CreateButton(ADDONS)
        for _, entry in ipairs(loadedAddons) do
            addonMenu:CreateButton(entry.text, entry.func)
        end
    end
end

    -- Pico Menu Button

local picoMenu = CreateFrame("Button", "nMainbarPicoMenu", UIParent)
picoMenu:SetFrameStrata("MEDIUM")
picoMenu:SetFrameLevel(3)
picoMenu:SetToplevel(true)
picoMenu:SetSize(30, 30)
picoMenu:SetPoint("BOTTOMLEFT", MainActionBar, "BOTTOMRIGHT", 8, 0)
picoMenu:RegisterForClicks("AnyUp")

picoMenu:SetNormalTexture(PICOMENU_TEXTURE.."picomenuNormal")
picoMenu:GetNormalTexture():SetSize(30, 30)

picoMenu:SetHighlightTexture(PICOMENU_TEXTURE.."picomenuHighlight")
picoMenu:GetHighlightTexture():SetAllPoints(picoMenu:GetNormalTexture())

picoMenu:SetScript("OnMouseDown", function(self)
    self:GetNormalTexture():ClearAllPoints()
    self:GetNormalTexture():SetPoint("CENTER", 1, -1)
end)

picoMenu:SetScript("OnMouseUp", function(self, button)
    self:GetNormalTexture():ClearAllPoints()
    self:GetNormalTexture():SetPoint("CENTER")

    if self:IsMouseOver() then
        if button == "LeftButton" then
            MenuUtil.CreateContextMenu(self, GeneratePicoMenu)
        else
            MainMenuMicroButton:Click()
        end
    end

    GameTooltip:Hide()
end)

picoMenu:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 25, -5)
    GameTooltip:AddLine(MAINMENU_BUTTON)
    GameTooltip:Show()
end)

picoMenu:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

    -- Move Ticket Icon

HelpOpenWebTicketButton:ClearAllPoints()
HelpOpenWebTicketButton:SetPoint("LEFT", picoMenu, "RIGHT", 0, 0)
HelpOpenWebTicketButton:SetScale(0.8)
HelpOpenWebTicketButton:SetParent(picoMenu)
