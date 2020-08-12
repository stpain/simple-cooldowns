

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
            local point, relativeTo, relativePoint, xOfs, yOfs = panel.Frame:GetPoint()
            SC_GLOBAL.Characters[guid].Panels[panel.Name].Anchor = point
            SC_GLOBAL.Characters[guid].Panels[panel.Name].OffsetX = xOfs
            SC_GLOBAL.Characters[guid].Panels[panel.Name].OffsetY = yOfs
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

----------------------------------------------------------------------------------------------------
-- slash commands
----------------------------------------------------------------------------------------------------
SLASH_SIMPLECOOLDOWNS1 = '/s-c'
SlashCmdList['SIMPLECOOLDOWNS'] = function(msg)
	if msg == '-help' then
        print('help')

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

----------------------------------------------------------------------------------------------------
-- context menu custom frames
----------------------------------------------------------------------------------------------------
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
                -- this will handle the size changes of sockets and panels
                panel:SetOrientation(panel.Orientation)
            end
        end
    end
end)


----------------------------------------------------------------------------------------------------
-- context menu
----------------------------------------------------------------------------------------------------
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
    -- local editPanel = {
    --     { text='Select panel', isTitle=true, notCheckable=true, }
    -- }
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
                            if guid and SC_GLOBAL then
                                return SC_GLOBAL.Characters[guid].Panels[panel.Name]['Display']
                            else
                                return false
                            end
                        end,
                        func = function(self)
                            local guid = UnitGUID('player')
                            if guid then
                                if SC_GLOBAL and SC_GLOBAL.Characters[guid].Panels[panel.Name] then
                                    SC_GLOBAL.Characters[guid].Panels[panel.Name]['Display'] = not SC_GLOBAL.Characters[guid].Panels[panel.Name]['Display']
                                end
                            end
                            if SC_GLOBAL.Characters[guid].Panels[panel.Name] and SC_GLOBAL.Characters[guid].Panels[panel.Name]['Display'] == true then
                                panel.Frame:Show()
                            else
                                panel.Frame:Hide()
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
                                    if SC_GLOBAL.Characters[guid].Panels[panel.Name]['Orientation'] == 'horizontal' then
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
                                    if SC_GLOBAL.Characters[guid].Panels[panel.Name]['Orientation'] == 'vertical' then
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
                            panel.Frame:Hide() 
                            local guid = UnitGUID('player')
                            if guid then
                                SC.Panels[k] = nil SC_GLOBAL.Characters[guid].Panels[k] = nil 
                            end
                        end, 
                    },
                    { text = SC.ContextMenu_Separator, notCheckable=true, notClickable=true },
                    { text = 'Sockets', arg1='sockets-header', notCheckable=true, isTitle=true,},
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
                                table.insert(SC_GLOBAL.Characters[guid].Panels[panel.Name].Sockets, { 
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
                                SC_GLOBAL.Characters[guid].Panels[panel.Name].Width = SC_GLOBAL.Characters[guid].Panels[panel.Name].Width + SC_GLOBAL.Characters[guid].Panels[panel.Name].Height
                                panel:CreateSocket((#panel.Sockets + 1), true, {r=1, g=0, b=0, a=0.6}, true, {r=0, g=0, b=0, a=0.8})
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
                        -- keep an eye on the value passed in to set position, should be set to the element with arg1='sockets-header'
                        table.insert(button.menuList, 7+i, {
                            text = string.format('%s %s', i, name),
                            isTitle = false,
                            --icon = socket.Texture:GetTexture(),
                            notCheckable = true,
                            hasArrow=true,
                            menuList = {
                                { text = 'Visibility', isTitle=false, notCheckable=true, hasArrow=true, menuList = {
                                    { 
                                        text = 'Always',
                                        checked = function()
                                            if socket.Visibility == 1 then
                                                return true
                                            else
                                                return false
                                            end
                                        end,
                                    },
                                    { 
                                        text = 'During cooldown', 
                                        checked = function()
                                            if socket.Visibility == 2 then
                                                return true
                                            else
                                                return false
                                            end
                                        end,
                                    },
                                    { 
                                        text = 'When usable', 
                                        checked = function()
                                            if socket.Visibility == 3 then
                                                return true
                                            else
                                                return false
                                            end
                                        end,
                                    },
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
        SC.Panels[name] = Panel.NewPanel(name, 'CENTER', tonumber(iconSize * numSockets), tonumber(iconSize), 0, 0, sockets, true, spec, 'horizontal')
        for k, v in ipairs(sockets) do
            SC.Panels[name]:CreateSocket(k, v.RangeOverlay, v.RangeOverlayRGBA, v.UsableOverlay, v.UsableOverlayRGBA)
        end
    end
    SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:ClearFocus()
end



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
                SC.Panels[panel.Name] = Panel.NewPanel(panel.Name, panel.Anchor, panel.Width, panel.Height, panel.OffsetX, panel.OffsetY, panel.Sockets, panel.Display, panel.Specialization, panel.Orientation)
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


function SC.OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...):lower() == "simplecooldowns" then
        C_Timer.After(1, SC.Init)

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        local spec = SC.FetchSpecData()
        local guid = UnitGUID('player')
        if guid and spec then
            for k, panel in pairs(SC.Panels) do
                if panel.Specialization.ID == spec.ID then
                    panel.Frame:Show()
                else
                    panel.Frame:Hide()
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