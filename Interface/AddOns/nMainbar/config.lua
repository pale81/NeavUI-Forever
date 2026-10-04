local _, nMainbar = ...

    -- Position, size, number of buttons, visibility (incl. mouseover) and the
    -- gryphons of all action bars are set with Edit Mode.

nMainbar.Config = {
    showPicomenu = true,

    button = {
        showVehicleKeybinds = true,
        showKeybinds = false,
        showMacroNames = false,
        buttonOutOfRange = false,

        watchbarFontsize = 12,
        watchbarFont = STANDARD_TEXT_FONT,

        countFontsize = 19,
        countFont = "Interface\\AddOns\\nMainbar\\Media\\font.ttf",

        macronameFontsize = 15,
        macronameFont = "Interface\\AddOns\\nMainbar\\Media\\font.ttf",

        hotkeyFontsize = 18,
        hotkeyFont = "Interface\\AddOns\\nMainbar\\Media\\font.ttf",

        petHotKeyFontsize = 15,
    },

    color = {   -- Red, Green, Blue, Alpha
        Normal = CreateColor(1.0, 0.78, 0.52, 1.0),           -- Button border, bronze like the gryphons (white = original gray)
        IsEquipped = CreateColor(0.0, 1.0, 0.0, 1.0),
        OutOfRange = CreateColor(0.8, 0.1, 0.1, 1.0),
        OutOfMana = CreateColor(0.3, 0.3, 1.0, 1.0),
        NotUsable = CreateColor(0.35, 0.35, 0.35, 1.0),

        HotKeyText = CreateColor(0.6, 0.6, 0.6, 1.0),
        MacroText = CreateColor(1.0, 1.0, 1.0, 1.0),
        CountText = CreateColor(1.0, 1.0, 1.0, 1.0),
    },

    vehicleBar = {
        scale = 0.80,
    },
}
