::start::
-- call modules
local rounding = require("modules.rounding")
local grepTable = require("modules.grepTable")

-- set usable capacity ratio for zfs (930 GB usable on a 1TB drive, allegedly)
local conversionRate = 930 / 1024

-- https://www.patorjk.com/software/taag/
print("\n\n             ______     ______   ______        ______     ______   "
  .. "  __     _____")
print("            /\\___  \\   /\\  ___\\ /\\  ___\\      /\\  == \\   /\\  _"
  .. "_ \\   /\\ \\   /\\  __-.")
print("            \\/_/  /__  \\ \\  __\\ \\ \\___  \\     \\ \\  __<   \\ \\"
  .. "  __ \\  \\ \\ \\  \\ \\ \\/\\ \\")
print("              /\\_____\\  \\ \\_\\    \\/\\_____\\     \\ \\_\\ \\_\\  "
  .. "\\ \\_\\ \\_\\  \\ \\_\\  \\ \\____-")
print("              \\/_____/   \\/_/     \\/_____/      \\/_/ /_/   \\/_/\\/"
  .. "_/   \\/_/   \\/____/\n")
print(" ______     ______     __         ______     __  __     __         ____"
  .. "__     ______   ______     ______")
print("/\\  ___\\   /\\  __ \\   /\\ \\       /\\  ___\\   /\\ \\/\\ \\   /\\ "
  .. "\\       /\\  __ \\   /\\__  _\\ /\\  __ \\   /\\  == \\")
print("\\ \\ \\____  \\ \\  __ \\  \\ \\ \\____  \\ \\ \\____  \\ \\ \\_\\ \\ "
  .. " \\ \\ \\____  \\ \\  __ \\  \\/_/\\ \\/ \\ \\ \\/\\ \\  \\ \\  __<")
print(" \\ \\_____\\  \\ \\_\\ \\_\\  \\ \\_____\\  \\ \\_____\\  \\ \\_____\\"
  .. "  \\ \\_____\\  \\ \\_\\ \\_\\    \\ \\_\\  \\ \\_____\\  \\ \\_\\ \\_\\")
print("  \\/_____/   \\/_/\\/_/   \\/_____/   \\/_____/   \\/_____/   \\/_____"
  .. "/   \\/_/\\/_/     \\/_/   \\/_____/   \\/_/ /_/\n\n")

------------------------
-- GET INFO FROM USER --
------------------------

-- get capacity per each drive from user
::driveCapacity::
print("\nWhat's the unformatted disk size, in GB? Ex: 256 for 256GB, "
  .. "4096 for 4TB")
local driveCapacity = io.read()
driveCapacity = tonumber(driveCapacity)
if not driveCapacity then
  print("Invalid input, please enter a number.")
  goto driveCapacity
end

-- get total number of drives from user
::driveQuantity::
print("\nHow many disks are in the array?")
local driveQuantity = io.read()
driveQuantity = tonumber(driveQuantity)
if not driveQuantity then
  print("Invalid input, please enter a number.")
  goto driveQuantity
end

-- get total number of vdevs from user
::vdevQuantity::
print("\nHow many vdevs will there be?")
local vdevQuantity = io.read()
vdevQuantity = tonumber(vdevQuantity)
if not vdevQuantity then
  print("Invalid input, please enter a number.")
  goto vdevQuantity
end
if (vdevQuantity * 2) > driveQuantity then
  print("Too many vdevs for the number of drives. Please try again.")
  goto vdevQuantity
end

-- get total number of disks in each vdev from user
::vdevMembers::
print("\nHow many disks will be in each vdev?")
local vdevMembers = io.read()
vdevMembers = tonumber(vdevMembers)
if not vdevMembers then
  print("Invalid input, please enter a number.")
  goto vdevMembers
end

-- get desired raid type for each vdev from user
::vdevType::
print("\nWhat raid type do you want to use? (mirror, raidz1, raidz2, raidz3)")
local validTypes = {
  "mirror",
  "raidz1",
  "raidz2",
  "raidz3",
}
local vdevType = io.read()
if not grepTable(validTypes, vdevType) then
  print("Invalid input. Please enter raidz1, raidz2, raidz3, or mirror.")
  goto vdevType
end
::vdevTypeQuestion::
if string.match(vdevType, "mirror") then
  print("NOTE: mirror calculations are untrustworthy. Work in progress.")
  local goback = io.read("Would you like to start over or proceed anyway? "
    .. "(y/n)")
  if string.match(goback, "y") or string.match(goback, "yes") then
    goto start
  elseif not string.match(goback, "n") or string.match(goback, "no") then
    print("Invalid input. Please enter y/n.")
    goto vdevTypeQuestion
  end
end


---------------
-- MATH TIME --
---------------

-- table to store most calc results in
local results = {}

-- Determine how many drives will be actively used, error if that number
-- exceeds drive quantity
results.liveDrives = vdevQuantity * vdevMembers
if results.liveDrives > driveQuantity then
  print("Invalid vdev configuration. Members per vdev * Number of vdevs can't "
    .. "exceed drive quantity.")
  print(vdevQuantity .. " vdevs x " .. vdevMembers .. " = "
    .. (vdevMembers * vdevQuantity) .. ", which is greater than "
    .. driveQuantity .. ".")
  print("Going back to setting vdev quantity.")
  goto vdevQuantity
end

-- Calculate usable capacity and redundancy
if string.match(vdevType, "raidz1") then
  results.usableVdevDisks = vdevMembers - 1
  results.vdevRedundancy = 1
  results.writePerformance = 1
  results.readPerformance = results.usableVdevDisks
elseif string.match(vdevType, "raidz2") then
  results.usableVdevDisks = vdevMembers - 2
  results.vdevRedundancy = 2
  results.writePerformance = 1
  results.readPerformance = results.usableVdevDisks
elseif string.match(vdevType, "raidz3") then
  results.usableVdevDisks = vdevMembers - 3
  results.vdevRedundancy = 3
  results.writePerformance = 1
  results.readPerformance = results.usableVdevDisks
else
  results.usableVdevDisks = 1
  results.vdevRedundancy = vdevMembers - 1
  results.writePerformance = vdevMembers
  results.readPerformance = vdevMembers
end


results.hotSpares = driveQuantity - results.liveDrives
-- round usable capacity to 2 digits
results.usableCapacity = rounding((driveCapacity * conversionRate
  * results.usableVdevDisks * vdevQuantity), 2)
results.totalRedundancy = vdevQuantity * results.vdevRedundancy
results.totalReadPerformance = results.usableVdevDisks * vdevQuantity

-- this is stupid but it works
if results.hotSpares == 1 then
  results.hotSpareOutput = "spare."
else
  results.hotSpareOutput = "spares."
end

print("\n\n             ______     ______     __     _____")
print("            /\\  == \\   /\\  __ \\   /\\ \\   /\\  __-.")
print("            \\ \\  __<   \\ \\  __ \\  \\ \\ \\  \\ \\ \\/\\ \\")
print("             \\ \\_\\ \\_\\  \\ \\_\\ \\_\\  \\ \\_\\  \\ \\____-")
print("              \\/_/ /_/   \\/_/\\/_/   \\/_/   \\/____/\n")
print(" _____     ______     ______   ______     __     __         ______")
print("/\\  __-.  /\\  ___\\   /\\__  _\\ /\\  __ \\   /\\ \\   /\\ \\       /"
  .. "\\  ___\\")
print("\\ \\ \\/\\ \\ \\ \\  __\\   \\/_/\\ \\/ \\ \\  __ \\  \\ \\ \\  \\ \\ "
  .. "\\____  \\ \\___  \\")
print(" \\ \\____-  \\ \\_____\\    \\ \\_\\  \\ \\_\\ \\_\\  \\ \\_\\  \\ \\_"
  .. "____\\  \\/\\_____\\")
print("  \\/____/   \\/_____/     \\/_/   \\/_/\\/_/   \\/_/   \\/_____/   \\/"
  .. "_____/\n\n\n")

if string.match(vdevType, "mirror") then
  print("REMINDER: mirror calculations are untrustworthy. Work in progress.")
end
print("- Total usable capacity is " .. results.usableCapacity .. " GB.")
print("- The chosen setup has " .. results.hotSpares .. " hot "
  .. results.hotSpareOutput)
print("- Depending on which disks are lost, the array can survive\n  between "
  .. results.vdevRedundancy .. " and " .. results.totalRedundancy
  .. " simultaneous disk failures (" .. results.vdevRedundancy .. " per vdev).")
print("- The chosen setup offers " .. results.writePerformance
  .. "x write performance.")
print("- The chosen setup offers " .. results.totalReadPerformance
  .. "x read performance.")
