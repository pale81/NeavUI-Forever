local gsub = string.gsub

for i = 1, Constants.ChatFrameConstants.MaxChatWindows do
    local editBox = _G["ChatFrame"..i.."EditBox"]

    editBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        if UnitExists("target") and UnitIsPlayer("target") and UnitIsFriend("player", "target") then
            if text:len() < 5 then
                if text:sub(1, 4) == "/tt " then
                    local unitname, realm = UnitName("target")

                    if issecretvalue(unitname) or issecretvalue(realm) then
                        return
                    end

                    if unitname then
                        unitname = gsub(unitname, " ", "")
                    end

                    if unitname and realm and not UnitIsSameServer("player", "target") then
                        unitname = unitname.."-"..gsub(realm, " ", "")
                    end

                    ChatFrameUtil.SendTell((unitname or SPELL_FAILED_BAD_TARGETS), ChatFrame1)
                end
            end
        end
    end)
end
