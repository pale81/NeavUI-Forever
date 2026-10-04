local _, nCore = ...

function nCore:MapCoords()
    local unpack = unpack

    local cfg = {
        location = {"BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 10, 0},
    }

    local mapRects = {}
    local tempVec2D = CreateVector2D(0, 0)
    local function GetPlayerMapPos(mapID)
        tempVec2D.x, tempVec2D.y = UnitPosition("player")
        if not tempVec2D.x then return end

        local mapRect = mapRects[mapID]
        if not mapRect then
            local pos1 = select(2, C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0)))
            local pos2 = select(2, C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1)))
            if not pos1 or not pos2 then return end
            mapRect = {pos1, pos2}
            mapRect[2]:Subtract(mapRect[1])

            mapRects[mapID] = mapRect
        end
        tempVec2D:Subtract(mapRect[1])

        return tempVec2D.y/mapRect[2].y, tempVec2D.x/mapRect[2].x
    end

    local nCore_CoordsFrame = CreateFrame("Frame", "nCore_Coords", WorldMapFrame, "nCore_Coords")

    nCore_CoordsFrame:SetScript("OnLoad", function(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:SetPoint(unpack(cfg.location))
    end)

        -- The coordinates of the default UI (without outline) are hidden while
        -- these are enabled.

    local blizzardCoords
    for _, frame in ipairs(WorldMapFrame.overlayFrames or {}) do
        if frame.PlayerCoords and frame.CursorCoords then
            blizzardCoords = frame
        end
    end

    nCore_CoordsFrame:SetScript("OnUpdate", function(self, elapsed)
        if blizzardCoords then
            blizzardCoords:SetAlpha(nCoreDB.MapCoords and 0 or 1)
        end

        if IsInInstance() or not nCoreDB.MapCoords then
            self.Mouse.Text:SetText("")
            self.Player.Text:SetText("")
            return
        end

        local mapID = C_Map.GetBestMapForUnit("player")
        local px, py = GetPlayerMapPos(mapID)

        if px then
            if px ~= 0 and py ~= 0 then
                self.Player.Text:SetFormattedText("%s: %.1f x %.1f", PLAYER, px * 100, py * 100)
            else
                self.Player.Text:SetText("")
            end
        end

        if WorldMapFrame.ScrollContainer:IsMouseOver() then
            local cx, cy = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()

            if cx then
                if cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1 then
                    self.Mouse.Text:SetFormattedText("%s: %.1f x %.1f", MOUSE_LABEL, cx * 100, cy * 100)
                else
                    self.Mouse.Text:SetText("")
                end
            end
        else
            self.Mouse.Text:SetText("")
        end
    end)
end