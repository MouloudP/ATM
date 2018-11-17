AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("ATM::OpenMenu::2d3d")
util.AddNetworkString("ATM::CloseMenu::2d3d")
util.AddNetworkString("ATM::GiveOrRetryMoney::2d3d")
util.AddNetworkString("ATM::ErrorMSG::2d3d")

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube150x150x025.mdl")
	self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
	self:DropToFloor()
end


function ENT:AcceptInput(string,ent,called)
  if not called:IsPlayer() then return end

  if not called.Menu2D3DExist then

    net.Start("ATM::OpenMenu::2d3d")
    net.WriteEntity(self)
		net.WriteFloat(called:GetMoneyATM())
    net.Send(called)
    called.Menu2D3DExist = true

  end

end

net.Receive("ATM::CloseMenu::2d3d",function(_,ply)

  if ply.Menu2D3DExist then

    ply.Menu2D3DExist = false

  end

end)


net.Receive("ATM::GiveOrRetryMoney::2d3d",function(_,ply)

	local bool = net.ReadBool()
	local money = net.ReadFloat()
	local ent = net.ReadEntity()

	if money < 0 or #tostring(money) > 8 or not IsValid(ent) then return end
	if not IsValid(ply) then return end

	if bool then

		if ply:CanBuyWithATM(money) then

			ply:SetMoneyATM(ply:GetMoneyATM() - money)
			ply:setDarkRPVar("money", ply:getDarkRPVar("money") + money)

			net.Start("ATM::ErrorMSG::2d3d")
			net.WriteEntity(ent)
			net.WriteString("Argent Retiré")
			net.Send(ply)

		else

			net.Start("ATM::ErrorMSG::2d3d")
			net.WriteEntity(ent)
			net.WriteString("Transfert Impossible")
			net.Send(ply)

		end

	else

		if ply:getDarkRPVar("money") >= money then

			ply:SetMoneyATM(ply:GetMoneyATM() + money)
			ply:setDarkRPVar("money", ply:getDarkRPVar("money") - money)

			net.Start("ATM::ErrorMSG::2d3d")
			net.WriteEntity(ent)
			net.WriteString("Argent Déposé")
			net.Send(ply)

		else

			net.Start("ATM::ErrorMSG::2d3d")
			net.WriteEntity(ent)
			net.WriteString("Dépot Impossible")
			net.Send(ply)

		end

	end

end)
