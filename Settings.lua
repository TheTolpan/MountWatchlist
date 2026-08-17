local ADDON_NAME, MW = ...

MW.settingsCategoryID = nil

function MW:OpenSettings()
    if self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
    end
end

function MW:InitializeSettings()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory("Mount Watchlist")
    self.settingsCategoryID = category:GetID()

    ----------------------------------------------------------------
    -- Remove collected mounts
    ----------------------------------------------------------------

    local removeCollectedSetting = Settings.RegisterAddOnSetting(
        category,
        "MountWatchlist_RemoveCollected",
        "removeCollected",
        MountWatchlistDB,
        Settings.VarType.Boolean,
        "Remove mounts when collected",
        true
    )

    Settings.CreateCheckbox(
        category,
        removeCollectedSetting,
        "Automatically remove mounts from your watchlist after they have been collected."
    )

    ----------------------------------------------------------------
    -- Minimap button
    ----------------------------------------------------------------

    local minimapSetting = Settings.RegisterAddOnSetting(
        category,
        "MountWatchlist_ShowMinimapButton",
        "showMinimapButton",
        MountWatchlistDB,
        Settings.VarType.Boolean,
        "Show minimap button",
        true
    )

    Settings.CreateCheckbox(
        category,
        minimapSetting,
        "Show the Mount Watchlist button around the minimap."
    )

    ----------------------------------------------------------------
    -- Mount Journal button
    ----------------------------------------------------------------

    local journalSetting = Settings.RegisterAddOnSetting(
        category,
        "MountWatchlist_ShowJournalButton",
        "showJournalButton",
        MountWatchlistDB,
        Settings.VarType.Boolean,
        "Show button in Mount Journal",
        true
    )

    Settings.CreateCheckbox(
        category,
        journalSetting,
        "Show the Watch Mount button in Warband Collections → Mounts."
    )

    ----------------------------------------------------------------
    -- React immediately when options change
    ----------------------------------------------------------------

    Settings.SetOnValueChangedCallback(
        "MountWatchlist_ShowMinimapButton",
        function(_, setting, value)
            if MW.UpdateMinimapButtonVisibility then
                MW:UpdateMinimapButtonVisibility()
            end
        end
    )

    Settings.SetOnValueChangedCallback(
        "MountWatchlist_ShowJournalButton",
        function(_, setting, value)
            if MW.UpdateJournalButton then
                MW:UpdateJournalButton()
            end
        end
    )

    Settings.SetOnValueChangedCallback(
        "MountWatchlist_RemoveCollected",
        function(_, setting, value)
            if value then
                MW:CleanupCollected()
            end

            if MW.Refresh then
                MW:Refresh()
            end
        end
    )

    Settings.RegisterAddOnCategory(category)
end