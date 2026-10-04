local _, nCore = ...

function nCore:SpellID()
    local find = string.find
    local sub = string.sub

    local function AddSpellID(self, id)
        if not id or issecretvalue(id) then
            return
        end

        local text = "SpellID: "..id

            -- Don't add the line twice, e.g. when the tooltip is refreshed.
        for i = 1, self:NumLines() do
            local line = _G[self:GetName().."TextLeft"..i]
            local lineText = line and line:GetText()
            if lineText and not issecretvalue(lineText) and lineText == text then
                return
            end
        end

        self:AddLine(text, 1, 1, 1)
        self:Show()
    end

    local function OnTooltipSetData(self, data)
        if self ~= GameTooltip or not nCoreDB.SpellID or self:IsForbidden() then
            return
        end

        AddSpellID(self, data and data.id)
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnTooltipSetData)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, OnTooltipSetData)

    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        if not nCoreDB.SpellID or issecretvalue(link) then return end
        if find(link,"^spell:") then
            local id = sub(link, 7)
            ItemRefTooltip:AddLine("SpellID: "..id, 1, 1, 1)
            ItemRefTooltip:Show()
        end
    end)
end
