    -- In-game options for the config.lua tables of the NeavUI addons.
    --
    -- The addons call NeavOptions_Register(name, config) at the end of their config.lua.
    -- Changed values are saved in NeavOptionsDB and written into the config table at
    -- that point, before the rest of the addon reads it, so changes take effect after
    -- a reload. The option pages are generated from the config tables: booleans are
    -- check boxes, numbers and strings are input fields and colors are color swatches.

local L = {
    title = "NeavUI",
    description = "Options of the NeavUI addons. Changes take effect after a reload.",
    reload = "Reload UI",
    defaults = "Defaults",
    pending = "Changes take effect after a reload.",
}

if GetLocale() == "deDE" then
    L.description = "Optionen der NeavUI-Addons. Änderungen werden nach einem Neuladen aktiv."
    L.reload = "UI neu laden"
    L.defaults = "Standard"
    L.pending = "Änderungen werden nach einem Neuladen aktiv."
end

local registry = {}

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
        return value.r, value.g, value.b, value.a
    end
    return value[1], value[2], value[3], value[4]
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

local function CollectEntries(entries, value, path, depth, visited)
    if depth > 8 or visited[value] then
        return
    end
    visited[value] = true

    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return a < b
        end
        return type(a) == "number"
    end)

    for _, key in ipairs(keys) do
        local child = value[key]
        local childPath = CopyTable(path)
        childPath[#childPath + 1] = key

        local valueType = type(child)
        if valueType == "boolean" or valueType == "number" or valueType == "string" then
            entries[#entries + 1] = {path = childPath, kind = valueType}
        elseif IsColor(key, child) then
            entries[#entries + 1] = {path = childPath, kind = "color"}
        elseif valueType == "table" and not IsFrame(child) then
            CollectEntries(entries, child, childPath, depth + 1, visited)
        end
    end
end

function NeavOptions_Register(name, config)
    if type(config) ~= "table" or registry[name] then
        return
    end

    NeavOptionsDB = NeavOptionsDB or {}

    local saved = NeavOptionsDB[name]
    if saved then
        for pathString, value in pairs(saved) do
            ApplyOverride(config, StringToPath(pathString), value)
        end
    end

    local entries = {}
    CollectEntries(entries, config, {}, 1, {})

    registry[#registry + 1] = name
    registry[name] = {config = config, entries = entries}
end

    -- Option pages

local ROW_HEIGHT = 26
local LABEL_WIDTH = 330

local function GetCurrentValue(name, entry)
    local saved = NeavOptionsDB[name]
    local pathString = PathToString(entry.path)

    if saved and saved[pathString] ~= nil then
        return saved[pathString]
    end

    local parent, key = GetParentAndKey(registry[name].config, entry.path)
    local value = parent and parent[key]

    if entry.kind == "color" and type(value) == "table" then
        return {GetColorValues(value)}
    end

    return value
end

local function SaveValue(name, entry, value)
    NeavOptionsDB[name] = NeavOptionsDB[name] or {}
    NeavOptionsDB[name][PathToString(entry.path)] = value
end

local function CreateCheckBox(parent, name, entry)
    local checkBox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkBox:SetSize(24, 24)
    checkBox:SetChecked(GetCurrentValue(name, entry))
    checkBox:SetScript("OnClick", function(self)
        SaveValue(name, entry, self:GetChecked() and true or false)
    end)
    return checkBox
end

local function CreateInput(parent, name, entry)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetSize(180, 20)
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
    swatch:SetSize(20, 20)

    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.6, 0.6, 0.6)

    local color = swatch:CreateTexture(nil, "ARTWORK")
    color:SetAllPoints()

    local function SetSwatchColor(r, g, b)
        color:SetColorTexture(r, g, b)
    end

    local value = GetCurrentValue(name, entry)
    SetSwatchColor(value[1], value[2], value[3])

    swatch:SetScript("OnClick", function()
        local current = GetCurrentValue(name, entry)
        local hasAlpha = current[4] ~= nil

        local function Save(r, g, b, a)
            SaveValue(name, entry, {r, g, b, hasAlpha and a or nil})
            SetSwatchColor(r, g, b)
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = current[1],
            g = current[2],
            b = current[3],
            opacity = current[4],
            hasOpacity = hasAlpha,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                Save(r, g, b, ColorPickerFrame:GetColorAlpha())
            end,
            opacityFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                Save(r, g, b, ColorPickerFrame:GetColorAlpha())
            end,
            cancelFunc = function()
                local r, g, b, a = ColorPickerFrame:GetPreviousValues()
                Save(r, g, b, a)
            end,
        })
    end)

    return swatch
end

local function CreatePage(name)
    local page = CreateFrame("Frame")
    page.name = name
    page:Hide()

    page:SetScript("OnShow", function(self)
        if self.built then
            return
        end
        self.built = true

        local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(name)

        local note = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        note:SetText(L.pending)

        local reload = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        reload:SetSize(120, 22)
        reload:SetPoint("TOPRIGHT", -16, -14)
        reload:SetText(L.reload)
        reload:SetScript("OnClick", ReloadUI)

        local defaults = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        defaults:SetSize(120, 22)
        defaults:SetPoint("RIGHT", reload, "LEFT", -6, 0)
        defaults:SetText(L.defaults)
        defaults:SetScript("OnClick", function()
            NeavOptionsDB[name] = nil
            ReloadUI()
        end)

        local scroll = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -64)
        scroll:SetPoint("BOTTOMRIGHT", -30, 8)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(LABEL_WIDTH + 220, 1)
        scroll:SetScrollChild(content)

        local entries = registry[name].entries
        for index, entry in ipairs(entries) do
            local y = -(index - 1) * ROW_HEIGHT

            local label = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            label:SetPoint("TOPLEFT", 8, y - 6)
            label:SetWidth(LABEL_WIDTH)
            label:SetJustifyH("LEFT")
            label:SetWordWrap(false)
            label:SetText((PathToString(entry.path):gsub("#", "")))

            local control
            if entry.kind == "boolean" then
                control = CreateCheckBox(content, name, entry)
            elseif entry.kind == "color" then
                control = CreateColorSwatch(content, name, entry)
            else
                control = CreateInput(content, name, entry)
            end
            control:SetPoint("LEFT", content, "TOPLEFT", LABEL_WIDTH + 16, y - 12)
        end

        content:SetHeight(math.max(1, #entries * ROW_HEIGHT))
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
    description:SetText(L.description)

    return page
end

local category

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    NeavOptionsDB = NeavOptionsDB or {}

    category = Settings.RegisterCanvasLayoutCategory(CreateMainPage(), L.title)

    for _, name in ipairs(registry) do
        Settings.RegisterCanvasLayoutSubcategory(category, CreatePage(name), name)
    end

    Settings.RegisterAddOnCategory(category)
end)

SlashCmdList["NEAVOPTIONS"] = function()
    if category then
        Settings.OpenToCategory(category:GetID())
    end
end
SLASH_NEAVOPTIONS1 = "/neavoptions"
SLASH_NEAVOPTIONS2 = "/nui"
