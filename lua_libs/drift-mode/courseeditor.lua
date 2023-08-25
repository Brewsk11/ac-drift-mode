---@class CourseEditor
---@field data TrackConfig
---@field currentlyMoving vec3?
---@field dirty boolean
---@field settingPointTo vec3?
---@field settingAxisTo vec3?
---@field onSave nil|fun(data: string)
---@field onReload nil|fun()
local CourseEditor = class 'CourseEditor'

local function drawUITest()
  if ui.button('Replace lines and stations with OBJ file', vec2(ui.availableSpaceX(), 0)) then
    ac.log("Test1")
  end
end

local function drawUITest2()
  if ui.button('Replace lines and stations with RAR file', vec2(ui.availableSpaceX(), 0)) then
    ac.log("Test2")
  end
end

local tabs = {
  { 'Test1', drawUITest },
  { 'Test2', drawUITest2 }
}


function CourseEditor:initialize()
end

function CourseEditor.allocate()
  return {}
end

local activeTab

function CourseEditor:drawUI(dt)
  activeTab = nil
  ui.pushFont(ui.Font.Small)
  ui.tabBar('tabs', function ()
    for _, v in ipairs(tabs) do
      ui.tabItem(v[1], v[4] and v[4](self) and ui.TabItemFlags.UnsavedDocument, function ()
        activeTab = v
        ui.childWindow('#scroll', ui.availableSpace(), function ()
          ui.pushItemWidth(ui.availableSpaceX())
          v[2](self, dt)
          ui.popItemWidth()
        end)
      end)
    end
    if _G['debugUI'] then
      ui.tabItem('Debug', function ()
        ui.childWindow('#scroll', ui.availableSpace(), function ()
          ui.pushItemWidth(ui.availableSpaceX())
          _G['debugUI']()
          ui.popItemWidth()
        end)
      end)
    end
  end)
  ui.popFont()
end

return class.emmy(CourseEditor, CourseEditor.allocate)
