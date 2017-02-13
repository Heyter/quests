-- Matthew Cormack (@johnjoemcbob)
-- 04/02/17
-- Main clientside quest visuals

-- Initialization of this message is contained within sv_quest.lua
net.Receive( "QU_Quest_Progress", function( len )
	local quest = net.ReadTable()

	-- Store the quest information on the player for rendering
	print( "Client received quest: " .. quest.Name )
	local found = false
	if ( LocalPlayer().Quests == null ) then
		LocalPlayer().Quests = {}
	else
		for k, oldquest in pairs( LocalPlayer().Quests ) do
			if ( oldquest.Name == quest.Name ) then
				LocalPlayer().Quests[k] = quest
				found = true

				-- Check for flag to delete (old name sent)
				print( table.length( quest ) )
				if ( table.length( quest ) == 1 ) then
					table.remove( LocalPlayer().Quests, k )
				end
				break
			end
		end
	end
	if ( !found ) then
		table.insert( LocalPlayer().Quests, quest )
	end
end )

-- Display quest info
function GM:HUDPaint_Quests()
	local width = ScrW() / 8
	local height = ScrH() / 20
	local x = ScrW() - width
	local y = ( ScrH() / 4 ) - ( height / 2 )
	local borderdivision = height / 10

	local count = 0
	local max = 4

	if ( LocalPlayer().Quests != null ) then
		for k, questdata in pairs( LocalPlayer().Quests ) do
			y = y + height + borderdivision

			-- Draw quest outline
			draw.RoundedBox(
				0,
				x, y,
				width, height,
				Color( 181, 140, 50, 200 )
			)

			-- Draw specific quest information
			local questtable = GetQuestTable( questdata.Name )
			questtable:HUDPaint( questdata, { x = x, y = y, Width = width, Height = height } )

			-- Maximum number of quests displayed
			count = count + 1
			if ( count > max ) then
				break
			end
		end
	end
end

-- rect = { x, y, Width, Height }
function QU_Draw_Quest_Title( rect, name )
	local font = "TargetID"
	local textcolour = Color( 100, 50, 200, 255 )

	draw.DrawText( name, font, rect.x, rect.y, textcolour, TEXT_ALIGN_LEFT )

	return QU_Draw_Quest_CalcNewRect( rect, draw.GetFontHeight( font ) )
end

-- rect = { x, y, Width, Height }
-- size = percentage of total rect width
function QU_Draw_Quest_Divider( rect, height, size )
	draw.RoundedBox(
		0,
		rect.x, rect.y,
		rect.Width / 100 * size, height,
		Color( 0, 0, 0, 50 )
	)

	return QU_Draw_Quest_CalcNewRect( rect, height )
end

-- rect = { x, y, Width, Height }
function QU_Draw_Quest_Space( rect, height )
	return QU_Draw_Quest_CalcNewRect( rect, height )
end

-- rect = { x, y, Width, Height }
function QU_Draw_Quest_CalcNewRect( rect, height )
	rect.y = rect.y + height
	rect.Height = rect.Height - height
	return rect
end
