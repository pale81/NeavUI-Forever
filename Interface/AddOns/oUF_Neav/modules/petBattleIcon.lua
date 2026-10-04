--[[
# Element: Battle Pet Indicator

Shows battle pet type icon.

## Widget

petBattleIcon - A `Texture` used to display the loot specialization icon.

    self.petBattleIcon = self:CreateTexture("$parentPetBattleIcon", "ARTWORK")
    self.petBattleIcon:SetSize(32, 32)
    self.petBattleIcon:SetPoint("CENTER", self.Portrait, "RIGHT")

--]]

local _, ns = ...
local oUF = ns.oUF or oUF

local function Update(self, event)
    local unit = self.__unit

    if unit and (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and PET_TYPE_SUFFIX[UnitBattlePetType(unit)] then
        local petType = UnitBattlePetType(unit)
        self.petBattleIcon:SetTexture("Interface\\TargetingFrame\\PetBadge-"..PET_TYPE_SUFFIX[petType])
        self.petBattleIcon:Show()
    else
        self.petBattleIcon:Hide()
    end
end

local function Path(self, ...)
    --[[ Override: petBattleIcon.Override(self, event, ...)
    Used to completely override the internal update function.

    * self  - the parent object
    * event - the event triggering the update (string)
    * ...   - the arguments accompanying the event
    --]]
    return (self.petBattleIcon.Override or Update) (self, ...)
end

local function ForceUpdate(element)
    return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
    local element = self.petBattleIcon
    if element then
        element.__owner = self
        element.ForceUpdate = ForceUpdate

        if self.__unit == "target" then
            self:RegisterEvent("PLAYER_ENTERING_WORLD", Path, true)
            self:RegisterEvent("PLAYER_TARGET_CHANGED", Path, true)
        end

        return true
    end
end

local function Disable(self)
    local element = self.petBattleIcon
    if element then
        element:Hide()

        self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
        self:UnregisterEvent("PLAYER_TARGET_CHANGED", Path)
    end
end

oUF:AddElement("petBattleIcon", Path, Enable, Disable)
