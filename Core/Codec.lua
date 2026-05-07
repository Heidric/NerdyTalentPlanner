local NTP = NerdyTalentPlanner

local COMPACT_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local COMPACT_CLASS_CODES = {
  WARRIOR = "W",
  PALADIN = "P",
  HUNTER = "H",
  ROGUE = "R",
  PRIEST = "I",
  SHAMAN = "S",
  MAGE = "M",
  WARLOCK = "L",
  DRUID = "D",
}
local COMPACT_CLASS_TOKENS = {}
local COMPACT_TALENTS_PER_TREE = 40

for classToken, code in pairs(COMPACT_CLASS_CODES) do
  COMPACT_CLASS_TOKENS[code] = classToken
end

local function splitPreserveEmpty(input, separator)
  local result = {}
  local value = tostring(input or "")
  local sep = separator or ":"
  local start = 1

  while true do
    local index = string.find(value, sep, start, true)
    if not index then
      table.insert(result, string.sub(value, start))
      break
    end

    table.insert(result, string.sub(value, start, index - 1))
    start = index + string.len(sep)
  end

  return result
end

local function split(input, separator)
  local result = {}
  local value = tostring(input or "")

  if value == "" then
    return result
  end

  local pattern = "([^" .. separator .. "]+)"
  for item in string.gmatch(value, pattern) do
    table.insert(result, item)
  end

  return result
end

local function getRankKey(talentId)
  return tostring(talentId)
end

local function countOrderRanks(order)
  local counts = {}

  for _, entry in ipairs(order or {}) do
    local key = getRankKey(entry.talentId)
    counts[key] = (counts[key] or 0) + 1
  end

  return counts
end

local function ranksMatchOrder(ranks, order)
  local counts = countOrderRanks(order)

  for talentId, rank in pairs(ranks or {}) do
    if (counts[getRankKey(talentId)] or 0) ~= rank then
      return false
    end
  end

  for talentId, count in pairs(counts) do
    if (ranks[getRankKey(talentId)] or 0) ~= count then
      return false
    end
  end

  return true
end

local function getAlphabetIndexMap()
  if NTP.compactAlphabetIndex then
    return NTP.compactAlphabetIndex
  end

  local index = {}
  for i = 1, string.len(COMPACT_ALPHABET) do
    index[string.sub(COMPACT_ALPHABET, i, i)] = i - 1
  end

  NTP.compactAlphabetIndex = index
  return index
end

local function encodeCompactBytes(bytes)
  local output = {}
  local buffer = 0
  local bits = 0

  for _, byte in ipairs(bytes or {}) do
    buffer = (buffer * 256) + byte
    bits = bits + 8

    while bits >= 6 do
      local shift = bits - 6
      local divisor = 2 ^ shift
      local value = math.floor(buffer / divisor)
      buffer = buffer - (value * divisor)
      bits = bits - 6
      table.insert(output, string.sub(COMPACT_ALPHABET, value + 1, value + 1))
    end
  end

  if bits > 0 then
    local value = buffer * (2 ^ (6 - bits))
    table.insert(output, string.sub(COMPACT_ALPHABET, value + 1, value + 1))
  end

  return table.concat(output)
end

local function decodeCompactBytes(payload)
  local index = getAlphabetIndexMap()
  local bytes = {}
  local buffer = 0
  local bits = 0

  for i = 1, string.len(payload or "") do
    local char = string.sub(payload, i, i)
    local value = index[char]
    if value == nil then
      return nil, "Invalid compact export character: " .. tostring(char)
    end

    buffer = (buffer * 64) + value
    bits = bits + 6

    while bits >= 8 do
      local shift = bits - 8
      local divisor = 2 ^ shift
      local byte = math.floor(buffer / divisor)
      buffer = buffer - (byte * divisor)
      bits = bits - 8
      table.insert(bytes, byte)
    end
  end

  return bytes
end

local function encodeFixedWidthValues(values, width)
  local output = {}
  local buffer = 0
  local bits = 0
  local base = 2 ^ width

  for _, value in ipairs(values or {}) do
    buffer = (buffer * base) + value
    bits = bits + width

    while bits >= 6 do
      local shift = bits - 6
      local divisor = 2 ^ shift
      local encoded = math.floor(buffer / divisor)
      buffer = buffer - (encoded * divisor)
      bits = bits - 6
      table.insert(output, string.sub(COMPACT_ALPHABET, encoded + 1, encoded + 1))
    end
  end

  if bits > 0 then
    local encoded = buffer * (2 ^ (6 - bits))
    table.insert(output, string.sub(COMPACT_ALPHABET, encoded + 1, encoded + 1))
  end

  return table.concat(output)
end

local function decodeFixedWidthValues(payload, width, count)
  local index = getAlphabetIndexMap()
  local values = {}
  local buffer = 0
  local bits = 0
  local base = 2 ^ width

  for i = 1, string.len(payload or "") do
    local char = string.sub(payload, i, i)
    local value = index[char]
    if value == nil then
      return nil, "Invalid compact export character: " .. tostring(char)
    end

    buffer = (buffer * 64) + value
    bits = bits + 6

    while bits >= width and #values < count do
      local shift = bits - width
      local divisor = 2 ^ shift
      local decoded = math.floor(buffer / divisor)
      buffer = buffer - (decoded * divisor)
      bits = bits - width
      if decoded < 0 or decoded >= base then
        return nil, "Invalid compact value."
      end
      table.insert(values, decoded)
    end
  end

  if #values ~= count then
    return nil, "Compact export ended early."
  end

  return values
end

local function getCompactRunCountChar(count)
  if count < 0 or count > 63 then
    return nil
  end

  return string.sub(COMPACT_ALPHABET, count + 1, count + 1)
end

local function decodeCompactRunCountChar(char)
  local index = getAlphabetIndexMap()
  return index[char]
end

local function encodeTalentReference(talent)
  if not talent or not talent.treeIndex or not talent.talentIndex then
    return nil
  end

  local value = ((talent.treeIndex - 1) * COMPACT_TALENTS_PER_TREE) + talent.talentIndex
  if value < 1 or value > 255 then
    return nil
  end

  return value
end

local function decodeTalentReference(classData, value)
  if not classData or not value or value < 1 then
    return nil
  end

  local treeIndex = math.floor((value - 1) / COMPACT_TALENTS_PER_TREE) + 1
  local talentIndex = ((value - 1) % COMPACT_TALENTS_PER_TREE) + 1
  local tree = classData.trees and classData.trees[treeIndex]

  if not tree or not tree.talents then
    return nil
  end

  return tree.talents[talentIndex]
end

local function getExportOrder(self, build)
  local classData = self:GetClassData(build.classToken)
  local order = build.order or {}

  if not ranksMatchOrder(build.ranks, order) then
    order = self:BuildOrderFromRanks(classData, build.ranks)
  end

  return order
end

local function buildCompactTalentOrdinalMap(classData)
  local byTalentId = {}
  local byOrdinal = {}
  local ordinal = 0

  for _, tree in ipairs((classData and classData.trees) or {}) do
    for _, talent in ipairs(tree.talents or {}) do
      ordinal = ordinal + 1
      byTalentId[getRankKey(talent.talentId)] = ordinal
      byOrdinal[ordinal] = talent
    end
  end

  return byTalentId, byOrdinal, ordinal
end

local function exportNTP4(self, build)
  if not build or not build.classToken then
    return "NTP4::"
  end

  local classData = self:GetClassData(build.classToken)
  local byTalentId = buildCompactTalentOrdinalMap(classData)
  local classCode = COMPACT_CLASS_CODES[build.classToken] or build.classToken
  local order = getExportOrder(self, build)
  local runs = {}

  for _, entry in ipairs(order or {}) do
    local ordinal = byTalentId[getRankKey(entry.talentId)]
    if ordinal then
      local lastRun = runs[#runs]
      if lastRun and lastRun.ordinal == ordinal and lastRun.count < 8 then
        lastRun.count = lastRun.count + 1
      else
        table.insert(runs, { ordinal = ordinal, count = 1 })
      end
    end
  end

  if #runs > 63 then
    return nil
  end

  local values = {}
  for _, run in ipairs(runs) do
    if run.ordinal < 1 or run.ordinal > 127 then
      return nil
    end
    table.insert(values, ((run.ordinal - 1) * 8) + (run.count - 1))
  end

  local countChar = getCompactRunCountChar(#runs)
  if not countChar then
    return nil
  end

  return table.concat({"NTP4", classCode, countChar .. encodeFixedWidthValues(values, 10)}, ":")
end

function NTP:BuildOrderFromRanks(classData, ranks)
  local order = {}

  for _, tree in ipairs((classData and classData.trees) or {}) do
    for _, talent in ipairs(tree.talents or {}) do
      local rank = ranks[getRankKey(talent.talentId)] or 0
      for point = 1, rank do
        table.insert(order, {
          talentId = talent.talentId,
          rank = point,
        })
      end
    end
  end

  return order
end

function NTP:ExportBuild(build)
  local exported = exportNTP4(self, build)

  if exported then
    return exported
  end

  return "NTP4::"
end

local function importNTP4(self, parts)
  local classToken = COMPACT_CLASS_TOKENS[parts[2] or ""] or parts[2]
  local classData = self:GetClassData(classToken)

  if not classData then
    return nil, "Unknown class token."
  end

  local payload = parts[3] or ""
  if payload == "" then
    return { classToken = classToken, ranks = {}, order = {} }
  end

  local runCount = decodeCompactRunCountChar(string.sub(payload, 1, 1))
  if runCount == nil then
    return nil, "Invalid compact run count."
  end

  local values, decodeReason = decodeFixedWidthValues(string.sub(payload, 2), 10, runCount)
  if not values then
    return nil, decodeReason or "Invalid compact export string."
  end

  local _, byOrdinal = buildCompactTalentOrdinalMap(classData)
  local build = {
    classToken = classToken,
    ranks = {},
    order = {},
  }

  for _, value in ipairs(values) do
    local ordinal = math.floor(value / 8) + 1
    local count = (value % 8) + 1
    local talent = byOrdinal[ordinal]

    if not talent then
      return nil, "Invalid compact talent reference."
    end

    local key = getRankKey(talent.talentId)
    for _ = 1, count do
      build.ranks[key] = (build.ranks[key] or 0) + 1
      table.insert(build.order, {
        talentId = talent.talentId,
        rank = build.ranks[key],
      })
    end
  end

  local valid, reason = self:ValidateRanksForClass(classData, build.ranks)
  if not valid then
    return nil, reason
  end

  return build
end

function NTP:ImportBuild(importString)
  local parts = splitPreserveEmpty(importString, ":")
  local format = parts[1]

  if format ~= "NTP4" then
    return nil, "Unsupported build format. Use NTP4."
  end

  return importNTP4(self, parts)
end
