-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 02/08/15
-- Main serverside logic

AddCSLuaFile( "cl_buff.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "sh_buff.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "sv_buff.lua" )

-- Sends to cl_hud.lua
util.AddNetworkString( "DC_Client_Round" )

local LastRoundInfo = {}
function SendClientRoundInformation( textenum, endtime )
	for k, ply in pairs( player.GetAll() ) do
		if ( ply.MessagesReceived ) then
			ply.MessagesReceived["DC_Client_Round"] = nil
		end
	end

	-- Store last message sent
	LastRoundInfo.Text = textenum
	LastRoundInfo.Time = CurTime() + endtime

	-- Send the round information enum (can be looked up within shared.lua)
	net.Start( "DC_Client_Round" )
		net.WriteFloat( textenum )
		net.WriteFloat( endtime )
	net.Broadcast()

	-- Resend this information if it hasn't been replied to
	if ( not timer.Exists( "DC_Client_Round" ) ) then
		timer.Create( "DC_Client_Round", 0.5, 1, function()
			for k, ply in pairs( player.GetAll() ) do
				if ( ( not ply.MessagesReceived ) or ( not ply.MessagesReceived["DC_Client_Round"] ) ) then
					-- Repeat until the client receives it
					SendClientRoundInformation( LastRoundInfo.Text, LastRoundInfo.Time - CurTime() )
				end
			end
		end )
	end
end
net.Receive( "DC_Client_Round", function( len, ply )
	if ( not ply.MessagesReceived ) then
		ply.MessagesReceived = {}
	end
	ply.MessagesReceived["DC_Client_Round"] = true
end )

function GM:Initialize()
	self.BaseClass:Initialize()
end

function GM:InitPostEntity()
	self.BaseClass:InitPostEntity()
end

function GM:SpawnMapItems()
	-- Remove all trap doors
	local removeent = {
		-- Landebrin Keep
		491,
		492,
		493,
		-- Grilleau Keep
		496,
		209,
		217,
	}
	for k, ent in pairs( removeent ) do
		ents.GetByIndex( ent ):Remove()
	end

	-- Load trigger positions and other data from sh_controlpoints.lua
	if ( self.ControlPoints[game.GetMap()] ) then
		for k, v in pairs( self.ControlPoints[game.GetMap()] ) do
			v.Entity = ents.Create( "dc_trigger_control" )
				v.Entity:SetPos( v.Position )
				v.Entity.StartPos = v.Start
				v.Entity.EndPos = v.End
				v.Entity.ID = k
				v.Entity.ZoneName = v.Title
				v.Entity.Type = v.Type
				v.Entity.CaptureSpeed = v.CaptureSpeed
				if ( v.PrecedingPoint >= 1 ) then
					v.Entity.PrecedingPoint = self.ControlPoints[game.GetMap()][v.PrecedingPoint].Entity
				end
			v.Entity:Spawn()
		end
	end

	-- Load chest locations from sh_chests.lua
	if ( self.Chests[game.GetMap()] ) then
		for k, v in pairs( self.Chests[game.GetMap()] ) do
			v.Entity = ents.Create( v.Type )
				v.Entity:SetPos( v.Position )
				v.Entity:SetAngles( v.Angle )
				v.Entity.PrecedingPoint = v.PrecedingPoint
				v.Entity.Level = v.Level
			v.Entity:Spawn()
		end
	end

	-- Spawn spell altars on the map
	for k, v in pairs( self.AltarSpawns ) do
		v.Entity = ents.Create( "dc_altar" )
			v.Entity:SetPos( v.Position )
			v.Entity:SetAngles( v.Rotation )
		v.Entity:Spawn()
	end
end

function GM:Think()
	self.BaseClass:Think()

	-- Used to update buffs on players, function located within sv_buff.lua
	self:Think_Buff()
end

function GM:PlayerSwitchFlashlight( ply, on )
	return not on
end

function GM:PlayerInitialSpawn( ply )
	self.BaseClass:PlayerInitialSpawn( ply )

	-- Used to initialize the player buff table, function located within sv_buff.lua
	self:PlayerInitialSpawn_Buff( ply )
end

function GM:PlayerSpawn( ply )
	self.BaseClass:PlayerSpawn( ply )

	-- Reset any buffs affecting the player
	for k, buff in pairs( self.Buffs ) do
		ply:RemoveBuff( k )
	end

	-- No players can zoom in this gamemode
	ply:SetCanZoom( false )
end

function GM:PostPlayerDeath( ply )

end

function GM:PlayerDisconnected( ply )
	self.BaseClass:PlayerDisconnected( ply )
end

function GM:PlayerShouldTakeDamage( ply, attacker )
	return self.BaseClass:PlayerShouldTakeDamage( ply, attacker )
end

function GM:GetFallDamage( ply, flFallSpeed )
	-- This can be used to flag never to inflict fall damage on a player or to make them invulnerable a specified number of times
	if ( ply.NoFallDamage == -1 ) then return end
	if ( ply.Ghost ) then return end
	if ( ply.NoFallDamage and ( ply.NoFallDamage > 0 ) ) then
		ply.NoFallDamage = ply.NoFallDamage - 1
		return
	end

	if ( self.RealisticFallDamage ) then
		return flFallSpeed / 8
	end

	return 10
end

-- Don't kill players if they are standing on the spawn point, some maps (i.e. rp_harmonti) only have one spawn
-- Also, players will be moved to the appropriate area after spawning
function GM:IsSpawnpointSuitable( ply, spawnpointent, bMakeSuitable )
	local pos = spawnpointent:GetPos()

	-- Note that we're searching the default hull size here for a player in the way of our spawning.
	-- This seems pretty rough, seeing as our player's hull could be different.. but it should do the job
	-- ( HL2DM kills everything within a 128 unit radius )
	local entsinrange = ents.FindInBox( pos + Vector( -16, -16, 0 ), pos + Vector( 16, 16, 72 ) )

	if ( ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED ) then return true end

	local blockers = 0
	for k, v in pairs( entsinrange ) do
		if ( IsValid( v ) && v:GetClass() == "player" && v:Alive() ) then
			blockers = blockers + 1
		end
	end

	if ( blockers > 0 ) then return false end
	return true
end

-- Make a shallow copy of a table (from http://lua-users.org/wiki/CopyTable)
function table.shallowcopy( orig )
    local orig_type = type( orig )
    local copy
    if ( orig_type == "table" ) then
        copy = {}
        for orig_key, orig_value in pairs( orig ) do
            copy[orig_key] = orig_value
        end
	-- Number, string, boolean, etc
    else
        copy = orig
    end
    return copy
end

hook.Add( "PlayerSpawn", "DC_PlayerSpawn_HandsSetup", function( ply )
	ply:SetupHands() -- Create the hands view model and call GM:PlayerSetHandsModel
end )

hook.Add( "PlayerSetHandsModel", "DC_PlayerSetHandsModel_Hands", function( ply, ent )
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end )