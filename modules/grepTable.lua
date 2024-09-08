local grep = function(table, value)
  for k, v in pairs(table) do
    if v == value then
      return k
    end
  end
end
return grep
