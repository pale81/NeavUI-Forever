local _, nMinimap = ...
local cfg = nMinimap.Config

if not cfg.collectButtons then
    return
end

    -- Minimap buttons of other addons are hidden and listed in the right click menu
    -- of the minimap, like the entries of the addon compartment: name left, icon right.

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local buttons = {}
local collected = {}

local IGNORED = {
    GameTimeFrame = true,
    TimeManagerClockButton = true,
    ExpansionLandingPageMinimapButton = true,
    AddonCompartmentFrame = true,
    QueueStatusButton = true,
    HybridMinimap = true,
}

local function IsIgnored(name)
    return IGNORED[name] or name:find("^Minimap") or name:find("^MiniMap") or name:find("^nMinimap")
end

local function GetButtonName(button, name)
    -- The text of a data object is a value (e.g. the bug count of BugSack), only
    -- the label is a name.

    local dataObject = button.dataObject
    local label = dataObject and dataObject.label
    if type(label) == "string" and label ~= "" then
        return label
    end

    name = name:gsub("^LibDBIcon10_", ""):gsub("_?[Mm]ini[Mm]ap_?[Bb]utton$", ""):gsub("_?[Bb]utton$", "")
    return name
end

local function GetButtonIcon(button)
    local name = button:GetName()
    local icon = button.icon or button.Icon or (name and _G[name.."Icon"]) or button:GetNormalTexture()

    if icon and icon.GetTexture then
        return icon:GetAtlas(), icon:GetTexture(), {icon:GetTexCoord()}
    end
end

local function CollectButton(button)
    local name = button:GetName()
    if collected[button] or not name or IsIgnored(name) or not button:IsObjectType("Button") then
        return
    end

    collected[button] = true
    buttons[#buttons + 1] = {button = button, name = GetButtonName(button, name)}

    button:SetParent(hiddenParent)
end

local function CollectButtons()
    for _, parent in pairs({Minimap, MinimapBackdrop, MinimapCluster}) do
        for _, child in pairs({parent:GetChildren()}) do
            CollectButton(child)
        end
    end
end

local function ClickButton(button, mouseButton)
    for _, script in pairs({"OnClick", "OnMouseUp", "OnMouseDown"}) do
        local handler = button:GetScript(script)
        if handler then
            handler(button, mouseButton)
            return
        end
    end
end

    -- The addon compartment is hidden, its entries move into the menu as well.

local compartment = AddonCompartmentFrame
if compartment then
    compartment:SetAlpha(0)
    compartment:EnableMouse(false)
end

local function SetupIcon(button, atlas, texture, texCoord, text)
    local icon = button:AttachTexture()
    icon:SetPoint("RIGHT")
    icon:SetSize(16, 16)

    if atlas then
        icon:SetAtlas(atlas)
    elseif texture then
        icon:SetTexture(texture)
        if texCoord then
            icon:SetTexCoord(unpack(texCoord))
        end
    end
    icon:SetShown(atlas ~= nil or texture ~= nil)

    local fontString = button.fontString
    fontString:ClearAllPoints()
    fontString:SetPoint("LEFT")
    fontString:SetTextToFit(text)
    fontString:SetWidth(fontString:GetWidth() + 24)
end

    -- Tooltips: LibDataBroker objects build their tooltip at the menu entry, like
    -- LibDBIcon does at the minimap button. Other buttons show their own tooltip.

local function ShowButtonTooltip(menuButton, button)
    local dataObject = button.dataObject

    if dataObject and dataObject.OnTooltipShow then
        GameTooltip:SetOwner(menuButton, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPRIGHT", menuButton, "TOPLEFT", -8, 0)
        dataObject.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    elseif dataObject and dataObject.OnEnter then
        dataObject.OnEnter(menuButton)
    elseif not dataObject then
        local onEnter = button:GetScript("OnEnter")
        if onEnter then
            onEnter(button)
        end
    end
end

local function HideButtonTooltip(menuButton, button)
    local dataObject = button.dataObject

    if dataObject and dataObject.OnLeave then
        dataObject.OnLeave(menuButton)
    elseif not dataObject then
        local onLeave = button:GetScript("OnLeave")
        if onLeave then
            onLeave(button)
        end
    end

    GameTooltip:Hide()
end

local function SortByName(a, b)
    return a.name:lower() < b.name:lower()
end

Menu.ModifyMenu("MENU_MINIMAP_TRACKING", function(_, rootDescription)
    CollectButtons()

    local entries = {}

    for _, data in ipairs(buttons) do
        if data.button:IsShown() then
            local atlas, texture, texCoord = GetButtonIcon(data.button)
            entries[#entries + 1] = {
                name = data.name,
                atlas = atlas,
                texture = texture,
                texCoord = texCoord,
                func = function(_, menuInputData)
                    ClickButton(data.button, menuInputData.buttonName)
                end,
                funcOnEnter = function(menuButton)
                    ShowButtonTooltip(menuButton, data.button)
                end,
                funcOnLeave = function(menuButton)
                    HideButtonTooltip(menuButton, data.button)
                end,
            }
        end
    end

    if compartment and compartment.registeredAddons then
        for _, addonData in ipairs(compartment.registeredAddons) do
            local icon = addonData.icon
            local isAtlas = icon and C_Texture.GetAtlasInfo(icon)
            entries[#entries + 1] = {
                name = addonData.text,
                atlas = isAtlas and icon or nil,
                texture = not isAtlas and icon or nil,
                func = addonData.func,
                funcOnEnter = addonData.funcOnEnter,
                funcOnLeave = addonData.funcOnLeave,
            }
        end
    end

    if #entries == 0 then
        return
    end

    table.sort(entries, SortByName)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle(ADDONS)

    for _, entry in ipairs(entries) do
        local description = rootDescription:CreateButton(entry.name, entry.func)
        description:AddInitializer(function(button)
            button:RegisterForClicks("AnyUp")
            SetupIcon(button, entry.atlas, entry.texture, entry.texCoord, entry.name)
        end)

        if entry.funcOnEnter then
            description:SetOnEnter(entry.funcOnEnter)
            description:SetOnLeave(entry.funcOnLeave)
        end
    end
end)

    -- Buttons are also collected right after loading, so they never show up.

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    CollectButtons()
    C_Timer.After(3, CollectButtons)

    local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LibDBIcon and LibDBIcon.RegisterCallback then
        LibDBIcon.RegisterCallback(nMinimap, "LibDBIcon_IconCreated", function(_, button)
            CollectButton(button)
        end)
    end
end)
