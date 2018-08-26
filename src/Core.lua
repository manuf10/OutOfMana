-- If you like the addon you can support the creator sending two coins of gold to Sabio!
-- 1% of the raised gold will be donated to the local gnomish orphanage

local default_list = { }

OutOfMana = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDebug-2.0")
roster = AceLibrary("RosterLib-2.0")

SLASH_OUTOFMANA1 = '/oomaddon';

function OutOfMana:formatName(name)
    name = string.lower(name)
    local formattedName,_ = string.gsub(name, "^%l", string.upper)
    return formattedName
end

local mifontRed = "|cffff0000"
local mifontGreen = "|cff00ff00"
local mifontWhite = "|cffffffff"
local mifontSubWhite = "|cffbbbbbb"
local mifontLightBlue = "|cff00e0ff"
local mifontYellow  = "|cffffff00"

local function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

local function handler(msg, editbox)
    local words = OutOfMana:split(msg, " ")
    local command = words[1]

    if command == "help" then
        OutOfMana:ShowHelp()
    elseif command == "clear" then
        OOMHealersList = {}
        OutOfMana:Print(mifontSubWhite .. "The entire list was erased.")
    elseif command == "remove" then
        local healers_removed = 0
        for i = 2, table.getn(words) do  
            local remove_healer = OutOfMana:formatName(words[i])
            if OutOfMana:has_value(OOMHealersList, remove_healer) then
                table.remove(OOMHealersList, tablefind(OOMHealersList, remove_healer))
                healers_removed = healers_removed + 1 
            end
        end       
        OutOfMana:Print(mifontRed .. healers_removed .. mifontWhite .. " healers were removed from the list." .. mifontSubWhite .. " Type \"/oomaddon list\" if you want to see the entire list.")
	elseif command == "add" then
        local healers_added = 0
        for i = 2, table.getn(words) do  
            local new_healer = OutOfMana:formatName(words[i])
            if not OutOfMana:has_value(OOMHealersList, new_healer) then
                table.insert(OOMHealersList, new_healer)
                healers_added = healers_added + 1 
            end
        end       
        OutOfMana:Print(mifontGreen ..healers_added .. mifontWhite .. " new healers were added to the list." .. mifontSubWhite .. " Type \"/oomaddon list\" if you want to see the entire list.")

    -- /oomaddon showlist will write the mana % in chat
    elseif command == "list" then
        OutOfMana:ShowList()

    -- /oomaddon mana will write the mana % in chat
	elseif command == "saymana" then
		OutOfMana:ShowPercentage(true)
    elseif command == "mana" then
		OutOfMana:ShowPercentage(false)
	end
end
SlashCmdList["OUTOFMANA"] = handler;

function OutOfMana:OnEnable()
	roster:ScanFullRoster()
    if OOMHealersList == nil then
        OOMHealersList = default_list
    end
    self:Print("Ready to use. " .. mifontYellow .. "Type /ooomaddon help to see the commands available.")
end

function OutOfMana:ShowHelp()
    OutOfMana:Print("/oomaddon add Name1 Name2 NameN" .. mifontSubWhite .. "\nExample: /oomaddon add Auroro Ryrorin")
    OutOfMana:Print("/oomaddon remove Name1 Name2 NameN" .. mifontSubWhite .. "\nExample: /oomaddon remove Auroro Ryrorin")
    OutOfMana:Print("/oomaddon list" .. mifontSubWhite .. " Shows the full list in chat.")
    OutOfMana:Print("/oomaddon clear" .. mifontSubWhite .. " Clears the entire list.")
    OutOfMana:Print("/oomaddon mana" .. mifontLightBlue .. " Shows mana percentage in your chat window only.")
    OutOfMana:Print("/oomaddon saymana" .. mifontLightBlue .. " Says mana percentage in party/raid chat.") 
end

function OutOfMana:ShowPercentage(send_group)
	local total_mana = 0
	local current_mana = 0
	local count = 0
    local count_alives = 0
	for i,name in pairs(OOMHealersList) do
    	local unitID = roster:GetUnitIDFromName(name)
    	if unitID then
	    	local unitObject = roster:GetUnitObjectFromUnit(unitID)
	    	if unitObject.online then
	    		count = count + 1
                if not UnitIsDeadOrGhost(unitID) then
                    count_alives = count_alives + 1
                end
	    		total_mana = total_mana + UnitManaMax(unitID)
                current_mana = current_mana + UnitMana(unitID)
	    	end
	    end
    end

    local channel = "PARTY"
    if UnitInRaid("player") == 1 then
        channel = "RAID"
    end

    if count > 0 then
        local percentage = current_mana * 100 / total_mana
        if count == count_alives then
            if count_alives == 0 then
                self:Print("There are no healers alive!")
            else
                if send_group then
                    SendChatMessage("Healers MANA: " .. math.floor(percentage) .. "% (" .. count ..  " healers found)" , channel, "COMMON", nil);
                else
                    self:Print("Healers MANA: " .. math.floor(percentage) .. "% (" .. count ..  " healers found)")
                end
            end
        else
            if send_group then
                SendChatMessage("Healers MANA: " .. math.floor(percentage) .. "% (Alive: " ..  count_alives 
                    .. ". Dead: " .. count - count_alives .. ")" , channel, "COMMON", nil);
            else
                self:Print("Healers MANA: " .. math.floor(percentage) .. "% (Alive: " ..  count_alives 
                    .. ". Dead: " .. count - count_alives .. ")")
            end
        end
    else
        self:Print("Your list is empty OR none of the listed healers were found in your raid!")
    end
end

-- Writes in chat all the healers ordered alphabetically
function OutOfMana:ShowList()
    local count = OutOfMana:tablelength(OOMHealersList)
    
    if count == 0 then
        self:Print("Your healers list is empty!")
    else
        table.sort(OOMHealersList, sort_alphabetically_func)
        self:Print("There are " .. mifontGreen .. OutOfMana:tablelength(OOMHealersList) .. mifontWhite .. " healers in your list.")
        local message = ""
        for i,name in pairs(OOMHealersList) do
            if i == 1 then
                message = name
            else
                message = message .. ", " .. name
            end
        end
        self:Print(message .. ".")
    end
end

local sort_alphabetically_func = function(name1, name2) return name1 < name2 end

local function strsplit(delim, str, maxNb, onlyLast)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb+1] = string.sub(str, lastPos)
    end
    if onlyLast then
        return result[nb+1]
    else
        return result[1], result[2]
    end
end

function OutOfMana:tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function OutOfMana:split(str, separator)
	local parts = {}
	while true do
		local start_index = strfind(str, separator, 1, true)
		if start_index then
			local part = strsub(str, 1, start_index - 1)
			tinsert(parts, part)
			str = strsub(str, start_index + 1)
		else
			local part = strsub(str, 1)
			tinsert(parts, part)
			return parts
		end
	end
end

function OutOfMana:has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end