-- Matthew Cormack (@johnjoemcbob)
-- 13/02/17
-- Main clientside dialogue visuals

local DialogueWidthRatio = 1 / 4
local DialogueHeightRatio = 1 / 3

-- Initialization of this message is contained within sv_dialogue.lua
net.Receive( "QU_Dialogue_Progress", function( len )
	local dialogue = net.ReadTable()

	-- Store the dialogue information on the player for rendering
	print( "Client received dialogue: " .. dialogue.Name )
	local found = false
	if ( LocalPlayer().Dialogues == nil ) then
		LocalPlayer().Dialogues = {}
		LocalPlayer().DialoguePanels = {}
	else
		for k, olddialogue in pairs( LocalPlayer().Dialogues ) do
			if ( olddialogue.Name == dialogue.Name ) then
				LocalPlayer().Dialogues[k] = dialogue
				found = true

				-- Check for flag to delete (old name sent)
				print( table.length( dialogue ) )
				if ( table.length( dialogue ) == 1 ) then
					table.remove( LocalPlayer().Dialogues, k )
					LocalPlayer().DialoguePanels[dialogue.Name]:Remove()
					return
				end
				break
			end
		end
	end
	if ( !found ) then
		table.insert( LocalPlayer().Dialogues, dialogue )
	end
	local dialoguetable = GetDialogueTable( dialogue.Name )
	dialoguetable:HUDPaint( dialogue, { x = x, y = y, Width = width, Height = height } )
end )

function QU_Dialogue_ClickOption( dialogue, id )
	print( "Clicked option " .. id .. " in " .. dialogue.Name )

	local option = { OptionID = id, Name = dialogue.Name }
	net.Start( "QU_Dialogue_Option" )
		net.WriteTable( option )
	net.SendToServer()
end

-- rect = { x, y, Width, Height }
function QU_Draw_Dialogue_Default( dialogue, data, rect )
	if ( LocalPlayer().DialoguePanels == nil ) then
		LocalPlayer().DialoguePanels = {}
	end

	-- Try to load frame or create new
	local frame = LocalPlayer().DialoguePanels[data.Name]
	if ( frame == nil or not frame:IsValid() ) then
		frame = vgui.Create( "DFrame" )
		frame:SetTitle( "" )
		frame:ShowCloseButton( false )
		frame:SetSize( ScrW() * DialogueWidthRatio, ScrH() * DialogueHeightRatio )
		frame:Center()
		frame:MakePopup()
		frame.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
			draw.RoundedBox( 0, 0, 0, w, h, Color( 231, 76, 60, 150 ) ) -- Draw a red box instead of the frame
		end
		frame.Children = {}
		LocalPlayer().DialoguePanels[data.Name] = frame
	end

	-- Clear old children
	for k, child in pairs( LocalPlayer().DialoguePanels[data.Name].Children ) do
		child:Remove()
	end
	LocalPlayer().DialoguePanels[data.Name].Children = {}

	-- Draw message
	local label = vgui.Create( "DLabel", frame )
	label:SetText( dialogue.DialogueTree.Messages[data.MessageID].Text )
	label:SetTextColor( Color( 255, 255, 255 ) )
	label:SetPos( 100, 30 )
	label:SetSize( 100, 30 )
	table.insert( LocalPlayer().DialoguePanels[data.Name].Children, label )

	-- Draw options
	local y = 100
	local dist = 40
	local options = dialogue.DialogueTree.Messages[data.MessageID].OptionIDs
	for k, option in pairs( options ) do
		local button = vgui.Create( "DButton", frame )
		button:SetText( dialogue.DialogueTree.Options[option].Text )
		button:SetTextColor( Color( 255, 255, 255 ) )
		button:SetPos( 100, y )
		button:SetSize( 100, 30 )
		button.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 250 ) ) -- Draw a blue button
		end
		button.DoClick = function()
			QU_Dialogue_ClickOption( dialogue, option )
		end
		y = y + dist
		table.insert( LocalPlayer().DialoguePanels[data.Name].Children, button )
	end
end
