

local addonName, SC = ...

-- this file is to be done if the addon grows in popularity

local L = {}
L['panel'] = 'Panel'
L['socket'] = 'Socket'


local locale = GetLocale()

if locale == "deDE" then
    L['panel'] = ''
    L['socket'] = ''
end

SC.Locales = L