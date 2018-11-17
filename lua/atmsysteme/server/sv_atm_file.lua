Atmm = {}
Atmm.Config = {}

Atmm.Config.StartWithMoney = 500  -- Argent donné lors de l'ouverture du compte

local meta = FindMetaTable("Player")

util.AddNetworkString("ATM::ChangeValue::Client")


hook.Add("Initialize","Initialize::CreateFile",function()

  if not file.Exists("atmdata","DATA") then

    file.CreateDir("atmdata")

  end

end)

hook.Add("PlayerInitialSpawn","PlayerInitialSpawn::CreateFile",function(ply)

  if not file.Exists("atmdata/" .. ply:SteamID64() .. ".txt","DATA") then

    file.Write("atmdata/" .. ply:SteamID64() .. ".txt",Atmm.Config.StartWithMoney)

    timer.Simple(0.5,function()

      net.Start("ATM::ChangeValue::Client")
      net.WriteFloat(Atmm.Config.StartWithMoney)
      net.Send(ply)

    end)

  else

    timer.Simple(0.5,function()

      net.Start("ATM::ChangeValue::Client")
      net.WriteFloat(tonumber(file.Read("atmdata/" .. ply:SteamID64() .. ".txt","DATA")))
      net.Send(ply)

    end)

  end

end)

function meta:CanBuyWithATM(price)

  if file.Exists("atmdata/" .. self:SteamID64() .. ".txt","DATA") then

    if tonumber(file.Read("atmdata/" .. self:SteamID64() .. ".txt","DATA")) >= price then

      return true

    else

      return false

    end

  end

end

function meta:GetMoneyATM()

  if file.Exists("atmdata/" .. self:SteamID64() .. ".txt","DATA") then

    return tonumber(file.Read("atmdata/" .. self:SteamID64() .. ".txt","DATA"))

  end

end

function meta:SetMoneyATM(price)

  if file.Exists("atmdata/" .. self:SteamID64() .. ".txt","DATA") then

    file.Write("atmdata/" .. self:SteamID64() .. ".txt",price)

    net.Start("ATM::ChangeValue::Client")
    net.WriteFloat(price)
    net.Send(self)

  end

end
