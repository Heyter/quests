-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 02/08/15
-- Main clientside logic

include( "shared.lua" )
include( "cl_hud.lua" )
include( "cl_buff.lua" )

-- Initialization of this message is contained within class/hero.lua
net.Receive( "DC_Client_Ghost", function( len )
	local entid = net.ReadFloat()
	local ghost = net.ReadBit() == 1

	if ( not LocalPlayer().OtherGhosts ) then return end

	-- Custom logic if the ghost is self
	if ( LocalPlayer():EntIndex() == entid ) then
		LocalPlayer().Ghost = ghost
		LocalPlayer():SetCustomCollisionCheck( ghost )
	end

	-- Otherwise store for player ring/halo rendering
	LocalPlayer().OtherGhosts[entid] = ghost
end )

function GM:Initialize()
	self.BaseClass:Initialize()

	-- Used to precache the buff icons, function located within cl_buff.lua
	self:Initialize_Buffs()
end

function GM:InitPostEntity()
	self.BaseClass:InitPostEntity()

	-- Used to setup the control point map, function located within cl_hud.lua
	self:InitPostEntity_HUD()

	-- Store the ghost status of each entity id representing a player
	LocalPlayer().OtherGhosts = {}
end

function GM:Think()
	self.BaseClass:Think()

	self:Think_HUD()
end

-- Setup view model hands for cast weapon
hook.Add( "PostDrawViewModel", "DC_PostDrawViewModel_Hands", function( vm, ply, weapon )
	if ( weapon.UseHands or ( not weapon:IsScripted() ) ) then
		local hands = LocalPlayer():GetHands()
		if ( IsValid( hands ) ) then
			hands:DrawModel()
		end
	end
end )

-- Setup hero halo outlines for monster players
hook.Add( "PreDrawHalos", "DC_PreDrawHalos", function()
	if ( not LocalPlayer().OtherGhosts ) then return end

	-- Ensure the ghost table exists
	if ( not LocalPlayer().OtherGhosts ) then
		-- Store the ghost status of each entity id representing a player
		LocalPlayer().OtherGhosts = {}
	end

	if ( not LocalPlayer().HaloPulse ) then
		LocalPlayer().HaloPulse = 1
		LocalPlayer().HaloPulseTarget = 15
	else
		local speed = FrameTime() * 10
			if ( LocalPlayer().HaloPulse == LocalPlayer().HaloPulseTarget ) then
				LocalPlayer().HaloPulseTarget = -LocalPlayer().HaloPulseTarget
			end
			if ( LocalPlayer().HaloPulseTarget < LocalPlayer().HaloPulse ) then
				speed = -speed
			end
		LocalPlayer().HaloPulse = math.Approach( LocalPlayer().HaloPulse, LocalPlayer().HaloPulseTarget, speed )
	end

	for k, ply in pairs( player.GetAll() ) do
		if ( ply:Team() == TEAM_HERO ) then
			-- Only draw hero outlines if;
			--		You are a monster
			--		You are a ghost
			--		The hero is a ghost
			if (
				( LocalPlayer():Team() == TEAM_MONSTER ) or
				( LocalPlayer().Ghost )
			) then
				halo.Add( { ply }, Color( 0, 0, 255 ), LocalPlayer().HaloPulse, LocalPlayer().HaloPulse, 2, true, true )
			end
			if ( LocalPlayer().OtherGhosts[ply:EntIndex()] ) then
				halo.Add( { ply }, Color( 150, 150, 255 ), LocalPlayer().HaloPulse, LocalPlayer().HaloPulse, 2, true, true )
			end
		elseif ( ply:Team() == TEAM_MONSTER ) then
			-- Only draw monster outlines if;
			--		You are a monster
			if ( LocalPlayer():Team() == TEAM_MONSTER ) then
				halo.Add( { ply }, Color( 255, 0, 0 ), LocalPlayer().HaloPulse, LocalPlayer().HaloPulse, 2, true, true )
			end
		end
	end
end )

-- Overwrite base fretta team rings to only display to players on the same team
local CircleMat = Material( "SGM/playercircle" );

function GM:DrawPlayerRing( pPlayer )
	if ( not LocalPlayer().OtherGhosts ) then return end

	if ( !IsValid( pPlayer ) ) then return end				-- Player isn't valid
	if (
		( not pPlayer:GetNWBool( "DrawRing", false ) ) or	-- Shouldn't draw the ring
		( not pPlayer:Alive() ) or							-- Isn't alive
		( pPlayer:Team() ~= LocalPlayer():Team() ) or		-- Isn't on the same team
		( LocalPlayer().Ghost ) or							-- Self is a ghost
		( LocalPlayer().OtherGhosts[pPlayer:EntIndex()] )	-- Target is a ghost
	) then
		return
	end

	local trace = {}
	trace.start 	= pPlayer:GetPos() + Vector(0,0,50)
	trace.endpos 	= trace.start + Vector(0,0,-300)
	trace.filter 	= pPlayer
	
	local tr = util.TraceLine( trace )
	
	if not tr.HitWorld then
		tr.HitPos = pPlayer:GetPos()
	end

	local color = table.Copy( team.GetColor( pPlayer:Team() ) )
	color.a = 40;

	render.SetMaterial( CircleMat )
	render.DrawQuadEasy( tr.HitPos + tr.HitNormal, tr.HitNormal, GAMEMODE.PlayerRingSize, GAMEMODE.PlayerRingSize, color )

	return false
end