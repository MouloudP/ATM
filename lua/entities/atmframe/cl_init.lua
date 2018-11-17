include("shared.lua")


local origin = Vector(0, 0, 0)
local angle = Angle(0, 0, 0)
local normal = Vector(0, 0, 0)
local scale = 0
local maxrange = 0

-- Helper functions

local function getCursorPos()
  local p = util.IntersectRayWithPlane(LocalPlayer():EyePos(), LocalPlayer():GetAimVector(), origin, normal)

  -- if there wasn't an intersection, don't calculate anything.
  if not p then return end
  if WorldToLocal(LocalPlayer():GetShootPos(), Angle(0,0,0), origin, angle).z < 0 then return end

  if maxrange > 0 then
    if p:Distance(LocalPlayer():EyePos()) > maxrange then
      return
    end
  end

  local pos = WorldToLocal(p, Angle(0,0,0), origin, angle)

  return pos.x, -pos.y
end

local function getParents(pnl)
  local parents = {}
  local parent = pnl:GetParent()
  while parent do
    table.insert(parents, parent)
    parent = parent:GetParent()
  end
  return parents
end

local function absolutePanelPos(pnl)
  local x, y = pnl:GetPos()
  local parents = getParents(pnl)

  for _, parent in ipairs(parents) do
    local px, py = parent:GetPos()
    x = x + px
    y = y + py
  end

  return x, y
end

local function pointInsidePanel(pnl, x, y)
  local px, py = absolutePanelPos(pnl)
  local sx, sy = pnl:GetSize()

  if not x or not y then return end

  x = x / scale
  y = y / scale

  return pnl:IsVisible() and x >= px and y >= py and x <= px + sx and y <= py + sy
end

-- Input

local inputWindows = {}
local usedpanel = {}

local function isMouseOver(pnl)
  return pointInsidePanel(pnl, getCursorPos())
end

local function postPanelEvent(pnl, event, ...)
  if not IsValid(pnl) or not pnl:IsVisible() or not pointInsidePanel(pnl, getCursorPos()) then return false end

  local handled = false

  for i, child in pairs(table.Reverse(pnl:GetChildren())) do
    if postPanelEvent(child, event, ...) then
      handled = true
      break
    end
  end

  if not handled and pnl[event] then
    pnl[event](pnl, ...)
    usedpanel[pnl] = {...}
    return true
  else
    return false
  end
end

-- Always have issue, but less
local function checkHover(pnl, x, y, found)
  if not (x and y) then
    x, y = getCursorPos()
  end

  local validchild = false
  for c, child in pairs(table.Reverse(pnl:GetChildren())) do
    local check = checkHover(child, x, y, found or validchild)

    if check then
      validchild = true
    end
  end

  if found then
    if pnl.Hovered then
      pnl.Hovered = false
      if pnl.OnCursorExited then pnl:OnCursorExited() end
    end
  else
    if not validchild and pointInsidePanel(pnl, x, y) then
      pnl.Hovered = true
      if pnl.OnCursorEntered then pnl:OnCursorEntered() end

      return true
    else
      pnl.Hovered = false
      if pnl.OnCursorExited then pnl:OnCursorExited() end
    end
  end

  return false
end

-- Mouse input

hook.Add("KeyPress", "VGUI3D2DMousePress", function(_, key)
  if key == IN_USE then
    for pnl in pairs(inputWindows) do
      if IsValid(pnl) then
        origin = pnl.Origin
        scale = pnl.Scale
        angle = pnl.Angle
        normal = pnl.Normal

        local key = input.IsKeyDown(KEY_LSHIFT) and MOUSE_RIGHT or MOUSE_LEFT

        postPanelEvent(pnl, "OnMousePressed", key)
      end
    end
  end
end)

hook.Add("KeyRelease", "VGUI3D2DMouseRelease", function(_, key)
  if key == IN_USE then
    for pnl, key in pairs(usedpanel) do
      if IsValid(pnl) then
        origin = pnl.Origin
        scale = pnl.Scale
        angle = pnl.Angle
        normal = pnl.Normal

        if pnl["OnMouseReleased"] then
          pnl["OnMouseReleased"](pnl, key[1])
        end

        usedpanel[pnl] = nil
      end
    end
  end
end)

function vgui.Start3D2D(pos, ang, res)
  origin = pos
  scale = res
  angle = ang
  normal = ang:Up()
  maxrange = 0

  cam.Start3D2D(pos, ang, res)
end

function vgui.MaxRange3D2D(range)
  maxrange = isnumber(range) and range or 0
end

function vgui.IsPointingPanel(pnl)
  origin = pnl.Origin
  scale = pnl.Scale
  angle = pnl.Angle
  normal = pnl.Normal

  return pointInsidePanel(pnl, getCursorPos())
end

local Panel = FindMetaTable("Panel")
function Panel:Paint3D2D()
  if not self:IsValid() then return end

  -- Add it to the list of windows to receive input
  inputWindows[self] = true

  -- Override gui.MouseX and gui.MouseY for certain stuff
  local oldMouseX = gui.MouseX
  local oldMouseY = gui.MouseY
  local cx, cy = getCursorPos()

  function gui.MouseX()
    return (cx or 0) / scale
  end
  function gui.MouseY()
    return (cy or 0) / scale
  end

  -- Override think of DFrame's to correct the mouse pos by changing the active orientation
  if self.Think then
    if not self.OThink then
      self.OThink = self.Think

      self.Think = function()
        origin = self.Origin
        scale = self.Scale
        angle = self.Angle
        normal = self.Normal

        self:OThink()
      end
    end
  end

  -- Update the hover state of controls
  local _, tab = checkHover(self)

  -- Store the orientation of the window to calculate the position outside the render loop
  self.Origin = origin
  self.Scale = scale
  self.Angle = angle
  self.Normal = normal

  -- Draw it manually
  self:SetPaintedManually(false)
    self:PaintManual()
  self:SetPaintedManually(true)

  gui.MouseX = oldMouseX
  gui.MouseY = oldMouseY
end

function vgui.End3D2D()
  cam.End3D2D()
end


surface.CreateFont( "FontATM2D3D1", {
font = "Roboto",
size = 60,
weight = 1000,
})

surface.CreateFont( "FontATM2D3D2", {
    font = "Roboto",
    size = 22,
    weight = 1000,
})

surface.CreateFont( "FontATM2D3D3", {
    font = "Roboto",
    size = 24,
    weight = 1000,
})

surface.CreateFont( "FontATM2D3D4", {
    font = "Arial",
    size = 30,
    weight = 700,
})
surface.CreateFont( "FontATM2D3D5", {
    font = "Arial",
    size = 15,
    weight = 1000,
})

local functi = {}


net.Receive("ATM::OpenMenu::2d3d",function()

  local atm_menu = {}
  local ent = net.ReadEntity()
  local money = net.ReadFloat()

  atm_menu.BaseBox = vgui.Create("DFrame")
  atm_menu.BaseBox:SetSize(700, 700)
  atm_menu.BaseBox:SetPos(0,0)
  atm_menu.BaseBox:SetTitle("")
  atm_menu.BaseBox:ShowCloseButton(false)
  atm_menu.BaseBox:SetVisible(true)
  atm_menu.BaseBox:SetDraggable(false)
  atm_menu.BaseBox.Paint = function(self,w,h)

      draw.RoundedBox(6, 0, 0, w, h, Color(107, 126, 255))
      draw.RoundedBox(6, w/300, h/165, w/1.007, h/1.012, Color(255, 255, 255, 255))
      draw.DrawText("Distributeur", "FontATM2D3D1", w/2, h/100, Color(107, 126, 255), TEXT_ALIGN_CENTER)
      draw.DrawText("En Banque : " .. LocalPlayer():GetMoneyATM() .. "$", "FontATM2D3D1", w/2, h/5, Color(107, 126, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.close = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.close:SetSize(70, 30)
  atm_menu.close:SetPos(600, 20)
  atm_menu.close:SetText("")
  atm_menu.close:SetTextColor(Color(0,0,0,255))
  atm_menu.close.Paint = function(self,w,h)

      draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
      draw.DrawText("X", "FontATM2D3D4", w/2, h/200, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.close.DoClick = function()

      atm_menu.BaseBox:Remove()

      net.Start("ATM::CloseMenu::2d3d")
      net.SendToServer()

  end

  atm_menu.Deposer = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.Deposer:SetSize(400, 100)
  atm_menu.Deposer:Center()
  atm_menu.Deposer:SetText("")
  atm_menu.Deposer:SetTextColor(Color(0,0,0,255))
  atm_menu.Deposer.Paint = function(self,w,h)

    draw.RoundedBox(6, 0, 0, w, h, Color(107, 126, 255))
    draw.RoundedBox(6, w/100, h/20, w/1.02, h/1.13, Color(255, 255, 255, 255))
    draw.DrawText("Déposer", "FontATM2D3D1", w/2, h/5, Color(107, 126, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.Deposer.DoClick = function(self)

    atm_menu.BaseBox:Remove()
    functi.MenuKeypad(false, ent)

  end

  atm_menu.Retiré = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.Retiré:SetSize(400, 100)
  atm_menu.Retiré:Center()
  atm_menu.Retiré:CenterVertical(0.7)
  atm_menu.Retiré:SetText("")
  atm_menu.Retiré:SetTextColor(Color(0,0,0,255))
  atm_menu.Retiré.Paint = function(self,w,h)

    draw.RoundedBox(6, 0, 0, w, h, Color(107, 126, 255))
    draw.RoundedBox(6, w/100, h/20, w/1.02, h/1.13, Color(255, 255, 255, 255))
    draw.DrawText("Retirer", "FontATM2D3D1", w/2, h/5, Color(107, 126, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.Retiré.DoClick = function(self)

    atm_menu.BaseBox:Remove()
    functi.MenuKeypad(true, ent)

  end

  local pos = ent:GetPos() + ent:GetUp() * 6.5 + ent:GetForward() * 35 + ent:GetRight() * -35
  local ang = ent:GetAngles()

  ang:RotateAroundAxis( ang:Up(), 270 )

  hook.Add( "PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables::ATMOpenMenu", function()

    vgui.Start3D2D( pos, ang, 0.1 )

      atm_menu.BaseBox:Paint3D2D()

    vgui.End3D2D()

  end)

end)


function functi.MenuKeypad(bool, ent)

  local atm_menu = {}

  local number = 0

  atm_menu.BaseBox = vgui.Create("DFrame")
  atm_menu.BaseBox:SetSize(700, 700)
  atm_menu.BaseBox:SetPos(0,0)
  atm_menu.BaseBox:SetTitle("")
  atm_menu.BaseBox:ShowCloseButton(false)
  atm_menu.BaseBox:SetVisible(true)
  atm_menu.BaseBox:SetDraggable(false)
  atm_menu.BaseBox.Paint = function(self,w,h)

      draw.RoundedBox(6, 0, 0, w, h, Color(107, 126, 255))
      draw.RoundedBox(6, w/300, h/165, w/1.007, h/1.012, Color(255, 255, 255, 255))
      draw.DrawText("Distributeur", "FontATM2D3D1", w/2, h/100, Color(107, 126, 255), TEXT_ALIGN_CENTER)
      draw.DrawText(number .. "$", "FontATM2D3D1", w/2, h/7, Color(107, 126, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.close = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.close:SetSize(70, 30)
  atm_menu.close:SetPos(600, 20)
  atm_menu.close:SetText("")
  atm_menu.close:SetTextColor(Color(0,0,0,255))
  atm_menu.close.Paint = function(self,w,h)

      draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
      draw.DrawText("X", "FontATM2D3D4", w/2, h/200, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.close.DoClick = function()

      atm_menu.BaseBox:Remove()

      net.Start("ATM::CloseMenu::2d3d")
      net.SendToServer()

  end

  atm_menu.PanelOfkeypad = vgui.Create("DPanel", atm_menu.BaseBox)
  atm_menu.PanelOfkeypad:SetSize(300,500)
  atm_menu.PanelOfkeypad:Center()
  atm_menu.PanelOfkeypad:CenterVertical(0.65)
  atm_menu.PanelOfkeypad.Paint = function(self, w, h)
  end


  atm_menu.scroll = vgui.Create("DScrollPanel", atm_menu.PanelOfkeypad)
  atm_menu.scroll:Dock(FILL)


  atm_menu.sbar = atm_menu.scroll:GetVBar()
  function atm_menu.sbar:Paint()end
  function atm_menu.sbar.btnUp:Paint() end
  function atm_menu.sbar.btnDown:Paint() end
  function atm_menu.sbar.btnGrip:Paint() end

  atm_menu.layout = vgui.Create("DIconLayout", atm_menu.scroll)
  atm_menu.layout:Dock(FILL)
  atm_menu.layout:SetSpaceY(5)
  atm_menu.layout:SetSpaceX(5)



  for i=1 , 9 do

    atm_menu.Keypad = vgui.Create("DButton", atm_menu.layout)
    atm_menu.Keypad:SetSize(atm_menu.PanelOfkeypad:GetWide() / 3.1, atm_menu.PanelOfkeypad:GetWide() / 3.1)
    atm_menu.Keypad:SetText("")
    atm_menu.Keypad:SetTextColor(Color(0,0,0,255))
    atm_menu.Keypad.Paint = function(self,w,h)

        draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
        draw.DrawText(i, "FontATM2D3D1", w/2, h/5, Color(255, 255, 255), TEXT_ALIGN_CENTER)

    end

    atm_menu.Keypad.DoClick = function()

      if #tostring(number) < 8 then

        number = number * 10 + i

      end

    end

  end

  atm_menu.Number0 = vgui.Create("DButton", atm_menu.layout)
  atm_menu.Number0:SetSize(atm_menu.Keypad:GetWide() *3 + 10, atm_menu.PanelOfkeypad:GetWide() / 3.1)
  atm_menu.Number0:SetText("")
  atm_menu.Number0:SetTextColor(Color(0,0,0,255))
  atm_menu.Number0.Paint = function(self,w,h)

      draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
      draw.DrawText("0", "FontATM2D3D1", w/2, h/5, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.Number0.DoClick = function()

    if #tostring(number) < 8 then

      number = number * 10

    end

  end

  atm_menu.Delete = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.Delete:SetSize(atm_menu.PanelOfkeypad:GetWide() / 3.1, atm_menu.PanelOfkeypad:GetWide() / 3.1)
  atm_menu.Delete:SetPos(atm_menu.PanelOfkeypad:GetWide() *1.7 , 205)
  atm_menu.Delete:SetText("")
  atm_menu.Delete:SetTextColor(Color(0,0,0,255))
  atm_menu.Delete.Paint = function(self,w,h)

      draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
      draw.DrawText("<", "FontATM2D3D1", w/2, h/5, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.Delete.DoClick = function()

    if #tostring(number) > 0 then

      number = string.Replace(number, string.Right(number,1), "")

      if #tostring(number) == 0 then

        number = 0

      end

    end

  end

  atm_menu.Valider = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.Valider:SetSize(atm_menu.PanelOfkeypad:GetWide(), atm_menu.PanelOfkeypad:GetWide() / 5)
  atm_menu.Valider:Center()
  atm_menu.Valider:CenterVertical(0.91)
  atm_menu.Valider:SetText("")
  atm_menu.Valider:SetTextColor(Color(0,0,0,255))
  atm_menu.Valider.Paint = function(self,w,h)

      draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
      draw.DrawText("Valider", "FontATM2D3D1", w/2, h/200, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.Valider.DoClick = function()

    atm_menu.BaseBox:Remove()

    net.Start("ATM::GiveOrRetryMoney::2d3d")
    net.WriteBool(bool)
    net.WriteFloat(number)
    net.WriteEntity(ent)
    net.SendToServer()

  end




  local pos = ent:GetPos() + ent:GetUp() * 6.5 + ent:GetForward() * 35 + ent:GetRight() * -35
  local ang = ent:GetAngles()

  ang:RotateAroundAxis( ang:Up(), 270 )

  hook.Add( "PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables::ATMOpenMenu", function()

    vgui.Start3D2D( pos, ang, 0.1 )

      atm_menu.BaseBox:Paint3D2D()

    vgui.End3D2D()

  end)


end

net.Receive("ATM::ErrorMSG::2d3d",function(_,ply)

  local ent = net.ReadEntity()
  local string = net.ReadString()

  local atm_menu = {}

  atm_menu.BaseBox = vgui.Create("DFrame")
  atm_menu.BaseBox:SetSize(700, 700)
  atm_menu.BaseBox:SetPos(0,0)
  atm_menu.BaseBox:SetTitle("")
  atm_menu.BaseBox:ShowCloseButton(false)
  atm_menu.BaseBox:SetVisible(true)
  atm_menu.BaseBox:SetDraggable(false)
  atm_menu.BaseBox.Paint = function(self,w,h)

      draw.RoundedBox(6, 0, 0, w, h, Color(107, 126, 255))
      draw.RoundedBox(6, w/300, h/165, w/1.007, h/1.012, Color(255, 255, 255, 255))
      draw.DrawText("Distributeur", "FontATM2D3D1", w/2, h/100, Color(107, 126, 255), TEXT_ALIGN_CENTER)
      draw.DrawText(string, "FontATM2D3D1", w/2, h/2, Color(107, 126, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.close = vgui.Create("DButton", atm_menu.BaseBox)
  atm_menu.close:SetSize(70, 30)
  atm_menu.close:SetPos(600, 20)
  atm_menu.close:SetText("")
  atm_menu.close:SetTextColor(Color(0,0,0,255))
  atm_menu.close.Paint = function(self,w,h)

      draw.RoundedBox(3, 0, 0, w, h, Color(107, 126, 255) )
      draw.DrawText("X", "FontATM2D3D4", w/2, h/200, Color(255, 255, 255), TEXT_ALIGN_CENTER)

  end

  atm_menu.close.DoClick = function()

      atm_menu.BaseBox:Remove()

      net.Start("ATM::CloseMenu::2d3d")
      net.SendToServer()

  end

  local pos = ent:GetPos() + ent:GetUp() * 6.5 + ent:GetForward() * 35 + ent:GetRight() * -35
  local ang = ent:GetAngles()

  ang:RotateAroundAxis( ang:Up(), 270 )

  hook.Add( "PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables::ATMOpenMenu" .. math.random(0,99999), function()

    vgui.Start3D2D( pos, ang, 0.1 )

      atm_menu.BaseBox:Paint3D2D()

    vgui.End3D2D()

  end)

--[[  timer.Simple(5,function()

    if IsValid(atm_menu.BaseBox) then

      atm_menu.BaseBox:Remove()
      net.Start("ATM::CloseMenu::2d3d")
      net.SendToServer()

    end

  end)]]


end)
