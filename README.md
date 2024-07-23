# Peon
A small collection of Lua scripts (along with a few useful utility libraries) I wrote for myself to use with SND.

## How to use?
1. [Download](https://github.com/heIIish/Peon/archive/refs/heads/master.zip) and extract the ZIP
2. Run `install.cmd`
3. Open SND and import `loader.lua`
4. Change the script variable in the loader file to the script file name you want to load

## Scripts
* ### [A4N Turn-in](Peon/Scripts/A4N%20Turn-in.lua)
  Buys and turns in A4N drops.
* ### [O3N Farm](Peon/Scripts/O3N%20Farm.lua)
  Completes O3N and collects loot.
* ### [Diadem Gatherer](Peon/Scripts/Diadem%20Gatherer.lua)
  Mines nodes using certain DoL buffs and shoots mobs when gauge fills.
  * Pathing not included.
* ### [Leve Turn-in](Peon/Scripts/A4N%20Turn-in.lua)
  Picks up and turns in Tsai leve.
* ### [AutoFood](Peon/Scripts/AutoFood.lua)
  Eats egg when in an instance and food buff is low.
  * Primarily for leveling alt jobs, or something...

## I don't want to use the loader
Instead of importing the loader, you can instead import the source code of a script into SND. You need to add the code below at the top of each script, as they all rely on utility functions from Peon.
```lua
dofile(os.getenv("APPDATA") .. "\\XIVLauncher\\pluginConfigs\\Peon\\init.lua")
```

> [!NOTE]
> You still need to have all the files installed in `XIVLauncher/pluginConfigs`.

## Support?
Read the source code.
