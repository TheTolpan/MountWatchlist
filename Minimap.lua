local ADDON_NAME, MW = ...

local button

local MINIMAP_RADIUS = 80
local DEFAULT_ANGLE = 220

local function GetSavedAngle()
    return MountWatchlistDB.minimapAngle or DEFAULT_ANGLE
end

local function SetButtonPosition(angle)
    if not button then
        return
    end

    MountWatchlistDB.minimapAngle = angle

    local radians = math.rad(angle)

    local x = math.cos(radians) * MINIMAP_RADIUS
    local y = math.sin(radians) * MINIMAP_RADIUS

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdatePositionFromMouse()
    local minimapX, minimapY = Minimap:GetCenter()
    local mouseX, mouseY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    mouseX = mouseX / scale
    mouseY = mouseY / scale

    local angle = math.deg(
        math.atan2(mouseY - minimapY, mouseX - minimapX)
    )

    SetButtonPosition(angle)
end

function MW:UpdateMinimapButtonVisibility()
    if not button then
        return
    end

    if MountWatchlistDB.showMinimapButton then
        button:Show()
    else
        button:Hide()
    end
end

function MW:InitializeMinimapButton()
    if button then
        self:UpdateMinimapButtonVisibility()
        return
    end

    button = CreateFrame("Button", "MountWatchlistMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    ----------------------------------------------------------------
    -- Background
    ----------------------------------------------------------------

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(28, 28)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    ----------------------------------------------------------------
    -- Icon
    ----------------------------------------------------------------

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")

    -- Horse-themed Blizzard icon.
    -- If you later find a horseshoe texture you prefer, only this line changes.
    icon:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    ----------------------------------------------------------------
    -- Border
    ----------------------------------------------------------------

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    ----------------------------------------------------------------
    -- Highlight
    ----------------------------------------------------------------

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetSize(32, 32)
    highlight:SetPoint("CENTER")

    ----------------------------------------------------------------
    -- Click
    ----------------------------------------------------------------

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            MW:Toggle()

        elseif mouseButton == "RightButton" then
            MW:OpenSettings()
        end
    end)

    ----------------------------------------------------------------
    -- Tooltip
    ----------------------------------------------------------------

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")

        GameTooltip:SetText("Mount Watchlist")

        GameTooltip:AddLine(
            "Left Click: Open watchlist",
            1,
            1,
            1
        )

        GameTooltip:AddLine(
            "Right Click: Settings",
            1,
            1,
            1
        )

        GameTooltip:AddLine(
            "Drag: Move button",
            0.7,
            0.7,
            0.7
        )

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ----------------------------------------------------------------
    -- Dragging
    ----------------------------------------------------------------

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdatePositionFromMouse)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    SetButtonPosition(GetSavedAngle())

    self:UpdateMinimapButtonVisibility()
end

function MountWatchlist_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "LeftButton" then
        MW:Toggle()
    elseif buttonName == "RightButton" then
        MW:OpenSettings()
    end
end

function MountWatchlist_OnAddonCompartmentEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Mount Watchlist")
    GameTooltip:AddLine("Left Click: Open watchlist", 1, 1, 1)
    GameTooltip:AddLine("Right Click: Settings", 1, 1, 1)
    GameTooltip:Show()
end

function MountWatchlist_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end