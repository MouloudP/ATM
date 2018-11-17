if SERVER then

  MsgC(Color(0, 76, 153), "-- [Logs] Chargement Coté Serveur...\n")

  local files = file.Find("atmsysteme/shared/*.lua","LUA")

  for _, file in ipairs( files ) do

    AddCSLuaFile("atmsysteme/shared/" .. file)
    include("atmsysteme/shared/" .. file)

  end

  local files = file.Find("atmsysteme/server/*.lua","LUA")

  for _, file in ipairs( files ) do

    include("atmsysteme/server/" .. file)

  end

  local files = file.Find("atmsysteme/client/*.lua","LUA")

  for _, file in ipairs( files ) do

    AddCSLuaFile("atmsysteme/client/" .. file)

  end

  MsgC(Color(0, 76, 153), "-- [Logs] Chargement Coté Serveur...\n")

end

if CLIENT then

  local files = file.Find("atmsysteme/client/*.lua","LUA")

  for _, file in ipairs( files ) do

    include("atmsysteme/client/" .. file)

  end

  local files = file.Find("atmsysteme/shared/*.lua","LUA")

  for _, file in ipairs( files ) do

    include("atmsysteme/shared/" .. file)

  end

end
