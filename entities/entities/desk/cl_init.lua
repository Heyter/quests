include( "shared.lua" )

-- Map
local QU_Offset = Vector( -23, -45.35, 31.05 )
local QU_Angle = Angle( 0, 90, 0 )
local QU_Scale = 1 / 10
local QU_Size = Vector( 906, 431 )
local QU_Colour_Base = Color( 150, 150, 250, 255 )

-- Tiles
local QU_Tile_Offset = Vector( 0.25, 0 )
local QU_Tile_Size = Vector( 128, 128 - 16 )
local QU_Tile_Border = 8
local QU_Tile_OffsetDividier = 1.35
local QU_Tile_Count = Vector( 9, 5 )
local QU_Colour_Tile = Color( 150, 200, 150, 255 )
local QU_Colour_Tile_Border = Color( 100, 100, 100, 255 )

-- Border
local QU_BorderWidth = 16
local QU_BorderDivide = 48
local QU_Colour_Border_Front = Color( 200, 200, 150, 255 )
local QU_Colour_Border_Back = Color( 155, 100, 50, 255 )

-- Animation
local QU_Animation_CurrentTime = 0
local QU_Animation_CurrentDirection = 1

local QU_Animation_Total = 0
local QU_Animation = {
	{ "Dummy", 50 },
	{ "FoldDown", 75 },
	{ "MapRise", 300 },
	{ "BorderScale", 30 },
	{ "Pause", 500 },
}

-- Particles
local QU_Particle_Next = 0
local QU_Particle_Between = 0.5

local function QU_GetAnimationTotal()
	if ( QU_Animation_Total != 0 ) then return QU_Animation_Total end

	local count = 0
		for k, anim in pairs( QU_Animation ) do
			count = count + anim[2]
		end
	QU_Animation_Total = count
	return count
end
local function QU_GetAnimationProgress( index )
	-- Count the time of animations before this one
	local thisanimtime = 0
	local count = 0
		for k, anim in pairs( QU_Animation ) do
			if ( tostring( anim[1] ) == tostring( index ) ) then
				thisanimtime = anim[2]
				break
			end
			count = count + anim[2]
		end
	local progress = math.max( 0, QU_Animation_CurrentTime - count )
		progress = math.min( 1, progress / thisanimtime )
	return progress
end

-- Hex poly definition
local QU_Poly_Hex = {
	{ x = -1/2, y = 0 },
	{ x = -1/4, y = -1/2 },
	{ x = 1/4, y = -1/2 },
	{ x = 1/2, y = 0 },
	{ x = 1/4, y = 1/2 },
	{ x = -1/4, y = 1/2 },
}

function ENT:Think()
	-- Update particle effects
	local prog = QU_GetAnimationProgress( "Pause" )
	if ( ( prog > 0 ) and ( prog < 1 ) ) then
		if ( CurTime() > QU_Particle_Next ) then
			local effectdata = EffectData()
				effectdata:SetOrigin( self:GetPos() + Vector( 0, 0, 28 + 3 ) )
				effectdata:SetAngles( self:GetAngles() + Angle( 0, 0, 0 ) )
			util.Effect( "qu_desk_border", effectdata, true, true )
			QU_Particle_Next = CurTime() + QU_Particle_Between
		end
	end
	-- Update animation
	QU_Animation_CurrentTime = QU_Animation_CurrentTime + FrameTime() * 100 * QU_Animation_CurrentDirection
	if ( QU_Animation_CurrentTime >= QU_GetAnimationTotal() ) then QU_Animation_CurrentDirection = -1 end
	if ( QU_Animation_CurrentTime <= 0 ) then QU_Animation_CurrentDirection = 1 end

end

function ENT:Draw()
	self:DrawModel()

	local angle = QU_Angle + Angle( 0, self:GetAngles().y, 0 )
	render.ClearStencil()
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetBlend(0) --makes shit invisible
		render.SetStencilReferenceValue(10)
			cam.Start3D2D( self:GetPos() + QU_Offset, angle, QU_Scale )
				-- Draw base
				surface.SetDrawColor( QU_Colour_Base )
				draw.NoTexture()
				surface.DrawRect( 0, 0, QU_Size.x, QU_Size.y )
			cam.End3D2D()
		render.SetBlend(1)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
			-- Draw map tiles
			cam.IgnoreZ( true )
				cam.Start3D2D( self:GetPos() + QU_Offset - Vector( 0, 0, 1000 * ( 1 - QU_GetAnimationProgress( "MapRise" ) ) + 10 ), angle, QU_Scale * QU_GetAnimationProgress( "MapRise" ) )
					self:Draw_Map_Tiles()
				cam.End3D2D()
			cam.IgnoreZ( false )
			-- Draw borders
			cam.Start3D2D( self:GetPos() + QU_Offset, angle, QU_Scale )
				self:Draw_Map_Border()
			cam.End3D2D()
			-- Draw desk top
			if ( QU_GetAnimationProgress( "FoldDown" ) <= 1 ) then
				cam.IgnoreZ( true )
					self:Draw_Desk_Top()
				cam.IgnoreZ( false )
			end
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilEnable(false)
end

function ENT:Draw_Desk_Top()
	surface.SetDrawColor( QU_Colour_Base )
	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	local Mat = Material( "models/props_combine/breendesk_sheet" )
	local strImage = Mat:GetName()
	if ( string.find( Mat:GetShader(), "VertexLitGeneric" ) || string.find( Mat:GetShader(), "Cable" ) ) then
		local t = Mat:GetString( "$basetexture" )

		if ( t ) then
			local params = {}
			params[ "$basetexture" ] = t
			params[ "$vertexcolor" ] = 1
			params[ "$vertexalpha" ] = 1

			Mat = CreateMaterial( strImage .. "_Unlit", "UnlitGeneric", params )
		end
	end
	surface.SetMaterial( Mat )

	local ang = QU_GetAnimationProgress( "FoldDown" ) * 180
	local angle = QU_Angle + Angle( 0, self:GetAngles().y, 0 )
	cam.Start3D2D( self:GetPos() + QU_Offset, angle + Angle( ang, 0, 0 ), QU_Scale )
		surface.DrawTexturedRectUV( 0, 0, QU_Size.x / 2, QU_Size.y, 0, 0, 0.25, 0.22 )
		-- surface.DrawTexturedRectUV( -QU_Animation_CurrentTime, 0, QU_Size.x / 2, QU_Size.y, 0, 0, 0.25, 0.22 )
	cam.End3D2D()
	cam.Start3D2D( self:GetPos() + QU_Offset - Vector( 0, QU_Scale * -QU_Size.x, 0 ), angle + Angle( -ang, 0, 0 ), QU_Scale )
		surface.DrawTexturedRectUV( -QU_Size.x / 2, 0, QU_Size.x / 2, QU_Size.y, 0.25, 0, 0.5, 0.22 )
		-- surface.DrawTexturedRectUV( QU_Size.x / 2 + QU_Animation_CurrentTime, 0, QU_Size.x / 2, QU_Size.y, 0.25, 0, 0.5, 0.22 )
	cam.End3D2D()
end

function ENT:Draw_Map_Tiles()
	for x = 0, QU_Tile_Count.x do
		for y = 0, QU_Tile_Count.y do
			local offx = x + QU_Tile_Offset.x
			local offy = y + QU_Tile_Offset.y
			if ( x % 2 != 0 ) then offy = offy + 0.5 end
			self:Draw_Map_Tile( offx * QU_Tile_Size.x / QU_Tile_OffsetDividier, offy * QU_Tile_Size.y, QU_Tile_Size.x, QU_Tile_Size.y )
		end
	end
end

function ENT:Draw_Map_Tile( x, y, width, height )
	-- Draw border
	surface.SetDrawColor( QU_Colour_Tile_Border )
	draw.NoTexture()
	local poly = {}
	for k, vert in pairs( QU_Poly_Hex ) do
		table.insert( poly, {
			x = ( vert.x * width ) + x,
			y = ( vert.y * height ) + y,
		} )
	end
	surface.DrawPoly( poly )

	-- Draw tile
	surface.SetDrawColor( QU_Colour_Tile )
	draw.NoTexture()
	local poly = {}
	for k, vert in pairs( QU_Poly_Hex ) do
		table.insert( poly, {
			x = ( vert.x * ( width - QU_Tile_Border ) ) + x,
			y = ( vert.y * ( height - QU_Tile_Border ) ) + y,
		} )
	end
	surface.DrawPoly( poly )
end

function ENT:Draw_Map_Border()
	local prog = QU_GetAnimationProgress( "BorderScale" )
	if ( prog == 0 ) then return end

	local width = QU_BorderWidth * prog

	local borders = {
		{ 0, 0, width, QU_Size.y, QU_Size.y, 0, 1, 1, 0 },
		{ QU_Size.x - width, 0, width, QU_Size.y, QU_Size.y, 0, 1, 1, 0 },
		{ 0, 0, QU_Size.x, width, QU_Size.x, 1, 0, 0, 1 },
		{ 0, QU_Size.y - width, QU_Size.x, width, QU_Size.x, 1, 0, 0, 1 },
	}
	for k, border in pairs( borders ) do
		-- Draw main line border
		surface.SetDrawColor( QU_Colour_Border_Back )
		draw.NoTexture()
		surface.DrawRect( border[1], border[2], border[3], border[4] )

		-- Draw white segments
		surface.SetDrawColor( QU_Colour_Border_Front )
		draw.NoTexture()
		for add = 0, border[5], QU_BorderDivide * 2 do
			local x = border[1] + border[6] * add
			local y = border[2] + border[7] * add
			local width = border[3] * border[8] + QU_BorderDivide * math.Remap( border[8], 0, 1, 1, 0 )
			local height = border[4] * border[9] + QU_BorderDivide * math.Remap( border[9], 0, 1, 1, 0 )
			
			-- Check in range
			local max_x = x + width - QU_Size.x
			if ( max_x > 0 ) then
				width = width - max_x
			end
			local max_y = y + height - QU_Size.y
			if ( max_y > 0 ) then
				height = height - max_y
			end

			surface.DrawRect(
				x,
				y,
				width,
				height
			)
		end
	end
end
