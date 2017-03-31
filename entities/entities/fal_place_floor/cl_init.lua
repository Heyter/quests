include( "shared.lua" )

function ENT:Draw()
	-- self.StartPos = self:GetStartPos()

	-- local width = self:GetWidthPos()
	-- if ( width == Vector( 0, 0, 0 ) ) then
		-- width = self.Owner:GetEyeTrace().HitPos
		-- width.z = self.StartPos.z
		-- self.CurrentWidth = width
	-- end

	-- local xDiff = width.x - self.StartPos.x;
	-- local yDiff = width.y - self.StartPos.y;
	-- local ang = math.atan2( yDiff, xDiff ) * 180.0 / math.pi;

	-- local pos = self.StartPos + Vector( 0, 0, 0 )
	-- ang = Angle( 0, ang, 0 )
	-- cam.Start3D2D( pos, ang, 1 )
		-- surface.SetDrawColor( Color( 255, 165, 0, 255 ) )
		-- surface.DrawRect( 0, 0, xDiff, yDiff )
	-- cam.End3D2D()
end
