<img src="https://github.com/jaseknighter/krill/blob/main/images/1-1-0-start.png" />

# krill

a lorenz system sequencer and mod matrix running @okyeron's UGen linux port of Mutable Instruments Rings for monome norns.

for beginner scripters: i've put some notes at the end of this documentation that covers some of the coding techniques used in this script. i hope that folks interested in learning more about norns coding will find these somewhat random notes helpful.

## requirements

* norns (required)
* crow, W/, just friends, midi (optional)
* audio input to excite the MIRings engine (optional)

## installation

the install process requires 3 steps to properly install!

1. open maiden and below the "matron" tab, enter:

    `;install https://github.com/jaseknighter/krill`

2. in the same "matron" tab install the MIRings UGen with this command:

    `version = "mi-UGens-linux-v.03"; url = "https://github.com/okyeron/mi-UGens/raW/master/linux-norns-binaries/"..version ..".tar"; os.execute("wget -T 180 -q -P /tmp/ " .. url .. " && tar -xvf /tmp/"..version..".tar -C /tmp && cp -r /tmp/"..version.."/* /home/we/.local/share/SuperCollider/Extensions/ && rm -r /tmp/"..version.." && rm -r /tmp/"..version..".tar")`

    note: you may skip step 2 above if the MIRings UGen was previously installed with either @okyeron's [MI-UGens for Norns](https://llllllll.co/t/mi-ugens-for-norns/31781) or @21echoes [Pedalboard](https://llllllll.co/t/pedalboard-chainable-fx-for-norns/31119) scripts.

3. restart your norns.

  
## about the script
the idea for the script and its name came from @mattallison and is inspired by [Todd Barton's Krell patch] (https://vimeo.com/48382205). originally, i was thinking of making something like a krell acid patch, using @infinitedigits [acid test engine](https://llllllll.co/t/acid-test/52201), but eventually i replaced the acid engine with @okyeron's MIRings UGen.

this script's use of a chaotic lorenz system algorithm (vs using more random values)  differentiates it from the classic Krell patch, which (in theory at least) creates modulations that lie in a space between random and predictable, whereas the classic Krell patch's use of random voltages makes it's sounds more random and less predictable.  


## credits

obvious credit is due to @mattallison for the original concept and script name. i am deeply grateful to him and @SPIKE for working with me over many hours and days testing and discussing the script. 

additional thanks and credits go out to:

* @galapagoose for publishing a lorenz algorithm in lua as part of the [crow bowery](https://github.com/monome/bowery/blob/3dd5c520c6ea401db5e1b01e0bddae396da4ed53/lorenz.lua)
* @okyeron for creating a linux version of Volker Bohm's (@geplanteobsoleszenz) MI Modules for SuperCollider
* @geplanteobsoleszenz for porting the modules to SuperCollider
* @midouest for developing a [really splendid SuperCollider envelope](https://llllllll.co/t/supercollider-tips-q-a/3185/371) that captures rise and fall as individual events
* @justmat for creating lua lfo's which i borrowed from his [otis script](https://github.com/justmat/otis)




## documentation

the krill script has two basic views:

* sequencer view
* mod matrix view

*use k1+e1 to switch back and forth between the views*

### sequencer
<img src="https://github.com/jaseknighter/krill/blob/main/images/1-2-0-start_w_grid.png" width="500" />
the sequencer view is divided into three UI sections (from left to right):

1. controls 
2. lorenz system visualization
3. lorenz x/y and lfos

e1/e2/e3 are used to navigate the controls section. all of the UI controls found in the sequencer view are also found in the main norns params menu J(PARAMETERS>EDIT).

note: when the script is first loaded, just the second and third UI sections are visible. when an encoder is turned, the first section becomes temporarily visible, along with a grid overlaying the lorenz system visualization. to make the grid overlay and UI controls section always visible, there is a PARAMETER called `grid display` in the main norns params menu (PARAMETERS>EDIT)that can be set to `always show`. 

#### *seq* (sequencer controls)

    the notes generated by the krill script are based on the underlying lorenz system algorithm. notes are selected by visualizing the algorithm and overlaying a grid on top of the visualization. this grid is subdivided by note/octave to determine pitch, which is sent to the internal krill SuperCollider engine and/or the other supported outputs (midi, crow, Just Friends, and W/).

    there are two sequencer modes: *krell* and *vuja de*

- *krell* sequencer

  the krell sequencer is modelled after Todd Barton's Krell script. the vuja de sequencer is modelled after MI Marbles eurorack module. new notes are generated in the krell mode based on the rise and fall of an envelope built into the krell script's SuperCollider engine.

  when the krell sequencer is active, seven parameters are accessible from the main UI's *seq* menu:

  1. *seq mode* (sequencing mode): switch between the two sequencing modes
  2. *env sclr* (envelope scalar): scale the rise and fall time of the SuperCollider engine's envelope proportionally
  3. *rise(ms)* (rise time): envelope rise time
  4. *fall (ms)* (fall time): envelope fall time
  5. *env level* (envelope level): envelope amplitude
  6. *env shp* (envelope shape): envelope shape (smaller values create pluckier envelopes)
  7. *num octs* (# octaves): the number of octaves available to sequence

- *vuja de* sequencer

  the vuja de sequencer is structured as a set of patterns (up to six) built using the norns [lattice](https://monome.org/docs/norns/reference/lib/lattice) and [sequins](https://monome.org/docs/norns/reference/lib/sequins) modules. 

  when the vuja de sequencer is active the seven parameters listed above are accessible from the main UI's *seq* menu. 

  in addition to the seven parameters listed above, there are three additional controls on the main UI's *seq* menu specific to the vuja de sequencer: 

  8. *loop len* (loop length): the length of each pattern (1-8 steps)
  9. *vuja_de_prob* (vuja de probability): the probability that a new note will be selected for the active step
  10. *vjd div[1-6]* (vuja de pattern divisions): sets a default division of the 1-6 enabled patterns. by default each pattern has the same set of default divisions: 1,1/2,1/4,1/8,1/16,1/32,1/64

      note: the default divisions (*vjd div[1-6]*) can be modified for each of the 6 available patterns by editing a static variable found in `/lib/globals.lua` called `VJD_PAT_DEFAULT_DIVS`. custom divisions may also be set while the script is running (see *division patterns* in the **sequencer param listing** below)

  - **other sequencer params**

    additional sequencer params may be found in the main norns PARAMETERS>EDIT menu: 

    ***SCALES+NOTES* section**: param settings related to scale, quantization, and number of octaves. this section of the params menu also displays the active note of the sequencer 

    ***VUJA DE* section**:  *vjd num divs* *: sets the number of active patterns (1-6)

    ****div pat assignments* sub-menu***:  the outputs available to the script (krill SuperCollider engine, midi, crow, W/, and Just Friends) may be assigned to up to two of the vuja de division patterns. 

    *** *division pattern[1-6]* sub-menu ***
    * *vjd divX*: same as the *vjd div[1-6]* referenced above
    * *vjd div numX*: sets a custom numerator for the pattern's division
    * *vjd div denX*: sets a custom denominator for the pattern's division
    * *vjd jitterX*: sets a positive or negative jitter to the pattern division
    * *vjd oct offset*: offsets the octave of the notes played by this pattern
  
    *** *rthm patterns[1-6]* sub-menu ***
    each pattern contains three rhythms that are defined as 8-step cellular automata patterns

     * *active rthm patX*: sets which of the three rhythm patterns are active
     * *vjd rthm stepX*: change the step size of the rhythm patterns from default 1 to 8
     * *vjd rthm patX-X*: sets the 3 rhythms to one of 256 patterns
     * *vjd rthm activeX*: indicates whether the selected rhythm is active. note, this "read only" param will only indicate a selected rhythm is active if the sequence mode (*seq mode*) is set to *vuja de*.

##### *scr* (lorenz system visualization controls)
    the *scr* (screen) sub-menu's params control how the lorenz system is displayed, which effects sequence generation:

- *x/y input***
  the lorenz system algorithm outputs three values: *first*, *second* and *third*. the *x input* and *y input* params are used to assign two of the three lorenz system output values to x/y coordinates and visualize the algorithm. changing the x input and y input assignments will change the shape of the visualization.

  as mentioned above, a grid is placed on top of the lorenz system visualization which is subdivided by note and octave to set the pitch each time the sequencer plays a note.

- ***x/y offset***
  the *x offset* and *y offset* params move the lorenz system visualization horizontally and vertically relative to the note/octave grid. this changes the pitches generated by the krill and vija de sequencers. setting these parameters to lower values will tend to lower the pitch of the notes and setting them to higher values will tend to increase the pitch of the notes.

- ***x/y scale***
  *x scale* and *y scale* changes the width and height of the lorenz system visualization. 

  an increase to the x scale will tend to generate pitches across more notes and a decrease will tend to generate pitches of across fewer notes.

  an increase to the y scale will tend to generate pitches across more octaves and a decrease will tend to generate pitches of across fewer octaves.

  the *scr* params described above are found in the main norns PARAMETERS>EDIT menu under the *LORENZ* menu separator in the *lorenz view* sub-menu.

- **lorenz x/y output**
  controls for sending lorenz x/y values to crow and midi are found in the main norns PARAMETERS>EDIT menu under the *MODULATION* menu separator in the *lorenz x/y outputs* sub-menu. 


##### *lrz* (lorenz system algorithm controls)
    the *lrz* (lorenz system algorithm) sub-menu's params set a number of the lorenz system's parameters, effecting how it behaves and gets displayed, which subsequently effects sequence generation. 

    the *lz speed* param changes how fast the algorithm changes. the other params will effect the algorthm in other ways that i don't really understand well enough to describe, but they are worth exploring and are generally "safe" to use (unlike some of the other params mentioned below).

- **additional *lrz* (lorenz algorithm) params**
  the *lrz* params described above are found in the main norns PARAMETERS>EDIT menu under the *LORENZ* menu separator in the *lorenz params* sub-menu.

  there are additional params related to the lorenz system algorithm in the *lorenz params* and *lorenz weights* sub-menus. these additional paramschange a variety of settings for the lorenz system algorithm. 

  *USE CAUTION* when changing the params in these two sub-menus as unexpected results may occur that sometimes cause the lorenz system algorithm visualization to disappear and when this happens the sequencer tends to stop playing, requiring a restart of the script. 

##### *lfo* (lfo controls)
    the *lfo* sub-menu's params control two lfos:

  * *lfo*: turns the lfo on and off
  * *shape*: sets the lfo to a sine shape, a square shape, or a Sample and Hold random value generator
  * *depth*: scales the values generated by the lfo
  * *offset*: offsets the values generatored by the lfo
  * *freq*: sets the speed of the lfo

- **additional *lfo* params**
  the *lfo* params described above are found in the main norns PARAMETERS>EDIT menu under the *MODULATION* menu separator along with parameters to set how lfo values are sent to crow and midi.

  the crow parameters in this sub-menu set slew and params to scale the lfos output values to a min and max voltage.

  the midi parameters in this sub-menu set the cc and channel values to be used with the lfo as well as turn the midi version of the lfo on and off.

  finally, the read-only *lfo value* param displays the current value of the lfo.

##### *eng* (MI Rings SuperCollider engine controls)
    the *eng* sub-menu's params control the settings for the MI Rings SuperCollider engine:

  * mode controls
    * *egg mode*: setting egg mode to 1 enables the Rings easter egg, inspired by the Roland RS-09 and disasterpeace
    * *eng mode*: sets the resonator model to one of 6 modes: 
      ** *res*: resonator
      ** *sstr*: sympathetic string
      ** *mstr*: modulated/inharmonic string
      ** *fm*: 2-op fm voice
      ** *sstrq*: sympathetic string quantized
      ** *strr*: string and reverb
    * *eng mode* (egg mode): sets the 'model' to one of 6 modes: 
      ** *for*: formant
      ** *chor*: chorus
      ** *rev*: reverb
      ** *for2*: formant 2
      ** *ens*: ensemble
      ** *rev2*: chorus 2
      * *trig type*: sets excitation signal to *internal* or *external.* if set to external, an audio signal is required from the norns audio input jack(s)
  * slew controls
    * *freq slew*: sets a slew value for the pitch of notes played by the SuperCollider engine
    * *fslw enbl* (frequency slew enable): enables/disables frequency slew
  * model controls
    * *pos* (position): specifies the position where the model's structure is excited
    * *str* (structure base): with the modal and non-linear string models, controls the inharmonicity of the spectrum (which directly impacts the perceived “material”); with the sympathetic strings model, controls the intervals between strings.
    * *str rng*: sets a range that the value of the structure base param above will modulate around 
    * *brt* (brightness base): specifies the brightness and richness of the spectrum
    * *brt rng*: sets a range that the value of the brightness base param above will modulate around
    * *dmp* (damping): controls the damping rate of the sound, from 100ms to 10s
    * *dmp rng*: sets a range that the value of the damping base param above will modulate around. 
    * *poly* (polyphony): number of simultaneous voices (1 -- 4) - this also influences the number of partials generated per voice. more voices mean less partials.

    the *eng* params described above are also found in the main norns PARAMETERS>EDIT menu in the *rings* sub-menu. 

    the above parameter descriptions are copied with gratitude from @geplanteobsoleszenz SuperCollider help documentation.

### mod matrix
<img src="https://github.com/jaseknighter/krill/blob/main/images/2-1-0.png" width="500" />
the mod matrix allows any parameter to be used to modulate any other parameter. it is divided into four UI sections:

1. menu name
2. control parameters
3. input output labels and values
4. patchpoints


#### mod matrix menu options
the mod matrix has 5 menus (e1 navigates between them):

1. *row/col* (patchpoint navigator)
  e2/e3 navigates the patchpoint matrix. a dot will appear in the center of the patchpoints to show the row and column that is currently selected.

  note: when other menus are active, k1+e2 and k1+e3 are used to navigate the patchpoint matrix.

2. *in/out* (input/output selection)
  e2/e3 selects the input/output for the selected patchpoint matrix row/column

  k1+e2 and k+e3 just display parameter folders names for fast navigation

  matrix rows represent inputs. matrix columns represent outputs.



- additional mod matrix notes:
  changing a patchpoint's  input or output will disable the patchpoint for safety. since the k3 button enables the patchpoint from any of the 3 menus, it is easy to reenable the patchpoint quickly when switching to a new input/output.
 
  the patchpoint circles give you a visual understanding of the state of each patchpoint:
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

### DATA MANAGEMENT

the *krill data* sub-menu at the end of the PARAMETERS menu has all the options for saving, loading, deleting mod_matrix settings. this sub-menu is also where you can enable/disable autosave. 

there is a global parameter in the `globals.lua` file called `AUTOSAVE_DEFAULT`. setting it to 2 means autosave is on by default. setting it to one means autosave is off by default.

## feature roadmap
* bug fixes and UI usability improvements
* vuja de set loop length and probability separately for each pattern
* publish the mod matrix as a mod that other scripts can use

## notes on the code (for aspiring scripters)