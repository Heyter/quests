ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "FalRadius" );
end
