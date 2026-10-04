local _, nCore = ...

-- Forked from rVignette by zork - 2014

function nCore:VignetteAlert()

    local addon = CreateFrame("Frame")

    local function OnEvent(self, event, id)
        if not nCoreDB.VignetteAlert then return end

        if event == "VIGNETTE_MINIMAP_UPDATED" then
            if not id then return end

            self.vignettes = self.vignettes or {}
            if self.vignettes[id] then return end

            local vignetteInfo = C_VignetteInfo.GetVignetteInfo(id)
            if not vignetteInfo then return end

            local str = vignetteInfo.atlasName and CreateAtlasMarkup(vignetteInfo.atlasName, 16, 16) or ""

            if vignetteInfo.name ~= "Garrison Cache" and vignetteInfo.name ~= "Full Garrison Cache" and vignetteInfo.name ~= nil then
                RaidWarningFrame:AddMessage(str.." "..vignetteInfo.name.." spotted!", ChatTypeInfo["RAID_WARNING"])
                print(str.." "..vignetteInfo.name,"spotted!")
                self.vignettes[id] = true
            end
        end
    end

    -- Listen for vignette event.
    addon:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    addon:SetScript("OnEvent", OnEvent)
end
