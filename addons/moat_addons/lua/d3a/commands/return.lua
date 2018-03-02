COMMAND.Name = "Return"

COMMAND.Flag = D3A.Config.Commands.Return
COMMAND.AdminMode = true
COMMAND.CheckRankWeight = true

COMMAND.Args = {{"player", "Name/SteamID"}}

COMMAND.Run = function(pl, args, supp)
	if (not supp[1].LastPos) then
		D3A.Chat.SendToPlayer2(pl, moat_red, supp[1]:Name() .. " has no last known position!")
		return
	end

	supp[1]:SetPos(supp[1].LastPos)
	supp[1].LastPos = nil

	D3A.Chat.BroadcastStaff2(moat_cyan, pl:Name(), moat_white, " has returned ", moat_green, supp[1]:Name(), moat_white, ".")
end