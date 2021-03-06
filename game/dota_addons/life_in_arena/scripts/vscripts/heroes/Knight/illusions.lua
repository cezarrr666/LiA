function illusions( event )
	local caster = event.caster
	local player = caster:GetPlayerID()
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local images_count = ability:GetLevelSpecialValueFor( "images_count", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability:GetLevel() - 1 )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability:GetLevel() - 1 )
	local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability:GetLevel() - 1 )
	local radius = ability:GetLevelSpecialValueFor( "radius_hide", ability:GetLevel() - 1 )

	local casterOrigin = caster:GetAbsOrigin()
	local casterAngles = caster:GetAngles()
	local casterForward = caster:GetForwardVector()

	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.mirror_image_illusions then
		caster.mirror_image_illusions = {}
	end

	-- Kill the old images
	for k,v in pairs(caster.mirror_image_illusions) do
		if v and IsValidEntity(v) then 
			v:ForceKill(false)
		end
	end

	-- Start a clean illusion table
	caster.mirror_image_illusions = {}

	----------------------------------------------------------------------------------

	local angle = 360/(images_count+1)
	local vRandomSpawnPos = {}
	vRandomSpawnPos[1] = casterOrigin + RotatePosition(Vector(0,0,0), QAngle(0,-90,0),casterForward)*radius
	--print(vRandomSpawnPos[1],casterOrigin)
	for i=1,images_count do 
		vRandomSpawnPos[i+1] = RotatePosition(casterOrigin, QAngle(0,angle,0), vRandomSpawnPos[i])
		--print(vRandomSpawnPos[i+1])
	end


	-- At first, move the main hero to one of the random spawn positions.
	FindClearSpaceForUnit( caster, table.remove( vRandomSpawnPos,RandomInt(1, #vRandomSpawnPos)), true )

	-- Spawn illusions
	for i=1, images_count do

		local origin = table.remove( vRandomSpawnPos,RandomInt(1, #vRandomSpawnPos))

		-- handle_UnitOwner needs to be nil, else it will crash the game.
		local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
		illusion:SetOwner(caster)
	
		illusion:SetPlayerID(caster:GetPlayerID())
		illusion:SetControllableByPlayer(player, true)
		
		illusion:SetAngles( casterAngles.x, casterAngles.y, casterAngles.z )
		illusion:SetForwardVector(casterForward)
		
		-- Level Up the unit to the casters level
		local casterLevel = caster:GetLevel()
		for i=1,casterLevel-1 do
			illusion:HeroLevelUp(false)
		end

		-- Set the skill points to 0 and learn the skills of the caster
		illusion:SetAbilityPoints(0)
		for abilitySlot=0,15 do
			local ability = caster:GetAbilityByIndex(abilitySlot)
			if ability ~= nil then 
				local abilityLevel = ability:GetLevel()
				local abilityName = ability:GetAbilityName()
				local illusionAbility = illusion:FindAbilityByName(abilityName)
				illusionAbility:SetLevel(abilityLevel)
			end
		end

		-- Recreate the items of the caster
		for itemSlot=0,5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end
		
		-- set life and mana illusion
		illusion:SetMana(caster:GetMana())
		illusion:SetHealth(caster:GetHealth())

		illusion:SetBaseAgility(caster:GetBaseAgility())
		illusion:SetBaseIntellect(caster:GetBaseIntellect())
		illusion:SetBaseStrength(caster:GetBaseStrength())
		illusion:CalculateStatBonus()

		-- Set the unit as an illusion
		-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
		illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
		
		-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
		illusion:MakeIllusion()

		-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
		table.insert(caster.mirror_image_illusions, illusion)
		--
		--caster:Purge(false, true, false, true, false)
		--caster:Purge(true, true, true, true, true)
	end
	--
	local abilityM = caster:FindAbilityByName("knight_dark_gifts")
	local durationM = abilityM:GetLevelSpecialValueFor( "duration", abilityM:GetLevel() - 1 )
	local modif = caster:FindModifierByName("modifier_knight_dark_gifts")
	if modif then
		local timeSet = durationM-modif:GetElapsedTime()
		local modifIll
		-- приделаем эффект ульты на существующие в данный момент иллюзии
		for i=1, #caster.mirror_image_illusions do
			if not caster.mirror_image_illusions[i]:IsNull() then
				abilityM:ApplyDataDrivenModifier( caster, caster.mirror_image_illusions[i], 'modifier_knight_dark_gifts', {} ) --Duration = timeSet
				modifIll = caster.mirror_image_illusions[i]:FindModifierByName("modifier_knight_dark_gifts")
				modifIll:SetDuration(timeSet, false)
			end
		end
		--print("			modif:GetElapsedTime =", modif:GetElapsedTime())
	end
end

function debuff( event )
	local caster = event.caster
	--local ability = event.ability
	--
	--print(" --------------		Purge ")
	caster:Purge(false, true, false, true, false)
	--
end


