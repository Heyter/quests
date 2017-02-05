-- Matthew Cormack (@johnjoemcbob)
-- 04/02/17
-- Event triggers, which can be used as quest logic
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

GM.Events = {}

table.insert(
	GM.Events,
	{
		Name = "Jump",
		Description = "Triggered when the player jumps",
		Icon = "icon16/house.png",
		Think = function( self, ply ) -- Check for event triggering (may be null and instead be manually called)
			if ( ply:KeyPressed( IN_JUMP ) ) then
				self:Callback( ply )
				return true
			end

			return false
		end,
		Callback = function( self, ply ) -- Callback when event is triggered
			print( "Event Triggered: " .. self.Name )
		end
	}
)
