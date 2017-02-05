-- Matthew Cormack (@johnjoemcbob)
-- 04/02/17
-- Quest serverside logic
--

-- Sends to cl_quest.lua
util.AddNetworkString( "QU_Quest_Progress" )

function SendQuest( ply, index )
	net.Start( "QU_Quest_Progress" )
		local send = table.shallowcopy( ply.Quests[index] )
			-- Check each index against whitelist and remove fails
			for element, v in pairs( send ) do
				local found = false
				for k, whitelist in pairs( ply.Quests[index].Send ) do
					if ( element == whitelist ) then
						found = true
					end
				end
				if ( !found ) then
					send[element] = null
				end
			end
		net.WriteTable( send )
	net.Send( ply )
end

function SendRemoveQuest( ply, name )
	net.Start( "QU_Quest_Progress" )
		net.WriteTable( { Name = name } )
	net.Send( ply )
end

function AddQuest( ply, name )
	if ( ply.Quests == null ) then
		ply.Quests = {}
	end

	for k, quest in pairs( GAMEMODE.Quests ) do
		if ( quest.Name == name ) then
			table.insert( ply.Quests, table.shallowcopy( quest ) )
			ply.Quests[#ply.Quests]:Init( ply )
			SendQuest( ply, #ply.Quests )
			print( "Add Quest: " .. name )
		end
	end
end

function RemoveQuest( ply, name )
	SendRemoveQuest( ply, name )
end
