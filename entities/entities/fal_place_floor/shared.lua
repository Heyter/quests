ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "StartPos" );
	self:NetworkVar( "Vector", 1, "WidthPos" );
end
