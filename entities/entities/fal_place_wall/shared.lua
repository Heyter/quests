ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "StartPos" );
	self:NetworkVar( "Vector", 1, "WidthPos" );
	self:NetworkVar( "Float", 2, "HeightPos" );
end
