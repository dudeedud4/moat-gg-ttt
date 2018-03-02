COMMAND.Name = "Unban"

COMMAND.Flag = D3A.Config.Commands.Unban
COMMAND.AdminMode = true

COMMAND.Args = {{"string", "SteamID"}, {"string", "Reason"}}

COMMAND.Run = function(pl, args, supp)
	local sid = tostring(args[1]):upper()
	
	if (string.sub(sid, 1, 8) != "STEAM_0:") then
		D3A.Chat.SendToPlayer2(pl, moat_red, "Please input a SteamID!")
		return
	end
	
	D3A.Bans.GetBans(sid, function(Bans)
		if (!Bans.Current) then
			D3A.Chat.SendToPlayer2(pl, moat_red, sid .. " is not banned!")
		else
			local reason = table.concat(args, " ", 2)
			if (D3A.Bans.Unban(sid, reason, Bans.Current.time)) then
				D3A.Chat.Broadcast2(moat_cyan, ((pl:IsValid() and pl:Name()) or "Console"), moat_white, " has unbanned ", moat_green, sid, moat_white, ". Reason: ", moat_green, reason, moat_white, ".")
				local msg = ((pl:IsValid() and pl:Name()) or "Console") .. " (" .. ((pl:IsValid() and pl:SteamID()) or "Console") ..") has *unbanned* " .. sid.. ". Reason: " .. reason .. "."
				SVDiscordRelay.SendToDiscordRaw("Ban bot",false,msg,"https://discordapp.com/api/webhooks/393120753593221130/bPZTXCj5fjQgHJCOKDPbUj4Btq5EtqkZSKV-ewwaLwESwZEEc7fBHBWuIbe8np2FG8Jn")
			else
				D3A.Chat.SendToPlayer2(pl, moat_red, "An unexpected error has occurred while unbanning. Tell the boss!")
			end
		end
	end)
end