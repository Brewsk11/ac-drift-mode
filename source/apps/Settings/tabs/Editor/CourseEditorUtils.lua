local CourseEditorUtils = {}

---@enum CourseEditorUtils.DisableFlags
CourseEditorUtils.DisableFlags = {
    Input = ui.InputTextFlags.ReadOnly,
    Button = ui.ButtonFlags.Disabled
}

function CourseEditorUtils.wrapFlags(flags, flag_type, disabled)
    local val = 0
    for _, flag in ipairs(flags) do
        val = bit.bor(val, flag)
    end

    if disabled then
        val = bit.bor(val, flag_type)
    end

    return val
end

return CourseEditorUtils
