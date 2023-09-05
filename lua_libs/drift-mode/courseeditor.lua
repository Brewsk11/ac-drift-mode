local EventSystem = require('drift-mode/eventsystem')
local ConfigIO = require('drift-mode/configio')
local Assert = require('drift-mode/assert')
local AsyncUtils = require('drift-mode/asynchelper')
local Resources = require('drift-mode/Resources')
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
local cursor_data = Cursor() ---@type Cursor

local closest_poi = nil

local is_user_editing = false
local button_global_flags = ui.ButtonFlags.None
local input_global_flags = ui.ButtonFlags.None

local unsaved_changes = false

local pois = {} ---@type ObjectEditorPoi[]

local current_routine = nil ---@type EditorRoutine?

-- #endregion


---@enum PoiType
local PoiType = {
  Zone = "Zone",
  Clip = "Clip",
  Segment = "Segment",
  StartingPoint = "StartingPoint"
}

---@class ObjectEditorPoi : ClassBase
---@field point Point
---@field poi_type PoiType
local ObjectEditorPoi = class("ObjectEditorPoi")

function ObjectEditorPoi:initialize(point, poi_type)
  self.point = point
  self.poi_type = poi_type
end

function ObjectEditorPoi:set(new_pos)
  Assert.Error("Abstract method called")
end



---@enum PoiZonePointType
local PoiZonePointType = {
  FromInsideLine = "FromInsideLine",
  FromOutsideLine = "FromOutsideLine"
}

---@class PoiZone : ObjectEditorPoi
---@field zone Zone
---@field point_type PoiZonePointType
---@field point_index integer
local PoiZone = class("PoiZone", ObjectEditorPoi)

function PoiZone:initialize(point, zone, zone_obj_type, point_index)
  ObjectEditorPoi.initialize(self, point, PoiType.Zone)
  self.zone = zone
  self.point_type = zone_obj_type
  self.point_index = point_index
end

function PoiZone:set(new_pos)
  self.point:set(new_pos)
end



---@enum PoiClipPointType
local PoiClipPointType = {
  Origin = "Origin",
  Ending = "Ending"
}

---@class PoiClip : ObjectEditorPoi
---@field clip Clip
---@field point_type PoiClipPointType
local PoiClip = class("PoiClip", ObjectEditorPoi)

function PoiClip:initialize(point, clip, clip_obj_type)
  ObjectEditorPoi.initialize(self, point, PoiType.Clip)
  self.clip = clip
  self.point_type = clip_obj_type
end

function PoiClip:set(new_pos)
  if self.point_type == PoiClipPointType.Origin then
    self.clip.origin:set(new_pos)
  elseif self.point_type == PoiClipPointType.Ending then
    self.clip:setEnd(Point(new_pos))
  end
end



---@enum PoiSegmentType
local PoiSegmentType = {
  StartLine = "StartLine",
  FinishLine = "FinishLine"
}

---@enum PoiSegmentPointType
local PoiSegmentPointType = {
  Head = "Head",
  Tail = "Tail"
}

---@class PoiSegment : ObjectEditorPoi
---@field segment Segment
---@field segment_type PoiSegmentType
---@field segment_point_type PoiSegmentPointType
local PoiSegment = class("PoiSegment", ObjectEditorPoi)

function PoiSegment:initialize(point, segment, segment_type, segment_point_type)
  ObjectEditorPoi.initialize(self, point, PoiType.Segment)
  self.segment = segment
  self.segment_type = segment_type
  self.segment_point_type = segment_point_type
end

function PoiSegment:set(new_pos)
  if self.segment_point_type == PoiSegmentPointType.Head then
    self.segment.head:set(new_pos)
  elseif self.segment_point_type == PoiSegmentPointType.Tail then
    self.segment.tail:set(new_pos)
  end
end



---@class PoiStartingPoint : ObjectEditorPoi
---@field starting_point StartingPoint
local PoiStartingPoint = class("PoiStartingPoint", ObjectEditorPoi)

function PoiStartingPoint:initialize(point, starting_point)
  ObjectEditorPoi.initialize(self, point, PoiType.StartingPoint)
  self.starting_point = starting_point
end

function PoiStartingPoint:set(new_pos)
  self.starting_point.origin:set(new_pos)
end

---@param origin vec3
---@param radius number
---@return ObjectEditorPoi?
local function findClosestPoi(origin, radius)
  local closest_dist = radius
  closest_poi = nil ---@type ObjectEditorPoi?
  if origin then
    for _, poi in ipairs(pois) do
      local distance = origin:distance(poi.point:value())
      if distance < closest_dist then
        closest_poi = poi
        closest_dist = distance
      end
    end
  end
  return closest_poi
end


---@return ObjectEditorPoi[]
local function gatherPois()
  local _pois = {} ---@type ObjectEditorPoi[]

  if not course then return _pois end

  for _, obj in ipairs(course.scoringObjects) do
    if obj.isInstanceOf(Zone) then
      local zone_obj = obj ---@type Zone
      for idx, inside_point in zone_obj:getInsideLine():iter() do
        _pois[#_pois+1] = PoiZone(
          inside_point,
          zone_obj,
          PoiZonePointType.FromInsideLine,
          idx
        )
      end
      for idx, outside_point in zone_obj:getOutsideLine():iter() do
        _pois[#_pois+1] = PoiZone(
          outside_point,
          zone_obj,
          PoiZonePointType.FromOutsideLine,
          idx
        )
      end
    elseif obj.isInstanceOf(Clip) then
      local clip_obj = obj ---@type Clip
      _pois[#_pois+1] = PoiClip(
        clip_obj.origin,
        clip_obj,
        PoiClipPointType.Origin
      )
      _pois[#_pois+1] = PoiClip(
        clip_obj:getEnd(),
        clip_obj,
        PoiClipPointType.Ending
      )
    end
  end

  if course.startLine then
    _pois[#_pois+1] = PoiSegment(
      course.startLine.head,
      course.startLine,
      PoiSegmentType.StartLine,
      PoiSegmentPointType.Head
    )

    _pois[#_pois+1] = PoiSegment(
      course.startLine.tail,
      course.startLine,
      PoiSegmentType.StartLine,
      PoiSegmentPointType.Tail
    )
  end

  if course.finishLine then
    _pois[#_pois+1] = PoiSegment(
      course.finishLine.head,
      course.finishLine,
      PoiSegmentType.FinishLine,
      PoiSegmentPointType.Head
    )

    _pois[#_pois+1] = PoiSegment(
      course.finishLine.tail,
      course.finishLine,
      PoiSegmentType.FinishLine,
      PoiSegmentPointType.Tail
    )
  end

  if course.startingPoint then
    _pois[#_pois+1] = PoiStartingPoint(
      course.startingPoint.origin,
      course.startingPoint
    )
  end

  return _pois
end

---Called when editor changes the course in any way
---@param new_course TrackConfigInfo
local function onCourseEdited()
  Assert.NotNil(course, "Course was edited but simultaneously was nil")
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, course)
  pois = gatherPois()
  unsaved_changes = true
end


---@class EditorRoutine : ClassBase
---@field callback fun(payload: any)?
local EditorRoutine = class("EditorRoutine")
function EditorRoutine:initialize(callback)
  self.callback = callback
end

function EditorRoutine:run()
  Assert.Error("Abstract method called")
end

function EditorRoutine:attachCondition()
  Assert.Error("Abstract method called")
end

function EditorRoutine:detachCondition()
  Assert.Error("Abstract method called")
end

---@class RoutineMovePoi : EditorRoutine
---@field poi ObjectEditorPoi?
---@field offset vec3?
local RoutineMovePoi = class("RoutineMovePoi", EditorRoutine)
function RoutineMovePoi:initialize()
  EditorRoutine.initialize(self)
  self.poi = nil
  self.offset = nil
end

function RoutineMovePoi:run()
  ---@type vec3?
  local hit = AsyncUtils.taskTrackRayHit()
  if not hit then return end

  self.poi:set(hit + self.offset)

  cursor_data.selector = Point(hit + self.offset)
  cursor_data.color_selector = rgbm(1.5, 3, 0, 3)

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)

  if self.poi.isInstanceOf(PoiZone) then
    local poi_zone = self.poi ---@type PoiZone
    poi_zone.zone:setDirty()
  end
end

---@param poi ObjectEditorPoi
function RoutineMovePoi:deletePoi(poi)
  if poi.poi_type == PoiType.Zone then
    local poi_zone = poi ---@type PoiZone
    if poi_zone.point_type == PoiZonePointType.FromInsideLine then
      poi_zone.zone:getInsideLine():remove(poi_zone.point_index)
    elseif poi_zone.point_type == PoiZonePointType.FromOutsideLine then
      poi_zone.zone:getOutsideLine():remove(poi_zone.point_index)
    end
  elseif poi.poi_type == PoiType.Clip then
    local poi_clip = poi ---@type PoiClip
    table.removeItem(course.scoringObjects, poi_clip.clip)
  elseif poi.poi_type == PoiType.StartingPoint then
    course.startingPoint = nil
  elseif poi.poi_type == PoiType.Segment then
    local poi_segment = poi ---@type PoiSegment
    if poi_segment.segment_type == PoiSegmentType.StartLine then
      course.startLine = nil
    elseif poi_segment.segment_type == PoiSegmentType.FinishLine then
      course.finishLine = nil
    end
  end
  onCourseEdited()
end

function RoutineMovePoi:attachCondition()
  cursor_data:reset()

  ---@type vec3?
  local hit = AsyncUtils.taskTrackRayHit()
  if not hit then return false end

  ---@type ObjectEditorPoi?
  local poi = findClosestPoi(hit, 1)
  if not poi then return false end

  cursor_data.selector = poi.point

  if ui.keyboardButtonDown(ui.KeyIndex.Control) then
    cursor_data.color_selector = rgbm(3, 0, 1.5, 3)
  else
    cursor_data.color_selector = rgbm(0, 3, 1.5, 3)
  end

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)

  self.poi = poi
  self.offset = poi.point:value() - hit

  -- Handle removing POIs
  if ui.keyboardButtonDown(ui.KeyIndex.Control) and ui.mouseClicked() then
    self:deletePoi(self.poi)
    return false
  end

  return ui.mouseClicked()
end

function RoutineMovePoi.detachCondition()
  return ui.mouseReleased()
end



---@class RoutineExtendPointGroup : EditorRoutine
---@field point_group PointGroup
local RoutineExtendPointGroup = class("RoutineExtendPointGroup", EditorRoutine)
function RoutineExtendPointGroup:initialize(point_group)
  EditorRoutine.initialize(self)
  self.point_group = point_group
end

function RoutineExtendPointGroup:run()
  ---@type vec3?
  local hit = AsyncUtils.taskTrackRayHit()
  if not hit then return end

  cursor_data.selector = Point(hit)
  cursor_data.color_selector = rgbm(1.5, 3, 0, 3)

  if self.point_group:count() > 0 then
    cursor_data.point_group_b = PointGroup({ self.point_group:last(), Point(hit) })
    cursor_data.color_b = rgbm(0, 3, 0, 3)
  end

  if ui.mouseClicked() then
    self.point_group:append(Point(hit))
  end

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

function RoutineExtendPointGroup:attachCondition()
  Assert.Error("Manually attachable")
end

function RoutineExtendPointGroup:detachCondition()
  return ui.mouseClicked(ui.MouseButton.Right)
end



---@class RoutineSelectSegment : EditorRoutine
---@field private segment Segment
local RoutineSelectSegment = class("RoutineSelectSegment", EditorRoutine)

function RoutineSelectSegment:initialize(callback)
  EditorRoutine.initialize(self, callback)
  self.segment = Segment()
end

function RoutineSelectSegment:run()
  ---@type vec3?
  local hit = AsyncUtils.taskTrackRayHit()
  if not hit then return end

  cursor_data.selector = Point(hit)
  cursor_data.color_selector = rgbm(1.5, 3, 0, 3)

  -- When head has already been set
  if self.segment.head then
    if ui.mouseClicked() then
      self.segment.tail = Point(hit)
    end
    cursor_data.point_group_b = PointGroup({ self.segment.head, Point(hit) })
  end

  -- To set the head
  if self.segment.head == nil and ui.mouseClicked() then
    self.segment.head = Point(hit)
  end

  EventSystem.emit(EventSystem.Signal.CursorChanged, cursor_data)
end

function RoutineSelectSegment:attachCondition()
  Assert.Error("Manually attachable")
end

function RoutineSelectSegment:detachCondition()
  if self.segment.tail then
    if self.callback then self.callback(self.segment) end
    return true
  end
  return false
end


-- #region CourseEditor

---@class CourseEditor : ClassBase
local CourseEditor = class('CourseEditor')

function CourseEditor:initialize()
  self.__tabs = {
    { 'Scoring objects', self.drawUIScoringObjects },
    { 'Other',           self.drawUIOther },
    { 'Help',            self.drawUIHelp },
  }
  pois = gatherPois()
end

---Main function drawing app UI
---@param dt integer
function CourseEditor:drawUI(dt)

  if current_routine then
    button_global_flags = ui.ButtonFlags.Disabled
    input_global_flags = ui.InputTextFlags.ReadOnly
  else
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

  local reload_button_flags = button_global_flags
  if not selected_course_info then reload_button_flags = ui.ButtonFlags.Disabled end
  if ui.button("Reload", vec2(60), reload_button_flags) then
    self:onSelectedCourseChange(selected_course_info)
  end
  if ui.itemHovered() then
    ui.setTooltip("Discard any changes made and reload currently selected course.")
  end

  ui.sameLine(0, 4)
  if ui.button("New", vec2(60), button_global_flags) then
    course = TrackConfig("NewCourse")
    onCourseEdited()
  end
  if ui.itemHovered() then
    ui.setTooltip("This will discard any changes made.")
  end

  if course == nil then
    ui.text("<No course selected>"); return
  end

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
  onCourseEdited()
  unsaved_changes = false
end


function CourseEditor:drawUIScoringObjects(dt)
  local objects = course.scoringObjects
  ui.pushFont(ui.Font.Small)

  ui.beginChild(
    "scoring_object_scrolling_pane",
    vec2(ui.availableSpaceX(), ui.availableSpaceY() - 60),
    true,
    ui.WindowFlags.AlwaysVerticalScrollbar
  )

  ui.offsetCursorY(8)

  local toRemove = nil

  for i = 1, #objects do
    ui.pushID(i)
    ui.pushFont(ui.Font.Main)

    local up_flags = (i == 1 or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.button("↑", vec2(24, 0), up_flags) then
      local tmp_zone = objects[i - 1]
      objects[i - 1] = objects[i]
      objects[i] = tmp_zone
      onCourseEdited()
    end

    ui.sameLine(0, 4)
    if objects[i].isInstanceOf(Zone) then
      ui.image(Resources.IconZoneWhite, vec2(24, 24), rgbm(1, 1, 1, 0.7))
      if ui.itemHovered() then
        ui.setTooltip("Zone")
      end
    elseif objects[i].isInstanceOf(Clip) then
      ui.image(Resources.IconClipWhite, vec2(24, 24), rgbm(1, 1, 1, 0.7))
      if ui.itemHovered() then
        ui.setTooltip("Clip")
      end
    end
    ui.sameLine(0, 4)

    if Zone.isInstanceOf(objects[i]) then
      local zone = objects[i] ---@type Zone

      ui.setNextItemWidth(ui.availableSpaceX() - 32)
      zone.name = ui.inputText("Zone #" .. tostring(i), zone.name, ui.InputTextFlags.Placeholder + input_global_flags)
      if ui.itemHovered() then
        ui.setTooltip("Zone #" .. tostring(i))
      end

      ui.sameLine(0, 4)
      local down_flags = (i == #objects or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
      if ui.button("↓", vec2(24, 0), down_flags) then
        local tmp_zone = objects[i + 1]
        objects[i + 1] = objects[i]
        objects[i] = tmp_zone
        onCourseEdited()
      end
      ui.popFont()

      ui.pushFont(ui.Font.Monospace)
      ui.setNextItemWidth(42)
      local text, changed = ui.inputText("Points", tostring(zone.maxPoints),
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
        zone.maxPoints = tonumber(new_clip_points)
        onCourseEdited()
      end

      ui.sameLine(0, 8)
      if ui.button(")  Inner", vec2(60, 0), button_global_flags) then
        current_routine = RoutineExtendPointGroup(zone:getInsideLine())
      end
      if ui.itemHovered() then
        ui.setTooltip("Enable pointer to extend the inner line")
      end

      ui.sameLine(0, 2)
      if ui.button("Outer   )", vec2(60, 0), button_global_flags) then
        current_routine = RoutineExtendPointGroup(zone:getOutsideLine())
      end
      if ui.itemHovered() then
        ui.setTooltip("Enable pointer to extend the outer line")
      end
    elseif Clip.isInstanceOf(objects[i]) then
      local clip = objects[i] ---@type Clip

      ui.sameLine(0, 4)
      ui.setNextItemWidth(ui.availableSpaceX() - 32)
      objects[i].name = ui.inputText("Clip #" .. tostring(i), clip.name, ui.InputTextFlags.Placeholder + input_global_flags)
      if ui.itemHovered() then
        ui.setTooltip("Clip #" .. tostring(i))
      end

      ui.sameLine(0, 4)
      local down_flags = (i == #objects or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
      if ui.button("↓", vec2(24, 0), down_flags) then
        local tmp_zone = objects[i + 1]
        objects[i + 1] = objects[i]
        objects[i] = tmp_zone
        onCourseEdited()
      end
      ui.popFont()

      ui.pushFont(ui.Font.Monospace)
      ui.setNextItemWidth(42)
      local text, changed = ui.inputText("Points", tostring(clip.maxPoints),
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
        clip.maxPoints = tonumber(new_clip_points)
        onCourseEdited()
      end
    else
      Assert.Error("")
    end

    ui.sameLine(0, 0)
    ui.offsetCursorX(ui.availableSpaceX() - 64)
    if ui.button("Remove", vec2(60, 0), button_global_flags) then
      toRemove = i
    end

    ui.offsetCursorY(8)
    ui.separator()
    ui.offsetCursorY(8)

    ui.popID()
  end

  ui.offsetCursorY(ui.windowHeight() - 100)

  if toRemove then
    table.remove(objects, toRemove)
    onCourseEdited()
  end

  ui.popFont()
  ui.endChild()

  ui.offsetCursorY(10)

  local button_width = 130
  local button_gap = 10

  ui.offsetCursorX((ui.availableSpaceX() - (button_width * 2 + button_gap)) / 2)
  if ui.availableSpaceY() > 0 + 65 then
    ui.offsetCursorY(ui.availableSpaceY() - 65)
  end

  if ui.button("Create new zone", vec2(button_width, 40), button_global_flags) then
    objects[#objects + 1] = Zone(course:getNextZoneName(), nil, nil, tonumber(new_clip_points))
    onCourseEdited()
  end

  ui.sameLine(0, button_gap)

  if ui.button("Create new clip", vec2(button_width, 40), button_global_flags) then
    current_routine = RoutineSelectSegment(function (segment)
      local new_clip = Clip(course:getNextClipName(), segment.head, nil, nil, 1000)
      new_clip:setEnd(segment.tail)
      course.scoringObjects[#course.scoringObjects+1] = new_clip
    end)
  end
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
      onCourseEdited()
    end
  else
    if ui.button("Define###startline", vec2(120, 30), button_global_flags) then
      current_routine = RoutineSelectSegment(function (segment)
        course.startLine = segment
      end)
    end
  end

  ui.textAligned("Finish line", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if is_finish_defined then
    if ui.button("Clear###finishline", vec2(120, 30), button_global_flags) then
      course.finishLine = nil
      is_finish_defined = false
      onCourseEdited()
    end
  else
    if ui.button("Define###finishline", vec2(120, 30), button_global_flags) then
      current_routine = RoutineSelectSegment(function (segment)
        course.finishLine = segment
      end)
    end
  end

  ui.offsetCursorY(16)

  ui.textAligned("Starting point", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if is_starting_point_defined then
    if ui.button("Clear###startingpoint", vec2(120, 30), button_global_flags) then
      course.startingPoint = nil
      is_starting_point_defined = false
      onCourseEdited()
    end
  else
    if ui.button("Define###startingpoint", vec2(120, 30), button_global_flags) then
      current_routine = RoutineSelectSegment(function (segment)
        course.startingPoint = StartingPoint(segment.head, nil)
        course.startingPoint:setEnd(segment.tail)
      end)
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
    onCourseEdited()
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
    onCourseEdited()
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
    onCourseEdited()
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
    onCourseEdited()
  end

  ui.offsetCursorY(32)
  ui.textAligned("Reset the course", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if ui.imageButton(nil, vec2(120, 30), rgbm(0, 0, 0, 0), rgbm(0.3, 0, 0, 1), vec2(1, -1), vec2(1, 1), 0) then
    course = TrackConfig(course.name)
    onCourseEdited()
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
    os.openInExplorer(ConfigIO.getUserCoursesDirectory())
  end
  if ui.itemHovered() then
    ui.setTooltip(ConfigIO.getUserCoursesDirectory())
  end

  ui.popFont()
end

function CourseEditor:drawUIHelp(dt)
  ui.pushFont(ui.Font.Main)
  ui.offsetCursorY(8)
  ui.text("When editing objects left click places\nmarkers and right click cancells the action.")
  ui.offsetCursorY(8)
  ui.text("Clicking on objects while holding CTRL\nwill delete them.")
  ui.offsetCursorY(8)
  ui.text("Zones are scored with the rear.\nClips are scored with the front.")
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


function CourseEditor:runEditor(dt)
  if current_routine then
    if current_routine:detachCondition() then
      current_routine = nil
      cursor_data:reset()
    else
      current_routine:run()
    end
    onCourseEdited()
  else
    for _, routine_class in ipairs({ RoutineMovePoi }) do
      local routine = routine_class()
      if routine:attachCondition() then
        current_routine = routine
        break
      end
    end
  end
end

return CourseEditor

-- #endregion
