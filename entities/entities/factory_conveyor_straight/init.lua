AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self.Entity:SetModel( "models/props_junk/TrashDumpster02b.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	--self.Entity:DrawShadow( true )

        local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Think()
	if ( !self.Entities ) then
		self.Entities = {}
	end

	for k, ent in pairs( self.Entities ) do
		if ( ent:IsPlayer() ) then
			local playerpush = -self:GetAngles():Right() * 1
			ent:SetPos( ent:GetPos() + playerpush )
		else
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				local pushpos = ent:GetPos()
				local pushvec = -self:GetAngles():Right() * 10 * phys:GetMass()
					pushvec = pushvec + self:GetAngles():Up() * 8
				phys:ApplyForceOffset( pushvec, pushpos )
			end
		end
	end

	-- Run more often when there are entities on the conveyor, for smoother movement
	--if ( #self.Entities != 0 ) then
		self:NextThink( CurTime() )
		return true
	--end

	--self:NextThink( CurTime() + 1 )
	--return true
end

function ENT:StartTouch( ent )
	if ( !self.Entities ) then
		self.Entities = {}
	end

	if ( !table.HasValue( self.Entities, ent ) ) then
		table.insert( self.Entities, ent )
		PrintTable( self.Entities )
		print( "join" .. tostring( ent ) )
	end
end

function ENT:EndTouch( ent )
	table.RemoveByValue( self.Entities, ent )
	print( "leave" .. tostring( ent ) )
end
