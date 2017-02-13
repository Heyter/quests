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
		if ( phys and phys:IsValid() ) then
			phys:EnableMotion( false )
		end

	if ( !IsValid( self.Owner ) ) then
		self.Owner = Entity( 1 )
	end
	print( self.Owner )

	-- Cast entity onto surface
	-- local tr = self.Owner:GetEyeTrace()
	-- print( tr.HitNormal )
	-- local temp = ents.Create( "prop_physics" )
	-- temp:SetPos( self.Entity:GetPos() + tr.HitNormal * 10 )
		-- self.Entity:PointAtEntity( temp )
	-- temp:Remove()

	-- self.Entity:SetAngles( self.Entity:GetAngles() + Angle( 90, 0, 0 ) )
end