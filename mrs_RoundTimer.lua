local PluginAPI = CS.Akequ.Plugins.PluginAPI
local GameObject = CS.UnityEngine.GameObject
local Text = CS.UnityEngine.UI.Text
local RectTransform = CS.UnityEngine.RectTransform
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local TextAnchor = CS.UnityEngine.TextAnchor
local Font = CS.UnityEngine.Font
local Resources = CS.UnityEngine.Resources
local Time = CS.UnityEngine.Time
local Mirror = CS.Mirror
local ColorUtility = CS.UnityEngine.ColorUtility
local Debug = CS.UnityEngine.Debug

---@class mrs_RoundTimer:CS.Akequ.Base.Room
mrs_RoundTimer = {}

mrs_RoundTimer.is_round_end = false
mrs_RoundTimer.NRM = false
        
mrs_RoundTimer.game_time = 0
mrs_RoundTimer.time_sec = 0
mrs_RoundTimer.time_min = 0

mrs_RoundTimer.html_str = "ffffff"

mrs_RoundTimer.text_ = nil

function mrs_RoundTimer:Init()
    if self.main.netEvent.isServer then                
        local f = io.open("Plugins/NewRoundManager.lua", "r")
        if f ~= nil then
            io.close(f)
            self.NRM = true
        end

        self.html_str = CS.Config.GetString("timer_color", "ffffff")

        CS.HookManager.Add("onNRMRoundEnd", function(obj)
            self.main:SendToEveryone("CLIENTRoundEnd", self.time_min, self.time_sec, self.html_str)
            self.is_round_end = true
        end)
        CS.HookManager.Add("onRoundEnd", function(obj)                
            if not self.NRM then     
                self.main:SendToEveryone("CLIENTRoundEnd", self.time_min, self.time_sec, self.html_str)
                self.is_round_end = true
            end
        end) 
    end
    if self.main.netEvent.isClient then           
        self.main:SendToServer("GetFromClient")

        local html_str = CS.Config.GetString("timer_color", "ffffff")
        local success, color = ColorUtility.TryParseHtmlString("#" .. html_str)
        

        local base_ = GameObject.Find("Canvas")
        if base_ == nil then return end
        
        local textobject_ = GameObject("ScriptText")
        textobject_.transform:SetParent(base_.transform, false)
        textobject_.transform.localPosition = Vector3(320, 15, 0)
        
        local rt = textobject_:AddComponent(typeof(RectTransform))
        rt.anchorMin = Vector2(0, 0)
        rt.anchorMax = Vector2(0, 0)
        rt.pivot = Vector2(0, 0)
        rt.sizeDelta = Vector2(500, 25)
        
        self.text_ = textobject_:AddComponent(typeof(Text))
        self.text_.alignment = TextAnchor.MiddleLeft
        self.text_.text = "Ожидание получения информации..."
        self.text_.fontSize = 20
        self.text_.font = Resources.GetBuiltinResource(typeof(Font), "Arial.ttf")
        self.text_.raycastTarget = false
        self.text_.color = color
    end
end

function mrs_RoundTimer:Update()    
    self.game_time = self.game_time + Time.deltaTime
    
    if self.game_time >= 1 then
        self.game_time = 0
        
        if self.is_round_end then
            if self.main.netEvent.isClient then 
                self.text_.text = "Раунд окончен за " .. string.format("%02d:%02d", self.time_min, self.time_sec)
            end
        else        
            self.time_sec = self.time_sec + 1
            if self.time_sec >= 60 then
                self.time_min = self.time_min + 1
                self.time_sec = 0
            end
            if self.main.netEvent.isClient and self.text_ ~= nil then 
                self.text_.text = "Раунд идёт " .. string.format("%02d:%02d", self.time_min, self.time_sec)
            end
        end
    end
end
--SERVER
function mrs_RoundTimer:GetFromClient(conn)
    if self.is_round_end == false then
        self.main:SendToClient("GetFromServer", conn, self.time_min, self.time_sec, self.html_str)
    else
        self.main:SendToClient("CLIENTRoundEnd", conn, self.time_min, self.time_sec, self.html_str)
    end
end
--CLIENT
function mrs_RoundTimer:GetFromServer(mins, secs, got_html_str)
    self.time_min = mins
    self.time_sec = secs
    
    local success, color = ColorUtility.TryParseHtmlString("#" .. got_html_str)
    if success then
        self.text_.color = color
    else
        CS.GameConsole.Log("Failed to color text(")
    end
end

function mrs_RoundTimer:CLIENTRoundEnd(mins, secs, got_html_str)
    self.time_min = mins
    self.time_sec = secs
    self.is_round_end = true

    local success, color = ColorUtility.TryParseHtmlString("#" .. got_html_str)
    if success then   
        local r = color.r - 0.35
        if r < 0 then
            r = 0
        end
        local g = color.g - 0.35
        if g < 0 then
            g = 0
        end
        local b = color.b - 0.35
        if b < 0 then
            b = 0
        end
        self.text_.color = CS.UnityEngine.Color(r, g, b)
    else
        CS.GameConsole.Log("Failed to color dark text(")
    end
end

return mrs_RoundTimer