AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self.Entity:SetModel( "models/hunter/plates/plate1x1.mdl" )
	self.Entity:SetMaterial( "models/debug/debugwhite" )
	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:SetSolid( SOLID_NONE )

	self.Models = {}
end

function ENT:Think()
	--if ( self:GetStartPos != Vector( 0, 0, 0 ) and self.Entity:() == Vector( 0, 0, 0 ) ) then return end
	if ( self:GetStartPos() == Vector( 0, 0, 0 ) ) then
		self:SetStartPos( self:GetPos() )
	end

	local height = 1
	local width = self:GetWidthPos()
	if ( width == Vector( 0, 0, 0 ) ) then
		width = self.Owner:GetEyeTrace().HitPos
		width.z = self:GetStartPos().z
		self.CurrentWidth = width
	else
		height = self:GetHeightPos()
		if ( height == 0 ) then
			height = math.abs( self.Owner:EyeAngles().x ) * 5
			self.CurrentHeight = height
		end
	end
	-- local dist = width:Distance( self.StartPos )

	-- local scale = Vector( height / 50, dist / 50, 1 )

	-- self.Entity:SetFalScale( scale )
	self.Entity:SetPos( ( ( -self:GetStartPos() + width ) / 2 ) + self:GetStartPos() + Vector( 0, 0, height / 2 ) )
	self:LookFromTo( self:GetStartPos(), width )
	-- self.Entity:SetCollisionBounds( Vector( -scale.x, -scale.y, -1 ), Vector( scale.x, scale.y, 1 ) )

	self:NextThink( CurTime() + 0.01 )
end

function ENT:OnRemove()
	self.Entity:ClearWall()
end

function ENT:LookFromTo( from, to )
	local xDiff = to.x - from.x;
	local yDiff = to.y - from.y;
	local ang = math.atan2( yDiff, xDiff ) * 180.0 / math.pi;
	self.Entity:SetAngles( Angle( 90, ang + 90, 0 ) )
end

function ENT:ConfirmPoint()
	if ( self:GetWidthPos() == Vector( 0, 0, 0 ) ) then
		self:SetWidthPos( self.CurrentWidth )
	elseif ( self:GetHeightPos() == 0 ) then
		self:SetHeightPos( self.CurrentHeight )
	else
		-- if ( self.Entity:() != Vector( 0, 0, 0 ) ) then
			-- self.Entity:SetStartPos( self:GetStartPos() - Vector( 0, 0, 50 ) )
			-- self.Entity:SetWidthPos( self:GetWidthPos() - Vector( 0, 0, 50 ) )
		-- end
		self.Entity:GenerateWall()
	end
end

local GlobalZOffset = 25

function ENT:GenerateWall()
	self.Entity:ClearWall()

	-- Subdivide wall space into columns of varying width (depending on available props)
	local coltab
	while ( !coltab ) do
		coltab = self.Entity:GenerateWall_GetColumns()
	end
	-- Subdivide each column into varying rows for visual effect

	-- Find props to match each cell
	local dist = 0
	for col = 1, #coltab do
		-- Create entity first for bounding information
		local rnd = coltab[col]
		local ent = self.Entity:AddModel( GAMEMODE.Fal_Walls[rnd].Model, self.Entity:GetPos() )

		-- Calculate relative angles
		local ang = Angle( -90, 0, 0 ) + Angle( math.random( -5, 5 ), math.random( -5, 5 ), math.random( -5, 5 ) )
			-- if ( math.random( 1, 2 ) == 1 ) then
				-- ang = ang + Angle( 0, 180, 0 )
			-- end
			if ( GAMEMODE.Fal_Walls[rnd].Angles ) then
				ang = ang + GAMEMODE.Fal_Walls[rnd].Angles
			end
			ang = ang + self.Entity:GetAngles()
		-- Calculate relative positions
		local pos = self:GetStartPos() -- + Vector( 0, 0, self:GetHeightPos() / 2 )
			local dir = ( self:GetWidthPos() - self:GetStartPos() ):GetNormalized()
			pos = pos + dir * ( dist + GAMEMODE.Fal_Walls[rnd].Width / 2 )
			local tr = util.TraceLine( {
				start = pos + Vector( 0, 0, 1000 ),
				endpos = pos + Vector( 0, 0, -1100 ),
				filter = function( ent ) if ( ent:GetClass() == "fal_model" ) then return false end end
			} )
			pos.z = tr.HitPos.z + GlobalZOffset
			--pos = pos + Vector( math.random( -1, 1 ), math.random( -1, 1 ), math.random( -1, 1 ) )
			if ( GAMEMODE.Fal_Walls[rnd].Offset ) then
				pos = pos + ang:Forward() * GAMEMODE.Fal_Walls[rnd].Offset.x
				pos = pos + ang:Right() * GAMEMODE.Fal_Walls[rnd].Offset.y
				pos = pos + ang:Up() * GAMEMODE.Fal_Walls[rnd].Offset.z
			end

		-- Set the entity to proper transform
		ent:SetAngles( ang )
		ent:SetPos( pos )

		-- Move along for next entity
		dist = dist + GAMEMODE.Fal_Walls[rnd].Width
	end

	if ( self.Models ) then
		for k, model in pairs( self.Models ) do
			model:SetParent( self.Entity )
		end
	end
end

function ENT:GenerateWall_GetColumns()
	local count = 0
	local smallest = GAMEMODE.Fal_Walls[1].Width
		for k, prop in pairs( GAMEMODE.Fal_Walls ) do
			if ( prop.Width < smallest ) then
				smallest = prop.Width
			end
			count = count + 1
		end
	local width = self:GetWidthPos():Distance( self:GetStartPos() )
	local coltab = {}
		local timeout = 0
		while ( width >= smallest and timeout < 100 ) do
			local rnd = math.random( 1, count )
			if ( GAMEMODE.Fal_Walls[rnd].Width <= width ) then
				local match = false
					if ( self.Whitelist ) then
						for k, tag in pairs( GAMEMODE.Fal_Walls[rnd].Tags ) do
							for k, whitetag in pairs( self.Whitelist ) do
								if ( tag == whitetag ) then
									match = true
									break
								end
							end
							if ( match ) then
								break
							end
						end
					else
						match = true
					end
					-- Only check if already matching
					if ( self.Blacklist and match ) then
						for k, tag in pairs( GAMEMODE.Fal_Walls[rnd].Tags ) do
							for k, blacktag in pairs( self.Blacklist ) do
								if ( tag == blacktag ) then
									match = false
									break
								end
							end
						end
					end
				if ( match ) then
					table.insert( coltab, rnd )
					width = width - GAMEMODE.Fal_Walls[rnd].Width
				end
			end

			timeout = timeout + 1
		end
	return coltab
end

function ENT:ClearWall()
	if ( !self.Models ) then return end

	for k, ent in pairs( self.Models ) do
		if ( ent and ent:IsValid() ) then
			ent:Remove()
		end
	end
	self.Models = {}
end

function ENT:AddModel( model, pos, motion )
	if ( !self.Models ) then
		self.Models = {}
	end

	local ent = ents.Create( "prop_physics" )
		ent:SetPos( pos )
		ent:SetModel( model )
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if ( phys:IsValid() ) then
			phys:EnableMotion( motion )
		end
		--ent:SetParent( self.Entity )
	table.insert( self.Models, ent )
	return ent
end
