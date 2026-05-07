local NTP = NerdyTalentPlanner

local BUTTON_SIZE = 36

local function getLauncherSettings()
  NTP:EnsureDB()
  NerdyTalentPlannerDB.settings.launcher = NerdyTalentPlannerDB.settings.launcher or {}
  return NerdyTalentPlannerDB.settings.launcher
end

local function applyLauncherPosition(button)
  local settings = getLauncherSettings()

  button:ClearAllPoints()

  if settings.point then
    button:SetPoint(settings.point, UIParent, settings.relativePoint or settings.point, settings.x or 0, settings.y or 0)
  else
    button:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -120, -95)
  end
end

local function saveLauncherPosition(button)
  local settings = getLauncherSettings()
  local point, _, relativePoint, x, y = button:GetPoint(1)

  settings.point = point or "TOPRIGHT"
  settings.relativePoint = relativePoint or settings.point
  settings.x = x or -120
  settings.y = y or -95
end

function NTP:CreateLauncherButton()
  if self.launcherButton then
    applyLauncherPosition(self.launcherButton)
    self.launcherButton:Show()
    return self.launcherButton
  end

  local button = CreateFrame("Button", "NerdyTalentPlannerLauncherButton", UIParent)
  button:SetWidth(BUTTON_SIZE)
  button:SetHeight(BUTTON_SIZE)
  button:SetFrameStrata("FULLSCREEN_DIALOG")
  if button.SetToplevel then
    button:SetToplevel(true)
  end
  if button.SetFrameLevel then
    button:SetFrameLevel(90)
  end
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  if button.SetClampedToScreen then
    button:SetClampedToScreen(true)
  end

  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetPoint("TOPLEFT", 5, -5)
  button.icon:SetPoint("BOTTOMRIGHT", -5, 5)
  button.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")

  button.border = button:CreateTexture(nil, "OVERLAY")
  button.border:SetAllPoints(button)
  button.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")

  button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
  button.highlight:SetAllPoints(button.icon)
  button.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  button.highlight:SetBlendMode("ADD")

  button:SetScript("OnDragStart", function(selfButton)
    selfButton.isDragging = true
    selfButton:StartMoving()
  end)

  button:SetScript("OnDragStop", function(selfButton)
    selfButton:StopMovingOrSizing()
    saveLauncherPosition(selfButton)
    selfButton.isDragging = false
  end)

  button:SetScript("OnShow", function(selfButton)
    selfButton:SetFrameStrata("FULLSCREEN_DIALOG")
    if selfButton.SetFrameLevel then
      selfButton:SetFrameLevel(90)
    end
  end)

  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
      NTP:Print("Drag this button with left mouse button. Use /ntp resetpos to restore its default position.")
      return
    end

    NTP:ToggleMainFrame()
  end)

  button:SetScript("OnEnter", function(selfButton)
    GameTooltip:SetOwner(selfButton, "ANCHOR_LEFT")
    GameTooltip:AddLine("Nerdy Talent Planner", 1, 1, 1)
    GameTooltip:AddLine("Left click: open planner", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: move button", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right click: help", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  self.launcherButton = button
  applyLauncherPosition(button)
  button:Show()

  return button
end

function NTP:ResetLauncherPosition()
  local settings = getLauncherSettings()
  settings.point = nil
  settings.relativePoint = nil
  settings.x = nil
  settings.y = nil

  if self.launcherButton then
    applyLauncherPosition(self.launcherButton)
  end

  self:Print("Launcher position reset.")
end
