include( "shared.lua" )

local ent

local FontSizeSmall = 12
local FontSizes = 24
local FontSizeJump = 1
for size = 1, FontSizes do
	surface.CreateFont( "Fal_Settlement" .. size,
		{
			font = "UrbanJungleDEMO", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = false,
			size = FontSizeSmall + size * FontSizeJump,
			weight = 500,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false,
		}
	)
end

local Speed = 2
local AnimationPosX, AnimationPosY, AnimationColour, AnimationFont, AnimationLine, AnimationLineColour
local CurrentState
local States = {}
	States.ENTER = function()
		local Speed = 4

		if ( !AnimationPosX ) then
			AnimationPosX = ScrW() / 2
			AnimationPosY = -128
			AnimationColour = Color( 0, 0, 0, 0 )
			AnimationLine = 0
			AnimationLineColour = Color( 0, 0, 0, 0 )
		end
		local targetx = ScrW() / 2
		local targety = ScrH() / 8
		local targetcolour = Color( 255, 255, 255, 255 )
		local completion = math.Round( ( AnimationPosY - ( targety / 4 * 3 ) ) / ( targety / 4 ) * FontSizes )
		local font = math.min( FontSizes, math.max( completion, 1 ) )

		AnimationPosX = Lerp( FrameTime() * Speed, AnimationPosX, targetx )
		AnimationPosY = targety-- Lerp( FrameTime() * Speed, AnimationPosY, targety )
		AnimationColour = LerpColour( FrameTime() * Speed, AnimationColour, targetcolour )
		AnimationFont = "Fal_Settlement" .. font

		local dif = math.abs( AnimationColour.r - targetcolour.r )
		if ( dif < 5 ) then
			CurrentState = States.LINE
		end
	end
	States.LINE = function()
		targetline = ScrW() / 4
		targetlinecolour = Color( 181, 181, 181, 100 )
		AnimationLine = Lerp( FrameTime() * Speed, AnimationLine, targetline )
		AnimationLineColour = LerpColour( FrameTime() * Speed, AnimationLineColour, targetlinecolour )

		local dif = math.abs( AnimationLineColour.r - targetlinecolour.r )
		if ( dif < 5 ) then
			CurrentState = States.SMALL
		end
	end
	States.SMALL = function()
		local Speed = 8

		local targetx = ScrW() / 16 * 13
		local targety = ScrH() / 16
		AnimationPosX = Lerp( FrameTime() * Speed, AnimationPosX, targetx )
		AnimationPosY = Lerp( FrameTime() * Speed, AnimationPosY, targety )

		local dif = math.abs( AnimationPosX - targetx ) + math.abs( AnimationPosY - targety )
		if ( dif < 0.5 ) then
			CurrentState = States.IDLE
		end
	end
	States.IDLE = function()
	
	end
	States.EXITSMALL = function()
		local Speed = 8

		local targetx = ScrW() / 2
		local targety = ScrH() / 8
		AnimationPosX = Lerp( FrameTime() * Speed, AnimationPosX, targetx )
		AnimationPosY = Lerp( FrameTime() * Speed, AnimationPosY, targety )

		local dif = math.abs( AnimationPosX - targetx ) + math.abs( AnimationPosY - targety )
		if ( dif < 0.5 ) then
			CurrentState = States.EXITLINE
		end
	end
	States.EXITLINE = function()
		local Speed = 8

		local targetline = 0
		local targetlinecolour = Color( 0, 0, 0, 0 )
		AnimationLine = Lerp( FrameTime() * Speed, AnimationLine, targetline )
		AnimationLineColour = LerpColour( FrameTime() * Speed, AnimationLineColour, targetlinecolour )

		local dif = math.abs( AnimationLineColour.r - targetlinecolour.r )
		if ( dif < 5 ) then
			CurrentState = States.EXIT
		end
	end
	States.EXIT = function()
		local Speed = 8

		local targetcolour = Color( 0, 0, 0, 0 )
		AnimationColour = LerpColour( FrameTime() * Speed, AnimationColour, targetcolour )

		local dif = math.abs( AnimationColour.r - targetcolour.r )
		if ( dif < 5 ) then
			LocalPlayer().Fal_Settlement = nil
		end
	end


net.Receive( "Fal_Settlement_EnterExit", function( len, ply )
	local enter = net.ReadBool()
	if ( enter ) then
		local name = net.ReadString()
		CurrentState = States.ENTER
		if ( LocalPlayer().Fal_Settlement != name ) then
			LocalPlayer().Fal_Settlement = name
			AnimationPosX = nil
		end
	else
		CurrentState = States.EXITSMALL
	end
end )

function ENT:Initialize()
	ent = self
end

function ENT:Draw()
	ent = self
	--self:DrawModel()
end

hook.Add( "PostDrawOpaqueRenderables", "Fal_Settlement_PostDrawOpaqueRenderables", function()
	if ( !ent ) then return end

	local rad = ent.Entity:GetFalRadius()

	local function drawbound( pos, ang )
		cam.Start3D2D( ent:GetPos() + pos, ang, 1 )
			surface.SetDrawColor( Color( 0, 0, 0, 50 ) )
			surface.DrawRect( 0, 0, 8, rad * 2 )
		cam.End3D2D()
	end

	-- Front
	local pos = Vector( rad, rad, -4 )
	local ang = Angle( 90, 0, 0 )
	drawbound( pos, ang )

	-- Back
	pos = Vector( -rad, rad, -4 )
	ang = Angle( 90, 0, 0 )
	drawbound( pos, ang )

	-- Left
	local pos = Vector( -rad, rad, -4 )
	local ang = Angle( 90, 90, 0 )
	drawbound( pos, ang )

	-- Right
	local pos = Vector( -rad, -rad, -4 )
	local ang = Angle( 90, 90, 0 )
	drawbound( pos, ang )
end )

hook.Add( "HUDPaint", "Fal_Settlement_HUDPaint", function()
	if ( LocalPlayer().Fal_Settlement ) then
		local x = ScrW() / 2
		local y = ScrH() / 8
		if ( CurrentState ) then
			CurrentState()
			x = AnimationPosX
			y = AnimationPosY
		end
		draw.SimpleText( LocalPlayer().Fal_Settlement, AnimationFont, x, y, AnimationColour, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		surface.SetDrawColor( AnimationLineColour.r, AnimationLineColour.g, AnimationLineColour.b, AnimationLineColour.a )
		surface.DrawRect( x - ( AnimationLine / 2 ), y + 24, AnimationLine, 2 )
		surface.SetDrawColor( 255, 255, 255, 255 )
	end
end )

function LerpColour( t, from, to )
	local colour = Color( 0, 0, 0, 0 )
		colour.r = Lerp( t, from.r, to.r )
		colour.g = Lerp( t, from.g, to.g )
		colour.b = Lerp( t, from.b, to.b )
		colour.a = Lerp( t, from.a, to.a )
	return colour
end
