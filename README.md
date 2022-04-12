# krill

**installation**

the install process requires 3 steps to properly install!

1. open maiden and below the "matron" tab, enter:
`;install https://github.com/jaseknighter/krill`
2. in the same "matron" tab install the plugins with this command:
`os.execute("cd /tmp && wget https://github.com/schollz/tapedeck/releases/download/PortedPlugins/PortedPlugins.tar.gz && tar -xvzf PortedPlugins.tar.gz && rm PortedPlugins.tar.gz && sudo rsync -avrP PortedPlugins /home/we/.local/share/SuperCollider/Extensions/")`
3. restart your norns.

**view switching**

k1+e1: switch back and forth between the *krill sequencer* and *mod matrix*

**krill sequencer**

e1: top-level menu
e2: sub-menu
e3: change sub-menu values

there are two sequencer modes:

*krell* 

modelled after Todd Barton's Krell script

*vuja de* 

modelled after MI Marbles

**rings engine**

params to change the built-in rings are found in the PARAMETERS `rings` sub-menu.

**lorenz algorithm x/y outputs**

params to change the x/y outputs are found in the PARAMETERS `lz x/y outputs` sub-menu. these outputs may be sent to midi or crow (see the *midi* and *crow* PARAMETER sub-menus for details)

**mod matrix**

* alt+k1: switch to/from mod_matrix 
* e1: switch between the 3 mod matrix menus:
  1. row/col: use e2/e3 to change the selected row/column
  2. in/out: use e2/e3 to change the input/output for the selected row/column. 
  3. pp opt: use e2 to select the four options: enbl (enable), lvl (level), sm (self mods), rm (relative mods). use e3 to change the value of the selected pp opt. *pp opt* stands for *patchpoint options*. note, only the first pp opt (enbl) enables/disables the patch point. the other three options aren't hooked up yet. also,  k2/k3 disables/enables the patchpoint from all of the three mod matrix menus. 

mod matrix notes
* changing a patchpoint's  input or output will disable the patchpoint for safety. since the k3 button enables the patchpoint from any of the 3 menus, it is easy to reenable the patchpoint quickly when switching to a new input/output.
* the patchpoint circles give you a visual understanding of the state of each patchpoint:
  * dimly lit shape means disabled
  * medium lit shape means patchpoint is selected for editing
  * brightly lit shape means patchpoint is enabled
  * empty circle: no input/output defined for the patchpoint
  * left half of circle filled: input defined for the patchpoint
  * right half of circle filled: output defined for the patchpoint
  *  circle completely filled: input and output defined for the patchpoint
* the *in* and *out* values at the bottom indicate the input/output parameters selected for the selected patchpoint
  * the first value to appear ("-------------") provides indication that you are at the start of the list
  * a value with dashes at the front and end (e.g. "--LORENZ--") indicates a param separator.
  * a value with carrots at the front and end (e.g. "<\<lorenz view>>") indicates a param sub-menu.

**DATA MANAGEMENT**

the *krill data* sub-menu at the end of the PARAMETERS menu has all the options for saving, loading, deleting mod_matrix settings. this sub-menu is also where you can enable/disable autosave. 

there is a global parameter in the `globals.lua` file called `AUTOSAVE_DEFAULT`. setting it to 2 means autosave is on by default. setting it to one means autosave is off by default.