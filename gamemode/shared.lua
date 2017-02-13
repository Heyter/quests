-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 02/08/15
-- Main shared info/logic
-- Mostly contains changes to fretta base settings

DeriveGamemode( "Sandbox" )

include( "sh_buff.lua" )
include( "sh_event.lua" )
include( "sh_quest.lua" )
include( "sh_dialogue.lua" )

GM.Name		= "Quests"
GM.Author 	= "Matthew Cormack (@johnjoemcbob)"
GM.Email		= ""
GM.Website 	= "www.johnjoemcbob.com"
GM.Help		= "No Help Available"

function AddRectBorder( rect, border )
	rect.x = rect.x + border
	rect.y = rect.y + border
	rect.Width = rect.Width - ( border * 2 )
	rect.Height = rect.Height - ( border * 2 )
	return rect
end