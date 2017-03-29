include( "shared.lua" )

function ENT:Draw()
	-- local scale = self.Entity:GetFalScale()
	-- if ( scale != Vector( 0, 0, 0 ) ) then
		-- local mat = Matrix()
			-- mat:Scale( scale )
		-- self.Entity:EnableMatrix( "RenderMultiply", mat )
		-- self:DrawModel()
	-- end

	self.StartPos = self:GetStartPos()

	local height = 10
	local width = self:GetWidthPos()
	if ( width == Vector( 0, 0, 0 ) ) then
		width = self.Owner:GetEyeTrace().HitPos
		width.z = self.StartPos.z
		self.CurrentWidth = width
	else
		height = self:GetHeightPos()
		if ( height == 0 ) then
			height = math.abs( self.Owner:EyeAngles().x ) * 5
			self.CurrentHeight = height
		end
	end

	if ( self:GetHeightPos() == 0 ) then
		local dist = width:Distance( self.StartPos )

		local xDiff = width.x - self.StartPos.x;
		local yDiff = width.y - self.StartPos.y;
		local ang = math.atan2( yDiff, xDiff ) * 180.0 / math.pi;

		local pos = self.StartPos + Vector( 0, 0, height )
		ang = Angle( 90, ang + 90, 0 )
		cam.Start3D2D( pos, ang, 1 )
			surface.SetDrawColor( Color( 255, 165, 0, 255 ) )
			surface.DrawRect( 0, 0, height, dist )
		cam.End3D2D()
	end
end
