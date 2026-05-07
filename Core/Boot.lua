NerdyTalentPlanner = NerdyTalentPlanner or {}
local NTP = NerdyTalentPlanner

NTP.name = "NerdyTalentPlanner"
NTP.displayName = "Nerdy Talent Planner"
NTP.version = "0.1.25"

NTP.config = {
  firstTalentLevel = 10,
  maxPoints = 61,
  pointsPerTier = 5,
  bonusTalentPointLevels = {
    [14] = true,
    [19] = true,
    [24] = true,
    [29] = true,
    [34] = true,
    [39] = true,
    [44] = true,
    [49] = true,
    [54] = true,
    [60] = true,
  },
}

NTP.classDisplayNames = {
  WARRIOR = "Warrior",
  PALADIN = "Paladin",
  HUNTER = "Hunter",
  ROGUE = "Rogue",
  PRIEST = "Priest",
  SHAMAN = "Shaman",
  MAGE = "Mage",
  WARLOCK = "Warlock",
  DRUID = "Druid",
}


NTP.classMeta = {
  WARRIOR = { classId = 1, classMask = 1, name = "Warrior" },
  PALADIN = { classId = 2, classMask = 2, name = "Paladin" },
  HUNTER = { classId = 3, classMask = 4, name = "Hunter" },
  ROGUE = { classId = 4, classMask = 8, name = "Rogue" },
  PRIEST = { classId = 5, classMask = 16, name = "Priest" },
  DEATHKNIGHT = { classId = 6, classMask = 32, name = "Death Knight" },
  SHAMAN = { classId = 7, classMask = 64, name = "Shaman" },
  MAGE = { classId = 8, classMask = 128, name = "Mage" },
  WARLOCK = { classId = 9, classMask = 256, name = "Warlock" },
  DRUID = { classId = 11, classMask = 1024, name = "Druid" },
}

local function createSyntheticTalentId(classToken, treeIndex, talentIndex)
  local meta = NTP.classMeta and NTP.classMeta[classToken]
  local classId = meta and meta.classId or 0
  return 9000000 + (classId * 100000) + ((treeIndex or 0) * 1000) + (talentIndex or 0)
end

local function findTalentByPosition(tree, row, col)
  for _, talent in ipairs((tree and tree.talents) or {}) do
    if talent.row == row and talent.col == col then
      return talent
    end
  end

  return nil
end

function NTP:CreateClassDataFromLiveDump(classToken, dump)
  if not classToken or not dump or not dump.trees then
    return nil
  end

  local meta = self.classMeta and self.classMeta[classToken] or {}
  local classData = {
    token = classToken,
    name = dump.className or meta.name or self.classDisplayNames[classToken] or classToken,
    classId = meta.classId or 0,
    classMask = meta.classMask or 0,
    dataSource = "liveDump",
    dataKey = "liveDump:" .. tostring(classToken) .. ":" .. tostring(dump.dumpedAt or "unknown"),
    trees = {},
  }

  for treeIndex, liveTree in ipairs(dump.trees or {}) do
    local tree = {
      tabId = liveTree.index or treeIndex,
      name = liveTree.name or ("Tree " .. tostring(treeIndex)),
      order = treeIndex - 1,
      icon = liveTree.icon,
      background = liveTree.background,
      talents = {},
    }

    for talentIndex, liveTalent in ipairs(liveTree.talents or {}) do
      local syntheticTalentId = createSyntheticTalentId(classToken, treeIndex, liveTalent.index or talentIndex)
      tree.talents[#tree.talents + 1] = {
        talentId = syntheticTalentId,
        key = "live_" .. string.lower(tostring(classToken)) .. "_" .. tostring(treeIndex) .. "_" .. tostring(liveTalent.index or talentIndex),
        name = liveTalent.name or ("Talent " .. tostring(talentIndex)),
        row = liveTalent.row or 1,
        col = liveTalent.col or 1,
        maxRank = liveTalent.maxRank or 1,
        icon = liveTalent.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        spellIds = {},
        ranks = {},
        liveIndex = liveTalent.index or talentIndex,
      }
    end

    for talentIndex, liveTalent in ipairs(liveTree.talents or {}) do
      if liveTalent.prereq and liveTalent.prereq.row and liveTalent.prereq.col then
        local targetTalent = tree.talents[talentIndex]
        local sourceTalent = findTalentByPosition(tree, liveTalent.prereq.row, liveTalent.prereq.col)
        if targetTalent and sourceTalent then
          targetTalent.requires = {
            {
              talentId = sourceTalent.talentId,
              requiredRank = sourceTalent.maxRank or 1,
              rawRank = sourceTalent.maxRank or 1,
            },
          }
        end
      end
    end

    classData.trees[#classData.trees + 1] = tree
  end

  return classData
end


function NTP:CaptureStaticTalentData()
  if self.staticTalentClasses or not NTP_TalentData or not NTP_TalentData.classes then
    return
  end

  self.staticTalentClasses = {}
  for classToken, classData in pairs(NTP_TalentData.classes) do
    self.staticTalentClasses[classToken] = classData
  end
end

function NTP:RestoreStaticTalentData()
  if not self.staticTalentClasses or not NTP_TalentData or not NTP_TalentData.classes then
    return
  end

  for classToken, classData in pairs(self.staticTalentClasses) do
    NTP_TalentData.classes[classToken] = classData
  end
end

function NTP:ApplyLiveDumpsToTalentData()
  if not NTP_TalentData or not NTP_TalentData.classes then
    return 0
  end

  self:EnsureDB()
  self:CaptureStaticTalentData()
  self:RestoreStaticTalentData()

  self.liveDumpsApplied = 0

  if not NerdyTalentPlannerDB.settings.useLiveDumps then
    return 0
  end

  local liveDumps = NerdyTalentPlannerDB and NerdyTalentPlannerDB.liveDumps
  if not liveDumps then
    return 0
  end

  local appliedCount = 0
  for classToken, dump in pairs(liveDumps) do
    local classData = self:CreateClassDataFromLiveDump(classToken, dump)
    if classData and classData.trees and #(classData.trees) > 0 then
      NTP_TalentData.classes[classToken] = classData
      appliedCount = appliedCount + 1
    end
  end

  self.liveDumpsApplied = appliedCount
  return appliedCount
end

local function trim(value)
  return string.gsub(value or "", "^%s*(.-)%s*$", "%1")
end

function NTP:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffNTP:|r " .. tostring(message))
  end
end

function NTP:EnsureDB()
  NerdyTalentPlannerDB = NerdyTalentPlannerDB or {}
  NerdyTalentPlannerDB.version = NerdyTalentPlannerDB.version or 1
  NerdyTalentPlannerDB.scratch = NerdyTalentPlannerDB.scratch or {}
  NerdyTalentPlannerDB.settings = NerdyTalentPlannerDB.settings or {}
  NerdyTalentPlannerDB.savedBuilds = NerdyTalentPlannerDB.savedBuilds or {}
  NerdyTalentPlannerDB.savedBuildCounter = NerdyTalentPlannerDB.savedBuildCounter or 0

  if NerdyTalentPlannerDB.settings.maxPoints == nil or NerdyTalentPlannerDB.settings.maxPoints == 71 then
    NerdyTalentPlannerDB.settings.maxPoints = self.config.maxPoints
  end

  NerdyTalentPlannerDB.settings.launcher = NerdyTalentPlannerDB.settings.launcher or {}
  if NerdyTalentPlannerDB.settings.launcher.hidden == nil then
    NerdyTalentPlannerDB.settings.launcher.hidden = false
  end

  if NerdyTalentPlannerDB.settings.useLiveDumps == nil then
    NerdyTalentPlannerDB.settings.useLiveDumps = false
  end
end

function NTP:ToggleMainFrame()
  if not self.CreateMainFrame then
    self:Print("UI module is not loaded. Enable Lua errors and reload the UI to see the failing file.")
    return
  end

  local frame = self:CreateMainFrame()

  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end

function NTP:PrintWarnings()
  if not self.index and self.BuildIndex then
    self:BuildIndex()
  end

  if not self.index or not self.index.warnings or #(self.index.warnings) == 0 then
    self:Print("No talent data warnings.")
    return
  end

  for _, warning in ipairs(self.index.warnings) do
    self:Print(warning)
  end
end

function NTP:PrintDebugState()
  local classCount = 0
  local talentCount = 0

  if self.index and self.index.classes then
    for _, classData in pairs(self.index.classes) do
      classCount = classCount + 1
      for _, tree in ipairs(classData.trees or {}) do
        talentCount = talentCount + #(tree.talents or {})
      end
    end
  end

  self:Print("Version: " .. tostring(self.version))
  self:Print("Data table: " .. tostring(NTP_TalentData ~= nil))
  self:Print("Indexed classes: " .. tostring(classCount))
  self:Print("Indexed talents: " .. tostring(talentCount))
  self:Print("UI module: " .. tostring(self.CreateMainFrame ~= nil))
  self:Print("Launcher module: " .. tostring(self.CreateLauncherButton ~= nil))
  self:Print("Live dump module: " .. tostring(self.DumpLiveTalents ~= nil and self.CheckLiveTalents ~= nil))
  self:Print("Chat link module: " .. tostring(self.PrintBuildLinkTest ~= nil and self.InitializeChatLinks ~= nil))
  self:Print("Use live dump overrides: " .. tostring(NerdyTalentPlannerDB and NerdyTalentPlannerDB.settings and NerdyTalentPlannerDB.settings.useLiveDumps or false))
  self:Print("Live dump overrides applied: " .. tostring(self.liveDumpsApplied or 0))
end

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

  if self.ApplyLiveDumpsToTalentData then
    self:ApplyLiveDumpsToTalentData()
  end

  if self.BuildIndex then
    self:BuildIndex()
  end

  if self.frame and self.frame:IsShown() then
    self:RenderClass(self.frame, classToken)
  end

  self:Print("The live dump is now used for " .. tostring(classToken) .. " in this session.")
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


function NTP:RebuildAndRenderSelectedClass()
  if self.BuildIndex then
    self:BuildIndex()
  end

  if self.frame and self.frame:IsShown() then
    self:RenderClass(self.frame, self.frame.selectedClassToken)
  end
end

function NTP:SetLiveDumpOverrideUsage(enabled)
  self:EnsureDB()
  NerdyTalentPlannerDB.settings.useLiveDumps = enabled and true or false
  self:RebuildAndRenderSelectedClass()

  if NerdyTalentPlannerDB.settings.useLiveDumps then
    self:Print("Live dump overrides enabled. Static generated data is still kept as fallback.")
  else
    self:Print("Static generated data enabled. Existing live dumps are ignored, not deleted.")
  end
end

function NTP:ClearLiveDumps(target)
  self:EnsureDB()
  NerdyTalentPlannerDB.liveDumps = NerdyTalentPlannerDB.liveDumps or {}

  local normalizedTarget = string.upper(tostring(target or ""))
  if normalizedTarget == "" then
    normalizedTarget = self:GetPlayerClassToken() or ""
  end

  if normalizedTarget == "ALL" then
    NerdyTalentPlannerDB.liveDumps = {}
    self:Print("All live dumps cleared.")
  elseif normalizedTarget ~= "" then
    NerdyTalentPlannerDB.liveDumps[normalizedTarget] = nil
    self:Print("Live dump cleared for " .. tostring(normalizedTarget) .. ".")
  else
    self:Print("No class selected for live dump cleanup.")
  end

  self:RebuildAndRenderSelectedClass()
end

function NTP:HandleSlashCommand(message)
  local rawCommand = trim(message)
  local command = string.lower(rawCommand)

  local maxPointsValue = string.match(command, "^maxpoints%s+(%d+)$")
  if maxPointsValue then
    self:EnsureDB()
    NerdyTalentPlannerDB.settings.maxPoints = tonumber(maxPointsValue)
    self:Print("Max talent points set to " .. tostring(NerdyTalentPlannerDB.settings.maxPoints) .. ".")

    if self.frame and self.frame:IsShown() then
      self:RenderClass(self.frame, self.frame.selectedClassToken)
    end

    return
  end

  if command == "" or command == "toggle" or command == "show" then
    self:ToggleMainFrame()
    return
  end

  if command == "hide" then
    if self.frame then
      self.frame:Hide()
    end
    return
  end


  if command == "import" then
    if self.ShowImport then
      self:ShowImport()
    else
      self:Print("UI module is not loaded.")
    end
    return
  end

  if command == "export" then
    if self.ShowExport and self.frame then
      self:ShowExport(self.frame.selectedClassToken)
    else
      self:Print("Open the planner first, then export the current build.")
    end
    return
  end

  if command == "builds" or command == "saved" then
    if self.ShowSavedBuilds then
      self:ShowSavedBuilds()
    else
      self:Print("UI module is not loaded.")
    end
    return
  end

  if command == "warnings" then
    self:PrintWarnings()
    return
  end

  if command == "debug" then
    self:PrintDebugState()
    return
  end

  if command == "resetpos" then
    self:ResetLauncherPosition()
    return
  end

  if command == "livedump" then
    if self.DumpLiveTalents then
      self:DumpLiveTalents()
    else
      self:Print("Live dump module is not loaded.")
    end
    return
  end

  if command == "livecheck" then
    if self.CheckLiveTalents then
      self:CheckLiveTalents()
    else
      self:Print("Live dump module is not loaded.")
    end
    return
  end

  if command == "uselive" then
    self:SetLiveDumpOverrideUsage(true)
    return
  end

  if command == "usestatic" then
    self:SetLiveDumpOverrideUsage(false)
    return
  end

  if command == "source" or command == "datasource" then
    self:EnsureDB()
    self:Print("Data source: " .. (NerdyTalentPlannerDB.settings.useLiveDumps and "live dump overrides" or "static generated files"))
    return
  end

  local linkTestTarget = string.match(command, "^linktest%s*(.*)$")
  if linkTestTarget ~= nil then
    if self.PrintBuildLinkTest then
      self:PrintBuildLinkTest(trim(linkTestTarget))
    else
      self:Print("Chat link module is not loaded.")
    end
    return
  end

  local clearTarget = string.match(command, "^clearlivedump%s*(.*)$") or string.match(command, "^clearlivedumps%s*(.*)$")
  if clearTarget ~= nil then
    self:ClearLiveDumps(trim(clearTarget))
    return
  end

  self:Print("Commands: /ntp, /ntp import, /ntp export, /ntp builds, /ntp warnings, /ntp debug, /ntp resetpos, /ntp maxpoints 61, /ntp linktest [export], /ntp livedump, /ntp livecheck, /ntp usestatic, /ntp uselive, /ntp source, /ntp clearlivedump [CLASS|all]")
end

function NTP:RegisterSlashCommands()
  SLASH_NTP1 = "/ntp"
  SLASH_NTP2 = "/talentplanner"
  SLASH_NTP3 = "/nerdytalentplanner"
  SLASH_NTP4 = "/nerdytalents"

  SlashCmdList["NTP"] = function(message)
    NTP:HandleSlashCommand(message)
  end

  self.slashCommandsRegistered = true
end



if not NTP.chatLinksEmbedded then
NTP.chatLinksEmbedded = true
local BUILD_LINK_PREFIX = "ntpbuild:"
local BUILD_LINK_PREFIX_LENGTH = string.len(BUILD_LINK_PREFIX)

local COMPACT_CLASS_TOKENS = {
  W = "WARRIOR",
  P = "PALADIN",
  H = "HUNTER",
  R = "ROGUE",
  I = "PRIEST",
  S = "SHAMAN",
  M = "MAGE",
  L = "WARLOCK",
  D = "DRUID",
}

local CHAT_LINK_EVENTS = {
  "CHAT_MSG_SAY",
  "CHAT_MSG_YELL",
  "CHAT_MSG_EMOTE",
  "CHAT_MSG_TEXT_EMOTE",
  "CHAT_MSG_WHISPER",
  "CHAT_MSG_WHISPER_INFORM",
  "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER",
  "CHAT_MSG_RAID",
  "CHAT_MSG_RAID_LEADER",
  "CHAT_MSG_RAID_WARNING",
  "CHAT_MSG_INSTANCE_CHAT",
  "CHAT_MSG_INSTANCE_CHAT_LEADER",
  "CHAT_MSG_GUILD",
  "CHAT_MSG_OFFICER",
  "CHAT_MSG_CHANNEL",
  "CHAT_MSG_BN_WHISPER",
  "CHAT_MSG_BN_WHISPER_INFORM",
  "CHAT_MSG_BN_CONVERSATION",
  "CHAT_MSG_BATTLEGROUND",
  "CHAT_MSG_BATTLEGROUND_LEADER",
}

local function extractBuildClassToken(exportString)
  local classPart = string.match(tostring(exportString or ""), "^NTP4:([^:]+):")
  if not classPart or classPart == "" then
    return nil
  end

  return COMPACT_CLASS_TOKENS[classPart] or classPart
end

local function getBuildLinkText(exportString)
  local classToken = extractBuildClassToken(exportString)
  local className = classToken and NTP.classDisplayNames and NTP.classDisplayNames[classToken] or nil

  if className and className ~= "" then
    return "NTP Build: " .. tostring(className)
  end

  return "NTP Build"
end

local function normalizeExportString(value)
  return tostring(value or "")
end

local function escapeChatPayload(value)
  value = tostring(value or "")
  value = string.gsub(value, "|", "")
  value = string.gsub(value, "[\r\n]", "")
  return value
end

function NTP:CreateBuildHyperlink(exportString)
  local value = escapeChatPayload(normalizeExportString(exportString))
  if value == "" then
    return value
  end

  return "|cff66ccff|H" .. BUILD_LINK_PREFIX .. value .. "|h[" .. getBuildLinkText(value) .. "]|h|r"
end

function NTP:LinkifyChatMessage(message)
  if type(message) ~= "string" or message == "" then
    return message
  end

  if string.find(message, "|H" .. BUILD_LINK_PREFIX, 1, true) then
    return message
  end

  return string.gsub(message, "(NTP4:[^%s:]+:[^%s|]+)", function(exportString)
    exportString = string.gsub(exportString, "[%.%,%;%:%!%?%)%]%}]$", "")
    return NTP:CreateBuildHyperlink(exportString)
  end)
end

function NTP:OpenBuildImportLink(exportString)
  local value = normalizeExportString(exportString)
  if value == "" then
    self:Print("Empty build link.")
    return
  end

  local build, reason = self:ImportBuild(value)
  local status
  if build then
    status = "Build link detected: " .. tostring(self.classDisplayNames[build.classToken] or build.classToken) .. ". Click Import to load it."
  else
    status = reason or "Invalid build link."
  end

  if self.ShowImport then
    self:ShowImport(value, status)
  else
    self:Print(status)
  end
end

function NTP:InstallBuildLinkHandler()
  if self.buildLinkHandlerInstalled then
    return
  end

  if type(SetItemRef) ~= "function" then
    return
  end

  local originalSetItemRef = SetItemRef
  SetItemRef = function(link, text, button, chatFrame)
    if type(link) == "string" and string.sub(link, 1, BUILD_LINK_PREFIX_LENGTH) == BUILD_LINK_PREFIX then
      local exportString = string.sub(link, BUILD_LINK_PREFIX_LENGTH + 1)

      if IsShiftKeyDown and IsShiftKeyDown() and ChatEdit_InsertLink then
        ChatEdit_InsertLink(exportString)
        return
      end

      NTP:OpenBuildImportLink(exportString)
      return
    end

    return originalSetItemRef(link, text, button, chatFrame)
  end

  self.buildLinkHandlerInstalled = true
end

local function wrapChatFrame(chatFrame)
  if not chatFrame or chatFrame.NTPBuildLinksWrapped or type(chatFrame.AddMessage) ~= "function" then
    return
  end

  chatFrame.NTPBuildLinksWrapped = true
  chatFrame.NTPOriginalAddMessage = chatFrame.AddMessage

  chatFrame.AddMessage = function(selfFrame, message, ...)
    if NTP and NTP.LinkifyChatMessage then
      message = NTP:LinkifyChatMessage(message)
    end

    return selfFrame:NTPOriginalAddMessage(message, ...)
  end
end

local function installChatFrameWrappers()
  local windowCount = NUM_CHAT_WINDOWS or 10
  for index = 1, windowCount do
    wrapChatFrame(_G["ChatFrame" .. tostring(index)])
  end

  if DEFAULT_CHAT_FRAME then
    wrapChatFrame(DEFAULT_CHAT_FRAME)
  end
end

local function chatMessageEventFilter(self, event, message, ...)
  if NTP and NTP.LinkifyChatMessage then
    message = NTP:LinkifyChatMessage(message)
  end

  return false, message, ...
end

function NTP:InstallBuildChatEventFilters()
  if self.buildChatEventFiltersInstalled then
    return
  end

  if type(ChatFrame_AddMessageEventFilter) ~= "function" then
    return
  end

  for _, eventName in ipairs(CHAT_LINK_EVENTS) do
    ChatFrame_AddMessageEventFilter(eventName, chatMessageEventFilter)
  end

  self.buildChatEventFiltersInstalled = true
end

function NTP:InstallBuildChatLinking()
  if self.buildChatLinkingInstalled then
    return
  end

  installChatFrameWrappers()
  self:InstallBuildChatEventFilters()

  if not self.buildChatLinkRefreshFrame and CreateFrame then
    local refreshFrame = CreateFrame("Frame")
    refreshFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
    refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    refreshFrame:SetScript("OnEvent", function()
      installChatFrameWrappers()
      if NTP and NTP.InstallBuildChatEventFilters then
        NTP:InstallBuildChatEventFilters()
      end
    end)
    self.buildChatLinkRefreshFrame = refreshFrame
  end

  self.buildChatLinkingInstalled = true
end

function NTP:PrintBuildLinkTest(exportString)
  local value = exportString
  if not value or value == "" then
    value = "NTP4:H:M0G30f286WH34E145GIHP60QHy74WY898d2WAW"
  end

  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("NTP link test: " .. value)
  else
    self:Print("NTP link test: " .. value)
  end
end

function NTP:InitializeChatLinks()
  self:InstallBuildLinkHandler()
  self:InstallBuildChatLinking()
end

end

function NTP:Initialize()
  self:RegisterSlashCommands()
  self:EnsureDB()

  if self.BuildIndex then
    self:BuildIndex()
  end

  if self.CreateLauncherButton then
    self:CreateLauncherButton()
  end

  if self.InitializeChatLinks then
    self:InitializeChatLinks()
  end
end

NTP:RegisterSlashCommands()

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, addonName)
  if event == "ADDON_LOADED" and addonName == "NerdyTalentPlanner" then
    NTP:Initialize()
  elseif event == "PLAYER_LOGIN" then
    NTP:RegisterSlashCommands()

    if NTP.CreateLauncherButton then
      NTP:CreateLauncherButton()
    end

    if NTP.InitializeChatLinks then
      NTP:InitializeChatLinks()
    end
  end
end)
