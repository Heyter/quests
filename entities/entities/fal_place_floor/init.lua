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

local cellsize, length, breadth, forward, right, celllength, cellbreadth, count, smallest, grid
	cellsize = 1
local x = 0
local y = 0
local gen = false
function ENT:Think()
	if ( !gen ) then return false end

	x = x + 1
	if ( x > celllength ) then
		x = 0
		-- y = y + 1
		gen = false
	end
	-- if ( y > cellbreadth ) then
		-- gen = false
	-- end
	-- print( x .. " " .. y )
	for y = 0, cellbreadth do
		self:GenerateFloor_GetCells_Internal( x, y )
	end

	self:NextThink( CurTime() + 0.01 )
	return true
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
		self.Entity:GenerateFloor_GetCells()
		x = 0
		y = 0
		gen = true
	--end

end

function ENT:GenerateFloor_GetCells()

	-- Find space
	breadth = self.Breadth:Distance( self.Length )
	length = self.Max:Distance( self.Min )
	celllength = math.floor( length / cellsize )
	cellbreadth = math.floor( breadth / cellsize )

	-- Find smallest and count the number of possible floor props
	count = 0
	smallest = GAMEMODE.Fal_Floors[1].Length
		for k, prop in pairs( GAMEMODE.Fal_Floors ) do
			if ( prop.Length < smallest ) then
				smallest = prop.Length
			end
			if ( prop.Breadth < smallest ) then
				smallest = prop.Breadth
			end
			count = count + 1
		end

	-- Define placement grid
	grid = {}
		for x = 0, celllength do
			grid[x] = {}
			for y = 0, cellbreadth do
				grid[x][y] = false
			end
		end

	-- Generate
	-- for x = 0, celllength do
		-- for y = 0, cellbreadth do
			-- self:GenerateFloor_GetCells_Internal( x, y )
		-- end
	-- end
end

function ENT:GenerateFloor_GetCells_Internal( x, y )
	local min = self.Entity:GetPos() - Vector( length / 2, breadth / 2, 0 )
	if ( !grid[x][y] ) then
		-- debugoverlay.Box( min, Vector( x * cellsize, y * cellsize, x * y / 20 ), Vector( x* cellsize + cellsize, y *cellsize + cellsize, x * y / 20 ), 10, Color( 255, 0, 0, 255 ) )

		-- Find largest square area starting here
		local currentlength = 0
		local currentbreadth = 0
			local timeout = 0
			local inx = x
			local iny = y
			local incr = 1
			while ( timeout < length ) do
				local collide = false
				for checkx = x, inx do
					for checky = y, iny do
						if ( grid[checkx][checky] ) then
							collide = true
							break
						end
					end
					if ( collide ) then
						break
					end
				end
				-- debugoverlay.Box( min, Vector( x * cellsize, y * cellsize, x * y / 20 ), Vector( inx * cellsize, iny * cellsize, 0.5 * timeout + 1 ), 1, Color( 255, 255, 0, 255 ) )
				if ( collide ) then
					break
				end

				inx = inx + incr
				iny = iny + incr
				if ( inx > celllength and iny > cellbreadth ) then
					break
				elseif ( inx > celllength ) then
					inx = celllength
				elseif ( iny > cellbreadth ) then
					iny = cellbreadth
				end

				currentlength = currentlength + incr
				currentbreadth = currentbreadth + incr

				timeout = timeout + 1
			end
		currentlength = currentlength * cellsize
		currentbreadth = currentbreadth * cellsize

		-- Remove this area if too small
		print( currentlength )
		if ( currentlength < smallest or currentbreadth < smallest ) then
			-- Remove old area
			-- table.remove( areas, 1 )
			-- areacount = areacount - 1
		else
			-- Choose a random prop which fits in this space
			local rnd = 0
			local timeout_inner = 0
			local props = table.shallowcopy( GAMEMODE.Fal_Floors )
			local localcount = count
			-- local props = { table.shallowcopy( GAMEMODE.Fal_Floors[9] ) }
			-- local localcount = 1
			while ( rnd == 0 and localcount > 0 and timeout_inner < 100 ) do
				local rnd_try = math.random( 1, localcount )
				if ( props[rnd_try].Breadth <= currentbreadth and props[rnd_try].Length <= currentlength ) then
					rnd = rnd_try
					break
				end
				table.remove( props, rnd_try )
				localcount = localcount - 1

				timeout_inner = timeout_inner + 1
			end

			if ( rnd != 0 ) then
				-- Fill spaces
				local relativelength = math.max( 1, math.floor( props[rnd].Breadth / cellsize ) )
				local relativebreadth = math.max( 1, math.floor( props[rnd].Length / cellsize ) )
				for fillx = 0, relativelength do
					for filly = 0, relativebreadth do
						local inx = math.min( x + fillx, celllength )
						local iny = math.min( y + filly, cellbreadth )
						grid[inx][iny] = true
					end
				end
				-- debugoverlay.Box( min, Vector( x * cellsize, y * cellsize, x * y / 20 ), Vector( x* cellsize + cellsize * relativelength, y *cellsize + cellsize * relativebreadth, 0 ), 10, Color( 0, 0, 255, 255 ) )

				-- Spawn prop
				local ang = props[rnd].Angles
					local rnd_ang = 0
					local rnd_ang_y = 12
					ang = ang + Angle( math.random( -rnd_ang, rnd_ang ), math.random( -rnd_ang_y, rnd_ang_y ), math.random( -rnd_ang, rnd_ang ) )
				local pos = min + Vector( x * cellsize, y * cellsize, 0 ) + Vector( props[rnd].Length / 2, props[rnd].Breadth / 2, 0 )
				-- Calculate relative positions
					if ( props[rnd].Offset ) then
						pos = pos + ang:Forward() * props[rnd].Offset.x
						pos = pos + ang:Right() * props[rnd].Offset.y
						pos = pos + ang:Up() * props[rnd].Offset.z
					end
					pos = pos + Vector( math.random( -1, 1 ), math.random( -1, 1 ), math.random( -1, 1 ) )
				local ent = self:AddModel( props[rnd].Model, pos )
				ent:SetAngles( self:GetAngles() + ang )
			end

			-- Remove old area
			-- table.remove( areas, 1 )
			-- areacount = areacount - 1
		end
	end
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

function ENT:GenerateFloor_GetCells_OLD()
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
