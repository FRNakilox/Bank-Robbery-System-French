AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')

if not playerRobber then
    local playerRobber
end

local function isAllowed(ply)
    return BANK_CONFIG.Robbers[team.GetName(ply:Team())]
end

local function teamsCount()
    local gCount = 0
    local bCount = 0
    
    for k, v in pairs(player.GetAll()) do
        local team = team.GetName(v:Team())

        if BANK_CONFIG.Government[team] then
            gCount = gCount +1
        elseif BANK_CONFIG.Bankers[team] then
            bCount = bCount +1
        end
    end

    return BANK_CONFIG.MinGovernment <= gCount, BANK_CONFIG.MinBankers <= bCount
end

function ENT:Initialize()
    self:SetModel('models/props/cs_assault/moneypallet.mdl')
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.BankSiren = CreateSound(self, 'bank_vault/siren.wav')
    self.BankSiren:SetSoundLevel(130)
    
    local phys = self:GetPhysicsObject()
    
    if phys:IsValid() then
        phys:EnableMotion(false)
    end
end

function ENT:Use(ply)
    local enoughCops, enoughBankers = teamsCount()
    
    if not isAllowed(ply) then
        DarkRP.notify(ply, 1, 3, "Vous ne pouvez pas commencer un braquage en tant que "..team.GetName(ply:Team())..'!')
        return
    elseif ply:isArrested() then
        DarkRP.notify(ply, 1, 3, "Vous ne pouvez pas commencer un braquage en étant arrêté!")
        return 
    elseif player.GetCount() < BANK_CONFIG.MinPlayers then
        DarkRP.notify(ply, 1, 3, "Vous ne pouvez pas commencer un braquage sans assez de joueurs!")
        return 
    elseif not enoughCops then
        DarkRP.notify(ply, 1, 3, "Vous ne pouvez pas commencer un braquage sans assez de policiers!")
        return
    elseif not enoughBankers then
        DarkRP.notify(ply, 1, 3, "Vous ne pouvez pas commencer un braquage sans assez de banquiers!")
        return
    elseif playerRobber then
        DarkRP.notify(ply, 1, 3, 'Un braquage est déjà en cours!')
        return
    elseif self:GetStatus() == 2 then
        DarkRP.notify(ply, 1, 3, 'Ce coffre-fort est en rechargement!')
        return
    end
    
    self:StartRobbery(ply)
end

function ENT:StartRobbery(ply)
    local name = ply:GetName()

    playerRobber = ply
    self.BankSiren:Play()
    self:SetStatus(1)
    self:SetNextAction(CurTime() +BANK_CONFIG.RobberyTime)
    ply:wanted(nil, 'Braque la banque!', BANK_CONFIG.RobberyTime)
    DarkRP.notify(ply, 0, 3, 'Vous avez commencé un braquage de banque!')
    DarkRP.notify(ply, 0, 10, "Ne vous éloignez pas trop ou le braquage échouera!")
    DarkRP.notifyAll(0, 10, name..' a commencé un braquage!')

    if not BANK_CONFIG.LoopSiren then
        timer.Simple(SoundDuration('bank_vault/siren.wav'), function()
            if self.BankSiren then
                self.BankSiren:Stop()
            end
        end)
    end

    hook.Add('Think', 'BankRS_RobberyThink', function()
        if self:GetNextAction() <= CurTime() then
            ply:addMoney(self:GetReward())
            self:SetReward(BANK_CONFIG.BaseReward)
            self:StartCooldown()
            DarkRP.notifyAll(0, 10, name..' a fini de braquer la banque!')
        else
            if ply:IsValid() then    
                if ply:isArrested() then
                    ply:unWanted()
                    self:StartCooldown()
                    DarkRP.notifyAll(1, 5, name..' a été arrêté pendant le braquage!')
                elseif not isAllowed(ply) then
                    self:StartCooldown()    
                    DarkRP.notifyAll(1, 5, name..' a changé de métier pendant le braquage!')
                elseif not ply:Alive() then
                    ply:unWanted()
                    self:StartCooldown()
                    DarkRP.notifyAll(1, 5, name..' est mort pendant le braquage!')
                elseif ply:GetPos():DistToSqr(self:GetPos()) > BANK_CONFIG.MaxDistance ^2 then
                    self:StartCooldown()
                    DarkRP.notifyAll(1, 5, name..' a quitté la zone de braquage!')
                end
            else
                self:StartCooldown()
                DarkRP.notifyAll(1, 5, name..' a quitté le serveur pendant le braquage!')
            end
        end
    end)
end

function ENT:StartCooldown()
    playerRobber = nil
    self.BankSiren:Stop()    
    self:SetStatus(2)
    self:SetNextAction(CurTime() +BANK_CONFIG.CooldownTime)
    hook.Remove('Think', 'BankRS_RobberyThink')
    timer.Simple(BANK_CONFIG.CooldownTime, function()
        if self:IsValid() then
            self:SetStatus(0)
        end
    end)
end

function ENT:OnRemove()
    if self.BankSiren:IsPlaying() then
        playerRobber = nil
        self.BankSiren:Stop()
        hook.Remove('Think', 'BankRS_RobberyThink')
    end
end

hook.Add('PlayerDeath', 'BankRS_RewardSavior', function(victim, inf, att)
    if victim ~= att and victim == playerRobber and att:IsPlayer() then
        att:addMoney(BANK_CONFIG.SaviorReward)
        DarkRP.notifyAll(0, 10, 'Notre héros '..att:GetName()..' a arrêté '..playerRobber:GetName()..' de braquer la banque!')
        DarkRP.notify(att, 0, 5, 'Vous avez été récompensé de '..DarkRP.formatMoney(BANK_CONFIG.SaviorReward)..' pour avoir arrêté un braquage!')
    end
end)

timer.Create('BankRS_ApplyInterest', BANK_CONFIG.InterestTime, 0, function()
    for k, v in pairs(ents.FindByClass('bank_vault')) do
        if v:GetStatus() == 0 then
            local value = v:GetReward()

            if value ~= BANK_CONFIG.MaxReward then
                v:SetReward(math.Clamp(value +BANK_CONFIG.Interest, 0, BANK_CONFIG.MaxReward))
            end
        end
    end
end)

local function spawnSaved()
    local read = file.Read('bankrs/'..game.GetMap()..'.txt', 'DATA')

    if read then
        local data = util.JSONToTable(read)
        
        for k, v in pairs(data) do
            local ent = ents.Create('bank_vault')
            ent:SetPos(v.pos)
            ent:SetAngles(v.ang)
            ent:Spawn()
        end

        MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), #data..' coffres-forts trouvés et chargés dans '..game.GetMap()..'.\n')
    else
        MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Aucune sauvegarde trouvée pour '..game.GetMap()..'.\n')
    end
end

hook.Add('InitPostEntity', 'BankRS_SpawnVaults', function()
    local function checkVersion()
        if not http or not http.Fetch then
            MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Impossible de vérifier les mises à jour - HTTP non disponible\n')
            return
        end
        
        http.Fetch('https://dl.dropboxusercontent.com/s/90pfxdcg0mtbumu/bankVersion.txt', 
            function(body, size, headers, code)   
                if code == 200 and body then
                    if body > '1.8.4' then 
                        MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Version obsolète détectée, veuillez mettre à jour.\n')
                    end
                else
                    MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Échec de la vérification des mises à jour - Réponse invalide\n')
                end
            end,
            function(error)
                MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Échec de la vérification des mises à jour: '..error..'\n')
            end
        )
    end

    pcall(checkVersion)
    
    spawnSaved()
end)


hook.Add('PostCleanupMap', 'BankRS_RespawnVaults', function()
    MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Nettoyage détecté! Tentative de réapparition des coffres-forts...\n')
    spawnSaved()
end)

concommand.Add('bankrs_save', function(ply)
    if ply:IsSuperAdmin() then
        local found = ents.FindByClass('bank_vault')

        if #found > 0 then
            local data = {}

            for k, v in pairs(found) do
                table.insert(data, {pos = v:GetPos(), ang = v:GetAngles()})
            end

            if not file.Exists('bankrs', 'DATA') then
                file.CreateDir('bankrs')
            end
            
            file.Write('bankrs/'..game.GetMap()..'.txt', util.TableToJSON(data))
            DarkRP.notify(ply, 0, 10, #found..' coffres-forts sauvegardés.')
            MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Nouvelle sauvegarde pour '..game.GetMap()..' contenant '..#found..' coffres-forts écrite.\n')
        else
            DarkRP.notify(ply, 1, 5, 'Aucun coffre-fort trouvé.')
        end
    end
end)

concommand.Add('bankrs_wipe', function(ply)
    if ply:IsSuperAdmin() then
        local read = file.Read('bankrs/'..game.GetMap()..'.txt', 'DATA')
        
        if read then
            file.Delete('bankrs/'..game.GetMap()..'.txt')
            DarkRP.notify(ply, 0, 10, 'Données de sauvegarde effacées.')
            MsgC(Color(255, 0, 0), '[BankRS] ', Color(255, 255, 0), 'Données de sauvegarde pour '..game.GetMap()..' effacées!\n')
        else
            DarkRP.notify(ply, 1, 5, 'Aucune donnée de sauvegarde trouvée pour '..game.GetMap()..'!')
        end
    end
end)