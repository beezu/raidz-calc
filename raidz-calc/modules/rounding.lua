-- desiredDigits should be 0 for ones place, 1 for tens place, etc.
local rounding = function(currentNumber, desiredDigits)
  local shiftMult = 10 ^ desiredDigits
  local output = math.floor(((currentNumber * shiftMult) + 0.5)) / shiftMult
  return output
end

return rounding
