local _, nCore = ...

function nCore:AltBuy()
    local L = nCore.L

    local NEW_ITEM_VENDOR_STACK_BUY = ITEM_VENDOR_STACK_BUY
    ITEM_VENDOR_STACK_BUY = "|cffa9ff00"..NEW_ITEM_VENDOR_STACK_BUY.."|r" -- luacheck: ignore

        -- Alt-click to buy a stack.

    hooksecurefunc("MerchantItemButton_OnModifiedClick", function(self, ...)
        if not nCoreDB.AltBuy then return end
        if IsAltKeyDown() then
            local numAvailable = C_MerchantFrame.GetItemInfo(self:GetID()).numAvailable

            -- -1 means an item has unlimited supply.
            if numAvailable ~= -1 then
                BuyMerchantItem(self:GetID(), numAvailable)
            else
                BuyMerchantItem(self:GetID(), GetMerchantItemMaxStack(self:GetID()))
            end
        end
    end)

        -- Add a hint to the tooltip.

    local function IsMerchantButtonOver()
        local focus = GetMouseFoci()[1]
        local name = focus and focus.GetName and focus:GetName()
        return name and name:find("MerchantItem%d")
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(self)
        if self ~= GameTooltip or not nCoreDB.AltBuy then return end
        if MerchantFrame:IsShown() and IsMerchantButtonOver() then
            for i = 2, GameTooltip:NumLines() do
                local line = _G["GameTooltipTextLeft"..i]:GetText() or ""
                if not issecretvalue(line) and line:find("<[sS]hift") then
                    GameTooltip:AddLine("|cff00ffcc"..L.AltBuyVendorToolip.."|r")
                end
            end
        end
    end)
end
