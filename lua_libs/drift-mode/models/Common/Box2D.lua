local model_path = ...
local ModelBase = require("drift-mode.models.ModelBase")
local Assert = require('drift-mode.assert')

---A class for describing a rectangle on a 2D coordinate system.
---Useful for minimap calculations.
---@class Box2D : ModelBase
---@field private _p1 vec2
---@field private _p2 vec2
---@field private _size vec2
---@field private _center vec2
local Box2D = class("Box2D", ModelBase)
Box2D.__model_path = "Common.Box2D"

---When p1 & p2 == nil create a dummy 10x10 box starting at (0, 0)
---@param p1 vec2|nil
---@param p2 vec2|nil
function Box2D:initialize(p1, p2)
    local _p1 = p1
    local _p2 = p2
    if p1 == nil then
        _p1 = vec2(0, 0)
        _p2 = vec2(10, 10)
    end

    self._size = nil
    self._center = nil
    self:set(_p1, _p2)
end

---For now, P1 must be closer to origin than P2
---@private
function Box2D:validateOrder(p1, p2)
    if p1.x > p2.x or p1.y > p2.y then
        Assert.Error("P1 has to be closer to origin than P2")
    end
end

---@private
function Box2D:recalculate()
    self._size = self._p2 - self._p1
    self._center = (self._size / 2) + self._p1
end

function Box2D:set(p1, p2)
    self:validateOrder(p1, p2)
    self._p1 = p1
    self._p2 = p2
    self:recalculate()
end

function Box2D:setP1(p1)
    self:validateOrder(p1, self._p2)
    self._p1 = p1
    self:recalculate()
end

function Box2D:setP2(p2)
    self:validateOrder(self._p1, p2)
    self._p2 = p2
    self:recalculate()
end

function Box2D:get()
    return { p1 = self._p1, p2 = self._p2 }
end

function Box2D:getP1()
    return self._p1
end

function Box2D:getP2()
    return self._p2
end

function Box2D:getCenter()
    return self._center
end

function Box2D:getSize()
    return self._size
end

function Box2D:setSize(size)
    local new_p1 = self._center - (size / 2)
    local new_p2 = self._center + (size / 2)

    self:set(new_p1, new_p2)
end

function Box2D:setCenter(center)
    local new_p1 = center - (self._size / 2)
    local new_p2 = center + (self._size / 2)

    self:set(new_p1, new_p2)
end

function Box2D:getHeight()
    return self._size.y
end

function Box2D:getWidth()
    return self._size.x
end

function Box2D:setHeight(height)
    local center = self:getCenter()
    local size = self._size
    size.y = height
    self:set(center - (size / 2), center + (size / 2))
end

function Box2D:setWidth(width)
    local center = self:getCenter()
    local size = self._size
    size.x = width
    self:set(center - (size / 2), center + (size / 2))
end

---Change the size of self proportionally to fit in the given box.
---Align to center of the area.
---@param box Box2D
---@param out Box2D|nil
function Box2D:fitIn(box, out)
    local boxWidth = box:getWidth()
    local boxHeight = box:getHeight()
    local selfWidth = self:getWidth()
    local selfHeight = self:getHeight()

    local ratio = math.min(
        boxWidth / selfWidth,
        boxHeight / selfHeight)

    if out == nil then
        self:setSize(self._size * ratio)
    else
        out:setSize(self._size * ratio)
    end
end

---Change the size of self proportionally to fit in the given box.
---Align to center of the area.
---@param box Box2D
---@param out Box2D|nil
function Box2D:fit(box, out)
    local boxWidth = box:getWidth()
    local boxHeight = box:getHeight()
    local selfWidth = self:getWidth()
    local selfHeight = self:getHeight()

    local ratio = math.min(
        boxWidth / selfWidth,
        boxHeight / selfHeight)

    if out == nil then
        self:setSize(self._size / ratio)
    else
        out:setSize(self._size / ratio)
    end
end

function Box2D:fitInAndMoveTo(box, out)
    if out == nil then
        self:fitIn(box)
        self:setCenter(box:getCenter())
    else
        self:fitIn(box, out)
        out:setCenter(box:getCenter())
    end
end

function Box2D.test()
    local RENDER_TEST_TEXTURE = true

    -- Box2D:fitIn()
    local fitIn_data = {
        {
            box = Box2D(vec2(0, 0), vec2(10, 10)),
            containment = Box2D(vec2(10, 10), vec2(30, 30)),
            res = nil,
            expected = Box2D(vec2(10, 10), vec2(30, 30))
        },
        {
            box = Box2D(vec2(0, 0), vec2(10, 10)),
            containment = Box2D(vec2(40, 10), vec2(70, 30)),
            res = nil,
            expected = Box2D(vec2(45, 10), vec2(65, 30))
        },
        {
            box = Box2D(vec2(0, 0), vec2(10, 10)),
            containment = Box2D(vec2(10, 40), vec2(30, 70)),
            res = nil,
            expected = Box2D(vec2(10, 45), vec2(30, 65))
        },
        {
            box = Box2D(vec2(20, 0), vec2(40, 10)),
            containment = Box2D(vec2(40, 40), vec2(60, 70)),
            res = nil,
            expected = Box2D(vec2(40, 50), vec2(60, 60))
        },
        {
            box = Box2D(vec2(20, 0), vec2(40, 10)),
            containment = Box2D(vec2(60, 80), vec2(90, 90)),
            res = nil,
            expected = Box2D(vec2(65, 80), vec2(85, 90))
        },
    }

    -- Transform
    for _, data in ipairs(fitIn_data) do
        data.res = Box2D()
        data.box:fitInAndMoveTo(data.containment, data.res)
    end

    -- Visualize
    if RENDER_TEST_TEXTURE then
        local box2d_test_texture = ui.ExtraCanvas(vec2(100, 100)):clear(rgbm(0, 0, 0, 0)):setName("testing_Box2D")
        box2d_test_texture:update(function(dt)
            for _, data in ipairs(fitIn_data) do
                display.rect({
                    pos = data.containment:getP1(),
                    size = data.containment:getSize(),
                    color = rgbm(1, 1, 1,
                        0.33)
                })
                display.rect({ pos = data.expected:getP1(), size = data.expected:getSize(), color = rgbm(0, 1, 0, 0.33) })
                display.rect({ pos = data.res:getP1(), size = data.res:getSize(), color = rgbm(1, 0, 0, 0.33) })
            end

            local container = Box2D(vec2(0, 0), vec2(51, 51))
            local mapbb = Box2D(vec2(0, 0), vec2(17, 23))
            mapbb:fitInAndMoveTo(container)

            display.rect({
                pos = container:getP1(),
                size = container:getSize(),
                color = rgbm(1, 1, 1,
                    0.33)
            })
            display.rect({ pos = mapbb:getP1(), size = mapbb:getSize(), color = rgbm(1, 0, 0, 0.33) })
        end)
    end

    -- Validate
    for idx, data in ipairs(fitIn_data) do
        Assert.Equal(data.res:getP1(), data.expected:getP1(), "Checking P1 for #" .. idx .. " case")
        Assert.Equal(data.res:getP2(), data.expected:getP2(), "Checking P2 for #" .. idx .. " case")
    end
end

return Box2D
