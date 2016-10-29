include( "shared.lua" )

function ENT:Initialize()
--
	self.AnimTime = 0
	self.AnimDir = 1
	self.Entity:SetSequence( self.Entity:LookupSequence( "fists_draw" ) )
	self.Entity:ResetSequence( self.Entity:LookupSequence( "fists_draw" ) )
--
end

function ENT:Draw()
--
	if ( LocalPlayer() == self.Entity:GetOwner() ) then
	--
		self.Entity:DrawModel()
	--
	end
--
end

function ENT:Think()
--
	if ( LocalPlayer() == self.Entity:GetOwner() ) then -- TODO: parent to viewmodel maybe
	--
		self.Entity:SetPos( LocalPlayer():EyePos() + ( LocalPlayer():GetRight() * 5 ) + ( LocalPlayer():GetForward() * -2.5 ) + ( LocalPlayer():GetUp() * -6 ) )
		self.Entity:SetAngles( LocalPlayer():EyeAngles() + Angle( 0, 0, -90 ) )
	--
	end
	self.AnimTime = self.AnimTime + ( self.AnimDir * 0.007 )
	--
		if ( self.AnimTime > 0.45 ) then self.AnimDir = -1 end
		if ( self.AnimTime < 0.2 ) then self.AnimDir = 1 end
	--
	self.Entity:SetCycle( self.AnimTime )
--
end