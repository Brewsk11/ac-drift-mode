local Assert = {}

local function _assert(testing, constant, test, default_message, message)
    local _message = default_message
    if message then
        _message = message
    end
    _message = _message .. ": "
    assert(test(testing, constant), _message .. "testing( " .. tostring(testing) .. " ) vs. constant( " .. tostring(constant) .. " )")
end

function Assert.Custom(a, b, test, message)
    _assert(a, b, test, "The assertion test failed", message)
end

function Assert.Equal(a, b, message)
    _assert(a, b, function (_a, _b) return _a == _b end, "Values not equal", message)
end

function Assert.NotEqual(a, b, message)
    _assert(a, b, function (_a, _b) return _a ~= _b end, "Values not not-equal", message)
end

function Assert.LessThan(a, b, message)
    _assert(a, b, function (_a, _b) return _a < _b end, "Value not less than constant", message)
end

function Assert.MoreThan(a, b, message)
    _assert(a, b, function (_a, _b) return _a > _b end, "Value not greater than constant", message)
end

function Assert.LessOrEqual(a, b, message)
    _assert(a, b, function (_a, _b) return _a <= _b end, "Value greater than constant", message)
end

function Assert.MoreOrEqual(a, b, message)
    _assert(a, b, function (_a, _b) return _a >= _b end, "Value less than constant", message)
end

function Assert.True(a, message)
    _assert(a, true, function (_a) return _a == true end, "Value is false", message)
end

function Assert.False(a, message)
    _assert(a, false, function (_a) return _a == false end, "Value is true", message)
end

function Assert.Nil(a, message)
    _assert(a, nil, function (_a) return _a == nil end, "Value is not nil", message)
end

function Assert.NotNil(a, message)
    _assert(a, nil, function (_a) return _a ~= nil end, "Value is nil", message)
end

function Assert.Error(message)
    _assert(nil, nil, function () return false end, "Reached unconditional error", message)
end

return Assert
