

local addonName, SC = ...

SC.Panel = {}
SC.Panel.__index = SC.Panel

function SC.Panel.New(name, anchor, width, height, offsetX, offsetY, sockets, display, spec, orientation)
    local panel = {}
    local frame = CreateFrame('FRAME', string.format('%s_%s', 'SimpleCooldowns', name), UIParent)
    panel.Frame = frame
    panel.Name = name
    panel.Height = tonumber(height)
    if not panel.Height then
        panel.Height = 50
    end
    panel.Width = tonumber(width)
    if not panel.Width then
        panel.Width = 200
    end
    panel.Frame:SetPoint(anchor, offsetX, offsetY)
    panel.Frame:SetSize(width, height + 14)
    panel.Frame:EnableMouse(true)

    panel.Background = panel.Frame:CreateTexture("$parentBackground", 'BACKGROUND')
    panel.Background:SetAllPoints(panel.Frame)
    panel.Background:SetColorTexture(0,0,0,0.7)
    panel.Background:Hide()

    panel.Title = panel.Frame:CreateFontString("$parentTitle", 'OVERLAY', 'GameFontNormal')
    panel.Title:SetPoint('TOP', 0, 0)
    panel.Title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    panel.Title:SetTextColor(1,1,1,1)
    panel.Title:SetText('Click to drag & move')
    panel.Title:Hide()

    panel.Display = display
    panel.Sockets = {}
    panel.Specialization = spec
    panel.Orientation = orientation
    
    setmetatable(panel, SC.Panel)
    return panel
end

function SC.Panel:CreateSocket(iter, rangeOverlay, rangeOverlayRGBA, usableOverlay, usableOverlayRGBA)
    local panel = self
    local s = CreateFrame('FRAME', tostring(self.Name..'_Socket'..iter), self.Frame)
    s:EnableMouse(true)
    s:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
    })
    if self.Height > self.Width then
        s:SetSize(self.Width, self.Width)
    else
        s:SetSize(self.Height, self.Height)
    end
    s:SetPoint('BOTTOMLEFT', (iter-1)*self.Height, 0)

    s.Texture = s:CreateTexture("$parentTexture", 'ARTWORK')
    s.Texture:SetAllPoints(s)
    s.Texture:SetTexture(132048)

    s.UsableOverlayDisplay = usableOverlay
    s.UsableOverlay = s:CreateTexture("$parentUsableOverlay", "OVERLAY")
    s.UsableOverlay:SetPoint('TOPLEFT', 2, -2)
    s.UsableOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
    if not usableOverlayRGBA then
        usableOverlayRGBA = {r=0, g=0, b=0, a=0.8}
    end
    s.UsableOverlay:SetColorTexture(usableOverlayRGBA.r, usableOverlayRGBA.g, usableOverlayRGBA.b, usableOverlayRGBA.a)
    s.UsableOverlay:Hide()

    s.RangeOverlayDisplay = rangeOverlay
    s.RangeOverlay = s:CreateTexture("$parentRangeOverlay", "OVERLAY")
    s.RangeOverlay:SetPoint('TOPLEFT', 2, -2)
    s.RangeOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
    if not rangeOverlayRGBA then
        rangeOverlayRGBA = {r=1, g=0, b=0, a=0.6}
    end
    s.RangeOverlay:SetColorTexture(rangeOverlayRGBA.r, rangeOverlayRGBA.g, rangeOverlayRGBA.b, rangeOverlayRGBA.a)
    s.RangeOverlay:Hide()

    s.Cooldown = CreateFrame("Cooldown", "$parentCooldown", s, "CooldownFrameTemplate")
    s.Cooldown:SetAllPoints(s)
    s.Cooldown:SetFrameLevel(6)
    s.Cooldown:Show()

    s.SpellId = nil
    s.SpellName = nil
    s.ItemId = nil
    s.ItemName = nil

    s:SetScript('OnMouseUp', function(self, button)
        if button == 'RightButton' and IsShiftKeyDown() then
            SC.GenerateContextMenu()
            EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, "cursor", 0 , 100, "MENU")
        end
    end)
    s:SetScript('OnReceiveDrag', function(self)
        print(self.Id, panel.Name)
        local info, a, b, c = GetCursorInfo()
        if info == 'item' then
            panel:SetSocketInfo(self, info, tonumber(a))
        elseif info == 'spell' then
            panel:SetSocketInfo(self, info, tonumber(c))
        end
        ClearCursor()
    end)
    s:SetScript('OnLeave', function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    s:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
        if self.SpellId then
            GameTooltip:SetHyperlink('spell:'..self.SpellId)
        elseif self.ItemId then
            GameTooltip:SetHyperlink('item:'..self.ItemId)
        else
            GameTooltip:AddLine(tostring('|cffffffff'..'Drag an item or spell here')) -- \nor |rShift|cffffffff click to move spells or items'))
        end
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('|cffA330C9Simple Cooldowns|r')
        --GameTooltip:AddLine(' ')
        GameTooltip:AddDoubleLine('Panel', tostring('|cffffffff'..panel.Name))
        GameTooltip:AddDoubleLine('Spec', tostring('|cffffffff'..panel.Specialization.Name))
        GameTooltip:AddLine('|cffffffffShift click for menu')
        GameTooltip:Show()
    end)

    table.insert(self.Sockets, s)
end

function SC.Panel:SetOrientation(orientation)
    self.Orientation = orientation
    if self.Orientation == 'horizontal' then
        for k, socket in ipairs(self.Sockets) do
            socket:ClearAllPoints()
            --socket:SetSize(self.Height, self.Height)
            socket:SetPoint('BOTTOMLEFT', socket:GetWidth() * (k-1), 0)
            self.Width = #self.Sockets * socket:GetWidth()
            self.Height = socket:GetWidth()
        end
    elseif self.Orientation == 'vertical' then
        for k, socket in ipairs(self.Sockets) do
            socket:ClearAllPoints()
            --socket:SetSize(self.Height, self.Height)
            socket:SetPoint('TOPLEFT', 0, ((socket:GetHeight() * (k-1)) * -1) - 14)
            self.Width = socket:GetWidth()
            self.Height = #self.Sockets * socket:GetWidth()
        end
    end
    self.Frame:SetSize(self.Width, self.Height + 14)
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        if SC_GLOBAL.Characters[guid].Panels[self.Name] then
            SC_GLOBAL.Characters[guid].Panels[self.Name].Orientation = orientation
            SC_GLOBAL.Characters[guid].Panels[self.Name].Height = self.Height
            SC_GLOBAL.Characters[guid].Panels[self.Name].Width = self.Width
        end
    end
end

function SC.Panel:DeleteSocket(socket, id)
    local guid = UnitGUID('player')
    if SC_GLOBAL and guid then
        socket:Hide()
        table.remove(self.Sockets, id)
        for k, socket in ipairs(self.Sockets) do
            socket:SetPoint('BOTTOMLEFT', ((k-1)*self.Height), 0)
        end
        self.Frame:SetWidth(self.Height * #self.Sockets)
    end
end

function SC.Panel:SetSocketInfo(socket, info, id)
    if info == 'item' then
        socket.ItemId = tonumber(id)
        local itemTexture = select(10, GetItemInfo(socket.ItemId))
        socket.Texture:SetTexture(tonumber(itemTexture))
        local itemName = select(1, GetItemInfo(socket.ItemId))
        socket.ItemName = itemName
        -- remove spell data for cooldown API checks
        socket.SpellId = nil
        socket.SpellName = nil
    elseif info == 'spell' then
        socket.SpellId = tonumber(id)
        local spellTexture = select(1, GetSpellTexture(socket.SpellId))
        socket.Texture:SetTexture(tonumber(spellTexture))
        local spellName = select(1, GetSpellInfo(socket.SpellId))
        socket.SpellName = spellName
        -- remove item data for cooldown API checks
        socket.ItemId = nil
        socket.ItemName = nil
    end
    -- update saved variables
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        if SC_GLOBAL.Characters[guid].Panels[self.Name] then
            for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[self.Name].Sockets) do
                if self.Sockets[k] then
                    s.Texture = self.Sockets[k].Texture
                    s.ItemId = self.Sockets[k].ItemId
                    s.ItemName = self.Sockets[k].ItemName
                    s.SpellId = self.Sockets[k].SpellId
                    s.SpellName = self.Sockets[k].SpellName
                end
            end
        end
    end
end