-- Matthew Cormack (@johnjoemcbob), Nichlas Rager (@dasomeone), Jordan Brown (@DrMelon)
-- 03/08/15
-- Main clientside hud visuals

-- The currently displayed progress amount, which is lerped as new information is received
local Progress = 0

-- Initialization of this message is contained within init.lua
net.Receive( "DC_Client_Round", function( len )
	local textenum = math.Round( net.ReadFloat() )
	local timer = net.ReadFloat()

	-- Store the round information on the player for rendering
	LocalPlayer().Round = {
		Enum = textenum,
		Time = CurTime() + timer
	}

	-- Send received confirmation
	net.Start( "DC_Client_Round" )
		net.WriteFloat( 0 )
		net.WriteFloat( 0 )
	net.SendToServer()
end )

function GM:InitPostEntity_HUD()

end

function GM:Think_HUD()
	
end

function GM:ContextMenuOpen()
	return true
end

function GM:OnContextMenuOpen()
	gui.EnableScreenClicker( true )

	-- Show spell description when the context menu is open
	LocalPlayer().DisplaySpellDesc = { true, true }
end

function GM:OnContextMenuClose()
	gui.EnableScreenClicker( false )
	LocalPlayer().DisplaySpellDesc = { false, false }
end

function GM:HUDPaint()
	-- Personal information
	self:HUDPaint_Health()
	self:HUDPaint_Mana()
	self:HUDPaint_Buffs()
	self:HUDPaint_Spells()
	self:HUDPaint_Ghost()
	self:HUDPaint_Quests()

	-- Control point information
	self:HUDPaint_ControlPoint_Overall()
	self:HUDPaint_ControlPoint_Current()

	-- Spell Altar information
	if ( LocalPlayer().SpellAltarCard and IsValid( LocalPlayer().SpellAltarCard ) ) then
		GAMEMODE:HUDPaint_Spell_Tooltip( ScrW() / 2, ScrH(), GAMEMODE.Spells[LocalPlayer().SpellAltarCard.AssociatedSpell.Base], LocalPlayer().SpellAltarCard.AssociatedSpell, 0, 255 )
	end

	-- Round information
	self:HUDPaint_Round()
end

-- Display health
function GM:HUDPaint_Health()
	if ( LocalPlayer().Ghost ) then return end

	local width = ScrW() / 5
	local height = ScrH() / 20
	local x = ( ScrW() / 2 ) - ( width / 2 )
	local y = ( ScrH() / 20 * 18 ) - ( height / 2 )
	local borderdivision = 20

	-- Health bar border
	draw.RoundedBox(
		0,
		x, y,
		width, height,
		Color( 50, 50, 50, 150 )
	)

	-- Move the health bar inside the border
	local x = x + height / borderdivision
	local y = y + height / borderdivision
	local width = width - ( height / borderdivision * 2 )
	local height = height - ( height / borderdivision * 2 )

	-- Health bar
	draw.RoundedBox(
		0,
		x, y,
		width * ( LocalPlayer():Health() / LocalPlayer():GetMaxHealth() ), height,
		Color( 200, 50, 50, 255 )
	)
end

-- Display mana
function GM:HUDPaint_Mana()
	if ( LocalPlayer().Ghost ) then return end

	LocalPlayer().Mana = LocalPlayer():GetNWString( "dc_mana" )
	LocalPlayer().MaxMana = 100

	local width = ScrW() / 4
	local height = ScrH() / 20
	local x = ( ScrW() / 2 ) - ( width / 2 )
	local y = ( ScrH() / 20 * 19.25 ) - ( height / 2 )
	local borderdivision = 20

	-- Mana bar border
	draw.RoundedBox(
		0,
		x, y,
		width, height,
		Color( 50, 50, 50, 150 )
	)

	-- Move the mana bar inside the border
	local x = x + height / borderdivision
	local y = y + height / borderdivision
	local width = width - ( height / borderdivision * 2 )
	local height = height - ( height / borderdivision * 2 )

	-- Mana bar
	draw.RoundedBox(
		0,
		x, y,
		width * ( 100 / 100 ), height,
		Color( 50, 50, 200, 255 )
	)
end

-- Display ghost specific information on the HUD when dead
function GM:HUDPaint_Ghost()
	if ( not LocalPlayer().Ghost ) then return end

	local width = ScrW() / 4
	local height = ScrH() / 30
	local x = ( ScrW() / 2 ) - ( width / 2 )
	local y = ( ScrH() / 20 * 19.5 ) - ( height / 2 )
	local borderdivision = 20

	-- Ghost bar border
	draw.RoundedBox(
		0,
		x, y,
		width, height,
		Color( 50, 50, 50, 150 )
	)

	-- Move the ghost bar inside the border
	local x = x + height / borderdivision
	local y = y + height / borderdivision
	local width = width - ( height / borderdivision * 2 )
	local height = height - ( height / borderdivision * 2 )

	-- Ghost bar
	draw.RoundedBox(
		0,
		x, y,
		width * ( LocalPlayer().Mana / LocalPlayer().MaxMana ), height,
		Color( 100, 50, 200, 255 )
	)

	-- Setup text
	local text = "GHOST STRENGTH"
	local font = "CloseCaption_Bold"
	local textcolour = Color( 255, 255, 255, 255 )

	-- Find the size of the text
	surface.SetFont( font )
	local _, size = surface.GetTextSize( text )

	-- Display GHOST text
	draw.DrawText( text, font, x + ( width / 2 ), y + ( height / 2 ) - ( size / 2 ), textcolour, TEXT_ALIGN_CENTER )
end

-- Display spells
function GM:HUDPaint_Spells()

end

-- Display spell tooltip
function GM:HUDPaint_Spell_Tooltip( defx, defy, spelldesc, spellval, cooldown, backalpha )

end

-- Display information about the overall location and state of all control points
function GM:HUDPaint_ControlPoint_Overall()
	-- Calculate the coordinates to display at, depending on the users resolution
	-- (the control point positions are normalized on initialization)
	local width = ScrW() / 8
	local height = ScrH() / 8
	local x = ( height / 2 )
	local y = ( height / 2 )
	local radius = width / 14
	local pathradius = radius / 4
	local playerradius = radius / 3

	-- Display the map
	if ( LocalPlayer().Minimap and LocalPlayer().Minimap.Points ) then
		-- Draw control point borders
		for k, v in pairs( LocalPlayer().Minimap.Points ) do
			draw.NoTexture()

			surface.SetDrawColor( 0, 0, 0, 255 )
			draw.Circle( x + ( width * v.Position.x ), y + height - ( height * v.Position.y ), radius, 25 )
		end
		-- Draw paths between the control points
		for k, v in pairs( LocalPlayer().Minimap.Points ) do
			if ( v.MonsterControlled ) then
				surface.SetDrawColor( 255, 0, 0, 200 )
			else
				surface.SetDrawColor( 0, 0, 255, 200 )
			end

			if ( self.ControlPoints[game.GetMap()][k].PrecedingPoint > 0 ) then
				local preceding = LocalPlayer().Minimap.Points[self.ControlPoints[game.GetMap()][k].PrecedingPoint]
				-- Draw more detailed path
				if ( v.Path ) then
					local lastpoint = Vector( v.Position.x, v.Position.y )
					for k, path in pairs( v.Path ) do
						surface.DrawLine(
							x + ( width * lastpoint.x ), y + height - ( height * lastpoint.y ),
							x + ( width * path.x ), y + height - ( height * path.y )
						)
						draw.NoTexture()
						draw.Circle( x + ( width * path.x ), y + height - ( height * path.y ), pathradius, 25 )
						lastpoint = path
					end
					surface.DrawLine(
						x + ( width * preceding.Position.x ), y + height - ( height * preceding.Position.y ),
						x + ( width * lastpoint.x ), y + height - ( height * lastpoint.y )
					)
				-- Draw straight line path
				else
					surface.DrawLine(
						x + ( width * preceding.Position.x ), y + height - ( height * preceding.Position.y ),
						x + ( width * v.Position.x ), y + height - ( height * v.Position.y )
					)
				end
			end
		end
		-- Draw control points
		for k, v in pairs( LocalPlayer().Minimap.Points ) do
			draw.NoTexture()

			if ( v.MonsterControlled ) then
				surface.SetDrawColor( 255, 0, 0, 255 )
			else
				surface.SetDrawColor( 0, 0, 255, 255 )
			end

			-- Display the number of this point, or a B for bonus
			local text = self.ControlPoints[game.GetMap()][k].PrecedingPoint
				if ( not text ) then
					text = "B"
				else
					text = text + 1
				end
			local cx = x + ( width * v.Position.x )
			local cy = y + height - ( height * v.Position.y )
			draw.Circle( cx, cy, radius * 0.8, 25 )
			draw.SimpleText( text, "Default", cx, cy, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		-- Player's position in the world
		local plyx = LocalPlayer():GetPos().x
		local plyy = LocalPlayer():GetPos().y
			-- Normalize position
			plyx = ( plyx + math.abs( LocalPlayer().Minimap.X.min ) ) / LocalPlayer().Minimap.X.dif
			plyy = ( plyy + math.abs( LocalPlayer().Minimap.Y.min ) ) / LocalPlayer().Minimap.Y.dif
			-- Scale up to minimap position
			plyx = x + ( width * plyx )
			plyy = y + height - ( height * plyy )
		draw.NoTexture()
		surface.SetDrawColor( 0, 0, 0, 255 )
		draw.Circle( plyx, plyy, playerradius, 12 )
		surface.SetDrawColor( 100, 100, 255, 255 )
			if ( LocalPlayer():Team() == TEAM_MONSTER ) then
				surface.SetDrawColor( 255, 100, 100, 255 )
			end
		draw.Circle( plyx, plyy, playerradius * 0.8, 12 )
	end
end

-- Display information about the current control point, such as name and capture progress
function GM:HUDPaint_ControlPoint_Current()
	if ( not LocalPlayer().ControlPoint ) then return end

	-- Skip to the right value if too far out
	if ( math.abs( LocalPlayer().ControlPoint.Progress - Progress ) > 50 ) then
		Progress = LocalPlayer().ControlPoint.Progress
	-- Lerp upwards if close value
	elseif ( Progress < LocalPlayer().ControlPoint.Progress ) then
		Progress = math.Approach( Progress, LocalPlayer().ControlPoint.Progress, FrameTime() * 100 )
	-- Lerp downwards
	elseif ( Progress > LocalPlayer().ControlPoint.Progress ) then
		Progress = math.Approach( Progress, LocalPlayer().ControlPoint.Progress, -FrameTime() * 100 )
	end

	-- Progress bar for capturing
	local progresscolour = Color( 0, 0, 255, 128 )
		if ( Progress ~= 100 ) then
			progresscolour = Color( 255, 0, 0, 128 )
		end
	local width = 256 / 100 * Progress
	local height = 28
	draw.RoundedBox(
		0,
		( ScrW() * 0.5 ) - ( width / 2 ), ( ScrH() * 0.01 ) - ( height / 2 ),
		width, height,
		progresscolour
	)

	-- Display the name of this point
	local textcolour = Color( 255, 255, 255, 255 )
	draw.DrawText( LocalPlayer().ControlPoint.Name, "TargetID", ScrW() * 0.5, ScrH() * 0.01, textcolour, TEXT_ALIGN_CENTER )
end

-- Display information about the current round status
function GM:HUDPaint_Round()
	if ( not LocalPlayer().Round ) then return end
	if ( CurTime() > LocalPlayer().Round.Time ) then return end

	-- Get the text format information
	local roundtextformat = GAMEMODE.RoundText[LocalPlayer().Round.Enum]

	-- Get the height of the text for centering
	surface.SetFont( roundtextformat.Font )
	local textwidth, size = surface.GetTextSize( roundtextformat.Text )
	local _, averagesize = surface.GetTextSize( "TEST" )
	size = size - averagesize

	-- Backdrop of this text
	local colour = roundtextformat.BackdropColour
	local x = ( ScrW() * 0.5 )
	local y = ( ScrH() * 0.1 )
	local width =  textwidth + ( ScrW() * 0.05 )
	local height = ScrH() * 0.1
	draw.RoundedBox(
		0,
		x - ( width / 2 ), y - ( height / 2 ),
		width, height + size,
		colour
	)

	-- Display the current round status
	local textcolour = roundtextformat.TextColour
	draw.DrawText(
		string.format( roundtextformat.Text, math.Round( LocalPlayer().Round.Time - CurTime() ) ),
		roundtextformat.Font,
		x, y - ( height / 4 ),
		textcolour,
		TEXT_ALIGN_CENTER
	)
end

hook.Add( "PostDrawOpaqueRenderables", "DC_DrawPlayerHealthBar", function()
	-- For each player, draw their health bar above their head
	for k, v in pairs( player.GetAll() ) do
		-- Different player
		if ( v ~= LocalPlayer() ) then
			-- Max distance the health bar will be visible at
			local distance = v:GetPos():Distance( LocalPlayer():GetPos() )
			if ( ( distance < 1000 ) and ( v:Health() > 0 ) ) then
				-- Initialize sizes
				local scale = 0.5
				local width = 48
				local height = 8
				local border = 2
				local health = v:Health() / v:GetMaxHealth()

				cam.Start3D2D( v:GetPos() + Vector( 0, 0, 75 ), Angle( 180, LocalPlayer():EyeAngles().y + 90, -90 ), scale )
					-- Draw health bar border
					surface.SetDrawColor( Color( 50, 50, 50, 150 ) )
					surface.DrawRect( -( width / 2 ), -( height / 2 ), width, height )

					-- Draw health bar
					surface.SetDrawColor( Color( 255, 50, 50, 200 ) )
					surface.DrawRect( -( width / 2 ) + ( border / 2 ), -( height / 2 ) + ( border / 2 ), ( width * health ) - border, height - border )
				cam.End3D2D()
			end
		end
	end
end )

-- Hide all of the default HUD elements
local HUDHide = {
	CHudHealth = true,
	CHudBattery = true,
	CHudSuitPower = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudWeaponSelection = true
}
hook.Add( "HUDShouldDraw", "DC_HUDShouldDraw", function( name )
	if ( HUDHide[ name ] ) then return false end
end )

-- From http://wiki.garrysmod.com/page/surface/DrawPoly
function draw.Circle( x, y, radius, seg )
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is need for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end