local _, MW = ...

local ROW_HEIGHT = 50
local FRAME_WIDTH = 900
local FRAME_HEIGHT = 760
local LEFT_X = 16
local RIGHT_X = 464
local COLUMN_WIDTH = 420
local DETAILS_HEIGHT = 188
local DETAILS_BOTTOM = 16
local LIST_TOP = -108
local LIST_BOTTOM = DETAILS_BOTTOM + DETAILS_HEIGHT + 16

local frame
local selectedMountID

local FILTERS = {
    { label = "All", sourceType = nil, width = 52 },
    { label = "Drop", sourceType = 1, width = 58 },
    { label = "Vendor", sourceType = 3, width = 66 },
    { label = "Achievement", sourceType = 6, width = 92 },
    { label = "Quest", sourceType = 2, width = 60 },
    { label = "Profession", sourceType = 4, width = 82 },
}

local function CreateBackdrop(f)
    if not f.SetBackdrop then
        Mixin(f, BackdropTemplateMixin)
    end

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
end

local function UpdateFilterButtons()
    if not frame or not frame.filterButtons then
        return
    end

    for _, button in ipairs(frame.filterButtons) do
        local selected = frame.activeSourceFilter == button.sourceType

        if selected then
            button:SetButtonState("PUSHED", true)
            button:LockHighlight()
        else
            button:SetButtonState("NORMAL", false)
            button:UnlockHighlight()
        end
    end
end

local function InitializeRow(row, trackedMode, width)
    if row._mountWatchlistInitialized then
        return
    end

    row._mountWatchlistInitialized = true
    row.trackedMode = trackedMode
    row:SetSize(width, ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0.04, 0.04, 0.04, 0.55)

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(1, 1, 1, 0.06)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(36, 36)
    row.icon:SetPoint("LEFT", 5, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -2)
    row.name:SetPoint("RIGHT", -72, 0)
    row.name:SetJustifyH("LEFT")

    row.category = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.category:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.category:SetJustifyH("LEFT")

    row.source = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.source:SetPoint("TOPLEFT", row.category, "BOTTOMLEFT", 0, -1)
    row.source:SetPoint("RIGHT", -72, 0)
    row.source:SetJustifyH("LEFT")

    -- Important: rows have a fixed height, so source text must never wrap
    row.source:SetWordWrap(false)
    row.source:SetNonSpaceWrap(false)
    row.source:SetMaxLines(1)
    row.source:SetHeight(12)

    row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.action:SetSize(62, 24)
    row.action:SetPoint("RIGHT", -4, 0)

    row:SetScript("OnEnter", function(self)
        if not self.mountID then
            return
        end

        local mount = MW:GetMount(self.mountID)
        if not mount then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(mount.name)
        GameTooltip:AddLine(mount.sourceCategory, 0.9, 0.75, 0.2)
        GameTooltip:AddLine(mount.sourceText, 1, 1, 1, true)
        if mount.description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(mount.description, 0.75, 0.75, 0.75, true)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Ctrl + Left Click: Preview in Dressing Room", 0.35, 0.8, 1, true)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    row:SetScript("OnClick", function(self, mouseButton)
        if not self.mountID then
            return
        end

        if mouseButton == "LeftButton" and IsControlKeyDown() then
            MW:PreviewMount(self.mountID)
            return
        end

        if mouseButton == "LeftButton" then
            selectedMountID = self.mountID
            MW:ShowDetails(self.mountID)
        end
    end)

    row.action:SetScript("OnClick", function(self)
        local owner = self:GetParent()
        if not owner.mountID then
            return
        end

        if owner.trackedMode then
            MW:SetTracked(owner.mountID, false)
        else
            MW:SetTracked(owner.mountID, true)
        end
    end)
end

local function SetRowData(row, mount, trackedMode, width)
    InitializeRow(row, trackedMode, width)

    row.mountID = mount.id
    row.trackedMode = trackedMode
    row.icon:SetTexture(mount.icon)
    row.name:SetText(mount.name)

    if mount.isCollected then
        row.category:SetText("|cff44ff44Collected|r")
    else
        row.category:SetText("|cffaaaaaa" .. mount.sourceCategory .. "|r")
    end

    local source = mount.sourceText or ""

    -- Collapse Blizzard's multiline source information into one compact list line.
    source = source:gsub("|n", " ")
    source = source:gsub("\r", " ")
    source = source:gsub("\n", " ")
    source = source:gsub("%s+", " ")
    source = source:gsub("^%s+", "")
    source = source:gsub("%s+$", "")

    if #source > 62 then
        source = source:sub(1, 59) .. "..."
    end

    row.source:SetText(source)

    if trackedMode then
        row.action:SetText("Remove")
        row.action:Enable()
    elseif MW:IsTracked(mount.id) then
        row.action:SetText("Tracked")
        row.action:Disable()
    else
        row.action:SetText("Add")
        row.action:Enable()
    end
end

local function CreateList(parent, title, x, width, trackedMode)
    local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", x, -48)
    heading:SetText(title)

    local count = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    count:SetPoint("LEFT", heading, "RIGHT", 8, 0)

    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, LIST_TOP)
    scrollBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", x + width - 16, LIST_BOTTOM)

    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 5, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 5, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ROW_HEIGHT)
    view:SetPadding(0, 0, 0, 0, 0)

    view:SetElementInitializer("Button", function(row, mount)
        SetRowData(row, mount, trackedMode, width - 16)
    end)

    view:SetElementResetter(function(row)
        row.mountID = nil
        if GameTooltip:GetOwner() == row then
            GameTooltip:Hide()
        end
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    if scrollBar.SetHideIfUnscrollable then
        scrollBar:SetHideIfUnscrollable(true)
    end

    return {
        scrollBox = scrollBox,
        scrollBar = scrollBar,
        view = view,
        count = count,
    }
end

local function SetListData(list, data)
    local provider = CreateDataProvider()
    provider:InsertTable(data)
    list.scrollBox:SetDataProvider(provider, ScrollBoxConstants.RetainScrollPosition)
end

local function UpdateDetailsContentHeight()
    if not frame or not frame.detailsTextScroll or not frame.detailsContent then
        return
    end

    local viewportWidth = math.max(100, frame.detailsTextScroll:GetWidth() - 28)
    frame.detailsContent:SetWidth(viewportWidth)
    frame.detailsSource:SetWidth(viewportWidth)
    frame.detailsDescription:SetWidth(viewportWidth)

    local sourceHeight = math.max(14, frame.detailsSource:GetStringHeight())
    local descriptionHeight = math.max(0, frame.detailsDescription:GetStringHeight())
    local spacing = descriptionHeight > 0 and 12 or 0
    local contentHeight = sourceHeight + descriptionHeight + spacing + 4

    frame.detailsContent:SetHeight(math.max(frame.detailsTextScroll:GetHeight(), contentHeight))
end

function MW:ShowDetails(mountID)
    if not frame then
        return
    end

    local mount = self:GetMount(mountID)
    if not mount then
        return
    end

    frame.detailsIcon:SetTexture(mount.icon)
    frame.detailsName:SetText(mount.name)
    frame.detailsCategory:SetText(mount.sourceCategory)
    frame.detailsSource:SetText(mount.sourceText)

    if mount.description ~= "" then
        frame.detailsDescription:SetText(mount.description)
        frame.detailsDescription:Show()
    else
        frame.detailsDescription:SetText("")
        frame.detailsDescription:Hide()
    end

    frame.detailsAction.mountID = mount.id

    if self:IsTracked(mount.id) then
        frame.detailsAction:SetText("Remove from watchlist")
        frame.detailsAction:Enable()
    elseif mount.isCollected then
        frame.detailsAction:SetText("Already collected")
        frame.detailsAction:Disable()
    else
        frame.detailsAction:SetText("Add to watchlist")
        frame.detailsAction:Enable()
    end

    frame.detailsTextScroll:SetVerticalScroll(0)
    C_Timer.After(0, UpdateDetailsContentHeight)
end

function MW:Refresh()
    if not frame or not frame:IsShown() then
        return
    end

    local search = frame.searchBox:GetText() or ""
    local availableData = self:GetAllUncollected(search, frame.activeSourceFilter)
    local trackedData = self:GetTracked()

    frame.availableList.count:SetText("(" .. #availableData .. ")")
    frame.trackedList.count:SetText("(" .. #trackedData .. ")")

    SetListData(frame.availableList, availableData)
    SetListData(frame.trackedList, trackedData)

    if frame.removeCollectedCheckbox then
        frame.removeCollectedCheckbox:SetChecked(
            MountWatchlistDB.removeCollected == true
        )
    end

    if selectedMountID then
        self:ShowDetails(selectedMountID)
    elseif trackedData[1] then
        selectedMountID = trackedData[1].id
        self:ShowDetails(selectedMountID)
    elseif availableData[1] then
        selectedMountID = availableData[1].id
        self:ShowDetails(selectedMountID)
    end
end

function MW:InitializeUI()
    if frame then
        return
    end

    frame = CreateFrame("Frame", "MountWatchlistFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    CreateBackdrop(frame)
    frame:SetBackdropBorderColor(0.55, 0.45, 0.2, 1)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText("Mount Watchlist")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    frame.searchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    frame.searchBox:SetSize(300, 28)
    frame.searchBox:SetPoint("TOPRIGHT", -42, -12)
    frame.searchBox:SetAutoFocus(false)
    frame.searchBox:SetScript("OnTextChanged", function()
        if frame:IsShown() then
            MW:Refresh()
        end
    end)

    -- Detail pane is created first so the list and detail regions have a single,
    -- non-overlapping layout.
    local details = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    details:SetPoint("BOTTOMLEFT", DETAILS_BOTTOM, DETAILS_BOTTOM)
    details:SetPoint("BOTTOMRIGHT", -DETAILS_BOTTOM, DETAILS_BOTTOM)
    details:SetHeight(DETAILS_HEIGHT)
    CreateBackdrop(details)

    frame.detailsIcon = details:CreateTexture(nil, "ARTWORK")
    frame.detailsIcon:SetSize(48, 48)
    frame.detailsIcon:SetPoint("TOPLEFT", 10, -10)

    frame.detailsName = details:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.detailsName:SetPoint("TOPLEFT", frame.detailsIcon, "TOPRIGHT", 10, 0)
    frame.detailsName:SetPoint("RIGHT", -185, 0)
    frame.detailsName:SetJustifyH("LEFT")

    frame.detailsCategory = details:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.detailsCategory:SetPoint("TOPLEFT", frame.detailsName, "BOTTOMLEFT", 0, -4)

    frame.detailsAction = CreateFrame("Button", nil, details, "UIPanelButtonTemplate")
    frame.detailsAction:SetSize(165, 30)
    frame.detailsAction:SetPoint("TOPRIGHT", -10, -16)
    frame.detailsAction:SetScript("OnClick", function(self)
        if not self.mountID then
            return
        end

        MW:ToggleTracked(self.mountID)
        MW:ShowDetails(self.mountID)
    end)

    local removeCollected = CreateFrame("CheckButton", nil, details, "UICheckButtonTemplate")
    frame.removeCollectedCheckbox = removeCollected
    removeCollected:SetPoint("TOPRIGHT", frame.detailsAction, "BOTTOMRIGHT", 0, -10)
    removeCollected:SetChecked(MountWatchlistDB.removeCollected)
    removeCollected.text = removeCollected:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    removeCollected.text:SetPoint("RIGHT", removeCollected, "LEFT", -3, 0)
    removeCollected.text:SetText("Remove when collected")
    removeCollected:SetScript("OnClick", function(self)
        MountWatchlistDB.removeCollected = self:GetChecked() == true
        MW:CleanupCollected()
        MW:Refresh()
    end)

    local previewHint = details:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    previewHint:SetPoint("TOPRIGHT", removeCollected, "BOTTOMRIGHT", 0, -13)
    previewHint:SetText("Ctrl-click a mount to preview")

    frame.detailsTextScroll = CreateFrame("ScrollFrame", nil, details, "UIPanelScrollFrameTemplate")
    frame.detailsTextScroll:SetPoint("TOPLEFT", details, "TOPLEFT", 10, -68)
    frame.detailsTextScroll:SetPoint("BOTTOMRIGHT", details, "BOTTOMRIGHT", -190, 10)

    frame.detailsContent = CreateFrame("Frame", nil, frame.detailsTextScroll)
    frame.detailsContent:SetSize(620, 100)
    frame.detailsTextScroll:SetScrollChild(frame.detailsContent)

    frame.detailsSource = frame.detailsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.detailsSource:SetPoint("TOPLEFT", 0, 0)
    frame.detailsSource:SetJustifyH("LEFT")
    frame.detailsSource:SetJustifyV("TOP")
    frame.detailsSource:SetWordWrap(true)

    frame.detailsDescription = frame.detailsContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.detailsDescription:SetPoint("TOPLEFT", frame.detailsSource, "BOTTOMLEFT", 0, -12)
    frame.detailsDescription:SetJustifyH("LEFT")
    frame.detailsDescription:SetJustifyV("TOP")
    frame.detailsDescription:SetWordWrap(true)

    frame.detailsTextScroll:HookScript("OnSizeChanged", function()
        C_Timer.After(0, UpdateDetailsContentHeight)
    end)

    frame.filterButtons = {}
    frame.activeSourceFilter = nil

    local filterX = LEFT_X
    for _, filter in ipairs(FILTERS) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(filter.width, 22)
        button:SetPoint("TOPLEFT", filterX, -76)
        button:SetText(filter.label)
        button.sourceType = filter.sourceType

        button:SetScript("OnClick", function(self)
            frame.activeSourceFilter = self.sourceType
            UpdateFilterButtons()
            MW:Refresh()
        end)

        frame.filterButtons[#frame.filterButtons + 1] = button
        filterX = filterX + filter.width + 4
    end
    UpdateFilterButtons()

    frame.availableList = CreateList(frame, "Uncollected mounts", LEFT_X, COLUMN_WIDTH, false)
    frame.trackedList = CreateList(frame, "My watchlist", RIGHT_X, COLUMN_WIDTH, true)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.35, 0.35, 0.35, 0.7)
    divider:SetWidth(1)
    divider:SetPoint("TOP", frame, "TOP", 0, -48)
    divider:SetPoint("BOTTOM", details, "TOP", 0, 12)

    frame:SetScript("OnShow", function()
        MW:Refresh()
    end)
end

function MW:Toggle()
    if not frame then
        self:InitializeUI()
    end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
