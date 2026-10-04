local _, nChat = ...
local cfg = nChat.Config

local type = type
local select = select
local unpack = unpack
local gsub = string.gsub
local find = string.find
local sub = string.sub

_G.CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0

_G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 0.5
_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0

_G.CHAT_FRAME_FADE_OUT_TIME = 0.25
_G.CHAT_FRAME_FADE_TIME = 0.1

_G.CHAT_FONT_HEIGHTS = {
    [1] = 8,
    [2] = 9,
    [3] = 10,
    [4] = 11,
    [5] = 12,
    [6] = 13,
    [7] = 14,
    [8] = 15,
    [9] = 16,
    [10] = 17,
    [11] = 18,
    [12] = 19,
    [13] = 20,
}

    -- Short channel names and flags.
    -- The CHAT_*_GET and CHAT_FLAG_* globals are read by the default chat code while it
    -- handles (possibly secret) message payloads, so replacing them would taint that code.
    -- Instead the default prefixes are replaced in the finished message.

local SHORT_PREFIXES = {
    GUILD = "(|Hchannel:Guild|hG|h) ",
    OFFICER = "(|Hchannel:o|hO|h) ",

    PARTY = "(|Hchannel:party|hP|h) ",
    PARTY_LEADER = "(|Hchannel:party|hPL|h) ",
    PARTY_GUIDE = "(|Hchannel:party|hDG|h) ",
    MONSTER_PARTY = "(|Hchannel:raid|hR|h) ",

    RAID = "(|Hchannel:raid|hR|h) ",
    RAID_WARNING = "(RW!) ",
    RAID_LEADER = "(|Hchannel:raid|hL|h) ",

    BATTLEGROUND = "(|Hchannel:Battleground|hBG|h) ",
    BATTLEGROUND_LEADER = "(|Hchannel:Battleground|hBL|h) ",

    INSTANCE_CHAT = "|Hchannel:INSTANCE_CHAT|h[I]|h ",
    INSTANCE_CHAT_LEADER = "|Hchannel:INSTANCE_CHAT|h[IL]|h ",
}

local SHORT_FLAGS = {
    AFK = "[AFK] ",
    DND = "[DND] ",
    GM = "[GM] ",
}

local channelReplacements = {}
local flagReplacements = {}

for chatType, shortPrefix in pairs(SHORT_PREFIXES) do
    local format = _G["CHAT_"..chatType.."_GET"]
    local prefix = type(format) == "string" and format:match("^(.-)%%s")

    if prefix and prefix ~= "" then
        channelReplacements[#channelReplacements + 1] = {prefix, shortPrefix}
    end
end

    -- Longer prefixes first, e.g. "[Party Leader]" before "[Party]".

table.sort(channelReplacements, function(a, b)
    return #a[1] > #b[1]
end)

for flag, shortFlag in pairs(SHORT_FLAGS) do
    local text = _G["CHAT_FLAG_"..flag]

    if type(text) == "string" and text ~= "" then
        flagReplacements[#flagReplacements + 1] = {text, shortFlag}
    end
end

local function ReplacePlain(text, old, new)
    local first, last = find(text, old, 1, true)

    if first then
        return sub(text, 1, first - 1)..new..sub(text, last + 1), true
    end

    return text, false
end

    -- Other modules (e.g. urlcopy.lua) can add their own text filters.

nChat.MessageFilters = {}

local function FilterMessage(text)
    for _, replacement in ipairs(channelReplacements) do
        local replaced
        text, replaced = ReplacePlain(text, replacement[1], replacement[2])

        if replaced then
            break
        end
    end

    for _, replacement in ipairs(flagReplacements) do
        text = ReplacePlain(text, replacement[1], replacement[2])
    end

    text = gsub(text, "(|HBNplayer.-|h)%[(.-)%]|h", "%1%2|h")
    text = gsub(text, "(|Hplayer.-|h)%[(.-)%]|h", "%1%2|h")
    text = gsub(text, "%[(%d0?)%. (.-)%]", "(%1)")

    for _, filter in ipairs(nChat.MessageFilters) do
        text = filter(text)
    end

    return text
end

local function AddMessage(self, text, ...)
        -- Secret messages can't be modified.
    if type(text) == "string" and not issecretvalue(text) then
        text = FilterMessage(text)
    end

    return self.nChatAddMessage(self, text, ...)
end

    -- Quick Join Button Options

if cfg.enableQuickJoinButton then
    ChatAlertFrame:ClearAllPoints()
    ChatAlertFrame:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "TOPLEFT", 0, 0)
else
    QuickJoinToastButton:SetAlpha(0)
    QuickJoinToastButton:EnableMouse(false)
    QuickJoinToastButton:UnregisterAllEvents()
end

    -- Voice Chat Buttons

if not cfg.enableVoiceChatButtons then
    for _, frame in pairs({
        ChatFrameChannelButton,
        ChatFrameToggleVoiceDeafenButton,
        ChatFrameToggleVoiceMuteButton,
    }) do
        frame:SetAlpha(0)
        frame:EnableMouse(false)
        frame:UnregisterAllEvents()
    end
end

    -- Hide the menu.

ChatFrameMenuButton:SetAlpha(0)
ChatFrameMenuButton:EnableMouse(false)

    -- Tab text colors for the tabs

hooksecurefunc("FCFTab_UpdateColors", function(self, selected)
    if selected then
        self:GetFontString():SetTextColor(unpack(cfg.tab.selectedColor))
    else
        self:GetFontString():SetTextColor(unpack(cfg.tab.normalColor))
    end
end)

    -- Reposit toast frame.

BNToastFrame:HookScript("OnShow", function(self)
    BNToastFrame:ClearAllPoints()
    BNToastFrame:SetPoint("BOTTOMLEFT", ChatFrame1EditBox, "TOPLEFT", 0, 15)
end)

    -- Modify the chat tabs.

local function SkinTab(chat)
    local font = chat:GetFont()

    local tab = _G[chat:GetName().."Tab"]
    for i = 1, select("#", tab:GetRegions()) do
        local texture = select(i, tab:GetRegions())
        if texture and texture:GetObjectType() == "Texture" then
            texture:SetTexture(nil)
        end
    end

    local tabText = tab:GetFontString()
    tabText:SetJustifyH("CENTER")
    tabText:SetWidth(60)
    if cfg.tab.fontOutline then
        tabText:SetFont(font, cfg.tab.fontSize, "OUTLINE")
        tabText:SetShadowOffset(0, 0)
    else
        tabText:SetFont(font, cfg.tab.fontSize, "")
        tabText:SetShadowOffset(1, -1)
    end

    local a1, a2, a3, a4 = tabText:GetPoint()
    tabText:SetPoint(a1, a2, a3, a4, 1)

    local s1, s2, s3 = unpack(cfg.tab.specialColor)
    local e1, e2, e3 = unpack(cfg.tab.selectedColor)
    local n1, n2, n3 = unpack(cfg.tab.normalColor)

    local tabGlow = tab.glow
    hooksecurefunc(tabGlow, "Show", function()
        tabText:SetTextColor(s1, s2, s3, CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA)
    end)

    hooksecurefunc(tabGlow, "Hide", function()
        tabText:SetTextColor(n1, n2, n3)
    end)

    local function GetTabTextColor()
        if chat == SELECTED_CHAT_FRAME and chat.isDocked then
            return e1, e2, e3
        elseif tabGlow:IsShown() then
            return s1, s2, s3
        else
            return n1, n2, n3
        end
    end

    tab:HookScript("OnEnter", function()
        tabText:SetTextColor(s1, s2, s3, tabText:GetAlpha())
    end)

    tab:HookScript("OnLeave", function()
        tabText:SetTextColor(GetTabTextColor())
    end)

    hooksecurefunc(tab, "Show", function()
        if not tab.wasShown then
            if chat:IsMouseOver() then
                tab:SetAlpha(CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA)
            else
                tab:SetAlpha(CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA)
            end

            tabText:SetTextColor(GetTabTextColor())

            tab.wasShown = true
        end
    end)
end

local function UpdateEditBoxBorderColor(editBox)
    local chatType = editBox:GetChatType()
    if not chatType then
        return
    end

    local info = ChatTypeInfo[chatType]
    if info then
        editBox:SetBeautyBorderColor(info.r, info.g, info.b)
    end
end

local function ModChat(chat)
    local name = chat:GetName()

    if not cfg.chatOutline then
        chat:SetShadowOffset(1, -1)
    end

    if cfg.disableFade then
        chat:SetFading(false)
    end

    SkinTab(chat)

    local font, fontsize, fontflags = chat:GetFont()
    chat:SetFont(font, fontsize, cfg.chatOutline and "OUTLINE" or fontflags)
    chat:SetClampedToScreen(true)

    chat:SetResizeBounds(150, 25, UIParent:GetWidth(), UIParent:GetHeight())

        -- Shift + mousewheel scrolls to the top or bottom.

    chat:HookScript("OnMouseWheel", function(self, delta)
        if IsShiftKeyDown() then
            if delta > 0 then
                self:ScrollToTop()
            else
                self:ScrollToBottom()
            end
        end
    end)

    if chat ~= ChatFrame2 and not chat.nChatAddMessage then
        chat.nChatAddMessage = chat.AddMessage
        chat.AddMessage = AddMessage
    end

    for _, texture in pairs({
        "ButtonFrameBackground",
        "ButtonFrameTopLeftTexture",
        "ButtonFrameBottomLeftTexture",
        "ButtonFrameTopRightTexture",
        "ButtonFrameBottomRightTexture",
        "ButtonFrameLeftTexture",
        "ButtonFrameRightTexture",
        "ButtonFrameBottomTexture",
        "ButtonFrameTopTexture",
    }) do
        local region = _G[name..texture]
        if region then
            region:SetTexture(nil)
        end
    end

        -- Modify the editbox

    local editBox = chat.editBox

    for _, texture in pairs({"Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid"}) do
        local region = _G[editBox:GetName()..texture]
        if region then
            region:SetTexture(nil)
        end
    end

    editBox:SetAltArrowKeyMode(cfg.ignoreArrows)

    if cfg.showInputBoxAbove then
        local tabHeight = _G[name.."Tab"]:GetHeight()
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", 0, tabHeight + 5)
        editBox:SetPoint("BOTTOMRIGHT", chat, "TOPRIGHT", 0, tabHeight + 5)
    end

    Mixin(editBox, BackdropTemplateMixin)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        insets = {
            left = 3, right = 3, top = 2, bottom = 2
        },
    })

    editBox:SetBackdropColor(0, 0, 0, 0.5)
    editBox:CreateBeautyBorder(11)
    editBox:SetBeautyBorderPadding(-2, -1, -2, -1, -2, -1, -2, -1)

    if cfg.enableBorderColoring then
        editBox:SetBeautyBorderTexture("white")
        hooksecurefunc(editBox, "UpdateHeader", UpdateEditBoxBorderColor)
    end
end

local function SetChatStyle()
    for _, frame in pairs(CHAT_FRAMES) do
        local chat = _G[frame]

        if chat then
            chat:SetClampRectInsets(0, -1, 0, 0)

            if not chat.hasModification then
                ModChat(chat)

                if cfg.enableChatWindowBorder then
                    if chat.Background then
                        chat.BorderFrame = CreateFrame("Frame")
                        chat.BorderFrame:SetParent(chat)
                        chat.BorderFrame:SetAllPoints(chat.Background)
                        chat.BorderFrame:CreateBeautyBorder(12)
                        chat.BorderFrame:SetBeautyBorderPadding(2)
                    end
                end

                chat.hasModification = true
            end
        end
    end
end
hooksecurefunc("FCF_OpenTemporaryWindow", SetChatStyle)
SetChatStyle()

    -- Chat menu, just a middle click on the chatframe 1 tab

ChatFrame1Tab:RegisterForClicks("AnyUp")
ChatFrame1Tab:HookScript("OnClick", function(self, button)
    if button == "MiddleButton" or button == "Button4" or button == "Button5" then
        ChatFrameMenuButton:OpenMenu()
    end
end)

    -- Modify the gm chatframe and add a sound notification on incoming whispers

local eventWatcher = CreateFrame("Frame")
eventWatcher:RegisterEvent("ADDON_LOADED")
eventWatcher:RegisterEvent("CHAT_MSG_WHISPER")
eventWatcher:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "Blizzard_GMChatUI" then
            GMChatFrame:SetHeight(200)
        elseif name == "Blizzard_CombatLog" then
            hooksecurefunc("FCF_DockUpdate", function()
                if COMBATLOG and COMBATLOG.isDocked then
                    COMBATLOG:SetClampRectInsets(0, -1, 0, 0)
                end
            end)
        end
    end

    if event == "CHAT_MSG_WHISPER" then
        if cfg.alwaysAlertOnWhisper then
            PlaySound(SOUNDKIT.TELL_MESSAGE)
        end
    end
end)

    -- Combat and chat log menu options.

Menu.ModifyMenu("MENU_FCF_TAB", function(owner, rootDescription)
    rootDescription:CreateDivider()

    rootDescription:CreateCheckbox("|cffFFD100CombatLog|r", LoggingCombat, function()
        if not LoggingCombat() then
            LoggingCombat(true)
            DEFAULT_CHAT_FRAME:AddMessage(COMBATLOGENABLED, 1, 1, 0)
        else
            LoggingCombat(false)
            DEFAULT_CHAT_FRAME:AddMessage(COMBATLOGDISABLED, 1, 1, 0)
        end
    end)

    rootDescription:CreateCheckbox("|cffFFD100ChatLog|r", LoggingChat, function()
        if not LoggingChat() then
            LoggingChat(true)
            DEFAULT_CHAT_FRAME:AddMessage(CHATLOGENABLED, 1, 1, 0)
        else
            LoggingChat(false)
            DEFAULT_CHAT_FRAME:AddMessage(CHATLOGDISABLED, 1, 1, 0)
        end
    end)
end)
