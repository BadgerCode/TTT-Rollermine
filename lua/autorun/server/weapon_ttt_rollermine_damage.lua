
-- Rollermine Configuration

local cvarOptions = FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE

CreateConVar("weapon_ttt_rollermine_damage_scale", 1.5, cvarOptions,
             "The multiplier applied to rollermine damage. (Default: 1.5)")

CreateConVar("weapon_ttt_rollermine_health", 2500, cvarOptions,
             "Rollermine health. (Default: 2500)")

CreateConVar("weapon_ttt_rollermine_explosion_damage", 75, cvarOptions,
             "Maximum damage from rollermine death explosion. (Default: 75)")



function CheckRollermineDamage( target, dmginfo )
   if target:IsPlayer() and dmginfo:GetAttacker().IsTraitorRollermine then
      
      local attacker = dmginfo:GetAttacker()
      
      if target == attacker.Deployer then
         dmginfo:SetDamage(0)
      else
         local damageScale = GetConVar("weapon_ttt_rollermine_damage_scale"):GetFloat()
         dmginfo:SetDamage(dmginfo:GetDamage() * damageScale)
         
         if attacker.Deployer and IsValid(attacker.Deployer) then
            dmginfo:SetAttacker(attacker.Deployer)
         end
      end
      
   elseif target.IsTraitorRollermine then
      dmginfo:SetDamageForce(ScaleRollermineKnockback(dmginfo:GetDamageForce()))

      DamageRollermine(target, dmginfo:GetDamage())
   end
end

hook.Add("EntityTakeDamage", "weapon_ttt_rollermine_damage", CheckRollermineDamage)


function ScaleRollermineKnockback(damageForce)
   -- Decreases damage force. Default behaviour causes rollermines to fly away
   local forceDistance = damageForce:Length()
   local targetDistance = math.min(forceDistance, 30000)
   local distanceRatio = targetDistance / forceDistance
   
   damageForce:Mul(distanceRatio)
   return damageForce
end


function DamageRollermine(rollermine, damage)
   if rollermine.RollermineDestructionPhase then return end

   local newHealth = rollermine:Health() - damage
   
   if newHealth <= 0 then
      rollermine.RollermineDestructionPhase = true
      rollermine:Fire("IgniteLifetime", 5)
      rollermine:SetHealth(0)
      
      local uniqueTimerName = "weapon_ttt_rollermine"..rollermine:EntIndex()
      timer.Create(uniqueTimerName, 3, 1, function() KillRollermine(rollermine) end)
      
   else
      rollermine:SetHealth(newHealth)
   end
end


function KillRollermine(rollermine)
   local explode = ents.Create( "env_explosion" )
      explode:SetPos(rollermine:GetPos())
      if IsValid(rollermine.Deployer) then explode:SetOwner(rollermine.Deployer) end
      explode:Spawn()
      explode:SetKeyValue("iMagnitude", GetConVar("weapon_ttt_rollermine_explosion_damage"):GetFloat())
      explode:SetKeyValue("iRadiusOverride", "400")
      explode:Fire("Explode", 0, 0)
      explode:EmitSound("NPC_RollerMine.ExplodeChirpRespond")

   rollermine:Fire("kill")
end