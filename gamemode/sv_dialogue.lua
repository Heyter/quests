-- Matthew Cormack (@johnjoemcbob)
-- 13/02/17
-- Dialogue serverside logic
--

-- Sends to cl_dialogue.lua
util.AddNetworkString( "QU_Dialogue_Progress" )

function SendDialogue( ply, name )
	net.Start( "QU_Dialogue_Progress" )
		local send = table.shallowcopy( ply.Dialogues[name] )
			-- Check each index against whitelist and remove fails
			for element, v in pairs( send ) do
				local found = false
				for k, whitelist in pairs( ply.Dialogues[name].Send ) do
					if ( element == whitelist ) then
						found = true
					end
				end
				if ( !found ) then
					send[element] = nil
				end
			end
		net.WriteTable( send )
	net.Send( ply )
end

-- Receives from cl_dialogue.lua
util.AddNetworkString( "QU_Dialogue_Option" )

net.Receive( "QU_Dialogue_Option", function( len, ply )
	-- Player must have a table of dialogues (otherwise what is this message refering to)
	if ( ply.Dialogues == nil ) then return end

	local dialogue = net.ReadTable()
	local id = dialogue.OptionID
	local name = dialogue.Name
	print( "Server received client choice; " .. id .. " in " .. name )

	-- Player must be in the specified dialogue (otherwise what is this message refering to)
	if ( ply.Dialogues[name] == nil ) then return end

	-- Check that the option selected exists in the current message (don't trust player)
	local containsoption = false
		for k, option in pairs( ply.Dialogues[name].DialogueTree.Messages[ply.Dialogues[name].MessageID].OptionIDs ) do
			if ( option == id ) then
				containsoption = true
				break
			end
		end
	if ( containsoption ) then
		-- Check that the option selected is available to the client (don't trust player)
		local option = ply.Dialogues[name].DialogueTree.Options[id]
		if ( option.OptionAvailable() ) then
			-- Callback for message happening
			option.Callback( ply )
			-- Check for dialogue removed flag
			if ( option.NextMessageID == nil ) then
				ply.Dialogues[name] = nil
				SendRemoveDialogue( ply, name )
				return
			end
			-- Set next part of dialogue and update player
			ply.Dialogues[name].MessageID = option.NextMessageID
			SendDialogue( ply, name )
		end
	end
end )

function SendRemoveDialogue( ply, name )
	net.Start( "QU_Dialogue_Progress" )
		net.WriteTable( { Name = name } )
	net.Send( ply )
end

function AddDialogue( ply, name )
	if ( ply.Dialogues == nil ) then
		ply.Dialogues = {}
	end

	for k, dialogue in pairs( GAMEMODE.Dialogues ) do
		if ( dialogue.Name == name ) then
			ply.Dialogues[name] = table.shallowcopy( dialogue )
			ply.Dialogues[name]:Init( ply )
			SendDialogue( ply, name )
			print( "Add Dialogue: " .. name )
		end
	end
end

function RemoveDialogue( ply, name )
	SendRemoveDialogue( ply, name )
end
