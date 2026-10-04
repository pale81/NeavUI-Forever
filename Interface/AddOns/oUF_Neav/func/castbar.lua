local _, ns = ...
local config = ns.Config

function ns.ColorBorder(self, ...)
    local texture, r, g, b = ...
    self:SetBeautyBorderTexture(texture)
    self:SetBeautyBorderColor(r, g, b)
end

    -- The non-interruptible state of a cast can be secret, so it can't be used in a
    -- condition. Instead a red border is laid over the default border and its alpha is
    -- set from the (possibly secret) boolean.

local function CreateNonInterruptibleBorder(frame, color)
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 1)
    overlay:CreateBeautyBorder(11)
    overlay:SetBeautyBorderTexture("white")
    overlay:SetBeautyBorderColor(unpack(color))
    overlay:SetAlpha(0)

    for i = 1, 8 do
        overlay.beautyBorder[i]:ClearAllPoints()
        overlay.beautyBorder[i]:SetAllPoints(frame.beautyBorder[i])
        overlay.beautyShadow[i]:Hide()
    end

    return overlay
end

local function UpdateInterruptible(self, unit, notInterruptible)
    if unit == "player" or (not issecretvalue(notInterruptible) and notInterruptible == nil) then
        return
    end

    local color = self.nonInterruptibleColor or {0.7, 0.0, 0.0}

    if self.beautyBorder and not self.NonInterruptibleBorder then
        self.NonInterruptibleBorder = CreateNonInterruptibleBorder(self, color)

        if self.IconOverlay then
            self.IconOverlay.NonInterruptibleBorder = CreateNonInterruptibleBorder(self.IconOverlay, color)
        end
    end

    if self.NonInterruptibleBorder then
        self.NonInterruptibleBorder:SetAlphaFromBoolean(notInterruptible, 1, 0)
    end

    if self.IconOverlay and self.IconOverlay.NonInterruptibleBorder then
        self.IconOverlay.NonInterruptibleBorder:SetAlphaFromBoolean(notInterruptible, 1, 0)
    end
end

local function IsChanneling(unit)
    local name = UnitChannelInfo(unit)
    return issecretvalue(name) or name ~= nil
end

function ns.UpdateCastbarColor(self, unit, spellID, notInterruptible)
    local startColor = IsChanneling(unit) and self.channeledColor or self.castColor or {1.0, 0.7, 0.0}

    self:SetStatusBarColor(unpack(startColor))
    self.Background:SetVertexColor(startColor[1]*0.3, startColor[2]*0.3, startColor[3]*0.3)

    UpdateInterruptible(self, unit, notInterruptible)
end

function ns.UpdateCastbarInterruptible(self, unit, spellID, notInterruptible)
    UpdateInterruptible(self, unit, notInterruptible)
end

function ns.UpdateCastbarFailed(self)
    self:SetStatusBarColor(unpack(self.failedCastColor))
    self.Background:SetVertexColor(self.failedCastColor[1]*0.3, self.failedCastColor[2]*0.3, self.failedCastColor[3]*0.3)
end

function ns.CustomDelayText(self, delay)
    self.Delay:SetFormattedText("|cffff0000-%.1f|r", delay)
end

function ns.SetupCastbarCallbacks(castbar)
    castbar.PostCastStart = ns.UpdateCastbarColor
    castbar.PostCastInterruptible = ns.UpdateCastbarInterruptible
    castbar.PostCastFail = ns.UpdateCastbarFailed
    castbar.PostCastInterrupted = ns.UpdateCastbarFailed
    castbar.CustomDelayText = ns.CustomDelayText
end

function ns.CreateCastbarStrings(self, size)
    self.Castbar.Time = self.Castbar:CreateFontString(nil, "OVERLAY")

    if size then
        self.Castbar.Time:SetFont(config.font.normal, 21)
        self.Castbar.Time:SetPoint("RIGHT", self.Castbar, -2, 0)
    else
        self.Castbar.Time:SetFont(config.font.normal, config.font.normalSize)
        self.Castbar.Time:SetPoint("RIGHT", self.Castbar, -5, 0)
    end

    self.Castbar.Time:SetShadowOffset(1, -1)
    self.Castbar.Time:SetHeight(10)
    self.Castbar.Time:SetJustifyH("RIGHT")
    self.Castbar.Time:SetParent(self.Castbar)

    self.Castbar.Delay = self.Castbar:CreateFontString(nil, "OVERLAY")
    self.Castbar.Delay:SetFont(config.font.normal, config.font.normalSize - 1)
    self.Castbar.Delay:SetShadowOffset(1, -1)
    self.Castbar.Delay:SetPoint("RIGHT", self.Castbar.Time, "LEFT", -2, 0)

    self.Castbar.Text = self.Castbar:CreateFontString(nil, "OVERLAY")
    self.Castbar.Text:SetFont(config.font.normal, config.font.normalSize)
    self.Castbar.Text:SetPoint("LEFT", self.Castbar, 4, 0)

    if size then
        self.Castbar.Text:SetPoint("RIGHT", self.Castbar.Delay, "LEFT", -7, 0)
    else
        self.Castbar.Text:SetPoint("RIGHT", self.Castbar.Delay, "LEFT", -4, 0)
    end

    self.Castbar.Text:SetShadowOffset(1, -1)
    self.Castbar.Text:SetHeight(10)
    self.Castbar.Text:SetJustifyH("LEFT")
    self.Castbar.Text:SetParent(self.Castbar)
end
