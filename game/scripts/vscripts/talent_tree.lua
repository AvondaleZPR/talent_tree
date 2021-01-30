if (not _G.TalentTree) then
    _G.TalentTree = class({})
end

function TalentTree:Init()
    if (not IsServer() or TalentTree.initialized) then
        return
    end
	
    self.abilitiesData = LoadKeyValues("scripts/npc/npc_hero_talents.txt")
    local data = LoadKeyValues("scripts/kv/hero_talents.txt")
    self.talentsData = {}
    self.tabs = {}
    self.rows = {}	
    if (not data) then
        print("[TalentTree] Error loading scripts/kv/hero_talents.txt.")
        return
    end
    if (not data["Points"]) then
        print("[TalentTree] Can't find talents data.")
        return
    end
	
	for _,hero in pairs(data) do
		if not hero["min_level"] then
			for tabName, tabData in pairs(hero) do
				table.insert(self.tabs, tabName)
				for nlvl, talents in pairs(tabData) do
					table.insert(self.rows, tonumber(nlvl))
					for _, talent in pairs(talents) do
						local talentData = {
							Ability = talent,
							Tab = #self.tabs,
							NeedLevel = tonumber(nlvl)
						}
						if self.abilitiesData[talent] then
							talentData.MaxLevel = self.abilitiesData[talent]["MaxLevel"] or 4
						else
							talentData.MaxLevel = 4
						end
						table.insert(self.talentsData, talentData)
					end
				end
			end
		end
	end
	
    local loclenght = 1
    local locarr = {}
    table.sort(self.rows)
    for i = 1, #self.rows do
        if locarr[self.rows[i]] == nil then
            locarr[self.rows[i]] = loclenght
            loclenght = loclenght + 1
        end
    end
	
    self.rows = locarr
    TalentTree:InitPanaromaEvents()
    TalentTree.initialized = true
	
	self.talentData = data
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(self, 'OnPlayerLevelUp'), self)	
end

function TalentTree:InitPanaromaEvents()
    CustomGameEventManager:RegisterListener("talent_tree_get_talents", Dynamic_Wrap(TalentTree, 'OnTalentTreeTalentsRequest'))
    CustomGameEventManager:RegisterListener("talent_tree_level_up_talent", Dynamic_Wrap(TalentTree, 'OnTalentTreeLevelUpRequest'))
    CustomGameEventManager:RegisterListener("talent_tree_get_state", Dynamic_Wrap(TalentTree, 'OnTalentTreeStateRequest'))
    CustomGameEventManager:RegisterListener("talent_tree_reset_talents", Dynamic_Wrap(TalentTree, 'OnTalentTreeResetRequest'))
end

function TalentTree:OnPlayerLevelUp(keys)
	local player = PlayerResource:GetPlayer(keys.player_id)
	local level = keys.level
	local hero = player:GetAssignedHero()
	local kv = TalentTree.talentData["Points"] 
	
	if hero and level >= kv["min_level"] and level <= kv["max_level"] then
		local points = tonumber(kv["amount"])
		for k,v in pairs(kv["special_levels"]) do
			if k == tostring(level) then
				points = tonumber(v)
			end
		end
		TalentTree:AddTalentPointsToHero(hero, points)
	end
end

function TalentTree:OnTalentTreeTalentsRequest(event)
    if (not event or not event.PlayerID) then
        return
    end
    local player = PlayerResource:GetPlayer(event.PlayerID)
    if (not player) then
        return
    end
    CustomGameEventManager:Send_ServerToPlayer(player, "talent_tree_get_talents_from_server", {talents = TalentTree.talentsData, tabs = TalentTree.tabs, rows = TalentTree.rows})
end

function TalentTree:GetColumnTalentPoints(hero, tab)
    local points = 0
    if hero and hero.talents then
        for talentId, lvl in pairs(hero.talents.level) do
            if TalentTree.talentsData[talentId].Tab == tab then
                points = points + lvl
            end
        end
    end
    return points
end

function TalentTree:GetLatestTalentID()
	--[[
    -- local id = -1
    -- for talentId, _ in pairs(TalentTree.talentsData) do
    --     local convertedId = tonumber(talentId)
    --     if (convertedId > id) then
    --         id = convertedId
    --     end
    -- end
	]]
    return #TalentTree.talentsData
end

function TalentTree:SetupForHero(hero)
    if (not hero) then
        return
    end
    hero.talents = {}
    hero.talents.level = {}
    hero.talents.abilities = {}
    for i = 1, TalentTree:GetLatestTalentID() do
        hero.talents.level[i] = 0
    end
    hero.talents.currentPoints = 0
end

function TalentTree:GetHeroCurrentTalentPoints(hero)
    if (not hero or not hero.talents) then
        return 0
    end
    return hero.talents.currentPoints or 0
end

function TalentTree:AddTalentPointsToHero(hero, points)
    if (not hero or not hero.talents) then
        return false
    end
    points = tonumber(points)
    if (not points) then
        return false
    end
    hero.talents.currentPoints = hero.talents.currentPoints + points
    local event = {
        PlayerID = hero:GetPlayerOwnerID()
    }
    TalentTree:OnTalentTreeStateRequest(event)
end

ListenToGameEvent("npc_spawned", function(keys)
    if (not IsServer()) then
        return
    end
    local unit = EntIndexToHScript(keys.entindex)
    if (TalentTree:IsHeroHaveTalentTree(unit) == false and unit.IsRealHero and unit:IsRealHero()) then
        TalentTree:SetupForHero(unit)
    end
end, nil)

function TalentTree:IsHeroHaveTalentTree(hero)
    if (not hero) then
        return false
    end
    if (hero.talents) then
        return true
    end
    return false
end

function TalentTree:GetTalentTab(talentId)
    if (TalentTree.talentsData[talentId]) then
        return TalentTree.talentsData[talentId].Tab
    end
    return -1
end

function TalentTree:GetTalentMaxLevel(talentId)
    if (TalentTree.talentsData[talentId]) then
        return TalentTree.talentsData[talentId].MaxLevel
    end
    return -1
end

function TalentTree:GetHeroTalentLevel(hero, talentId)
    if (TalentTree:IsHeroHaveTalentTree(hero) == true and talentId and talentId > 0) then
        return hero.talents.level[talentId]
    end
    return 0
end

function TalentTree:SetHeroTalentLevel(hero, talentId, level)
    level = tonumber(level)
    if (hero.talents and talentId > 0 and level and level > -1) then
        hero.talents.level[talentId] = level
		-- remove
        if (level == 0) then
            if (hero.talents.abilities[talentId]) then
                hero.talents.abilities[talentId]:GetCaster():RemoveAbilityByHandle(hero.talents.abilities[talentId])
                hero.talents.abilities[talentId] = nil
            end
		-- level up
        else
            if (not hero.talents.abilities[talentId]) then
                hero.talents.abilities[talentId] = hero:AddAbility(TalentTree.talentsData[talentId].Ability)
            end
            if(hero.talents.abilities[talentId]) then
                hero.talents.abilities[talentId]:SetLevel(level)
            end
        end
        
        TalentTree:OnTalentTreeStateRequest({ PlayerID = hero:GetPlayerOwnerID() })
    end
end

--[[
-- function TalentTree:IsHeroSpendEnoughPointsInColumnForTalent(hero, talentId)
--     if (not TalentTree.talentsData[talentId]) then
--         return false
--     end
--     local row = TalentTree:GetTalentRow(talentId)
--     local column = TalentTree:GetTalentColumn(talentId)
--     local totalRequiredPoints = 0
--     for _, requirementsData in pairs(TalentTree.talentsRequirements) do
--         if (requirementsData.Column == column and requirementsData.Row == row) then
--             totalRequiredPoints = requirementsData.RequiredPoints
--             break
--         end
--     end
--     local pointsSpendedInColumn = 0
--     for i = 1, TalentTree:GetLatestTalentID() do
--         if (TalentTree:GetTalentColumn(i) == column and TalentTree:GetTalentRow(i) < row) then
--             pointsSpendedInColumn = pointsSpendedInColumn + TalentTree:GetHeroTalentLevel(hero, i)
--         end
--     end
--     if (pointsSpendedInColumn >= totalRequiredPoints) then
--         return true
--     end
--     return false
-- end
]]

function TalentTree:IsHeroCanLevelUpTalent(hero, talentId)
    if (not TalentTree.talentsData[talentId]) then
        return false
    end
    if (TalentTree:GetHeroTalentLevel(hero, talentId) >= TalentTree:GetTalentMaxLevel(talentId)) then
        return false
    end
    if (TalentTree:GetHeroCurrentTalentPoints(hero) <= 0) then
        return false
    end
    -- local row = TalentTree:GetTalentRow(talentId)
    -- local column = TalentTree:GetTalentColumn(talentId)
    local heroLevel = hero:GetLevel()
    if heroLevel < TalentTree.talentsData[talentId].NeedLevel then
        return false
    end
    for i = 1, TalentTree:GetLatestTalentID() do
        if (i ~= talentId and TalentTree.talentsData[i].NeedLevel == TalentTree.talentsData[talentId].NeedLevel and TalentTree:GetHeroTalentLevel(hero, i) > 0) then
            return false
        end
    end
    return true
end

function TalentTree:OnTalentTreeResetRequest(event)
    if (not IsServer()) then
        return
    end
    if (event == nil or not event.PlayerID) then
        return
    end
    local player = PlayerResource:GetPlayer(event.PlayerID)
    if (not player) then
        return
    end
    local hero = player:GetAssignedHero()
    if (not hero) then
        return
    end
    if (TalentTree:IsHeroHaveTalentTree(hero) == false) then
        return
    end
    local pointsToReturn = 0
    for i = 1, TalentTree:GetLatestTalentID() do
        pointsToReturn = pointsToReturn + TalentTree:GetHeroTalentLevel(hero, i)
        TalentTree:SetHeroTalentLevel(hero, i, 0)
    end
    TalentTree:AddTalentPointsToHero(hero, pointsToReturn)
end

function TalentTree:OnTalentTreeLevelUpRequest(event)
    if (not IsServer()) then
        return
    end
    if (event == nil or not event.PlayerID) then
        return
    end
    local talentId = tonumber(event.id)
    if (not talentId or talentId < 1 or talentId > TalentTree:GetLatestTalentID()) then
        return
    end
    local player = PlayerResource:GetPlayer(event.PlayerID)
    if (not player) then
        return
    end
    local hero = player:GetAssignedHero()
    if (not hero) then
        return
    end
    if not hero.talents then
        return
    end
	
    if TalentTree:IsHeroCanLevelUpTalent(hero, talentId) then--(TalentTree:IsHeroSpendEnoughPointsInColumnForTalent(hero, talentId) and TalentTree:IsHeroCanLevelUpTalent(hero, talentId)) then
        local talentLvl = TalentTree:GetHeroTalentLevel(hero, talentId)
        TalentTree:AddTalentPointsToHero(hero, -1)
        TalentTree:SetHeroTalentLevel(hero, talentId, talentLvl + 1)
    end
end

-- отправляет текущее состояние талантов и ково поинтов на клиент игрока
function TalentTree:OnTalentTreeStateRequest(event)
    if (not IsServer()) then
        return
    end
    if (not event or not event.PlayerID) then
        return
    end
    local player = PlayerResource:GetPlayer(event.PlayerID)
    if (not player) then
        return
    end
	
    Timers:CreateTimer(0, function()
        local hero = player:GetAssignedHero()
        if (hero == nil) then
            return 1.0
        end
		
        if not hero.talents then
            return 1.0
        end
		
        local resultTable = {}
        for i = 1, TalentTree:GetLatestTalentID() do
		local talentLvl = TalentTree:GetHeroTalentLevel(hero, i)
		local talentMaxLvl = TalentTree:GetTalentMaxLevel(i)
		
		local isDisabled = TalentTree:IsHeroCanLevelUpTalent(hero, i) == false--(TalentTree:IsHeroSpendEnoughPointsInColumnForTalent(hero, i) == false) or 
			if (talentLvl == talentMaxLvl) then
				isDisabled = false
			end
			table.insert(resultTable, { id = i, disabled = isDisabled, level = talentLvl, maxlevel = talentMaxLvl })
		end
		
		if (TalentTree:GetHeroCurrentTalentPoints(hero) == 0) then
			for _, talent in pairs(resultTable) do
				if (TalentTree:GetHeroTalentLevel(hero, talent.id) == 0) then
					talent.disabled = true
					talent.lvlup = false
				end
			end
		end
		
		CustomGameEventManager:Send_ServerToPlayer(player, "talent_tree_get_state_from_server", { talents = json.encode(resultTable), points = TalentTree:GetHeroCurrentTalentPoints(hero) })
	end)
end

--
TalentTree:Init()