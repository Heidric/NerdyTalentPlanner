local NTP = NerdyTalentPlanner

local function keyForTalent(talentId)
  return tostring(talentId)
end

local function getRankFromRanks(ranks, talentId)
  return ranks[keyForTalent(talentId)] or 0
end

local function setRankInRanks(ranks, talentId, rank)
  local key = keyForTalent(talentId)

  if rank <= 0 then
    ranks[key] = nil
  else
    ranks[key] = rank
  end
end

local function cloneRanks(ranks)
  local copy = {}

  for key, value in pairs(ranks or {}) do
    copy[key] = value
  end

  return copy
end

function NTP:GetScratchBuild(classToken)
  self:EnsureDB()

  NerdyTalentPlannerDB.scratch[classToken] = NerdyTalentPlannerDB.scratch[classToken] or {
    classToken = classToken,
    ranks = {},
    order = {},
  }

  local build = NerdyTalentPlannerDB.scratch[classToken]
  local classData = self:GetClassData(classToken)
  local dataVersion = NTP_TalentData and NTP_TalentData.version or 0
  local dataKey = classData and classData.dataKey or ("static:" .. tostring(dataVersion) .. ":" .. tostring(classToken))

  if build.dataKey ~= dataKey then
    build.ranks = {}
    build.order = {}
    build.dataKey = dataKey
  end

  build.ranks = build.ranks or {}
  build.order = build.order or {}

  return build
end

function NTP:GetRank(build, talentId)
  return getRankFromRanks(build.ranks, talentId)
end

function NTP:GetTotalPoints(build)
  local total = 0

  for _, rank in pairs(build.ranks or {}) do
    total = total + rank
  end

  return total
end

function NTP:GetTreePoints(build, tree)
  local total = 0

  for _, talent in ipairs(tree.talents or {}) do
    total = total + getRankFromRanks(build.ranks, talent.talentId)
  end

  return total
end

function NTP:GetTreePointsExcludingTalent(build, tree, excludedTalentId)
  local total = 0

  for _, talent in ipairs(tree.talents or {}) do
    if talent.talentId ~= excludedTalentId then
      total = total + getRankFromRanks(build.ranks, talent.talentId)
    end
  end

  return total
end

function NTP:GetRequiredTreePoints(talent)
  return (talent.row - 1) * self.config.pointsPerTier
end

function NTP:RequirementsMet(build, talent)
  for _, requirement in ipairs(talent.validRequires or {}) do
    if getRankFromRanks(build.ranks, requirement.talentId) < requirement.requiredRank then
      return false, "Requires " .. tostring(requirement.requiredRank) .. " point(s) in prerequisite talent."
    end
  end

  return true
end

function NTP:TierMet(build, talent)
  local treePoints = self:GetTreePointsExcludingTalent(build, talent.tree, talent.talentId)
  local requiredPoints = self:GetRequiredTreePoints(talent)

  if treePoints < requiredPoints then
    return false, "Requires " .. tostring(requiredPoints) .. " point(s) in " .. talent.tree.name .. "."
  end

  return true
end

function NTP:CanAddPoint(build, talent)
  local currentRank = getRankFromRanks(build.ranks, talent.talentId)

  if currentRank >= talent.maxRank then
    return false, "Talent is already at maximum rank."
  end

  local maxPoints = NerdyTalentPlannerDB and NerdyTalentPlannerDB.settings and NerdyTalentPlannerDB.settings.maxPoints or self.config.maxPoints
  if self:GetTotalPoints(build) >= maxPoints then
    return false, "Build already uses the configured point limit."
  end

  local tierMet, tierReason = self:TierMet(build, talent)
  if not tierMet then
    return false, tierReason
  end

  local requirementsMet, requirementsReason = self:RequirementsMet(build, talent)
  if not requirementsMet then
    return false, requirementsReason
  end

  return true
end

function NTP:ValidateRanksForClass(classData, ranks)
  local temporaryBuild = {
    classToken = classData.token,
    ranks = ranks,
  }

  for _, tree in ipairs(classData.trees or {}) do
    for _, talent in ipairs(tree.talents or {}) do
      local rank = getRankFromRanks(ranks, talent.talentId)

      if rank > talent.maxRank then
        return false, talent.name .. " exceeds maximum rank."
      end

      if rank > 0 then
        local tierMet, tierReason = self:TierMet(temporaryBuild, talent)
        if not tierMet then
          return false, talent.name .. ": " .. tierReason
        end

        local requirementsMet, requirementsReason = self:RequirementsMet(temporaryBuild, talent)
        if not requirementsMet then
          return false, talent.name .. ": " .. requirementsReason
        end
      end
    end
  end

  return true
end

function NTP:CanRemovePoint(build, talent)
  local currentRank = getRankFromRanks(build.ranks, talent.talentId)

  if currentRank <= 0 then
    return false, "Talent has no assigned points."
  end

  local classData = self:GetClassData(build.classToken)
  local ranks = cloneRanks(build.ranks)
  setRankInRanks(ranks, talent.talentId, currentRank - 1)

  return self:ValidateRanksForClass(classData, ranks)
end

function NTP:AddPoint(build, talent)
  local canAdd, reason = self:CanAddPoint(build, talent)
  if not canAdd then
    return false, reason
  end

  local currentRank = getRankFromRanks(build.ranks, talent.talentId)
  setRankInRanks(build.ranks, talent.talentId, currentRank + 1)
  table.insert(build.order, { talentId = talent.talentId, rank = currentRank + 1 })

  return true
end

function NTP:RemovePoint(build, talent)
  local canRemove, reason = self:CanRemovePoint(build, talent)
  if not canRemove then
    return false, reason
  end

  local currentRank = getRankFromRanks(build.ranks, talent.talentId)
  setRankInRanks(build.ranks, talent.talentId, currentRank - 1)

  for index = #(build.order), 1, -1 do
    if build.order[index].talentId == talent.talentId then
      table.remove(build.order, index)
      break
    end
  end

  return true
end

function NTP:ResetBuild(classToken)
  local build = self:GetScratchBuild(classToken)
  build.ranks = {}
  build.order = {}
end



local function cloneOrder(order)
  local copy = {}

  for index, entry in ipairs(order or {}) do
    copy[index] = {
      talentId = entry.talentId,
      rank = entry.rank,
    }
  end

  return copy
end

function NTP:SetScratchBuild(build)
  if not build or not build.classToken then
    return false, "Invalid build."
  end

  self:EnsureDB()
  local scratch = self:GetScratchBuild(build.classToken)
  scratch.ranks = cloneRanks(build.ranks or {})
  scratch.order = cloneOrder(build.order or {})
  scratch.dataKey = build.dataKey or scratch.dataKey

  return true
end

function NTP:CopyBuild(build)
  if not build then
    return nil
  end

  return {
    id = build.id,
    name = build.name,
    classToken = build.classToken,
    ranks = cloneRanks(build.ranks or {}),
    order = cloneOrder(build.order or {}),
    dataKey = build.dataKey,
    createdAt = build.createdAt,
    updatedAt = build.updatedAt,
  }
end

local function getDateStamp()
  if date then
    return date("%Y-%m-%d %H:%M")
  end

  return "unknown date"
end

function NTP:CreateSavedBuildId()
  self:EnsureDB()
  NerdyTalentPlannerDB.savedBuildCounter = (NerdyTalentPlannerDB.savedBuildCounter or 0) + 1
  return "build-" .. tostring(NerdyTalentPlannerDB.savedBuildCounter)
end

function NTP:GetSavedBuilds()
  self:EnsureDB()
  NerdyTalentPlannerDB.savedBuilds = NerdyTalentPlannerDB.savedBuilds or {}
  return NerdyTalentPlannerDB.savedBuilds
end

function NTP:GetSavedBuildById(buildId)
  for _, savedBuild in ipairs(self:GetSavedBuilds()) do
    if savedBuild.id == buildId then
      return savedBuild
    end
  end

  return nil
end

function NTP:SaveScratchBuild(classToken, name)
  local scratch = self:GetScratchBuild(classToken)
  local savedBuild = self:CopyBuild(scratch)
  local classData = self:GetClassData(classToken)
  local stamp = getDateStamp()

  savedBuild.id = self:CreateSavedBuildId()
  savedBuild.name = (name and name ~= "" and name) or ((classData and classData.name or classToken) .. " Build " .. stamp)
  savedBuild.createdAt = stamp
  savedBuild.updatedAt = stamp

  table.insert(self:GetSavedBuilds(), savedBuild)
  return savedBuild
end

function NTP:RenameSavedBuild(buildId, name)
  if not name or name == "" then
    return false, "Build name cannot be empty."
  end

  local savedBuild = self:GetSavedBuildById(buildId)
  if not savedBuild then
    return false, "Saved build was not found."
  end

  savedBuild.name = name
  savedBuild.updatedAt = getDateStamp()
  return true
end

function NTP:DeleteSavedBuild(buildId)
  local savedBuilds = self:GetSavedBuilds()

  for index, savedBuild in ipairs(savedBuilds) do
    if savedBuild.id == buildId then
      table.remove(savedBuilds, index)
      return true
    end
  end

  return false, "Saved build was not found."
end

function NTP:LoadSavedBuild(buildId)
  local savedBuild = self:GetSavedBuildById(buildId)
  if not savedBuild then
    return false, "Saved build was not found."
  end

  return self:SetScratchBuild(savedBuild)
end

function NTP:GetPlannedLevelForOrderIndex(orderIndex)
  orderIndex = tonumber(orderIndex) or 1

  local level = self.config.firstTalentLevel or 10
  local remaining = orderIndex
  local bonusLevels = self.config.bonusTalentPointLevels or {}

  while true do
    remaining = remaining - 1
    if remaining <= 0 then
      return level
    end

    if bonusLevels[level] then
      remaining = remaining - 1
      if remaining <= 0 then
        return level
      end
    end

    level = level + 1
  end
end
