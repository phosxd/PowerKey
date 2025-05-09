A simple Godot-4.4 plug-in that implements easy-to-use dynamic translation. Also offers GDScript execution on Nodes, without needing to attach a Script.

# What are the advantages?
## Easier to implement:
There is no built-in CSV editor in Godot. Currently, you need to use a separate software to generate your translation files.
With PowerKey, all you need is a GDScript.
## Script-based values:
Because values are stored within a GDScript, they can be manipulated & change based on any factors (including system language).
The built-in translation system in Godot only lets values change based on system language & the values are constant.
## GDScript execution without a Script:
Say for example, you wanted to randomize some text or texture, or any property on a Node. You would need to create a whole new Script file for your scene if you did not already have one.
Instead of doing that, you could simply add a line of text to the PKExpressions field in the Inspector for the Node that needs it.

This CAN be used for randomized translation but it is very much not limited to just translation. You can do anything with it that a Script can do, **however**, it is not meant to serve as a replacement for Scripts! Use only for simple tasks.
# How do I use it?
## Define a Resources script:
PowerKey reads all variables from a single script. Create a new GDScript file, *make sure it extends Node*. Now copy the file path & paste it into the "Resources Script Path" field within the PowerKey configuration menu.

In order for PowerKey to use variables in the script, they must be defined in the script's globals! You can define variables with null values & give them new values in the "_ready" function if needed.
## Write a PKExpression:
Select any Node, then in the Inspector dock, scroll down to the "PKExpressions" dropdown located under the "Node" category. Open it up & manage the Node's PKExpressions from there.
View the integrated Guide to learn how PKExpressions work.

There is a full integrated guide section in the add-on. It should give you all the information you need. If you need help, join my [Discord](https://dsc.gg/sohp) for assistance.
# When NOT to use PowerKey:
For basic localization, the systems already in place for Godot should suffice.
PowerKey is meant to serve as a more user-friendly & more powerful approach. But sometimes more power isn't what you need.

# TO-DO:
## Node type excluder:
**Milestone:** 1.5.0

"Excluded Nodes" field in the Configuration menu in which you can define Node types to be ignored when hooking & evaluating Nodes. Excluded Nodes will not have the PKExpressions dropdown & will not run PKExpressions.
## Visual PKExpression builder:
**Milestone:** 1.5.0

A "Add Visually" button in the PKExpressions dropdown for the Inspector dock. Pressing the "Add Visually" button will show a pop-up form that makes it possible to add an expression without knowing the syntax. It will also be very helpful for getting started learning the syntax.
## Broad translations:
**Milestone:** 1.5.0

"Translations" field in the Configuration menu in which you can add/modifiy translations.

Each translation has 3 properties:

1. Property: the property on the Node to translate.
2. Key: the key to look for in the Node's property before translation.
3. Value: the property in the Resources Script to assign to the Node's property, if the key matches the Node's property (beofre translation).

This works more like the translation system built-into Godot, but still provides all the advantages of PowerKey.
## List property support:
**Milestone:** 1.5.0

Currently, in "Link" & "Assign" PKExpressions you can only acess properties from objects of type `Dictionary` or `Object`. I want to add the ability to access values from `Array`s as well.
