-- Matthew Cormack (@johnjoemcbob)
-- 13/08/15
-- Spell generation and storage serverside logic
-- Actual spells are defined as separate lua files inside gamemode/spells

-- Sends to cl_spell.lua
util.AddNetworkString( "DC_Client_LootedSpells" )

local LastRoundInfo = {}
function SendClientLootedSpellInformation( ply )
	-- Flag the next message as not confirmed
	if ( not ply.MessagesReceived ) then
		ply.MessagesReceived = {}
	end
	ply.MessagesReceived["DC_Client_LootedSpells"] = -1

	-- Send the round information enum (can be looked up within shared.lua)
	net.Start( "DC_Client_LootedSpells" )
		net.WriteTable( ply.LootedSpells )
	net.Send( ply )

	-- Resend this information if it hasn't been replied to
	timer.Create( "DC_Client_LootedSpells", 1, 1, function()
		for k, ply in pairs( player.GetAll() ) do
			-- Has sent this message and not received confirmation
			if ( ply.MessagesReceived and ( ply.MessagesReceived["DC_Client_LootedSpells"] == -1 ) ) then
				-- Repeat until the client receives it
				SendClientLootedSpellInformation( ply )
			end
		end
	end )
end
net.Receive( "DC_Client_LootedSpells", function( len, ply )
	if ( not ply.MessagesReceived ) then
		ply.MessagesReceived = {}
	end
	ply.MessagesReceived["DC_Client_LootedSpells"] = true
end )

function GM:PlayerInitialSpawn_Spell( ply )
	-- Now initialized in the hero class loadout
	--ply.LootedSpells = {}
	ply:SetMana( 100 )
end

local plymeta = FindMetaTable( "Player" )

function plymeta:SetMana( value )
	self:SetNWFloat( "dc_mana", value )
end

function plymeta:GetMana()
	return self:GetNWFloat( "dc_mana" )
end

-- Store the spell on the player (in their list of possible spells, not equipped)
-- Also procedurally generates any spell values flagged as random
-- NOTE: level here is a percentage to do with which control point the loot was gained near, in order to
-- give better loot nearer the end of the game (0% - 100%)
function plymeta:AddSpell( id, level )
	local raritylevel = level
	local originalspell = GAMEMODE.Spells[id]
	local copyspell = {}
		copyspell.Base = id
	if ( originalspell.Random ) then
		for k, v in pairs( originalspell.Random ) do
			local chance = 0.8
				if ( v.ChanceMultiplier ) then
					chance = v.ChanceMultiplier
				end
			raritylevel = math.random( level * chance, level )
			copyspell[k] = v.Min + ( ( v.Max - v.Min ) / 100 * raritylevel )
		end
	end
	table.insert( self.LootedSpells, copyspell )

	-- Send information to the client
	SendClientLootedSpellInformation( self )

	-- Print to the player's chat to describe what they picked up
	local rarity = " COMMON"
		if ( raritylevel > 80 ) then
			rarity = " LEGENDARY"
		elseif ( raritylevel > 60 ) then
			rarity = "n EPIC"
		elseif ( raritylevel > 40 ) then
			rarity = " RARE"
		elseif ( raritylevel > 20 ) then
			rarity = "n UNCOMMON"
		end
	self:ChatPrint( "Picked up a"..rarity.." spell! Find a spell altar to examine it." )
end