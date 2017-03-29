AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local TIME_REMOVE = 5

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Think()
	if ( self.RemoveTimer ) then
		if ( self.RemoveTimer <= CurTime() ) then
			self:Remove()
			return
		end
		self:NextThink( self.RemoveTimer - CurTime() )
	end
	self:NextThink( CurTime() + TIME_REMOVE )
end

function ENT:StartRemove()
	self.OldColour = self.Entity:GetColor()
	self.Entity:SetColor( Color( 255, 0, 0, 255 ) )
	self.RemoveTimer = CurTime() + TIME_REMOVE

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableCollisions( false )
		phys:EnableMotion( false )
	end
end

function ENT:StopRemove()
	if ( self.RemoveTimer ) then
		self.Entity:SetColor( self.OldColour or Color( 255, 255, 0, 255 ) )
		self.RemoveTimer = nil
	end

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:EnableCollisions( true )
		phys:EnableMotion( !self.NoMotion )
	end
end
