-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 03/08/15
-- Clientside atmospheric additions

-- Radius in which a light source must be to affect the player
local LightAffectRadius = 300

-- The affect being inside should have on the light level (from 0 dark -> 1 full light)
local LightAffectInside = 5 / 16
local LightAffectSettlement = 7 / 16

-- The speed at which to approach new atmospheric fog/light values
local AtmosphereApproachSpeed = 100
local AtmosphereLightApproachSpeed = 0.1

-- Fog max distance
local FogStart_Default = 200

-- Fog min distance
local FogStart_Dark = 70

local FogColour = Color( 170, 150, 100 )

-- The runtime fog distance value
local FogTarget = FogStart_Default
local FogStart = FogStart_Default

-- Post processing light defaults
local ps_default_brightness = -0.10
local ps_default_contrast = 1
local ps_default_colour = 0.85

-- Post processing dark defaults
local ps_dark_brightness = -0.42
local ps_dark_contrast = 0.6
local ps_dark_colour = 0.8

-- Post processing monster defaults
local ps_monster_colour = 0.1

-- Post processing runtime values
local DC_PS_Brightness = ps_default_brightness
local DC_PS_Contrast = ps_default_contrast
local DC_PS_Colour = ps_default_colour

function AtmosphereInit()
	
end
hook.Add( "Initialize", "DC_Initialize_Atmosphere", AtmosphereInit )

function AtmosphereThink()
	-- Find if the player is inside
	-- NOTE: This is used for muffling the rain sounds and lightening the screen inside
	local tr = util.TraceLine(
		{
			start = LocalPlayer():EyePos() + Vector( 0, 0, 1 ) * 20,
			endpos = LocalPlayer():EyePos() + Vector( 0, 0, 1 ) * 400,
		}
	)
	LocalPlayer().Inside = tr.Hit

	-- Setup the fake skybox to follow the player, just outside the fog radius
	-- This is present as a black curtain in case the map skybox is too bright
	if ( not LocalPlayer().ClientSkybox ) or ( not IsValid( LocalPlayer().ClientSkybox ) ) then
		LocalPlayer().ClientSkybox = ClientsideModel(
			"models/props_phx/construct/metal_dome360.mdl",
			RENDERGROUP_OPAQUE
		)
		LocalPlayer().ClientSkybox:SetMaterial( "models/debug/debugwhite" )
		LocalPlayer().ClientSkybox:SetColor( FogColour )
		LocalPlayer().ClientSkybox:SetModelScale( 40 * FogStart / 700, 0 )
	else
		LocalPlayer().ClientSkybox:SetPos( LocalPlayer():GetPos() - Vector( 0, 0, 1000 ) )
		LocalPlayer().ClientSkybox:SetColor( Color( 0, 0, 0, 255 ) )
	end
	hook.Call( "SetupWorldFog" )
end
hook.Add( "Think", "DC_Think_Atmosphere", AtmosphereThink )

-- NOTE: Original credits for this system go to Rick Dark (https://garrysmods.org/download/3952/weatheraddonzip)
function PostProcess_DarkOutside()
	-- Calculate closeness to light sources
	local max = 100
	local add = 20
	local lightlevel = 0
		-- Inside settlement override
		if ( LocalPlayer().Buffs and LocalPlayer().Buffs[GetBuffID( "Relative Safety" )] != 0 ) then
			lightlevel = lightlevel + max * LightAffectSettlement
		-- Automatically add extra light if indoors
		elseif ( LocalPlayer().Inside or ( LocalPlayer():Team() == TEAM_MONSTER ) or LocalPlayer().Ghost ) then
			lightlevel = max * LightAffectInside
		end
	for k, v in pairs( ents.FindInSphere( LocalPlayer():GetPos(), LightAffectRadius ) ) do
		if ( v.IsLightSource ) then
			lightlevel = math.Approach( lightlevel, max, add * v.LightLevel )
		end
		if ( v:GetClass() == "gmod_light" ) then
			lightlevel = math.Approach( lightlevel, max, add * 2 )
		end
	end
	-- lightlevel = max

	-- Convert this light level into post processing values
	DC_PS_Brightness_Target = ps_dark_brightness + ( ( ps_default_brightness - ps_dark_brightness ) / max * lightlevel )
	DC_PS_Contrast_Target = ps_dark_contrast + ( ( ps_default_contrast - ps_dark_contrast ) / max * lightlevel )
	DC_PS_Colour_Target = ps_dark_colour + ( ( ps_default_colour - ps_dark_colour ) / max * lightlevel )
		-- Monsters/ghosts have a separate colour value
		if ( ( LocalPlayer():Team() == TEAM_MONSTER ) or LocalPlayer().Ghost ) then
			DC_PS_Colour_Target = ps_monster_colour
		end

	-- Lerp these post processing values
	local speed = AtmosphereLightApproachSpeed
		if ( DC_PS_Brightness_Target < DC_PS_Brightness ) then
			speed = -speed
		end
	DC_PS_Brightness = math.Approach( DC_PS_Brightness, DC_PS_Brightness_Target, FrameTime() * speed )

	local speed = AtmosphereLightApproachSpeed
		if ( DC_PS_Contrast_Target < DC_PS_Contrast ) then
			speed = -speed
		end
	DC_PS_Contrast = math.Approach( DC_PS_Contrast, DC_PS_Contrast_Target, FrameTime() * speed )

	local speed = AtmosphereLightApproachSpeed
		if ( DC_PS_Colour_Target < DC_PS_Colour ) then
			speed = -speed
		end
	DC_PS_Colour = math.Approach( DC_PS_Colour, DC_PS_Colour_Target, FrameTime() * speed )

	-- Create post process effect based on the calculated closeness to light sources
	local postprocess_colourmodify = {
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0,
		["$pp_colour_brightness"] = DC_PS_Brightness,
		["$pp_colour_contrast"] = DC_PS_Contrast,
		["$pp_colour_colour"] = DC_PS_Colour
	}
	DrawColorModify( postprocess_colourmodify )

	-- Also use this light level to affect the fog distance from the player
	FogTarget = FogStart_Dark + ( FogStart_Default - FogStart_Dark ) / max * lightlevel
end
hook.Add( "RenderScreenspaceEffects", "PostProcess_DarkOutside", PostProcess_DarkOutside )

function GM:SetupWorldFog()
	-- Lerp the target fog values
	local speed = AtmosphereApproachSpeed
		if ( FogTarget < FogStart ) then
			speed = -speed
		end
	FogStart = math.Approach( FogStart, FogTarget, FrameTime() * speed )

	-- Setup fog
	render.FogMode( MATERIAL_FOG_LINEAR )
	render.FogStart( FogStart )
	render.FogEnd( FogStart * 10 )
	render.FogColor( FogColour.r, FogColour.g, FogColour.b )
	if ( LocalPlayer().ClientSkybox ) then
		LocalPlayer().ClientSkybox:SetColor( FogColour )
		LocalPlayer().ClientSkybox:SetModelScale( 0.5 * FogStart, 0 )
	end

	return true
end