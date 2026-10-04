local _, ns = ...
local config = ns.Config

    -- Auras are displayed by the client side aura container (oUF Auras element). Aura data
    -- is not accessible to addons in restricted content, so all per-aura styling (dispel
    -- type border, stealable border, duration, count) is configured on the buttons and
    -- differences between player and other auras are handled with separate filter groups.

local function CreateTextParent(button)
    if button.Cooldown then
        local textParent = CreateFrame("Frame", nil, button)
        textParent:SetAllPoints()
        textParent:SetFrameLevel(button.Cooldown:GetFrameLevel() + 1)
        return textParent
    end

    return button
end

local function CreateAuraButton(element, options, button)
    local size = options.size or element.size or 20
    button:SetSize(size, size)
    button:EnableMouse(true)
    button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT", 0, 0)

    local icon = button:CreateTexture(nil, "BORDER")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetDesaturated(options.desaturate == true)
    button.Icon = icon
    button:SetIcon(icon)

        -- config.show.disableCooldown: use the cooldown spiral (e.g. for OmniCC) instead of
        -- our duration text.

    if config.show.disableCooldown then
        local cooldown = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
        cooldown:SetReverse(false)
        cooldown:SetDrawEdge(true)
        cooldown:SetHideCountdownNumbers(true)
        cooldown:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -1, -1)
        cooldown:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 1, 1)
        button.Cooldown = cooldown
        button:SetDurationCooldown(cooldown)
    end

    local textParent = CreateTextParent(button)

    local overlay = textParent:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture(config.media.border)
    overlay:SetPoint("TOPRIGHT", icon, 1.35, 1.35)
    overlay:SetPoint("BOTTOMLEFT", icon, -1.35, -1.35)
    button.Overlay = overlay

    if options.isHarmful and not options.desaturate then
        button:AddDispelTypeTexture(overlay, {
            style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
            showWhenHarmful = true,
            showWithoutDispelType = true,
            customDispelColorMap = element.__owner.colors.dispel,
        })
    elseif options.isHarmful then
        overlay:SetVertexColor(0.5, 0.5, 0.5, 1)
    else
        overlay:SetVertexColor(unpack(config.media.auraBorderColor))
    end

    if options.showStealable then
        local stealable = textParent:CreateTexture(nil, "OVERLAY", nil, 1)
        stealable:SetPoint("TOPLEFT", icon, -3, 3)
        stealable:SetPoint("BOTTOMRIGHT", icon, 3, -3)
        stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
        stealable:SetBlendMode("ADD")
        button.Stealable = stealable
        button:AddDispelTypeTexture(stealable, {
            style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
            showWhenHelpful = true,
            showWithoutDispelType = true,
            stealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable,
        })
    end

    local count = textParent:CreateFontString(nil, "OVERLAY")
    count:SetFont(config.font.normal, 11, "OUTLINE")
    count:SetShadowOffset(0, 0)
    count:SetPoint("BOTTOMRIGHT", icon, 2, 0)
    button.Count = count
    button:SetApplicationCount(count, {})

    if not config.show.disableCooldown and options.showDuration ~= false then
        local time = textParent:CreateFontString(nil, "OVERLAY")
        time:SetFont(config.font.normal, 8, "OUTLINE")
        time:SetShadowOffset(0, 0)
        time:SetPoint("TOP", icon, 0, 2)
        button.Time = time
        button:SetDurationText(time, {})
    end

    local shadow = button:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", icon, "TOPLEFT", -4, 4)
    shadow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 4, -4)
    shadow:SetTexture("Interface\\AddOns\\oUF_Neav\\media\\borderBackground")
    shadow:SetVertexColor(0, 0, 0, 1)
    button.Shadow = shadow
end

    --[[
        settings = {
            point = {"TOPLEFT", self, "BOTTOMLEFT", -2, -5},
            width, height, size, spacing,
            initialAnchor = "TOPLEFT", growthX = "RIGHT", growthY = "DOWN",
        }

        Groups are added by the caller with auras:AddGroup(filter, options). Extra options
        used by CreateAuraButton: isHarmful, desaturate, showStealable, showDuration.
    --]]

function ns.CreateAuras(self, settings)
    local auras = self:CreateAuras({
        initialAnchor = settings.initialAnchor or "TOPLEFT",
        growthX = settings.growthX or "RIGHT",
        growthY = settings.growthY or "DOWN",
        layoutLimit = settings.width,
    })

    auras:SetSize(settings.width, settings.height)
    auras:SetPoint(unpack(settings.point))

    auras.size = settings.size
    auras.elementSpacing = settings.spacing
    auras.lineSpacing = settings.spacing
    auras.groupSpacing = settings.spacing
    auras.groupLineSpacing = settings.spacing
    auras.CreateButton = CreateAuraButton

    return auras
end

    -- Adds the debuff groups of a frame. Other players debuffs are desaturated if
    -- colorPlayerDebuffsOnly is enabled and only show a timer if showAllTimers is enabled.

function ns.AddDebuffGroups(auras, num, onlyShowPlayer, forceNewLine)
    local layout = {forceNewLine = forceNewLine}

    if onlyShowPlayer then
        auras:AddGroup("HARMFUL|PLAYER", {maxFrameCount = num, isHarmful = true, layout = layout})
    elseif config.units.target.colorPlayerDebuffsOnly or not config.units.target.showAllTimers then
        auras:AddGroup("HARMFUL|PLAYER", {maxFrameCount = num, isHarmful = true, layout = layout})
        auras:AddGroup("HARMFUL|!PLAYER", {
            maxFrameCount = num,
            isHarmful = true,
            desaturate = config.units.target.colorPlayerDebuffsOnly,
            showDuration = config.units.target.showAllTimers,
        })
    else
        auras:AddGroup("HARMFUL", {maxFrameCount = num, isHarmful = true, layout = layout})
    end
end

function ns.AddBuffGroup(auras, num, onlyShowPlayer, forceNewLine)
    auras:AddGroup(onlyShowPlayer and "HELPFUL|PLAYER" or "HELPFUL", {
        maxFrameCount = num,
        showStealable = true,
        layout = {forceNewLine = forceNewLine},
    })
end

    -- Portrait timers: important auras (ns.PortraitTimerDB) are shown on top of the portrait.

local function CreatePortraitTimerButton(element, options, button)
    button:SetAllPoints(element)
    button:EnableMouse(false)

    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(button)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(button)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:AddMaskTexture(mask)
    button.Icon = icon
    button:SetIcon(icon)

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetDrawSwipe(false)
    button.Cooldown = cooldown
    button:SetDurationCooldown(cooldown)
end

function ns.CreatePortraitTimer(self)
    local auras = self:CreateAuras()
    auras:SetAllPoints(self.Portrait)
    auras:SetFrameLevel(self.Health:GetFrameLevel() + 2)
    auras.CreateButton = CreatePortraitTimerButton

    local candidateFilters = {includeSpellIDs = ns.PortraitTimerDB}

    for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
        local slotKey = auras:AddSlot(filter, {candidateFilters = candidateFilters})
        local slot = auras:GetAuraSlotFrame(slotKey)
        slot:ClearAllPoints()
        slot:SetAllPoints(auras)
    end

    return auras
end
