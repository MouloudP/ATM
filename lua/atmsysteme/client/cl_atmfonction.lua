local meta = FindMetaTable("Player")

net.Receive("ATM::ChangeValue::Client",function()

  LocalPlayer():SetNWInt("Ply::GetMoneyATM",net.ReadFloat())

end)

function meta:GetMoneyATM()

  return self:GetNWInt("Ply::GetMoneyATM")

end
