local EventSystem = require('drift-mode/eventsystem')
local ConfigIO = require('drift-mode/configio')
local Assert = require('drift-mode/assert')
local AsyncUtils = require('drift-mode/asynchelper')
require('drift-mode/models')

-- #region Pre-script definitions

---Course currently showing (choosen in combo box)
local loaded_course_info = ConfigIO.getLastUsedTrackConfigInfo() ---@type TrackConfigInfo?
local selected_course_info = ConfigIO.getLastUsedTrackConfigInfo() ---@type TrackConfigInfo?
local course = (loaded_course_info and loaded_course_info:load()) ---@type TrackConfig?

---Currently activated tab
local activeTab = nil

---Event system listener ID
local listener_id = EventSystem.registerListener('app-editor-courses')

local new_clip_points = "1000"

---Cursor
local cursor_data = Cursor.new() ---@type Cursor

local closest_point = nil
local currently_editing = false
local initial_offset = nil
local closest_type = nil
local clip_ref = nil
local clip_start = nil

local is_user_editing = false
local button_global_flags = ui.ButtonFlags.None
local input_global_flags = ui.ButtonFlags.None

---@alias OtherCreatingContext { head_position: Point?, type_creating: string }
local other_creating_context = nil ---@type OtherCreatingContext?

---@alias LineExtendingInfo { zone_idx: integer, line: string, point_group_ref: PointGroup }
local currently_extending = nil ---@type LineExtendingInfo?

local unsaved_changes = false

-- #endregion

-- #region CourseEditor

---@class CourseEditor
local CourseEditor = class('CourseEditor')

function CourseEditor:initialize()
  self.__tabs = {
    { 'Zones',           self.drawUIZones },
    { 'Clipping points', self.drawUIClips },
    { 'Other',           self.drawUIOther },
    { 'Help',            self.drawUIHelp },
  }
end

---Main function drawing app UI
---@param dt integer
function CourseEditor:drawUI(dt)

  if currently_editing or currently_extending or other_creating_context then
    is_user_editing = true
    button_global_flags = ui.ButtonFlags.Disabled
    input_global_flags = ui.InputTextFlags.ReadOnly
  else
    is_user_editing = false
    button_global_flags = ui.ButtonFlags.None
    input_global_flags = ui.InputTextFlags.None
  end

  -- [COMBO] Track config combo box
  local combo_item_name = "<None>"
  ui.setNextItemWidth(ui.availableSpaceX() - 132)
  if selected_course_info then combo_item_name = string.format("[%.1s] %s", selected_course_info.type, selected_course_info.name) end
  ui.combo("##configDropdown", combo_item_name, function()
    for _, cfg in ipairs(ConfigIO.listTrackConfigs()) do
      local label = string.format("%10s %s", "[" .. cfg.type .. "]", cfg.name)
      if ui.selectable(label) then
        selected_course_info = cfg
        self:onSelectedCourseChange(selected_course_info)
      end
    end
  end)

  ui.sameLine(0, 8)
  if ui.button("Reload", vec2(60), button_global_flags) then
    self:onSelectedCourseChange(selected_course_info)
  end
  if ui.itemHovered() then
    ui.setTooltip("Discard any changes made and reload currently selected course.")
  end

  ui.sameLine(0, 4)
  if ui.button("New", vec2(60), button_global_flags) then
    course = TrackConfig.new("NewCourse")
    self:onCourseEdited()
  end
  if ui.itemHovered() then
    ui.setTooltip("This will discard any changes made.")
  end

  if course == nil then
    ui.text("<No course selected>"); return
  end
  course:drawSetup()

  ui.setNextItemWidth(ui.availableSpaceX() - 132)
  course.name = ui.inputText("Course name", course.name, ui.InputTextFlags.Placeholder + input_global_flags)
  if ui.itemHovered() then
    ui.setTooltip("Name of the course")
  end

  ui.sameLine(0, 8)
  if ui.button("Save", vec2(124), button_global_flags) then
    local new_course_info = ConfigIO.saveTrackConfig(course)
    self:onSelectedCourseChange(new_course_info)
  end
  if unsaved_changes then
    ui.notificationCounter()
  end

  if ui.itemHovered() then
    ui.setTooltip("Choose a new name and save to clone current course.\n\
To create a new course clone the current one and choose 'Reset' in 'Other' tab, then save.")
  end

  ui.offsetCursorY(4)

  ui.tabBar('tabs', function()
    for _, v in ipairs(self.__tabs) do
      ui.tabItem(v[1], v[4] and v[4](self) and ui.TabItemFlags.UnsavedDocument, function()
        activeTab = v
        ui.childWindow('#scroll', ui.availableSpace(), function()
          ui.pushItemWidth(ui.availableSpaceX())
          v[2](self, dt)
          ui.popItemWidth()
        end)
      end)
    end
  end)
end

---Called when user selects different course in combo box
---@param new_course TrackConfigInfo
function CourseEditor:onSelectedCourseChange(new_course)
  loaded_course_info = new_course
  course = loaded_course_info:load()
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, course)
  unsaved_changes = false
end

---Called when editor changes the course in any way
---@param new_course TrackConfigInfo
function CourseEditor:onCourseEdited()
  Assert.NotNil(course, "Course was edited but simultaneously was nil")
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, course)
  unsaved_changes = true
end

function CourseEditor:drawUIZones(dt)
  local zones = course.zones
  ui.pushFont(ui.Font.Small)

  ui.offsetCursorY(8)

  local toRemove = nil

  for i = 1, #zones do
    ui.pushID(i)

    ui.pushFont(ui.Font.Main)

    local up_flags = (i == 1 or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.button("↑", vec2(24, 0), up_flags) then
      local tmp_zone = zones[i - 1]
      zones[i - 1] = zones[i]
      zones[i] = tmp_zone
      self:onCourseEdited()
    end

    ui.sameLine(0, 4)
    ui.setNextItemWidth(ui.availableSpaceX() - 32)
    zones[i].name = ui.inputText("Zone #" .. tostring(i), zones[i].name, ui.InputTextFlags.Placeholder + input_global_flags)
    if ui.itemHovered() then
      ui.setTooltip("Zone #" .. tostring(i))
    end

    ui.sameLine(0, 4)
    local down_flags = (i == #zones or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.button("↓", vec2(24, 0), down_flags) then
      local tmp_zone = zones[i + 1]
      zones[i + 1] = zones[i]
      zones[i] = tmp_zone
      self:onCourseEdited()
    end
    ui.popFont()

    ui.pushFont(ui.Font.Monospace)
    ui.setNextItemWidth(42)
    local text, changed = ui.inputText("Points", tostring(zones[i].maxPoints),
      (ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags))
    ui.popFont()

    if ui.itemHovered() then
      ui.setTooltip("Max points")
    end
    if changed then
      if text == "" then
        new_clip_points = "0"
      else
        new_clip_points = tostring(tonumber(text))
      end
      zones[i].maxPoints = tonumber(new_clip_points)
      self:onCourseEdited()
    end

    ui.sameLine(0, 8)
    if ui.button(")  Inner", vec2(60, 0), button_global_flags) then
      currently_extending = {
        zone_idx = i,
        line = "in",
        point_group_ref = zones[i]:getInsideLine()
      }
    end
    if ui.itemHovered() then
      ui.setTooltip("Enable pointer to extend the inner line")
    end

    ui.sameLine(0, 2)
    if ui.button("Outer   )", vec2(60, 0), button_global_flags) then
      currently_extending = {
        zone_idx = i,
        line = "out",
        point_group_ref = zones[i]:getOutsideLine()
      }
    end
    if ui.itemHovered() then
      ui.setTooltip("Enable pointer to extend the outer line")
    end

    ui.sameLine(0, 0)
    ui.offsetCursorX(ui.availableSpaceX() - 64)
    if ui.button("Remove", vec2(60, 0), button_global_flags) then
      toRemove = i
    end

    ui.separator()
    ui.offsetCursorY(8)

    ui.popID()
  end

  ui.popFont()

  if toRemove then
    table.remove(zones, toRemove)
    self:onCourseEdited()
  end

  ui.offsetCursorX((ui.availableSpaceX() - 200) / 2)
  if ui.availableSpaceY() > 0 + 65 then
    ui.offsetCursorY(ui.availableSpaceY() - 65)
  end
  if ui.button("Create new zone", vec2(200, 60), button_global_flags) then
    zones[#zones + 1] = Zone.new(course:getNextZoneName(), nil, nil, tonumber(new_clip_points))
    self:onCourseEdited()
  end

  --[[
  Editor algorithm:

  - Raycast track and save `hit`

  - If not currently editing and not extending:
    - Find closest point of interest (zone, clip, start/finish line, start point) in given radius
    - If `closest_point` found:
      - If     delete modifier and mouse pressed - start editing
      - If not delete modifier and mouse pressed - delete point

  - If currently editing:
    - Set current cursor position to new point value

  - If currently extending:
    - If mouse pressed - append a new point

  ]]
     --

  local hit = AsyncUtils.taskTrackRayHit()
  if not currently_editing and not currently_extending then
    local closest_dist = 1
    closest_point = nil
    if hit then
      for _, zone in ipairs(course.zones) do
        for _, point in zone:getPolygon():iter() do
          local distance = hit:distance(point:value())
          if distance < closest_dist then
            closest_point = point
            closest_dist = distance
          end
        end
      end
    end

    cursor_data.selector = closest_point
    cursor_data.color_selector = rgbm(0, 2, 1, 3)
  end

  if closest_point then
    if ui.keyboardButtonDown(ui.KeyIndex.Control) then
      cursor_data.color_selector = rgbm(3, 0, 0, 3)
      ui.setMouseCursor(ui.MouseCursor.Hand)
      if ui.mouseClicked() then
        for _, zone in ipairs(course.zones) do
          local changed = false
          changed = zone:getInsideLine():delete(closest_point)
          changed = zone:getOutsideLine():delete(closest_point) or changed
          if changed then zone:setDirty() end
        end
        self:onCourseEdited()
        cursor_data.selector = nil
      end
    else
      if ui.mouseClicked() then
        currently_editing = true
        initial_offset = closest_point:value() - hit
      end
    end
  end

  if currently_editing and hit then
    closest_point:set(hit + initial_offset)
    cursor_data.selector = Point.new(hit + initial_offset)
    EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)

    self:onCourseEdited()
    if ui.mouseReleased() then currently_editing = false end
  end

  if currently_extending and hit then
    local hit_point = Point.new(hit)
    cursor_data.selector = hit_point
    if currently_extending.point_group_ref:count() > 0 then
      cursor_data.point_group_b = PointGroup.new({ currently_extending.point_group_ref:last(), hit_point })
    end

    if ui.mouseClicked() then
      currently_extending.point_group_ref:append(hit_point)
      self:onCourseEdited()
    end

    if ui.mouseClicked(ui.MouseButton.Right) then
      cursor_data = Cursor.new()

      -- Set dirty to recalculate polygon
      course.zones[currently_extending.zone_idx]:setDirty()

      currently_extending = nil
    end
  end

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

function CourseEditor:drawUIClips(dt)
  local clips = course.clips
  ui.pushFont(ui.Font.Small)

  ui.offsetCursorY(8)

  local toRemove = nil

  for i = 1, #clips do
    ui.pushID(i)

    ui.pushFont(ui.Font.Main)

    local up_flags = (i == 1 or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.button("↑", vec2(24, 0), up_flags) then
      local tmp_zone = clips[i - 1]
      clips[i - 1] = clips[i]
      clips[i] = tmp_zone
      self:onCourseEdited()
    end

    ui.sameLine(0, 4)
    ui.setNextItemWidth(ui.availableSpaceX() - 32)
    clips[i].name = ui.inputText("Clip #" .. tostring(i), clips[i].name, ui.InputTextFlags.Placeholder + input_global_flags)
    if ui.itemHovered() then
      ui.setTooltip("Clip #" .. tostring(i))
    end

    ui.sameLine(0, 4)
    local down_flags = (i == #clips or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.button("↓", vec2(24, 0), down_flags) then
      local tmp_zone = clips[i + 1]
      clips[i + 1] = clips[i]
      clips[i] = tmp_zone
      self:onCourseEdited()
    end
    ui.popFont()

    ui.pushFont(ui.Font.Monospace)
    ui.setNextItemWidth(42)
    local text, changed = ui.inputText("Points", tostring(clips[i].maxPoints),
      (ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags))
    ui.popFont()

    if ui.itemHovered() then
      ui.setTooltip("Max points")
    end
    if changed then
      if text == "" then
        new_clip_points = "0"
      else
        new_clip_points = tostring(tonumber(text))
      end
      clips[i].maxPoints = tonumber(new_clip_points)
      self:onCourseEdited()
    end

    ui.sameLine(0, 0)
    ui.offsetCursorX(ui.availableSpaceX() - 64)
    if ui.button("Remove", vec2(60, 0), button_global_flags) then
      toRemove = i
    end

    ui.separator()
    ui.offsetCursorY(8)

    ui.popID()
  end

  ui.popFont()

  ui.offsetCursorX((ui.availableSpaceX() - 200) / 2)
  if ui.availableSpaceY() > 0 + 65 then
    ui.offsetCursorY(ui.availableSpaceY() - 65)
  end
  if ui.button("Create new clipping point", vec2(200, 60), button_global_flags) then
    currently_extending = true
    closest_type = 'origin'
  end

  if toRemove then
    table.remove(clips, toRemove)
    self:onCourseEdited()
  end

  local hit = AsyncUtils.taskTrackRayHit()
  if not currently_editing and not currently_extending then
    local closest_dist = 1
    closest_point = nil
    if hit then
      for _, clip in ipairs(course.clips) do
        for idx, point in ipairs({ clip.origin, clip:getEnd() }) do
          local distance = hit:distance(point:value())
          if distance < closest_dist then
            closest_point = point
            closest_dist = distance
            clip_ref = clip
            if idx == 1 then closest_type = 'origin' else closest_type = 'end' end
          end
        end
      end
    end

    cursor_data.selector = closest_point
    cursor_data.color_selector = rgbm(0, 2, 1, 3)
  end

  if closest_point and ui.mouseClicked() then
    currently_editing = true
    initial_offset = closest_point:value() - hit
  end

  if currently_editing and hit then
    cursor_data.selector = Point.new(hit + initial_offset)
    if closest_type == 'origin' then
      closest_point:set(hit + initial_offset)
    else -- == 'end'
      clip_ref:setEnd(Point.new(hit + initial_offset))
    end

    self:onCourseEdited()
    if ui.mouseReleased() then currently_editing = false end
  end


  if currently_extending and hit then
    cursor_data.selector = Point.new(hit)

    if closest_type == 'origin' then
      if ui.mouseClicked() then
        clip_start = Point.new(hit)
        closest_type = 'end'
      end
    else
      cursor_data.point_group_b = PointGroup.new({ clip_start, Point.new(hit) })
      if ui.mouseClicked() then
        course.clips[#course.clips+1] = Clip.new(course:getNextClipName(), clip_start, vec3(0, 0, 0), 0, new_clip_points)
        course.clips[#course.clips]:setEnd(Point.new(hit))
        currently_extending = false
        cursor_data = Cursor.new()
        self:onCourseEdited()
      end
    end

    if ui.mouseClicked(ui.MouseButton.Right) then
      currently_extending = false
      cursor_data = Cursor.new()
    end
  end

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

function CourseEditor:drawUIOther(dt)
  ui.pushFont(ui.Font.Main)
  ui.offsetCursorY(8)

  local is_start_defined = course.startLine ~= nil
  local is_finish_defined = course.finishLine ~= nil
  local is_starting_point_defined = course.startingPoint ~= nil

  ui.textAligned("Start line", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if is_start_defined then
    if ui.button("Clear###startline", vec2(120, 30), button_global_flags) then
      course.startLine = nil
      is_start_defined = false
      self:onCourseEdited()
    end
  else
    if ui.button("Define###startline", vec2(120, 30), button_global_flags) then
      other_creating_context = {
        head_position = nil,
        type_creating = 'startLine'
      }
    end
  end

  ui.textAligned("Finish line", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if is_finish_defined then
    if ui.button("Clear###finishline", vec2(120, 30), button_global_flags) then
      course.finishLine = nil
      is_finish_defined = false
      self:onCourseEdited()
    end
  else
    if ui.button("Define###finishline", vec2(120, 30), button_global_flags) then
      other_creating_context = {
        head_position = nil,
        type_creating = 'finishLine'
      }
    end
  end

  ui.offsetCursorY(16)

  ui.textAligned("Starting point", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if is_starting_point_defined then
    if ui.button("Clear###startingpoint", vec2(120, 30), button_global_flags) then
      course.startingPoint = nil
      is_starting_point_defined = false
      self:onCourseEdited()
    end
  else
    if ui.button("Define###startingpoint", vec2(120, 30), button_global_flags) then
      other_creating_context = {
        head_position = nil,
        type_creating = 'startingPoint'
      }
    end
  end

  ui.offsetCursorY(16)

  ui.textAligned("Speed scoring range", vec2(0, 0.5), vec2(ui.availableSpaceX() - 124, 20))

  ui.sameLine(0, 4)
  ui.setNextItemWidth(60)
  ui.pushFont(ui.Font.Monospace)
  local text, _, changed = ui.inputText("Low###speedlow", tostring(course.scoringRanges.speedRange.start), ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
  ui.popFont()
  if ui.itemHovered() then
    ui.setTooltip("Speed [km/h] until which speed multiplier is at 0%.\nSuggested to be set lower for slow courses and higher if zone and clip entries are fast.")
  end
  if changed then
    if text == "" then text = "0" end
    if tonumber(text) > course.scoringRanges.speedRange.finish then course.scoringRanges.speedRange.finish = tonumber(text) end
    course.scoringRanges.speedRange.start = tonumber(text)
    self:onCourseEdited()
  end

  ui.sameLine(0, 4)
  ui.setNextItemWidth(60)
  ui.pushFont(ui.Font.Monospace)
  local text, _, changed = ui.inputText("High###speedhigh", tostring(course.scoringRanges.speedRange.finish), ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
  ui.popFont()
  if ui.itemHovered() then
    ui.setTooltip("Speed [km/h] at which speed multiplier is at maximum (100%).")
  end
  if changed then
    if text == "" then text = "0" end
    if tonumber(text) < course.scoringRanges.speedRange.start then course.scoringRanges.speedRange.start = tonumber(text) end
    course.scoringRanges.speedRange.finish = tonumber(text)
    self:onCourseEdited()
  end

  ui.textAligned("Angle scoring range", vec2(0, 0.5), vec2(ui.availableSpaceX() - 124, 20))

  ui.sameLine(0, 4)
  ui.setNextItemWidth(60)
  ui.pushFont(ui.Font.Monospace)
  local text, _, changed = ui.inputText("Low###anglelow", tostring(course.scoringRanges.angleRange.start), ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
  ui.popFont()
  if ui.itemHovered() then
    ui.setTooltip("Angle [deg] until which angle multiplier is at 0%.\nSuggested to be set lower for technical, tight courses and higher for courses with high speed scoring areas.")
  end
  if changed then
    if text == "" then text = "0" end
    if tonumber(text) > course.scoringRanges.angleRange.finish then course.scoringRanges.angleRange.finish = tonumber(text) end
    course.scoringRanges.angleRange.start = tonumber(text)
    self:onCourseEdited()
  end

  ui.sameLine(0, 4)
  ui.setNextItemWidth(60)
  ui.pushFont(ui.Font.Monospace)
  local text, _, changed = ui.inputText("High###anglegihg", tostring(course.scoringRanges.angleRange.finish), ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
  ui.popFont()
  if ui.itemHovered() then
    ui.setTooltip("Angle [deg] at which angle multiplier is at maximum (100%).")
  end
  if changed then
    if text == "" then text = "0" end
    if tonumber(text) < course.scoringRanges.angleRange.start then course.scoringRanges.angleRange.start = tonumber(text) end
    course.scoringRanges.angleRange.finish = tonumber(text)
    self:onCourseEdited()
  end

  ui.offsetCursorY(32)
  ui.textAligned("Reset the course", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if ui.imageButton(nil, vec2(120, 30), rgbm(0, 0, 0, 0), rgbm(0.3, 0, 0, 1), vec2(1, -1), vec2(1, 1), 0) then
    course = TrackConfig.new(course.name)
    self:onCourseEdited()
  end
  if ui.itemHovered() then
    ui.setTooltip("This will remove all zones and clipping points, and restore all settings to default values.\n\
This won't save the course - if clicked by mistake load the course again before saving.")
  end

  ui.sameLine(0, 0)
  ui.offsetCursor(vec2(-80, 3))
  ui.text("RESET")

  ui.offsetCursorY(24)
  ui.separator()
  ui.offsetCursorY(24)

  ui.textAligned("User courses directory", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if ui.button("Open explorer", vec2(120, 30), button_global_flags) then
    os.showInExplorer(ConfigIO.getLastUsedTrackConfigInfo().path)
  end
  if ui.itemHovered() then
    ui.setTooltip(ConfigIO.getUserCoursesDirectory())
  end


  ui.popFont()

  local hit = AsyncUtils.taskTrackRayHit()
  if not currently_editing and not currently_extending then
    local closest_dist = 1
    closest_point = nil
    if hit then
      local pois = {}
      if is_start_defined then
        pois[#pois+1] = course.startLine.head
        pois[#pois+1] = course.startLine.tail
      end
      if is_finish_defined then
        pois[#pois+1] = course.finishLine.head
        pois[#pois+1] = course.finishLine.tail
      end
      if is_starting_point_defined then
        pois[#pois+1] = course.startingPoint.origin
      end
      for _, point in ipairs(pois) do
        local distance = hit:distance(point:value())
        if distance < closest_dist then
          closest_point = point
          closest_dist = distance
        end
      end
    end

    cursor_data.selector = closest_point
    cursor_data.color_selector = rgbm(0, 2, 1, 3)
  end

  if closest_point and ui.mouseClicked() then
    currently_editing = true
    initial_offset = closest_point:value() - hit
  end

  if currently_editing and hit then
    cursor_data.selector = Point.new(hit + initial_offset)
    closest_point:set(hit + initial_offset)

    self:onCourseEdited()
    if ui.mouseReleased() then currently_editing = false end
  end


  if other_creating_context and hit then
    cursor_data.selector = Point.new(hit)

    if other_creating_context.head_position == nil then
      if ui.mouseClicked() then
        other_creating_context.head_position = Point.new(hit)
      end
    else
      cursor_data.point_group_b = PointGroup.new({ other_creating_context.head_position, Point.new(hit) })

      if ui.mouseClicked() then
        if other_creating_context.type_creating == 'startingPoint' then
          course.startingPoint = StartingPoint.new(other_creating_context.head_position, vec3(0, 0, 0))
          course.startingPoint:setEnd(Point.new(hit))
          self:onCourseEdited()
        elseif other_creating_context.type_creating == 'startLine' then
          course.startLine = Segment.new(other_creating_context.head_position, Point.new(hit))
        elseif other_creating_context.type_creating == 'finishLine' then
          course.finishLine = Segment.new(other_creating_context.head_position, Point.new(hit))
        else
          Assert.Error("Skipped all if-tree conditions")
        end

        other_creating_context = nil
        cursor_data = Cursor.new()
        self:onCourseEdited()
      end
    end

    if ui.mouseClicked(ui.MouseButton.Right) then
      other_creating_context = nil
      cursor_data = Cursor.new()
    end
  end

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

function CourseEditor:drawUIHelp(dt)
  ui.pushFont(ui.Font.Main)
  ui.offsetCursorY(8)
  ui.text("When editing objects left click places\nmarkers and right click cancells the action.")
  ui.offsetCursorY(8)
  ui.text("To edit objects' points (drag on the track)\ncorresponding tab has to be active.")
  ui.offsetCursorY(8)
  ui.text("Clicking on zone points while holding CTRL\nwill delete them.")
  ui.offsetCursorY(16)
  ui.separator()
  ui.offsetCursorY(16)
  ui.text("Visit project pages:")
  if ui.textHyperlink("RaceDepartment") then
    os.openURL("https://www.racedepartment.com/downloads/driftmode-competition-drift-gamemode.59863/")
  end
  if ui.textHyperlink("YouTube") then
    os.openURL("https://www.youtube.com/channel/UCzdi8sI1KxO7VXNlo_WaSAA")
  end
  if ui.textHyperlink("GitHub") then
    os.openURL("https://github.com/Brewsk11/ac-drift-mode")
  end
  ui.popFont()
end

return class.emmy(CourseEditor, CourseEditor.initialize)

-- #endregion
