include( "shared.lua" )

local scale = 64 -- 1px in 2d = 200 units in 3d
local texturesize
local texturescale = 8
local height
local position, angle

function ENT:DrawHole()
	cam.Start3D2D( position, angle, 1 )
		surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
		surface.DrawRect( 0, 0, scale, scale ) -- a 1 x 1 square
	cam.End3D2D()
end

function ENT:DrawInner()
	self:DrawInner_Walls()
	self:DrawInner_Props()
	self:DrawInner_Floor()
end

function ENT:DrawInner_Walls()
	local transforms = {
		{ position + Vector( scale, 0, 0 ), angle + Angle( 0, -90, 90 ) },
		{ position + Vector( 0, -scale, 0 ), angle + Angle( 0, 90, 90 ) },
		{ position + Vector( 0, 0, 0 ), angle + Angle( 0, 0, 90 ) },
		{ position + Vector( scale, -scale, 0 ), angle + Angle( 180, 0, -90 ) },
	}
	for k, trans in pairs( transforms ) do
		local pos = trans[1]
		local ang = trans[2]
		render.SetLightingMode( 2 )
		cam.Start3D2D( pos, ang, 1 )
			surface.SetDrawColor( Color( 50, 50, 255, 255 ) )
			surface.SetTexture( surface.GetTextureID( "CONCRETE/CONCRETEFLOOR023A" ) )
			surface.DrawTexturedRect( 0, 0, scale, scale )
		cam.End3D2D()
		render.SetLightingMode( 0 )
	end
end

function ENT:DrawInner_Props()
	for key, prop in pairs(ents.FindByClass( "prop_physics" )) do
		prop:DrawModel()
	end
end

function ENT:DrawInner_Floor()
	cam.Start3D2D( position + Vector( 0, 0, -height ), angle, 1 )
		surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		surface.SetTexture( surface.GetTextureID( self.CameraTexture:GetName() ) )
		surface.DrawTexturedRect( 0, 0, texturesize, texturesize ) -- a 1 x 1 square
	cam.End3D2D()
end

function ENT:Draw()
	local up = self.Entity:GetUp()
	position = self.Entity:GetPos() + ( up * 0.5 )
	angle = self.Entity:GetAngles()
	height = math.max( 0, math.sin( CurTime() / 1 ) * scale )

	-- Don't draw anything if no 'hole'
	--if ( height == 0 ) then return end

	-- Don't draw if there isn't a straight path to the player's eyes
	local tr = util.TraceLine( {
		start = position + up,
		endpos = LocalPlayer():EyePos()
	} )
	if ( tr.HitEntity != nil or tr.HitWorld ) then return end

	self:GetTextureFromCamera( position )

	-- Main render
	render.ClearStencil()
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetBlend(0) --makes shit invisible
		render.SetStencilReferenceValue(10)
			self:DrawHole()
		render.SetBlend(1)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
			-- Draw objects inside 'hole'
			cam.IgnoreZ( true ) -- see objects through world
				self:DrawInner()
			cam.IgnoreZ( false )
		-- Redraw client viewmodel on top of objects in 'hole'
		self:DrawViewModel()
	render.SetStencilEnable(false)
end

function ENT:GetTextureFromCamera( position )
	local up = self.Entity:GetUp()
	texturesize = scale
	if ( !self.CameraTexture ) then
		self.CameraTexture = GetRenderTarget( "qu_stencil_test", texturesize * texturescale, texturesize * texturescale, false )
	end
	render.PushRenderTarget( self.CameraTexture )
		render.Clear( 0, 0, 255, 0, true, true )
		render.RenderView( {
			type = "3D",
			origin = position + up * 10 + Vector( scale, -0.5, 0 ),
			angles = self.Entity:GetAngles() + Angle( 90, -90, 0 ),

			drawviewmodel = false,

			x = 0,
			y = 0,
			w = texturesize * texturescale,
			h = texturesize * texturescale,

			aspect = 1,
			ortho = {
				left = scale,
				right = 0,
				top = scale,
				bottom = 0,
			},
		} )
	render.PopRenderTarget()
end

function ENT:DrawViewModel()
	local fov = LocalPlayer():GetActiveWeapon().ViewModelFOV or (LocalPlayer():GetFOV() - 21.5)
	cam.Start3D( EyePos(), EyeAngles(), fov + 15)
		cam.IgnoreZ( true )
			LocalPlayer():GetViewModel():DrawModel()
		cam.IgnoreZ( false )
	cam.End3D()
end
