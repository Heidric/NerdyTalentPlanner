NerdyTalentPlanner = NerdyTalentPlanner or {}
local NTP = NerdyTalentPlanner

local function lower(value)
  return string.lower(tostring(value or ""))
end

local function sortedKeys(source)
  local keys = {}

  for key in pairs(source or {}) do
    keys[#keys + 1] = key
  end

  table.sort(keys)
  return keys
end

local function firstNonEmpty(...)
  local values = {...}

  for index = 1, #values do
    local value = values[index]
    if value ~= nil and value ~= "" then
      return value
    end
  end

  return nil
end

function NTP:GetPlayerClassToken()
  local _, classToken = UnitClass("player")
  return classToken
end

function NTP:CollectLiveTalentData()
  local _, classToken = UnitClass("player")
  local result = {
    class = classToken,
    className = firstNonEmpty(UnitClass("player"), classToken),
    build = GetBuildInfo and GetBuildInfo() or nil,
    dumpedAt = date and date("%Y-%m-%d %H:%M:%S") or nil,
    trees = {},
  }

  local tabCount = GetNumTalentTabs and GetNumTalentTabs() or 0

  for tabIndex = 1, tabCount do
    local tabName, tabIcon, pointsSpent, background = GetTalentTabInfo(tabIndex)
    local tree = {
      index = tabIndex,
      name = tabName,
      icon = tabIcon,
      pointsSpent = pointsSpent,
      background = background,
      talents = {},
    }

    local talentCount = GetNumTalents and GetNumTalents(tabIndex) or 0

    for talentIndex = 1, talentCount do
      local name, icon, row, col, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabIndex, talentIndex)
      local prereqRow, prereqCol, prereqIsLearnable

      if GetTalentPrereqs then
        prereqRow, prereqCol, prereqIsLearnable = GetTalentPrereqs(tabIndex, talentIndex)
      end

      tree.talents[#tree.talents + 1] = {
        index = talentIndex,
        name = name,
        icon = icon,
        row = row,
        col = col,
        rank = rank,
        maxRank = maxRank,
        isExceptional = isExceptional,
        meetsPrereq = meetsPrereq,
        prereq = prereqRow and {
          row = prereqRow,
          col = prereqCol,
          isLearnable = prereqIsLearnable,
        } or nil,
      }
    end

    result.trees[#result.trees + 1] = tree
  end

  return result
end

function NTP:DumpLiveTalents()
  self:EnsureDB()

  local classToken = self:GetPlayerClassToken()
  if not classToken then
    self:Print("Could not resolve player class token.")
    return
  end

  local dump = self:CollectLiveTalentData()

  NerdyTalentPlannerDB.liveDumps = NerdyTalentPlannerDB.liveDumps or {}
  NerdyTalentPlannerDB.liveDumps[classToken] = dump

  local talentCount = 0
  for _, tree in ipairs(dump.trees or {}) do
    talentCount = talentCount + #(tree.talents or {})
  end

  self:Print("Live dump saved for " .. tostring(classToken) .. ": " .. tostring(#(dump.trees or {})) .. " tree(s), " .. tostring(talentCount) .. " talent(s).")
  self:Print("Run /reload or exit the game to write SavedVariables to disk.")
  self:Print("File: WTF\\Account\\<account>\\SavedVariables\\NerdyTalentPlanner.lua")
end

local function mapTreesByName(classData)
  local result = {}

  for _, tree in ipairs((classData and classData.trees) or {}) do
    result[lower(tree.name)] = tree
  end

  return result
end

local function mapTalentsByName(tree)
  local result = {}

  for _, talent in ipairs((tree and tree.talents) or {}) do
    result[lower(talent.name)] = talent
  end

  return result
end

local function mapTalentsByPosition(tree)
  local result = {}

  for _, talent in ipairs((tree and tree.talents) or {}) do
    if talent.row and talent.col then
      result[tostring(talent.row) .. ":" .. tostring(talent.col)] = talent
    end
  end

  return result
end

function NTP:CheckLiveTalents()
  if not self.index and self.BuildIndex then
    self:BuildIndex()
  end

  local classToken = self:GetPlayerClassToken()
  if not classToken then
    self:Print("Could not resolve player class token.")
    return
  end

  local generatedClass = self.index and self.index.classes and self.index.classes[classToken]
  if not generatedClass then
    self:Print("No generated data exists for " .. tostring(classToken) .. ".")
    return
  end

  local liveClass = self:CollectLiveTalentData()
  local generatedTreesByName = mapTreesByName(generatedClass)
  local generatedCount = 0
  local liveCount = 0
  local extraGenerated = {}
  local missingGenerated = {}
  local positionMismatches = {}

  for _, tree in ipairs(generatedClass.trees or {}) do
    generatedCount = generatedCount + #(tree.talents or {})
  end

  for _, liveTree in ipairs(liveClass.trees or {}) do
    liveCount = liveCount + #(liveTree.talents or {})

    local generatedTree = generatedTreesByName[lower(liveTree.name)] or (generatedClass.trees and generatedClass.trees[liveTree.index])

    if generatedTree then
      local generatedByName = mapTalentsByName(generatedTree)
      local liveByName = mapTalentsByName(liveTree)
      local liveByPosition = mapTalentsByPosition(liveTree)

      for _, generatedTalent in ipairs(generatedTree.talents or {}) do
        if not liveByName[lower(generatedTalent.name)] then
          extraGenerated[#extraGenerated + 1] = tostring(generatedTree.name) .. ": " .. tostring(generatedTalent.name)
        else
          local liveTalent = liveByName[lower(generatedTalent.name)]
          if liveTalent.row ~= generatedTalent.row or liveTalent.col ~= generatedTalent.col or liveTalent.maxRank ~= generatedTalent.maxRank then
            positionMismatches[#positionMismatches + 1] = tostring(generatedTree.name) .. ": " .. tostring(generatedTalent.name)
          end
        end

        local liveTalentAtPosition = liveByPosition[tostring(generatedTalent.row) .. ":" .. tostring(generatedTalent.col)]
        if liveTalentAtPosition and lower(liveTalentAtPosition.name) ~= lower(generatedTalent.name) then
          positionMismatches[#positionMismatches + 1] = tostring(generatedTree.name) .. " row " .. tostring(generatedTalent.row) .. " col " .. tostring(generatedTalent.col) .. ": generated " .. tostring(generatedTalent.name) .. ", live " .. tostring(liveTalentAtPosition.name)
        end
      end

      for _, liveTalent in ipairs(liveTree.talents or {}) do
        if not generatedByName[lower(liveTalent.name)] then
          missingGenerated[#missingGenerated + 1] = tostring(liveTree.name) .. ": " .. tostring(liveTalent.name)
        end
      end
    else
      missingGenerated[#missingGenerated + 1] = "Missing generated tree: " .. tostring(liveTree.name)
    end
  end

  self:Print("Live check for " .. tostring(classToken) .. ": generated " .. tostring(generatedCount) .. " talent(s), live " .. tostring(liveCount) .. " talent(s).")
  self:Print("Extra generated talents: " .. tostring(#extraGenerated))
  self:Print("Missing generated talents: " .. tostring(#missingGenerated))
  self:Print("Position/rank mismatches: " .. tostring(#positionMismatches))

  local limit = 12

  if #extraGenerated > 0 then
    self:Print("First extra generated talent(s):")
    for index = 1, math.min(limit, #extraGenerated) do
      self:Print("  " .. tostring(extraGenerated[index]))
    end
  end

  if #missingGenerated > 0 then
    self:Print("First missing generated talent(s):")
    for index = 1, math.min(limit, #missingGenerated) do
      self:Print("  " .. tostring(missingGenerated[index]))
    end
  end

  if #positionMismatches > 0 then
    self:Print("First position/rank mismatch(es):")
    for index = 1, math.min(limit, #positionMismatches) do
      self:Print("  " .. tostring(positionMismatches[index]))
    end
  end
end
