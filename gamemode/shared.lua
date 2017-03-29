-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 02/08/15
-- Main shared info/logic
-- Mostly contains changes to fretta base settings

DeriveGamemode( "Sandbox" )

include( "sh_buff.lua" )
include( "sh_event.lua" )
include( "sh_quest.lua" )
include( "sh_dialogue.lua" )
include( "sh_model.lua" )

GM.Name		= "Quests"
GM.Author 	= "Matthew Cormack (@johnjoemcbob)"
GM.Email	= ""
GM.Website 	= "www.johnjoemcbob.com"
GM.Help		= "No Help Available"

local function includerecurse( dir, localdir )
	local files, directories = file.Find( dir .. localdir .. "*", "GAME" )
	for k, file in pairs( files ) do
		if ( string.find( file, ".lua" ) ) then
			include( localdir .. file )
		end
	end
	for k, subdir in pairs( directories ) do
		includerecurse( dir, localdir .. subdir .. "/" )
	end
end

includerecurse( "gamemodes/quests/gamemode/", "model/" )

function AddRectBorder( rect, border )
	rect.x = rect.x + border
	rect.y = rect.y + border
	rect.Width = rect.Width - ( border * 2 )
	rect.Height = rect.Height - ( border * 2 )
	return rect
end

-- Make a shallow copy of a table (from http://lua-users.org/wiki/CopyTable)
function table.shallowcopy( orig )
    local orig_type = type( orig )
    local copy
    if ( orig_type == "table" ) then
        copy = {}
        for orig_key, orig_value in pairs( orig ) do
            copy[orig_key] = orig_value
        end
	-- Number, string, boolean, etc
    else
        copy = orig
    end
    return copy
end
