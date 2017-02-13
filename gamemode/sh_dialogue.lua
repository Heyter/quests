-- Matthew Cormack (@johnjoemcbob)
-- 13/02/17
-- Dialogue shared information

GM.Dialogues = {}

function GetDialogueTable( name )
	for k, dialogue in pairs( GAMEMODE.Dialogues ) do
		if ( dialogue.Name == name ) then
			return dialogue
		end
	end
	return nil
end

table.insert(
	GM.Dialogues,
	{
		Name = "TEST", -- Must be unique
		Description = "Testing dialogue system",
		MessageID = "INTRO", -- Start dialogue at intro

		DialogueTree = {
			Messages = { -- NPC messages to players
				["INTRO"] = { -- ID internal to only this dialogue tree (INTRO is the default introduction to the dialogue unless another is stated)
					Text = "Hey there",
					OptionIDs = { "HI", "BYE" },
				},
				["2"] = {
					Text = "Would you mind jumping for me?",
					OptionIDs = { "JUMP_YES", "BYE" },
				},
			},
			Options = { -- Player responses to NPCs
				["HI"] = {
					Text = "Hello",
					NextMessageID = "2", -- Which message to move onto after this response
					OptionAvailable = function() -- Returns true if this option is available to this player
						return true
					end,
					Callback = function( ply ) -- Called when this dialogue option is selected by the player
						print( "Player said hello" )
					end,
				},
				["BYE"] = {
					Text = "I've got to go, bye!",
					NextMessageID = nil, -- Which message to move onto after this response (nil means the dialogue is over)
					OptionAvailable = function() -- Returns true if this option is available to this player
						return true
					end,
					Callback = function( ply ) -- Called when this dialogue option is selected by the player
						print( "Player said bye" )
					end,
				},
				["JUMP_YES"] = {
					Text = "Sure, watch this!",
					NextMessageID = nil, -- Which message to move onto after this response (nil means the dialogue is over)
					OptionAvailable = function() -- Returns true if this option is available to this player
						return true
					end,
					Callback = function( ply ) -- Called when this dialogue option is selected by the player
						AddQuest( ply, "Bounce" )
					end,
				},
			},
		},
		Send = {
			"Name",
			"MessageID",
		},

		Init = function( self, ply ) -- Called when the dialogue starts
			self.Events = {}
			local event_jump = table.shallowcopy( GAMEMODE.Events[1] )
				event_jump.Callback = function( self, ply )
					print( "Callback override but still " .. self.Name );
				end
			table.insert( self.Events, event_jump )

			self.Progress = 0
		end,
		Think = function( self, ply ) -- Called when the dialogue is in progress (returns true if status changes)
			if ( SERVER ) then
				if ( self.Events != nil and self.Events[1] != nil ) then
					
				end

				return false
			end
		end,
		HUDPaint = function( self, data, rect )
			QU_Draw_Dialogue_Default( self, data, rect )
		end,
		Remove = function( self, ply ) -- Called when the dialogue is completed
			print( "Dialogue complete!" )
			self.Removed = true
		end
	}
)
