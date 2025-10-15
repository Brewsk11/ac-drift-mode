local Assert = require('drift-mode.assert')
local Resources = require('drift-mode.Resources')
local Utils = require('drift-mode.CourseEditorUtils') -- TODO: Fix this
local ConfigIO = require("drift-mode.configio")

local CourseEditorElements = require('drift-mode.ui_layouts.CourseEditorElements')

local Cursor = require('drift-mode.models.Editor.Cursor')
local Zone = require("drift-mode.models.Elements.Scorables.Zone.Zone")
local ZoneArc = require("drift-mode.models.Elements.Scorables.ZoneArc.ZoneArc")
local Clip = require("drift-mode.models.Elements.Scorables.Clip.Clip")
local TrackConfig = require("drift-mode.models.Elements.Course.TrackConfig")
local StartingPoint = require("drift-mode.models.Elements.Position.StartingPoint")
local CourseEditorUtils = require("drift-mode.models.Editor.init")
local ConfigIO = require("drift-mode.configio")
local EventSystem = require("drift-mode.EventSystem")
local MinimapHelper = require("drift-mode.MinimapHelper")
local PointDir = require("drift-mode.models.Common.Point.init")


-- #region Pre-script definitions

---Course currently showing (choosen in combo box)
local loaded_course_info = ConfigIO.getLastUsedTrackConfigInfo() ---@type TrackConfigInfo?
local selected_course_info = ConfigIO.getLastUsedTrackConfigInfo() ---@type TrackConfigInfo?
local course = (loaded_course_info and ConfigIO.loadTrackConfig(loaded_course_info)) ---@type TrackConfig?

---Currently activated tab
local activeTab = nil

---Event system listener ID
local listener_id = EventSystem.registerListener('app-editor-courses')

---Cursor
local cursor_data = Cursor() ---@type Cursor

local closest_poi = nil

local is_user_editing = false
local button_global_flags = ui.ButtonFlags.None
local input_global_flags = ui.ButtonFlags.None

local unsaved_changes = false

local pois = {} ---@type ObjectEditorPoi[]

local current_routine = nil ---@type EditorRoutine?


---@alias EditorObjectsContext { is_hovered: boolean, smoothing_function: fun(number) }
local editor_objects_context = nil ---@type EditorObjectsContext[]?

---A canvas to draw a minimap of the hovered over object
local canvas = ui.ExtraCanvas(vec2(256, 256)):clear(rgbm(0, 0, 0, 0)):setName("TestingMinimap")

---@type MinimapHelper
local minimap_helper = MinimapHelper(ac.getFolder(ac.FolderID.CurrentTrackLayout), vec2(256, 256))
local currently_hovered_track_config = {
  name = nil,
  track_config = nil
}

-- #endregion

local function attachRoutine(routine)
  current_routine = routine
end

---@return ObjectEditorPoi[]
local function gatherPois()
  local _pois = {} ---@type ObjectEditorPoi[]

  if not course then
    return _pois
  end

  for _, obj in ipairs(course.scorables) do
    if obj.isInstanceOf(Zone) then
      ---@cast obj Zone
      for idx, inside_point in obj:getInsideLine():iter() do
        _pois[#_pois + 1] = CourseEditorUtils.POIs.Zone(
          inside_point,
          obj,
          CourseEditorUtils.POIs.Zone.Type.FromInsideLine,
          idx
        )
      end
      for idx, outside_point in obj:getOutsideLine():iter() do
        _pois[#_pois + 1] = CourseEditorUtils.POIs.Zone(
          outside_point,
          obj,
          CourseEditorUtils.POIs.Zone.Type.FromOutsideLine,
          idx
        )
      end
      local zone_center = obj:getCenter()
      if zone_center then
        _pois[#_pois + 1] = CourseEditorUtils.POIs.Zone(
          zone_center,
          obj,
          CourseEditorUtils.POIs.Zone.Type.Center,
          nil
        )
      end
    elseif obj.isInstanceOf(Clip) then
      ---@cast obj Clip
      _pois[#_pois + 1] = CourseEditorUtils.POIs.Clip(
        obj.origin,
        obj,
        CourseEditorUtils.POIs.Clip.Type.Origin
      )
      _pois[#_pois + 1] = CourseEditorUtils.POIs.Clip(
        obj:getEnd(),
        obj,
        CourseEditorUtils.POIs.Clip.Type.Ending
      )
    elseif obj.isInstanceOf(ZoneArc) then
      ---@cast obj ZoneArc
      local arc = obj:getArc()
      if arc ~= nil then
        _pois[#_pois + 1] = CourseEditorUtils.POIs.ZoneArc(
          obj:getArc():getCenter(),
          obj,
          CourseEditorUtils.POIs.ZoneArc.Type.Center
        )

        _pois[#_pois + 1] = CourseEditorUtils.POIs.ZoneArc(
          arc:getStartPoint(),
          obj,
          CourseEditorUtils.POIs.ZoneArc.Type.ArcStart
        )

        _pois[#_pois + 1] = CourseEditorUtils.POIs.ZoneArc(
          arc:getEndPoint(),
          obj,
          CourseEditorUtils.POIs.ZoneArc.Type.ArcEnd
        )

        _pois[#_pois + 1] = CourseEditorUtils.POIs.ZoneArc(
          arc:getPointOnArc(0.5),
          obj,
          CourseEditorUtils.POIs.ZoneArc.Type.ArcControl
        )
      end
    end
  end

  if course.startLine then
    _pois[#_pois + 1] = CourseEditorUtils.POIs.Segment(
      course.startLine.head,
      course.startLine,
      CourseEditorUtils.POIs.Segment.Type.StartLine,
      CourseEditorUtils.POIs.Segment.Part.Head
    )

    _pois[#_pois + 1] = CourseEditorUtils.POIs.Segment(
      course.startLine.tail,
      course.startLine,
      CourseEditorUtils.POIs.Segment.Type.StartLine,
      CourseEditorUtils.POIs.Segment.Part.Tail
    )
  end

  if course.finishLine then
    _pois[#_pois + 1] = CourseEditorUtils.POIs.Segment(
      course.finishLine.head,
      course.finishLine,
      CourseEditorUtils.POIs.Segment.Type.FinishLine,
      CourseEditorUtils.POIs.Segment.Part.Head
    )

    _pois[#_pois + 1] = CourseEditorUtils.POIs.Segment(
      course.finishLine.tail,
      course.finishLine,
      CourseEditorUtils.POIs.Segment.Type.FinishLine,
      CourseEditorUtils.POIs.Segment.Part.Tail
    )
  end

  if course.respawnLine then
    _pois[#_pois + 1] = CourseEditorUtils.POIs.Segment(
      course.respawnLine.head,
      course.respawnLine,
      CourseEditorUtils.POIs.Segment.Type.RespawnLine,
      CourseEditorUtils.POIs.Segment.Part.Head
    )

    _pois[#_pois + 1] = CourseEditorUtils.POIs.Segment(
      course.respawnLine.tail,
      course.respawnLine,
      CourseEditorUtils.POIs.Segment.Type.RespawnLine,
      CourseEditorUtils.POIs.Segment.Part.Tail
    )
  end

  if course.startingPoint then
    _pois[#_pois + 1] = CourseEditorUtils.POIs.StartingPoint(
      course.startingPoint.origin,
      course.startingPoint
    )
  end

  --cursor_data:registerObject("editor_pois", pois, CourseEditorUtils.POIs.Drawers.Simple(PointDir.Drawers.Simple()))
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
    { 'Scoring objects', self.drawUIScorables },
    { 'Other',           self.drawUIOther },
    { 'Help',            self.drawUIHelp },
  }
  pois = gatherPois()
end

---Main function drawing app UI
---@param dt integer
function CourseEditor:drawUI(dt)
  if current_routine ~= nil then
    is_user_editing = true
  else
    is_user_editing = false
  end

  if is_user_editing then
    button_global_flags = ui.ButtonFlags.Disabled
    input_global_flags = ui.InputTextFlags.ReadOnly
  else
    button_global_flags = ui.ButtonFlags.None
    input_global_flags = ui.InputTextFlags.None
  end

  -- [COMBO] Track config combo box
  local combo_item_name = "<None>"
  ui.setNextItemWidth(ui.availableSpaceX() - 132)
  if selected_course_info then
    combo_item_name = string.format("[%.1s] %s", selected_course_info.type,
      selected_course_info.name)
  end

  ui.combo("##configDropdown", combo_item_name, function()
    for _, cfg in ipairs(ConfigIO.listTrackConfigs()) do
      local label = string.format("%10s %s", "[" .. cfg.type .. "]", cfg.name)
      if ui.selectable(label) then
        selected_course_info = cfg
        self:onSelectedCourseChange(selected_course_info)
      end

      if ui.itemHovered(ui.HoveredFlags.None) then
        if currently_hovered_track_config.name ~= cfg.name then
          currently_hovered_track_config.name = cfg.name
          currently_hovered_track_config.track_config = ConfigIO.loadTrackConfig(cfg)
          minimap_helper:setBoundingBox(currently_hovered_track_config.track_config:getBoundingBox(0))
        end

        ui.setNextWindowContentSize(vec2(256, 256))
        ui.tooltip(function()
          minimap_helper:drawMap(vec2(0, 0))
          if currently_hovered_track_config.track_config then
            minimap_helper:drawTrackConfig(vec2(0, 0), currently_hovered_track_config.track_config)
          end
        end)
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
  if unsaved_changes and ac.getPatchVersionCode() > 2144 then
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
  course = ConfigIO.loadTrackConfig(loaded_course_info)
  onCourseEdited()
  unsaved_changes = false
end

local smoothers = {}
local config_initial_height = 38
local config_final_heights = {}

function CourseEditor:drawUIScorables(dt)
  local objects = course.scorables
  ui.pushFont(ui.Font.Small)

  ui.beginChild(
    "scoring_object_scrolling_pane",
    vec2(ui.availableSpaceX(), ui.availableSpaceY() - 60),
    true,
    ui.WindowFlags.AlwaysVerticalScrollbar
  )

  ui.offsetCursorY(8)

  local toRemove = nil
  local anyHightlighted = false

  for i = 1, #objects do
    if smoothers[i] == nil then
      smoothers[i] = ui.SmoothInterpolation(config_initial_height)
    end

    ui.pushID(i)
    ui.pushFont(ui.Font.Main)

    ui.beginGroup()

    local up_flags = (i == 1 or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.arrowButton("↑", ui.Direction.Up, vec2(24, config_initial_height / 2 - 2), up_flags) then
      local tmp_zone = objects[i - 1]
      objects[i - 1] = objects[i]
      objects[i] = tmp_zone
      onCourseEdited()
    end

    local down_flags = (i == #objects or is_user_editing) and ui.ButtonFlags.Disabled or ui.ButtonFlags.None
    if ui.arrowButton("↓", ui.Direction.Down, vec2(24, config_initial_height / 2 - 2), down_flags) then
      local tmp_zone = objects[i + 1]
      objects[i + 1] = objects[i]
      objects[i] = tmp_zone
      onCourseEdited()
    end
    ui.endGroup()

    ui.sameLine(0, 4)

    local config_height
    if currently_highlighted == i then
      config_height = smoothers[i](config_final_heights[i])
    else
      config_height = smoothers[i](config_initial_height)
    end

    ui.childWindow("object" .. tostring(i), vec2(ui.availableSpaceX() - 32, config_height), true,
      bit.bor(ui.WindowFlags.NoScrollbar, ui.WindowFlags.NoScrollWithMouse), function()
        if objects[i].isInstanceOf(Zone) then
          ui.image(Resources.IconZoneWhite, vec2(26, 26), rgbm(1, 1, 1, 0.7))
          if ui.itemHovered() then
            ui.setTooltip("Zone")
          end
        elseif objects[i].isInstanceOf(Clip) then
          ui.image(Resources.IconClipWhite, vec2(26, 26), rgbm(1, 1, 1, 0.7))
          if ui.itemHovered() then
            ui.setTooltip("Clip")
          end
        end

        ui.sameLine(0, 4)

        ui.setNextItemWidth(ui.availableSpaceX() - 60)
        ui.pushFont(ui.Font.Main)
        objects[i].name = ui.inputText("Object #" .. tostring(i), objects[i].name,
          ui.InputTextFlags.Placeholder + input_global_flags)
        if ui.itemHovered() then
          ui.setTooltip("Object #" .. tostring(i))
        end
        ui.popFont()

        ui.sameLine(0, 6)

        ui.setNextItemWidth(ui.availableSpaceX())
        local text, changed = ui.inputText(
          "0",
          tostring(objects[i].maxPoints),
          Utils.wrapFlags({ ui.InputTextFlags.CharsDecimal, ui.InputTextFlags.Placeholder }, Utils.DisableFlags.Input,
            is_user_editing)
        )
        if ui.itemHovered() then
          ui.setTooltip("Max points")
        end

        if changed then
          if text == "" then
            text = "0"
          end
          objects[i].maxPoints = tonumber(text)
          onCourseEdited()
        end

        ui.offsetCursorY(2)
        ui.separator()
        ui.offsetCursorY(6)

        CourseEditorElements.ObjectConfigPanel(i, objects[i], is_user_editing, cursor_data, onCourseEdited, attachRoutine)

        config_final_heights[i] = ui.windowContentSize().y + 24
      end)

    if ui.itemHovered(ui.HoveredFlags.AllowWhenBlockedByActiveItem) then
      currently_highlighted = i
      anyHightlighted = true
    end

    ui.sameLine(0, 6)

    if ui.iconButton(ui.Icons.Trash, vec2(24, config_initial_height), rgbm(1, 0, 0, 0.6), rgbm(0, 0, 0, 0), -1, nil, nil, true, button_global_flags) then
      toRemove = i
    end

    ui.popFont()

    ui.popID()

    if ui.itemHovered() then
      cursor_data:registerObject(
        "on_ui_hover_highlight_scoringobject_" .. tostring(i),
        objects[i]:getCenter(),
        PointDir.Drawers.Sphere()
      )
    else
      cursor_data:unregisterObject("on_ui_hover_highlight_scoringobject_" .. tostring(i))
    end

    ui.offsetCursorY(8)
    ui.separator()
    ui.offsetCursorY(8)
  end

  ui.offsetCursorY(ui.windowHeight() - 100)

  if toRemove then
    cursor_data:unregisterObject("on_ui_hover_highlight_scoringobject_" .. tostring(toRemove))
    table.remove(objects, toRemove)
    onCourseEdited()
  end

  if not anyHightlighted then
    currently_highlighted = nil
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
    objects[#objects + 1] = Zone(course:getNextZoneName(), nil, nil, 1000)
    onCourseEdited()
  end

  ui.sameLine(0, button_gap)

  if ui.button("Create new arc", vec2(button_width, 40), button_global_flags) then
    current_routine = CourseEditorUtils.Routines.SelectArc(function(arc)
      local new_zonearc = ZoneArc(course:getNextZoneName(), 1000, false, arc, 5)
      course.scorables[#course.scorables + 1] = new_zonearc
    end)
  end

  if ui.button("Create new clip", vec2(button_width, 40), button_global_flags) then
    current_routine = CourseEditorUtils.Routines.RoutineSelectSegment(function(segment)
      local new_clip = Clip(course:getNextClipName(), segment.head, nil, nil, 1000)
      new_clip:setEnd(segment.tail)
      course.scorables[#course.scorables + 1] = new_clip
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
      current_routine = CourseEditorUtils.Routines.RoutineSelectSegment(function(segment)
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
      current_routine = CourseEditorUtils.Routines.RoutineSelectSegment(function(segment)
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
      current_routine = CourseEditorUtils.Routines.RoutineSelectSegment(function(segment)
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
      current_routine = CourseEditorUtils.Routines.RoutineSelectSegment(function(segment)
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
  local text, _, changed = ui.inputText("Low###speedlow", tostring(course.scoringRanges.speedRange.start),
    ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
  ui.popFont()
  if ui.itemHovered() then
    ui.setTooltip(
      "Speed [km/h] until which speed multiplier is at 0%.\nSuggested to be set lower for slow courses and higher if zone and clip entries are fast.")
  end
  if changed then
    if text == "" then text = "0" end
    if tonumber(text) > course.scoringRanges.speedRange.finish then
      course.scoringRanges.speedRange.finish = tonumber(
        text)
    end
    course.scoringRanges.speedRange.start = tonumber(text)
    onCourseEdited()
  end

  ui.sameLine(0, 4)
  ui.setNextItemWidth(60)
  ui.pushFont(ui.Font.Monospace)
  local text, _, changed = ui.inputText("High###speedhigh", tostring(course.scoringRanges.speedRange.finish),
    ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
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
  local text, _, changed = ui.inputText("Low###anglelow", tostring(course.scoringRanges.angleRange.start),
    ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
  ui.popFont()
  if ui.itemHovered() then
    ui.setTooltip(
      "Angle [deg] until which angle multiplier is at 0%.\nSuggested to be set lower for technical, tight courses and higher for courses with high speed scoring areas.")
  end
  if changed then
    if text == "" then text = "0" end
    if tonumber(text) > course.scoringRanges.angleRange.finish then
      course.scoringRanges.angleRange.finish = tonumber(
        text)
    end
    course.scoringRanges.angleRange.start = tonumber(text)
    onCourseEdited()
  end

  ui.sameLine(0, 4)
  ui.setNextItemWidth(60)
  ui.pushFont(ui.Font.Monospace)
  local text, _, changed = ui.inputText("High###anglegihg", tostring(course.scoringRanges.angleRange.finish),
    ui.InputTextFlags.CharsDecimal + ui.InputTextFlags.Placeholder + input_global_flags)
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
    for _, routine_class in ipairs({ CourseEditorUtils.Routines.RoutineMovePoi }) do
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
