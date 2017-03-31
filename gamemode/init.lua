-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 02/08/15
-- Main serverside logic

AddCSLuaFile( "cl_buff.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "cl_quest.lua" )
AddCSLuaFile( "cl_dialogue.lua" )
AddCSLuaFile( "cl_atmosphere.lua" )

AddCSLuaFile( "cl_init.lua" )

AddCSLuaFile( "sh_buff.lua" )
AddCSLuaFile( "sh_event.lua" )
AddCSLuaFile( "sh_quest.lua" )
AddCSLuaFile( "sh_dialogue.lua" )
AddCSLuaFile( "sh_model.lua" )

local function AddCSLuaFileRecurse( dir, localdir )
	local files, directories = file.Find( dir .. localdir .. "*", "GAME" )
	for k, file in pairs( files ) do
		if ( string.find( file, ".lua" ) ) then
			AddCSLuaFile( localdir .. file )
		end
	end
	for k, subdir in pairs( directories ) do
		AddCSLuaFileRecurse( dir, localdir .. subdir .. "/" )
	end
end

AddCSLuaFileRecurse( "gamemodes/quests/gamemode/", "model/" )

AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "sv_buff.lua" )
include( "sv_quest.lua" )
include( "sv_dialogue.lua" )

-- Sends to cl_hud.lua
util.AddNetworkString( "DC_Client_Round" )

resource.AddFile( "fonts/UrbanJungleDEMO.oft" )

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

function GM:Think()
	self.BaseClass:Think()

	-- Used to update buffs on players, function located within sv_buff.lua
	self:Think_Buff()

	-- Update all current quests
	for _, ply in pairs( player.GetAll() ) do
		if ( ply.Quests != null ) then
			for k, quest in pairs( ply.Quests ) do
				local statuschanged = quest:Think( ply )
				if ( statuschanged ) then
					SendQuest( ply, k )
					if ( quest.Removed ) then
						RemoveQuest( ply, quest.Name )
						table.remove( ply.Quests, k )
					end
				end
			end
		end
	end

	-- Testing wall placement
	for _, ply in pairs( player.GetAll() ) do
		if ( ply:KeyPressed( IN_WALK ) ) then
			if ( ply.Fal_Place_Wall ) then
				ply.Fal_Place_Wall:ConfirmPoint()
			else
				ply.Fal_Place_Wall = ents.Create( "fal_place_wall" )
				ply.Fal_Place_Wall:SetPos( ply:GetEyeTrace().HitPos + Vector( 0, 0, 10 ) )
				ply.Fal_Place_Wall:SetOwner( ply )
				ply.Fal_Place_Wall:Spawn()
			end
		end
		if ( ply:KeyPressed( IN_DUCK ) ) then
			if ( ply.Fal_Place_Wall ) then
				ply.Fal_Place_Wall:Remove()
				ply.Fal_Place_Wall = nil
			end
		end
		if ( ply:KeyPressed( IN_RELOAD ) ) then
			ply.Fal_Place_Wall = nil
		end
	end
end

-- function GM:PlayerSwitchFlashlight( ply, on )
	-- return !on
-- end

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
	ply:SetCanZoom( true )
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

function GM:OnEntityCreated( ent )
	self.BaseClass:OnEntityCreated( ent )

	if ( ent:IsNPC() ) then
		ent:EmitSound( "vo/npc/male01/no02.wav" )
		ent:NavSetGoalTarget( player.GetAll()[1]:GetPos(), Vector( 0, 0, 0 ) )
		ent:SetTarget( player.GetAll()[1] )
		ent:SetSaveValue( "m_vecLastPosition", player.GetAll()[1]:GetPos() )
		ent:SetSchedule( SCHED_TARGET_CHASE )
		print( player.GetAll()[1]:GetPos() )
	end
end

function table.length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
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

function GM:PlayerSpawnProp( ply, model )
	if ( ply.Fal_Settlement ) then
		local withinbounds = false
			local vStart = ply:GetShootPos()
			local vForward = ply:GetAimVector()
			local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * 2048)
			trace.filter = ply

			local tr = util.TraceLine( trace )
			local spawnpos = tr.HitPos
			local dist = math.Distance( spawnpos.x, spawnpos.y, ply.Fal_Settlement:GetPos().x, ply.Fal_Settlement:GetPos().y )
			if ( dist <= ply.Fal_Settlement:GetFalRadius() + ply.Fal_Settlement.RadiusMargin ) then
				withinbounds = true
			end
		if ( ply:HasWeapon( "weapon_physgun" ) and withinbounds ) then
			local e
				if ( string.find( model, "plates/" ) ) then
					e = ply.Fal_Settlement:AddPlot( model, spawnpos )
				else
					e = ply.Fal_Settlement:AddModel( model, spawnpos )
				end
				local vFlushPoint = tr.HitPos - ( tr.HitNormal * 512 )	-- Find a point that is definitely out of the object in the direction of the floor
				vFlushPoint = e:NearestPoint( vFlushPoint )			-- Find the nearest point inside the object to that point
				vFlushPoint = e:GetPos() - vFlushPoint				-- Get the difference
				vFlushPoint = tr.HitPos + vFlushPoint					-- Add it to our target pos

				-- Set new position
				e:SetPos( vFlushPoint )

				local ang = ply:EyeAngles()
				ang.yaw = ang.yaw + 180 -- Rotate it 180 degrees in my favour
				ang.roll = 0
				ang.pitch = 0
				e:SetAngles( ang )

			if ( IsValid( ply ) ) then
				gamemode.Call( "PlayerSpawnedProp", ply, model, e )
			end

			FixInvalidPhysicsObject( e )

			DoPropSpawnedEffect( e )

			undo.Create( "Prop" )
				undo.SetPlayer( ply )
				undo.AddEntity( e )
			undo.Finish( "Prop (" .. tostring( model ) .. ")" )

			ply:AddCleanup( "props", e )
		end
	end

	return false
end

function GM:PlayerSpawnEffect( ply, model )
	return false
end

function GM:PlayerSpawnRagdoll( ply, model )
	return false
end

function GM:PlayerSpawnSENT( ply, class )
	return false
end

function GM:PlayerSpawnSWEP( ply, weapon, swep )
	return false
end

-- function GM:PlayerSpawnNPC( ply, npc_type, weapon )
	-- return false
-- end
