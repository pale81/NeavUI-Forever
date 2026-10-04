local _, addon = ...
local frame = CreateFrame("Button", nil, UIParent)
local watches = {}

local text = frame:CreateFontString(nil, "ARTWORK")
text:SetFontObject(GameFontHighlightSmall)
text:SetPoint("TOPLEFT", frame)

    -- Values can be secret during restricted content (e.g. chat lockdown), so they are only
    -- tested or compared when they are accessible.

local isTrue = function(value)
    return not issecretvalue(value) and value
end

local memberSortCompare = function(a, b)
    return ((a.color.r + a.color.g + a.color.b) .. a.name) < ((b.color.r + b.color.g + b.color.b) .. b.name)
end

local lastUpdate = 0
local result = nil
local onUpdate = function(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    if lastUpdate > 1 then
        lastUpdate = 0
        result = nil

        if GetNumGroupMembers() > 0 then
            for name, callback in pairs(watches) do
                local count = 0

                for i = 1, GetNumGroupMembers() do
                    local unit = "raid" .. i

                    if UnitExists(unit) and isTrue(callback(unit)) then
                        count = count + 1
                    end
                end

                if count > 0 then
                    result = (result and result .. ", " or "") .. name .. ": " .. count
                end
            end
        end

        if result then
            text:SetText(result)
            text:Show()

            frame:SetWidth(text:GetWidth())
        else
            text:Hide()
        end
    end
end

local matches, classId, unitName, sortable
local onEnter = function()
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")

    for name, callback in pairs(watches) do
        matches = {}
        sortable = true

        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i

            if UnitExists(unit) and isTrue(callback(unit)) then
                _, classId = UnitClass(unit)
                unitName = UnitName(unit)

                if issecretvalue(unitName) or issecretvalue(classId) then
                    sortable = false
                end

                local color = (not issecretvalue(classId) and RAID_CLASS_COLORS[classId]) or NORMAL_FONT_COLOR
                table.insert(matches, {name = unitName, color = color})
            end
        end

        if next(matches) then
            if GameTooltip:NumLines() > 0 then
                GameTooltip:AddLine(" ")
            end

            GameTooltip:AddLine(name .. ":", 1, 1, 1)

            if sortable then
                table.sort(matches, memberSortCompare)
            end

            for _, match in pairs(matches) do
                GameTooltip:AddLine(match.name, match.color.r, match.color.g, match.color.b)
            end
        end
    end

    GameTooltip:Show()
end

function addon:AddWatch(name, callback)
    watches[name] = callback
end

frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 3, -3)
frame:SetHeight(16)

frame:SetScript("OnUpdate", onUpdate)
frame:SetScript("OnEnter", onEnter)
frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
