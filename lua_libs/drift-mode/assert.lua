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
    _assert(a, b, test, "Values not equal", message)
end

function Assert.Equal(a, b, message)
    _assert(a, b, function (_a, _b) return _a == _b end, "Values not equal", message)
end

function Assert.NotEqual(a, b, message)
    _assert(a, b, function (_a, _b) return _a ~= _b end, "Values not not-equal", message)
end

return Assert
