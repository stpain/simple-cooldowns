

local addonName, SC = ...

SC.Panel = {}
SC.Panel.__index = SC.Panel

--- create a new panel
function SC.Panel.NewPanel(name, anchor, width, height, offsetX, offsetY, sockets, display, spec, orientation)
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
    panel.SocketCount = 0
    panel.Specialization = spec
    panel.Orientation = orientation
    
    setmetatable(panel, SC.Panel)
    return panel
end

--- adjust the panel layout, can be used any time the panel layout needs updating
-- @param orientation string value for new layout
function SC.Panel:SetOrientation(orientation)
    self.Orientation = orientation
    if self.Orientation == 'horizontal' then
        for k, socket in ipairs(self.Sockets) do
            socket.Frame:ClearAllPoints()
            --socket:SetSize(self.Height, self.Height)
            socket.Frame:SetPoint('BOTTOMLEFT', socket.Frame:GetWidth() * (k-1), 0)
            self.Width = #self.Sockets * socket.Frame:GetWidth()
            self.Height = socket.Frame:GetWidth()
        end
    elseif self.Orientation == 'vertical' then
        for k, socket in ipairs(self.Sockets) do
            socket.Frame:ClearAllPoints()
            --socket:SetSize(self.Height, self.Height)
            socket.Frame:SetPoint('TOPLEFT', 0, ((socket.Frame:GetHeight() * (k-1)) * -1) - 14)
            self.Width = socket.Frame:GetWidth()
            self.Height = #self.Sockets * socket.Frame:GetWidth()
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

--- creates a new socket frame
-- @param id, number value for this socket within the panel sockets table, also used to positioning
-- @param rangeOverlay, table value used to set the rangeOverlay
-- @param usableOverlay, table value used to set the usable Overlay
-- @param visibility, boolean value to determine when socket is shown
function SC.Panel:NewSocket(id, rangeOverlay, usableOverlay, visibility)
    local panel = self
    panel.SocketCount = panel.SocketCount + 1 -- this is incremented during the client up time and is used to keep socket id's unique
    
    local socket = {}
    socket.Id = id
    socket.Frame = CreateFrame('FRAME', tostring(panel.Name..'_Socket'..panel.SocketCount), panel.Frame, BackdropTemplateMixin and "BackdropTemplate")
    socket.Frame:EnableMouse(true)
    socket.Frame:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
    })
    if panel.Height > panel.Width then -- orientation is vertical, could just use panel.Orientation ?
        socket.Frame:SetSize(panel.Width, panel.Width)
    else
        socket.Frame:SetSize(panel.Height, panel.Height)
    end
    local x = #panel.Sockets -- needs to be assigned to local variable else table length is wrong
    socket.Frame:SetPoint('BOTTOMLEFT', x * panel.Height, 0)

    socket.Texture = 132048
    socket.Frame.Texture = socket.Frame:CreateTexture("$parentTexture", 'ARTWORK')
    socket.Frame.Texture:SetAllPoints(socket.Frame)
    socket.Frame.Texture:SetTexture(socket.Texture)

    if not usableOverlay.RGBA then
        usableOverlay.RGBA = {r=0, g=0, b=0, a=0.8}
    end
    socket.UsableOverlay = {}
    socket.UsableOverlay.RGBA = usableOverlay.RGBA
    socket.UsableOverlay.Display = usableOverlay.Display
    socket.Frame.UsableOverlay = socket.Frame:CreateTexture("$parentUsableOverlay", "OVERLAY")
    socket.Frame.UsableOverlay:SetPoint('TOPLEFT', 2, -2)
    socket.Frame.UsableOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
    socket.Frame.UsableOverlay:SetColorTexture(usableOverlay.RGBA.r, usableOverlay.RGBA.g, usableOverlay.RGBA.b, usableOverlay.RGBA.a)
    socket.Frame.UsableOverlay:Hide()

    if not rangeOverlay.RGBA then
        rangeOverlay.RGBA = {r=1, g=0, b=0, a=0.6}
    end
    socket.RangeOverlay = {}
    socket.RangeOverlay.RGBA = rangeOverlay.RGBA
    socket.RangeOverlay.Display = rangeOverlay.Display
    socket.Frame.RangeOverlay = socket.Frame:CreateTexture("$parentRangeOverlay", "OVERLAY")
    socket.Frame.RangeOverlay:SetPoint('TOPLEFT', 2, -2)
    socket.Frame.RangeOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
    socket.Frame.RangeOverlay:SetColorTexture(rangeOverlay.RGBA.r, rangeOverlay.RGBA.g, rangeOverlay.RGBA.b, rangeOverlay.RGBA.a)
    socket.Frame.RangeOverlay:Hide()

    socket.Frame.Cooldown = CreateFrame("Cooldown", "$parentCooldown", socket.Frame, "CooldownFrameTemplate")
    socket.Frame.Cooldown:SetAllPoints(socket.Frame)
    socket.Frame.Cooldown:SetFrameLevel(6)
    socket.Frame.Cooldown:Show()

    socket.Visibility = tonumber(visibility)

    socket.SpellId = nil
    socket.SpellName = nil
    socket.ItemId = nil
    socket.ItemName = nil

    socket.Frame:SetScript('OnMouseUp', function(self, button)
        if button == 'RightButton' and IsShiftKeyDown() then
            SC.GenerateContextMenu()
            local h = #SC.ContextMenu
            EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, "cursor", 0 , h * 18, "MENU")
        end
    end)
    socket.Frame:SetScript('OnReceiveDrag', function(self)
        local info, a, b, c = GetCursorInfo()
        if info == 'item' then
            socket:SetInfo(panel, info, tonumber(a))
        elseif info == 'spell' then
            socket:SetInfo(panel, info, tonumber(c))
        end
        ClearCursor()
    end)
    socket.Frame:SetScript('OnLeave', function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    socket.Frame:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
        if socket.SpellId then
            GameTooltip:SetHyperlink('spell:'..socket.SpellId)
        elseif socket.ItemId then
            GameTooltip:SetHyperlink('item:'..socket.ItemId)
        else
            GameTooltip:AddLine(tostring('|cffffffff'..'Drag an item or spell here')) -- \nor |rShift|cffffffff click to move spells or items'))
        end
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine('|cffA330C9Simple Cooldowns|r')
        --GameTooltip:AddLine(' ')
        GameTooltip:AddDoubleLine('Panel', tostring('|cffffffff'..panel.Name))
        GameTooltip:AddDoubleLine('Spec', tostring('|cffffffff'..panel.Specialization.Name))
        --GameTooltip:AddDoubleLine('Socket', tostring('|cffffffff'..socket.Id))
        GameTooltip:AddLine('|cffffffffShift|r+ right click for menu')
        GameTooltip:Show()
    end)

    setmetatable(socket, SC.Socket)
    return socket
end

--- removes a socket from the players UI and deletes from saved var
-- @param socket frame object to remove
-- @param id number value of the table element for the socket
function SC.Panel:DeleteSocket(socket, id)
    local guid = UnitGUID('player')
    if SC_GLOBAL and guid then
        socket.Frame:Hide()
        table.remove(self.Sockets, id)
        -- this will handle the new panel layout
        self:SetOrientation(self.Orientation)
    end
end