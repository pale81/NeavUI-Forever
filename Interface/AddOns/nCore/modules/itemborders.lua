local _, nCore = ...

    -- Beautycase borders for the item slots of the bags, the bank and the character
    -- frame, colored by item quality like the tooltip border. Empty slots and common
    -- (white) items get the default border color.

function nCore:ItemBorders()
    if not nCoreDB.ItemBorders then return end

    local function IsSupportedButton(button)
        local name = button:GetName()
        local parent = button:GetParent()
        local parentName = parent and parent:GetName()

        if name and (name:match("^Character%a+Slot$") or name:match("^BankFrameItem%d+$")) then
            return true
        end

        return parentName and parentName:match("^ContainerFrame") ~= nil
    end

    local function UpdateItemBorder(button, quality, itemIDOrLink)
        if not button or not button.CreateBeautyBorder or button:IsForbidden() or not IsSupportedButton(button) then
            return
        end

        if not button.beautyBorder then
            button:CreateBeautyBorder(10)
            button:SetBeautyBorderPadding(1)
        end

        if button.IconBorder then
            button.IconBorder:SetAlpha(0)
        end

        if itemIDOrLink and not issecretvalue(quality) and quality and quality ~= Enum.ItemQuality.Common then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            button:SetBeautyBorderTexture("white")
            button:SetBeautyBorderColor(r, g, b)
        else
            button:SetBeautyBorderTexture("default")
            button:SetBeautyBorderColor()
        end
    end

    hooksecurefunc("SetItemButtonQuality", UpdateItemBorder)
end
