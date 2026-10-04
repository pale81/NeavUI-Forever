local _, nBuff = ...

    -- Position, icon size, icons per row and padding are set with Edit Mode.

nBuff.Config = {
    buffBorderColor = {1.0, 0.78, 0.52},          -- Bronze like the gryphons, {1, 1, 1} = original gray

    buffFontSize = 14,
    buffCountSize = 16,

    borderBuff = "Interface\\AddOns\\nBuff\\media\\textureOverlay",
    borderDebuff = "Interface\\AddOns\\nBuff\\media\\textureDebuff",

    debuffFontSize = 14,
    debuffCountSize = 16,

    tempEnchantBorderColor = {0.9, 0.25, 0.9},

    durationFont = STANDARD_TEXT_FONT,
    countFont = STANDARD_TEXT_FONT,
}
