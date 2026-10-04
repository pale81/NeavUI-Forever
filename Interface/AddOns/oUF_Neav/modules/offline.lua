local _, ns = ...
local oUF = ns.oUF or _G.oUF

local Update = function(self, event, unit)
    if unit and unit ~= self.__unit then
        return
    end

    unit = self.__unit

    if UnitIsConnected(unit) then
        self.OfflineIcon:Hide()
    else
        self.OfflineIcon:Show()
    end
end

local Path = function(self, ...)
    return (self.OfflineIcon.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
    return Path(element.__owner, "ForceUpdate", element.__owner.__unit)
end

local Enable = function(self)
    local officon = self.OfflineIcon

    if officon then
        officon.__owner = self
        officon.ForceUpdate = ForceUpdate

        self:RegisterEvent("UNIT_CONNECTION", Path)
        self:RegisterEvent("PLAYER_TARGET_CHANGED", Path, true)

        if officon:IsObjectType("Texture") and not officon:GetTexture() then
            officon:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
        end

        return true
    end
end

local Disable = function(self)
    local officon = self.OfflineIcon

    if officon then
        self:UnregisterEvent("UNIT_CONNECTION", Path)
        self:UnregisterEvent("PLAYER_TARGET_CHANGED", Path)
    end
end

oUF:AddElement("OfflineIcon", Path, Enable, Disable)
