local Data

function EFFECT:Init( data )
	Data = data
	self.particlemultiplier = 0.5
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	local vOffset = Data:GetOrigin()
	local vAngle = Data:GetAngles()

	local altarsize = Vector( 44, 90 )
	local altaroffset = Vector( -1, 0 )

	local rotationvector = Vector( 1, 0, 0 )
	local rotationvector2 = Vector( 0, 1, 0 )
		if ( ( vAngle.y ~= 0 ) and ( vAngle.y ~= 180 ) ) then
			rotationvector = Vector( 0, 1, 0 )
			rotationvector2 = Vector( 1, 0, 0 )
		end

	local emitter = ParticleEmitter( vOffset, false )
		for xside = -1, 1, 2 do
			for x = 0, altarsize.x * self.particlemultiplier do
				local particle = emitter:Add(
					"effects/softglow",
					vOffset +
					( ( -altarsize.x / 2 + altaroffset.x ) * rotationvector ) +
					( ( x / self.particlemultiplier ) * rotationvector ) +
					( ( altarsize.y / 2 * xside + altaroffset.y ) * rotationvector2 )
				)
				if particle then
					particle:SetAngles( vAngle )
					particle:SetVelocity( Vector( 0, 0, -math.random( 10, 20 ) / 10 ) )
					particle:SetColor( 147, 112, 219 )
						local randomcolour = math.random( 1, 10 )
						if ( randomcolour == 1 ) then
							particle:SetColor( 247, 112, 19 )
						elseif ( randomcolour == 2 ) then
							particle:SetColor( 255, 255, 255 )
						end
					particle:SetLifeTime( 0 )
					particle:SetDieTime( 4 )
					particle:SetStartAlpha( 255 )
					particle:SetEndAlpha( 0 )
					particle:SetStartSize( 0.1 )
					particle:SetStartLength( 5 )
					particle:SetEndSize( 4 )
					particle:SetEndLength( 4 )
					particle:SetGravity( Vector( 0, 0, 0 ) )
				end
			end
		end
		for yside = -1, 1, 2 do
			for y = 0, altarsize.y * self.particlemultiplier do
				local particle = emitter:Add(
					"effects/softglow",
					vOffset +
					( ( -altarsize.y / 2+ altaroffset.y ) * rotationvector2 ) +
					( ( y / self.particlemultiplier ) * rotationvector2 ) +
					( ( altarsize.x / 2 * yside + altaroffset.x ) * rotationvector )
				)
				if particle then
					particle:SetAngles( vAngle )
					particle:SetVelocity( Vector( 0, 0, -math.random( 10, 20 ) / 10 ) )
					particle:SetColor( 147, 112, 219 )
						local randomcolour = math.random( 1, 10 )
						if ( randomcolour == 1 ) then
							particle:SetColor( 247, 112, 19 )
						elseif ( randomcolour == 2 ) then
							particle:SetColor( 255, 255, 255 )
						end
					particle:SetLifeTime( 0 )
					particle:SetDieTime( 4 )
					particle:SetStartAlpha( 255 )
					particle:SetEndAlpha( 0 )
					particle:SetStartSize( 0.1 )
					particle:SetStartLength( 5 )
					particle:SetEndSize( 4 )
					particle:SetEndLength( 4 )
					particle:SetGravity( Vector( 0, 0, 0 ) )
				end
			end
		end
	emitter:Finish()
end