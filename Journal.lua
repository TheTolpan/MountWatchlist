local _, MW = ...

local journalButton
local hooksInstalled = false

function MW:UpdateJournalButton()
    if not journalButton or not MountJournal then
        return
    end

    if MountWatchlistDB.showJournalButton == false then
        journalButton:Hide()
        return
    end

    local mountID = MountJournal.selectedMountID
    if not mountID then
        journalButton.mountID = nil
        journalButton:Hide()
        return
    end

    local mount = self:GetMount(mountID)
    if not mount then
        journalButton.mountID = nil
        journalButton:Hide()
        return
    end

    journalButton.mountID = mountID
    journalButton:Show()

    if mount.isCollected then
        journalButton:SetText("Collected")
        journalButton:Disable()
    elseif self:IsTracked(mountID) then
        journalButton:SetText("Remove Watch")
        journalButton:Enable()
    else
        journalButton:SetText("+ Watch Mount")
        journalButton:Enable()
    end
end

function MW:SetupJournalIntegration()
    if journalButton then
        self:UpdateJournalButton()
        return
    end

    if not MountJournal or not MountJournal.MountDisplay then
        return
    end

    journalButton = CreateFrame(
        "Button",
        "MountWatchlistJournalButton",
        MountJournal.MountDisplay,
        "UIPanelButtonTemplate"
    )

    journalButton:SetSize(130, 24)
    journalButton:SetPoint("BOTTOMRIGHT", MountJournal.MountDisplay, "BOTTOMRIGHT", -12, 12)
    journalButton:SetFrameLevel(MountJournal.MountDisplay:GetFrameLevel() + 50)

    journalButton:SetScript("OnClick", function(self)
        if not self.mountID then
            return
        end

        MW:ToggleTracked(self.mountID)
        MW:UpdateJournalButton()
    end)

    journalButton:SetScript("OnEnter", function(self)
        if not self.mountID then
            return
        end

        local mount = MW:GetMount(self.mountID)
        if not mount then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if mount.isCollected then
            GameTooltip:SetText("Mount Watchlist")
            GameTooltip:AddLine("You already collected this mount.", 1, 1, 1, true)
        elseif MW:IsTracked(self.mountID) then
            GameTooltip:SetText("Remove from Mount Watchlist")
            GameTooltip:AddLine(mount.sourceText, 1, 1, 1, true)
        else
            GameTooltip:SetText("Add to Mount Watchlist")
            GameTooltip:AddLine(mount.sourceText, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)

    journalButton:SetScript("OnLeave", GameTooltip_Hide)

    if not hooksInstalled then
        hooksInstalled = true

        if MountJournal_SetSelected then
            hooksecurefunc("MountJournal_SetSelected", function()
                MW:UpdateJournalButton()
            end)
        end

        if MountJournal_UpdateMountDisplay then
            hooksecurefunc("MountJournal_UpdateMountDisplay", function()
                MW:UpdateJournalButton()
            end)
        end

        MountJournal:HookScript("OnShow", function()
            MW:UpdateJournalButton()
        end)
    end

    self:UpdateJournalButton()
end
