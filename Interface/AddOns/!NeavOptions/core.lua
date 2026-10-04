local _, ns = ...
local L = ns.L

    -- In-game options for the config.lua tables of the NeavUI addons.
    --
    -- The addons call NeavOptions_Register(name, config) at the end of their config.lua.
    -- Changed values are saved in NeavOptionsDB and written into the config table at
    -- that point, before the rest of the addon reads it, so changes take effect after
    -- a reload. The option pages are generated from the config tables, labels and
    -- descriptions come from locale.lua.

local registry = {}

local ANCHOR_POINTS = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}

local FONTS = {
    {"Fonts\\FRIZQT__.TTF", "Friz Quadrata"},
    {"Fonts\\ARIALN.TTF", "Arial Narrow"},
    {"Fonts\\skurri.ttf", "Skurri"},
    {"Fonts\\MORPHEUS.TTF", "Morpheus"},
}

local TEXTURE_KEYS = {
    border = true,
    statusbar = true,
    customTexture = true,
    borderBuff = true,
    borderDebuff = true,
}

    -- Paths are stored as strings, numeric keys are prefixed with "#".

local function PathToString(path)
    local parts = {}
    for i, key in ipairs(path) do
        parts[i] = type(key) == "number" and ("#"..key) or key
    end
    return table.concat(parts, ".")
end

local function StringToPath(pathString)
    local path = {}
    for part in pathString:gmatch("[^%.]+") do
        local index = part:match("^#(%d+)$")
        path[#path + 1] = index and tonumber(index) or part
    end
    return path
end

local function IsFrame(value)
    return type(value) == "table" and type(value.GetObjectType) == "function"
end

local function IsColor(key, value)
    if type(value) ~= "table" or IsFrame(value) then
        return false
    end

    if type(value.r) == "number" and type(value.g) == "number" and type(value.b) == "number" then
        return true
    end

    if not tostring(key):lower():find("color") then
        return false
    end

    local count = #value
    if count ~= 3 and count ~= 4 then
        return false
    end

    for i = 1, count do
        if type(value[i]) ~= "number" or value[i] < 0 or value[i] > 1 then
            return false
        end
    end

    return true
end

local function GetColorValues(value)
    if type(value.r) == "number" then
        return {value.r, value.g, value.b, value.a}
    end
    return {value[1], value[2], value[3], value[4]}
end

    -- Colors are replaced instead of changed in place, some config tables share color
    -- tables between options.

local function MakeColor(template, r, g, b, a)
    if type(template.r) == "number" then
        if template.GetRGBA then
            return CreateColor(r, g, b, a or template.a)
        end
        return {r = r, g = g, b = b, a = a or template.a}
    end

    if #template == 4 then
        return {r, g, b, a or template[4]}
    end
    return {r, g, b}
end

local function GetParentAndKey(config, path)
    local parent = config
    for i = 1, #path - 1 do
        parent = parent[path[i]]
        if type(parent) ~= "table" then
            return
        end
    end
    return parent, path[#path]
end

local function ApplyOverride(config, path, value)
    local parent, key = GetParentAndKey(config, path)
    if not parent then
        return
    end

    local current = parent[key]

    if type(value) == "table" then
        if IsColor(key, current) then
            parent[key] = MakeColor(current, value[1], value[2], value[3], value[4])
        end
    elseif type(current) == type(value) then
        parent[key] = value
    end
end

local function SortKeys(a, b)
    if type(a) == type(b) then
        return a < b
    end
    return type(a) == "number"
end

    -- Roles of the values of anchor arrays like {"TOPLEFT", UIParent, "TOPLEFT", 34, -30}.

local function GetPositionRoles(value)
    local roles, strings, numbers = {}, 0, 0

    for index = 1, #value do
        if type(value[index]) == "string" then
            strings = strings + 1
            roles[index] = strings == 1 and "anchor" or "relativeAnchor"
        elseif type(value[index]) == "number" then
            numbers = numbers + 1
            roles[index] = numbers == 1 and "offsetX" or "offsetY"
        end
    end

    return roles
end

local function CollectEntries(entries, value, path, depth, visited)
    if depth > 8 or visited[value] then
        return
    end
    visited[value] = true

    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, SortKeys)

    local parentKey = path[#path]
    local roles = (parentKey == "position" or parentKey == "location") and GetPositionRoles(value)

    local tables = {}

    for _, key in ipairs(keys) do
        local child = value[key]
        local childPath = CopyTable(path)
        childPath[#childPath + 1] = key

        local valueType = type(child)
        if valueType == "boolean" or valueType == "number" or valueType == "string" then
            entries[#entries + 1] = {path = childPath, key = key, kind = valueType, role = roles and roles[key], default = child}
        elseif IsColor(key, child) then
            entries[#entries + 1] = {path = childPath, key = key, kind = "color", default = GetColorValues(child)}
        elseif valueType == "table" and not IsFrame(child) then
            tables[#tables + 1] = key
        end
    end

        -- Sub tables after the plain values of a section.

    for _, key in ipairs(tables) do
        local childPath = CopyTable(path)
        childPath[#childPath + 1] = key
        CollectEntries(entries, value[key], childPath, depth + 1, visited)
    end
end

function NeavOptions_Register(name, config)
    if type(config) ~= "table" or registry[name] then
        return
    end

    NeavOptionsDB = NeavOptionsDB or {}

        -- The entries keep the default values, so they are collected first.

    local entries = {}
    CollectEntries(entries, config, {}, 1, {})

    local saved = NeavOptionsDB[name]
    if saved then
        for pathString, value in pairs(saved) do
            ApplyOverride(config, StringToPath(pathString), value)
        end
    end

    registry[#registry + 1] = name
    registry[name] = {config = config, entries = entries}
end

    -- Labels, descriptions and control types

local function Humanize(key)
    local text = tostring(key):gsub("(%l)(%u)", "%1 %2"):gsub("_", " ")
    return text:sub(1, 1):upper()..text:sub(2)
end

local function GetLabel(entry)
    local key = entry.key
    local parentKey = entry.path[#entry.path - 1]

    if entry.role then
        return L[entry.role]
    elseif type(key) == "number" then
        if parentKey == "ignoreList" then
            return L.spellID:format(key)
        end
        return tostring(key)
    elseif parentKey == "showPowerType" then
        return _G[key] or key
    end

    return L.labels[key] or Humanize(key)
end

local function GetSectionTitle(path)
    local parts = {}
    for i = 1, #path - 1 do
        local key = path[i]
        if key ~= "units" then
            parts[#parts + 1] = L.sections[key] or Humanize(key)
        end
    end
    return table.concat(parts, " › ")
end

local function IsTag(key)
    key = tostring(key)
    return key:find("Tag") or key:find("Format")
end

local function GetDescription(entry)
    local key = entry.key

    if L.descriptions[key] then
        return L.descriptions[key]
    elseif entry.kind == "string" and IsTag(key) then
        return L.tagHelp
    elseif TEXTURE_KEYS[key] then
        return L.texture
    end
end

local function GetSliderRange(key)
    key = tostring(key)
    local lower = key:lower()

    if lower:find("scale") then
        return 0.5, 2, 0.05
    elseif lower:find("alpha") then
        return 0, 1, 0.05
    elseif key == "auraSize" then
        return 10, 50, 1
    elseif key == "numBuffs" or key == "numDebuffs" then
        return 0, 40, 1
    elseif key == "width" or key == "sizeWidth" then
        return 50, 500, 1
    elseif key == "height" then
        return 5, 60, 1
    elseif lower:find("size$") then
        return 6, 40, 1
    end
end

local function IsFontPath(value)
    return type(value) == "string" and value:lower():find("%.ttf$")
end

local function GetChoices(entry)
    local key = entry.key
    local parentKey = entry.path[#entry.path - 1]

    if entry.role == "anchor" or entry.role == "relativeAnchor" then
        return ANCHOR_POINTS
    elseif key == "textPos" then
        return {"TOP", "CENTER", "BOTTOM"}
    elseif key == "position" and parentKey == "icon" then
        return {"LEFT", "RIGHT"}
    elseif key == "style" then
        return {"NORMAL", "RARE", "ELITE", "CUSTOM"}
    end
end

local function FormatValue(entry, value)
    if entry.kind == "boolean" then
        return value and L.on or L.off
    elseif entry.kind == "color" then
        return ("%.2f, %.2f, %.2f"):format(value[1], value[2], value[3])
    elseif entry.kind == "string" and value == "" then
        return "\"\""
    end
    return tostring(value)
end

    -- Saved values

local function GetCurrentValue(name, entry)
    local saved = NeavOptionsDB[name]
    local value = saved and saved[PathToString(entry.path)]

    if value ~= nil then
        return value
    end

    return entry.default
end

local function IsDefault(entry, value)
    if entry.kind == "color" then
        for i = 1, 3 do
            if math.abs(value[i] - entry.default[i]) > 0.001 then
                return false
            end
        end
        return true
    end
    return value == entry.default
end

local function SaveValue(name, entry, value)
    local pathString = PathToString(entry.path)

    if IsDefault(entry, value) then
        if NeavOptionsDB[name] then
            NeavOptionsDB[name][pathString] = nil
            if not next(NeavOptionsDB[name]) then
                NeavOptionsDB[name] = nil
            end
        end
        return
    end

    NeavOptionsDB[name] = NeavOptionsDB[name] or {}
    NeavOptionsDB[name][pathString] = value
end

    -- Controls

local function ShowTooltip(owner, entry)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(GetLabel(entry), 1, 1, 1)

    local description = GetDescription(entry)
    if description then
        GameTooltip:AddLine(description, nil, nil, nil, true)
    end

    GameTooltip:AddLine(L.default:format(FormatValue(entry, entry.default)), 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
end

local function AddTooltip(frame, entry)
    frame:HookScript("OnEnter", function(self)
        ShowTooltip(self, entry)
    end)
    frame:HookScript("OnLeave", GameTooltip_Hide)
end

local function CreateCheckBox(parent, name, entry)
    local checkBox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkBox:SetSize(26, 26)
    checkBox:SetChecked(GetCurrentValue(name, entry))
    checkBox:SetScript("OnClick", function(self)
        SaveValue(name, entry, self:GetChecked() and true or false)
    end)
    return checkBox
end

local function CreateSlider(parent, name, entry, minValue, maxValue, step)
    local value = GetCurrentValue(name, entry)
    minValue = math.min(minValue, value)
    maxValue = math.max(maxValue, value)

    local slider = CreateFrame("Slider", nil, parent, "UISliderTemplateWithLabels")
    slider:SetWidth(170)
    slider.Low:Hide()
    slider.High:Hide()
    slider.Text:Hide()

    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)

    local format = step < 1 and "%.2f" or "%d"

    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(value)
    valueText:SetFormattedText(format, value)

    slider:SetScript("OnValueChanged", function(self, newValue, userInput)
        newValue = math.floor(newValue / step + 0.5) * step
        valueText:SetFormattedText(format, newValue)

        if userInput then
            SaveValue(name, entry, newValue)
        end
    end)

    return slider
end

local function CreateDropdown(parent, name, entry, choices)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(180)

    local function IsSelected(value)
        return GetCurrentValue(name, entry) == value
    end

    local function SetSelected(value)
        SaveValue(name, entry, value)
    end

    dropdown:SetupMenu(function(_, rootDescription)
        for _, choice in ipairs(choices) do
            local value, text = choice, choice
            if type(choice) == "table" then
                value, text = choice[1], choice[2]
            end
            rootDescription:CreateRadio(text, IsSelected, SetSelected, value)
        end
    end)

    return dropdown
end

local function GetFontChoices(entry)
    local choices = {}
    local hasDefault = false

    for _, font in ipairs(FONTS) do
        choices[#choices + 1] = font
        if font[1]:lower() == entry.default:lower() then
            hasDefault = true
        end
    end

    if not hasDefault then
        local file = entry.default:match("([^\\/]+)$") or entry.default
        table.insert(choices, 1, {entry.default, L.customFont:format(file)})
    end

    return choices
end

local function CreateInput(parent, name, entry)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetSize(entry.kind == "number" and 80 or 220, 20)
    input:SetText(tostring(GetCurrentValue(name, entry)))
    input:SetCursorPosition(0)

    local function Commit(self)
        local text = self:GetText()
        local value = text

        if entry.kind == "number" then
            value = tonumber(text)
        end

        if value == nil then
            self:SetText(tostring(GetCurrentValue(name, entry)))
        else
            SaveValue(name, entry, value)
        end

        self:SetCursorPosition(0)
    end

    input:SetScript("OnEnterPressed", function(self)
        Commit(self)
        self:ClearFocus()
    end)
    input:SetScript("OnEditFocusLost", Commit)
    input:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(GetCurrentValue(name, entry)))
        self:ClearFocus()
    end)

    return input
end

local function CreateColorSwatch(parent, name, entry)
    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(22, 22)

    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.8, 0.8, 0.8)

    local color = swatch:CreateTexture(nil, "ARTWORK")
    color:SetAllPoints()

    local function SetSwatchColor(r, g, b)
        color:SetColorTexture(r, g, b)
    end

    local value = GetCurrentValue(name, entry)
    SetSwatchColor(value[1], value[2], value[3])

    swatch:SetScript("OnClick", function()
        local current = GetCurrentValue(name, entry)
        local hasAlpha = entry.default[4] ~= nil

        local function Save(r, g, b, a)
            SaveValue(name, entry, {r, g, b, hasAlpha and a or nil})
            SetSwatchColor(r, g, b)
        end

        local function OnChanged()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            Save(r, g, b, ColorPickerFrame:GetColorAlpha())
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = current[1],
            g = current[2],
            b = current[3],
            opacity = current[4],
            hasOpacity = hasAlpha,
            swatchFunc = OnChanged,
            opacityFunc = OnChanged,
            cancelFunc = function()
                Save(ColorPickerFrame:GetPreviousValues())
            end,
        })
    end)

    return swatch
end

local function CreateControl(parent, name, entry)
    if entry.kind == "boolean" then
        return CreateCheckBox(parent, name, entry), 28
    elseif entry.kind == "color" then
        return CreateColorSwatch(parent, name, entry), 28
    elseif entry.kind == "number" then
        local minValue, maxValue, step = GetSliderRange(entry.key)
        if minValue and not entry.role then
            return CreateSlider(parent, name, entry, minValue, maxValue, step), 34
        end
    elseif entry.kind == "string" then
        local choices = GetChoices(entry)
        if not choices and IsFontPath(entry.default) then
            choices = GetFontChoices(entry)
        end
        if choices then
            return CreateDropdown(parent, name, entry, choices), 34
        end
    end

    return CreateInput(parent, name, entry), 28
end

    -- Pages

local LABEL_X = 24
local CONTROL_X = 300
local PAGE_WIDTH = 600

local function BuildPage(page, name)
    local title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(name)

    local note = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    note:SetText(L.pending)

    local reload = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    reload:SetSize(130, 22)
    reload:SetPoint("TOPRIGHT", -16, -14)
    reload:SetText(L.reload)
    reload:SetScript("OnClick", ReloadUI)

    local defaults = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    defaults:SetSize(130, 22)
    defaults:SetPoint("RIGHT", reload, "LEFT", -6, 0)
    defaults:SetText(L.defaults)
    defaults:SetScript("OnClick", function()
        NeavOptionsDB[name] = nil
        ReloadUI()
    end)

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -64)
    scroll:SetPoint("BOTTOMRIGHT", -30, 8)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(PAGE_WIDTH, 1)
    scroll:SetScrollChild(content)

    local y = -4
    local lastSection

    for _, entry in ipairs(registry[name].entries) do
        local section = GetSectionTitle(entry.path)

        if section ~= lastSection then
            lastSection = section

            if section ~= "" then
                y = y - 10

                local header = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                header:SetPoint("TOPLEFT", 8, y)
                header:SetText(section)

                local line = content:CreateTexture(nil, "ARTWORK")
                line:SetColorTexture(1, 0.82, 0, 0.25)
                line:SetHeight(1)
                line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
                line:SetWidth(PAGE_WIDTH - 16)

                y = y - 22
            end
        end

        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetSize(PAGE_WIDTH, 26)
        row:EnableMouse(true)
        AddTooltip(row, entry)

        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", LABEL_X, 0)
        label:SetWidth(CONTROL_X - LABEL_X - 10)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        label:SetText(GetLabel(entry))

        local control, height = CreateControl(row, name, entry)
        control:SetPoint("LEFT", row, "LEFT", CONTROL_X, 0)
        AddTooltip(control, entry)

        row:SetHeight(height)
        y = y - height
    end

    content:SetHeight(math.max(1, -y + 8))
end

local function CreatePage(name)
    local page = CreateFrame("Frame")
    page:Hide()

    page:SetScript("OnShow", function(self)
        if not self.built then
            self.built = true
            BuildPage(self, name)
        end
    end)

    return page
end

local function CreateMainPage()
    local page = CreateFrame("Frame")
    page:Hide()

    local title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.title)

    local description = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetPoint("RIGHT", -16, 0)
    description:SetJustifyH("LEFT")
    description:SetText(L.description.."\n\n/nui")

    return page
end

    -- The NeavUI category exists from the start, so other addons can add their own
    -- pages to it with NeavOptions_AddCategory while they load.

local category = Settings.RegisterCanvasLayoutCategory(CreateMainPage(), L.title)
Settings.RegisterAddOnCategory(category)

function NeavOptions_AddCategory(frame, name)
    return Settings.RegisterCanvasLayoutSubcategory(category, frame, name)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    NeavOptionsDB = NeavOptionsDB or {}

    for _, name in ipairs(registry) do
        Settings.RegisterCanvasLayoutSubcategory(category, CreatePage(name), name)
    end
end)

SlashCmdList["NEAVOPTIONS"] = function()
    Settings.OpenToCategory(category:GetID())
end
SLASH_NEAVOPTIONS1 = "/neavoptions"
SLASH_NEAVOPTIONS2 = "/nui"
