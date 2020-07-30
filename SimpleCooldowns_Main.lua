

local addonName, SC = ...

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
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function SC.LockFramePos(frame)
    frame:SetMovable(false)
    --frame:EnableMouse(false)
end

function SC.RgbToPercent(t)
    if type(t) == 'table' then
        if type(t[1]) == 'number' and type(t[2]) == 'number' and type(t[3]) == 'number' then
            local r = tonumber(t[1] / 256.0)
            local g = tonumber(t[2] / 256.0)
            local b = tonumber(t[3] / 256.0)
            return {r, g, b}
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
                SC.GenerateMinimapContextMenu()
                EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, "cursor", 0 , 0, "MENU")
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("|cffFF7D0A"..addonName)
            tooltip:AddLine("|cffFFFFFFRight click:|r Options")
        end,
    })
    SC.MinimapIcon = LibStub("LibDBIcon-1.0")
    if not SC_CHARACTER['MinimapButton'] then SC_CHARACTER['MinimapButton'] = {} end
    SC.MinimapIcon:Register(addonName, SC.MinimapButtonObject, SC_CHARACTER['MinimapButton'])
end

function SC.TogglePanelLock()
    SC.MovingMode = not SC.MovingMode
    if SC.MovingMode == true then
        for k, panel in pairs(SC.Panels) do
            SC.MakeFrameMovable(panel)
            panel.Title:Show()
            panel.Background:Show()
        end
    elseif SC.MovingMode == false then
        for k, panel in pairs(SC.Panels) do
            SC.LockFramePos(panel)
            panel.Title:Hide()
            panel.Background:Hide()
        end
    end
    for k, panel in pairs(SC.Panels) do
        local point, relativeTo, relativePoint, xOfs, yOfs = panel:GetPoint()
        SC_CHARACTER.Panels[panel.Name].Anchor = point
        SC_CHARACTER.Panels[panel.Name].OffsetX = xOfs
        SC_CHARACTER.Panels[panel.Name].OffsetY = yOfs
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
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetMinMaxValues(20, 80) 
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetValueStep(1)
_G[SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:GetName()..'Low']:SetText('')
_G[SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:GetName()..'High']:SetText('')

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text = SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider:CreateFontString('SCContextMenuCustomFrameEditPanel_IconSize_Slider_Text', 'OVERLAY', 'GameFontNormal')
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetPoint('LEFT', SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider, 'RIGHT', 10, 0)
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetFont("Fonts\\FRIZQT__.TTF", 10)

SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetValue(40)
SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetText(string.format("%.0f", SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:GetValue()))


SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetScript('OnShow', function(self)
    if SC_CHARACTER and SC_CHARACTER.Panels then
        local dropDownListID = self:GetParent():GetParent()['parentLevel']
        local buttonID = self:GetParent():GetParent()['parentID']
        if dropDownListID and buttonID then
            local panel = _G['DropDownList'..dropDownListID..'Button'..buttonID].arg1
            if panel and panel.Name then
                self:SetValue(tonumber(SC_CHARACTER.Panels[panel.Name].Height))
            end
        end
    end
end)


SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.slider:SetScript('OnValueChanged', function(self)
    if SC_CHARACTER and SC_CHARACTER.Panels then
        SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider.text:SetText(string.format("%.0f", self:GetValue()))
        local dropDownListID = self:GetParent():GetParent()['parentLevel']
        local buttonID = self:GetParent():GetParent()['parentID']
        local panel = _G['DropDownList'..dropDownListID..'Button'..buttonID].arg1
        if panel then
            for k, socket in ipairs(panel.Sockets) do
                socket:SetSize(self:GetValue(), self:GetValue())
                socket:SetPoint('BOTTOMLEFT', ((k-1)*self:GetValue()), 0)
            end
            panel:SetSize((#panel.Sockets * self:GetValue()), self:GetValue() + 10)
            if SC_CHARACTER.Panels[panel.Name] then
                SC_CHARACTER.Panels[panel.Name].Width = (#panel.Sockets * self:GetValue())
                SC_CHARACTER.Panels[panel.Name].Height = self:GetValue() -- + 10
            end
        end
    end
end)

function SC.GenerateMinimapContextMenu()
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
    -- if next(SC.Panels) then
    --     for k, panel in pairs(SC.Panels) do
    --         table.insert(editPanel, {
    --             text = k,
    --             arg1 = panel,
    --             arg2 = panel.Name,
    --             hasArrow=true,
    --             notCheckable=true,
    --             menuList = {
    --                 { text = panel.Name, isTitle=true, notCheckable=true, },
    --                 { text = 'Show', arg1=panel, notCheckable=true, keepShownOnClick=true, func=function(self) self.arg1:Show() end, },
    --                 { text = 'Hide', arg1=panel, notCheckable=true, keepShownOnClick=true, func=function(self) self.arg1:Hide() end, },
    --                 { text = 'Delete', arg1=panel, notCheckable=true, func=function(self) self.arg1:Hide() SC.Panels[k] = nil SC_CHARACTER.Panels[k] = nil end, },
    --                 { text = 'Socket size', isTitle=true, notClickable=true, notCheckable=true, },
    --                 { text = ' ', arg1=panel, arg2 = panel.Name, notCheckable=true, customFrame=SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider, },
    --             }
    --         })
    --     end
    -- end
    SC.ContextMenu = {
        { text = 'Simple Cooldowns', isTitle=true, notCheckable=true, },
        { text = 'Toggle panel lock', notCheckable=true, func=SC.TogglePanelLock, keepShownOnClick=true },
        --{ text = SC.ContextMenu_Separator, notCheckable=true, notClickable=true },
        --{ text = 'Panel Options', isTitle=true, notCheckable=true, },
        { text = 'New panel', notCheckable=true, hasArrow=true, menuList=newPanel },
        --{ text = 'Panels', hasArrow=true, notCheckable=true, menuList=editPanel },
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
                    { text = 'Show', arg1=panel, notCheckable=true, keepShownOnClick=true, func=function(self) 
                        self.arg1:Show()
                        if SC_CHARACTER and SC_CHARACTER.Panels[self.arg1.Name] then
                            SC_CHARACTER.Panels[self.arg1.Name]['Display'] = true
                        end
                    end, },
                    { text = 'Hide', arg1=panel, notCheckable=true, keepShownOnClick=true, func=function(self) 
                        self.arg1:Hide() 
                        if SC_CHARACTER and SC_CHARACTER.Panels[self.arg1.Name] then
                            SC_CHARACTER.Panels[self.arg1.Name]['Display'] = false
                        end
                    end, },
                    { text = 'Delete', arg1=panel, notCheckable=true, func=function(self) self.arg1:Hide() SC.Panels[k] = nil SC_CHARACTER.Panels[k] = nil end, },
                    { text = 'Socket size', isTitle=true, notClickable=true, notCheckable=true, },
                    { text = ' ', arg1=panel, arg2 = panel.Name, notCheckable=true, customFrame=SC.ContextMenu_CustomFrame_EditPanel_IconSize_Slider, },
                }
            })
        end
    end
end

function SC.ContextMenu_CreatePanel()
    local numSockets = math.ceil(SC.ContextMenu_CustomFrame_NewPanel_Sockets_Slider.slider:GetValue())
    local sockets = {}
    for i = 1, numSockets do
        table.insert(sockets, {
            Id = tonumber(i), 
            Texture = 132048, 
            SpellId = nil, 
            SpellName = nil, 
            ItemId = nil, 
            ItemName = nil,
        })
    end
    local name = SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:GetText()
    for k, panel in pairs(SC_CHARACTER.Panels) do
        if tostring(k) == tostring(name) then
            name = tostring(GetServerTime())
        end
    end
    if not name then
        name = tostring(GetServerTime())
    end
    local iconSize = SC.ContextMenu_CustomFrame_NewPanel_IconSize_Slider.slider:GetValue()
    iconSize = tonumber(iconSize)
    SC.CreatePanel(name, 'CENTER', (iconSize * numSockets), iconSize, 0, 0, sockets, true)
    SC.ContextMenu_CustomFrame_NewPanel_Editbox.editbox:ClearFocus()
end

----------------------------------------------------------------------------------------------------
-- functions
----------------------------------------------------------------------------------------------------

--currently updating UI and then writing data to saved var, consider writing data and making a refresh func
function SC.UpdateSocket(panel, socket, spellId, itemId) --are spells and items also diff id's? - could merge into 1?
    if spellId ~= nil then
        spellId = tonumber(spellId)
        local spelltexture = select(1, GetSpellTexture(spellId))
        spelltexture = tonumber(spelltexture)
        local spellname = select(1, GetSpellInfo(spellId))
        spellname = tostring(spellname)
        for k, s in ipairs(SC_CHARACTER.Panels[panel.Name].Sockets) do
            if s.Id == socket.Id then
                s.Texture = spelltexture
                s.SpellId = spellId
                s.SpellName = spellname
                s.ItemId = nil
                s.ItemName = nil
            end
        end
        for k, s in ipairs(SC.Panels[panel.Name].Sockets) do
            if s.Id == socket.Id then
                s.Texture:SetTexture(spelltexture)
                s.SpellId = spellId
                s.SpellName = spellname
                s.ItemId = nil
                s.ItemName = nil
            end
        end
    elseif itemId ~= nil then
        itemId = tonumber(itemId)
        local itemname = select(1, GetItemInfo(itemId))
        itemname = tostring(itemname)
        local itemtexture = select(10, GetItemInfo(itemId))
        itemtexture = tonumber(itemtexture)
        for k, s in ipairs(SC_CHARACTER.Panels[panel.Name].Sockets) do
            if s.Id == socket.Id then
                s.Texture = itemtexture
                s.ItemId = itemId
                s.ItemName = itemname
                s.SpellId = nil
                s.SpellName = nil
            end
        end
        for k, s in ipairs(SC.Panels[panel.Name].Sockets) do
            if s.Id == socket.Id then
                s.Texture:SetTexture(itemtexture)
                s.ItemId = itemId
                s.ItemName = itemname
                s.SpellId = nil
                s.SpellName = nil
            end
        end
    end
end


function SC.CreatePanel(name, anchor, width, height, offsetX, offsetY, sockets, display)
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
        local s = CreateFrame('FRAME', tostring("$parentSocket"..k), f)
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
                GameTooltip:AddDoubleLine(tostring(SC.Locales['socket']..' '..self.Id), tostring('|cffffffff'..'drag an item or spell here to set cooldown'))
            end
            GameTooltip:AddLine(' ')
            GameTooltip:AddDoubleLine('|cffA330C9Simple Cooldowns Panel|r', tostring('|cffffffff'..name))
            GameTooltip:AddLine('|cffffffffShift click for menu')
            GameTooltip:Show()
        end)
        s:SetScript('OnMouseUp', function(self, button)
            if button == 'RightButton' and IsShiftKeyDown() then
                SC.GenerateMinimapContextMenu()
                EasyMenu(SC.ContextMenu, SC.ContextMenu_DropDown, "cursor", 0 , 100, "MENU")
            end
        end)
        s:SetScript('OnLeave', function(self)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end)
        s:SetScript('OnReceiveDrag', function(self) --update function built in here?
            local item, a, b, c = GetCursorInfo()
            if item == 'item' then
                itemid = tonumber(a)
                SC.UpdateSocket(f, self, nil, itemid)
            elseif item == 'spell' then
                local spellid = tonumber(c)
                SC.UpdateSocket(f, self, spellid, nil)
            end
            ClearCursor()
        end)
        s.Texture = s:CreateTexture("$parentTexture", 'ARTWORK')
        s.Texture:SetAllPoints(s)
        s.Texture:SetTexture(v.Texture)
        s.UsableOverlay = s:CreateTexture("$parentUsableOverlay", "OVERLAY")
        s.UsableOverlay:SetPoint('TOPLEFT', 2, -2)
        s.UsableOverlay:SetPoint('BOTTOMRIGHT', -2, 2)
        s.UsableOverlay:SetColorTexture(0,0,0,0.6)
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
    SC.Panels[name] = f
    if SC_CHARACTER and SC_CHARACTER.Panels then
        if not SC_CHARACTER.Panels[name] then
            SC_CHARACTER.Panels[name] = {}
            SC_CHARACTER.Panels[name].Name = name
            SC_CHARACTER.Panels[name].Anchor = anchor
            SC_CHARACTER.Panels[name].Width = width
            SC_CHARACTER.Panels[name].Height = height
            SC_CHARACTER.Panels[name].OffsetX = offsetX
            SC_CHARACTER.Panels[name].OffsetY = offsetY
            SC_CHARACTER.Panels[name].Sockets = sockets
            SC_CHARACTER.Panels[name].Display = display
        end
    end
end

----------------------------------------------------------------------------------------------------
-- register events
----------------------------------------------------------------------------------------------------
SC.EventFrame = CreateFrame('FRAME', 'SimpleCooldownsEventFrame', UIParent)
SC.EventFrame:RegisterEvent('ADDON_LOADED')

----------------------------------------------------------------------------------------------------
-- init
----------------------------------------------------------------------------------------------------
function SC.Init()
    if not SC_CHARACTER then 
        SC_CHARACTER = {
            MinimapButton = {},
            Panels = {},
            SpellBook = {},
            Items = {},
        }
    end
    if not SC_GLOBAL then 
        SC_GLOBAL = {
            AddonName = addonName,
        } 
    end
    if not SC_CHARACTER.Panels['Default'] then
        SC_CHARACTER.Panels['Default'] = {
            Name = 'Default',
            Anchor = 'CENTER',
            Width = 200.0,
            Height = 50.0,
            OffsetX = 0.0,
            OffsetY = 0.0,
            Sockets = {
                { Id = 1, Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil },
                { Id = 2, Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil },
                { Id = 3, Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil },
                { Id = 4, Texture = 132048, SpellId = nil, SpellName = nil, ItemId = nil, ItemName = nil }, 
            }
        }
    end
    SC.CreateMinimapButton()
end

function SC.LoadPanels()
    for k, panel in pairs(SC_CHARACTER.Panels) do
        if not SC.Panels[panel.Name] then
            SC.CreatePanel(
                panel.Name, 
                panel.Anchor, 
                panel.Width, 
                panel.Height,
                panel.OffsetX, 
                panel.OffsetY, 
                panel.Sockets,
                panel.Display
            )
        end
    end
end

function SC.OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...):lower() == "simplecooldowns" then
        SC.Print('loaded! To set up cooldowns head to the options interface menu > addons > Simple Cooldowns.')
        SC.Init()
        C_Timer.After(1, SC.LoadPanels)
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