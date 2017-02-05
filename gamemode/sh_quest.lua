-- Matthew Cormack (@johnjoemcbob)
-- 03/12/16
-- Quest shared information, contains the description of every quest
--
-- {
	-- Name = "Sheltered", -- Name for the tooltip
	-- Description = "Under shelter, protected from the elements.", -- Description for the tooltip
	-- Icon = "icon16/house.png", -- Icon to display as the buff's main visuals
	-- Time = 0, -- Times here are in seconds; NOTE - exactly 0.5 flags the client to display a quickly recurring buff (e.g. shelter)
	-- Team = TEAM_BOTH, -- Which team this buff/debuff should affect (TEAM_MONSTER,TEAM_HERO,TEAM_BOTH)
	-- Debuff = false, -- Whether or not this buff should be displayed as a negative buff (debuff)
	-- ThinkActivate = function( self, ply ) -- Run every frame to run logic on adding the buff to the player under certain conditions
		-- return true/false -- Whether or not the buff should be activated
	-- end,
	-- Init = function( self, ply ) -- Run when the buff is first added to the player
		
	-- end,
	-- Think = function( self, ply ) -- Run every frame the buff exists on the player
		
	-- end,
	-- Remove = function( self, ply ) -- Run when the buff is removed from the player
		
	-- end
-- }
--
-- If you want to continue using silk icons, a full list can be found in this image;
-- http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png

GM.Quests = {}

function GetQuestTable( name )
	for k, quest in pairs( GAMEMODE.Quests ) do
		if ( quest.Name == name ) then
			return quest
		end
	end
	return null
end

table.insert(
	GM.Quests,
	{
		Name = "Bounce", -- Must be unique
		Description = "Jump!",
		Icon = "icon16/house.png",
		Time = 0, -- No time limit
		MaxProgress = 10, -- Not required
		Send = { -- Data to send to client
			"Name", -- Always send name to identify this quest
			"Progress"
		},
		ThinkTrigger = function( self, ply ) -- Check for quest triggering (starting)
		
		end,
		Init = function( self, ply ) -- Called when the quest starts
			self.Events = {}
			local event_jump = table.shallowcopy( GAMEMODE.Events[1] )
				event_jump.Callback = function( self, ply )
					print( "Callback override but still " .. self.Name );
				end
			table.insert( self.Events, event_jump )

			self.Progress = 0
		end,
		Think = function( self, ply ) -- Called when the quest is in progress (returns true if status changes)
			if ( SERVER ) then
				if ( self.Events != null and self.Events[1] != null ) then
					local trigger = self.Events[1]:Think( ply )
					if ( trigger ) then
						self.Progress = self.Progress + 1
						print( "Progress: " .. self.Progress )

						if ( self.Progress >= self.MaxProgress ) then
							self:Remove( ply )
						end

						return true
					end
				end

				return false
			end
		end,
		HUDPaint = function( self, data, rect )
			rect = AddRectBorder( rect, 4 )
			rect = QU_Draw_Quest_Title( rect, self.Name )
			rect = QU_Draw_Quest_Space( rect, 4 )
			rect = QU_Draw_Quest_Divider( rect, 2, 75 )
			rect = QU_Draw_Quest_Space( rect, 2 )

			local font = "TargetID"
			local textcolour = Color( 200, 200, 200, 255 )
			draw.DrawText( "Jumps Remaining: " .. ( data.Progress or "N/A" ) .. "/" .. self.MaxProgress, font, rect.x, rect.y, textcolour, TEXT_ALIGN_LEFT )
		end,
		Remove = function( self, ply ) -- Called when the quest is completed
			print( "Quest Success!" )
			self.Removed = true
		end
	}
)

table.insert(
	GM.Quests,
	{
		Name = "Assassinate", -- Must be unique
		Description = "Jump!",
		Icon = "icon16/house.png",
		Time = 0, -- No time limit
		MaxProgress = 10, -- Not required
		Send = { -- Data to send to client
			"Name", -- Always send name to identify this quest
			"Progress"
		},
		ThinkTrigger = function( self, ply ) -- Check for quest triggering (starting)
		
		end,
		Init = function( self, ply ) -- Called when the quest starts
			self.Events = {}
			local event_jump = table.shallowcopy( GAMEMODE.Events[1] )
				event_jump.Callback = function( self, ply )
					
				end
			table.insert( self.Events, event_jump )

			self.Progress = 0
		end,
		Think = function( self, ply ) -- Called when the quest is in progress (returns true if status changes)
			if ( SERVER ) then
				if ( self.Events != null and self.Events[1] != null ) then
					local trigger = self.Events[1]:Think( ply )
					if ( trigger ) then
						self.Progress = self.Progress + 1

						if ( self.Progress >= self.MaxProgress ) then
							self:Remove( ply )
						end

						return true
					end
				end

				return false
			end
		end,
		HUDPaint = function( self, data, rect )
			rect = AddRectBorder( rect, 4 )
			rect = QU_Draw_Quest_Title( rect, self.Name )
			rect = QU_Draw_Quest_Space( rect, 4 )
			rect = QU_Draw_Quest_Divider( rect, 2, 75 )
			rect = QU_Draw_Quest_Space( rect, 2 )

			local font = "TargetID"
			local textcolour = Color( 200, 200, 200, 255 )
			draw.DrawText( "Jumps Remaining: " .. ( data.Progress or "N/A" ) .. "/" .. self.MaxProgress, font, rect.x, rect.y, textcolour, TEXT_ALIGN_LEFT )
		end,
		Remove = function( self, ply ) -- Called when the quest is completed
			self.Removed = true
		end
	}
)
