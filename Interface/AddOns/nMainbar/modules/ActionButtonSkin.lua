local _, nMainbar = ...
local cfg = nMainbar.Config
local Color = cfg.color

local pairs = pairs
local gsub = string.gsub

local MEDIA_PATH = "Interface\\AddOns\\nMainbar\\Media\\"

local IsSkinned = {}

    -- Usable, range and equipped states can be secret in restricted content.

local function IsTrue(value)
    return not issecretvalue(value) and value
end

local function SetButtonTextures(button, borderOffset)
    button:SetNormalTexture(MEDIA_PATH.."textureNormal")

    local normalTexture = button:GetNormalTexture()
    normalTexture:SetDrawLayer("OVERLAY")
    normalTexture:ClearAllPoints()
    PixelUtil.SetPoint(normalTexture, "TOPRIGHT", button, "TOPRIGHT", borderOffset, borderOffset)
    PixelUtil.SetPoint(normalTexture, "BOTTOMLEFT", button, "BOTTOMLEFT", -borderOffset, -borderOffset)
    normalTexture:SetVertexColor(Color.Normal:GetRGBA())

    button:SetPushedTexture(MEDIA_PATH.."texturePushed")
    local pushedTexture = button:GetPushedTexture()
    pushedTexture:SetDrawLayer("OVERLAY")
    pushedTexture:ClearAllPoints()
    pushedTexture:SetAllPoints(normalTexture)

    if button.SlotArt then
        button.SlotArt:SetAlpha(0)
    end

    if button.SlotBackground then
        button.SlotBackground:SetAlpha(0)
    end

    return normalTexture
end

local function SkinButton(button, borderOffset, shadowOffset)
    if IsSkinned[button] then
        return
    end

    local icon = button.icon or button.Icon
    local normalTexture = SetButtonTextures(button, borderOffset)

        -- The default buttons art is changed when bars are moved or resized in Edit Mode.

    if button.UpdateButtonArt then
        hooksecurefunc(button, "UpdateButtonArt", function(self)
            SetButtonTextures(self, borderOffset)
        end)
    end

    if icon then
        if button.IconMask then
            icon:RemoveMaskTexture(button.IconMask)
        end

        icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        icon:ClearAllPoints()
        PixelUtil.SetPoint(icon, "TOPRIGHT", button, "TOPRIGHT", -1, -1)
        PixelUtil.SetPoint(icon, "BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
    end

    local cooldown = button.cooldown
    if cooldown then
        cooldown:ClearAllPoints()
        PixelUtil.SetPoint(cooldown, "TOPRIGHT", button, "TOPRIGHT", -2, -2)
        PixelUtil.SetPoint(cooldown, "BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
    end

    button:SetCheckedTexture(MEDIA_PATH.."textureChecked")
    button:GetCheckedTexture():ClearAllPoints()
    button:GetCheckedTexture():SetAllPoints(normalTexture)

    button:SetHighlightTexture(MEDIA_PATH.."textureHighlight")
    button:GetHighlightTexture():ClearAllPoints()
    button:GetHighlightTexture():SetAllPoints(normalTexture)

    local border = button.Border
    if border then
        border:SetBlendMode("BLEND")
        border:SetTexture(MEDIA_PATH.."UI-ActionButton-Glow")
        border:ClearAllPoints()
        border:SetAllPoints(normalTexture)
    end

    if not button.Background then
        button.Background = button:CreateTexture(nil, "BACKGROUND", nil, -8)
        button.Background:SetTexture(MEDIA_PATH.."textureBackground")
        PixelUtil.SetPoint(button.Background, "TOPRIGHT", button, "TOPRIGHT", 14, 12)
        PixelUtil.SetPoint(button.Background, "BOTTOMLEFT", button, "BOTTOMLEFT", -14, -16)
    end

    if not button.Shadow then
        button.Shadow = button:CreateTexture(nil, "BACKGROUND")
        button.Shadow:SetTexture(MEDIA_PATH.."textureShadow")
        button.Shadow:SetVertexColor(0.0, 0.0, 0.0, 1.0)
        PixelUtil.SetPoint(button.Shadow, "TOPRIGHT", normalTexture, "TOPRIGHT", shadowOffset, shadowOffset)
        PixelUtil.SetPoint(button.Shadow, "BOTTOMLEFT", normalTexture, "BOTTOMLEFT", -shadowOffset, -shadowOffset)
    end

    IsSkinned[button] = true
end

local function ShortenHotkeyText(text)
    text = gsub(text, "(s%-)", "S-")
    text = gsub(text, "(a%-)", "A-")
    text = gsub(text, "(c%-)", "C-")
    text = gsub(text, "(st%-)", "C-") -- German Control "Steuerung"

    for i = 1, 30 do
        if _G["KEY_BUTTON"..i] then
            text = gsub(text, _G["KEY_BUTTON"..i], "M"..i)
        end
    end

    for i = 1, 9 do
        if _G["KEY_NUMPAD"..i] then
            text = gsub(text, _G["KEY_NUMPAD"..i], "Nu"..i)
        end
    end

    for key, short in pairs({
        KEY_NUMPADDECIMAL = "Nu.",
        KEY_NUMPADDIVIDE = "Nu/",
        KEY_NUMPADMINUS = "Nu-",
        KEY_NUMPADMULTIPLY = "Nu*",
        KEY_NUMPADPLUS = "Nu+",
        KEY_MOUSEWHEELUP = "MU",
        KEY_MOUSEWHEELDOWN = "MD",
        KEY_NUMLOCK = "NuL",
        KEY_PAGEUP = "PU",
        KEY_PAGEDOWN = "PD",
        KEY_SPACE = "_",
        KEY_INSERT = "Ins",
        KEY_HOME = "Hm",
        KEY_DELETE = "Del",
    }) do
        if _G[key] then
            text = gsub(text, _G[key], short)
        end
    end

    return text
end

local function UpdateHotkeys(self)
    local hotkey = self.HotKey
    if not hotkey then
        return
    end

    local text = hotkey:GetText()
    if text and not issecretvalue(text) and text ~= RANGE_INDICATOR then
        hotkey:SetText(ShortenHotkeyText(text))
    end

    if self.isVehicleButton then
        if cfg.button.showVehicleKeybinds then
            hotkey:SetFont(cfg.button.hotkeyFont, cfg.button.hotkeyFontsize + 3, "OUTLINE")
            hotkey:SetVertexColor(Color.HotKeyText:GetRGB())
            hotkey:ClearAllPoints()
            hotkey:SetPoint("TOPRIGHT", self, -4, -8)
        else
            hotkey:Hide()
        end
    elseif cfg.button.showKeybinds then
        hotkey:ClearAllPoints()
        hotkey:SetPoint("TOPRIGHT", self, 0, -3)
        hotkey:SetFont(cfg.button.hotkeyFont, self.isSmallButton and cfg.button.petHotKeyFontsize or cfg.button.hotkeyFontsize, "OUTLINE")
        hotkey:SetVertexColor(Color.HotKeyText:GetRGB())
    else
        hotkey:Hide()
    end
end

local function UpdateCount(self)
    local text = self.Count

    if text then
        text:ClearAllPoints()
        text:SetPoint("BOTTOMRIGHT", self, 0, 1)
        text:SetFont(cfg.button.countFont, cfg.button.countFontsize, "OUTLINE")
        text:SetVertexColor(Color.CountText:GetRGB())
    end
end

local function UpdateUsable(self, _, isUsable, notEnoughMana)
    local icon = self.icon
    local normalTexture = self:GetNormalTexture()
    if not icon or not normalTexture or not self.action then
        return
    end

    if isUsable == nil or notEnoughMana == nil then
        isUsable, notEnoughMana = C_ActionBar.IsUsableAction(self.action)
    end

    if IsTrue(isUsable) then
        icon:SetVertexColor(1.0, 1.0, 1.0)
        normalTexture:SetVertexColor(Color.Normal:GetRGBA())
    elseif IsTrue(notEnoughMana) then
        icon:SetVertexColor(Color.OutOfMana:GetRGB())
        normalTexture:SetVertexColor(Color.OutOfMana:GetRGB())
    elseif not issecretvalue(isUsable) then
        icon:SetVertexColor(Color.NotUsable:GetRGB())
        normalTexture:SetVertexColor(Color.NotUsable:GetRGB())
    end
end

local function Update(self)
    local actionName = self.Name
    if actionName then
        if not cfg.button.showMacroNames then
            actionName:SetText("")
        else
            actionName:SetFont(cfg.button.macronameFont, cfg.button.macronameFontsize, "OUTLINE")
            actionName:SetVertexColor(Color.MacroText:GetRGB())
        end
    end

    local border = self.Border
    if border and self.action then
        if IsTrue(C_ActionBar.IsEquippedAction(self.action)) then
            border:SetVertexColor(Color.IsEquipped:GetRGB())
            border:SetAlpha(1)
        else
            border:SetAlpha(0)
        end
    end
end

hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checksRange, inRange)
    if issecretvalue(checksRange) or issecretvalue(inRange) or not self.HotKey then
        return
    end

    if self.action and cfg.button.buttonOutOfRange then
        UpdateUsable(self)

        if checksRange and not inRange then
            self.icon:SetVertexColor(Color.OutOfRange:GetRGB())
        end
    end

    local text = self.HotKey:GetText()
    if issecretvalue(text) then
        return
    end

    if text == RANGE_INDICATOR then
        if checksRange then
            self.HotKey:Show()
            if inRange then
                self.HotKey:SetVertexColor(Color.HotKeyText:GetRGB())
            else
                self.HotKey:SetVertexColor(Color.OutOfRange:GetRGB())
            end
        else
            self.HotKey:Hide()
        end
    else
        if checksRange and not inRange then
            self.HotKey:SetVertexColor(Color.OutOfRange:GetRGB())
        else
            self.HotKey:SetVertexColor(Color.HotKeyText:GetRGB())
        end
    end
end)

local function HookMethod(button, method, func)
    if button[method] then
        hooksecurefunc(button, method, func)
    end
end

local function SetupActionButton(button, borderOffset, shadowOffset)
    SkinButton(button, borderOffset, shadowOffset)

    UpdateCount(button)
    UpdateHotkeys(button)
    Update(button)
    UpdateUsable(button)

    HookMethod(button, "Update", Update)
    HookMethod(button, "UpdateCount", UpdateCount)
    HookMethod(button, "UpdateHotkeys", UpdateHotkeys)
    HookMethod(button, "UpdateUsable", UpdateUsable)
end

    -- Action bars

for _, bar in pairs({
    MainActionBar,
    MultiBarBottomLeft,
    MultiBarBottomRight,
    MultiBarRight,
    MultiBarLeft,
    MultiBar5,
    MultiBar6,
    MultiBar7,
}) do
    for _, button in pairs(bar.actionButtons) do
        SetupActionButton(button, 1, 4)
    end
end

    -- Vehicle bar

for i = 1, NUM_OVERRIDE_BUTTONS do
    local button = _G["OverrideActionBarButton"..i]
    if button then
        button.isVehicleButton = true
        UpdateHotkeys(button)
        HookMethod(button, "UpdateHotkeys", UpdateHotkeys)
    end
end

    -- Pet, stance and possess bar

for _, bar in pairs({
    PetActionBar,
    StanceBar,
    PossessActionBar,
}) do
    for _, button in pairs(bar.actionButtons) do
        button.isSmallButton = true
        SkinButton(button, bar == StanceBar and 2 or 1.5, 4)
        UpdateHotkeys(button)

        HookMethod(button, "SetHotkeys", UpdateHotkeys)
        HookMethod(button, "UpdateHotkeys", UpdateHotkeys)
    end
end

    -- Extra action button

hooksecurefunc("ExtraActionBar_Update", function()
    local button = ExtraActionBarFrame.button

    if C_ActionBar.HasExtraActionBar() and not IsSkinned[button] then
        button.style:Hide()
        SkinButton(button, 4, 5)
    end
end)

    -- Bag keybind

local f = CreateFrame("Frame", nil)
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        local bagBinding = GetBindingKey("NBAGS_TOGGLE") or "ALT-CTRL-B"
        SetBinding(bagBinding, "NBAGS_TOGGLE")
        f:UnregisterEvent("PLAYER_LOGIN")
    end
end)
