-- Traitor Equipment: Throwable rollermine npc from HL2

AddCSLuaFile()

SWEP.Author = "Badger"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198021181972"

SWEP.HoldType           = "grenade"

if CLIENT then
   SWEP.PrintName       = "Rollermine"
   SWEP.Slot            = 6

   SWEP.ViewModelFlip   = false
   SWEP.ViewModelFOV    = 54
   SWEP.DrawCrosshair   = false
   
   SWEP.EquipMenuData = {
      type  = "item_weapon",
      name  = "Rollermine",
      desc  = "Rollermines will chase players down, doing shock damage."
   };

   SWEP.Icon            = "vgui/ttt/icon_rollermine"
end

SWEP.Base                   = "weapon_tttbase"

SWEP.Kind                   = WEAPON_EQUIP1
SWEP.CanBuy                 = {ROLE_TRAITOR} -- only traitors can buy

SWEP.UseHands               = true
SWEP.ViewModel              = Model("models/weapons/v_bugbait.mdl")
SWEP.WorldModel             = Model("models/roller.mdl")

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = 5.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 1.0

SWEP.NoSights               = true

local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )


function SWEP:Initialize()
   -- For whatever reason, the world model will still collide with the world using its original size
   -- Collision with players and display size is correct
   self:SetModelScale(0.25)
end

function SWEP:PrimaryAttack()
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   
   self:RollerDrop()
end

function SWEP:RollerDrop()
   if SERVER then
      local ply = self.Owner
      if not IsValid(ply) then return end

      if self.Planted then return end

      local vsrc = ply:GetShootPos()
      local vang = ply:GetAimVector()
      local vvel = ply:GetVelocity()
      
      local vthrow = vvel + vang * 500

      local rollermine = ents.Create("npc_rollermine")
      if IsValid(rollermine) then
         self.Planted = true

         rollermine:SetPos(vsrc + vang * 10)
         rollermine:SetOwner(ply)
         rollermine:Spawn()
         rollermine:Activate()
         
         local phys = rollermine:GetPhysicsObject()
         if IsValid(phys) then
            phys:SetVelocity(vthrow)
         end   

         self:Remove()
      end
   end

   self:EmitSound(throwsound)
end

function SWEP:Reload()
   return false
end

function SWEP:OnRemove()
   if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
      if IsValid(self.RollermineViewModel) then
         self.RollermineViewModel:Remove()
         self.RollermineViewModel = nil
      end
      RunConsoleCommand("lastinv")
   end
end

if CLIENT then

   function SWEP:ViewModelDrawn()
      if self.Planted then return end

      local ply = LocalPlayer()
      local viewModel = ply:GetViewModel()
      if not IsValid(viewModel) then return end

      if not IsValid(self.RollermineViewModel) then
         self.RollermineViewModel = ClientsideModel("models/roller.mdl", RENDERGROUP_VIEWMODEL)
         self.RollermineViewModel:SetModelScale(0.25)
      end

      local rightHandPos, rightHandAngle = viewModel:GetBonePosition( viewModel:LookupBone( "ValveBiped.Bip01_R_Hand" ) )
      
      rightHandPos = rightHandPos 
                     + rightHandAngle:Forward() * 2.97
                     + rightHandAngle:Up() * 0.34 
                     + rightHandAngle:Right() * 3.48
      
      local modelSettings = {
         model = "models/roller.mdl",
         pos = rightHandPos,
         angle = rightHandAngle
      }
      render.Model(modelSettings, self.RollermineViewModel)
   end
   
   function SWEP:DrawWorldModel()
      local isEquipped = IsValid(self.Owner)
      
      if isEquipped then
         self:DrawHeldWorldModel()
      else
         self:DrawModel()
      end
   end

   function SWEP:DrawHeldWorldModel()
      local rightHandPos, rightHandAngle = self.Owner:GetBonePosition(self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" ) )
      
      rightHandPos = rightHandPos 
                     + rightHandAngle:Forward() * 2.97
                     + rightHandAngle:Up() * 0.34 
                     + rightHandAngle:Right() * 3.48

      if not IsValid(self.RollermineWorldModel) then
         -- Ideally, this should be drawing the actual world model in the player's hand
         -- Couldn't get it to work so here's a clientside model instead
         self.RollermineWorldModel = ClientsideModel("models/roller.mdl", RENDERGROUP_OPAQUE)
         self.RollermineWorldModel:SetModelScale(0.25)
      end
      
      local modelSettings = {
         model = "models/roller.mdl",
         pos = rightHandPos,
         angle = rightHandAngle
      }
      render.Model(modelSettings, self.RollermineWorldModel)
   end
end