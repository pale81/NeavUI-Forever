local _, nCore = ...

function nCore:ErrorFilter()
    UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    UIErrorsFrame:SetTimeVisible(1)
    UIErrorsFrame:SetFadeDuration(0.75)

        -- Constants that don't exist in this client are skipped.

    local ignoreList = {
        [193] = true, -- aka LE_GAME_ERR_NO_ATTACK_TARGET, variable version doesn"t work.
    }

    for _, name in ipairs({
        "LE_GAME_ERR_ABILITY_COOLDOWN",
        "LE_GAME_ERR_SPELL_COOLDOWN",
        "LE_GAME_ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS",
        "LE_GAME_ERR_OUT_OF_HOLY_POWER",
        "LE_GAME_ERR_OUT_OF_POWER_DISPLAY",
        "LE_GAME_ERR_OUT_OF_SOUL_SHARDS",
        "LE_GAME_ERR_OUT_OF_FOCUS",
        "LE_GAME_ERR_OUT_OF_COMBO_POINTS",
        "LE_GAME_ERR_OUT_OF_CHI",
        "LE_GAME_ERR_OUT_OF_PAIN",
        "LE_GAME_ERR_OUT_OF_HEALTH",
        "LE_GAME_ERR_OUT_OF_RAGE",
        "LE_GAME_ERR_OUT_OF_ARCANE_CHARGES",
        "LE_GAME_ERR_OUT_OF_RANGE",
        "LE_GAME_ERR_OUT_OF_ENERGY",
        "LE_GAME_ERR_OUT_OF_LUNAR_POWER",
        "LE_GAME_ERR_OUT_OF_RUNIC_POWER",
        "LE_GAME_ERR_OUT_OF_INSANITY",
        "LE_GAME_ERR_OUT_OF_RUNES",
        "LE_GAME_ERR_OUT_OF_FURY",
        "LE_GAME_ERR_OUT_OF_MAELSTROM",
        "LE_GAME_ERR_SPELL_FAILED_TOTEMS",
        "LE_GAME_ERR_SPELL_FAILED_EQUIPPED_ITEM",
        "LE_GAME_ERR_SPELL_ALREADY_KNOWN_S",
        "LE_GAME_ERR_SPELL_FAILED_SHAPESHIFT_FORM_S",
        "LE_GAME_ERR_SPELL_FAILED_ALREADY_AT_FULL_MANA",
        "LE_GAME_ERR_OUT_OF_MANA",
        "LE_GAME_ERR_SPELL_OUT_OF_RANGE",
        "LE_GAME_ERR_SPELL_FAILED_S",
        "LE_GAME_ERR_SPELL_FAILED_REAGENTS",
        "LE_GAME_ERR_SPELL_FAILED_REAGENTS_GENERIC",
        "LE_GAME_ERR_SPELL_FAILED_NOTUNSHEATHED",
        "LE_GAME_ERR_SPELL_UNLEARNED_S",
        "LE_GAME_ERR_SPELL_FAILED_EQUIPPED_SPECIFIC_ITEM",
        "LE_GAME_ERR_SPELL_FAILED_ALREADY_AT_FULL_POWER_S",
        "LE_GAME_ERR_SPELL_FAILED_EQUIPPED_ITEM_CLASS_S",
        "LE_GAME_ERR_SPELL_FAILED_ALREADY_AT_FULL_HEALTH",
        "LE_GAME_ERR_GENERIC_NO_VALID_TARGETS",
        "LE_GAME_ERR_BADATTACKFACING",
        "LE_GAME_ERR_BADATTACKPOS",
        "LE_GAME_ERR_ITEM_COOLDOWN",
        "LE_GAME_ERR_CANT_USE_ITEM",
    }) do
        local messageType = _G[name]
        if messageType then
            ignoreList[messageType] = true
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("UI_ERROR_MESSAGE")

    f:SetScript("OnEvent", function(self, event, messageType, message)
        if issecretvalue(messageType) then
            UIErrorsFrame:AddMessage(message, 1, .1, .1)
        elseif nCoreDB.ErrorFilter and not ignoreList[messageType] then
            UIErrorsFrame:AddMessage(message, 1, .1, .1)
        elseif not nCoreDB.ErrorFilter then
            UIErrorsFrame:AddMessage(message, 1, .1, .1)
        end
    end)
end
