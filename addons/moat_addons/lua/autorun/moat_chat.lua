if (SERVER) then
    AddCSLuaFile("autorun/moat_chat.lua")

    return
end

surface.CreateFont("moat_ChatFont", {
    font = "Arial",
    size = 16,
    weight = 1200
})

local math              = math
local table             = table
local draw              = draw
local team              = team
local IsValid           = IsValid
local CurTime           = CurTime
local draw_SimpleText = draw.SimpleText
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local draw_RoundedBox = draw.RoundedBox
local draw_RoundedBoxEx = draw.RoundedBoxEx
local surface_SetFont = surface.SetFont
local surface_DrawRect = surface.DrawRect
local surface_DrawLine = surface.DrawLine
local surface_GetTextSize = surface.GetTextSize
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local blur = Material("pp/blurscreen")
local gradient_u = Material("vgui/gradient-u")
local gradient_r = Material("vgui/gradient-r")
local gradient_d = Material("vgui/gradient-d")
local default_x, default_y = chat.GetChatBoxPos()

if (moat_chat and moat_chat.BG) then
    moat_chat.BG:Remove()
end

moat_chat = {}

moat_chat.config = {
    x = default_x + 17,
    y = default_y - 20,
    w = 514,
    h = 222
}

if ((default_y + 222) > (ScrH() - 180)) then
    moat_chat.config.y = ScrH() - 180 - 242
end

moat_chat.font = "moat_ChatFont"
moat_chat.chattype = ""
moat_chat.alpha = 0
moat_chat.header = "General Chat | Website: Moat.GG"
moat_chat.isopen = false

moat_chat.sayvars = {
    {
        w = 45
    },
    {
        w = 93
    }
}

moat_chat.curx = 0
moat_chat.FadeTime = 10
moat_chat.MaxItems = 150

moat_chat.TextSize = {
    w = 0,
    h = 0
}
surface_SetFont("moat_ChatFont")
moat_chat.TextSize.w, moat_chat.TextSize.h = surface_GetTextSize("AbC1230")
moat_chat.click = CurTime()
moat_chat.SelectedMessage = nil
moat_chat.HighlightColor = Color(255, 255, 255, 100)
moat_chat.Theme = {
    CHAT_BG = function(s, w, h, a)

    end,
    CHAT_PANEL = function(s, w, h, a)

    end,
    CHAT_ENTRY = function(s, w, h, a)

    end,
    DefaultColor = Color(255, 255, 255)
}

local blur = Material("pp/blurscreen")

local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface_SetDrawColor(255, 255, 255, moat_chat.alpha * 255)
    surface_SetMaterial(blur)

    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface_DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

if (not ConVarExists("moat_gangsta")) then
    CreateClientConVar("moat_gangsta", 0, true, false)
end

function m_GetFullItemName(itemtbl)
    local ITEM_NAME_FULL = ""

    if (itemtbl.n) then
        return "\"" .. itemtbl.n:Replace("''", "'") .. "\""
    end

    if (itemtbl.item.Kind == "tier") then
        local ITEM_NAME = weapons.Get(itemtbl.w).PrintName

        if (string.EndsWith(ITEM_NAME, "_name")) then
            ITEM_NAME = string.sub(ITEM_NAME, 1, ITEM_NAME:len() - 5)
            ITEM_NAME = string.upper(string.sub(ITEM_NAME, 1, 1)) .. string.sub(ITEM_NAME, 2, ITEM_NAME:len())
        end

        ITEM_NAME_FULL = itemtbl.item.Name .. " " .. ITEM_NAME

        if (itemtbl.item.Rarity == 0) then
            ITEM_NAME_FULL = ITEM_NAME
        end
    else
        ITEM_NAME_FULL = itemtbl.item.Name
    end

    return ITEM_NAME_FULL
end

function moat_chat.AlphaControl(s)
    if (moat_chat.isopen) then
        local ctime = CurTime() + 0.5
        local contents = moat_chat.SPNL.Chat.Contents

        for i = 1, #contents do
            if (isnumber(contents[i].CreateTime)) then
                if (contents[i].CreateTime >= ctime) then continue end
            end

            contents[i].CreateTime = ctime
        end

        return true
    else
        return false
    end
end

local function m_PaintChatVBar(sbar)
    sbar.moving = false
    sbar.alpha = 0

    function sbar:Paint(w, h)
        if (not moat_chat.isopen) then
            sbar.alpha = Lerp(10 * FrameTime(), sbar.alpha, 0)
        else
            sbar.alpha = Lerp(10 * FrameTime(), sbar.alpha, 1)
        end

        draw_RoundedBox(0, 0, 4, 11, h - 8, Color(0, 0, 0, 100 * sbar.alpha))
    end

    local vbar_moving = false

    function sbar.btnGrip:Paint(w, h)
        /*
        local draw_color = Color(64, 64, 64, 255 * sbar.alpha)

        if (not input.IsMouseDown(MOUSE_LEFT) and vbar_moving) then
            vbar_moving = false
        end

        if (self:IsHovered()) then
            draw_color = Color(72, 72, 72, 255 * sbar.alpha)

            if (input.IsMouseDown(MOUSE_LEFT)) then
                vbar_moving = true
            end

            self:SetCursor("hand")
        end

        if (vbar_moving) then
            self:SetCursor("hand")
            draw_color = Color(64, 64, 100, 255 * sbar.alpha)
        end

        draw_RoundedBox(0, 0, 0, 11, h, draw_color)
        surface_SetDrawColor(Color(50, 50, 50, 255 * sbar.alpha))
        surface_SetMaterial(gradient_r)
        surface_DrawTexturedRect(0, 0, 11, h)*/

        local draw_color = Color(150, 150, 150, 50  * sbar.alpha)

        if (not input.IsMouseDown(MOUSE_LEFT) and sbar.moving) then
            sbar.moving = false
        end

        if (self:IsHovered()) then
            draw_color = Color(150, 150, 150, 100 * sbar.alpha)

            if (input.IsMouseDown(MOUSE_LEFT)) then
                sbar.moving = true
            end

            self:SetCursor("hand")
        end

        if (sbar.moving) then
            self:SetCursor("hand")
            draw_color = Color(200, 200, 200, 100  * sbar.alpha)
            sbar.LerpTarget = sbar:GetScroll()
        end

        draw_RoundedBox(0, 0, 0, 11, h, draw_color)
    end

    function sbar.btnUp:Paint(w, h)
        local draw_color = Color(150, 150, 150, 255 * sbar.alpha)

        if (self:IsHovered()) then
            draw_color = Color(255, 255, 255, 255 * sbar.alpha)
        end

        surface_SetDrawColor(draw_color)
        surface_DrawLine(1, 4 + 6, 6, 5)
        surface_DrawLine(9, 4 + 6, 4, 5)
        surface_DrawLine(2, 4 + 6, 6, 6)
        surface_DrawLine(8, 4 + 6, 4, 6)
    end

    function sbar.btnDown:Paint(w, h)
        local draw_color = Color(150, 150, 150, 255 * sbar.alpha)

        if (self:IsHovered()) then
            draw_color = Color(255, 255, 255, 255 * sbar.alpha)
        end

        surface_SetDrawColor(draw_color)
        surface_DrawLine(1, 4, 6, 4 + 5)
        surface_DrawLine(9, 4, 4, 4 + 5)
        surface_DrawLine(2, 4, 6, 4 + 4)
        surface_DrawLine(8, 4, 4, 4 + 4)
    end
end

function moat_chat.CloseChat()
    local mc = moat_chat
    mc.BG:KillFocus()
    mc.BG:SetKeyBoardInputEnabled(false)
    mc.BG:SetMouseInputEnabled(false)
    mc.ENTRY:KillFocus()
    hook.Call("FinishChat", GAMEMODE)
    hook.Call("ChatTextChanged", GAMEMODE, "")
end

function moat_chat.AutoComplete(entry, auto)
    local match
    local words = string.Explode(" ", entry:GetValue())
    match = words[#words]
    if (not match or match == "") then return end
    local ply

    for k, v in ipairs(player.GetAll()) do
        if ((string.find(v:Name():lower(), match:lower(), 1, true) or -1) == 1) then
            ply = v
            break
        end
    end

    if (ply) then
        local pref = string.sub(entry:GetValue(), 1, 1)
        local add
        local firstarg = string.sub(entry:GetValue(), 1, (string.find(entry:GetValue(), " ") or (#entry:GetValue() + 1)) - 1)

        if ((pref == "!" or pref == "!") and (not auto)) then
            add = ply:SteamID()
        else
            add = ply:Name()
        end

        if (not auto) then
            entry:SetText(string.sub(entry:GetValue(), 1, -(#match + 1)) .. add .. " ")
        else
            return string.sub(add, #match + 1)
        end

        return
    end
end

function moat_chat.Speak(str, t)
    if (t) then
        RunConsoleCommand("say_team", str)
    else
        RunConsoleCommand("say", str)
    end
end

function moat_chat.Gangsta(str, func)
    http.Post("http://www.gizoogle.net/textilizer.php", {translatetext = str}, function(res)
        func(res:match("<textarea type=\"text\" name=\"translatetext\" style=\"width: 600px; height:250px;\"/>(.-)</textarea>"))
    end)
end

local MousePressedX, MousePressedY, MouseReleasedX, MouseReleasedY, SelectedChatMsg, SelectingText
local function MousePress()
    local pan = vgui.GetHoveredPanel()
    if !pan or !pan.IsChatTextPanel then return end
    MousePressedX, MousePressedY = pan:CursorPos()
    SelectedChatMsg = pan
    SelectingText = true
end
local function MouseRelease()
    SelectingText = false
    local pan = vgui.GetHoveredPanel()
    if !pan or !pan.IsChatTextPanel then return end
    MouseReleasedX, MouseReleasedY = pan:CursorPos()
end
local mouseDown
local function ChatThink() // GUIMousePressed/Released hooks are both broken, thanks garry :^) (aren't called when pressed on chat)
    if (not moat_chat.isopen) then return end
    
    local down = input.IsMouseDown(MOUSE_LEFT)
    if down and !mouseDown then
        MousePress()
        mouseDown = true
    elseif !down and mouseDown then
        MouseRelease()
        mouseDown = false
    elseif !down and !mouseDown and SelectedChatMsg and input.IsMouseDown(MOUSE_RIGHT) then
        SelectedChatMsg = nil
    elseif SelectedChatMsg and SelectedChatMsg:IsValid() and input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_C) then
        local str = ""
        for i=1, #SelectedChatMsg.TextTable do
            if SelectedChatMsg.TextTable[i][4] then
                str = table.concat({str, SelectedChatMsg.TextTable[i][1]}, "")
            end
        end
        SetClipboardText(str)
    end
end
hook.Add("Think", "NewChatThink", ChatThink)

local customchatx = CreateConVar("moat_chatbox_x", tostring(moat_chat.config.x), FCVAR_ARCHIVE)
local customchaty = CreateConVar("moat_chatbox_y", tostring(moat_chat.config.y), FCVAR_ARCHIVE)

concommand.Add("moat_resetchat", function()
    moat_chat.config.x = tonumber(customchatx:GetDefault())
    moat_chat.config.y = tonumber(customchaty:GetDefault())

    customchatx:SetInt(moat_chat.config.x)
    customchaty:SetInt(moat_chat.config.y)

    moat_chat.BG:SetPos(customchatx:GetInt(), customchaty:GetInt())
end)

function moat_chat.InitChat()
    local mc = moat_chat
    local mcc = mc.config

    mc.BG = vgui.Create("DFrame")
    local FRAME = mc.BG
    FRAME:SetTitle("")
    FRAME:ShowCloseButton(false)
    FRAME:SetDraggable(false)
    FRAME:SetSize(mcc.w, mcc.h)
    FRAME:SetPos(customchatx:GetInt(), customchaty:GetInt())

    FRAME.Paint = function(s, w, h)
        COLOR_WHITE = Color(255, 255, 255, 255)
        color_white = Color(255, 255, 255, 255)
        if (not mc.AlphaControl(s)) then
            mc.alpha = Lerp(10 * FrameTime(), mc.alpha, 0)
        else
            mc.alpha = Lerp(10 * FrameTime(), mc.alpha, 1)
            if (input.IsKeyDown(KEY_ESCAPE)) then
                RunConsoleCommand("cancelselect")
                SelectedChatMsg = nil
                mc.ENTRY:SetText("")
                mc.ENTRY.AutocompleteText = nil
                mc.CloseChat()
            end
        end

        /*surface_SetDrawColor(62, 62, 64, 255 * mc.alpha)
        surface_DrawOutlinedRect(0, 0, w, h)
        draw_RoundedBox(0, 1, 1, w - 2, h - 2, Color(34, 35, 38, 250 * mc.alpha))
        surface_SetDrawColor(0, 0, 0, 120 * mc.alpha)
        surface_SetMaterial(gradient_d)
        surface_DrawTexturedRect(1, 1, w - 2, h - 2)
        surface_SetDrawColor(0, 0, 0, 150 * mc.alpha)
        surface_SetMaterial(gradient_d)
        surface_DrawTexturedRect(1, 1, w - 2, 20)*/

        /*surface_SetDrawColor(0, 0, 0, 100 * mc.alpha)
        surface_DrawRect(0, 0, w, h)

        surface_SetDrawColor(83, 83, 83, 175 * mc.alpha)
        surface_DrawOutlinedRect(0, 0, w, h)*/

        if (moat_chat.Theme.CHAT_BG) then
            moat_chat.Theme.CHAT_BG(s, w, h, mc, DrawBlur)
            return
        end

        DrawBlur(s, 5)

        draw_RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 50 * mc.alpha))
        draw_RoundedBox(0, 1, 1, w-2, h-2, Color(0, 0, 0, 50 * mc.alpha))

        surface_SetDrawColor(150, 150, 150, 50 * mc.alpha)
        surface_DrawRect(0, 0, w, 21)

        draw.DrawText(mc.header, mc.font, 6, 2, Color(255, 255, 255, 255 * mc.alpha))
        local chat_str = "Say :"
        local chat_type = 1

        if (#mc.chattype > 1) then
            chat_str = "Say (TEAM) :"
            chat_type = 2
        end

        /*surface_SetDrawColor(62, 62, 64, 255 * mc.alpha)
        surface_DrawOutlinedRect(5, mcc.h - 25, moat_chat.sayvars[chat_type].w, 20)
        surface_SetDrawColor(0, 0, 0, 150 * mc.alpha)
        surface_SetMaterial(gradient_d)
        surface_DrawTexturedRect(5, mcc.h - 25, moat_chat.sayvars[chat_type].w, 20)*/
        draw.DrawText(chat_str, mc.font, 10, mcc.h - 24, Color(255, 255, 255, 255 * mc.alpha))
    end

    local moveicon = Material("icon16/arrow_out.png")

    mc.MOVE = vgui.Create("DButton", FRAME)
    mc.MOVE:SetPos(mcc.w - 18, 2)
    mc.MOVE:SetSize(16, 16)
    mc.MOVE:SetText("")
    mc.MOVE.Paint = function(s, w, h)
        draw.WebImage("http://server.moatgaming.org/images/arrows.png", 0, 0, 16, 16, Color(255, 255, 255, (50 + s.HoverColor) * mc.alpha))
    end
    mc.MOVE.Moving = false
    mc.MOVE.MovingX = 0
    mc.MOVE.MovingY = 0
    mc.MOVE.HoverColor = 0
    mc.MOVE.Think = function(s)
        if (s:IsHovered()) then
            s.HoverColor = Lerp(FrameTime() * 10, s.HoverColor, 200)
        elseif (s.HoverColor > 1) then
            s.HoverColor = Lerp(FrameTime() * 10, s.HoverColor, 0)
        end

        if (input.IsMouseDown(MOUSE_LEFT) and s:IsHovered() and not s.Moving) then
            s.Moving = true

            s.MovingX, s.MovingY = mc.BG:CursorPos()
        end

        if (not input.IsMouseDown(MOUSE_LEFT) and s.Moving) then
            s.Moving = false

            return
        end

        if (s.Moving) then
            local mx, my = gui.MousePos()

            customchatx:SetInt(mx - s.MovingX)
            customchaty:SetInt(my - s.MovingY)

            mc.BG:SetPos(mx - s.MovingX, my - s.MovingY)
        end
    end
    mc.MOVE:SetToolTip("Hold left click to drag around, Right click to reset")

    mc.MOVE.DoRightClick = function(s)
        RunConsoleCommand("moat_resetchat")
    end

    mc.SPNL = vgui.Create("DScrollPanel", FRAME)
    mc.SPNL:SetPos(5, 21)
    mc.SPNL:SetSize(mcc.w - 6, mcc.h - 46)

    mc.SPNL.Paint = function(s, w, h)
        if (moat_chat.Theme.CHAT_PANEL) then
            moat_chat.Theme.CHAT_PANEL(s, w, h, mc, DrawBlur)
            return
        end

        --draw_RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 15 * mc.alpha))
    end

    local SPNL = mc.SPNL

    -- because the default scroll to child does a dumb glitchy animation
    function SPNL:ScrollToChild(panel)
        self:PerformLayout()
        local x, y = self.pnlCanvas:GetChildPosition(panel)
        local w, h = panel:GetSize()
        y = y + h * 0.5
        y = y - self:GetTall() * 0.5
        self.VBar:SetScroll(y)
    end
    function SPNL:ShouldScrollToChild(panel)
        local x, y = self.pnlCanvas:GetChildPosition(panel)
        local w, h = panel:GetSize()
        y = y + h * 0.5
        y = y - self:GetTall() * 0.5
       return y
    end

    local sbar = SPNL:GetVBar()
    m_PaintChatVBar(sbar)
    SPNL.Chat = vgui.Create("DPanel", SPNL)
    SPNL.Chat:SetPaintBackground(false)
    SPNL.Chat.Contents = {}
    SPNL.Chat:SetSize(SPNL:GetWide(), 0)

    FRAME.AddItem = function(s, item)

        s = SPNL
        local size = #s.Chat.Contents
        local chatc = s.Chat.Contents

        if (size == mc.MaxItems) then
            table.remove(chatc, 1):Remove()
            table.insert(chatc, item)
            item:SetParent(s.Chat)
            local curPos = 0
            local itemSize = 0

            for i = 1, #chatc do
                itemSize = chatc[i - 1] and chatc[i - 1]:GetTall() + 3 or 0
                curPos = curPos + itemSize
                chatc[i]:SetPos(0, curPos)
            end

            --rebuild positions
            local x, y = chatc[#chatc]:GetPos()
            itemSize = chatc[#chatc]:GetTall()
            y = y + itemSize
            local tallsize, ypos = s.Chat:GetPos()
            tallsize = -s.Chat:GetTall() + s:GetTall()
            s.Chat:SetTall(y)
            if (not mc.AlphaControl(s) or ((s:ShouldScrollToChild(item) - s:GetVBar():GetScroll() <= 96))) then
                s:ScrollToChild(item)
            end

            return
        end
        local itemSize = item:GetTall() + 3
        s.Chat:SetTall(s.Chat:GetTall() + itemSize)
        table.insert(chatc, item)
        item:SetParent(s.Chat)
        item:SetPos(0, s.Chat:GetTall() - itemSize)
        local x, y = s.Chat:GetPos()
        if (not mc.AlphaControl(s) or ((s:ShouldScrollToChild(item) - s:GetVBar():GetScroll() <= 96))) then
            s:ScrollToChild(item)
        end
    end

    mc.ENTRY = vgui.Create("DTextEntry", FRAME)
    mc.ENTRY:SetSize(mcc.w - 60, 20)
    mc.ENTRY:SetPos(55, mcc.h - 25)
    mc.ENTRY:SetFont(mc.font)
    mc.ENTRY.Stored = {}

    mc.ENTRY.Paint = function(s, w, h)
        /*
        surface_SetDrawColor(62, 62, 64, 255 * mc.alpha)
        surface_DrawOutlinedRect(0, 0, w, h)
        surface_SetDrawColor(0, 0, 0, 150 * mc.alpha)
        surface_SetMaterial(gradient_d)
        surface_DrawTexturedRect(0, 0, w, h)*/

        if (moat_chat.Theme.CHAT_ENTRY) then
            moat_chat.Theme.CHAT_ENTRY(s, w, h, mc, DrawBlur)
            return
        end

        surface_SetDrawColor(150, 150, 150, 50 * mc.alpha)
        surface_DrawRect(0, 0, w, h)

        s:DrawTextEntryText(Color(255, 255, 255, 255), s:GetHighlightColor(), Color(255, 255, 255, 255))
    end

    mc.ENTRY.PaintOver = function(s, w, h)
        if (not s.AutocompleteText) then return end
        
        surface_SetFont(mc.font)
        local x = surface_GetTextSize(s:GetValue())
        local w, h = surface_GetTextSize(s.AutocompleteText)

        surface_SetDrawColor(s:GetHighlightColor())
        surface_DrawRect(x + 3, 2, w, h + 1)
        surface.SetTextColor(Color(255, 255, 255, 255))
        surface.SetTextPos(x + 3, 2)
        surface.DrawText(s.AutocompleteText)
    end

    mc.ENTRY.OnTextChanged = function(s)
        local autocomplete = mc.AutoComplete(s, true)

        s.AutocompleteText = autocomplete or nil

        if (s:GetValue():len() > 126) then
            s:SetText(s:GetValue():sub(1, 126))
            s:SetCaretPos(126)
            surface.PlaySound("/resource/warning.wav")
        end

        hook.Call("ChatTextChanged", GAMEMODE, s:GetValue())
    end

    mc.ENTRY.OnEnter = function(s)
        local teamchat = #mc.chattype > 1
        
        if (GetConVar("moat_gangsta"):GetInt() == 1) then
            moat_chat.Gangsta(s:GetValue(), function(txt)
                moat_chat.Speak(txt, teamchat)
            end)
        else
            moat_chat.Speak(s:GetValue(), teamchat)
        end

        if (string.Trim(s:GetValue()) ~= "") then
            table.insert(s.Stored, 1, s:GetValue())
        end

        SelectedChatMsg = nil
        s.AutocompleteText = nil
        s:SetText("")
        mc.CloseChat()
    end

    mc.ENTRY.OnKeyCodeTyped = function(s, k)
        if (k == KEY_BACKQUOTE) then
            RunConsoleCommand("cancelselect")
        elseif (k == KEY_ESCAPE) then
            RunConsoleCommand("cancelselect")
            SelectedChatMsg = nil
            s.AutocompleteText = nil
            s:SetText("")
            mc.CloseChat()
        elseif (k == KEY_TAB) or ((k == KEY_RIGHT) and (s:GetCaretPos() == #s:GetValue())) then
            mc.AutoComplete(s)
            s:OnTextChanged()
            s:SetCaretPos(#s:GetValue())
        elseif (k == KEY_UP and (s.Stored[s.storagePos + 1])) then
            s.storagePos = s.storagePos + 1
            s:SetText(s.Stored[s.storagePos])
            s:SetCaretPos(#s:GetValue())
        elseif (k == KEY_DOWN and (s.Stored[s.storagePos - 1] or s.storagePos - 1 == 0)) then
            s.storagePos = s.storagePos - 1
            s:SetText(s.Stored[s.storagePos] or "")
            s:SetCaretPos(#s:GetValue())
        elseif (k == KEY_ENTER) then
            s:OnEnter()
        end
    end

    mc.ENTRY.OnLoseFocus = function(s)
        if (input.IsKeyDown(KEY_TAB)) then
            s:RequestFocus()
            s:SetCaretPos(#s:GetText())
        end
    end
end

timer.Simple(0, moat_chat.InitChat)

function moat_chat.OpenChat()

    local MT = MOAT_THEME.Themes
    local CurTheme = GetConVar("moat_Theme"):GetString()
    if (not MT[CurTheme]) then
        CurTheme = "Blur" 
    end

    moat_chat.Theme.CHAT_BG = MT[CurTheme].CHAT and MT[CurTheme].CHAT.CHAT_BG
    moat_chat.Theme.CHAT_PANEL = MT[CurTheme].CHAT and MT[CurTheme].CHAT.CHAT_PANEL
    moat_chat.Theme.CHAT_ENTRY = MT[CurTheme].CHAT and MT[CurTheme].CHAT.CHAT_ENTRY
    moat_chat.Theme.DefaultColor = MT[CurTheme].CHAT and MT[CurTheme].CHAT.DefaultColor

    local mc = moat_chat
    local mcc = moat_chat.config
    mc.ENTRY:SetSize(mcc.w - 60, 20)
    mc.ENTRY:SetPos(55, mcc.h - 25)

    if (#mc.chattype > 1) then
        mc.ENTRY:SetSize(mcc.w - (mc.sayvars[2].w + 15), 20)
        mc.ENTRY:SetPos(mc.sayvars[2].w + 10, mcc.h - 25)
    end

    mc.BG:MakePopup()
    mc.ENTRY:RequestFocus()
    mc.ENTRY.storagePos = 0
end

function moat_chat.IsHovering(self, w, h, x, y)

    local xx, yy = self:CursorPos()

    if (xx > x and xx < x + w and yy > y and yy < y + h) then
        return true
    else
        return false
    end
end

function moat_chat.DrawText(self, texte, texttbl, a)

    surface_SetFont("moat_ChatFont")

    if (texttbl.IsItem) then
        local item_tbl = texttbl.item_tbl
        local ITEM_NAME_FULL = texttbl[1]--texttbl.ItemName
        local name_font = "moat_ChatFont"
        local draw_name_x = 4 + texttbl[2]
        local draw_name_y = texttbl[3]
        local name_col = texttbl["item_tbl"].item.NameColor or rarity_names[texttbl["item_tbl"].item.Rarity][2]

        if (item_tbl.item.NameEffect) then
            local tfx = item_tbl.item.NameEffect

            if (tfx == "glow") then
                m_DrawGlowingText(false, ITEM_NAME_FULL, name_font, draw_name_x, draw_name_y, name_col)
            elseif (tfx == "fire") then
                m_DrawFireText(item_tbl.item.Rarity, ITEM_NAME_FULL, name_font, draw_name_x, draw_name_y, name_col)
            elseif (tfx == "bounce") then
                m_DrawBouncingText(ITEM_NAME_FULL, name_font, draw_name_x, draw_name_y, name_col)
            elseif (tfx == "enchanted") then
                m_DrawEnchantedText(ITEM_NAME_FULL, name_font, draw_name_x, draw_name_y, name_col, item_tbl.item.NameEffectMods[1])
            elseif (tfx == "electric") then
                m_DrawElecticText(ITEM_NAME_FULL, name_font, draw_name_x, draw_name_y, name_col)
            elseif (tfx == "frost") then
                DrawFrostingText(10, 1.5, ITEM_NAME_FULL, name_font, draw_name_x, draw_name_y, Color(100, 100, 255), Color(255, 255, 255))
            else
                draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2] + 1, texttbl[3] + 1, Color(name_col.r, name_col.g, name_col.b, 25), 0, 0, 0, Color(10, 10, 10, 0))
                draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2] + 1, texttbl[3] + 1, Color(0, 0, 0, 175), 0, 0, 0, Color(10, 10, 10, 0))
                draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2], texttbl[3], name_col, 0, 0, 0, Color(10, 10, 10, 0))
                --draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2], texttbl[3], name_col, 0, 0, 0.5, Color(10, 10, 10, a))
            end
        else
            draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2] + 1, texttbl[3] + 1, Color(name_col.r, name_col.g, name_col.b, 25), 0, 0, 0, Color(10, 10, 10, 0))
            draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2] + 1, texttbl[3] + 1, Color(0, 0, 0, 175), 0, 0, 0, Color(10, 10, 10, 0))
            draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2], texttbl[3], name_col, 0, 0, 0, Color(10, 10, 10, 0))
            --draw_SimpleTextOutlined(ITEM_NAME_FULL, "moat_ChatFont", 4 + texttbl[2], texttbl[3], name_col, 0, 0, 0.5, Color(10, 10, 10, a))
        end

        if (not texttbl or (texttbl and not texttbl[1])) then return end

        local text_w, text_h = surface_GetTextSize(texttbl[1])
        local text_x, text_y = 4 + texttbl[2], texttbl[3]

        if (moat_chat.IsHovering(self, text_w, text_h, text_x, text_y)) then
            self:SetCursor("hand")
            surface_SetDrawColor(name_col.r, name_col.g, name_col.b, a)
            surface_DrawLine(text_x, text_y + text_h - 1, text_x + text_w, text_y + text_h - 1)

            if (input.IsMouseDown(MOUSE_LEFT) and moat_chat.click <= CurTime()) then
                m_DrawFoundItem(item_tbl, "chat")
                moat_chat.click = CurTime() + 1
            end
        end

        return
    end

    local textpos = 0
    local spw = surface_GetTextSize(" ")
    
    for i = 1, #texte do
        local str = texte[i]
        local space = " "
        if (i == 1) then space = "" end
        local tw, th = surface_GetTextSize(space .. str)

        if (string.StartWith(str:lower(), "http://") or string.StartWith(str:lower(), "https://") or string.StartWith(str:lower(), "wwww.")) then

            draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos + 1, texttbl[3] + 1, Color(100, 100, 255, 25), 0, 0, 0, Color(10, 10, 10, 0))
            draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos + 1, texttbl[3] + 1, Color(0, 0, 0, 175), 0, 0, 0, Color(10, 10, 10, 0))
            draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos, texttbl[3], Color(100, 100, 255), 0, 0, 0, Color(10, 10, 10, 0))
            --draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos, texttbl[3], Color(100, 100, 255), 0, 0, 0.5, Color(10, 10, 10, a))

            local text_w, text_h = surface_GetTextSize(str)
            local text_x, text_y = 4 + texttbl[2] + textpos + spw, texttbl[3]

            if (moat_chat.IsHovering(self, text_w, text_h, text_x, text_y)) then
                self:SetCursor("hand")
                surface_SetDrawColor(100, 100, 255, a)
                surface_DrawLine(text_x, text_y + text_h - 1, text_x + text_w, text_y + text_h - 1)

                if (input.IsMouseDown(MOUSE_LEFT) and moat_chat.click <= CurTime()) then
                    gui.OpenURL(str)
                    moat_chat.click = CurTime() + 1
                end
            end
        else
            draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos + 1, texttbl[3] + 1, Color(texttbl[4].r, texttbl[4].g, texttbl[4].b, 25), 0, 0, 0, Color(10, 10, 10, 0))
            draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos + 1, texttbl[3] + 1, Color(0, 0, 0, 175), 0, 0, 0, Color(10, 10, 10, 0))
            draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos, texttbl[3], texttbl[4], 0, 0, 0, Color(10, 10, 10, 0))
            --draw_SimpleTextOutlined(space .. str, "moat_ChatFont", 4 + texttbl[2] + textpos, texttbl[3], texttbl[4], 0, 0, 0.5, Color(10, 10, 10, a))

            local text_w, text_h = surface_GetTextSize(str)
            local text_x, text_y = 4 + texttbl[2] + textpos + spw, texttbl[3]

            if (moat_chat.IsHovering(self, text_w, text_h, text_x, text_y)) then
                self:SetCursor("arrow")
            end
        end

        textpos = textpos + tw
    end

end

function moat_chat.ChatObjectPaint(self)

    local curtime = CurTime()
    local a = self.CreateTime - curtime <= 1 and (self.CreateTime - curtime) * 510 or 255
    local mc = moat_chat
    if a < 0 then return end

    if SelectedChatMsg == self and mc.AlphaControl(self) then
        if SelectingText then
            MouseReleasedX, MouseReleasedY = self:CursorPos()
            for i=1, #self.TextTable do
                if (MousePressedX < self.TextTable[i][2] and MousePressedY-mc.TextSize.h <= self.TextTable[i][3] and MouseReleasedY-mc.TextSize.h > self.TextTable[i][3]) or (MousePressedX <= self.TextTable[i][2] and MouseReleasedX >= self.TextTable[i][2] and MousePressedY-mc.TextSize.h < self.TextTable[i][3] and MouseReleasedY > self.TextTable[i][3]) or (MousePressedY <= mc.TextSize.h and MouseReleasedY > mc.TextSize.h and self.TextTable[i][3] >= mc.TextSize.h and self.TextTable[i][3] <= mc.TextSize.h and MouseReleasedX>=self.TextTable[i][2]) then
                    self.TextTable[i][4] = true
                else
                    self.TextTable[i][4] = nil
                end
            end
        end
        local lines = self.TextTable[#self.TextTable][3]/mc.TextSize.h + 1
        surface_SetDrawColor(mc.HighlightColor)
        for i=1, lines do
            local xsize, x, start = 0, 0
            for a=1, #self.TextTable do
                if self.TextTable[a][4] and self.TextTable[a][3] == i*mc.TextSize.h-mc.TextSize.h then
                    x = a== 1 and 4 or x == 0 and self.TextTable[a][2]-4 or x
                    xsize = self.TextTable[a][2]-x+4
                end
            end
            surface_DrawRect(x, mc.TextSize.h*i-mc.TextSize.h, xsize, mc.TextSize.h)
        end
    end

    if self.Icon then
        surface_SetDrawColor(255, 255, 255, a)
        surface_SetMaterial(self.Icon)
        surface_DrawTexturedRect(2, 0, 16, 16)
    end

    for i = 1, #self.Text do
        self.Text[i][4].a = a

        if (not self.Text[i] or (self.Text[i] and not self.Text[i][1])) then
            continue
        end

        local texte = string.Explode(" ", self.Text[i][1])

        moat_chat.DrawText(self, texte or "", self.Text[i], a)
    end
end

function chat.AddText(...)
    if (not moat_chat or (moat_chat and (not moat_chat.BG or not moat_chat.SPNL))) then
        local cur = CurTime()
        local args = {...}

        -- create a timer to retry the func when our chatbox wasn't initialized
        timer.Create("moat_chatretry" .. cur, 0.1, 0, function()
            if (moat_chat and moat_chat.BG and moat_chat.SPNL) then
                chat.AddText(unpack(args))
                timer.Remove("moat_chatretry" .. cur)

                return
            end
        end)

        return
    end

    local mc = moat_chat
    local TextTable, TextPosX, TextPosY, icon = {...}, 0, 0
    local type1 = type(TextTable[1])

    if type1 == "IMaterial" then
        icon = TextTable[1]
        TextPosX = 17
        table.remove(TextTable, 1)
    end

    local TextTableNum = #TextTable

    for i = 1, TextTableNum do
        local t = type(TextTable[i])

        if t == "Player" then
            table.insert(TextTable, i + 1, TextTable[i]:Nick())
            TextTableNum = TextTableNum + 1
            TextTable[i] = team.GetColor(TextTable[i]:Team())
        elseif t ~= "string" and t ~= "table" and (not TextTable[i].IsItem) then
            if TextTable[i].IsValid and TextTable[i]:IsValid() then
                TextTable[i] = TextTable[i]:GetClass()
            else
                TextTable[i] = "NULL"
            end
        end
    end

    local FinalText = {}
    local windowSizeX = 486
    surface_SetFont("moat_ChatFont")
    local _, tall = surface_GetTextSize("AbC1230")
    TextTableNum = #TextTable
    local pos = 0
    local LineText = ""
    local LastColor = Color(255, 255, 255, 255)

    while pos ~= TextTableNum do
        pos = pos + 1

        if (type(TextTable[pos]) == "table" and (not TextTable[pos].IsItem) and type(TextTable[pos][2]) == "table") then
            local text = TextTable[pos][1]
            local x, y = surface_GetTextSize(text)
            table.insert(FinalText, {text, TextPosX, TextPosY, TextTable[pos][2], 1})
            TextPosX = TextPosX + x
        else
            while IsColor(TextTable[pos]) do
                LastColor = TextTable[pos]
                pos = pos + 1
            end

            if (not TextTable[pos]) then break end
            local text = TextTable[pos]
            if (istable(TextTable[pos]) and TextTable[pos].IsItem) then text = TextTable[pos]["ItemName"] or "Scripted Weapon" end
            if (not text) then break end

            local x, y = surface_GetTextSize(text)

            if TextPosX + x >= windowSizeX then
                local startpos, t, t2, size = #FinalText

                for line in (text):gmatch("[^%s]+") do
                    if t then
                        t2 = table.concat({t, line}, " ")
                    else
                        t2 = line
                        t = ""
                    end

                    size = surface_GetTextSize(t2)

                    if TextPosX + size >= windowSizeX then
                        if (istable(TextTable[pos]) and TextTable[pos].IsItem) then
                            table.insert(FinalText, {t, TextPosX, TextPosY, LastColor, IsItem = true, item_tbl = TextTable[pos].item_tbl, ItemName = text})
                            table.insert(FinalText, {" ", TextPosX, TextPosY, LastColor})
                        else
                            table.insert(FinalText, {t, TextPosX, TextPosY, LastColor})
                            table.insert(FinalText, {" ", TextPosX, TextPosY, LastColor})
                        end
                        TextPosX = 0
                        TextPosY = TextPosY + tall
                        t = line
                    else
                        t = t2
                    end
                end

                --table.insert(FinalText, {t, TextPosX, TextPosY, LastColor})
                
                if (istable(TextTable[pos]) and TextTable[pos].IsItem) then
                    table.insert(FinalText, {t, TextPosX, TextPosY, LastColor, IsItem = true, item_tbl = TextTable[pos].item_tbl, ItemName = text})
                else
                    table.insert(FinalText, {t, TextPosX, TextPosY, LastColor})
                end
                if (t) then
                    size = surface_GetTextSize(t)
                    TextPosX = TextPosX + size
                end
            else
                if (istable(TextTable[pos]) and TextTable[pos].IsItem) then
                    table.insert(FinalText, {text, TextPosX, TextPosY, LastColor, IsItem = true, item_tbl = TextTable[pos].item_tbl, ItemName = text})
                else
                    table.insert(FinalText, {text, TextPosX, TextPosY, LastColor})
                end
                TextPosX = TextPosX + x
            end
        end
    end

    local ListItem = vgui.Create("DPanel", mc.SPNL)
    ListItem.IsChatTextPanel = true
    ListItem.Icon = icon
    ListItem.CreateTime = CurTime() + mc.FadeTime
    ListItem.Text = FinalText
    ListItem:SetSize(mc.SPNL:GetWide(), TextPosY + tall)
    ListItem.Paint = mc.ChatObjectPaint
    ListItem:SetPaintBackground(false)
    local TextTable = {}

    for i = 1, #FinalText do
        if (not FinalText[i] or (FinalText[i] and not FinalText[i][1])) then continue end
        
        local len = FinalText[i][1]:len()
        local TextX, TextY = FinalText[i][2], FinalText[i][3]

        for a = 1, len do
            local x = surface_GetTextSize(FinalText[i][1][a])
            TextX = TextX + x
            table.insert(TextTable, {FinalText[i][1][a], TextX, TextY})
        end
    end

    ListItem.TextTable = TextTable

    mc.BG:AddItem(ListItem)
    local pack, a = {}, 0

    for i = 1, #FinalText do
        a = a + 1
        pack[a] = Color(FinalText[i][4].r, FinalText[i][4].g, FinalText[i][4].b, 255)
        a = a + 1
        pack[a] = FinalText[i][1]
    end

    pack[a + 1] = "\n"
    MsgC(unpack(pack))
end

hook.Remove("PlayerBindPress", "moat_OpenChat")

hook.Add("PlayerBindPress", "moat_OpenChat", function(ply, bind, pressed)
    if (string.sub(bind, 1, 11) == "messagemode") then
        if (bind == "messagemode2") then
            moat_chat.chattype = "team"
        else
            moat_chat.chattype = ""
        end

        moat_chat.OpenChat()
        hook.Call("StartChat", GAMEMODE, bind == "messagemode2")

        return true
    end
end)

hook.Add("StartChat", "moat_StartChat", function()
    moat_chat.isopen = true
end)

hook.Add("FinishChat", "moat_FinishChat", function()
    moat_chat.isopen = false
    m_DrawFoundItem({}, "remove_chat")
end)

local hud_tbl = {CHudChat = true}
hook.Add("HUDShouldDraw", "moat_DisableDefaultChat", function(name)
    if (hud_tbl[name]) then return false end
end)

net.Receive("MOAT_LINK_ITEM", function(len)
    local ply = Entity(net.ReadDouble())
    local tbl = net.ReadTable()

    if (not IsValid(ply)) then return end
    if (not IsValid(LocalPlayer())) then return end

    if (IsValid(ply) and IsValid(LocalPlayer()) and (ply:IsSpec() and LocalPlayer():IsSpec()) or ply:Team() ~= TEAM_SPEC) then
        local tab = {}

        if (ply:IsSpec()) then
            table.insert(tab, Color(255, 30, 40))
            table.insert(tab, "*DEAD* ")
        end

        if (IsValid(ply)) then
            table.insert(tab, ply)
        else
            table.insert(tab, "Console")
        end

        local ITEM_NAME_FULL = m_GetFullItemName(tbl)

        --local item_color = tbl.item.NameColor or rarity_names[tbl.item.Rarity][2]
        table.insert(tab, Color(255, 255, 255))
        table.insert(tab, ": ")
        table.insert(tab, {
            ItemName = ITEM_NAME_FULL,
            IsItem = true,
            item_tbl = tbl
        })

        chat.AddText(unpack(tab))
    end
end)

net.Receive("MOAT_CHAT_LINK_ITEM", function(len)
    local ply = net.ReadEntity()
    local str = net.ReadTable()
    local amt = net.ReadUInt(4)

    local itemtbl = {}

    for i = 1, amt do
        local tbl = net.ReadTable()
        itemtbl[tbl.id] = tbl
    end

    if (not IsValid(ply)) then return end
    if (not IsValid(LocalPlayer())) then return end

    if (IsValid(ply) and IsValid(LocalPlayer()) and (ply:IsSpec() and LocalPlayer():IsSpec()) or ply:Team() ~= TEAM_SPEC) then
        local tab = {}

        if (ply:IsSpec()) then
            table.insert(tab, Color(255, 30, 40))
            table.insert(tab, "*DEAD* ")
        end

        if (IsValid(ply)) then
            table.insert(tab, ply)
        else
            table.insert(tab, "Console")
        end
        --local item_color = tbl.item.NameColor or rarity_names[tbl.item.Rarity][2]
        table.insert(tab, Color(255, 255, 255))
        table.insert(tab, ": ")

        for k, v in pairs(str) do
            if (itemtbl[v]) then
                str[k] = itemtbl[v]
            end
        end

        for i = 1, #str do
            table.insert(tab, Color(255, 255, 255))
            if (isstring(str[i])) then
                table.insert(tab, str[i])
            else
                local ITEM_NAME_FULL = m_GetFullItemName(str[i])
                table.insert(tab, {
                    ItemName = ITEM_NAME_FULL,
                    IsItem = true,
                    item_tbl = str[i]
                })
            end
        end

        chat.AddText(unpack(tab))
    end


end)

local ITEM_RARITY_TO_NAME = {
    ["Worn"] = 1,
    ["Standard"] = 2,
    ["Specialized"] = 3,
    ["Superior"] = 4,
    ["High-End"] = 5,
    ["Ascended"] = 6,
    ["Cosmic"] = 7
}

local vowels = {"a", "e", "i", "o", "u"}

net.Receive("MOAT_OBTAIN_ITEM", function(len)
    local ply = ents.GetByIndex(net.ReadDouble())
    local tbl = net.ReadTable()
    local rar = GetConVar("moat_chat_obtain_rarity"):GetString()

    if (ply:IsValid() and IsValid(ply) and LocalPlayer():IsValid() and ply ~= LocalPlayer() and ITEM_RARITY_TO_NAME[rar] and tbl and tbl.item and tbl.item.Rarity and tbl.item.Rarity < ITEM_RARITY_TO_NAME[rar]) then
        return
    end

    if (not ply:IsValid() or not IsValid(ply) or not LocalPlayer():IsValid() or not IsValid(LocalPlayer())) then
        return
    end

    local tab = {}
    table.insert(tab, Color(20, 255, 20))
    local has = " has"
    local nick = ply:Nick()

    if (ply == LocalPlayer()) then
        has = " have"
        nick = "You"
    end

    if (IsValid(ply)) then
        table.insert(tab, nick)
    else
        table.insert(tab, "PLAYER")
    end

    local ITEM_NAME_FULL = m_GetFullItemName(tbl)

    local da_rarity = tbl.item.Rarity

    if (da_rarity == 9) then
        da_rarity = 8
    end

    local item_color = tbl.item.NameColor or rarity_names[da_rarity][2]
    local grammar = " a "

    if (table.HasValue(vowels, string.lower(string.sub(ITEM_NAME_FULL, 1, 1)))) then
        grammar = " an "
    end

    -- no grammar if the item starts with an a or the
    if (string.lower(string.sub(ITEM_NAME_FULL, 1, 2)) == "a " or string.lower(string.sub(ITEM_NAME_FULL, 1, 4)) == "the ") then
        grammar = " "
    end

    table.insert(tab, Color(255, 255, 255))
    table.insert(tab, has .. " obtained" .. grammar)
    table.insert(tab, item_color)
    table.insert(tab, {
        ItemName = ITEM_NAME_FULL,
        IsItem = true,
        item_tbl = tbl
    })

    chat.AddText(Material("icon16/new.png"), unpack(tab))

    if (ply == LocalPlayer()) then
        chat.AddText(Color(255, 255, 255), "Press ", Color(20, 255, 20), "I", Color(255, 255, 255), " to view your inventory!")

        if (da_rarity > 5) then
            
            local wpn = ""
            if (tbl.w) then
                wpn = weapons.Get(tbl.w).PrintName or ""
            end

            net.Start("MOAT_CHAT_OBTAINED_VERIFY")
            net.WriteString(ply:Nick() .. " (" .. ply:SteamID() .. ") has obtained" .. grammar .. ITEM_NAME_FULL)
            net.WriteTable(tbl)
            net.WriteString(wpn)
            net.SendToServer()
        end
    end
end)

local pl = FindMetaTable("Player")

function pl:IsTyping()

    return IsValid(moat_chat.ENTRY) and moat_chat.ENTRY:IsEditing()
end