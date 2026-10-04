local _, nBuff = ...
local cfg = nBuff.Config

local unpack = unpack
local ceil = math.ceil
local format = string.format

    -- Short, white duration text (d/h/m/s). The global *_ONELETTER_ABBR strings
    -- are not replaced anymore, because that taints SecondsToTimeAbbrev.

local function FormatDuration(timeLeft)
    if timeLeft >= 86400 then
        return format("|cffffffff%dd|r", ceil(timeLeft / 86400))
    elseif timeLeft >= 3600 then
        return format("|cffffffff%dh|r", ceil(timeLeft / 3600))
    elseif timeLeft >= 60 then
        return format("|cffffffff%dm|r", ceil(timeLeft / 60))
    else
        return format("|cffffffff%d|r", timeLeft)
    end
end

local function UpdateDuration(self, timeLeft)
    if timeLeft and not issecretvalue(timeLeft) and self.Duration:IsShown() then
        self.Duration:SetText(FormatDuration(timeLeft))
    end
end

local function UpdateBorder(self)
    if self.isAuraAnchor or not self.Border then
        return
    end

    local auraType = self.auraType
    if auraType == "Debuff" or auraType == "DeadlyDebuff" then
        self.DebuffBorder:Hide()
        self.Border:SetTexture(cfg.borderDebuff)

        local debuffType = self.buttonInfo and self.buttonInfo.debuffType
        if debuffType and issecretvalue(debuffType) then
            debuffType = nil
        end
        self.Border:SetVertexColor(AuraUtil.GetAuraBorderColor(debuffType):GetRGB())
    elseif auraType == "TempEnchant" then
        self.TempEnchantBorder:Hide()
        self.Border:SetTexture(cfg.borderDebuff)
        self.Border:SetVertexColor(unpack(cfg.tempEnchantBorderColor))
    else
        self.Border:SetTexture(cfg.borderBuff)
        self.Border:SetVertexColor(unpack(cfg.buffBorderColor))
    end
end

local function StyleAuraButton(button, isDebuff)
    if button.isAuraAnchor or button.Border then
        return
    end

    local icon = button.Icon
    icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    local duration = button.Duration
    duration:ClearAllPoints()
    duration:SetPoint("BOTTOM", icon, "BOTTOM", 0, -2)
    duration:SetFont(cfg.durationFont, isDebuff and cfg.debuffFontSize or cfg.buffFontSize, "OUTLINE")
    duration:SetShadowOffset(0, 0)
    duration:SetDrawLayer("OVERLAY")

    local count = button.Count
    count:ClearAllPoints()
    count:SetPoint("TOPRIGHT", icon)
    count:SetFont(cfg.countFont, isDebuff and cfg.debuffCountSize or cfg.buffCountSize, "OUTLINE")
    count:SetShadowOffset(0, 0)
    count:SetDrawLayer("OVERLAY")

    button.Border = button:CreateTexture(nil, "ARTWORK")
    button.Border:SetPoint("TOPRIGHT", icon, 1, 1)
    button.Border:SetPoint("BOTTOMLEFT", icon, -1, -1)

    button.Shadow = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    button.Shadow:SetTexture("Interface\\AddOns\\nBuff\\media\\textureShadow")
    button.Shadow:SetPoint("TOPRIGHT", button.Border, 3.35, 3.35)
    button.Shadow:SetPoint("BOTTOMLEFT", button.Border, -3.35, -3.35)
    button.Shadow:SetVertexColor(0, 0, 0, 1)

    hooksecurefunc(button, "UpdateDuration", UpdateDuration)
    hooksecurefunc(button, "UpdateAuraType", UpdateBorder)
    hooksecurefunc(button, "Update", UpdateBorder)

    UpdateBorder(button)
end

for _, auraFrame in ipairs({BuffFrame, DebuffFrame}) do
    local isDebuff = auraFrame == DebuffFrame

    for _, button in ipairs(auraFrame.auraFrames) do
        StyleAuraButton(button, isDebuff)
    end
end
