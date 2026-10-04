local _, nChat = ...

local find = string.find
local gsub = string.gsub
local sub = string.sub

    -- URLs are shown as addon links, which the default UI passes on to the
    -- "SetItemRef" EventRegistry event.

local LINK_PREFIX = "addon:nChat:url:"

local found = false

local function ColorURL(text, url)
    found = true
    return " |H"..LINK_PREFIX..tostring(url).."|h".."|cff0099FF["..tostring(url).."]|h|r "
end

local function ScanURL(text)
    found = false

    if find(text:upper(), "%pTINTERFACE%p+") then
        found = true
    end

    -- 192.168.2.1:1234
    if not found then
        text = gsub(text, "(%s?)(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:%d%d?%d?%d?%d?)(%s?)", ColorURL)
    end
    -- 192.168.2.1
    if not found then
        text = gsub(text, "(%s?)(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?)(%s?)", ColorURL)
    end
    -- www.url.com:3333
    if not found then
        text = gsub(text, "(%s?)([%w_-]+%.?[%w_-]+%.[%w_-]+:%d%d%d?%d?%d?)(%s?)", ColorURL)
    end
    -- http://www.google.com
    if not found then
        text = gsub(text, "(%s?)(%a+://[%w_/%.%?%%=~&-\"%-]+)(%s?)", ColorURL)
    end
    -- www.google.com
    if not found then
        text = gsub(text, "(%s?)(www%.[%w_/%.%?%%=~&-\"%-]+)(%s?)", ColorURL)
    end
    -- url@domain.com
    if not found then
        text = gsub(text, "(%s?)([_%w-%.~-]+@[_%w-]+%.[_%w-%.]+)(%s?)", ColorURL)
    end

    return text
end

table.insert(nChat.MessageFilters, ScanURL)

EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button, chatFrame)
    if sub(link, 1, #LINK_PREFIX) ~= LINK_PREFIX then
        return
    end

    local value = sub(link, #LINK_PREFIX + 1)
    local editBox = ChatFrameUtil.ChooseBoxForSend(chatFrame)
    if editBox then
        ChatFrameUtil.ActivateChat(editBox)
        editBox:SetText(value)
        editBox:HighlightText()
    end
end, nChat)
