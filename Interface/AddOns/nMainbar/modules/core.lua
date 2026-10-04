local _, nMainbar = ...
local cfg = nMainbar.Config

    -- Functions

function nMainbar:IsTaintable()
    return (InCombatLockdown() or (UnitAffectingCombat("player") or UnitAffectingCombat("pet")))
end

    -- Vehicle Bar

OverrideActionBar:SetScale(cfg.vehicleBar.scale)
