


local addonName, SC = ...

SC.Socket = {}
SC.Socket.__index = SC.Socket

--- updates the socket spell or item information and writes data to save var
-- @param panel frame object to use for saved var lookup
-- @param info string either spell or item
-- @param id number value for the spell or item ID
function SC.Socket:SetInfo(panel, info, id)
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].Texture = self.Texture
        if info == 'item' then
            self.ItemId = tonumber(id)
            local itemTexture = select(10, GetItemInfo(self.ItemId))
            self.Texture = tonumber(itemTexture)
            self.Frame.Texture:SetTexture(tonumber(itemTexture))
            local itemName = select(1, GetItemInfo(self.ItemId))
            self.ItemName = itemName
            -- remove spell data for cooldown API checks
            self.SpellId = nil
            self.SpellName = nil
            SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].ItemId = self.ItemId
            SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].ItemName = self.ItemName
        elseif info == 'spell' then
            self.SpellId = tonumber(id)
            local spellTexture = select(1, GetSpellTexture(self.SpellId))
            self.Texture = tonumber(spellTexture)
            self.Frame.Texture:SetTexture(tonumber(spellTexture))
            local spellName = select(1, GetSpellInfo(self.SpellId))
            self.SpellName = spellName
            -- remove item data for cooldown API checks
            self.ItemId = nil
            self.ItemName = nil
            SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].SpellId = self.SpellId
            SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].SpellName = self.SpellName
        end
    end
end

function SC.Socket:SetRangeOverlayRGB(panel, r, g, b)
    self.RangeOverlay.RGBA.r = r
    self.RangeOverlay.RGBA.g = g
    self.RangeOverlay.RGBA.b = b
    -- update saved variables
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        if SC_GLOBAL.Characters[guid].Panels[panel.Name] then
            --for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].RangeOverlay.RGBA.r = self.RangeOverlay.RGBA.r
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].RangeOverlay.RGBA.g = self.RangeOverlay.RGBA.g
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Idk].RangeOverlay.RGBA.r = self.RangeOverlay.RGBA.b
            --end
        end
    end
end


function SC.Socket:SetRangeOverlayOpacity(panel, a)
    self.RangeOverlay.RGBA.a = tonumber(a)
    -- update saved variables
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        if SC_GLOBAL.Characters[guid].Panels[panel.Name] then
            --for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].RangeOverlay.RGBA.a = self.RangeOverlay.RGBA.a
            --end
        end
    end
end


function SC.Socket:SetUsableOverlayRGB(panel, r, g, b)
    self.UsableOverlay.RGBA.r = r
    self.UsableOverlay.RGBA.g = g
    self.UsableOverlay.RGBA.b = b
    -- update saved variables
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        if SC_GLOBAL.Characters[guid].Panels[panel.Name] then
            --for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].UsableOverlay.RGBA.r = self.UsableOverlay.RGBA.r
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].UsableOverlay.RGBA.g = self.UsableOverlay.RGBA.g
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Idk].UsableOverlay.RGBA.r = self.UsableOverlay.RGBA.b
            --end
        end
    end
end


function SC.Socket:SetUsableOverlayOpacity(panel, a)
    self.UsableOverlay.RGBA.a = tonumber(a)
    -- update saved variables
    local guid = UnitGUID('player')
    if guid and SC_GLOBAL then
        if SC_GLOBAL.Characters[guid].Panels[panel.Name] then
            --for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
                SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets[self.Id].UsableOverlay.RGBA.a = self.UsableOverlay.RGBA.a
            --end
        end
    end
end


function SC.Socket:GetInfo()
    local panel = { Parent = self.Frame:GetParent(), Name = self.Frame:GetParent():GetName() }
    print(panel.Parent, panel.Name)
    for k, v in pairs(self) do
        print(k, v)
    end
end