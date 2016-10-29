AddCSLuaFile( "shared.lua" )

SWEP.PrintName	= "Magic Fists"

SWEP.Author		= ""
SWEP.Purpose	= ""

SWEP.Spawnable	= true
SWEP.UseHands	= true
SWEP.DrawAmmo	= false

SWEP.ViewModel	= "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel	= ""

SWEP.ViewModelFOV	= 52
SWEP.Slot			= 0
SWEP.SlotPos		= 5

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

local AnimTime = 0
local AnimDir = 1

local ViewModel_Offset_Up = -15
local ViewModel_Offset_Right = 0
local ViewModel_Angle_Roll = 0

function SWEP:Initialize()
	self:SetWeaponHoldType( "fist" )
end

function SWEP:PreDrawViewModel( vm, wep, ply )
	vm:SetMaterial( "engine/occlusionproxy" ) -- Hide that view model with hacky material
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "NextIdle" )
end

function SWEP:UpdateNextIdle()
	local vm = self.Owner:GetViewModel()
	self:SetNextIdle( CurTime() + vm:SequenceDuration() )
end

function SWEP:PrimaryAttack( right )
	if ( SERVER ) then
		if ( CurTime() > self:GetNextPrimaryFire() ) then
			self:SetNextPrimaryFire( CurTime() + self:Cast( self.Owner.Spells[1] ) )
		end
	end
end

function SWEP:SecondaryAttack()
	if ( SERVER ) then
		if ( CurTime() > self:GetNextSecondaryFire() ) then
			self:SetNextSecondaryFire( CurTime() + self:Cast( self.Owner.Spells[2] ) )
		end
	end
end

function SWEP:OnRemove()
	if ( IsValid( self.Owner ) ) then
		local vm = self.Owner:GetViewModel()
		if ( IsValid( vm ) ) then vm:SetMaterial( "" ) end
	end
end

function SWEP:Holster( wep )
	self:OnRemove()

	return true
end

function SWEP:Deploy()
	return true
end

if ( CLIENT ) then
	local ViewModel_Dest_Up = -15
	function SWEP:GetViewModelPosition( pos, ang )
		local speed = 0.05

		local dest_up = ViewModel_Dest_Up -- Default up offset (move viewmodel down partly out of vision)
		local dest_right = 0 -- Default right offset (viewmodel centre)
			if ( input.IsKeyDown( KEY_Q ) ) then -- In spell selector
				dest_right = 2.8 -- Focus on left hand
				dest_up = -0.7 -- Move hand into screen centre
			end
			if ( input.IsKeyDown( KEY_E ) ) then -- In spell selector
				ViewModel_Dest_Up = -3
				dest_right = -2.8 -- Focus on right hand
				dest_up = -0.7 -- Move hand into screen centre
			end
		if ( ViewModel_Offset_Right != dest_right ) then
			if ( ViewModel_Offset_Right < dest_right ) then
				ViewModel_Offset_Right = ViewModel_Offset_Right + speed
				if ( ViewModel_Offset_Right > dest_right ) then
					ViewModel_Offset_Right = dest_right
				end
			else
				ViewModel_Offset_Right = ViewModel_Offset_Right - speed
				if ( ViewModel_Offset_Right < dest_right ) then
					ViewModel_Offset_Right = dest_right
				end
			end
		end
		if ( ViewModel_Offset_Up != dest_up ) then
			if ( ViewModel_Offset_Up < dest_up ) then
				ViewModel_Offset_Up = ViewModel_Offset_Up + speed
				if ( ViewModel_Offset_Up > dest_up ) then
					ViewModel_Offset_Up = dest_up
				end
			else
				ViewModel_Offset_Up = ViewModel_Offset_Up - speed
				if ( ViewModel_Offset_Up < dest_up ) then
					ViewModel_Offset_Up = dest_up
				end
			end
		end

		pos = pos + ( ang:Right() * -2 )--* ViewModel_Offset_Right )
		pos = pos + ( ang:Up() * ViewModel_Offset_Up )
		pos = pos + ( ang:Forward() * 1 )--* ViewModel_Offset_Up )

		ang = ang + Angle( 0, 0, 0 )-- ViewModel_Angle_Roll )

		return pos, ang
	end
end

function SWEP:Think()
	local vm = self.Owner:GetViewModel()
	local curtime = CurTime()
	local idletime = self:GetNextIdle()

	if ( vm and IsValid( vm ) ) then
		vm:SendViewModelMatchingSequence( vm:LookupSequence( "fists_draw" ) )

		if ( CLIENT ) then
			if ( not input.IsKeyDown( KEY_Q ) ) then
				AnimTime = AnimTime + ( AnimDir * FrameTime() * 0.3 )
					if ( AnimTime > 0.5 ) then AnimDir = -1 end
					if ( AnimTime < 0.12 ) then AnimDir = 1 end
				vm:SetAnimTime( curtime - AnimTime )
			else
				AnimTime = AnimTime + math.random( 0.005, 0.0075 )
					if ( AnimTime > math.random( 0.275, 0.285 ) ) then AnimTime = math.random( 0.285, 0.305 ) end
				vm:SetAnimTime( curtime - AnimTime )
			end
		end

		ViewModel_Angle_Roll = ViewModel_Angle_Roll + 0.001
	end
end

function SWEP:Cast( spellname )
	if ( self.Owner.SpawnInvulnerable and ( CurTime() <= self.Owner.SpawnInvulnerable ) ) then return 0 end

	-- Simple monster spell, has not random qualities
	if ( type( spellname ) == "string" ) then
		spell = GAMEMODE.Spells[spellname]
	-- Hero spell, has advanced
	else
		spellname = self.Owner.LootedSpells[spellname]
		spell = GAMEMODE.Spells[spellname.Base]
		for k, v in pairs( spellname ) do
			if ( k ~= "Name" ) then
				spell[k] = v
			end
		end
	end

	-- Ensure the player has enough mana to cast this spell
	if ( self.Owner:GetMana() < spell.ManaUsage ) then return 0.01 end

	-- Run casting logic depending on type
	if ( spell.Type == "Totem" ) then
		local cast = self:Cast_TrapTotem( spell )
		if ( cast == false ) then
			return 0
		end
	elseif ( spell.Type == "Projectile" ) then
		local cast = self:Cast_Projectile( spell )
		if ( cast == false ) then
			return 0
		end
	elseif ( spell.Type == "Touch" ) then
		local cast = self:Cast_Touch( spell )
		if ( cast == false ) then
			return 0
		end
	elseif ( spell.Type == "Misc" ) then
		local cast = self:Cast_Misc( spell )
		if ( cast == false ) then
			return 0
		end
	end

	-- Take mana from player
	self.Owner:SetMana( self.Owner:GetMana() - spell.ManaUsage )

	return spell.Cooldown
end

-- Base function for any spells which create world traps to hurt heroes,
-- or totems to buff heroes/debuff monsters
function SWEP:Cast_TrapTotem( spell )
	local firstendpos = self.Owner:EyePos() + self.Owner:EyeAngles():Forward() * spell.Range
	local tr = util.TraceLine( {
		start = self.Owner:EyePos(),
		endpos = firstendpos,
		mask = MASK_SOLID_BRUSHONLY
	} )
	-- If it hits nothing, project forward by the max range and then fire downwards
	if ( not tr.Hit ) then
		tr = util.TraceLine( {
			start = firstendpos,
			endpos = firstendpos + self.Owner:EyeAngles():Up() * -spell.Range,
			mask = MASK_SOLID_BRUSHONLY
		} )
	end

	-- If it hit something, continue on to creating the trap/totem at the point hit
	local spellent
	if ( tr.Hit ) then
		spellent = spell:Create( self.Owner, tr )
		spellent.Owner = self.Owner
		if ( spell.TotemRotate ) then
			self:Cast_TrapTotem_Rotate( spellent, tr )
		end
	end

	return spellent
end

-- Base function used as part of any spells which create world traps to hurt heroes,
-- or totems to buff heroes/debuff monsters
-- Used to rotate traps/totems depending on the hit normal of the surface cast on
function SWEP:Cast_TrapTotem_Rotate( spell, trace )
	-- Rotate the totem based on the trace hit normal
	local angle = trace.HitNormal:Angle()
	-- If the totem has been placed on a near vertical wall
	if (
		( math.abs( math.AngleDifference( angle.p, 0 ) ) <= 20 ) and
		( math.abs( math.AngleDifference( angle.r, 0 ) ) <= 20 )
	) then
		spell:SetAngles( spell:GetAngles() + ( ( -angle:Forward() * 10 ) + ( angle:Up() * 2 ) ):Angle() )
	end
end

-- Base function for any spells which fire a projectile
function SWEP:Cast_Projectile( spell )
	local spell, angle = spell:Create( self.Owner, self.Owner:GetPos() + Vector( 0, 0, 50 ) )
	spell.Owner = self.Owner

	-- Project forward out of the player a little
	local forward = ( self.Owner:EyeAngles() + angle ):Forward()
	spell:SetPos( spell:GetPos() + ( forward * 50 ) )

	-- Fire the projectile
	local physics = spell:GetPhysicsObject()
	if ( physics and IsValid( physics ) ) then
		physics:AddVelocity( forward * spell.Speed )
	end

	return spell
end

-- Base function for any spells which are close proximity
function SWEP:Cast_Touch( spell )
	-- Project forward out of the player a little
	local forward = self.Owner:EyeAngles():Forward() * self.Range
	local entsinrange = ents.FindInSphere( self.Owner:GetPos() + forward, spell.Radius )
	for k, v in pairs( entsinrange ) do
		-- Is another player
		-- NOTE: Team checking logic is done on a spell by spell basic, to allow for touch buffs for allies, and touch damages for enemies
		if ( ( v:IsPlayer() ) and ( v ~= self.Owner ) ) then
			spell:Create( self.Owner, v )
		end
	end

	return spell
end

-- Base function for any spells which have their own logic
function SWEP:Cast_Misc( spell )
	local spell, angle = spell:Create( self.Owner, self.Owner:GetPos() )
	if ( spell ) then
		spell.Owner = self.Owner
	end
	return spell
end