local EventSystem = require('drift-mode/eventsystem')
local ConfigIO = require('drift-mode/configio')
local Assert = require('drift-mode/assert')
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

---@return ObjectEditorPoi[]
local function gatherPois()
  local _pois = {} ---@type ObjectEditorPoi[]

  if not course then
    --cursor_data:unregisterObject("editor_pois")
    return _pois
  end

  for _, obj in ipairs(course.scoringObjects) do
    if obj.isInstanceOf(Zone) then
      local zone_obj = obj ---@type Zone
      for idx, inside_point in zone_obj:getInsideLine():iter() do
        _pois[#_pois+1] = PoiZone(
          inside_point,
          zone_obj,
          PoiZone.Type.FromInsideLine,
          idx
        )
      end
      for idx, outside_point in zone_obj:getOutsideLine():iter() do
        _pois[#_pois+1] = PoiZone(
          outside_point,
          zone_obj,
          PoiZone.Type.FromOutsideLine,
          idx
        )
      end
    elseif obj.isInstanceOf(Clip) then
      local clip_obj = obj ---@type Clip
      _pois[#_pois+1] = PoiClip(
        clip_obj.origin,
        clip_obj,
        PoiClip.Type.Origin
      )
      _pois[#_pois+1] = PoiClip(
        clip_obj:getEnd(),
        clip_obj,
        PoiClip.Type.Ending
      )
    end
  end

  if course.startLine then
    _pois[#_pois+1] = PoiSegment(
      course.startLine.head,
      course.startLine,
      PoiSegment.Type.StartLine,
      PoiSegment.Part.Head
    )

    _pois[#_pois+1] = PoiSegment(
      course.startLine.tail,
      course.startLine,
      PoiSegment.Type.StartLine,
      PoiSegment.Part.Tail
    )
  end

  if course.finishLine then
    _pois[#_pois+1] = PoiSegment(
      course.finishLine.head,
      course.finishLine,
      PoiSegment.Type.FinishLine,
      PoiSegment.Part.Head
    )

    _pois[#_pois+1] = PoiSegment(
      course.finishLine.tail,
      course.finishLine,
      PoiSegment.Type.FinishLine,
      PoiSegment.Part.Tail
    )
  end

  if course.respawnLine then
    _pois[#_pois+1] = PoiSegment(
      course.respawnLine.head,
      course.respawnLine,
      PoiSegment.Type.RespawnLine,
      PoiSegment.Part.Head
    )

    _pois[#_pois+1] = PoiSegment(
      course.respawnLine.tail,
      course.respawnLine,
      PoiSegment.Type.RespawnLine,
      PoiSegment.Part.Tail
    )
  end

  if course.startingPoint then
    _pois[#_pois+1] = PoiStartingPoint(
      course.startingPoint.origin,
      course.startingPoint
    )
  end

  --cursor_data:registerObject("editor_pois", pois, DrawerObjectEditorPoi(DrawerPointSimple()))
  return _pois
end

---Called when editor changes the course in any way
local function onCourseEdited()
  Assert.NotNil(course, "Course was edited but simultaneously was nil")
  pois = gatherPois()
  unsaved_changes = true
  EventSystem.emit(EventSystem.Signal.TrackConfigChanged, course)
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
    ui.beginGroup()

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
        cursor_data:registerObject("ui_on_hover_to_extend_zone_inner_" .. tostring(i), objects[i]:getInsideLine():last(), DrawerPointSimple())
      else
        cursor_data:unregisterObject("ui_on_hover_to_extend_zone_inner_" .. tostring(i))
      end

      ui.sameLine(0, 2)
      if ui.button("Outer   )", vec2(60, 0), button_global_flags) then
        current_routine = RoutineExtendPointGroup(zone:getOutsideLine())
      end
      if ui.itemHovered() then
        ui.setTooltip("Enable pointer to extend the outer line")
        cursor_data:registerObject("ui_on_hover_to_extend_zone_outer_" .. tostring(i), objects[i]:getOutsideLine():last(), DrawerPointSimple())
      else
        cursor_data:unregisterObject("ui_on_hover_to_extend_zone_outer_" .. tostring(i))
      end

      ui.sameLine(0, 8)
      if ui.checkbox("Collide", zone:getCollide(), ui.Flags) then
        zone:setCollide(not zone:getCollide())
        onCourseEdited()
      end
      if ui.itemHovered() then
        ui.setTooltip("Enable collisions with the outside zone line\n\nWorks only with patched tracks!")
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

    ui.endGroup()
    if ui.itemHovered() then
      cursor_data:registerObject(
        "on_ui_hover_highlight_scoringobject_" .. tostring(i),
        objects[i]:getVisualCenter(),
        DrawerPointSphere()
      )
    else
      cursor_data:unregisterObject("on_ui_hover_highlight_scoringobject_" .. tostring(i))
    end
  end

  ui.offsetCursorY(ui.windowHeight() - 100)

  if toRemove then
    cursor_data:unregisterObject("on_ui_hover_highlight_scoringobject_" .. tostring(toRemove))
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
  local is_respawn_defined = course.respawnLine ~= nil
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

  ui.textAligned("Respawn line", vec2(0, 1.5), vec2(ui.availableSpaceX() - 124, 20))
  ui.sameLine(0, 4)
  if is_respawn_defined then
    if ui.button("Clear###respawnLine", vec2(120, 30), button_global_flags) then
      course.respawnLine = nil
      is_respawn_defined = false
      onCourseEdited()
    end
  else
    if ui.button("Define###respawnLine", vec2(120, 30), button_global_flags) then
      current_routine = RoutineSelectSegment(function (segment)
        course.respawnLine = segment
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
  ui.offsetCursorY(15)
  local help_text = [[
When editing objects left click places markers and right click cancels the action.

Clicking on objects while holding CTRL will delete them.

Zones are scored with the rear.
Clips are scored with the front.]]
  ui.dwriteTextAligned(help_text, 14, -1, -1, vec2(ui.availableSpaceX(), 0), true)
end


function CourseEditor:runEditor(dt)
  ---@type EditorRoutine.Context
  local context = {
    course = course,
    cursor = cursor_data,
    pois = pois
  }

  if current_routine then
    if current_routine:detachCondition(context) then
      current_routine = nil
      cursor_data:reset()
    else
      current_routine:run(context)
    end
    onCourseEdited()
  else
    for _, routine_class in ipairs({ RoutineMovePoi }) do
      local routine = routine_class(onCourseEdited)
      if routine:attachCondition(context) then
        current_routine = routine
        break
      end
    end
  end
end

return CourseEditor

-- #endregion
