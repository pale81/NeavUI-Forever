local _, ns = ...
local config = ns.Config

local oUF = ns.oUF or oUF
oUF.colors.power.MANA:SetRGB(0, 0.55, 1)
oUF.colors.health:SetRGB(0, 1, 0)
oUF.colors.disconnected:SetRGB(0.5, 0.5, 0.5)

local _, playerClass = UnitClass("player")
local charTexPath = "Interface\\CharacterFrame\\"
local tarTexPath = "Interface\\TargetingFrame\\"
local texPath = tarTexPath.."UI-TargetingFrame"
local texTable = {
    ["elite"] = texPath.."-Elite",
    ["rareelite"] = texPath.."-Rare-Elite",
    ["rare"] = texPath.."-Rare",
    ["worldboss"] = texPath.."-Elite",
    ["normal"] = texPath,
}

local function CreateTab(self, text)
    self.T = {}
    local tabCoordTable = {
        [1] = {0.1875, 0.53125, 0, 1},
        [2] = {0.53125, 0.71875, 0, 1},
        [3] = {0, 0.1875, 0, 1},
    }

    for i = 1, 3 do
        self.T[i] = self:CreateTexture("$parentTabPart"..i, "BACKGROUND")
        self.T[i]:SetTexture(charTexPath.."UI-CharacterFrame-GroupIndicator")
        self.T[i]:SetTexCoord(unpack(tabCoordTable[i]))
        self.T[i]:SetSize(24, 18)
        self.T[i]:SetAlpha(0.5)
    end

    self.T[1]:SetPoint("BOTTOM", self.Name.Bg, "TOP", -1, 0) --0, 1
    self.T[2]:SetPoint("LEFT", self.T[1], "RIGHT")
    self.T[3]:SetPoint("RIGHT", self.T[1], "LEFT")

    self.T[4] = self:CreateFontString("$parentTabText", "OVERLAY")
    self.T[4]:SetFont(config.font.normal, config.font.normalSize - 1)
    self.T[4]:SetShadowOffset(1, -1)
    self.T[4]:SetPoint("BOTTOM", self.T[1], 0, 2)
    self.T[4]:SetAlpha(0.5)

    self.T[4]:SetText(text)
    local width = self.T[4]:GetStringWidth()
    self.T[1]:SetWidth((width < 5 and 50) or width + 4)

    self.T.FadeIn = function(_, alpha, alpha2)
        for i = 1, 4 do
            securecall("UIFrameFadeIn", self.T[i], 0.15, self.T[i]:GetAlpha(), alpha)
            securecall("UIFrameFadeIn", self.T[4], 0.15, self.T[4]:GetAlpha(), alpha2 or alpha)
        end
    end

    self.T.FadeOut = function(_, alpha, alpha2)
        for i = 1, 4 do
            securecall("UIFrameFadeOut", self.T[i], 0.15, self.T[i]:GetAlpha(), alpha)
            securecall("UIFrameFadeOut", self.T[4], 0.15, self.T[4]:GetAlpha(), alpha2 or alpha)
        end
    end
end

local function UpdatePartyTab(self)
    local raidIndex = UnitInRaid("player")

    if not IsInRaid() or issecretvalue(raidIndex) or not raidIndex then
        self.T:FadeOut(0)
        return
    end

    local _, _, groupNumber = GetRaidRosterInfo(raidIndex)

    if not issecretvalue(groupNumber) and groupNumber then
        self.T:FadeIn(0.5, 0.65)
        self.T[4]:SetText(GROUP.." "..groupNumber)
        self.T[1]:SetWidth(self.T[4]:GetStringWidth()+4)
    end
end

    -- Update Threat. Threat values are secret in restricted content, the display is
    -- hidden then.

local function UpdateThreat(self)
    if not self.NumericalThreat then
        return
    end

    local isTanking, status, scaledPercent = UnitDetailedThreatSituation("player", "target")

    if issecretvalue(isTanking) or issecretvalue(status) or issecretvalue(scaledPercent) then
        self.NumericalThreat:Hide()
        return
    end

    local display = scaledPercent

    if isTanking then
        display = UnitThreatPercentageOfLead("player", "target")

        if issecretvalue(display) then
            self.NumericalThreat:Hide()
            return
        end
    end

    if UnitClassification(self.__unit) ~= "minus" and display and display ~= 0 then
        self.NumericalThreat.value:SetText(format("%1.0f", display).."%")
        self.NumericalThreat.bg:SetVertexColor(GetThreatStatusColor(status))
        self.NumericalThreat:Show()
    else
        self.NumericalThreat:Hide()
    end
end

    -- Update TotemBar Location

local function UpdateTotemBarAnchor(self)
    local totemBar = self.Totems and self.Totems.Bar
    if not totemBar then
        return
    end

    totemBar:ClearAllPoints()

    if UnitExists("pet") then
        totemBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -75)
    else
        totemBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 25, -25)
    end
end

    -- Update rest/combat flash.

local function UpdateFlashStatus(self)
    if UnitIsDeadOrGhost("player") then
        self.StatusFlash:Hide()
        return
    end

    local inCombat = UnitAffectingCombat("player")

    if IsResting() then
        if inCombat then
            self.StatusFlash:SetVertexColor(1.0, 0.0, 0.0, 1.0)
            self.StatusFlash:Show()
        else
            self.StatusFlash:SetVertexColor(1.0, 0.88, 0.25, 1.0)
            self.StatusFlash:Show()
        end
    elseif inCombat then
        self.StatusFlash:SetVertexColor(1.0, 0.0, 0.0, 1.0)
        self.StatusFlash:Show()
    else
        self.StatusFlash:Hide()
    end
end

    -- Player Frame StatusFlash OnUpdate

local function StatusFlash_OnUpdate(self, elapsed)
    if self.StatusFlash:IsShown() then
        local counter = self.statusCounter + elapsed
        local sign = self.statusSign

        if counter > 0.5 then
            sign = -sign
            self.statusSign = sign
        end
        counter = mod(counter, 0.5)
        self.statusCounter = counter

        local alpha
        if sign == 1 then
            alpha = (55  + (counter * 400)) / 255
        else
            alpha = (255 - (counter * 400)) / 255
        end
        self.StatusFlash:SetAlpha(alpha)

        if self.RestingIndicator.Glow:IsShown() then
            self.RestingIndicator.Glow:SetAlpha(alpha)
        elseif self.CombatIndicator.Glow:IsShown() then
            self.CombatIndicator.Glow:SetAlpha(alpha)
        end
    end

    if self.RestingIndicator:IsShown() then
        self.RestingIndicator.Glow:Show()
        self.CombatIndicator:Hide()
        self.CombatIndicator.Glow:Hide()
        self.Level:SetAlpha(0.01)
    elseif self.CombatIndicator:IsShown() then
        self.CombatIndicator.Glow:Show()
        self.Level:SetAlpha(0.01)
    else
        self.RestingIndicator.Glow:Hide()
        self.CombatIndicator.Glow:Hide()
        self.Level:SetAlpha(1)
    end
end

    -- Mouseover Text

local function EnableMouseOver(self)
    self.Health.Value:Hide()

    if self.Power and self.Power.Value then
        self.Power.Value:Hide()
    end

    if self.AdditionalPower and self.AdditionalPower.Value then
        self.AdditionalPower.Value:Hide()
    end

    self:HookScript("OnEnter", function(self)
        self.Health.Value:Show()

        if self.Power and self.Power.Value then
            self.Power.Value:Show()
        end

        if self.AdditionalPower and self.AdditionalPower.Value then
            self.AdditionalPower.Value:Show()
        end
    end)

    self:HookScript("OnLeave", function(self)
        self.Health.Value:Hide()

        if self.Power and self.Power.Value then
            self.Power.Value:Hide()
        end

        if self.AdditionalPower and self.AdditionalPower.Value then
            self.AdditionalPower.Value:Hide()
        end
    end)
end

    -- Class Icon Portraits (players only)
    -- The round class icons fit the portrait circle, the classicon atlas is square.

local function UpdateClassPortraits(self, unit, hasStateChanged)
    if not hasStateChanged then
        return
    end

    local isPlayer = UnitIsPlayer(unit)
    local _, class = UnitClass(unit)
    local coords = not issecretvalue(isPlayer) and isPlayer and not issecretvalue(class) and class and CLASS_ICON_TCOORDS[class]

    if coords then
        self:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        self:SetTexCoord(unpack(coords))
    else
        self:SetTexCoord(0, 1, 0, 1)
    end
end

    -- Update Portrait Color

local function UpdatePortraitColor(self, unit, cur, max)
    if not UnitIsConnected(unit) then
        self.Portrait:SetVertexColor(0.5, 0.5, 0.5, 0.7)
    elseif UnitIsDead(unit) then
        self.Portrait:SetVertexColor(0.35, 0.35, 0.35, 0.7)
    elseif UnitIsGhost(unit) then
        self.Portrait:SetVertexColor(0.3, 0.3, 0.9, 0.7)
    elseif not issecretvalue(cur) and not issecretvalue(max) and (max == 0 or cur/max * 100 < 25) then
        if UnitIsPlayer(unit) then
            if unit ~= "player" then
                self.Portrait:SetVertexColor(1, 0, 0, 0.7)
            end
        end
    else
        self.Portrait:SetVertexColor(1, 1, 1, 1)
    end
end

    -- Update Health

local function UpdateHealth(Health, unit, cur, max)
    local self = Health:GetParent()
    UpdatePortraitColor(self, unit, cur, max)

    if unit == "target" or unit == "focus" then
        if self.Name.Bg then
            self.Name.Bg:SetVertexColor(ns.GetUnitColor(unit))
        end
    end

    Health.Value:SetText(ns.GetHealthText(unit, cur, max))
end

    -- Update Power

local function UpdatePower(Power, unit, cur, min, max)
    if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
        Power:SetValue(0)
    end

    Power.Value:SetText(ns.GetPowerText(unit, cur, max))
end

    -- Update Level Anchor

local function UpdateLevelTextAnchor(self)
    local unit = self.__unit
    if not unit then
        return
    end

    local x
    local targetEffectiveLevel = UnitEffectiveLevel(unit)

    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        targetEffectiveLevel = UnitBattlePetLevel(unit)
    end

    if targetEffectiveLevel >= 100 then
        if unit == "player" or unit == "vehicle" then
            x = -62
        else
            x = 61
        end
    else
        if unit == "player" or unit == "vehicle" then
            x = -61
        else
            x = 62
        end
    end

    self.Level:SetPoint("CENTER", self.Texture, x, -16)
end

    -- Target and focus frame texture by classification

local function UpdateClassificationTexture(self)
    local unit = self.__unit
    if unit and UnitExists(unit) then
        self.Texture:SetTexture(texTable[UnitClassification(unit)] or texTable["normal"])
    end
end

    -- Player Frame Update

local function UpdatePlayerFrame(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateTotemBarAnchor(self)
        UpdateFlashStatus(self)
        UpdateLevelTextAnchor(self)
        UpdatePartyTab(self)
    elseif event == "UNIT_LEVEL" then
        UpdateLevelTextAnchor(self)
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateFlashStatus(self)
    elseif event == "PLAYER_REGEN_DISABLED" then
        UpdateFlashStatus(self)
    elseif event == "PLAYER_UPDATE_RESTING" then
        UpdateFlashStatus(self)
    elseif event == "UNIT_PET" then
        UpdateTotemBarAnchor(self)
    elseif event == "CINEMATIC_STOP" then
        UpdateFlashStatus(self)
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdatePartyTab(self)
    end
end

    -- Target Frame Update

local function UpdateTargetFrame(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateLevelTextAnchor(self)
    elseif event == "UNIT_LEVEL" then
        UpdateLevelTextAnchor(self)
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateThreat(self)
    elseif event == "PLAYER_REGEN_DISABLED" then
        UpdateThreat(self)
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateThreat(self)
        UpdateLevelTextAnchor(self)
        if UnitExists(self.__unit) and not C_PlayerInteractionManager.IsReplacingUnit() then
            if UnitIsEnemy(self.__unit, "player") then
                PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT)
            elseif UnitIsFriend("player", self.__unit) then
                PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT)
            else
                PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT)
            end
        end
    elseif event == "UNIT_TARGETABLE_CHANGED" then
        UpdateLevelTextAnchor(self)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateClassificationTexture(self)
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        UpdateThreat(self)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        UpdateThreat(self)
    end
end

    -- Focus Frame Update

local function UpdateFocusFrame(self, event, ...)
    if event == "UNIT_LEVEL" then
        UpdateLevelTextAnchor(self)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UpdateLevelTextAnchor(self)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateLevelTextAnchor(self)
        UpdateClassificationTexture(self)
    end
end

    -- Combo points (rogue and druid) via the oUF ClassPower element.

local function UpdateComboPoints(element, cur)
    for i = 1, #element do
        element[i].Highlight:SetShown(cur and i <= cur)
    end
end

local function CreateComboPoints(self)
    local element = {}

        -- Druids see their mana bar in cat form, the points are placed below it.

    local anchor = self.AdditionalPower or self.Power
    local offsetY = self.AdditionalPower and -4 or -2

    for i = 1, 10 do
        local point = CreateFrame("StatusBar", "$parentComboPoint"..i, self)
        point:SetSize(12, 16)
        point:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", (i - 1) * 12, offsetY)
        point:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        point:GetStatusBarTexture():SetAlpha(0)

        local background = point:CreateTexture("$parentBackground", "BACKGROUND")
        background:SetTexture("Interface\\ComboFrame\\ComboPoint")
        background:SetTexCoord(0, 0.375, 0, 1)
        background:SetSize(12, 16)
        background:SetPoint("TOPLEFT")

        local highlight = point:CreateTexture("$parentHighlight", "ARTWORK")
        highlight:SetTexture("Interface\\ComboFrame\\ComboPoint")
        highlight:SetTexCoord(0.375, 0.5625, 0, 1)
        highlight:SetSize(8, 16)
        highlight:SetPoint("TOPLEFT", 2, 0)
        highlight:Hide()
        point.Highlight = highlight

        element[i] = point
    end

    element.PostUpdate = UpdateComboPoints
    self.ClassPower = element
end

    -- Shaman totems via the oUF Totems element.

local function CreateTotems(self)
    local element = {}

    element.Bar = CreateFrame("Frame", "$parentTotemBar", self)
    element.Bar:SetSize(4 * 26, 24)
    element.Bar:SetScale(0.8)

    for i = 1, MAX_TOTEMS do
        local totem = CreateFrame("Button", "$parentTotem"..i, element.Bar)
        totem:SetSize(22, 22)
        totem:SetPoint("LEFT", element.Bar, (i - 1) * 26, 0)

        local icon = totem:CreateTexture(nil, "BORDER")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        totem.Icon = icon

        local cooldown = CreateFrame("Cooldown", nil, totem, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetReverse(true)
        totem.Cooldown = cooldown

        totem:CreateBeautyBorder(8)

        element[i] = totem
    end

    self.Totems = element
end

local function CreateUnitLayout(self, unit)
    self.IsMainFrame = ns.MultiCheck(unit, "player", "target", "focus")
    self.IsTargetFrame = ns.MultiCheck(unit, "targettarget", "focustarget")
    self.IsPartyFrame = unit:match("party")

    if self.IsTargetFrame then
        self:SetFrameLevel(30)
    end

    self:RegisterForClicks("AnyUp")

    self:SetScript("OnEnter", ns.UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)

    if config.units.focus.enableFocusToggleKeybind then
        if unit == "focus" then
            self:SetAttribute(config.units.focus.focusToggleKey, "macro")
            self:SetAttribute("macrotext", "/clearfocus")
        else
            self:SetAttribute(config.units.focus.focusToggleKey, "focus")
        end
    end

        -- Create the castbars.

    if config.show.castbars then
        ns.CreateCastbars(self, unit)
    end

        -- Texture

    self.Texture = self:CreateTexture("$parentFrameTexture", "BORDER")
    self.Texture:SetVertexColor(unpack(config.media.frameColor))

    if unit == "player" then
        if config.units.player.style == "NORMAL" then
            self.Texture:SetTexture(tarTexPath.."UI-TargetingFrame")
        elseif config.units.player.style == "RARE" then
            self.Texture:SetTexture(tarTexPath.."UI-TargetingFrame-Rare")
        elseif config.units.player.style == "ELITE" then
            self.Texture:SetTexture(tarTexPath.."UI-TargetingFrame-Elite")
        elseif config.units.player.style == "CUSTOM" then
            self.Texture:SetTexture(config.units.player.customTexture)
        end
        self.Texture:SetSize(232, 100)
        self.Texture:SetPoint("CENTER", self, -20, -7)
        self.Texture:SetTexCoord(1, 0.09375, 0, 0.78125)
    elseif unit == "pet" then
        self.Texture:SetSize(128, 64)
        self.Texture:SetPoint("TOPLEFT", self, 0, -2)
        self.Texture:SetTexture(tarTexPath.."UI-SmallTargetingFrame")
        self.Texture.SetTexture = function() end
    elseif unit == "target" or unit == "focus" then
        self.Texture:SetSize(230, 100)
        self.Texture:SetPoint("CENTER", self, 20, -7)
        self.Texture:SetTexture(tarTexPath.."UI-TargetingFrame")
        self.Texture:SetTexCoord(0.09375, 1, 0, 0.78125)
    elseif self.IsTargetFrame then
        self.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetofTargetFrame")
        self.Texture:SetTexCoord(0.015625, 0.7265625, 0, 0.703125)
        self.Texture:SetSize(93, 45)
        self.Texture:SetAllPoints(self)
    elseif self.IsPartyFrame then
        self.Texture:SetSize(128, 64)
        self.Texture:SetPoint("TOPLEFT", self, 0, -2)
        self.Texture:SetTexture(tarTexPath.."UI-PartyFrame")
    end

        -- Healthbar

    self.Health = CreateFrame("StatusBar", "$parentHealth", self, "BackdropTemplate")
    self.Health:SetStatusBarTexture(config.media.statusbar)
    self.Health:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
    self.Health:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    self.Health:SetBackdropColor(0, 0, 0, 0.70)

    self.Health.PostUpdate = UpdateHealth
    self.Health.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
    self.Health.colorDisconnected = true
    self.Health.colorClass = config.show.classHealth
    self.Health.colorHealth = true

    if unit == "player" then
        self.Health:SetSize(119, 12)
        self.Health:SetPoint("TOPLEFT", self.Texture, 106, -41)
    elseif unit == "pet" then
        self.Health:SetSize(70, 9)
        self.Health:SetPoint("TOPLEFT", self.Texture, 45, -20)
    elseif unit == "target" or unit == "focus" then
        self.Health:SetSize(119, 12)
        self.Health:SetPoint("TOPRIGHT", self.Texture, -105, -41) -- -105
    elseif self.IsTargetFrame then
        self.Health:SetSize(46, 7)
        self.Health:SetPoint("TOPRIGHT", self.Texture, -2, -15)
    elseif self.IsPartyFrame then
        self.Health:SetPoint("TOPLEFT", self.Texture, 47, -12)
        self.Health:SetSize(70, 7)
    end

        -- Health Prediction

    local healingPlayer = CreateFrame("StatusBar", "$parentMyHealthPredictionBar", self)
    healingPlayer:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
    healingPlayer:SetStatusBarTexture(config.media.statusbar, "OVERLAY")
    healingPlayer:SetStatusBarColor(0, 0.827, 0.765, 1)
    healingPlayer:SetOrientation("HORIZONTAL")
    healingPlayer:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT")
    healingPlayer:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT")
    healingPlayer:SetWidth(self.Health:GetWidth())

    local healingOther = CreateFrame("StatusBar", "$parentOtherHealthPredictionBar", self)
    healingOther:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
    healingOther:SetStatusBarTexture(config.media.statusbar, "OVERLAY")
    healingOther:SetStatusBarColor(0.0, 0.631, 0.557, 1)
    healingOther:SetOrientation("HORIZONTAL")
    healingOther:SetPoint("TOPLEFT", healingPlayer:GetStatusBarTexture(), "TOPRIGHT")
    healingOther:SetPoint("BOTTOMLEFT", healingPlayer:GetStatusBarTexture(), "BOTTOMRIGHT")
    healingOther:SetWidth(self.Health:GetWidth())

    local damageAbsorb = CreateFrame("StatusBar", "$parentTotalAbsorbBar", self)
    damageAbsorb:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
    damageAbsorb:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    damageAbsorb:SetStatusBarColor(0.85, 0.85, 0.9, 1)
    damageAbsorb:SetOrientation("HORIZONTAL")
    damageAbsorb:SetPoint("TOPLEFT", healingOther:GetStatusBarTexture(), "TOPRIGHT")
    damageAbsorb:SetPoint("BOTTOMLEFT", healingOther:GetStatusBarTexture(), "BOTTOMRIGHT")
    damageAbsorb:SetWidth(self.Health:GetWidth())

    damageAbsorb.Overlay = damageAbsorb:CreateTexture("$parentOverlay", "ARTWORK", "TotalAbsorbBarOverlayTemplate", 1)
    damageAbsorb.Overlay:SetAllPoints(damageAbsorb:GetStatusBarTexture())

    local healAbsorb = CreateFrame("StatusBar", "$parentHealAbsorbBar", self)
    healAbsorb:SetReverseFill(true)
    healAbsorb:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
    healAbsorb:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    healAbsorb:SetStatusBarColor(0.9, 0.1, 0.3, 1)
    healAbsorb:SetOrientation("HORIZONTAL")
    healAbsorb:SetPoint("TOP", self.Health:GetStatusBarTexture())
    healAbsorb:SetPoint("BOTTOM", self.Health:GetStatusBarTexture())
    healAbsorb:SetPoint("RIGHT", self.Health:GetStatusBarTexture())
    healAbsorb:SetWidth(self.Health:GetWidth())
    healAbsorb:SetHeight(self.Health:GetHeight())

    local overDamageAbsorb = self.Health:CreateTexture("$parentOverAbsorb", "OVERLAY")
    overDamageAbsorb:SetWidth(16)
    overDamageAbsorb:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", -10, 0)
    overDamageAbsorb:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", -10, 0)

    local overHealAbsorb = self.Health:CreateTexture("$parentOverHealAbsorb", "OVERLAY")
    overHealAbsorb:SetPoint("TOP")
    overHealAbsorb:SetPoint("BOTTOM")
    overHealAbsorb:SetPoint("RIGHT", self.Health, "LEFT")
    overHealAbsorb:SetWidth(10)
    overHealAbsorb:SetHeight(self.Health:GetHeight())

    self.Health.HealingPlayer = healingPlayer
    self.Health.HealingOther = healingOther
    self.Health.DamageAbsorb = damageAbsorb
    self.Health.HealAbsorb = healAbsorb
    self.Health.OverDamageAbsorbIndicator = overDamageAbsorb
    self.Health.OverHealAbsorbIndicator = overHealAbsorb
    self.Health.incomingHealOverflow = 1

        -- Health Text

    self.Health.Value = self:CreateFontString("$parentHealthText", "OVERLAY")
    self.Health.Value:SetShadowOffset(1, -1)

    if self.IsTargetFrame then
        self.Health.Value:SetFont(config.font.normal, config.font.normalSize - 2)
        self.Health.Value:SetPoint("CENTER", self.Health, "BOTTOM", -4, 1)
    else
        self.Health.Value:SetFont(config.font.normal, config.font.normalSize)
        self.Health.Value:SetPoint("CENTER", self.Health, 0, 1)
    end

        -- Powerbar

    self.Power = CreateFrame("StatusBar", "$parentPower", self, "BackdropTemplate")
    self.Power:SetStatusBarTexture(config.media.statusbar)
    self.Power:SetFrameLevel(math.max(0, self:GetFrameLevel() - 2))
    self.Power:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    self.Power:SetBackdropColor(0, 0, 0, 0.70)

    self.Power.frequentUpdates = true
    self.Power.smoothing = Enum.StatusBarInterpolation.ExponentialEaseOut
    self.Power.colorPower = true

    if self.IsTargetFrame then
        self.Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, 0)
        self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)
        self.Power:SetHeight(self.Health:GetHeight())
    else
        self.Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, 0)
        self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)
        self.Power:SetHeight(self.Health:GetHeight()-1)

        self.Power.Value = self:CreateFontString("$parentPowerText", "OVERLAY")
        self.Power.Value:SetFont(config.font.normal, config.font.normalSize)
        self.Power.Value:SetShadowOffset(1, -1)
        self.Power.Value:SetPoint("CENTER", self.Power, 0, 0)

        self.Power.PostUpdate = UpdatePower
    end

        -- Power Prediction Bar

    if unit == "player" then
        self.Power.CostPrediction = CreateFrame("StatusBar", "$parentPowerPrediction", self.Power)
        self.Power.CostPrediction:SetStatusBarTexture(config.media.statusbar)
        self.Power.CostPrediction:SetStatusBarColor(0.8,0.8,0.8,.50)
        self.Power.CostPrediction:SetReverseFill(true)
        self.Power.CostPrediction:SetPoint("TOP")
        self.Power.CostPrediction:SetPoint("BOTTOM")
        self.Power.CostPrediction:SetPoint("RIGHT", self.Power:GetStatusBarTexture())
        self.Power.CostPrediction:SetWidth(119)
    end

        -- Name

    self.Name = self:CreateFontString("$parentName", "OVERLAY")
    self.Name:SetFontObject("Neav_FontName")
    self.Name:SetJustifyH("CENTER")
    self.Name:SetHeight(10)

    self:Tag(self.Name, "[neav:name]")

    if unit == "player" then
        self.Name:SetWidth(110)
        self.Name:SetPoint("CENTER", self.Texture, 50, 19)
    elseif unit == "pet" then
        self.Name:SetWidth(90)
        self.Name:SetJustifyH("LEFT")
        self.Name:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, 4)
    elseif unit == "target" or unit == "focus" then
        self.Name:SetWidth(110)
        self.Name:SetPoint("CENTER", self.Texture, -50, 19)
    elseif self.IsTargetFrame then
        self.Name:SetWidth(60)
        self.Name:SetJustifyH("LEFT")
        self.Name:SetPoint("BOTTOMLEFT", self.Texture, 42, -1)
    elseif self.IsPartyFrame then
        self.Name:SetJustifyH("CENTER")
        self.Name:SetHeight(10)
        self.Name:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -3)
    end

        -- Level

    if self.IsMainFrame then
        self.Level = self:CreateFontString("$parentLevel", "ARTWORK")
        self.Level:SetFont(config.font.numberFont, 17, "OUTLINE")
        self.Level:SetShadowOffset(0, 0)
        self.Level:SetPoint("CENTER", self.Texture, "CENTER", (unit == "player" and -62) or 61, -16)
        self:Tag(self.Level, "[neav:level]")
    end

        -- Portrait

    self.Portrait = self.Health:CreateTexture("$parentPortrait", "BACKGROUND")

    if unit == "player" then
        self.Portrait:SetSize(64, 64)
        self.Portrait:SetPoint("TOPLEFT", self.Texture, 42, -12)
    elseif unit == "pet" then
        self.Portrait:SetSize(37, 37)
        self.Portrait:SetPoint("TOPLEFT", self.Texture, 7, -6)
    elseif unit == "target" or unit == "focus" then
        self.Portrait:SetSize(64, 64)
        self.Portrait:SetPoint("TOPRIGHT", self.Texture, -42, -12)
    elseif self.IsTargetFrame then
        self.Portrait:SetSize(35, 35)
        self.Portrait:SetPoint("TOPLEFT", self.Texture, 5, -5)
    elseif self.IsPartyFrame then
        self.Portrait:SetSize(37, 37)
        self.Portrait:SetPoint("TOPLEFT", self.Texture, 7, -6)
    end

    if config.show.classPortraits then
        self.Portrait.PostUpdate = UpdateClassPortraits
    end

        -- Portrait Timer

    if config.show.portraitTimer then
        self.PortraitTimer = ns.CreatePortraitTimer(self)
    end

        -- PvP Icon

    self.PvPIndicator = self:CreateTexture("$parentPvPIcon", "OVERLAY", nil, 7)

    if unit == "player" then
        self.PvPIndicator:SetSize(40, 42)
        self.PvPIndicator:SetPoint("TOPLEFT", self.Texture, 18, -20)
    elseif unit == "pet" then
        self.PvPIndicator:SetSize(35, 35)
        self.PvPIndicator:SetPoint("CENTER", self.Portrait, "LEFT", -7, -7)
    elseif unit == "target" or unit == "focus" then
        self.PvPIndicator:SetSize(40, 42)
        self.PvPIndicator:SetPoint("TOPRIGHT", self.Texture, -16, -23)
    elseif self.IsPartyFrame then
        self.PvPIndicator:SetSize(40, 40)
        self.PvPIndicator:SetPoint("TOPLEFT", self.Texture, -9, -10)
    end

        -- Group Leader Icon

    self.LeaderIndicator = self:CreateTexture("$parentLeaderIcon", "ARTWORK")
    self.LeaderIndicator:SetSize(16, 16)

    if unit == "player" then
        self.LeaderIndicator:SetPoint("TOPLEFT", self.Portrait, 3, 2)
    elseif unit == "target" or unit == "focus" then
        self.LeaderIndicator:SetPoint("TOPRIGHT", self.Portrait, -3, 2)
    elseif self.IsTargetFrame then
        self.LeaderIndicator:SetPoint("TOPLEFT", self.Portrait, -3, 4)
    elseif self.IsPartyFrame then
        self.LeaderIndicator:SetSize(14, 14)
        self.LeaderIndicator:SetPoint("CENTER", self.Portrait, "TOPLEFT", 1, -1)
    end

        -- Assist Icon

    self.AssistantIndicator = self:CreateTexture("$parentAssistIcon", "ARTWORK")
    self.AssistantIndicator:SetSize(16, 16)

    if unit == "player" then
        self.AssistantIndicator:SetPoint("TOPRIGHT", self.Portrait, -3, 3)
    elseif unit == "target" or unit == "focus" then
        self.AssistantIndicator:SetPoint("TOPRIGHT", self.Portrait, -3, 2)
    elseif self.IsTargetFrame then
        self.AssistantIndicator:SetPoint("TOPLEFT", self.Portrait, -3, 4)
    elseif self.IsPartyFrame then
        self.AssistantIndicator:SetSize(14, 14)
        self.AssistantIndicator:SetPoint("CENTER", self.Portrait, "TOPLEFT", 1, -1)
    end

        -- Raid target indicator

    self.RaidTargetIndicator = self:CreateTexture("$parentRaidTargetIcon", "ARTWORK")
    self.RaidTargetIndicator:SetPoint("CENTER", self.Portrait, "TOP", 0, -1)
    local s1 = self.Portrait:GetSize() / 3
    self.RaidTargetIndicator:SetSize(s1, s1)

        -- Phase Icon

    if not self.IsTargetFrame then
        self.PhaseIndicator = self:CreateTexture("$parentPhaseIcon", "OVERLAY")
        self.PhaseIndicator:SetPoint("CENTER", self.Portrait, "BOTTOM")

        if self.IsMainFrame then
            self.PhaseIndicator:SetSize(26, 26)
        else
            self.PhaseIndicator:SetSize(18, 18)
        end
    end

        -- Offline Icons

    self.OfflineIcon = self:CreateTexture("$parentOfflineIcon", "OVERLAY")
    self.OfflineIcon:SetPoint("TOPRIGHT", self.Portrait, 7, 7)
    self.OfflineIcon:SetPoint("BOTTOMLEFT", self.Portrait, -7, -7)

        -- Ready Check Icons

    if unit == "player" or self.IsPartyFrame then
        self.ReadyCheckIndicator = self:CreateTexture("$parentReadyCheckIcon", "OVERLAY", nil, 7)
        self.ReadyCheckIndicator:SetPoint("TOPRIGHT", self.Portrait, -7, -7)
        self.ReadyCheckIndicator:SetPoint("BOTTOMLEFT", self.Portrait, 7, 7)
        self.ReadyCheckIndicator.finishedTime = 2
        self.ReadyCheckIndicator.fadeTime = 0.5
    end

        -- Threat Textures

    self.ThreatGlow = self:CreateTexture("$parentThreatGlow", "BACKGROUND")

    if unit == "player" then
        self.ThreatGlow:SetSize(242, 93)
        self.ThreatGlow:SetPoint("TOPLEFT", self.Texture, 13, 0)
        self.ThreatGlow:SetTexture(tarTexPath.."UI-TargetingFrame-Flash")
        self.ThreatGlow:SetTexCoord(0.9453125, 0, 0, 0.181640625)
    elseif unit == "pet" then
        self.ThreatGlow:SetSize(129, 64)
        self.ThreatGlow:SetPoint("TOPLEFT", self.Texture, -5, 13)
        self.ThreatGlow:SetTexture(tarTexPath.."UI-PartyFrame-Flash")
        self.ThreatGlow:SetTexCoord(0, 1, 1, 0)
    elseif unit == "target" or unit == "focus" then
        self.ThreatGlow:SetSize(239, 92)
        self.ThreatGlow:SetPoint("TOPLEFT", self.Texture, -23, 0)
        self.ThreatGlow:SetTexture(tarTexPath.."UI-TargetingFrame-Flash")
        self.ThreatGlow:SetTexCoord(0, 0.9453125, 0, 0.182)
        self.feedbackUnit = "player"
    elseif self.IsPartyFrame then
        self.ThreatGlow:SetSize(128, 63)
        self.ThreatGlow:SetPoint("TOPLEFT", self.Texture, -3, 4)
        self.ThreatGlow:SetTexture(tarTexPath.."UI-PartyFrame-Flash")
    end

        -- LFD Role Icon

    if self.IsPartyFrame or unit == "player" or unit == "target" then
        self.GroupRoleIndicator = self:CreateTexture("$parentGroupRoleIcon", "OVERLAY", nil, 7)
        self.GroupRoleIndicator:SetSize(20, 20)

        if unit == "player" then
            self.GroupRoleIndicator:SetPoint("BOTTOMRIGHT", self.Portrait, -2, -3)
        elseif unit == "target" then
            self.GroupRoleIndicator:SetPoint("TOPLEFT", self.Portrait, -10, -2)
        else
            self.GroupRoleIndicator:SetPoint("BOTTOMLEFT", self.Portrait, -5, -5)
        end
    end

        -- Player Frame

    if unit == "player" then
        self:SetSize(175, 42)

        self.Name.Bg = self:CreateTexture("$parentNameBG", "BACKGROUND")
        self.Name.Bg:SetHeight(18)
        self.Name.Bg:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT")
        self.Name.Bg:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT")
        self.Name.Bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        self.Name.Bg:SetVertexColor(0, 0, 0, 0.70)

            -- Afk timer, using frequentUpdates function from oUF tags

        if config.units.player.showAFKTimer then
            self.NotHere = self:CreateFontString("$parentNotHere", "OVERLAY")
            self.NotHere:SetPoint("CENTER", self.Portrait, "BOTTOM")
            self.NotHere:SetFont(config.font.normal, 11, "OUTLINE")
            self.NotHere:SetShadowOffset(0, 0)
            self.NotHere:SetTextColor(0, 1, 0)
            self.NotHere.frequentUpdates = 1
            self:Tag(self.NotHere, "[neav:afk]")
        end

            -- Totems

        if playerClass == "SHAMAN" then
            CreateTotems(self)
        end

            -- Druid mana bar while in cat or bear form

        if playerClass == "DRUID" then
            self.AdditionalPower = CreateFrame("StatusBar", "$parentAdditionalPower", self, "BackdropTemplate")
            self.AdditionalPower:SetPoint("TOP", self.Power, "BOTTOM", 0, -1)
            self.AdditionalPower:SetStatusBarTexture(config.media.statusbar, "BORDER")
            self.AdditionalPower:SetSize(99, 9)
            self.AdditionalPower:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            self.AdditionalPower:SetBackdropColor(0, 0, 0, 0.70)
            self.AdditionalPower.colorPower = true
            self.AdditionalPower.displayPairs = {
                DRUID = {
                    [Enum.PowerType.Rage] = true,
                    [Enum.PowerType.Energy] = true,
                },
            }

            self.AdditionalPower.Value = self.AdditionalPower:CreateFontString("$parentAdditionalPowerText", "OVERLAY")
            self.AdditionalPower.Value:SetFont(config.font.normal, config.font.normalSize)
            self.AdditionalPower.Value:SetShadowOffset(1, -1)
            self.AdditionalPower.Value:SetPoint("CENTER", self.AdditionalPower, 0, 0.5)

            self:Tag(self.AdditionalPower.Value, "[neav:AdditionalPower]")

            self.AdditionalPower.Texture = self.AdditionalPower:CreateTexture("$parentAdditionalPowerTexture", "ARTWORK")
            self.AdditionalPower.Texture:SetTexture("Interface\\AddOns\\oUF_Neav\\media\\AdditionalPowerTexture")
            self.AdditionalPower.Texture:SetVertexColor(unpack(config.media.frameColor))
            self.AdditionalPower.Texture:SetSize(104, 28)
            self.AdditionalPower.Texture:SetPoint("TOP", self.Power, "BOTTOM", 0, 6)

            self.AdditionalPower.CostPrediction = CreateFrame("StatusBar", "$parentAltPowerPrediction", self.AdditionalPower)
            self.AdditionalPower.CostPrediction:SetStatusBarTexture(config.media.statusbar)
            self.AdditionalPower.CostPrediction:SetStatusBarColor(0.8,0.8,0.8,.50)
            self.AdditionalPower.CostPrediction:SetReverseFill(true)
            self.AdditionalPower.CostPrediction:SetPoint("TOP")
            self.AdditionalPower.CostPrediction:SetPoint("BOTTOM")
            self.AdditionalPower.CostPrediction:SetPoint("RIGHT", self.AdditionalPower:GetStatusBarTexture(),"RIGHT")
            self.AdditionalPower.CostPrediction:SetWidth(99)
        end

            -- Combo Points

        if playerClass == "ROGUE" or playerClass == "DRUID" then
            CreateComboPoints(self)
        end

            -- Raid Group Indicator

        CreateTab(self, GROUP)

            -- Pvptimer

        if self.PvPIndicator then
            self.PvPTimer = self:CreateFontString("$parentPvPTimer", "OVERLAY")
            self.PvPTimer:SetFont(config.font.normal, config.font.normalSize)
            self.PvPTimer:SetShadowOffset(1, -1)
            self.PvPTimer:SetPoint("BOTTOM", self.PvPIndicator, "TOP", 0, -3   )
            self.PvPTimer.frequentUpdates = 0.5
            self:Tag(self.PvPTimer, "[neav:pvptimer]")
        end

            -- Loot Spec Icon

        local LootSpecIndicator = self:CreateTexture("$parentSpecIcon")
        LootSpecIndicator:SetDrawLayer("OVERLAY", 2)
        LootSpecIndicator:SetSize(16, 16)
        LootSpecIndicator:SetPoint("TOPRIGHT", self.Portrait, 5, 0)
        LootSpecIndicator.alwaysShow = true

        LootSpecIndicator.Border = self:CreateTexture("$parentSpecIconRing")
        LootSpecIndicator.Border:SetDrawLayer("OVERLAY", 3)
        LootSpecIndicator.Border:SetSize(42,42)
        LootSpecIndicator.Border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
        LootSpecIndicator.Border:SetPoint("TOPLEFT", LootSpecIndicator, -5, 5)

        self.LootSpecIndicator = LootSpecIndicator

            -- Resting Icon

        self.RestingIndicator = self:CreateTexture("$parentRestingIcon", "OVERLAY")
        self.RestingIndicator:SetPoint("TOPLEFT", self.Texture, 39, -50)
        self.RestingIndicator:SetSize(31, 31) --31,34

        self.RestingIndicator.Glow = self:CreateTexture("$parentRestingIconGlow", "OVERLAY")
        self.RestingIndicator.Glow:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        self.RestingIndicator.Glow:SetTexCoord(0.0, 0.5, 0.5, 1.0)
        self.RestingIndicator.Glow:SetBlendMode("ADD")
        self.RestingIndicator.Glow:SetSize(32,32)
        self.RestingIndicator.Glow:SetPoint("TOPLEFT", self.RestingIndicator)
        self.RestingIndicator.Glow:SetAlpha(0)
        self.RestingIndicator.Glow:Hide()

            -- Combat Icon

        self.CombatIndicator = self:CreateTexture("$parentCombatIcon", "OVERLAY")
        self.CombatIndicator:SetDrawLayer("OVERLAY", 7)
        self.CombatIndicator:SetPoint("TOPLEFT", self.RestingIndicator, 1, 1)
        self.CombatIndicator:SetSize(32, 31)

        self.CombatIndicator.Glow = self:CreateTexture("$parentCombatIconGlow", "OVERLAY")
        self.CombatIndicator.Glow:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        self.CombatIndicator.Glow:SetTexCoord(0.5, 1.0, 0.5, 1.0)
        self.CombatIndicator.Glow:SetVertexColor(1.0, 0.0, 0.0)
        self.CombatIndicator.Glow:SetBlendMode("ADD")
        self.CombatIndicator.Glow:SetSize(32,32)
        self.CombatIndicator.Glow:SetPoint("TOPLEFT", self.RestingIndicator, 1, 1)
        self.CombatIndicator.Glow:SetAlpha(0)
        self.CombatIndicator.Glow:Hide()

            -- Resting/combat status flashing

        self.StatusFlash = self:CreateTexture("$parentStatusFlash", "ARTWORK")
        self.StatusFlash:SetTexture(charTexPath.."UI-Player-Status")
        self.StatusFlash:SetTexCoord(0, 0.74609375, 0, 0.53125)
        self.StatusFlash:SetBlendMode("ADD")
        self.StatusFlash:SetSize(192, 66)
        self.StatusFlash:SetPoint("TOPLEFT", self.Texture, 35, -9)
        self.StatusFlash:SetAlpha(0)

        UpdateFlashStatus(self)

        self.statusCounter = 0
        self.statusSign = -1

        self:SetScript("OnUpdate", StatusFlash_OnUpdate)

            -- Player Events

        self:RegisterEvent("PLAYER_ENTERING_WORLD", UpdatePlayerFrame, true)
        self:RegisterEvent("PLAYER_REGEN_ENABLED", UpdatePlayerFrame, true)
        self:RegisterEvent("PLAYER_REGEN_DISABLED", UpdatePlayerFrame, true)
        self:RegisterEvent("PLAYER_UPDATE_RESTING", UpdatePlayerFrame, true)
        self:RegisterEvent("CINEMATIC_STOP", UpdatePlayerFrame, true)
        self:RegisterEvent("GROUP_ROSTER_UPDATE", UpdatePlayerFrame, true)
        self:RegisterEvent("UNIT_PET", UpdatePlayerFrame)
        self:RegisterEvent("UNIT_LEVEL", UpdatePlayerFrame)
    end

        -- Petframe

    if unit == "pet" then
        self:SetSize(175, 42)

        if not config.units[ns.cUnit(unit)].disableAura then
            self.Auras = ns.CreateAuras(self, {
                point = {"TOPLEFT", self.Power, "BOTTOMLEFT", 1, -3},
                width = 20 * 4,
                height = 20,
                size = 20,
                spacing = 4,
            })
            ns.AddDebuffGroups(self.Auras, 9, false)
        end
    end

        -- Target + Focus Frame

    if unit == "target" or unit == "focus" then
        self:SetSize(175, 42)

            -- Class Colored Name Background

        self.Name.Bg = self:CreateTexture("$parentNameBG", "BACKGROUND")
        self.Name.Bg:SetHeight(18)
        self.Name.Bg:SetTexCoord(0.2, 0.8, 0.3, 0.85)
        self.Name.Bg:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT")
        self.Name.Bg:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT")
        self.Name.Bg:SetTexture("Interface\\AddOns\\oUF_Neav\\media\\nameBackground")

            -- Questmob Icon

        self.QuestIndicator = self:CreateTexture("$parentQuestIcon", "OVERLAY")
        self.QuestIndicator:SetSize(32, 32)
        self.QuestIndicator:SetPoint("CENTER", self.Health, "TOPRIGHT", 1, 10)

            -- Elite/rare frame texture, updated whenever the frame unit changes

        self.PostUpdate = UpdateClassificationTexture
    end

    if unit == "target" then
        if not config.units[ns.cUnit(unit)].disableAura then
            if config.units.target.showDebuffsOnTop then
                self.Debuffs = ns.CreateAuras(self, {
                    point = {"BOTTOMLEFT", self, "TOPLEFT", 2, 5},
                    width = 20 * 5,
                    height = 20 * 3,
                    size = 20,
                    spacing = 4.5,
                    initialAnchor = "BOTTOMLEFT",
                    growthY = "UP",
                })
                ns.AddDebuffGroups(self.Debuffs, config.units.target.numDebuffs, config.units.target.onlyShowPlayerDebuffs)

                self.Buffs = ns.CreateAuras(self, {
                    point = {"TOPLEFT", self, "BOTTOMLEFT", -2, -5},
                    width = 20 * 5,
                    height = 20 * 3,
                    size = 20,
                    spacing = 4.5,
                })
                ns.AddBuffGroup(self.Buffs, config.units.target.numBuffs, config.units.target.onlyShowPlayerBuffs)
            else
                self.Auras = ns.CreateAuras(self, {
                    point = {"TOPLEFT", self, "BOTTOMLEFT", -2, -5},
                    width = 20 * 5,
                    height = 20 * 3,
                    size = 20,
                    spacing = 4.5,
                })
                ns.AddBuffGroup(self.Auras, config.units.target.numBuffs, config.units.target.onlyShowPlayer)
                ns.AddDebuffGroups(self.Auras, config.units.target.numDebuffs, config.units.target.onlyShowPlayer, true)
            end
        end

    if not config.units.target.showDebuffsOnTop and config.units.target.showThreatValue then
            self.NumericalThreat = CreateFrame("Frame", "$parentNumericalThreat", self)
            self.NumericalThreat:SetSize(49, 18)
            self.NumericalThreat:SetPoint("BOTTOM", self, "TOP", 0, 0)
            self.NumericalThreat:Hide()

            self.NumericalThreat.bg = self.NumericalThreat:CreateTexture("$parentNumericalThreatBG", "ARTWORK")
            self.NumericalThreat.bg:SetDrawLayer("ARTWORK", 6)
            self.NumericalThreat.bg:SetPoint("TOP", 0, -3)
            self.NumericalThreat.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self.NumericalThreat.bg:SetSize(37, 14)

            self.NumericalThreat.value = self.NumericalThreat:CreateFontString("$parentNumericalThreatText", "OVERLAY", "GameFontHighlight")
            self.NumericalThreat.value:SetPoint("TOP", 1, -3)

            self.NumericalThreat.texture = self.NumericalThreat:CreateTexture("$parentNumericalThreatTexture", "ARTWORK")
            self.NumericalThreat.texture:SetPoint("TOP", 0, 0)
            self.NumericalThreat.texture:SetDrawLayer("ARTWORK", 7)
            self.NumericalThreat.texture:SetTexture("Interface\\TargetingFrame\\NumericThreatBorder")
            self.NumericalThreat.texture:SetTexCoord(0, 0.765625, 0, 0.5625)
            self.NumericalThreat.texture:SetSize(49, 18)
        end

            -- Battle Pet Icon

        self.petBattleIcon = self:CreateTexture("$parentPetBattleIcon", "ARTWORK")
        self.petBattleIcon:SetSize(32, 32)
        self.petBattleIcon:SetPoint("CENTER", self.Portrait, "RIGHT")

            -- Target Events

        self:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateTargetFrame, true)
        self:RegisterEvent("PLAYER_REGEN_DISABLED", UpdateTargetFrame, true)
        self:RegisterEvent("PLAYER_REGEN_ENABLED", UpdateTargetFrame, true)
        self:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateTargetFrame, true)
        self:RegisterEvent("UNIT_TARGETABLE_CHANGED", UpdateTargetFrame)
        self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateTargetFrame)
        self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", UpdateTargetFrame)
        self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", UpdateTargetFrame)
        self:RegisterEvent("UNIT_LEVEL", UpdateTargetFrame)
    end

    if unit == "focus" then
        CreateTab(self, FOCUS)

        self.T[4]:SetPoint("BOTTOM", self.T[1], -4, 2)

        self.FClose = CreateFrame("Button", "$parentFClose", self, "SecureActionButtonTemplate")
        self.FClose:EnableMouse(true)
        self.FClose:RegisterForClicks("AnyUp")
        self.FClose:SetAttribute("type", "macro")
        self.FClose:SetAttribute("macrotext", "/clearfocus")
        self.FClose:SetSize(20, 20)
        self.FClose:SetAlpha(0.65)
        self.FClose:SetPoint("TOPLEFT", self, (56 + (self.T[1]:GetWidth()/2)), 17)
        self.FClose:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        self.FClose:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        self.FClose:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
        self.FClose:GetHighlightTexture():SetBlendMode("ADD")

        self.FClose:SetScript("OnLeave", function()
            securecall("UIFrameFadeOut", self.T[4], 0.15, self.T[4]:GetAlpha(), 0.5)
        end)

        self.FClose:SetScript("OnEnter", function()
            securecall("UIFrameFadeIn", self.T[4], 0.15, self.T[4]:GetAlpha(), 1)
        end)

        if not config.units[ns.cUnit(unit)].disableAura then
            self.Auras = ns.CreateAuras(self, {
                point = {"TOPLEFT", self, "BOTTOMLEFT", -2, -5},
                width = 20 * 5,
                height = 20 * 3,
                size = 20,
                spacing = 4.5,
            })

            if not config.units[ns.cUnit(unit)].debuffsOnly then
                ns.AddBuffGroup(self.Auras, config.units.target.numBuffs, config.units.focus.onlyShowPlayer)
            end

            ns.AddDebuffGroups(self.Auras, config.units.target.numDebuffs, config.units.focus.onlyShowPlayer, true)
        end

            -- Focus Events

        self:RegisterEvent("PLAYER_FOCUS_CHANGED", UpdateFocusFrame, true)
        self:RegisterEvent("UNIT_LEVEL", UpdateFocusFrame)
        self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateFocusFrame)
    end

    if self.IsTargetFrame then
        self:SetSize(93, 45)

        if not config.units[ns.cUnit(unit)].disableAura then
            self.Auras = ns.CreateAuras(self, {
                point = {"TOPLEFT", self.Health, "TOPRIGHT", 7, 0},
                width = 20 * 3,
                height = 20,
                size = 20,
                spacing = 4,
            })
            ns.AddDebuffGroups(self.Auras, 4, false)
        end
    end

    if self.IsPartyFrame then
        self:SetSize(105, 30)

        if not config.units[ns.cUnit(unit)].disableAura then
            self.Auras = ns.CreateAuras(self, {
                point = {"TOPLEFT", self.Health, "TOPRIGHT", 5, 1},
                width = 20 * 3,
                height = 20,
                size = 20,
                spacing = 4,
            })
            self.Auras:SetFrameStrata("BACKGROUND")
            ns.AddDebuffGroups(self.Auras, 3, false)
        end
    end

        -- Mouseover Text

    if config.units[ns.cUnit(unit)] and config.units[ns.cUnit(unit)].mouseoverText then
        EnableMouseOver(self)
    end

    self:SetScale(config.units[ns.cUnit(unit)] and config.units[ns.cUnit(unit)].scale or 1)

        -- Range Check

    if unit == "pet" or self.IsPartyFrame then
        self.Range = {
            insideAlpha = 1,
            outsideAlpha = 0.3,
        }
    end

    return self
end

oUF:RegisterStyle("oUF_Neav", CreateUnitLayout)
oUF:Factory(function(self)

        -- Player frame spawn

    local player = self:Spawn("player", "oUF_Neav_Player")
    player:SetPoint(unpack(config.units.player.position))
    player:RegisterForDrag("LeftButton")
    player:SetFrameStrata("LOW")

    player:SetScript("OnReceiveDrag", function()
        if CursorHasItem() and not InCombatLockdown() then
            AutoEquipCursorItem()
        end
    end)

        -- Pet frame spawn

    local pet = self:Spawn("pet", "oUF_Neav_Pet")
    pet:SetPoint("TOPLEFT", player, "BOTTOMLEFT", unpack(config.units.pet.position))
    pet:SetFrameStrata("LOW")

        -- Target frame spawn

    local target = self:Spawn("target", "oUF_Neav_Target")
    target:SetPoint(unpack(config.units.target.position))
    target:RegisterForDrag("LeftButton")
    target:SetFrameStrata("LOW")

    target:SetScript("OnReceiveDrag", function()
        if CursorHasItem() and not InCombatLockdown() then
            AutoEquipCursorItem()
        end
    end)

        -- Targettarget frame spawn

    local targettarget = self:Spawn("targettarget", "oUF_Neav_TargetTarget")
    targettarget:SetPoint("TOPRIGHT", target, "BOTTOMRIGHT", 15, 0)
    targettarget:SetFrameStrata("LOW")

        -- Focus frame spawn

    local focus = self:Spawn("focus", "oUF_Neav_Focus")
    focus:SetPoint(unpack(config.units.focus.position))
    focus:SetFrameStrata("LOW")

        -- Focustarget frame spawn

    local focustarget = self:Spawn("focustarget", "oUF_Neav_FocusTarget")
    focustarget:SetPoint("TOPRIGHT", focus, "BOTTOMRIGHT", 15, 0)
    focustarget:SetFrameStrata("LOW")

        -- Party frame spawn

    if config.units.party.show then
        local party = oUF:SpawnHeader("oUF_Neav_Party", nil,
            "oUF-initialConfigFunction", [[
                self:SetWidth(105)
                self:SetHeight(30)
            ]],
            "showParty", true,
            "yOffset", -30
        )
        party:SetVisibility((config.units.party.hideInRaid and "party") or "party,raid")
        party:SetPoint(unpack(config.units.party.position))
        party:SetFrameStrata("LOW")
    end
end)

SlashCmdList["oUF_Neav_Reset"] = function(msg)
    if oUF_NeavDB then
        oUF_NeavDB = nil
        ReloadUI()
    end
end
SLASH_oUF_Neav_Reset1 = "/neavreset"
