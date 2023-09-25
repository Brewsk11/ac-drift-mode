local Resources = require('drift-mode/Resources')
local Utils = require('drift-mode/CourseEditorUtils')
require('drift-mode/models')

local CourseEditorElements = {}

function CourseEditorElements.ObjectConfigPanel(idx, object, is_disabled, cursor_data, onCourseEdited, attachRoutine)
    ui.pushFont(ui.Font.Monospace)
    ui.setNextItemWidth(42)
    local text, changed = ui.inputText(
        "Points",
        tostring(object.maxPoints),
        Utils.wrapFlags({ui.InputTextFlags.CharsDecimal, ui.InputTextFlags.Placeholder}, Utils.DisableFlags.Input, is_disabled)
    )
    ui.popFont()

    if ui.itemHovered() then
        ui.setTooltip("Max points")
    end

    if changed then
        if text == "" then
            text = "0"
        end
        object.maxPoints = tonumber(text)
        onCourseEdited()
    end

    if Zone.isInstanceOf(object) then
        CourseEditorElements.ZoneConfigPanel(idx, object, is_disabled, cursor_data, onCourseEdited, attachRoutine)
    elseif Clip.isInstanceOf(object) then
        CourseEditorElements.ClipConfigPanel(idx, object, is_disabled, cursor_data, onCourseEdited, attachRoutine)
    end
end

local generate_inside_drawer = DrawerPointGroupConnected(
  DrawerSegmentLine(Resources.ColorEditorActivePoi),
  DrawerPointSimple(Resources.ColorEditorActivePoi, 0.2))

function CourseEditorElements.ZoneConfigPanel(idx, zone, is_disabled, cursor_data, onCourseEdited, attachRoutine)
    ui.sameLine(0, 8)
    if ui.button(")  Inner", vec2(60, 0), Utils.wrapFlags({}, Utils.DisableFlags.Button, is_disabled)) then
        attachRoutine(RoutineExtendPointGroup(zone:getInsideLine()))
    end
    if ui.itemHovered() then
        ui.setTooltip("Enable pointer to extend the inner line")
        cursor_data:registerObject("ui_on_hover_to_extend_zone_inner_" .. tostring(idx),
        zone:getInsideLine():last(),
            DrawerPointSimple())
    else
        cursor_data:unregisterObject("ui_on_hover_to_extend_zone_inner_" .. tostring(idx))
    end

    ui.sameLine(0, 2)
    if ui.button("Outer   )", vec2(60, 0), Utils.wrapFlags({}, Utils.DisableFlags.Button, is_disabled)) then
        attachRoutine(RoutineExtendPointGroup(zone:getOutsideLine()))
    end
    if ui.itemHovered() then
        ui.setTooltip("Enable pointer to extend the outer line")
        cursor_data:registerObject("ui_on_hover_to_extend_zone_outer_" .. tostring(idx),
        zone:getOutsideLine():last(),
            DrawerPointSimple())
    else
        cursor_data:unregisterObject("ui_on_hover_to_extend_zone_outer_" .. tostring(idx))
    end

    ui.sameLine(0, 8)
    if ui.button("Generate inside", vec2(100, 0), Utils.wrapFlags({}, Utils.DisableFlags.Button, is_disabled)) then
        popup_context = { obj = zone, type = "generate_inside" }
    end
    if ui.itemHovered() then
        ui.setTooltip(
            "Experimental - use to generate inside line after manually defining outside line.\nExpect bugs.")
    end

    if popup_context and popup_context.obj == zone then
        ui.itemPopup(ui.MouseButton.Left, function()
            popup_context.val1 = ui.slider("", popup_context.val1, -10, 10, 'Distance to outside: %.1f')

            local pt_grp = PointGroup()
            for _, segment in zone:getOutsideLine():segment():iter() do
                local pt = Point(segment:getCenter():value() + segment:getNormal():value() * popup_context.val1)
                pt_grp:append(pt)
            end

            cursor_data:registerObject("generate_inside", pt_grp, generate_inside_drawer)

            ui.offsetCursorY(12)

            if ui.button("Generate", vec2(ui.availableSpaceX() / 2 - 4, 40)) then
                zone:setInsideLine(pt_grp)
                onCourseEdited()
                popup_context = nil
                cursor_data:unregisterObject("generate_inside")
            end

            ui.sameLine(0, 8)

            if ui.button("Cancel", vec2(ui.availableSpaceX(), 40)) then
                popup_context = nil
                cursor_data:unregisterObject("generate_inside")
            end
        end)
    end

    ui.sameLine(0, 8)
    if ui.checkbox("Collide", zone:getCollide()) then
        zone:setCollide(not zone:getCollide())
        onCourseEdited()
    end

    if ui.itemHovered() then
        ui.setTooltip("Enable collisions with the outside zone line\n\nWorks only with patched tracks!")
    end
end


function CourseEditorElements.ClipConfigPanel(idx, clip, is_disabled, cursor_data, onCourseEdited, attachRoutine)
    ui.sameLine(0, 8)
    if ui.button("Invert", vec2(60, 0), Utils.wrapFlags({}, Utils.DisableFlags.Button, is_disabled)) then
        local new_origin = clip:getEnd()
        local new_end = clip.origin
        clip.origin = new_origin
        clip:setEnd(new_end)
        onCourseEdited()
    end

    ui.sameLine(0, 8)
    if ui.checkbox("Collide", clip:getCollide()) then
        clip:setCollide(not clip:getCollide())
        onCourseEdited()
    end
end

return CourseEditorElements
