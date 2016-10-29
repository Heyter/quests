AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
--
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_NONE )
	self.Entity:DrawShadow( false )

	local phys = self.Entity:GetPhysicsObject()
	--
		if ( phys and phys:IsValid() ) then
		--
			phys:EnableMotion( false )
		--
		end
	--
	self.Entity:SetModel( "models/weapons/c_arms_citizen.mdl" )
	self.Entity:SetSequence( self.Entity:LookupSequence( "fists_draw" ) )
	self.Entity:UseClientSideAnimation( true )

	for k, v in pairs( player.GetAll() ) do
	--
		self.Entity:SetOwner( v )
		break
	--
	end
--
end