local NTP = NerdyTalentPlanner

local TALENT_BUTTON_SIZE = 32
local TALENT_X_STEP = 63
local TALENT_Y_STEP = 63
local TALENT_START_X = 35
local TALENT_START_Y = -20
local TREE_WIDTH = 336
local TREE_HEIGHT = 700
local TREE_GAP = 12
local CLASS_PANEL_WIDTH = 160
local PLAN_ICON_COUNT = 80
local PLAN_ICON_SIZE = 26
local PLAN_CELL_WIDTH = 36
local PLAN_CELL_HEIGHT = 34
local SAVED_VISIBLE_ROWS = 12
local DEPENDENCY_LINE_SIZE = 32

local TREE_BACKGROUNDS = {
  WARRIOR = {
    Arms = "WarriorArms",
    Fury = "WarriorFury",
    Protection = "WarriorProtection",
  },
  PALADIN = {
    Holy = "PaladinHoly",
    Protection = "PaladinProtection",
    Retribution = "PaladinCombat",
  },
  HUNTER = {
    ["Beast Mastery"] = "HunterBeastMastery",
    Marksmanship = "HunterMarksmanship",
    Survival = "HunterSurvival",
  },
  ROGUE = {
    Assassination = "RogueAssassination",
    Combat = "RogueCombat",
    Subtlety = "RogueSubtlety",
  },
  PRIEST = {
    Discipline = "PriestDiscipline",
    Holy = "PriestHoly",
    Shadow = "PriestShadow",
  },
  SHAMAN = {
    Elemental = "ShamanElementalCombat",
    Enhancement = "ShamanEnhancement",
    Restoration = "ShamanRestoration",
  },
  MAGE = {
    Arcane = "MageArcane",
    Fire = "MageFire",
    Frost = "MageFrost",
  },
  WARLOCK = {
    Affliction = "WarlockCurses",
    Demonology = "WarlockSummoning",
    Destruction = "WarlockDestruction",
  },
  DRUID = {
    Balance = "DruidBalance",
    ["Feral Combat"] = "DruidFeralCombat",
    Restoration = "DruidRestoration",
  },
}

local function createText(parent, layer, font, text)
  local value = parent:CreateFontString(nil, layer or "OVERLAY", font or "GameFontNormal")
  value:SetText(text or "")
  return value
end

local function setBackdrop(frame)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
end

local function setInsetBackdrop(frame)
  frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.72)
end

local function getInitialClassToken()
  local _, classToken = UnitClass("player")

  if classToken and NTP:GetClassData(classToken) then
    return classToken
  end

  return "WARRIOR"
end

local function getTalentTopLeft(talent)
  local x = TALENT_START_X + ((talent.col - 1) * TALENT_X_STEP)
  local y = TALENT_START_Y - ((talent.row - 1) * TALENT_Y_STEP)
  return x, y
end

local function getTalentTopCenter(talent)
  local x, y = getTalentTopLeft(talent)
  return x + (TALENT_BUTTON_SIZE / 2), y
end

local function getTalentBottomCenter(talent)
  local x, y = getTalentTopLeft(talent)
  return x + (TALENT_BUTTON_SIZE / 2), y - TALENT_BUTTON_SIZE
end

local BRANCH_TEXTURE_SIZE = 32
local MAX_TALENT_ROWS = 15
local TALENT_COLUMNS = 4

local TALENT_BRANCH_TEXTURECOORDS = {
  up = {
    [1] = {0.12890625, 0.25390625, 0, 0.484375},
    [-1] = {0.12890625, 0.25390625, 0.515625, 1.0},
  },
  down = {
    [1] = {0, 0.125, 0, 0.484375},
    [-1] = {0, 0.125, 0.515625, 1.0},
  },
  left = {
    [1] = {0.2578125, 0.3828125, 0, 0.5},
    [-1] = {0.2578125, 0.3828125, 0.5, 1.0},
  },
  right = {
    [1] = {0.2578125, 0.3828125, 0, 0.5},
    [-1] = {0.2578125, 0.3828125, 0.5, 1.0},
  },
  topright = {
    [1] = {0.515625, 0.640625, 0, 0.5},
    [-1] = {0.515625, 0.640625, 0.5, 1.0},
  },
  topleft = {
    [1] = {0.640625, 0.515625, 0, 0.5},
    [-1] = {0.640625, 0.515625, 0.5, 1.0},
  },
  bottomright = {
    [1] = {0.38671875, 0.51171875, 0, 0.5},
    [-1] = {0.38671875, 0.51171875, 0.5, 1.0},
  },
  bottomleft = {
    [1] = {0.51171875, 0.38671875, 0, 0.5},
    [-1] = {0.51171875, 0.38671875, 0.5, 1.0},
  },
  tdown = {
    [1] = {0.64453125, 0.76953125, 0, 0.5},
    [-1] = {0.64453125, 0.76953125, 0.5, 1.0},
  },
  tup = {
    [1] = {0.7734375, 0.8984375, 0, 0.5},
    [-1] = {0.7734375, 0.8984375, 0.5, 1.0},
  },
}

local TALENT_ARROW_TEXTURECOORDS = {
  top = {
    [1] = {0, 0.5, 0, 0.5},
    [-1] = {0, 0.5, 0.5, 1.0},
  },
  right = {
    [1] = {1.0, 0.5, 0, 0.5},
    [-1] = {1.0, 0.5, 0.5, 1.0},
  },
  left = {
    [1] = {0.5, 1.0, 0, 0.5},
    [-1] = {0.5, 1.0, 0.5, 1.0},
  },
}

local function resetDependencyTextureCursor(treeFrame)
  treeFrame.branchTextureCursor = 0
  treeFrame.arrowTextureCursor = 0

  if treeFrame.branchTextures then
    for _, texture in ipairs(treeFrame.branchTextures) do
      texture:Hide()
    end
  end

  if treeFrame.arrowTextures then
    for _, texture in ipairs(treeFrame.arrowTextures) do
      texture:Hide()
    end
  end
end

local function hideUnusedDependencyTextures(treeFrame)
  if treeFrame.branchTextures then
    for index = (treeFrame.branchTextureCursor or 0) + 1, #(treeFrame.branchTextures) do
      treeFrame.branchTextures[index]:Hide()
    end
  end

  if treeFrame.arrowTextures then
    for index = (treeFrame.arrowTextureCursor or 0) + 1, #(treeFrame.arrowTextures) do
      treeFrame.arrowTextures[index]:Hide()
    end
  end
end

local function acquireBranchTexture(treeFrame)
  treeFrame.branchTextures = treeFrame.branchTextures or {}
  treeFrame.branchTextureCursor = (treeFrame.branchTextureCursor or 0) + 1

  local texture = treeFrame.branchTextures[treeFrame.branchTextureCursor]
  if not texture then
    texture = treeFrame.branchFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetTexture("Interface\\TalentFrame\\UI-TalentBranches")
    texture:SetWidth(BRANCH_TEXTURE_SIZE)
    texture:SetHeight(BRANCH_TEXTURE_SIZE)
    treeFrame.branchTextures[treeFrame.branchTextureCursor] = texture
  end

  texture:ClearAllPoints()
  texture:SetTexture("Interface\\TalentFrame\\UI-TalentBranches")
  texture:SetWidth(BRANCH_TEXTURE_SIZE)
  texture:SetHeight(BRANCH_TEXTURE_SIZE)
  texture:SetVertexColor(1, 1, 1, 1)
  texture:Show()
  return texture
end

local function acquireArrowTexture(treeFrame)
  treeFrame.arrowTextures = treeFrame.arrowTextures or {}
  treeFrame.arrowTextureCursor = (treeFrame.arrowTextureCursor or 0) + 1

  local texture = treeFrame.arrowTextures[treeFrame.arrowTextureCursor]
  if not texture then
    texture = treeFrame.arrowFrame:CreateTexture(nil, "OVERLAY")
    texture:SetTexture("Interface\\TalentFrame\\UI-TalentArrows")
    texture:SetWidth(BRANCH_TEXTURE_SIZE)
    texture:SetHeight(BRANCH_TEXTURE_SIZE)
    treeFrame.arrowTextures[treeFrame.arrowTextureCursor] = texture
  end

  texture:ClearAllPoints()
  texture:SetTexture("Interface\\TalentFrame\\UI-TalentArrows")
  texture:SetWidth(BRANCH_TEXTURE_SIZE)
  texture:SetHeight(BRANCH_TEXTURE_SIZE)
  texture:SetVertexColor(1, 1, 1, 1)
  texture:Show()
  return texture
end

local function setBranchTexture(treeFrame, texCoords, xOffset, yOffset)
  local texture = acquireBranchTexture(treeFrame)
  texture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
  texture:SetPoint("TOPLEFT", treeFrame.branchFrame, "TOPLEFT", xOffset, yOffset)
end

local function setArrowTexture(treeFrame, texCoords, xOffset, yOffset)
  local texture = acquireArrowTexture(treeFrame)
  texture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
  texture:SetPoint("TOPLEFT", treeFrame.arrowFrame, "TOPLEFT", xOffset, yOffset)
end

local function resetBranchArray(treeFrame)
  treeFrame.branchArray = treeFrame.branchArray or {}

  for row = 1, MAX_TALENT_ROWS do
    treeFrame.branchArray[row] = treeFrame.branchArray[row] or {}
    for col = 1, TALENT_COLUMNS do
      treeFrame.branchArray[row][col] = treeFrame.branchArray[row][col] or {}
      local node = treeFrame.branchArray[row][col]
      node.id = nil
      node.up = 0
      node.down = 0
      node.left = 0
      node.right = 0
      node.leftArrow = 0
      node.rightArrow = 0
      node.topArrow = 0
    end
  end
end

local function drawBranchPath(treeFrame, buttonTier, buttonColumn, prereqTier, prereqColumn, requirementsMet)
  local nodes = treeFrame.branchArray

  if not nodes or not nodes[buttonTier] or not nodes[prereqTier] then
    return
  end

  if buttonColumn == prereqColumn then
    if (buttonTier - prereqTier) > 1 then
      for row = prereqTier + 1, buttonTier - 1 do
        if nodes[row][buttonColumn].id then
          return
        end
      end
    end

    for row = prereqTier, buttonTier - 1 do
      nodes[row][buttonColumn].down = requirementsMet
      if (row + 1) <= (buttonTier - 1) then
        nodes[row + 1][buttonColumn].up = requirementsMet
      end
    end

    nodes[buttonTier][buttonColumn].topArrow = requirementsMet
    return
  end

  if buttonTier == prereqTier then
    local left = math.min(buttonColumn, prereqColumn)
    local right = math.max(buttonColumn, prereqColumn)

    if (right - left) > 1 then
      for col = left + 1, right - 1 do
        if nodes[buttonTier][col].id then
          return
        end
      end
    end

    for col = left, right - 1 do
      nodes[buttonTier][col].right = requirementsMet
      nodes[buttonTier][col + 1].left = requirementsMet
    end

    if buttonColumn < prereqColumn then
      nodes[buttonTier][buttonColumn].rightArrow = requirementsMet
    else
      nodes[buttonTier][buttonColumn].leftArrow = requirementsMet
    end
    return
  end

  local left = math.min(buttonColumn, prereqColumn)
  local right = math.max(buttonColumn, prereqColumn)
  if left == prereqColumn then
    left = left + 1
  else
    right = right - 1
  end

  local blocked = false
  for col = left, right do
    if nodes[prereqTier][col].id then
      blocked = true
      break
    end
  end

  left = math.min(buttonColumn, prereqColumn)
  right = math.max(buttonColumn, prereqColumn)
  if not blocked then
    nodes[prereqTier][buttonColumn].down = requirementsMet
    nodes[buttonTier][buttonColumn].up = requirementsMet

    for row = prereqTier, buttonTier - 1 do
      nodes[row][buttonColumn].down = requirementsMet
      nodes[row + 1][buttonColumn].up = requirementsMet
    end

    for col = left, right - 1 do
      nodes[prereqTier][col].right = requirementsMet
      nodes[prereqTier][col + 1].left = requirementsMet
    end

    nodes[buttonTier][buttonColumn].topArrow = requirementsMet
    return
  end

  if left == buttonColumn then
    left = left + 1
  else
    right = right - 1
  end

  for col = left, right do
    if nodes[buttonTier][col].id then
      return
    end
  end

  left = math.min(buttonColumn, prereqColumn)
  right = math.max(buttonColumn, prereqColumn)
  for row = prereqTier, buttonTier - 1 do
    nodes[row][prereqColumn].up = requirementsMet
    nodes[row + 1][prereqColumn].down = requirementsMet
  end

  if buttonColumn < prereqColumn then
    nodes[buttonTier][buttonColumn].rightArrow = requirementsMet
  else
    nodes[buttonTier][buttonColumn].leftArrow = requirementsMet
  end
end

local function renderBranchArray(treeFrame)
  local ignoreUp

  for row = 1, MAX_TALENT_ROWS do
    for col = 1, TALENT_COLUMNS do
      local node = treeFrame.branchArray[row][col]
      local xOffset = ((col - 1) * TALENT_X_STEP) + TALENT_START_X + 2
      local yOffset = -((row - 1) * TALENT_Y_STEP) + TALENT_START_Y - 2

      if node.id then
        if node.up ~= 0 then
          if not ignoreUp then
            setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.up[node.up], xOffset, yOffset + TALENT_BUTTON_SIZE)
          else
            ignoreUp = nil
          end
        end
        if node.down ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.down[node.down], xOffset, yOffset - TALENT_BUTTON_SIZE + 1)
        end
        if node.left ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.left[node.left], xOffset - TALENT_BUTTON_SIZE, yOffset)
        end
        if node.right ~= 0 then
          local tempNode = treeFrame.branchArray[row][col + 1]
          if tempNode and tempNode.left ~= 0 and tempNode.down < 0 then
            setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.right[tempNode.down], xOffset + TALENT_BUTTON_SIZE, yOffset)
          else
            setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.right[node.right], xOffset + TALENT_BUTTON_SIZE + 1, yOffset)
          end
        end

        if node.rightArrow ~= 0 then
          setArrowTexture(treeFrame, TALENT_ARROW_TEXTURECOORDS.right[node.rightArrow], xOffset + (TALENT_BUTTON_SIZE / 2) + 5, yOffset)
        end
        if node.leftArrow ~= 0 then
          setArrowTexture(treeFrame, TALENT_ARROW_TEXTURECOORDS.left[node.leftArrow], xOffset - (TALENT_BUTTON_SIZE / 2) - 5, yOffset)
        end
        if node.topArrow ~= 0 then
          setArrowTexture(treeFrame, TALENT_ARROW_TEXTURECOORDS.top[node.topArrow], xOffset, yOffset + (TALENT_BUTTON_SIZE / 2) + 5)
        end
      else
        if node.up ~= 0 and node.left ~= 0 and node.right ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.tup[node.up], xOffset, yOffset)
        elseif node.down ~= 0 and node.left ~= 0 and node.right ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.tdown[node.down], xOffset, yOffset)
        elseif node.left ~= 0 and node.down ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.topright[node.left], xOffset, yOffset)
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.down[node.down], xOffset, yOffset - 32)
        elseif node.left ~= 0 and node.up ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.bottomright[node.left], xOffset, yOffset)
        elseif node.left ~= 0 and node.right ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.right[node.right], xOffset + TALENT_BUTTON_SIZE, yOffset)
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.left[node.left], xOffset + 1, yOffset)
        elseif node.right ~= 0 and node.down ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.topleft[node.right], xOffset, yOffset)
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.down[node.down], xOffset, yOffset - 32)
        elseif node.right ~= 0 and node.up ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.bottomleft[node.right], xOffset, yOffset)
        elseif node.up ~= 0 and node.down ~= 0 then
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.up[node.up], xOffset, yOffset)
          setBranchTexture(treeFrame, TALENT_BRANCH_TEXTURECOORDS.down[node.down], xOffset, yOffset - 32)
          ignoreUp = true
        end
      end
    end
  end
end

local function drawDependencies(treeFrame, tree, build)
  resetDependencyTextureCursor(treeFrame)
  resetBranchArray(treeFrame)

  for _, talent in ipairs((tree and tree.talents) or {}) do
    if talent.row and talent.col and treeFrame.branchArray[talent.row] and treeFrame.branchArray[talent.row][talent.col] then
      treeFrame.branchArray[talent.row][talent.col].id = talent.talentId
    end
  end

  for _, talent in ipairs((tree and tree.talents) or {}) do
    for _, requirement in ipairs(talent.validRequires or {}) do
      local sourceTalent = tree.talentsById and tree.talentsById[requirement.talentId]
      if sourceTalent and sourceTalent.row and sourceTalent.col and talent.row and talent.col then
        local sourceRank = NTP:GetRank(build, sourceTalent.talentId)
        local requiredRank = requirement.requiredRank or 1
        local requirementsMet = sourceRank >= requiredRank and 1 or -1
        drawBranchPath(treeFrame, talent.row, talent.col, sourceTalent.row, sourceTalent.col, requirementsMet)
      end
    end
  end

  renderBranchArray(treeFrame)
  hideUnusedDependencyTextures(treeFrame)
end

local function resolveTreeBackground(classToken, tree)
  if tree and tree.background and tree.background ~= "" and tree.background ~= "String not found" then
    return tree.background
  end

  local classBackgrounds = TREE_BACKGROUNDS[classToken]
  if classBackgrounds and tree and tree.name then
    return classBackgrounds[tree.name]
  end

  return nil
end

local function setTreeBackground(treeFrame, classToken, tree)
  local background = resolveTreeBackground(classToken, tree)
  local textures = treeFrame.backgroundTextures

  if background and treeFrame.customBackground then
    for _, texture in ipairs(textures) do
      texture:Hide()
    end

    treeFrame.customBackground:SetTexture("Interface\\AddOns\\NerdyTalentPlanner\\Media\\Backgrounds\\" .. background)
    treeFrame.customBackground:SetVertexColor(1, 1, 1, 1)
    treeFrame.customBackground:Show()
    return
  end

  if treeFrame.customBackground then
    treeFrame.customBackground:Hide()
  end

  for _, texture in ipairs(textures) do
    texture:Show()
  end

  local contentWidth = treeFrame.contentFrame:GetWidth()
  local contentHeight = treeFrame.contentFrame:GetHeight()

  if not contentWidth or contentWidth <= 0 then
    contentWidth = TREE_WIDTH - 36
  end
  if not contentHeight or contentHeight <= 0 then
    contentHeight = TREE_HEIGHT - 114
  end

  local leftWidth = 256
  local rightWidth = contentWidth - leftWidth
  if rightWidth < 1 then
    rightWidth = 44
    leftWidth = contentWidth - rightWidth
  end

  local topHeight = 256
  local bottomHeight = contentHeight - topHeight
  if bottomHeight < 1 then
    bottomHeight = 75
    topHeight = contentHeight - bottomHeight
  end

  textures[1]:SetWidth(leftWidth)
  textures[1]:SetHeight(topHeight)
  textures[2]:SetWidth(rightWidth)
  textures[2]:SetHeight(topHeight)
  textures[3]:SetWidth(leftWidth)
  textures[3]:SetHeight(bottomHeight)
  textures[4]:SetWidth(rightWidth)
  textures[4]:SetHeight(bottomHeight)

  textures[1]:SetTexCoord(0, 1, 0, 1)
  textures[2]:SetTexCoord(0, 0.6875, 0, 1)
  textures[3]:SetTexCoord(0, 1, 0, 0.5859375)
  textures[4]:SetTexCoord(0, 0.6875, 0, 0.5859375)

  if not background then
    for _, texture in ipairs(textures) do
      texture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
      texture:SetVertexColor(0.05, 0.05, 0.05, 0.85)
    end
    return
  end

  textures[1]:SetTexture("Interface\\TalentFrame\\" .. background .. "-TopLeft")
  textures[2]:SetTexture("Interface\\TalentFrame\\" .. background .. "-TopRight")
  textures[3]:SetTexture("Interface\\TalentFrame\\" .. background .. "-BottomLeft")
  textures[4]:SetTexture("Interface\\TalentFrame\\" .. background .. "-BottomRight")

  for _, texture in ipairs(textures) do
    texture:SetVertexColor(1, 1, 1, 1)
  end
end

local function createEditBox(parent, width, height)
  local editBox = CreateFrame("EditBox", nil, parent)
  editBox:SetWidth(width)
  editBox:SetHeight(height)
  editBox:SetAutoFocus(false)
  editBox:EnableMouse(true)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetTextInsets(8, 8, 0, 0)
  if editBox.SetMultiLine then
    editBox:SetMultiLine(false)
  end
  if parent and parent.GetFrameLevel and editBox.SetFrameLevel then
    editBox:SetFrameLevel(parent:GetFrameLevel() + 8)
  end
  setInsetBackdrop(editBox)
  editBox:SetScript("OnMouseDown", function(selfEditBox)
    selfEditBox:SetFocus()
  end)
  editBox:SetScript("OnEnterPressed", function(selfEditBox)
    selfEditBox:ClearFocus()
  end)
  editBox:SetScript("OnEscapePressed", function(selfEditBox)
    selfEditBox:ClearFocus()
  end)
  return editBox
end

local function getBuildDisplayName(build)
  if not build then
    return ""
  end

  return build.name or ((NTP.classDisplayNames and NTP.classDisplayNames[build.classToken]) or build.classToken or "Build")
end

local function registerEscCloseFrame(frameName)
  if not frameName then
    return
  end

  UISpecialFrames = UISpecialFrames or {}
  for _, registeredName in ipairs(UISpecialFrames) do
    if registeredName == frameName then
      return
    end
  end

  table.insert(UISpecialFrames, frameName)
end

local function raisePlannerFrame(frame)
  if not frame then
    return
  end

  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  if frame.SetToplevel then
    frame:SetToplevel(true)
  end
  if frame.SetFrameLevel then
    frame:SetFrameLevel(10)
  end
  if frame.Raise then
    frame:Raise()
  end
end

local function raiseSubWindowFrame(frame)
  if not frame then
    return
  end

  NerdyTalentPlanner.popupLevelCounter = (NerdyTalentPlanner.popupLevelCounter or 0) + 1
  if NerdyTalentPlanner.popupLevelCounter > 20 then
    NerdyTalentPlanner.popupLevelCounter = 1
  end

  frame:SetFrameStrata("TOOLTIP")
  if frame.SetToplevel then
    frame:SetToplevel(true)
  end
  if frame.SetFrameLevel then
    frame:SetFrameLevel(20 + NerdyTalentPlanner.popupLevelCounter)
  end
  if frame.EnableMouse then
    frame:EnableMouse(true)
  end
  if frame.Raise then
    frame:Raise()
  end
end

local function raiseDialogControl(control, level)
  if not control then
    return
  end
  if control.SetFrameStrata then
    control:SetFrameStrata("TOOLTIP")
  end
  if control.SetFrameLevel and level then
    control:SetFrameLevel(level)
  end
  if control.EnableMouse then
    control:EnableMouse(true)
  end
  if control.Enable then
    control:Enable()
  end
  if control.RegisterForClicks then
    control:RegisterForClicks("LeftButtonUp")
  end
end

local function raiseDialogControls(frame)
  if not frame or not frame.GetFrameLevel then
    return
  end

  local baseLevel = frame:GetFrameLevel()

  local controls = {
    frame.editBox,
    frame.nameEditBox,
    frame.apply,
    frame.cancel,
    frame.close,
    frame.saveCurrent,
    frame.load,
    frame.rename,
    frame.export,
    frame.delete,
    frame.prev,
    frame.next,
  }

  if frame.listPanel then
    table.insert(controls, frame.listPanel)
  end
  if frame.rows then
    for _, row in ipairs(frame.rows) do
      table.insert(controls, row)
    end
  end

  for index, control in ipairs(controls) do
    raiseDialogControl(control, baseLevel + 5 + index)
  end
end

local function focusAndSelectEditBox(editBox)
  if not editBox then
    return
  end

  if editBox.SetFrameStrata then
    editBox:SetFrameStrata("TOOLTIP")
  end
  if editBox.GetParent and editBox.SetFrameLevel then
    local parent = editBox:GetParent()
    if parent and parent.GetFrameLevel then
      editBox:SetFrameLevel(parent:GetFrameLevel() + 8)
    end
  end
  editBox:EnableMouse(true)
  editBox:SetFocus()
  editBox:HighlightText()
end

function NTP:CreateMainFrame()
  if self.frame then
    return self.frame
  end

  local frame = CreateFrame("Frame", "NerdyTalentPlannerFrame", UIParent)
  registerEscCloseFrame("NerdyTalentPlannerFrame")
  frame:SetWidth(1260)
  frame:SetHeight(920)
  frame:SetPoint("CENTER")
  raisePlannerFrame(frame)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetScript("OnShow", function(selfFrame)
    raisePlannerFrame(selfFrame)
  end)
  frame:Hide()
  setBackdrop(frame)

  frame.title = createText(frame, "OVERLAY", "GameFontNormalLarge", "Nerdy Talent Planner")
  frame.title:SetPoint("TOP", 0, -18)

  frame.pointsText = createText(frame, "OVERLAY", "GameFontHighlight", "")
  frame.pointsText:SetPoint("TOPRIGHT", -48, -22)

  frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  frame.close:SetPoint("TOPRIGHT", -6, -6)

  frame.classButtons = {}
  frame.treeFrames = {}
  frame.orderRows = {}
  frame.selectedClassToken = getInitialClassToken()

  local classPanel = CreateFrame("Frame", nil, frame)
  classPanel:SetWidth(CLASS_PANEL_WIDTH)
  classPanel:SetHeight(830)
  classPanel:SetPoint("TOPLEFT", 18, -58)
  setBackdrop(classPanel)

  local classTitle = createText(classPanel, "OVERLAY", "GameFontNormal", "Class")
  classTitle:SetPoint("TOP", 0, -14)

  local previousButton
  for _, classToken in ipairs(self:GetClassOrder()) do
    local button = CreateFrame("Button", nil, classPanel, "UIPanelButtonTemplate")
    button:SetWidth(124)
    button:SetHeight(24)

    if previousButton then
      button:SetPoint("TOP", previousButton, "BOTTOM", 0, -6)
    else
      button:SetPoint("TOP", classTitle, "BOTTOM", 0, -14)
    end

    button:SetText(self.classDisplayNames[classToken] or classToken)
    button.classToken = classToken
    button:SetScript("OnClick", function(clickedButton)
      frame.selectedClassToken = clickedButton.classToken
      NTP:RenderClass(frame, clickedButton.classToken)
    end)

    frame.classButtons[classToken] = button
    previousButton = button
  end

  frame.reset = CreateFrame("Button", nil, classPanel, "UIPanelButtonTemplate")
  frame.reset:SetWidth(124)
  frame.reset:SetHeight(24)
  frame.reset:SetPoint("BOTTOM", 0, 130)
  frame.reset:SetText("Reset")
  frame.reset:SetScript("OnClick", function()
    NTP:ResetBuild(frame.selectedClassToken)
    NTP:RenderClass(frame, frame.selectedClassToken)
  end)

  frame.import = CreateFrame("Button", nil, classPanel, "UIPanelButtonTemplate")
  frame.import:SetWidth(124)
  frame.import:SetHeight(24)
  frame.import:SetPoint("BOTTOM", 0, 102)
  frame.import:SetText("Import")
  frame.import:SetScript("OnClick", function()
    NTP:ShowImport()
  end)

  frame.export = CreateFrame("Button", nil, classPanel, "UIPanelButtonTemplate")
  frame.export:SetWidth(124)
  frame.export:SetHeight(24)
  frame.export:SetPoint("BOTTOM", 0, 74)
  frame.export:SetText("Export")
  frame.export:SetScript("OnClick", function()
    NTP:ShowExport(frame.selectedClassToken)
  end)

  frame.builds = CreateFrame("Button", nil, classPanel, "UIPanelButtonTemplate")
  frame.builds:SetWidth(124)
  frame.builds:SetHeight(24)
  frame.builds:SetPoint("BOTTOM", 0, 46)
  frame.builds:SetText("Builds")
  frame.builds:SetScript("OnClick", function()
    NTP:ShowSavedBuilds()
  end)

  frame.save = CreateFrame("Button", nil, classPanel, "UIPanelButtonTemplate")
  frame.save:SetWidth(124)
  frame.save:SetHeight(24)
  frame.save:SetPoint("BOTTOM", 0, 18)
  frame.save:SetText("Save")
  frame.save:SetScript("OnClick", function()
    local savedBuild = NTP:SaveScratchBuild(frame.selectedClassToken)
    NTP:Print("Saved build: " .. tostring(savedBuild.name))
    if NTP.savedBuildsFrame and NTP.savedBuildsFrame:IsShown() then
      NTP:RefreshSavedBuildsFrame()
    end
  end)

  local treesPanel = CreateFrame("Frame", nil, frame)
  treesPanel:SetWidth((TREE_WIDTH * 3) + (TREE_GAP * 2))
  treesPanel:SetHeight(TREE_HEIGHT)
  treesPanel:SetPoint("TOPLEFT", classPanel, "TOPRIGHT", 12, 0)
  frame.treesPanel = treesPanel

  local planPanel = CreateFrame("Frame", nil, frame)
  planPanel:SetWidth((TREE_WIDTH * 3) + (TREE_GAP * 2))
  planPanel:SetHeight(138)
  planPanel:SetPoint("TOPLEFT", treesPanel, "BOTTOMLEFT", 0, -8)
  setBackdrop(planPanel)
  frame.orderPanel = planPanel

  frame.orderTitle = createText(planPanel, "OVERLAY", "GameFontNormal", "Plan")
  frame.orderTitle:SetPoint("TOPLEFT", 14, -10)

  frame.orderEmpty = createText(planPanel, "OVERLAY", "GameFontHighlightSmall", "No planned points.")
  frame.orderEmpty:SetPoint("TOPLEFT", 14, -34)

  frame.orderIcons = {}
  local planColumns = math.floor((((TREE_WIDTH * 3) + (TREE_GAP * 2)) - 28) / PLAN_CELL_WIDTH)
  if planColumns < 1 then
    planColumns = 1
  end

  for index = 1, PLAN_ICON_COUNT do
    local item = CreateFrame("Button", nil, planPanel)
    item:SetWidth(PLAN_ICON_SIZE)
    item:SetHeight(PLAN_ICON_SIZE)

    local column = (index - 1) % planColumns
    local row = math.floor((index - 1) / planColumns)
    item:SetPoint("TOPLEFT", 14 + (column * PLAN_CELL_WIDTH), -34 - (row * PLAN_CELL_HEIGHT))

    item.icon = item:CreateTexture(nil, "ARTWORK")
    item.icon:SetAllPoints(item)
    item.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    item.normal = item:CreateTexture(nil, "OVERLAY")
    item.normal:SetTexture("Interface\Buttons\UI-Quickslot2")
    item.normal:SetWidth(50)
    item.normal:SetHeight(50)
    item.normal:SetPoint("CENTER", 0, -1)

    item.levelText = createText(item, "OVERLAY", "NumberFontNormalSmall", "")
    item.levelText:SetPoint("TOPLEFT", -2, 4)

    item.rankText = createText(item, "OVERLAY", "GameFontNormalSmall", "")
    item.rankText:SetPoint("BOTTOMRIGHT", 4, -4)

    item:SetScript("OnEnter", function(selfButton)
      NTP:ShowPlanEntryTooltip(selfButton)
    end)

    item:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    item:Hide()
    frame.orderIcons[index] = item
  end

  for index = 1, 3 do
    local treeFrame = CreateFrame("Frame", "NerdyTalentPlannerTree" .. tostring(index), treesPanel)
    treeFrame:SetWidth(TREE_WIDTH)
    treeFrame:SetHeight(TREE_HEIGHT)
    treeFrame:SetPoint("TOPLEFT", (index - 1) * (TREE_WIDTH + TREE_GAP), 0)
    setBackdrop(treeFrame)

    treeFrame.specIcon = treeFrame:CreateTexture(nil, "ARTWORK")
    treeFrame.specIcon:SetWidth(42)
    treeFrame.specIcon:SetHeight(42)
    treeFrame.specIcon:SetPoint("TOPLEFT", 32, -22)

    treeFrame.title = createText(treeFrame, "OVERLAY", "GameFontNormalLarge", "")
    treeFrame.title:SetPoint("TOP", 0, -26)

    treeFrame.pointsPanel = CreateFrame("Frame", nil, treeFrame)
    treeFrame.pointsPanel:SetWidth(TREE_WIDTH - 46)
    treeFrame.pointsPanel:SetHeight(28)
    treeFrame.pointsPanel:SetPoint("TOP", 0, -58)
    setInsetBackdrop(treeFrame.pointsPanel)

    treeFrame.points = createText(treeFrame.pointsPanel, "OVERLAY", "GameFontHighlightSmall", "")
    treeFrame.points:SetPoint("CENTER", 0, 0)

    treeFrame.contentFrame = CreateFrame("Frame", nil, treeFrame)
    treeFrame.contentFrame:SetPoint("TOPLEFT", 18, -96)
    treeFrame.contentFrame:SetPoint("BOTTOMRIGHT", -18, 18)

    treeFrame.backgroundFrame = treeFrame.contentFrame

    treeFrame.backgroundTextures = {}
    for textureIndex = 1, 4 do
      local texture = treeFrame.contentFrame:CreateTexture(nil, "BACKGROUND")
      treeFrame.backgroundTextures[textureIndex] = texture
    end

    treeFrame.backgroundTextures[1]:SetPoint("TOPLEFT", treeFrame.contentFrame, "TOPLEFT", 0, 0)
    treeFrame.backgroundTextures[2]:SetPoint("TOPLEFT", treeFrame.backgroundTextures[1], "TOPRIGHT", 0, 0)
    treeFrame.backgroundTextures[3]:SetPoint("TOPLEFT", treeFrame.backgroundTextures[1], "BOTTOMLEFT", 0, 0)
    treeFrame.backgroundTextures[4]:SetPoint("TOPLEFT", treeFrame.backgroundTextures[3], "TOPRIGHT", 0, 0)

    treeFrame.customBackground = treeFrame.contentFrame:CreateTexture(nil, "BACKGROUND")
    treeFrame.customBackground:SetAllPoints(treeFrame.contentFrame)
    treeFrame.customBackground:Hide()

    treeFrame.branchFrame = CreateFrame("Frame", nil, treeFrame.contentFrame)
    treeFrame.branchFrame:SetAllPoints(treeFrame.contentFrame)
    treeFrame.branchFrame:SetFrameLevel(treeFrame.contentFrame:GetFrameLevel() + 1)

    treeFrame.arrowFrame = CreateFrame("Frame", nil, treeFrame.contentFrame)
    treeFrame.arrowFrame:SetAllPoints(treeFrame.contentFrame)
    treeFrame.arrowFrame:SetFrameLevel(treeFrame.contentFrame:GetFrameLevel() + 3)

    treeFrame.buttons = {}
    treeFrame.buttonsByTalentId = {}
    frame.treeFrames[index] = treeFrame
  end

  self.frame = frame
  self:RenderClass(frame, frame.selectedClassToken)

  return frame
end

function NTP:IsSilentClickFailure(reason)
  return reason == "Talent is already at maximum rank."
    or reason == "Build already uses the configured point limit."
end

function NTP:CreateTalentButton(parent)
  local button = CreateFrame("Button", nil, parent)
  button:SetWidth(TALENT_BUTTON_SIZE)
  button:SetHeight(TALENT_BUTTON_SIZE)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetFrameLevel(parent:GetFrameLevel() + 2)

  button.slot = button:CreateTexture(nil, "BACKGROUND")
  button.slot:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
  button.slot:SetWidth(64)
  button.slot:SetHeight(64)
  button.slot:SetPoint("CENTER", 0, 0)

  button.icon = button:CreateTexture(nil, "BORDER")
  button.icon:SetAllPoints(button)
  button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  button.normal = button:CreateTexture(nil, "OVERLAY")
  button.normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  button.normal:SetWidth(64)
  button.normal:SetHeight(64)
  button.normal:SetPoint("CENTER", 0, -1)

  button.rankBorder = button:CreateTexture(nil, "OVERLAY")
  button.rankBorder:SetTexture("Interface\\TalentFrame\\TalentFrame-RankBorder")
  button.rankBorder:SetWidth(42)
  button.rankBorder:SetHeight(24)
  button.rankBorder:SetPoint("CENTER", button, "BOTTOMRIGHT", 6, -3)

  button.rank = createText(button, "OVERLAY", "GameFontNormalSmall", "")
  button.rank:SetWidth(38)
  button.rank:SetHeight(12)
  button.rank:SetJustifyH("CENTER")
  button.rank:SetPoint("CENTER", button.rankBorder, "CENTER", 0, 0)

  button:SetScript("OnEnter", function(selfButton)
    NTP:ShowTalentTooltip(selfButton)
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button:SetScript("OnClick", function(selfButton, mouseButton)
    local build = NTP:GetScratchBuild(selfButton.talent.classToken)
    local ok, reason

    if mouseButton == "RightButton" then
      ok, reason = NTP:RemovePoint(build, selfButton.talent)
    else
      ok, reason = NTP:AddPoint(build, selfButton.talent)
    end

    if not ok and not NTP:IsSilentClickFailure(reason) then
      NTP:Print(reason)
    end

    NTP:RenderClass(NTP.frame, selfButton.talent.classToken)
  end)

  return button
end

function NTP:ShowTalentTooltip(button)
  local talent = button.talent
  local build = self:GetScratchBuild(talent.classToken)
  local rank = self:GetRank(build, talent.talentId)
  local nextRank = rank + 1

  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  GameTooltip:AddLine(talent.name, 1, 1, 1)
  GameTooltip:AddLine("Rank " .. tostring(rank) .. "/" .. tostring(talent.maxRank), 0.8, 0.8, 0.8)

  if talent.ranks and talent.ranks[nextRank] then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Next rank", 0.2, 0.8, 1)
    GameTooltip:AddLine(talent.ranks[nextRank].description or "", 1, 0.82, 0, true)
  elseif talent.ranks and talent.ranks[rank] then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(talent.ranks[rank].description or "", 1, 0.82, 0, true)
  end

  local canAdd, reason = self:CanAddPoint(build, talent)
  if not canAdd and rank < talent.maxRank then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(reason, 1, 0.2, 0.2, true)
  end

  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Left click: add point", 0.7, 0.7, 0.7)
  GameTooltip:AddLine("Right click: remove point", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end

function NTP:RefreshOrderPanel(frame, build)
  local order = build and build.order or {}
  local icons = frame.orderIcons or {}

  if frame.orderEmpty then
    if #order == 0 then
      frame.orderEmpty:Show()
    else
      frame.orderEmpty:Hide()
    end
  end

  for index, item in ipairs(icons) do
    local entry = order[index]

    if entry then
      local talent = self:GetTalentById(entry.talentId)
      local level = self:GetPlannedLevelForOrderIndex(index)

      item.entry = entry
      item.talent = talent
      item.orderIndex = index
      item.level = level

      if talent then
        item.icon:SetTexture(talent.icon or "Interface\Icons\INV_Misc_QuestionMark")
        item.rankText:SetText(tostring(entry.rank or "?"))
      else
        item.icon:SetTexture("Interface\Icons\INV_Misc_QuestionMark")
        item.rankText:SetText("?")
      end

      item.levelText:SetText(tostring(level))
      item:Show()
    else
      item.entry = nil
      item.talent = nil
      item.orderIndex = nil
      item.level = nil
      item:Hide()
    end
  end
end

function NTP:ShowPlanEntryTooltip(item)
  if not item or not item.entry then
    return
  end

  local talent = item.talent
  local entry = item.entry
  local level = item.level or self:GetPlannedLevelForOrderIndex(item.orderIndex or 1)

  GameTooltip:SetOwner(item, "ANCHOR_RIGHT")

  if talent then
    GameTooltip:AddLine(tostring(level) .. ": " .. tostring(talent.name), 1, 1, 1)
    if talent.tree and talent.tree.name then
      GameTooltip:AddLine(tostring(talent.tree.name), 1, 0.82, 0)
    end
    GameTooltip:AddLine("Rank " .. tostring(entry.rank or "?") .. "/" .. tostring(talent.maxRank or "?"), 0.7, 0.7, 0.7)

    if entry.rank and talent.ranks and talent.ranks[entry.rank] and talent.ranks[entry.rank].description then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(talent.ranks[entry.rank].description, 1, 0.82, 0, true)
    end
  else
    GameTooltip:AddLine(tostring(level) .. ": Unknown talent", 1, 1, 1)
    GameTooltip:AddLine("Talent ID: " .. tostring(entry.talentId), 0.7, 0.7, 0.7)
  end

  GameTooltip:Show()
end

function NTP:RenderClass(frame, classToken)
  local classData = self:GetClassData(classToken)
  if not classData then
    self:Print("Unknown class: " .. tostring(classToken))
    return
  end

  frame.selectedClassToken = classToken
  local build = self:GetScratchBuild(classToken)

  for token, button in pairs(frame.classButtons) do
    if token == classToken then
      button:LockHighlight()
    else
      button:UnlockHighlight()
    end
  end

  frame.title:SetText("Nerdy Talent Planner - " .. (classData.name or classToken))
  frame.pointsText:SetText("Points: " .. tostring(self:GetTotalPoints(build)) .. "/" .. tostring(NerdyTalentPlannerDB.settings.maxPoints))
  self:RefreshOrderPanel(frame, build)

  for treeIndex, treeFrame in ipairs(frame.treeFrames) do
    local tree = classData.trees[treeIndex]

    for _, button in ipairs(treeFrame.buttons) do
      button:Hide()
    end
    treeFrame.buttonsByTalentId = {}
    resetDependencyTextureCursor(treeFrame)
    hideUnusedDependencyTextures(treeFrame)

    if tree then
      treeFrame.title:SetText(tree.name)
      treeFrame.points:SetText("Points spent in " .. tostring(tree.name) .. " Talents: " .. tostring(self:GetTreePoints(build, tree)))
      treeFrame.specIcon:SetTexture(tree.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      setTreeBackground(treeFrame, classToken, tree)

      for talentIndex, talent in ipairs(tree.talents or {}) do
        local button = treeFrame.buttons[talentIndex]
        if not button then
          button = self:CreateTalentButton(treeFrame.contentFrame)
          treeFrame.buttons[talentIndex] = button
        end

        button.talent = talent
        treeFrame.buttonsByTalentId[talent.talentId] = button

        local x, y = getTalentTopLeft(talent)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", treeFrame.contentFrame, "TOPLEFT", x, y)
        button.icon:SetTexture(talent.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local rank = self:GetRank(build, talent.talentId)
        button.rank:SetText(tostring(rank) .. "/" .. tostring(talent.maxRank))

        local canAdd = self:CanAddPoint(build, talent)
        button.rankBorder:Show()
        button.rank:Show()
        if rank > 0 then
          button.icon:SetVertexColor(1, 1, 1)
          if rank < talent.maxRank then
            button.slot:SetVertexColor(0.1, 1.0, 0.1)
            button.rank:SetTextColor(0.1, 1.0, 0.1)
          else
            button.slot:SetVertexColor(1.0, 0.82, 0)
            button.rank:SetTextColor(1.0, 0.82, 0)
          end
        elseif canAdd then
          button.icon:SetVertexColor(0.85, 0.85, 0.85)
          button.slot:SetVertexColor(0.1, 1.0, 0.1)
          button.rank:SetTextColor(0.1, 1.0, 0.1)
        else
          button.icon:SetVertexColor(0.35, 0.35, 0.35)
          button.slot:SetVertexColor(0.5, 0.5, 0.5)
          button.rank:SetTextColor(0.5, 0.5, 0.5)
        end

        button:Show()
      end

      drawDependencies(treeFrame, tree, build)
    else
      treeFrame.title:SetText("")
      treeFrame.points:SetText("")
      treeFrame.specIcon:SetTexture(nil)
    end
  end
end

function NTP:ShowExportForBuild(build, title)
  local exportString = self:ExportBuild(build)

  if not self.exportFrame then
    local frame = CreateFrame("Frame", "NerdyTalentPlannerExportFrame", UIParent)
    registerEscCloseFrame("NerdyTalentPlannerExportFrame")
    frame:SetWidth(680)
    frame:SetHeight(160)
    frame:SetPoint("CENTER")
    raiseSubWindowFrame(frame)
    frame:SetScript("OnShow", function(selfFrame)
      raiseSubWindowFrame(selfFrame)
      raiseDialogControls(selfFrame)
    end)
    frame:EnableMouse(true)
    setBackdrop(frame)

    frame.title = createText(frame, "OVERLAY", "GameFontNormal", "Export build")
    frame.title:SetPoint("TOP", 0, -18)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -6, -6)

    frame.editBox = createEditBox(frame, 610, 28)
    frame.editBox:SetPoint("TOP", 0, -62)
    frame.editBox:SetScript("OnEscapePressed", function(selfEditBox)
      selfEditBox:ClearFocus()
      frame:Hide()
    end)

    frame.hint = createText(frame, "OVERLAY", "GameFontHighlightSmall", "Copy this NTP4 string. It includes talent order.")
    frame.hint:SetPoint("TOP", frame.editBox, "BOTTOM", 0, -14)

    self.exportFrame = frame
  end

  self.exportFrame.title:SetText(title or "Export build")
  self.exportFrame.editBox:SetText(exportString)
  self.exportFrame:Show()
  raiseSubWindowFrame(self.exportFrame)
  raiseDialogControls(self.exportFrame)
  focusAndSelectEditBox(self.exportFrame.editBox)
end

function NTP:ShowExport(classToken)
  local build = self:GetScratchBuild(classToken)
  self:ShowExportForBuild(build, "Export current build")
end

function NTP:ShowImport(initialString, initialStatus)
  if not self.importFrame then
    local frame = CreateFrame("Frame", "NerdyTalentPlannerImportFrame", UIParent)
    registerEscCloseFrame("NerdyTalentPlannerImportFrame")
    frame:SetWidth(700)
    frame:SetHeight(210)
    frame:SetPoint("CENTER")
    raiseSubWindowFrame(frame)
    frame:SetScript("OnShow", function(selfFrame)
      raiseSubWindowFrame(selfFrame)
      raiseDialogControls(selfFrame)
    end)
    frame:EnableMouse(true)
    setBackdrop(frame)

    frame.title = createText(frame, "OVERLAY", "GameFontNormal", "Import build")
    frame.title:SetPoint("TOP", 0, -18)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -6, -6)

    frame.editBox = createEditBox(frame, 630, 28)
    frame.editBox:SetPoint("TOP", 0, -58)

    frame.status = createText(frame, "OVERLAY", "GameFontHighlightSmall", "Paste an NTP4 export string. It includes talent order.")
    frame.status:SetPoint("TOP", frame.editBox, "BOTTOM", 0, -14)

    frame.apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.apply:SetWidth(120)
    frame.apply:SetHeight(24)
    frame.apply:SetPoint("BOTTOM", -66, 22)
    frame.apply:SetText("Import")
    frame.apply:SetScript("OnClick", function()
      local build, reason = NTP:ImportBuild(frame.editBox:GetText())
      if not build then
        frame.status:SetText(reason or "Import failed.")
        return
      end

      local ok, setReason = NTP:SetScratchBuild(build)
      if not ok then
        frame.status:SetText(setReason or "Import failed.")
        return
      end

      local mainFrame = NTP:CreateMainFrame()
      if mainFrame then
        mainFrame.selectedClassToken = build.classToken
        NTP:RenderClass(mainFrame, build.classToken)
        mainFrame:Show()
        raisePlannerFrame(mainFrame)
      end

      frame:Hide()
      NTP:Print("Imported build for " .. tostring(NTP.classDisplayNames[build.classToken] or build.classToken) .. ".")
    end)

    frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.cancel:SetWidth(120)
    frame.cancel:SetHeight(24)
    frame.cancel:SetPoint("BOTTOM", 66, 22)
    frame.cancel:SetText("Close")
    frame.cancel:SetScript("OnClick", function()
      frame:Hide()
    end)

    self.importFrame = frame
  end

  self.importFrame.editBox:SetText(initialString or "")
  self.importFrame.status:SetText(initialStatus or "Paste an NTP4 export string. It includes talent order.")
  self.importFrame:Show()
  raiseSubWindowFrame(self.importFrame)
  raiseDialogControls(self.importFrame)
  if self.importFrame.editBox then
    self.importFrame.editBox:EnableMouse(true)
    self.importFrame.editBox:SetFocus()
    if initialString and initialString ~= "" then
      self.importFrame.editBox:HighlightText()
    end
  end
end

function NTP:GetSelectedSavedBuild()
  local frame = self.savedBuildsFrame
  if not frame or not frame.selectedBuildId then
    return nil
  end

  return self:GetSavedBuildById(frame.selectedBuildId)
end

function NTP:RefreshSavedBuildsFrame()
  local frame = self.savedBuildsFrame
  if not frame then
    return
  end

  local savedBuilds = self:GetSavedBuilds()
  local page = frame.page or 1
  local maxPage = math.max(1, math.ceil(#savedBuilds / SAVED_VISIBLE_ROWS))

  if page > maxPage then
    page = maxPage
    frame.page = page
  end

  local startIndex = ((page - 1) * SAVED_VISIBLE_ROWS) + 1

  for rowIndex = 1, SAVED_VISIBLE_ROWS do
    local savedBuild = savedBuilds[startIndex + rowIndex - 1]
    local row = frame.rows[rowIndex]

    row.buildId = savedBuild and savedBuild.id or nil
    if savedBuild then
      local className = self.classDisplayNames[savedBuild.classToken] or savedBuild.classToken
      row:SetText(tostring(savedBuild.name or "Build") .. " [" .. tostring(className) .. "]")
      row:Show()
      if savedBuild.id == frame.selectedBuildId then
        row:LockHighlight()
      else
        row:UnlockHighlight()
      end
    else
      row:SetText("")
      row:Hide()
      row:UnlockHighlight()
    end
  end

  frame.pageText:SetText("Page " .. tostring(page) .. "/" .. tostring(maxPage))

  local selected = self:GetSelectedSavedBuild()
  if selected then
    frame.nameEditBox:SetText(getBuildDisplayName(selected))
    frame.details:SetText("Class: " .. tostring(self.classDisplayNames[selected.classToken] or selected.classToken) .. " | Points: " .. tostring(self:GetTotalPoints(selected)))
  else
    frame.nameEditBox:SetText("")
    frame.details:SetText("No build selected.")
  end
end

function NTP:ShowSavedBuilds()
  if not self.savedBuildsFrame then
    local frame = CreateFrame("Frame", "NerdyTalentPlannerSavedBuildsFrame", UIParent)
    registerEscCloseFrame("NerdyTalentPlannerSavedBuildsFrame")
    frame:SetWidth(690)
    frame:SetHeight(455)
    frame:SetPoint("CENTER")
    raiseSubWindowFrame(frame)
    frame:SetScript("OnShow", function(selfFrame)
      raiseSubWindowFrame(selfFrame)
      raiseDialogControls(selfFrame)
    end)
    frame:EnableMouse(true)
    setBackdrop(frame)

    frame.title = createText(frame, "OVERLAY", "GameFontNormalLarge", "Saved Builds")
    frame.title:SetPoint("TOP", 0, -18)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -6, -6)

    frame.rows = {}
    frame.page = 1

    local listPanel = CreateFrame("Frame", nil, frame)
    frame.listPanel = listPanel
    listPanel:EnableMouse(false)
    listPanel:SetWidth(330)
    listPanel:SetHeight(310)
    listPanel:SetPoint("TOPLEFT", 28, -58)
    setInsetBackdrop(listPanel)

    for rowIndex = 1, SAVED_VISIBLE_ROWS do
      local row = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
      row:SetWidth(300)
      row:SetHeight(21)
      row:SetPoint("TOPLEFT", 14, -12 - ((rowIndex - 1) * 23))
      row:SetScript("OnClick", function(selfRow)
        frame.selectedBuildId = selfRow.buildId
        NTP:RefreshSavedBuildsFrame()
      end)
      frame.rows[rowIndex] = row
    end

    frame.prev = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.prev:SetWidth(70)
    frame.prev:SetHeight(24)
    frame.prev:SetPoint("TOPLEFT", listPanel, "BOTTOMLEFT", 8, -10)
    frame.prev:SetText("Prev")
    frame.prev:SetScript("OnClick", function()
      frame.page = math.max(1, (frame.page or 1) - 1)
      NTP:RefreshSavedBuildsFrame()
    end)

    frame.pageText = createText(frame, "OVERLAY", "GameFontHighlightSmall", "Page 1/1")
    frame.pageText:SetPoint("LEFT", frame.prev, "RIGHT", 24, 0)

    frame.next = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.next:SetWidth(70)
    frame.next:SetHeight(24)
    frame.next:SetPoint("TOPRIGHT", listPanel, "BOTTOMRIGHT", -8, -10)
    frame.next:SetText("Next")
    frame.next:SetScript("OnClick", function()
      frame.page = (frame.page or 1) + 1
      NTP:RefreshSavedBuildsFrame()
    end)

    local nameLabel = createText(frame, "OVERLAY", "GameFontNormal", "Name")
    nameLabel:SetPoint("TOPLEFT", 390, -64)

    frame.nameEditBox = createEditBox(frame, 250, 26)
    frame.nameEditBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -8)

    frame.details = createText(frame, "OVERLAY", "GameFontHighlightSmall", "No build selected.")
    frame.details:SetWidth(250)
    frame.details:SetJustifyH("LEFT")
    frame.details:SetPoint("TOPLEFT", frame.nameEditBox, "BOTTOMLEFT", 0, -16)

    frame.saveCurrent = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.saveCurrent:SetWidth(120)
    frame.saveCurrent:SetHeight(24)
    frame.saveCurrent:SetPoint("TOPLEFT", frame.details, "BOTTOMLEFT", 0, -26)
    frame.saveCurrent:SetText("Save Current")
    frame.saveCurrent:SetScript("OnClick", function()
      local name = frame.nameEditBox:GetText()
      local savedBuild = NTP:SaveScratchBuild(NTP.frame and NTP.frame.selectedClassToken or getInitialClassToken(), name)
      frame.selectedBuildId = savedBuild.id
      NTP:RefreshSavedBuildsFrame()
      NTP:Print("Saved build: " .. tostring(savedBuild.name))
    end)

    frame.load = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.load:SetWidth(120)
    frame.load:SetHeight(24)
    frame.load:SetPoint("TOPLEFT", frame.saveCurrent, "BOTTOMLEFT", 0, -10)
    frame.load:SetText("Load")
    frame.load:SetScript("OnClick", function()
      local selected = NTP:GetSelectedSavedBuild()
      if not selected then
        NTP:Print("Select a saved build first.")
        return
      end

      local ok, reason = NTP:LoadSavedBuild(selected.id)
      if not ok then
        NTP:Print(reason)
        return
      end

      if NTP.frame then
        NTP.frame.selectedClassToken = selected.classToken
        NTP:RenderClass(NTP.frame, selected.classToken)
      end

      NTP:Print("Loaded build: " .. tostring(selected.name))
    end)

    frame.rename = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.rename:SetWidth(120)
    frame.rename:SetHeight(24)
    frame.rename:SetPoint("TOPLEFT", frame.load, "BOTTOMLEFT", 0, -10)
    frame.rename:SetText("Rename")
    frame.rename:SetScript("OnClick", function()
      local selected = NTP:GetSelectedSavedBuild()
      if not selected then
        NTP:Print("Select a saved build first.")
        return
      end

      local ok, reason = NTP:RenameSavedBuild(selected.id, frame.nameEditBox:GetText())
      if not ok then
        NTP:Print(reason)
        return
      end

      NTP:RefreshSavedBuildsFrame()
    end)

    frame.export = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.export:SetWidth(120)
    frame.export:SetHeight(24)
    frame.export:SetPoint("TOPLEFT", frame.rename, "BOTTOMLEFT", 0, -10)
    frame.export:SetText("Export")
    frame.export:SetScript("OnClick", function()
      local selected = NTP:GetSelectedSavedBuild()
      if not selected then
        NTP:Print("Select a saved build first.")
        return
      end

      NTP:ShowExportForBuild(selected, "Export saved build")
    end)

    frame.delete = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.delete:SetWidth(120)
    frame.delete:SetHeight(24)
    frame.delete:SetPoint("TOPLEFT", frame.export, "BOTTOMLEFT", 0, -10)
    frame.delete:SetText("Delete")
    frame.delete:SetScript("OnClick", function()
      local selected = NTP:GetSelectedSavedBuild()
      if not selected then
        NTP:Print("Select a saved build first.")
        return
      end

      local ok, reason = NTP:DeleteSavedBuild(selected.id)
      if not ok then
        NTP:Print(reason)
        return
      end

      frame.selectedBuildId = nil
      NTP:RefreshSavedBuildsFrame()
    end)

    self.savedBuildsFrame = frame
  end

  self:RefreshSavedBuildsFrame()
  self.savedBuildsFrame:Show()
  raiseSubWindowFrame(self.savedBuildsFrame)
  raiseDialogControls(self.savedBuildsFrame)
end
