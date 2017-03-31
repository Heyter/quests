AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self.Entity:SetMaterial( "models/debug/debugwhite" )
	self.Entity:SetColor( Color( 100, 200, 50 ) )
	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Models = {}
end

function ENT:Use( ply )
	if ( self.NextUse and self.NextUse > CurTime() ) then return end
	self.Entity:ClearModels()
	self.Entity:Generate()
	self.NextUse = CurTime() + 0.5
end

function ENT:OnRemove()
	self.Entity:ClearModels()
end

function ENT:Generate()
	local oldang = self:GetAngles()
	self:SetAngles( Angle( 0, 0, 0 ) )
	-- Angles are set to 0 for local positioning
		-- Find bounds of plot
		local min = self:OBBMins()
		local max = self:OBBMaxs()
		local corners = {
			Vector( min.x, max.y, 0 ),
			Vector( -min.x, -min.y, 0 ),
			Vector( max.x, min.y, 0 ),
			Vector( -max.x, -max.y, 0 )
		}
		local walls = {}
		for corner = 1, 4 do
			local pos = self:GetPos() + corners[corner]
			local posend = self:GetPos()
				if ( corner == 4 ) then
					posend = posend + corners[1]
				else
					posend = posend + corners[corner+1]
				end
			table.insert( walls, { pos, posend } )
		end
		for k, wall in pairs( walls ) do
			local wallent = ents.Create( "fal_place_wall" )
			wallent:SetStartPos( wall[1] )
			wallent:SetWidthPos( wall[2] )
			wallent:SetHeightPos( 10 )
			wallent:LookFromTo( wall[1], wall[2] )
			wallent.Whitelist = { "Thin" }
			wallent.Blacklist = { "Partially Transparent" }
			wallent:GenerateWall()
			wallent:SetParent( self.Entity )
			table.insert( self.Models, wallent )
		end
		local floorent = ents.Create( "fal_place_floor" )
		floorent:SetPos( self.Entity:GetPos() )
		floorent.Min = corners[1]
		floorent.Max = corners[2]
		floorent.Length = corners[3]
		floorent.Breadth = corners[4]
		floorent:LookFromTo( floorent.Min, floorent.Max )
		floorent.Whitelist = { "Thin" }
		floorent.Blacklist = { "Partially Transparent" }
		floorent:Spawn()
		floorent:GenerateFloor()
		floorent:SetParent( self.Entity )
		table.insert( self.Models, floorent )
	-- Angles reset to old
	self:SetAngles( oldang )
	for k, wallent in pairs( self.Models ) do
		if ( wallent.Models ) then
			for k, model in pairs( wallent.Models ) do
				model:SetParent( nil )
			end
		end
	end
end

function ENT:AddModel( model, pos, motion )
	if ( !self.Models ) then
		self.Models = {}
	end

	local ent = ents.Create( "fal_model" )
		ent:SetPos( pos )
		ent:SetModel( model )
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if ( phys:IsValid() ) then
			phys:EnableMotion( motion )
		end
		ent:SetParent( self.Entity )
	table.insert( self.Models, ent )
	return ent
end

function ENT:ClearModels()
	for k, model in pairs( self.Models ) do
		if ( model and model:IsValid() ) then
			model:Remove()
		end
	end
	self.Models = {}
end
