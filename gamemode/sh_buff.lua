-- Matthew Cormack (@johnjoemcbob)
-- 06/08/15
-- Buff/debuff shared information, contains the description of every buff
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

GM.Buffs = {}

table.insert(
	GM.Buffs,
	{
		Name = "Sheltered",
		Description = "Under shelter, protected\nfrom the elements.",
		Icon = "icon16/house.png",
		Time = 0.5, -- Must constantly be re-added by ThinkActivate
		Team = TEAM_HERO,
		Debuff = false,
		ThinkActivate = function( self, ply )
			local tr = util.TraceLine(
				{
					start = ply:GetPos() + Vector( 0, 0, 1 ) * 20,
					endpos = ply:GetPos() + Vector( 0, 0, 1 ) * 400,
					mask = MASK_SOLID_BRUSHONLY
				}
			)
			if ( tr.Hit ) then
				return true
			end
			return false
		end,
		Init = function( self, ply )
			
		end,
		Think = function( self, ply )
			
		end,
		Remove = function( self, ply )
			
		end
	}
)
table.insert(
	GM.Buffs,
	{
		Name = "Soaked",
		Description = "Covered in water,\ncold and slower.",
		Icon = "icon16/weather_rain.png",
		Time = 30,
		Team = TEAM_HERO,
		Debuff = true,
		ThinkActivate = function( self, ply )
			if ( ply:WaterLevel() > 0 ) then
				return true
			end
			return false
		end,
		Init = function( self, ply )
			ply.OldWalkSpeed = ply:GetWalkSpeed()
			ply.OldRunSpeed = ply:GetRunSpeed()
			ply:SetWalkSpeed( ply:GetWalkSpeed() / 2 )
			ply:SetRunSpeed( ply:GetRunSpeed() / 2 )
		end,
		Think = function( self, ply )
			
		end,
		Remove = function( self, ply )
			ply:SetWalkSpeed( ply.OldWalkSpeed )
			ply:SetRunSpeed( ply.OldRunSpeed )
		end
	}
)
table.insert(
	GM.Buffs,
	{
		Name = "Poisoned",
		Description = "Suffering poison damage.",
		Icon = "icon16/bug.png",
		Time = 5,
		Team = TEAM_BOTH,
		Debuff = true,
		ThinkActivate = function( self, ply )
			-- This is mostly activated by spells hitting the player
		end,
		Init = function( self, ply )
			
		end,
		Think = function( self, ply )
			if ( ( not ply.NextPoison ) or ( CurTime() > ply.NextPoison ) ) then
				ply:TakeDamage( 1, ply, ply )
				ply.NextPoison = CurTime() + 0.5
			end
		end,
		Remove = function( self, ply )
			
		end
	}
)
table.insert(
	GM.Buffs,
	{
		Name = "Regeneration",
		Description = "Health is slowly\nregenerating.",
		Icon = "icon16/heart.png",
		Time = 1,
		Team = TEAM_BOTH,
		Debuff = false,
		ThinkActivate = function( self, ply )
			-- This is mostly activated by totems affecting the player
		end,
		Init = function( self, ply )
			
		end,
		Think = function( self, ply )
			if ( ( not ply.NextRegen ) or ( CurTime() > ply.NextRegen ) ) then
				ply:SetHealth( math.Clamp( ply:Health() + 1, 0, ply:GetMaxHealth() ) )
				ply.NextRegen = CurTime() + 0.5
			end
		end,
		Remove = function( self, ply )
			
		end
	}
)
table.insert(
	GM.Buffs,
	{
		Name = "Fire",
		Description = "You are on fire,\nit hurts.",
		Icon = "icon16/fire.png",
		Time = 2.5,
		Team = TEAM_BOTH,
		Debuff = true,
		ThinkActivate = function( self, ply )
			-- This is mostly activated by totems affecting the player
		end,
		Init = function( self, ply )
			
		end,
		Think = function( self, ply )
			if ( ( not ply.NextBurn ) or ( CurTime() > ply.NextBurn ) ) then
				ply:TakeDamage( 1, ply, ply )
				ply.NextBurn = CurTime() + 0.2
			end
		end,
		Remove = function( self, ply )
			
		end
	}
)
table.insert(
	GM.Buffs,
	{
		Name = "Regeneration",
		Description = "Mana is slowly\nregenerating.",
		Icon = "icon16/book.png",
		Time = 1,
		Team = TEAM_BOTH,
		Debuff = false,
		ThinkActivate = function( self, ply )
			-- This is mostly activated by totems affecting the player
		end,
		Init = function( self, ply )
			
		end,
		Think = function( self, ply )
			if ( ( not ply.NextManaRegen ) or ( CurTime() > ply.NextManaRegen ) ) then
				ply:SetMana( math.Clamp( ply:GetMana() + 1, 0, 100 ) )
				ply.NextManaRegen = CurTime() + 0.1
			end
		end,
		Remove = function( self, ply )
			
		end
	}
)
table.insert(
	GM.Buffs,
	{
		Name = "Haste",
		Description = "Spells can be cast\nmore quickly.",
		Icon = "icon16/clock_go.png",
		Time = 0.5,
		Team = TEAM_BOTH,
		Debuff = false,
		ThinkActivate = function( self, ply )
			-- This is mostly activated by totems affecting the player
		end,
		Init = function( self, ply )
			
		end,
		Think = function( self, ply )
			local weapon = ply:GetActiveWeapon()
			weapon:SetNextPrimaryFire( weapon:GetNextPrimaryFire() - FrameTime() * 5 )
			weapon:SetNextSecondaryFire( weapon:GetNextSecondaryFire() - FrameTime() * 5 )
		end,
		Remove = function( self, ply )
			
		end
	}
)