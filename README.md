# Raidz Calculator

Basic terminal-based ZFS raidz calculator written in Lua. Tested in Lua 5.4.7.

# Known Issues

- Some raid options are missing (mainly related to mirror and non-RaidZ striping)
- Mirror calculations are incorrect and untrustworthy currently. There's a disclaimer in the program as it runs if mirror is selected as the vdev type.
