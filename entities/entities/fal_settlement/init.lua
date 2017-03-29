AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local RADIUS = 500
local RADIUS_MARGIN = 100
local WEAPON_BUILD = { "weapon_physgun" }

util.AddNetworkString( "Fal_Settlement_EnterExit" )

function ENT:Initialize()
	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:SetSolid( SOLID_NONE )
	self.Entity:SetTrigger( true )
	self.Entity:UseTriggerBounds( true, 1 )
	self.Entity:SetFalRadius( RADIUS )
	self.Entity:UpdateBounds()
	self.Entity.RadiusMargin = RADIUS_MARGIN
	--self.Entity:DrawShadow( true )

	-- local phys = self:GetPhysicsObject()
	-- if (phys:IsValid()) then
		-- phys:Wake()
	-- end
end

-- In first Think, so the entity is definitely positioned properly
function ENT:LateInitialize()
	if ( !self.Models ) then
		self.Models = {}
		self:AddModel( "models/props_c17/fountain_01.mdl", self.Entity:GetPos() + Vector( 0, 0, -50 ), true )
	end
end

function ENT:Think()
	self:LateInitialize()
end

function ENT:StartTouch( ent )
	if ( ent:IsPlayer() ) then
		for k, weapon in pairs( WEAPON_BUILD ) do
			ent:Give( weapon )
		end
		ent.Fal_Settlement = self
		ent:AddBuff( GetBuffID( "Relative Safety" ) )

		net.Start( "Fal_Settlement_EnterExit" )
			net.WriteBool( true )
			net.WriteString( "Abernathy Farm" )
		net.Send( ent )
	end
	if ( ent:GetClass() == "fal_model" ) then
		ent:StopRemove()
	end
end

function ENT:EndTouch( ent )
	if ( ent:IsPlayer() ) then
		ent:StripWeapons( WEAPON_BUILD )
		ent.Fal_Settlement = nil
		ent:RemoveBuff( GetBuffID( "Relative Safety" ) )

		net.Start( "Fal_Settlement_EnterExit" )
			net.WriteBool( false )
		net.Send( ent )
	end
	if ( ent:GetClass() == "fal_model" ) then
		ent:StartRemove()
	end
end

function ENT:AddModel( model, pos, nomotion )
	local ent = ents.Create( "fal_model" )
		ent:SetPos( pos )
		ent:SetModel( model )
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if ( phys:IsValid() ) then
			phys:EnableMotion( !nomotion )
		end
		ent.NoMotion = nomotion
	table.insert( self.Models, ent )
	return ent
end

function ENT:AddPlot( model, pos )
	if ( !self.Plots ) then
		self.Plots = {}
	end

	local ent = ents.Create( "fal_plot" )
		ent:SetPos( pos )
		ent:SetModel( model )
		ent:Spawn()
	table.insert( self.Plots, ent )
	return ent
end

function ENT:UpdateBounds()
	local rad = self.Entity:GetFalRadius()
	self.Entity:SetCollisionBounds( Vector( -rad, -rad, -rad ), Vector( rad, rad, rad ) )
end
