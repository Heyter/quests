AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_NONE )
	self.Entity:DrawShadow( true )
	self.Entity:SetModel( "models/props_combine/breendesk.mdl" )

	local phys = self.Entity:GetPhysicsObject()
		if ( phys and phys:IsValid() ) then
			phys:EnableMotion( false )
		end
end