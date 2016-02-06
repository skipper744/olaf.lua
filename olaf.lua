if myHero.charName ~= "Olaf" then return end
local function AutoupdaterMsg(msg) print("<font color=\"##7D26CD\"><b>Olaf-S74</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
VERSION = 1.08
class("ScriptUpdate")
function GetBestLineFarmPosition(range, width, objects, from)
    local BestPos 
	local _from = from or myHero
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(_from.pos) + range * (Vector(object) - Vector(_from.pos)):normalized()
        local hit = CountObjectsOnLineSegment(_from.pos, EndPos, width, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
			BestObj = object
            if BestHit == #objects then
               break
            end
         end
    end
    return BestPos, BestHit, BestObj
end
function CountObjectsOnLineSegment(StartPos, EndPos, width, objects)
    local n = 0
    for i, object in ipairs(objects) do
        local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, object)
        if isOnSegment and GetDistanceSqr(pointSegment, object) < width * width then
            n = n + 1
        end
    end
    return n
end
function OnLoad()
	champ = kao()
end
class('kao')
function kao:__init()
	self.Prediction = {}
	ToUpdate = {}
	ToUpdate.Host = "raw.githubusercontent.com"
	ToUpdate.VersionPath = "/skipper744/olaf.lua/master/olaf.version"
	ToUpdate.ScriptPath =  "/skipper744/olaf.lua/master/olaf.lua"
	ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
	ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"##7D26CD\"><b>Olaf - S74 </b></font> <font color=\"#FFFFFF\">Updated to "..NewVersion..". </b></font>") end
	ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"##7D26CD\"><b>Olaf - the S74 </b></font> <font color=\"#FFFFFF\">You have lastest version ("..OldVersion..")</b></font>") end
	ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"##7D26CD\"><b>Olaf - the S74 </b></font> <font color=\"#FFFFFF\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
	ToUpdate.CallbackError = function(NewVersion) print("<font color=\"##7D26CD\"><b>Olaf - the S74 </b></font> <font color=\"#FFFFFF\">Error while Downloading. Please try again.</b></font>") end
	ScriptUpdate(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
	
	self.Q = {Range = 1000, Width = 90, Delay = 0.25, Speed = 1600, IsReady = function() return myHero:CanUseSpell(_Q) == READY end}
	self.W = {Range = 200, IsReady = function() return myHero:CanUseSpell(_W) == READY end}
	self.E = {Range = 325, IsReady = function() return myHero:CanUseSpell(_E) == READY end}
	self.R = {IsReady = function() return myHero:CanUseSpell(_R) == READY end}
	self.TS = TargetSelector(TARGET_LESS_CAST, self.Q.Range, DAMAGE_MAGIC, false)
	self.TS.name = "Your mather"
	self:OnOrbLoad()
	self.EnemyMinions = minionManager(MINION_ENEMY, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, 1100, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.axePos = nil
	self.Move = true
	self.Attack = true
	self.Movement = false
	self.MoveTo = nil
	self.boostbuffname=nil
	self.boostbufftype=nil
	self.boostbufftime=nil
	--HP
	
	self.comboQMaxRange = 0
	self.harassQMaxRange = 0
	self.QextraRange = 0
	if FileExist(LIB_PATH .. "SPrediction.lua") then
		require("SPrediction")
		SP = SPrediction()
		table.insert(self.Prediction, "SPrediction")
    end
    if FileExist(LIB_PATH .. "VPrediction.lua") then
		require("VPrediction")
		VP = VPrediction()
		table.insert(self.Prediction, "VPrediction")
    end
    if VIP_USER and FileExist(LIB_PATH.."DivinePred.lua") and FileExist(LIB_PATH.."DivinePred.luac") then
		require "DivinePred"
		dp = DivinePred()
		table.insert(self.Prediction, "DivinePred")
		self.DivineQ = LineSS(self.Q.Speed, self.Q.Range, self.Q.Width, self.Q.Delay * 1000, math.huge)
		self.DivineQ = dp:bindSS("DivineQ", self.DivineQ, 1)
    end
    if FileExist(LIB_PATH .. "HPrediction.lua") then
		require("HPrediction")
		HP = HPrediction()
		table.insert(self.Prediction, "HPrediction")
		self.HP_Q = HPSkillshot({type = "DelayLine", collisionM = false, collisionH = false, speed = self.Q.Speed, width = self.Q.Width, range = self.Q.Range, delay = self.Q.Delay})
    end
	self:LoadMenu()
end
function kao:OnOrbLoad()
	if _G.MMA_LOADED then
		MMALoad = true
		orbload = true
	elseif _G.Reborn_Loaded then
		SacLoad = true
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		AutoupdaterMsg("SxOrbWalk Load")
		require 'SxOrbWalk'
		SxO = SxOrbWalk()
		SxOLoad = true
		orbload = true
	end
end
function kao:LoadMenu()
	self.Config = scriptConfig("Olaf - S74", "Olaf")
		self.Config:addSubMenu(myHero.charName.." - Orbwalker Settings", "SOWorb")
			if SxOLoad then SxO:LoadToMenu(self.Config.SOWorb) 
			elseif SacLoad then self.Config.SOWorb:addParam("", "SAC DETECTED", SCRIPT_PARAM_INFO, "")
			elseif MMALoad then self.Config.SOWorb:addParam("", "MMA DETECTED", SCRIPT_PARAM_INFO, "")
			end
		self.Config:addSubMenu(myHero.charName.." - General Settings", "General")
			self.Config.General:addParam("On", "Script On", SCRIPT_PARAM_ONOFF, true)
			self.Config.General:addParam("Bla", " - HotKey Settings -", SCRIPT_PARAM_INFO, "")
			self.Config.General:addParam("OnOrbWalkerKey", "Use orbwalker key", SCRIPT_PARAM_ONOFF, true)
			self.Config.General:addParam("Combo",		"Combo HotKey : ", SCRIPT_PARAM_ONKEYDOWN, false, 32)
			self.Config.General:addParam("Harass",	 	"Harass HotKey : ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
			self.Config.General:addParam("LineClear", 	"LineClear HotKey : ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			self.Config.General:addParam("JungleClear", "JungleClear HotKey: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
			
		self.Config:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
			self.Config.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
			self.Config.Combo:addParam("QMaxRange", "Q Max Range", SCRIPT_PARAM_SLICE, 1000, 0, 1000, 0)
			
		self.Config:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
			self.Config.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
			self.Config.Harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, false)
			self.Config.Harass:addParam("QMaxRange", "Q Max Range", SCRIPT_PARAM_SLICE, 1000, 0, 1000, 0)
			
		self.Config:addSubMenu(myHero.charName.." - LineClear Settings", "LineClear")
			self.Config.LineClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.LineClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
			self.Config.LineClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, false)
			
		self.Config:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
			self.Config.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
			self.Config.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu(myHero.charName.." - Prediction Settiongs", "Pred")
			self.Config.Pred:addParam("QHit", "Q HitChance", SCRIPT_PARAM_SLICE, 1.4, 0, 3, 1)
			self.Config.Pred:addParam("QPred", "Q Prediction settings", SCRIPT_PARAM_LIST, 1, self.Prediction)
		
		self.Config:addSubMenu(myHero.charName.." - Auto Axe Catch Settings", "AutoC")
			self.Config.AutoC:addParam("Enable", "Auto axe catch enable", SCRIPT_PARAM_ONOFF, true)
			self.Config.AutoC:addParam("CatchRange", "Auto axe catch range", SCRIPT_PARAM_SLICE, 500, 0, 1000, 0)
			self.Config.AutoC:addParam("CatchFrom", "Auto axe catch range to :", SCRIPT_PARAM_LIST, 1, {"Mouse", "my Hero"})
			--self.Config.AutoC:addParam("Tower", "auto axe catch in tower", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("G"))
		
		self.Config:addSubMenu(myHero.charName.." - Draw Settings", "Draw")
			self.Config.Draw:addParam("DrawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
			self.Config.Draw:addParam("DrawQColor", "Draw Q Color", SCRIPT_PARAM_COLOR, {100, 255, 0, 0})
			self.Config.Draw:addParam("DrawAutoCatchRange", "Draw auto axe cath range", SCRIPT_PARAM_ONOFF, true)
			
		self.Config:addSubMenu(myHero.charName.." - Skill Settings", "Skill")
			self.Config.Skill:addSubMenu("Q Settings", "Q")
				self.Config.Skill.Q:addParam("extraRange", "Q extra range", SCRIPT_PARAM_SLICE, 100, 0, 200)
			self.Config.Skill:addSubMenu("W Settings", "W")
				self.Config.Skill.W:addParam("MinHP", "use Q HP <", SCRIPT_PARAM_SLICE, 80, 0, 100)
			self.Config.Skill:addSubMenu("E Settings", "E")
	
	AddTickCallback(function() self:Tick() end)
	AddDrawCallback(function() self:Draw() end)
	AddAnimationCallback(function(unit, animation) self:OnAnimation(unit, animation) end)
	AddApplyBuffCallback(function(unit,sorce,buff) self:OnApplyBuff(unit,sorce,buff) end)
end
function kao:OnAnimation(unit, anim)
	if unit.isMe then
		self.anim = anim
	end
end
function kao:Draw()
	if myHero.dead then return end
	if self.Q.IsReady() and self.Config.Draw.DrawQ then
		DrawCircle(player.x, player.y, player.z, self.Q.Range, TARGB(self.Config.Draw.DrawQColor))
	end
	if self.Config.Draw.DrawAutoCatchRange then
		if self.Config.AutoC.CatchFrom == 1then
			DrawCircle(mousePos.x, mousePos.y, mousePos.z, self.Config.AutoC.CatchRange, TARGB({100, 255, 0, 0}))
		else
			DrawCircle(myHero.x, myHero.y, myHero.z, self.Config.AutoC.CatchRange, TARGB({100, 255, 0, 0}))
		end
	end
	if self.QHitChance ~= nil then
		if self.QHitChance < 1 then
			self.Qcolor = ARGB(0xFF, 0xFF, 0x00, 0x00)
		elseif self.QHitChance == 3 then
			self.Qcolor = ARGB(0xFF, 0x00, 0x54, 0xFF)
		elseif self.QHitChance >= 2 then
			self.Qcolor = ARGB(0xFF, 0x1D, 0xDB, 0x16)
		elseif self.QHitChance >= 1 then
			self.Qcolor = ARGB(0xFF, 0xFF, 0xE4, 0x00)
		end
	end
	if self.QPos and self.Qcolor and self.Q.IsReady() then
		DrawCircle(self.QPos.x, self.QPos.y, self.QPos.z, self.Q.Width/2, self.Qcolor)
		if self.Config.Draw.Line then
			DrawLine3D(myHero.x, myHero.y, myHero.z, self.QPos.x, self.QPos.y, self.QPos.z, 2, self.Qcolor)
		end
    
		self.QPos = nil
	end
end
function kao:Tick()
	if self.Config.General.On then
		self.TS:update()
		self.Target = GetTarget() or self.TS.target
		self.comboQMaxRange = self.Config.Combo.QMaxRange
		self.harassQMaxRange = self.Config.Harass.QMaxRange
		self.QextraRange = self.Config.Skill.Q.extraRange
		if self.Config.General.OnOrbWalkerKey then
			if self.Config.General.Combo then
				self:Combo(self.Target)
			elseif self.Config.General.Harass then
				self:Harass(self.Target)
			elseif self.Config.General.LineClear then
				self:LineClear()
			elseif self.Config.General.JungleClear then
				self:JungleClear()
			end
		else
			if self:IsComboPressed() then
				self:Combo(self.Target)
			elseif self:IsHarassPressed() then
				self:Harass(self.Target)
			elseif self:IsClearPressed() then
				self:LineClear()
			elseif self:IsClearPressed() then
				self:JungleClear()
			end
		end
		if self.MoveTo and self:DoCatch(self.MoveTo) then
			if self.Movement and self.Config.AutoC.Enable then
				self:OrbwalkToPosition(self.MoveTo)
			else
				self:OrbwalkToPosition(mousePos)
			end
		else
			self:OrbwalkToPosition(mousePos)
		end
	end
end

function kao:DoCatch(Pos)
	if self.Config.AutoC.CatchFrom == 1 then
		return GetDistance(Pos, mousePos) < self.Config.AutoC.CatchRange
	elseif self.Config.AutoC.CatchFrom == 2 then
		return GetDistance(Pos, myHero) < self.Config.AutoC.CatchRange
	end
end
function kao:OrbwalkToPosition(position)
	if position ~= nil then
		if _G.MMA_Loaded then
			_G.moveToCursor(position.x, position.z)
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		elseif SxOLoad then
			SxO:ForcePoint(position.x, position.z)
		end
	end
end
function OnCreateObj(obj)
	if obj and obj.name == "olaf_axe_totem_team_id_green.troy" then
		champ.Movement = true
		champ.MoveTo = Vector(obj)
	end
end
function OnDeleteObj(obj)
	if obj and obj.name == "olaf_axe_totem_team_id_green.troy" then
		champ.Movement = false
		champ.MoveTo = nil
	end
end
function kao:Combo(target)
	if target ~= nil then
		if self.Q.IsReady() and self.Config.Combo.useQ and GetDistance(target, myHero) < self.comboQMaxRange then
			self:CastQ(target)
		end
		if self.W.IsReady() and self.Config.Combo.useW and GetDistance(target, myHero) < self.W.Range and myHero.health/myHero.maxHealth * 100 < self.Config.Skill.W.MinHP then
			CastSpell(_W)
		end
		if self.E.IsReady() and self.Config.Combo.useE and GetDistance(target, myHero) < self.E.Range then
			CastSpell(_E, target)
		end
	end
end
function kao:Harass(target)
	if target ~= nil then
		if self.Q.IsReady() and self.Config.Harass.useQ and GetDistance(target, myHero) < self.harassQMaxRange then
			self:CastQ(target)
		end
		if self.W.IsReady() and self.Config.Harass.useW and GetDistance(target, myHero) < self.W.Range and myHero.health/myHero.maxHealth * 100 < self.Config.Skill.W.MinHP then
			CastSpell(_W)
		end
		if self.E.IsReady() and self.Config.Harass.useE and GetDistance(target, myHero) < self.E.Range then
			CastSpell(_E, target)
		end
	end
end
function kao:LineClear()
	self.EnemyMinions:update()
	if self.Config.LineClear.useQ then
		for _, minion in pairs(self.EnemyMinions.objects) do
			if self.Q.IsReady() and #self.EnemyMinions.objects > 0 then
				local bestpos, besthit = GetBestLineFarmPosition(self.Q.Range, self.Q.Width, self.EnemyMinions.objects, myHero)
				if bestpos then
					CastSpell(_Q, bestpos.x, bestpos.z)
				end
			end
		end
	end
	if self.W.IsReady() and #self.EnemyMinions.objects > 3 and self.Config.LineClear.useW then
		CastSpell(_W)
	end
	if self.Config.LineClear.useE and self.W.IsReady() then
		for _, minion in pairs(self.EnemyMinions.objects) do
			if #self.EnemyMinions.objects > 0 and GetDistance(minion) < self.E.Range and not minion.dead and getDmg("E", minion, myHero) > minion.health then
				CastSpell(_E, minion)
			end
		end
	end
end
function kao:JungleClear()
	self.jungleTable:update()
	if self.Config.JungleClear.useQ then
		for _, minion in pairs(self.jungleTable.objects) do
			if self.Q.IsReady() and #self.jungleTable.objects > 0 then
				local bestpos, besthit = GetBestLineFarmPosition(self.Q.Range, self.Q.Width, self.jungleTable.objects, myHero)
				if bestpos then
					CastSpell(_Q, bestpos.x, bestpos.z)
				end
			end
		end
	end
	if self.W.IsReady() and #self.jungleTable.objects > 0 and self.Config.JungleClear.useW then
		CastSpell(_W)
	end
	if self.Config.JungleClear.useE and self.W.IsReady() then
		for _, minion in pairs(self.jungleTable.objects) do
			if #self.jungleTable.objects > 0 and GetDistance(minion) < self.E.Range and not minion.dead then
				CastSpell(_E, minion)
			end
		end
	end
end
function kao:CastQ(target)
	if self.Prediction[self.Config.Pred.QPred] == "HPrediction" then
		self.QPos, self.QHitChance = HP:GetPredict(self.HP_Q, target, myHero)
		self.QPos = self:GetExtraRange(self.QPos)
		if self.QPos and self.QHitChance >= self.Config.Pred.QHit then
			CastSpell(_Q, self.QPos.x, self.QPos.z)
		end
	elseif self.Prediction[self.Config.Pred.QPred] == "VPrediction" then
		self.QPos, self.QHitChance = VP:GetLineAOECastPosition(target, self.Q.Delay, self.Q.Width, self.Q.Range, self.Q.Speed, myHero)
		self.QPos = self:GetExtraRange(self.QPos)
		if self.QPos and self.QHitChance >= self.Config.Pred.QHit then
			CastSpell(_Q, self.QPos.x, self.QPos.z)
		end
	elseif self.Prediction[self.Config.Pred.QPred] == "SPrediction" then
		self.QPos, self.QHitChance, self.PredPos = SP:Predict(target, self.Q.Range, self.Q.Speed, self.Q.Delay, self.Q.Width*2, false, myHero)
		self.QPos = self:GetExtraRange(self.QPos)
		if self.QPos and self.QHitChance >= self.Config.Pred.QHit then
			CastSpell(_Q, self.QPos.x, self.QPos.z)
		end
	elseif self.Prediction[self.Config.Pred.QPred] == "DivinePred" then
		local Target = DPTarget(target)
		self.QState, self.QPos, self.QPerc = dp:predict("DivineQ", Target)
		self.QPos = self:GetExtraRange(self.QPos)
		if self.QPos and self.QState == SkillShot.STATUS.SUCCESS_HIT then
			CastSpell(_Q, self.QPos.x, self.QPos.z)
		end
	end
end
function kao:GetExtraRange(endP)
	local asdasd = GetDistance(endP)
	if (GetDistance(Vector(myHero) + ( Vector(endP) - Vector(myHero) ):normalized() * (self.QextraRange + asdasd)) < self.Q.Range) then
		return Vector(myHero) + ( Vector(endP) - Vector(myHero) ):normalized() * (self.QextraRange + asdasd) 
	else
		return endP
	end
end
function TARGB(colorTable)
    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])
end
function kao:IsComboPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.AutoCarry then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isFight then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsOrbwalking() then
			return true
		end
	end
    return false
end

function kao:IsHarassPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.MixedMode then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isHarass then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsDualCarrying() then
			return true
		end
	end
    return false
end

function kao:IsClearPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.LaneClear then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isLaneClear then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsLaneClearing() then
			return true
		end
	end
    return false
end

function kao:IsLastHitPressed()
	if SacLoad then
		if _G.AutoCarry.Keys.LastHit then
			return true
		end
	elseif SxOLoad then
		if _G.SxOrb.isLastHit then
			return true
		end
	elseif MMALoad then
		if _G.MMA_IsLastHitting() then
			return true
		end
	end
    return false
end
function kao:DisableMovement()
    if self.Move then
        if SacLoad then
            _G.AutoCarry.MyHero:MovementEnabled(false)
            self.Move = false
        elseif SxOLoad then
            SxO:DisableMove()
            self.Move = false
        elseif MMALoad then
            _G.MMA_AvoidMovement(true)
            self.Move = false
        end
    end
end

function kao:EnableMovement()
    if not self.Move then
        if SacLoad then
            _G.AutoCarry.MyHero:MovementEnabled(true)
            self.Move = true
        elseif SxOLoad then
            SxO:EnableMove()
            self.Move = true
        elseif MMALoad then
            _G.MMA_AvoidMovement(false)
            self.Move = true
        end
    end
end

function kao:DisableAttacks()
    if self.Attack then
        if SacLoad then
            _G.AutoCarry.MyHero:AttacksEnabled(false)
            self.Attack = false
        elseif SxOLoad then
            SxO:DisableAttacks()
            self.Attack = false
        elseif MMALoad then
            _G.MMA_StopAttacks(true)
            self.Attack = false
        end
    end
end

function kao:EnableAttacks()
    if not self.Attack then
        if SacLoad then
            _G.AutoCarry.MyHero:AttacksEnabled(true)
            self.Attack = true
        elseif SxOLoad then
            SxO:EnableAttacks()
            self.Attack = true
        elseif MMALoad then
            _G.MMA_StopAttacks(false)
            self.Attack = true
        end
    end
end
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
  self.LocalVersion = LocalVersion
  self.Host = Host
  self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
  self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
  self.SavePath = SavePath
  self.CallbackUpdate = CallbackUpdate
  self.CallbackNoUpdate = CallbackNoUpdate
  self.CallbackNewVersion = CallbackNewVersion
  self.CallbackError = CallbackError
  AddDrawCallback(function() self:OnDraw() end)
  self:CreateSocket(self.VersionPath)
  self.DownloadStatus = 'Connect to Server for VersionInfo'
  AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
  print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()

  if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
	DrawText3D('Olaf - the Berserker',myHero.x,myHero.y,myHero.z+70, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
    DrawText3D('Download Status: '..(self.DownloadStatus or 'Unknown'),myHero.x,myHero.y,myHero.z+50, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
  end
  
end

function ScriptUpdate:CreateSocket(url)

  if not self.LuaSocket then
    self.LuaSocket = require("socket")
  else
    self.Socket:close()
    self.Socket = nil
    self.Size = nil
    self.RecvStarted = false
  end
  
  self.LuaSocket = require("socket")
  self.Socket = self.LuaSocket.tcp()
  self.Socket:settimeout(0, 'b')
  self.Socket:settimeout(99999999, 't')
  self.Socket:connect('sx-bol.eu', 80)
  self.Url = url
  self.Started = false
  self.LastPrint = ""
  self.File = ""
end

function ScriptUpdate:Base64Encode(data)

  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  
  return ((data:gsub('.', function(x)
  
    local r,b='',x:byte()
    
    for i=8,1,-1 do
      r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0')
    end
    
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
  
    if (#x < 6) then
      return ''
    end
    
    local c=0
    
    for i=1,6 do
      c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0)
    end
    
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
  
end

function ScriptUpdate:GetOnlineVersion()

  if self.GotScriptVersion then
    return
  end
  
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading VersionInfo (0%)'
  end
  
  self.File = self.File .. (self.Receive or self.Snipped)
  
  if self.File:find('</s'..'ize>') then
  
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
      local _,ScriptFind = self.File:find('<scr'..'ipt>')
      local ScriptEnd = self.File:find('</scr'..'ipt>')
      
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      
      local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
      self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
    end
    
  end
  
  if self.File:find('</scr'..'ipt>') then
    self.DownloadStatus = 'Downloading VersionInfo (100%)'
    
    local a,b = self.File:find('\r\n\r\n')
    
    self.File = self.File:sub(a,-1)
     self.NewFile = ''
    
    for line,content in ipairs(self.File:split('\n')) do
    
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
      
    end
    
    local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
    local ContentEnd, _ = self.File:find('</sc'..'ript>')
    
    if not ContentStart or not ContentEnd then
    
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
      
    else
      self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart+1,ContentEnd-1)))
      self.OnlineVersion = tonumber(self.OnlineVersion)
      
      if self.OnlineVersion > self.LocalVersion then
      
        if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
          self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
        end
        
        self:CreateSocket(self.ScriptPath)
        self.DownloadStatus = 'Connect to Server for ScriptDownload'
        AddTickCallback(function() self:DownloadUpdate() end)
      else
        
        if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
          self.CallbackNoUpdate(self.LocalVersion)
        end
        
      end
      
    end
    
    self.GotScriptVersion = true
  end
  
end

function ScriptUpdate:DownloadUpdate()

  if self.GotScriptUpdate then
    return
  end
  
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading Script (0%)'
  end
  
  self.File = self.File .. (self.Receive or self.Snipped)
  
  if self.File:find('</si'..'ze>') then
  
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
      local _,ScriptFind = self.File:find('<scr'..'ipt>')
      local ScriptEnd = self.File:find('</scr'..'ipt>')
      
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      
      local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
      self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
    end
    
  end
  
  if self.File:find('</scr'..'ipt>') then
    self.DownloadStatus = 'Downloading Script (100%)'
    
    local a,b = self.File:find('\r\n\r\n')
    
    self.File = self.File:sub(a,-1)
    self.NewFile = ''
    
    for line,content in ipairs(self.File:split('\n')) do
    
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
      
    end
    
    local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
    local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
    
    if not ContentStart or not ContentEnd then
      
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
      
    else
      
      local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
      local newf = newf:gsub('\r','')
      
      if newf:len() ~= self.Size then
      
        if self.CallbackError and type(self.CallbackError) == 'function' then
          self.CallbackError()
        end
        
        return
      end
      
      local newf = Base64Decode(newf)
      
      if type(load(newf)) ~= 'function' then
      
        if self.CallbackError and type(self.CallbackError) == 'function' then
          self.CallbackError()
        end
        
      else
      
        local f = io.open(self.SavePath,"w+b")
        
        f:write(newf)
        f:close()
        
        if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
          self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
        end
        
      end
      
    end
    
    self.GotScriptUpdate = true
  end
  
end
