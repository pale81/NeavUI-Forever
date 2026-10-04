local _, nCore = ...

function nCore:QuestTracker()
    local format = string.format

    local function UpdateQuestText()
        if not WorldMapFrame or WorldMapFrame:IsMaximized() then
            return
        end

        if nCoreDB.QuestTracker then
            local _, numQuests = C_QuestLog.GetNumQuestLogEntries()
            WorldMapFrame.BorderFrame:SetTitle(format("%s - %d/%d", MAP_AND_QUEST_LOG, numQuests, C_QuestLog.GetMaxNumQuestsCanAccept()))
        else
            WorldMapFrame.BorderFrame:SetTitle(MAP_AND_QUEST_LOG)
        end
    end

    local function HookWorldMap()
        WorldMapFrame:HookScript("OnShow", UpdateQuestText)
        hooksecurefunc(WorldMapFrame, "SynchronizeDisplayState", UpdateQuestText)
        UpdateQuestText()
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("QUEST_ACCEPT_CONFIRM")
    watcher:RegisterEvent("QUEST_ACCEPTED")
    watcher:RegisterEvent("QUEST_AUTOCOMPLETE")
    watcher:RegisterEvent("QUEST_LOG_UPDATE")
    watcher:RegisterEvent("QUEST_REMOVED")

    if WorldMapFrame then
        HookWorldMap()
    else
        watcher:RegisterEvent("ADDON_LOADED")
    end

    watcher:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            if ... == "Blizzard_WorldMap" then
                HookWorldMap()
                self:UnregisterEvent("ADDON_LOADED")
            end
            return
        end

        UpdateQuestText()
    end)
end
