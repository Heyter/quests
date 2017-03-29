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
	
end

function ENT:OnRemove()
	self.Entity:ClearFloor()
end

function ENT:LookFromTo( from, to )
	local xDiff = to.x - from.x;
	local yDiff = to.y - from.y;
	local ang = math.atan2( yDiff, xDiff ) * 180.0 / math.pi;
	self.Entity:SetAngles( Angle( 0, ang, 0 ) )
end

function ENT:ConfirmPoint()

end

function ENT:GenerateFloor()
	self.Entity:ClearFloor()

	-- Subdivide wall space into columns of varying width (depending on available props)
	local cells
	--while ( !cells ) do
		cells = self.Entity:GenerateFloor_GetCells()
	--end

end

function ENT:GenerateFloor_GetCells()
	local count = 0
	local smallest = GAMEMODE.Fal_Floors[1].Length
		for k, prop in pairs( GAMEMODE.Fal_Floors ) do
			if ( prop.Length < smallest ) then
				smallest = prop.Length
			end
			if ( prop.Breadth < smallest ) then
				smallest = prop.Breadth
			end
			count = count + 1
		end
	local timeout = 0
	local cells = {}
		local areas = {
			{ self.Min, self.Max, self.Length, self.Breadth },
		}
		local areacount = 1
		while ( areacount > 0 and timeout < 100 ) do
			local of = self:GetPos() + Vector( 0, 0, 1 + timeout * 0 )
			debugoverlay.Line( of + areas[1][1], of + areas[1][2], 10, Color( 255, 0, 0, 255 ), true )
			debugoverlay.Line( of + areas[1][2], of + areas[1][3], 10, Color( 255, 0, 0, 255 ), true )
			debugoverlay.Line( of + areas[1][3], of + areas[1][4], 10, Color( 255, 0, 0, 255 ), true )
			debugoverlay.Line( of + areas[1][4], of + areas[1][1], 10, Color( 255, 0, 0, 255 ), true )
			-- if ( timeout == 5 ) then
				-- break
			-- end
			-- debugoverlay.Sphere( of + areas[1][1], 1, 10, Color( 255, 0, 0 ), true )
			-- debugoverlay.Sphere( of + areas[1][2], 1, 10, Color( 0, 255, 0 ), true )
			-- debugoverlay.Sphere( of + areas[1][3], 1, 10, Color( 0, 0, 255 ), true )
			-- debugoverlay.Sphere( of + areas[1][4], 1, 10, Color( 0, 0, 0 ), true )

			-- Find space
			local length = areas[1][2]:Distance( areas[1][1] )
			local breadth = areas[1][3]:Distance( areas[1][2] )
			local forward = ( areas[1][2] - areas[1][1] ):GetNormalized()
			local right = ( areas[1][3] - areas[1][2] ):GetNormalized()

			-- Remove this area if too small
			if ( length < smallest or breadth < smallest ) then
				-- Remove old area
				table.remove( areas, 1 )
				areacount = areacount - 1
			else
				-- Choose a random prop which fits in this space (area 1)
				-- Remove space if no prop found
				local rnd = 0
				local timeout_inner = 0
				local props = table.shallowcopy( GAMEMODE.Fal_Floors )
				local localcount = count
				while ( rnd == 0 and localcount > 0 and timeout_inner < 100 ) do
					local rnd_try = math.random( 1, localcount )
					if ( props[rnd_try].Breadth <= breadth and props[rnd_try].Length <= length ) then
						rnd = rnd_try
						break
					end
					table.remove( props, rnd_try )
					localcount = localcount - 1

					timeout_inner = timeout_inner + 1
				end

				if ( rnd != 0 ) then
					-- Divide around this into 2 new areas
					table.insert( areas, {
						areas[1][1] + right * props[rnd].Breadth,
						areas[1][2] + right * props[rnd].Breadth - forward * ( length - props[rnd].Length ),
						areas[1][3] - forward * ( length - props[rnd].Length ),
						areas[1][4],
					} )
					areacount = areacount + 1
					table.insert( areas, {
						areas[1][1] + forward * props[rnd].Length,
						areas[1][2],
						areas[1][3],
						areas[1][4] + forward * props[rnd].Length,
					} )
					areacount = areacount + 1

					-- Spawn prop
					local ent = self:AddModel( props[rnd].Model, self:GetPos() )
					local ang = self:GetAngles() + props[rnd].Angles
						local rnd_ang = 3
						local rnd_ang_y = 12
						ang = ang + Angle( math.random( -rnd_ang, rnd_ang ), math.random( -rnd_ang_y, rnd_ang_y ), math.random( -rnd_ang, rnd_ang ) )
					ent:SetAngles( ang )

					-- Calculate relative positions
					local pos = self:GetPos() + areas[1][1] -- + Vector( 0, 0, self:GetHeightPos() / 2 )
						local dir = ( self:GetWidthPos() - self:GetStartPos() ):GetNormalized()
						pos = pos + dir
						pos = pos + Vector( math.random( -1, 1 ), math.random( -1, 1 ), math.random( -1, 1 ) )
						if ( props[rnd].Offset ) then
							pos = pos + ang:Forward() * props[rnd].Offset.x
							pos = pos + ang:Right() * props[rnd].Offset.y
							pos = pos + ang:Up() * props[rnd].Offset.z
						end
					ent:SetPos( pos )
				end

				-- Remove old area
				table.remove( areas, 1 )
				areacount = areacount - 1
			end
			timeout = timeout + 1
		end
	return cells
end

function ENT:ClearFloor()
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
		ent:SetParent( self.Entity )
	table.insert( self.Models, ent )
	return ent
end
