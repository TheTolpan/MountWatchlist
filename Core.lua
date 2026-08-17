local ADDON_NAME, MW = ...

MountWatchlist = MW
MW.version = "0.3.0"

local SOURCE_TYPES = {
    [0] = "Other",
    [1] = "Drop",
    [2] = "Quest",
    [3] = "Vendor",
    [4] = "Profession",
    [5] = "Pet Battle",
    [6] = "Achievement",
    [7] = "World Event",
    [8] = "Promotion",
    [9] = "Trading Card Game",
    [10] = "Black Market",
    [11] = "Shop",
    [12] = "Discovery",
}

MW.SOURCE_TYPES = SOURCE_TYPES

local eventFrame = CreateFrame("Frame")
MW.eventFrame = eventFrame

local function EnsureDB()
    if type(MountWatchlistDB) ~= "table" then
        MountWatchlistDB = {}
    end

    if type(MountWatchlistDB.tracked) ~= "table" then
        MountWatchlistDB.tracked = {}
    end

    if MountWatchlistDB.removeCollected == nil then
        MountWatchlistDB.removeCollected = true
    end
end

function MW:GetMount(mountID)
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
        isFactionSpecific, faction, shouldHideOnChar, isCollected, returnedMountID,
        isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)

    if not name then
        return nil
    end

    local _, description, sourceText = C_MountJournal.GetMountInfoExtraByID(mountID)

    return {
        id = mountID,
        name = name,
        spellID = spellID,
        icon = icon,
        sourceType = sourceType or 0,
        sourceCategory = SOURCE_TYPES[sourceType or 0] or ("Source " .. tostring(sourceType or "?")),
        description = description or "",
        sourceText = sourceText or "No acquisition information is available in the Mount Journal.",
        isCollected = isCollected == true,
        shouldHideOnChar = shouldHideOnChar == true,
        isFactionSpecific = isFactionSpecific == true,
        faction = faction,
    }
end

function MW:GetAllUncollected(search, sourceFilter)
    local result = {}
    local needle = search and search:lower() or ""

    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local mount = self:GetMount(mountID)
        if mount
            and not mount.isCollected
            and not mount.shouldHideOnChar
            and (sourceFilter == nil or mount.sourceType == sourceFilter)
        then
            local matches = needle == ""
                or mount.name:lower():find(needle, 1, true)
                or mount.sourceCategory:lower():find(needle, 1, true)
                or mount.sourceText:lower():find(needle, 1, true)

            if matches then
                result[#result + 1] = mount
            end
        end
    end

    table.sort(result, function(a, b)
        return a.name < b.name
    end)

    return result
end

function MW:GetTracked()
    local result = {}
    local stale = {}

    for mountID, enabled in pairs(MountWatchlistDB.tracked) do
        if enabled then
            local numericID = tonumber(mountID)
            local mount = numericID and self:GetMount(numericID) or nil

            if not mount then
                stale[#stale + 1] = mountID
            elseif mount.isCollected and MountWatchlistDB.removeCollected then
                stale[#stale + 1] = mountID
            else
                result[#result + 1] = mount
            end
        end
    end

    for _, mountID in ipairs(stale) do
        MountWatchlistDB.tracked[mountID] = nil
    end

    table.sort(result, function(a, b)
        if a.isCollected ~= b.isCollected then
            return not a.isCollected
        end
        return a.name < b.name
    end)

    return result
end

function MW:IsTracked(mountID)
    return MountWatchlistDB.tracked[mountID] == true
        or MountWatchlistDB.tracked[tostring(mountID)] == true
end

function MW:SetTracked(mountID, tracked)
    if tracked then
        local mount = self:GetMount(mountID)
        if not mount or mount.isCollected then
            return
        end
        MountWatchlistDB.tracked[mountID] = true
    else
        MountWatchlistDB.tracked[mountID] = nil
        MountWatchlistDB.tracked[tostring(mountID)] = nil
    end

    if self.Refresh then
        self:Refresh()
    end

    if self.UpdateJournalButton then
        self:UpdateJournalButton()
    end
end

function MW:ToggleTracked(mountID)
    self:SetTracked(mountID, not self:IsTracked(mountID))
end

function MW:PreviewMount(mountID)
    if not mountID then
        return
    end

    -- Blizzard's standard mount dressing-room function.
    if DressUpMount then
        DressUpMount(mountID)
    end
end

function MW:CleanupCollected()
    if not MountWatchlistDB.removeCollected then
        return
    end

    local changed = false
    for mountID, enabled in pairs(MountWatchlistDB.tracked) do
        if enabled then
            local mount = self:GetMount(tonumber(mountID))
            if mount and mount.isCollected then
                MountWatchlistDB.tracked[mountID] = nil
                changed = true
            end
        end
    end

    if changed and self.Refresh then
        self:Refresh()
    end

    if changed and self.UpdateJournalButton then
        self:UpdateJournalButton()
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("NEW_MOUNT_ADDED")
eventFrame:RegisterEvent("COMPANION_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            EnsureDB()
            MW:InitializeUI()

            if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
                MW:SetupJournalIntegration()
            end
        elseif arg1 == "Blizzard_Collections" then
            EnsureDB()
            MW:SetupJournalIntegration()
        end
    elseif event == "NEW_MOUNT_ADDED" or event == "COMPANION_UPDATE" then
        EnsureDB()
        MW:CleanupCollected()
    end
end)

SLASH_MOUNTWATCHLIST1 = "/mwl"
SLASH_MOUNTWATCHLIST2 = "/mountwatchlist"
SlashCmdList.MOUNTWATCHLIST = function()
    MW:Toggle()
end
