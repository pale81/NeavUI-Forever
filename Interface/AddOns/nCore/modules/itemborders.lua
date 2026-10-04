local _, nCore = ...

    -- Beautycase borders for the item slots of the bags, the bank, the character
    -- frame and the quest rewards, colored by item quality like the tooltip border.
    -- Empty slots, poor (gray) and common (white) items get the default border color.

function nCore:ItemBorders()
    if not nCoreDB.ItemBorders then return end

    local function IsSupportedButton(button)
        local name = button:GetName()
        local parent = button:GetParent()
        local parentName = parent and parent:GetName()

        if name and (name:match("^Character%a+Slot$") or name:match("^BankFrameItem%d+$") or name:match("QuestInfoItem%d+$")) then
            return true
        end

        return parentName and parentName:match("^ContainerFrame") ~= nil
    end

        -- Quest reward buttons are wider than their icon, the border goes around the icon.

    local function GetBorderFrame(button)
        local name = button:GetName()
        if not (name and name:match("QuestInfoItem%d+$") and button.Icon) then
            return button
        end

        if not button.nCoreIconFrame then
            local frame = CreateFrame("Frame", nil, button)
            frame:SetAllPoints(button.Icon)
            button.nCoreIconFrame = frame
        end

        return button.nCoreIconFrame
    end

    local function UpdateItemBorder(button, quality, itemIDOrLink)
        if not button or not button.CreateBeautyBorder or button:IsForbidden() or not IsSupportedButton(button) then
            return
        end

        if button.IconBorder then
            button.IconBorder:SetAlpha(0)
        end

        local frame = GetBorderFrame(button)

        if not frame.beautyBorder then
            frame:CreateBeautyBorder(10)
            frame:SetBeautyBorderPadding(1)
        end

        if itemIDOrLink and not issecretvalue(quality) and quality and quality > Enum.ItemQuality.Common then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            frame:SetBeautyBorderTexture("white")
            frame:SetBeautyBorderColor(r, g, b)
        else
            frame:SetBeautyBorderTexture("default")
            frame:SetBeautyBorderColor()
        end
    end

    hooksecurefunc("SetItemButtonQuality", UpdateItemBorder)

        -- Sidebar tabs of the character frame (stats, titles, equipment sets)

    for i = 1, 4 do
        local tab = _G["PaperDollSidebarTab"..i]
        if tab and tab.CreateBeautyBorder and not tab.beautyBorder then
            tab:CreateBeautyBorder(10)
            tab:SetBeautyBorderPadding(-3)
        end
    end
end
