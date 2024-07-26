# Peon
A small collection of Lua scripts (along with a few useful utility libraries) I wrote for myself to use with SND.

## How to use?
1. [Download](https://github.com/heIIish/Peon/archive/refs/heads/master.zip) and extract the ZIP
2. Run `install.cmd`
3. Open SND and import `loader.lua`
4. Change the script variable in the loader file to the script file name you want to load
   * For example, if you wanted to load the "Materia Melder" script:
     ```lua
     local script = "Materia Melder"
     ```
5. Run the loader script in SND

## Scripts
* ### [Materia Melder](Peon/Scripts/Materia%20Melder/source.lua)
  Melds and retrieves materia from a gear piece for the "Getting Too Attached" achievement.
  * Uses the first gear piece and the first materia in the melding list.
* ### [A4N Turn-in](Peon/Scripts/A4N%20Turn-in/source.lua)
  Buys and turns in A4N drops.
* ### [O3N Farm](Peon/Scripts/O3N%20Farm/source.lua)
  Completes O3N and collects loot.
* ### [Diadem Gatherer](Peon/Scripts/Diadem%20Gatherer/source.lua)
  Mines nodes using certain DoL buffs and shoots mobs when gauge fills.
  * Pathing not included.
* ### [AutoFood](Peon/Scripts/AutoFood/source.lua)
  Tries to eat a "Boiled Egg" when in an instance and the food buff is < 20 minutes.
  * Primarily for leveling alt jobs, or something...
* ~~[Leve Turn-in](Peon/Scripts/Leve%20Turn-in/source.lua)~~
  * ~~Picks up and turns in Tsai leve.~~

## I don't want to use the loader
Instead of importing the loader, you can instead import the source code of a script into SND. You need to add the code below at the top of each script, as they all rely on utility functions from Peon.
```lua
dofile(os.getenv("APPDATA") .. "\\XIVLauncher\\pluginConfigs\\Peon\\init.lua")
```

> [!NOTE]
> You still need to have all the files installed in `XIVLauncher/pluginConfigs`.

## Support?
Read the source code.
