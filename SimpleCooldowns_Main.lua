

local addonName, SC = ...

local Panel = SC.Panel

SC.Loaded = false
SC.Panels = {}
SC.MovingMode = false
SC.ContextMenu_DropDown = CreateFrame("Frame", "SimpleCooldownsSpellButtonContextMenu", UIParent, "UIDropDownMenuTemplate")
SC.ContextMenu_Separator = "|TInterface/COMMON/UI-TooltipDivider:8:150|t"
SC.ContextMenu = {}

----------------------------------------------------------------------------------------------------
-- helper functions
----------------------------------------------------------------------------------------------------
function SC.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage('|cffABD473SimpleCooldowns: |r'..msg)
end

function SC.MakeFrameMovable(frame)
    if frame.Frame then
        frame.Frame:SetMovable(true)
        frame.Frame:EnableMouse(true)
        frame.Frame:RegisterForDrag("LeftButton")
        frame.Frame:SetScript("OnDragStart", frame.StartMoving)
        frame.Frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    else
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end
end

function SC.LockFramePos(frame)
    if frame.Frame then
        frame.Frame:SetMovable(false)
    else
        frame:SetMovable(false)
    end
    --frame:EnableMouse(false)
end

function SC.RgbToPercent(t)
    if type(t) == 'table' then
        if type(t[1]) == 'number' and type(t[2]) == 'number' and type(t[3]) == 'number' then
            return {tonumber(t[1] / 256.0), tonumber(t[2] / 256.0), tonumber(t[3] / 256.0)}
        end
    end
end

----------------------------------------------------------------------------------------------------
-- slash commands
----------------------------------------------------------------------------------------------------
SLASH_SIMPLECOOLDOWNS1 = '/s-c'
SlashCmdList['SIMPLECOOLDOWNS'] = function(msg)
	if msg == '-help' then
        print('help')
    elseif msg == 'test' then
        local s = SC.Socket:New(1, 2)
        s:Foo(3)
        s:Add()
        s:Edit(8)
    end
end

----------------------------------------------------------------------------------------------------
-- minimap button
----------------------------------------------------------------------------------------------------
function SC.CreateMinimapButton()
    local ldb = LibStub("LibDataBroker-1.1")
    SC.MinimapButtonObject = ldb:NewDataObject(addonName, {
        type = "data source",
        icon = 132129,
        OnClick = function(self, button)
            if button == "LeftButton" then
                -- Standard workaround call OpenToCategory twice
                -- https://www.wowinterface.com/forums/showpost.php?p=319664&postcount=2
                -- InterfaceOptionsFrame_OpenToCategory(addonName)
                -- InterfaceOptionsFrame_OpenToCategory(addonName)
            elseif button == 'RightButton' then
                SC.GenerateContextMenu()
                EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, UIParent, (UIParent:GetWidth() / 2) , (UIParent:GetHeight() / 2), "MENU")
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("|cffFF7D0A"..addonName)
            tooltip:AddLine("|cffFFFFFFRight click:|r Options")
        end,
    })
    SC.MinimapIcon = LibStub("LibDBIcon-1.0")
    if not SC_GLOBAL['MinimapButton'] then SC_GLOBAL['MinimapButton'] = {} end
    SC.MinimapIcon:Register(addonName, SC.MinimapButtonObject, SC_GLOBAL['MinimapButton'])
end

function SC.TogglePanelLock()
    SC.MovingMode = not SC.MovingMode
    if SC.MovingMode == true then
        for k, panel in pairs(SC.Panels) do
            SC.MakeFrameMovable(panel.Frame)
            panel.Title:Show()
            panel.Background:Show()
        end
    elseif SC.MovingMode == false then
        for k, panel in pairs(SC.Panels) do
            SC.LockFramePos(panel.Frame)
            panel.Title:Hide()
            panel.Background:Hide()
        end
    end
    for k, panel in pairs(SC.Panels) do
        local guid = UnitGUID('player')
        if guid then
            --local point, relativeTo, relativePoint, xOfs, yOfs = panel:GetPoint()
            local point, relativeTo, relativePoint, xOfs, yOfs = panel.Frame:GetPoint()
            SC_GLOBAL.Characters[guid].Panels[panel.Name].Anchor = point
            SC_GLOBAL.Characters[guid].Panels[panel.Name].OffsetX = xOfs
            SC_GLOBAL.Characters[guid].Panels[panel.Name].OffsetY = yOfs
        end
    end
end

SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider = CreateFrame('FRAME', 'SCContextMenuCustomFrameNewPanel_Sockets_Slider', UIParent, 'UIDropDownCustomMenuEntryTemplate')
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider:SetSize(125, 16)

SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider = CreateFrame('SLIDER', 'SCContextMenuCustomFrameNewPanel_Sockets_Slider_Slider', SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider, 'OptionsSliderTemplate')
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetPoint('LEFT', 0, 0)
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetThumbTexture("Interface/Buttons/UI-SliderBar-Button-Horizontal")
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetSize(100, 16)
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetOrientation('HORIZONTAL')
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetMinMaxValues(1, 10) 
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetValueStep(1.0)
_G[SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:GetName()..'Low']:SetText('')
_G[SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:GetName()..'High']:SetText('')

SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.text = SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider:CreateFontString('SCContextMenuCustomFrameNewPanel_Sockets_Slider_Text', 'OVERLAY', 'GameFontNormal')
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.text:SetPoint('LEFT', SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider, 'RIGHT', 10, 0)
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.text:SetFont("Fonts\\FRIZQT__.TTF", 10)

SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetValue(4)
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.text:SetText(string.format("%.0f", SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:GetValue()))
SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:SetScript('OnValueChanged', function(self)
    SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.text:SetText(string.format("%.0f", math.ceil(self:GetValue())))
end)

SC.ContextMenu_CustomFrame_NewPanel_Editbox = CreateFrame('FRAME', 'SCContextMenuCustomFrameNewPanelEditbox', UIParent, 'UIDropDownCustomMenuEntryTemplate')
SC.ContextMenu_CustomFrame_NewPanel_Editbox:SetSize(125, 16)

SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox = CreateFrame('EditBox', 'SCContextMenuCustomFrameNewPanel_Editbox', SC.ContextMenu_CustomFrame_NewPanel_Editbox, "InputBoxTemplate")
SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:SetFontObject('GameFontNormal')
SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:SetPoint('LEFT', 0, 0)
SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:SetSize(100, 16)
SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:SetText('Panel Name')

SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider = CreateFrame('FRAME', 'SCContextMenuCustomFrameNewPanel_IconSize_Slider', UIParent, 'UIDropDownCustomMenuEntryTemplate')
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider:SetSize(100, 16)

SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider = CreateFrame('SLIDER', 'SCContextMenuCustomFrameNewPanel_IconSize_Slider_Slider', SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider, 'OptionsSliderTemplate')
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetPoint('LEFT', 0, 0)
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetThumbTexture("Interface/Buttons/UI-SliderBar-Button-Horizontal")
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetSize(100, 16)
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetOrientation('HORIZONTAL')
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetMinMaxValues(10, 80) 
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetValueStep(1)
_G[SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:GetName()..'Low']:SetText('')
_G[SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:GetName()..'High']:SetText('')

SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.text = SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider:CreateFontString('SCContextMenuCustomFrameNewPanel_IconSize_Slider_Text', 'OVERLAY', 'GameFontNormal')
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.text:SetPoint('LEFT', SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider, 'RIGHT', 10, 0)
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.text:SetFont("Fonts\\FRIZQT__.TTF", 10)

SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetValue(4)
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.text:SetText(string.format("%.0f", SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:GetValue()))
SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:SetScript('OnValueChanged', function(self)
    SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.text:SetText(string.format("%.0f", self:GetValue()))
end)

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider = CreateFrame('FRAME', 'SCContextMenuCustomFrameEditPanel_IconSize_Slider', UIParent, 'UIDropDownCustomMenuEntryTemplate')
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider:SetSize(125, 16)

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider = CreateFrame('SLIDER', 'SCContextMenuCustomFrameEditPanel_IconSize_Slider_Slider', SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider, 'OptionsSliderTemplate')
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetPoint('LEFT', 0, 0)
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetThumbTexture("Interface/Buttons/UI-SliderBar-Button-Horizontal")
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetSize(100, 16)
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetOrientation('HORIZONTAL')
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetMinMaxValues(20, 100) 
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetValueStep(1)
_G[SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:GetName()..'Low']:SetText('')
_G[SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:GetName()..'High']:SetText('')

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text = SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider:CreateFontString('SCContextMenuCustomFrameEditPanel_IconSize_Slider_Text', 'OVERLAY', 'GameFontNormal')
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetPoint('LEFT', SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider, 'RIGHT', 10, 0)
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetFont("Fonts\\FRIZQT__.TTF", 10)

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetValue(40)
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetText(string.format("%.0f", SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:GetValue()))

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetScript('OnShow', function(self)
    local guid = UnitGUID('player')
    if guid then
        if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels then
            local dropDownListID = self:GetParent():GetParent()['parentLevel']
            local buttonID = self:GetParent():GetParent()['parentID']
            if dropDownListID and buttonID then
                local panel = _G['DropDownList'..dropDownListID..'Button'..buttonID].arg1
                if panel and SC_GLOBAL.Characters[guid].Panels[panel.Name] then
                    if panel.Orientation == 'horizontal' then
                        --self:SetValue(tonumber(SC_GLOBAL.Characters[guid].Panels[panel.Name].Height))
                        self:SetValue(tonumber(panel.Height))
                    elseif panel.Orientation == 'vertical' then
                        --self:SetValue(tonumber(SC_GLOBAL.Characters[guid].Panels[panel.Name].Width))
                        self:SetValue(tonumber(panel.Width))
                    end
                end
            end
        else
            self:SetValue(40)
        end
    end
end)

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetScript('OnValueChanged', function(self)
    local guid = UnitGUID('player')
    if guid then
        if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels then
            SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetText(string.format("%.0f", self:GetValue()))
            local dropDownListID = self:GetParent():GetParent()['parentLevel']
            local buttonID = self:GetParent():GetParent()['parentID']
            local panel = _G['DropDownList'..dropDownListID..'Button'..buttonID].arg1
            if panel then
                for k, socket in ipairs(panel.Sockets) do
                    socket:SetSize(self:GetValue(), self:GetValue())
                end
                panel:SetOrientation(panel.Orientation)
            end
        end
    end
end)

function SC.GenerateContextMenu()
    local newPanel = {
        { text = 'Create panel', isTitle=true, notCheckable=true, },
        { text = 'Number of sockets', notCheckable=true, notClickable=true, },
        { text = 'New panel Slider', notCheckable=true, customFrame = SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider, },
        { text = ' ', notCheckable=true, notClickable=true, },
        { text = 'New panel Editbox', notCheckable=true, customFrame = SC.ContextMenu_CustomFrame_NewPanel_Editbox, },
        { text = ' ', notCheckable=true, notClickable=true, },
        { text = 'Icon size', notCheckable=true, notClickable=true, },
        { text = 'New panel Slider', notCheckable=true, customFrame = SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider, },
        { text = ' ', notCheckable=true, notClickable=true, },
        { text = 'Create panel', notCheckable=true, func=SC.ContextMenu_CreatePanel },
    }
    local editPanel = {
        { text='Select panel', isTitle=true, notCheckable=true, }
    }
    SC.ContextMenu = {
        { text = 'Simple Cooldowns', isTitle=true, notCheckable=true, },
        { text = 'Toggle panel lock', notCheckable=true, func=SC.TogglePanelLock, keepShownOnClick=true },
        { text = 'New panel', notCheckable=true, hasArrow=true, menuList=newPanel },
        { text = SC.ContextMenu_Separator, notCheckable=true, notClickable=true },
        { text = 'Edit Panel', isTitle=true, notCheckable=true, },
    }
    if next(SC.Panels) then
        for k, panel in pairs(SC.Panels) do
            table.insert(SC.ContextMenu, {
                text = k,
                arg1 = panel,
                arg2 = panel.Name,
                hasArrow=true,
                notCheckable=true,
                menuList = {
                    { text = panel.Name, isTitle=true, notCheckable=true, },
                    { text = panel.Specialization.Name, icon = panel.Specialization.Icon, notClickable=true, notCheckable=true, },
                    {
                        text = 'Display',
                        arg1 = panel,
                        arg2 = panel.Name,
                        isNotRadio = true,
                        keepShownOnClick=true,
                        checked = function(self) 
                            local guid = UnitGUID('player')
                            if guid then
                                return SC_GLOBAL.Characters[guid].Panels[self.arg1.Name]['Display']
                            else
                                return false
                            end
                        end,
                        func = function(self)
                            local guid = UnitGUID('player')
                            if guid then
                                if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels[self.arg1.Name] then
                                    SC_GLOBAL.Characters[guid].Panels[self.arg1.Name]['Display'] = not SC_GLOBAL.Characters[guid].Panels[self.arg1.Name]['Display']
                                end
                            end
                            if SC_GLOBAL.Characters[guid].Panels[self.arg1.Name] and SC_GLOBAL.Characters[guid].Panels[self.arg1.Name]['Display'] == true then
                                self.arg1.Frame:Show()
                            else
                                self.arg1.Frame:Hide()
                            end
                        end,
                    },
                    { text = 'Orientation', isTitle=false, notCheckable=true, hasArrow=true, menuList = {
                        { 
                            text = 'Horizontal',
                            arg1 = panel,
                            isTitle=false,
                            --keepShownOnClick=true,
                            checked = function(self)
                                local guid = UnitGUID('player')
                                if guid and SC_GLOBAL then
                                    if SC_GLOBAL.Characters[guid].Panels[self.arg1.Name]['Orientation'] == 'horizontal' then
                                        return true
                                    else
                                        return false
                                    end
                                else
                                    return false
                                end
                            end,
                            func = function()
                                panel:SetOrientation('horizontal')
                            end
                        },
                        { 
                            text = 'Vertical', 
                            arg1 = panel,
                            isTitle=false,
                            --keepShownOnClick=true,
                            checked = function(self)
                                local guid = UnitGUID('player')
                                if guid and SC_GLOBAL then
                                    if SC_GLOBAL.Characters[guid].Panels[self.arg1.Name]['Orientation'] == 'vertical' then
                                        return true
                                    else
                                        return false
                                    end
                                else
                                    return false
                                end
                            end,
                            func = function()
                                panel:SetOrientation('vertical')
                            end 
                        }
                    }},
                    { 
                        text = 'Delete', 
                        arg1=panel, 
                        notCheckable=true, 
                        func=function(self) 
                            self.arg1.Frame:Hide() 
                            local guid = UnitGUID('player')
                            if guid then
                                SC.Panels[k] = nil SC_GLOBAL.Characters[guid].Panels[k] = nil 
                            end
                        end, 
                    },
                    { text = SC.ContextMenu_Separator, notCheckable=true, notClickable=true },
                    { text = 'Sockets', notCheckable=true, isTitle=true,},
                    { text = SC.ContextMenu_Separator, notCheckable=true, notClickable=true },
                    { text = 'Socket size', isTitle=true, notClickable=true, notCheckable=true, },
                    { text = ' ', arg1=panel, arg2 = panel.Name, notCheckable=true, customFrame=SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider, },
                    { 
                        text = 'Add socket', 
                        arg1=panel, 
                        isTitle=false, 
                        notCheckable=true, 
                        func = function(self)
                            local guid = UnitGUID('player')
                            if guid and SC_GLOBAL then
                                local id = GetTime()
                                table.insert(SC_GLOBAL.Characters[guid].Panels[self.arg1.Name].Sockets, { 
                                    Id = id, 
                                    Texture = 132048, 
                                    SpellId = nil, 
                                    SpellName = nil, 
                                    ItemId = nil, 
                                    ItemName = nil,
                                    Visibility = 1,
                                    RangeOverlay = true,
                                    RangeOverlayRGBA = {r=1, g=0, b=0, a=0.6},
                                    UsableOverlay = true,
                                    UsableOverlayRGBA = {r=0, g=0, b=0, a=0.8}, 
                                })
                                SC_GLOBAL.Characters[guid].Panels[self.arg1.Name].Width = SC_GLOBAL.Characters[guid].Panels[self.arg1.Name].Width + SC_GLOBAL.Characters[guid].Panels[self.arg1.Name].Height
                                self.arg1:CreateSocket((#self.arg1.Sockets + 1), true, {r=1, g=0, b=0, a=0.6}, true, {r=0, g=0, b=0, a=0.8})
                            end
                        end
                    }
                }
            })
            for _, button in pairs(SC.ContextMenu) do
                if button.arg2 == panel.Name then
                    for i, socket in ipairs(panel.Sockets) do
                        local name = ''
                        if socket.SpellName then
                            name = socket.SpellName
                        elseif socket.ItemName then
                            name = socket.ItemName
                        end
                        table.insert(button.menuList, 7+i, {
                            text = string.format('%s %s', i, name),
                            isTitle = false,
                            --icon = socket.Texture:GetTexture(),
                            notCheckable = true,
                            hasArrow=true,
                            menuList = {
                                { text = 'Visibility', isTitle=false, notCheckable=true, hasArrow=true, menuList = {
                                    { text = 'Always', },
                                    { text = 'During cooldown', },
                                    { text = 'When usable', },
                                }},
                                { 
                                    text = 'Delete', 
                                    notCheckable=true, 
                                    func=function(self)
                                        local guid = UnitGUID('player')
                                        if guid and SC_GLOBAL then
                                            table.remove(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets, i)
                                            SC_GLOBAL.Characters[guid].Panels[panel.Name].Width = SC_GLOBAL.Characters[guid].Panels[panel.Name].Width - SC_GLOBAL.Characters[guid].Panels[panel.Name].Height
                                            panel:DeleteSocket(socket, i)
                                        end
                                    end 
                                },
                            }
                        })
                    end
                end
            end
        end
    end
end

function SC.ContextMenu_CreatePanel()
    local numSockets = math.ceil(SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:GetValue())
    local sockets = {}
    for i = 1, numSockets do
        table.insert(sockets, {
            Id = GetTime(), 
            Texture = 132048, 
            SpellId = nil, 
            SpellName = nil, 
            ItemId = nil, 
            ItemName = nil,
            Visibility = 1,
            RangeOverlay = true,
            RangeOverlayRGBA = {r=1, g=0, b=0, a=0.6},
            UsableOverlay = true,
            UsableOverlayRGBA = {r=0, g=0, b=0, a=0.8},
        })
    end
    local name = SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:GetText()
    local guid = UnitGUID('player')
    local spec = SC.FetchSpecData()
    if guid and spec and SC_GLOBAL then
        for k, panel in pairs(SC_GLOBAL.Characters[guid].Panels) do
            if tostring(k) == tostring(name) then
                name = tostring(GetServerTime())
            end
        end
        if not name then
            name = tostring(GetServerTime())
        end
        local iconSize = SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:GetValue()
        SC_GLOBAL.Characters[guid].Panels[name] = {
            Name = name,
            Anchor = 'CENTER',
            Height = tonumber(iconSize),
            Width = tonumber(iconSize * numSockets),
            Sockets = sockets,
            Display = true,
            Specialization = spec,
            Orientation = 'horizontal',
        }
        SC.Panels[name] = Panel.New(name, 'CENTER', tonumber(iconSize * numSockets), tonumber(iconSize), 0, 0, sockets, true, spec, 'horizontal')
        for k, v in ipairs(sockets) do
            SC.Panels[name]:CreateSocket(k, v.RangeOverlay, v.RangeOverlayRGBA, v.UsableOverlay, v.UsableOverlayRGBA)
        end
    end
    SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:ClearFocus()
end

----------------------------------------------------------------------------------------------------
-- functions
----------------------------------------------------------------------------------------------------
--[[
--currently updating UI and then writing data to saved var, consider writing data and making a refresh func
function SC.UpdateSocket(panel, socket, spellId, itemId) --spell and item id's need to be managed differently as the update func will call item cooldown or spell cooldown
    local guid = UnitGUID('player')
    if guid then
        if spellId ~= nil then
            spellId = tonumber(spellId)
            local spelltexture = select(1, GetSpellTexture(spellId))
            spelltexture = tonumber(spelltexture)
            local spellname = select(1, GetSpellInfo(spellId))
            spellname = tostring(spellname)
            if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels[panel.Name] then
                for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
                    if s.Id == socket.Id then
                        s.Texture = spelltexture
                        s.SpellId = spellId
                        s.SpellName = spellname
                        s.ItemId = nil
                        s.ItemName = nil
                    end
                end
            end
            -- for k, s in ipairs(SC.Panels[panel.Name].Sockets) do
            --     if s.Id == socket.Id then
            --         s.Texture:SetTexture(spelltexture)
            --         s.SpellId = spellId
            --         s.SpellName = spellname
            --         s.ItemId = nil
            --         s.ItemName = nil
            --     end
            -- end
        elseif itemId ~= nil then
            itemId = tonumber(itemId)
            local itemname = select(1, GetItemInfo(itemId))
            itemname = tostring(itemname)
            local itemtexture = select(10, GetItemInfo(itemId))
            itemtexture = tonumber(itemtexture)
            if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels[panel.Name] then
                for k, s in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
                    if s.Id == socket.Id then
                        s.Texture = itemtexture
                        s.ItemId = itemId
                        s.ItemName = itemname
                        s.SpellId = nil
                        s.SpellName = nil
                    end
                end
            end
            -- for k, s in ipairs(SC.Panels[panel.Name].Sockets) do
            --     if s.Id == socket.Id then
            --         s.Texture:SetTexture(itemtexture)
            --         s.ItemId = itemId
            --         s.ItemName = itemname
            --         s.SpellId = nil
            --         s.SpellName = nil
            --     end
            -- end
        end
    end
end

function SC.DeleteSocket(panel, socket, id)
    local guid = UnitGUID('player')
    if SC_GLOBAL and guid then
        socket:Hide()
        --socket:SetSize(1,1)
        table.remove(panel.Sockets, id)
        local height = socket:GetHeight()
        for k, socket in ipairs(panel.Sockets) do
            socket:SetPoint('BOTTOMLEFT', ((k-1)*height), 0)
        end
        panel:SetWidth(height * #panel.Sockets)
    end
end


function SC.AddSocket(panel, id)
    local guid = UnitGUID('player')
    if SC_GLOBAL then
        for k, socket in ipairs(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets) do
            if not SC.Panels[panel.Name].Sockets[k] then
                local s = CreateFrame('FRAME', tostring("$parentSocket"..k), panel) --, "SecureActionButtonTemplate")
                s:EnableMouse(true)
                s:SetBackdrop({
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    edgeSize = 16,
                })
                s:SetSize(tonumber(SC_GLOBAL.Characters[guid].Panels[panel.Name].Height), tonumber(SC_GLOBAL.Characters[guid].Panels[panel.Name].Height))
                s:SetPoint('BOTTOMLEFT', ((k-1)*tonumber(SC_GLOBAL.Characters[guid].Panels[panel.Name].Height)), 0)
                s:SetScript('OnEnter', function(self)
                    GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
                    if self.SpellId then
                        GameTooltip:SetHyperlink('spell:'..self.SpellId)
                    elseif self.ItemId then
                        GameTooltip:SetHyperlink('item:'..self.ItemId)
                    else
                        GameTooltip:AddLine(tostring('|cffffffff'..'drag an item or spell here')) -- \nor |rShift|cffffffff click to move spells or items'))
                    end
                    GameTooltip:AddLine(' ')
                    GameTooltip:AddLine('|cffA330C9Simple Cooldowns|r')
                    GameTooltip:AddDoubleLine('Panel', tostring('|cffffffff'..panel.Name))
                    GameTooltip:AddDoubleLine('Spec', tostring('|cffffffff'..panel.Specialization.Name))
                    GameTooltip:AddLine('|cffffffffShift click for menu')
                    GameTooltip:Show()
                end)
                s:SetScript('OnMouseUp', function(self, button)
                    if button == 'RightButton' and IsShiftKeyDown() then
                        SC.GenerateContextMenu()
                        EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, "cursor", 0 , 100, "MENU")
                    end
                end)
                s:SetScript('OnLeave', function(self)
                    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                end)
                s:SetScript('OnReceiveDrag', function(self) --update function built in here?
                    local info, a, b, c = GetCursorInfo()
                    -- print('got cursor info', info, a, b, c)
                    -- ClearCursor()
                    -- print('clear cursor')
                    -- if s.SpellId then
                    --     PickupSpell(s.SpellId)
                    --     print('picked up spell', s.spellId)
                    --     local info, a, b, c = GetCursorInfo()
                    --     print('got new cursor info', info, a, b, c)
                    --     --PickupSpellBookItem(s.SpellName)
                    -- elseif s.ItemId then
                    --     PickupItem(s.ItemId)
                    --     print('picked up item', s.spellId)
                    --     local info, a, b, c = GetCursorInfo()
                    --     print('got new cursor info', info, a, b, c)
                    -- else
                    --     ClearCursor()
                    -- end
                    if info == 'item' then
                        itemid = tonumber(a)
                        SC.UpdateSocket(panel, self, nil, itemid)
                    elseif info == 'spell' then
                        local spellid = tonumber(c)
                        SC.UpdateSocket(panel, self, spellid, nil)
                    end
                    ClearCursor()
                end)
                s.Texture = s:CreateTexture("$parentTexture", 'ARTWORK')
                s.Texture:SetAllPoints(s)
                s.Texture:SetTexture(socket.Texture)
                s.UsableOverlay = s:CreateTexture("$parentUsableOverlay", "OVERLAY")
                s.UsableOverlay:SetPoint('TOPLEFT', 2, -2)
                s.UsableOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
                s.UsableOverlay:SetColorTexture(0,0,0,0.8)
                s.UsableOverlay:Hide()
                s.RangeOverlay = s:CreateTexture("$parentRangeOverlay", "OVERLAY")
                s.RangeOverlay:SetPoint('TOPLEFT', 2, -2)
                s.RangeOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
                s.RangeOverlay:SetColorTexture(1,0,0,0.6)
                s.RangeOverlay:Hide()
                s.Cooldown = CreateFrame("Cooldown", "$parentCooldown", s, "CooldownFrameTemplate")
                s.Cooldown:SetAllPoints(s)
                s.Cooldown:SetFrameLevel(6)
                s.Cooldown:Show()
                s.SpellId = nil
                s.SpellName = nil
                s.ItemId = nil
                s.ItemName = nil
                s.Id = socket.Id
                table.insert(SC.Panels[panel.Name].Sockets, s) 
            end
        end
        panel:SetWidth(SC_GLOBAL.Characters[guid].Panels[panel.Name].Height * #SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets)
    end
end


function SC.CreatePanel(name, anchor, width, height, offsetX, offsetY, sockets, display, spec)
    local f = CreateFrame('FRAME', tostring('SimpleCooldownsPanel_'..name), UIParent)
    f.Background = f:CreateTexture("$parentBackground", 'BACKGROUND')
    f.Background:SetAllPoints(f)
    f.Background:SetColorTexture(0,0,0,0.7)
    f.Background:Hide()
    f.Title = f:CreateFontString("$parentTitle", 'OVERLAY', 'GameFontNormal')
    f.Title:SetPoint('TOP', 0, 0)
    f.Title:SetFont("Fonts\\FRIZQT__.TTF", 12)
    f.Title:SetTextColor(1,1,1,1)
    f.Title:SetText('Click to drag & move')
    f.Title:Hide()
    f:SetPoint(anchor, offsetX, offsetY)
    f:SetSize(width, height + 10)
    f:EnableMouse(true)
    f.Name = name
    f.Sockets = {}
    for k, v in ipairs(sockets) do
        local s = CreateFrame('FRAME', tostring("$parentSocket"..k), f) --, "SecureActionButtonTemplate")
        s:EnableMouse(true)
        s:SetBackdrop({
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
        })
        s:SetSize(height, height)
        s:SetPoint('BOTTOMLEFT', ((k-1)*height), 0)
        s:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
            if self.SpellId then
                GameTooltip:SetHyperlink('spell:'..self.SpellId)
            elseif self.ItemId then
                GameTooltip:SetHyperlink('item:'..self.ItemId)
            else
                GameTooltip:AddLine(tostring('|cffffffff'..'drag an item or spell here')) -- \nor |rShift|cffffffff click to move spells or items'))
            end
            GameTooltip:AddLine(' ')
            GameTooltip:AddLine('|cffA330C9Simple Cooldowns|r')
            GameTooltip:AddDoubleLine('Panel', tostring('|cffffffff'..name))
            GameTooltip:AddDoubleLine('Spec', tostring('|cffffffff'..spec.Name))
            GameTooltip:AddLine('|cffffffffShift click for menu')
            GameTooltip:Show()
        end)
        s:SetScript('OnMouseUp', function(self, button)
            if button == 'RightButton' and IsShiftKeyDown() then
                SC.GenerateContextMenu()
                EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, "cursor", 0 , 100, "MENU")
            end
        end)
        s:SetScript('OnMouseDown', function(self, button)
            if button == 'LeftButton' and IsShiftKeyDown() then
                -- local info, a, b, c = GetCursorInfo()
                -- ClearCursor()
                -- if self.SpellId then
                --     PickupSpell(self.SpellId)
                --     print('picked up spell', self.spellId)
                --     local info, a, b, c = GetCursorInfo()
                --     print('got new cursor info', info, a, b, c)
                --     --PickupSpellBookItem(self.SpellName)
                -- elseif self.ItemId then
                --     PickupItem(self.ItemId)
                --     print('picked up item', self.spellId)
                --     local info, a, b, c = GetCursorInfo()
                --     print('got new cursor info', info, a, b, c)
                -- else
                --     ClearCursor()
                -- end
                -- if info == 'item' then
                --     SC.UpdateSocket(f, self, nil, tonumber(a))
                -- elseif info == 'spell' then
                --     SC.UpdateSocket(f, self, tonumber(c), nil)
                -- end
            end
        end)
        s:SetScript('OnLeave', function(self)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end)
        s:SetScript('OnReceiveDrag', function(self) --update function built in here?
            local info, a, b, c = GetCursorInfo()
            -- print('got cursor info', info, a, b, c)
            -- ClearCursor()
            -- print('clear cursor')
            -- if self.SpellId then
            --     PickupSpell(self.SpellId)
            --     print('picked up spell', self.spellId)
            --     local info, a, b, c = GetCursorInfo()
            --     print('got new cursor info', info, a, b, c)
            --     --PickupSpellBookItem(self.SpellName)
            -- elseif self.ItemId then
            --     PickupItem(self.ItemId)
            --     print('picked up item', self.spellId)
            --     local info, a, b, c = GetCursorInfo()
            --     print('got new cursor info', info, a, b, c)
            -- else
            --     ClearCursor()
            -- end
            if info == 'item' then
                SC.UpdateSocket(f, self, nil, tonumber(a))
            elseif info == 'spell' then
                SC.UpdateSocket(f, self, tonumber(c), nil)
            end
            ClearCursor()
        end)
        s.Texture = s:CreateTexture("$parentTexture", 'ARTWORK')
        s.Texture:SetAllPoints(s)
        s.Texture:SetTexture(v.Texture)
        s.UsableOverlay = s:CreateTexture("$parentUsableOverlay", "OVERLAY")
        s.UsableOverlay:SetPoint('TOPLEFT', 2, -2)
        s.UsableOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
        s.UsableOverlay:SetColorTexture(0,0,0,0.8)
        s.UsableOverlay:Hide()
        s.RangeOverlay = s:CreateTexture("$parentRangeOverlay", "OVERLAY")
        s.RangeOverlay:SetPoint('TOPLEFT', 2, -2)
        s.RangeOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
        s.RangeOverlay:SetColorTexture(1,0,0,0.6)
        s.RangeOverlay:Hide()
        s.Cooldown = CreateFrame("Cooldown", "$parentCooldown", s, "CooldownFrameTemplate")
        s.Cooldown:SetAllPoints(s)
        s.Cooldown:SetFrameLevel(6)
        s.Cooldown:Show()
        s.SpellId = v.SpellId
        s.SpellName = v.SpellName
        s.ItemId = v.ItemId
        s.ItemName = v.ItemName
        s.Id = v.Id
        table.insert(f.Sockets, s)
    end
    --print('created', name)
    if display == false then
        f:Hide()
    end
    f.Specialization = spec

    -- add to in game cache
    SC.Panels[name] = f

    -- check spec and update show/hide
    local specTable = SC.FetchSpecData()
    if spec.ID ~= specTable.ID then
        f:Hide()
    end

    -- add to saved var if new panel
    local guid = UnitGUID('player')
    if guid then
        if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels then
            if not SC_GLOBAL.Characters[guid].Panels[name] then
                SC_GLOBAL.Characters[guid].Panels[name] = {}
                SC_GLOBAL.Characters[guid].Panels[name].Name = name
                SC_GLOBAL.Characters[guid].Panels[name].Anchor = anchor
                SC_GLOBAL.Characters[guid].Panels[name].Width = width
                SC_GLOBAL.Characters[guid].Panels[name].Height = height
                SC_GLOBAL.Characters[guid].Panels[name].OffsetX = offsetX
                SC_GLOBAL.Characters[guid].Panels[name].OffsetY = offsetY
                SC_GLOBAL.Characters[guid].Panels[name].Sockets = sockets
                SC_GLOBAL.Characters[guid].Panels[name].Display = display
                SC_GLOBAL.Characters[guid].Panels[name].Specialization = spec
            end
        end
    end
end
]]


----------------------------------------------------------------------------------------------------
-- register events
----------------------------------------------------------------------------------------------------
SC.EventFrame = CreateFrame('FRAME', 'SimpleCooldownsEventFrame', UIParent)
SC.EventFrame:RegisterEvent('ADDON_LOADED')
SC.EventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

----------------------------------------------------------------------------------------------------
-- init
----------------------------------------------------------------------------------------------------
function SC.Init()
    local guid = UnitGUID('player')
    local spec = SC.FetchSpecData()
    if guid and spec then
        print(guid, spec.Name, spec.ID)
        if not SC_GLOBAL then 
            SC_GLOBAL = {
                AddonName = addonName,
                MinimapButton = {},
                Characters = {},
            } 
        end
        if not SC_GLOBAL.Characters[guid] then
            SC_GLOBAL.Characters[guid] = {
                Name = UnitName('player'),
                Panels = {
                    ['Default'] = {
                        Name = 'Default',
                        Anchor = 'CENTER',
                        Width = 200.0,
                        Height = 50.0,
                        OffsetX = 0.0,
                        OffsetY = 0.0,
                        Sockets = {
                            { Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil, Visibility = '1', RangeOverlay = true, RangeOverlayRGBA = {r=1, g=0, b=0, a=0.6}, UsableOverlay = true, UsableOverlayRGBA = {r=0, g=0, b=0, a=0.8} },
                            { Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil, Visibility = '1', RangeOverlay = true, RangeOverlayRGBA = {r=1, g=0, b=0, a=0.6}, UsableOverlay = true, UsableOverlayRGBA = {r=0, g=0, b=0, a=0.8} },
                            { Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil, Visibility = '1', RangeOverlay = true, RangeOverlayRGBA = {r=1, g=0, b=0, a=0.6}, UsableOverlay = true, UsableOverlayRGBA = {r=0, g=0, b=0, a=0.8} },
                            { Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil, Visibility = '1', RangeOverlay = true, RangeOverlayRGBA = {r=1, g=0, b=0, a=0.6}, UsableOverlay = true, UsableOverlayRGBA = {r=0, g=0, b=0, a=0.8} },
                        },
                        Display = true,
                        Orientation = 'horizontal',
                        Specialization = spec,
                    }
                },
            }
        end
        SC.Loaded = true
        SC.LoadPanels()
        SC.CreateMinimapButton()
    end
end

function SC.LoadPanels()
    local guid = UnitGUID('player')
    if guid then
        for k, panel in pairs(SC_GLOBAL.Characters[guid].Panels) do
            if not SC.Panels[panel.Name] then
                SC.Panels[panel.Name] = Panel.New(panel.Name, panel.Anchor, panel.Width, panel.Height, panel.OffsetX, panel.OffsetY, panel.Sockets, panel.Display, panel.Specialization, panel.Orientation)
                for k, v in ipairs(panel.Sockets) do
                    SC.Panels[panel.Name]:CreateSocket(k, v.RangeOverlay, v.RangeOverlayRGBA, v.UsableOverlay, v.UsableOverlayRGBA)
                    if v.SpellId then
                        SC.Panels[panel.Name]:SetSocketInfo(SC.Panels[panel.Name].Sockets[k], 'spell', v.SpellId)
                    elseif v.ItemId then
                        SC.Panels[panel.Name]:SetSocketInfo(SC.Panels[panel.Name].Sockets[k], 'item', v.ItemId)
                    end
                end
                SC.Panels[panel.Name]:SetOrientation(panel.Orientation)
            end
        end
    end
end

function SC.FetchSpecData()
    local ret = false
    local currentSpec = GetSpecialization()
    if currentSpec then
        local id, name, description, icon, background, role, primaryStat = GetSpecializationInfo(currentSpec)
        if id then
            local role = GetSpecializationRoleByID(tonumber(id))
            if role ~= nil then
                ret = { ID = id, Name = name, Icon = icon }
            end
        end
    end
    return ret
end

function SC.OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...):lower() == "simplecooldowns" then
        SC.Print('loaded! To set up cooldowns head to the options interface menu > addons > Simple Cooldowns.')
        C_Timer.After(1, SC.Init)

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        local spec = SC.FetchSpecData()
        local guid = UnitGUID('player')
        if guid and spec then
            for k, panel in pairs(SC.Panels) do
                if panel.Specialization.ID == spec.ID then
                    panel:Show()
                else
                    panel:Hide()
                end
            end
        end
    end
end

function SC.OnUpdate()
    for k, panel in pairs(SC.Panels) do
        for j, socket in ipairs(panel.Sockets) do
            if socket.SpellName then
                local inRange = IsSpellInRange(socket.SpellName, "target")
                if tonumber(inRange) == 0 then
                    socket.RangeOverlay:Show()
                else
                    socket.RangeOverlay:Hide()
                    local usable, noMana = IsUsableSpell(socket.SpellName)
                    if usable == false then
                        socket.UsableOverlay:Show()
                    elseif usable == true then
                        socket.UsableOverlay:Hide()
                    end
                end
            end
            if socket.SpellId then
                local spellStart, spellDuration, enabled, modRate = GetSpellCooldown(socket.SpellId)
                socket.Cooldown:SetCooldown(spellStart, spellDuration)
            end
            if socket.ItemId then
                local itemStart, itemDuration, itemEnable = GetItemCooldown(socket.ItemId)
                socket.Cooldown:SetCooldown(itemStart, itemDuration)
            end
        end
    end
end

SC.EventFrame:SetScript("OnEvent", SC.OnEvent)
SC.EventFrame:SetScript("OnUpdate", SC.OnUpdate)