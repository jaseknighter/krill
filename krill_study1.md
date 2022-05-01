## krill studies

### background

this study attempts to demonstrate an example of a solution to a common problem that frequently arises when coding norns scripts. 

i have tried to make this study accessible to someone without any prior coding experience. it does assume a working familiarity with norns devices, e.g., how to access and change params, use maiden load a script, etc. 

after going through this study, i highly recommend exploring the splendid [first light tutorial](https://monome.org/docs/norns/study-0/) on the monome website.

i hope this study helps people get started with the known and unknown pleasures of scripting on the norns platform. 

### technical requirements
to fully take advantage of the study's contents, you will want to first install the krill script following the installation instructions above and have it running while you are exploring  the contents below. 

### krill study 1: converting parameter ranges for the mod matrix
#### **high-level problem and solution**
the mod matrix that is built into the krill script allows parameters to modulate one another. 

the main technical challenge with this feature was to translate the current value of an input parameter to something within the min and max range of an output parameter. 

at a high level, five pieces of data had to be gathered to achieve this translation between inputs and outputs:

1. the input param's current value
2. the input param's minimum value
3. the input param's maximum value
4. the output param's minimum value
5. the output param's maximum value

to take a concrete example for this study, we'll use @justmat's lfos that were incorporated into the krill script. we will use them to change the norns reverb's return levels. 

#### sidebar 1: what is a mod matrix?
a mod matrix acts like a traditional telephone operator switchboard. it routes signals from a source (input) to a destination (output). 

#### sidebar 2: param names and ids
norns params typically have a *name* and an *id* attached to them. the param's name is what is displayed in the ui. the param's id is used to query the param, e.g. in order to get its current value or change it. 

#### **gathering the data: part i**
the 5 data points listed above can be obtained by querying the krill script's params. 

using the example of the script's lfos and reverb return levels, here are the ids of the two params we are interested in:

* `1lfo_value`
* `rev_return_level`

assuming that you have the krill script up and running, you can get the current value of these two parameters by typing the `params:get` command in the `>>` bar at the bottom of [maiden](https://monome.org/docs/norns/maiden). This is the matron REPL, where we’ll enter commands and press ENTER to execute them. 

so, get get these params' current values, open maiden, click on the `>>` bar at the bottom and enter these two lines of code (one at a time):

```
params:get("1lfo_value")
params:get("rev_return_level")
```

the numbers that are printed after entering these two commands represent the params' current values.

now enter these two commands a few more times. you should get a different value each time for `1lfo_value` and the same value each time for `rev_return_level`. (why is this? discuss amongst  yourself.)

by using the `params:get("1lfo_value")` command we have one of the 5 data points we need: the input param's current value. let's set it to a variable:

```
input_val = params:get("1lfo_value")
```

now that we've created a variable for the lfo's value param, we can enter it in the REPL and get the same result as if we typed in the param directly:

```
input_val
```

#### sidebar 3: what is a variable? 
variables act as placeholders or pointers to something else. in this case, the variable we are calling `input_val` is pointing to a number. in other cases, variables can point to other things like strings of characters, boolean (true/false) values, or even other variables.

it is interesting to note that if you enter the variable `input_val` into the REPL multiple times you'll always get the same value back in return. on the other hand, if you enter `params:get("1lfo_value")` into the REPL multiple times, you'll get a new value each time. this is because the `input_val` variable is set to the value of the param at the time you created the variable by entering `input_val = params:get("1lfo_value")` in the REPL. this could be an issue in some cases, but for our purposes here it doesn't really matter.

#### **gathering the data: part ii**

to get the params' `min` and `max` values we can lookup the param itself (not just its value). we can do this using the `lookup_param` command and set a variable to the data that is returned when calling `lookup_param`, like this:

```
lfo = params:lookup_param("1lfo_value")
rev_return_level = params:lookup_param("rev_return_level")
```

with the two variables we just created, we can get a peek into the guts of the param data using the `tab.print` comand, like so:

```
tab.print(lfo)
tab.print(rev_return_level)
```

the data returned by calling `tab.print` tells us something about the params (e.g. their `name` and `id`). however, it doesn't obviously provide us with the remaining four data points listed above that we are looking for (i.e. the params' min and max values). this is because these two params are both types of params called *control* params. control params are created with *controlspecs*. 

we can tell these are control params from two pieces of information we received when we ran the `tab.print` commands above:

1. the existance of a table called `controlspec`
2. the value of `t` for each param's `3`

in regards to the `t`, this stands for *type*. it took me a while to figure this out, but searching through the norns codebase, i found a [directory of files]((https://github.com/monome/norns/tree/main/lua/core/params) that told me there are are 10 types of params and after exploring these files i figured out that each type is given a unique value for `t`. here are a just a few of the other param types and their `t` values:

* separator: 0
* number: 1
* option: 2
* group: 7

(note: you can see all the param types and their `t` values in the `ParamSet` table set in the [paramset.lua](https://github.com/monome/norns/blob/main/lua/core/paramset.lua) file on GitHub.)

#### sidebar 4: what is a table?
in the notes above, you may have noticed a couple of references to *tables*. tables are the main way that data is structured in Lua (the language used to write most norns scripts). you can think of them as lists. i was going to provide a few more details about tables and how to use them, but then i remembered this is covered in the first light study mentioned above.

<!-- 
here is an example of a simple table you can create in the REPL that we'll assign to a variable called `simple_table`:

```
simple_table = {1,3,true,"mushroom"}
```

you can tell the size of a table by putting a *#* sign in front of the variable:

```
#simple_table
```

if you just type this variable into the REPL by itself you'll get a kind of confusing response that doesn't really tell you anything about the contents of the variable:

```
simple_table
```

to see the contents of a table, you can use the `tab.print` command:

```
tab.print(simple_table)
```

(you may recall we did this just a bit earlier to see the contents of the two params we set to the variables `lfo`
and `rev_return_level`.)

there are at least a couple of ways to get and set individual data elements that have been added to a table. the simplest is to use something called *bracket syntax* where you address the location (or *index*) of the data you want to change within the table.

going back to the simple table we created with the command `simple_table = {1,3,true,"mushroom"}`, we can change the last item item in the table from "mushroom" to "fruit":

simple_table[4] = "fruit"
 -->


#### back to the issue at hand
finding the params' `min` and `max` values, we can run tab.print again on the params controlspecs, but first, let's create two new variables for the controlspecs and then print out their contents:

```
lfo_cs = lfo.controlspec
rev_return_level_cs = rev_return_level.controlspec
tab.print(lfo_cs)
tab.print(rev_return_level_cs)
```
now, when we look at the `tab.print` outputs of these new variables, we see what we are looking for: both have the variables `minval` and `maxval`. so now we can put these min/max vals into their own variables and start working on the mapping:

```
input_min = lfo_cs.minval
input_max = lfo_cs.maxval
output_min = rev_return_level_cs.minval
output_max = rev_return_level_cs.maxval
```

we are almost there!!! well kinda almost...

#### **mapping values**
in order to map the value of the lfo param to the reverb's return level we need to find a method. happily, there are a number of functions available in the norns [util module](http://fatesblue.local/doc/modules/lib.util.html) for this.

the function we will use here is the [`linlin`](http://fatesblue.local/doc/modules/lib.util.html#linlin) function. it takes an input and the input's lower/upper range and maps to an output based on the outputs lower/upper ranges. 

here's a simple example:

  * input min: 0
  * input max: 10
  * output min: 0
  * output max: 100
  * input to convert: 5

with these example variables we can map inputs to outputs with the `linlin` function like this:

```
util.linlin(0,10,100,5)
```

running this function in the matron REPL should return a result of `50`.

now, let's run the same function with the variables we've collected above for the lfo and reverb return level params:

```
util.linlin(input_min, input_max, output_min, output_max, input_val)
```

#### **Ruh-roh**
here's where we hit a snag...rather than returning a mapped value as a number, we get a return value of `nan` which means 'not a number'

the first step to figuring this out is to look at the value of all the variables we provide to the function:

```
print(input_min, input_max, output_min, output_max, input_val)
```

printing out our variables, we see numerical values returned for everything but the third variable, `output_min`, which has a value of `-inf`. apparently, the `linlin` function doesn't know what to do with negative infinite values. go figure...

#### **digging deeper into controlspecs**
when i was building the mod matrix it took me a while to figure how how to account for mapping parameters that, like the reverb return level, have odd min or max values like `-inf`. i finally found the solution by reviewing the documentation for the [controlspec module](http://fatesblue.local/doc/modules/controlspec.html). this module is used to create (type 3) control parameters.

in the controlspec docs, i found a `map` function that, according to the doc, will 'transform an incoming value between 0 and 1 through this ControlSpec'.

so in order to perform this mapping to the reverb return level param, i first need to get the lfo value into a range between 0 and 1. i was able to do this using the same `linlin` function we just reviewed, and so i came up with some code like to set the lfo's value in the proper range and then map it, like so:

```
mapper_value = util.linlin(input_min,input_max,0,1,input_val)
```

printing this variable in the REPL, (`print(mapper_value)`) we can see the lfo param's value is now mapped to a number between 0 and 1 and now we can also use the `controlspec: map` function to set it to the correct value within the min and max range of the reverb return level param. 

here we'll reuse the variable we created earlier for the reverb return value param's controlspec, `rev_return_level_cs`

```
output_val = rev_return_level_cs:map(mapper_value)
```

(note: you may have noticed above that the `map` function needs to be called using a semicolon (`:`) instead of a dot (`.`). using a semicolon in lua leverages something called 'syntactic sugar'. explaining this is beyond the scope of this study, mostly because i don't understand it very well, but it is a good subject for a future study.)

longwinded notes aside, if we enter our `output_val` variable in the matron REPL we will get a new value that represents the lfo param value being successfully mapped to the reverb return level param. with this value we can now use it to set the value of the reverb return level. 

but first, so you can hear it, make sure you have the krill script running and the reverb turned on in the params menu.

then, run this command:

`param:set("rev_return_level",output_val)`

...and you should hear a change in the reverb.

that's it! phew! now, i need to do the dishes. :P


### final thoughts after having done the dishes 
what i've tried to demonstrate here is not just the solution to a few coding problems, but a bit about the process of solving the problem itself. for me, the joy of coding is as much about figuring out solutions to problems as it is about arriving at solutions. when i am trying to solve a problem, often the solution comes after i've decided i've done all i can and have more or less given up all hope. frequently, after i've given up, i decide to take a walk and then the solution just shows itself to me in my mind and sometimes the solution actually works! 

coding, especially i think for beginners, can be extremely challenging and often requires quite a bit of patience and perseverence. however, i think the effort is worth it and there is a very large community attached to monome that is here to help!
