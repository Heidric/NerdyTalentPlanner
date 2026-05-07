local NTP = NerdyTalentPlanner

function NTP:BuildIndex()
  self.index = {
    classes = {},
    talentsById = {},
    warnings = {},
  }

  if not NTP_TalentData or not NTP_TalentData.classes then
    self:Print("Talent data is missing.")
    return
  end

  if self.ApplyLiveDumpsToTalentData then
    self:ApplyLiveDumpsToTalentData()
  end

  for classToken, classData in pairs(NTP_TalentData.classes) do
    self.index.classes[classToken] = classData

    for treeIndex, tree in ipairs(classData.trees or {}) do
      tree.classToken = classToken
      tree.treeIndex = treeIndex
      tree.talentsById = {}

      for talentIndex, talent in ipairs(tree.talents or {}) do
        talent.classToken = classToken
        talent.treeIndex = treeIndex
        talent.talentIndex = talentIndex
        talent.tree = tree
        talent.validRequires = {}

        tree.talentsById[talent.talentId] = talent
        self.index.talentsById[talent.talentId] = talent
      end
    end
  end

  for classToken, classData in pairs(NTP_TalentData.classes) do
    for _, tree in ipairs(classData.trees or {}) do
      for _, talent in ipairs(tree.talents or {}) do
        for _, requirement in ipairs(talent.requires or {}) do
          local target = tree.talentsById[requirement.talentId]
          if target then
            table.insert(talent.validRequires, requirement)
          else
            table.insert(self.index.warnings, classToken .. "/" .. tree.name .. "/" .. talent.name .. " references missing prerequisite talentId=" .. tostring(requirement.talentId))
          end
        end
      end
    end
  end

  if #(self.index.warnings) > 0 then
    self:Print("Loaded talent data with " .. tostring(#(self.index.warnings)) .. " warning(s). Use /ntp warnings to inspect them.")
  end
end

function NTP:GetClassData(classToken)
  if not self.index then
    self:BuildIndex()
  end

  return self.index and self.index.classes[classToken]
end

function NTP:GetTalentById(talentId)
  if not self.index then
    self:BuildIndex()
  end

  return self.index and self.index.talentsById[talentId]
end

function NTP:GetClassOrder()
  if NTP_TalentData and NTP_TalentData.classOrder then
    return NTP_TalentData.classOrder
  end

  return {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
end
