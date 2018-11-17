Atmm = {}
Atmm.Config = {}

Atmm.Config.StartWithMoney = 500  -- Argent donné lors de l'ouverture du compte

local meta = FindMetaTable("Player")


hook.Add("Initialize","Initialize::CreateFile",function()

  if not file.Exists("atmdata","DATA") then

    file.CreateDir("atmdata")

  end

end)

hook.Add("PlayerInitialSpawn","PlayerInitialSpawn::CreateFile",function(ply)

  if not file.Exists("atmdata/" .. ply:SteamID64() .. ".txt","DATA") then

    file.Write("atmdata/" .. ply:SteamID64() .. ".txt",Atmm.Config.StartWithMoney)

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

  end

end
