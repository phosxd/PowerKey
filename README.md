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
# TO-DO:
## "Eval" ("V") PKExpression type:
**Milestone:** ???

This PKExpression type will let you safely evaluate GDScript expressions with access to the Node's properties & Resource script's properties.
This lets you perform calculations without needing to rely on the unsafe & more expensive "Execute" PKExpression type.
The result is applied to the specified property on the Node. Just like the "Assign" PKExpression type, it is one-off so it only runs on the Node once.
## Broad translations:
**Milestone:** ???

"Translations" field in the Configuration menu in which you can add/modifiy translations.

Each translation has 3 properties:

1. Property: the property on the Node to translate.
2. Key: the key to look for in the Node's property before translation.
3. Value: the property in the Resources Script to assign to the Node's property, if the key matches the Node's property (before translation).

This works more like the translation system built-into Godot, but still provides all the advantages of PowerKey.
## Visual PKExpression builder:
**Milestone:** 1.5.0

A "Add Visually" button in the PKExpressions dropdown for the Inspector dock. Pressing the "Add Visually" button will show a pop-up form that makes it possible to add an expression without knowing the syntax. It will also be very helpful for getting started learning the syntax.
## Enhanced property access support:
**Milestone:** 1.5.0

Currently, in "Link" & "Assign" PKExpressions you can only acess properties from objects of type `Dictionary`, `Object` & `Vector2`. I want to add the ability to access values from `Array`, `Rect2`, `Rect2i`, `Plane`, `Quaternion`, `AABB`, `Transform2D`, `Basis`, `Vector2i`, `Vector3`, `Vector3i`, `Vector4`, `Vector4i`, `StringName`, & `Color` types as well.
## "Frequency" parameter for "Link" PKExpressions:
**Milestone:** 1.5.0

A new parameter in Link expressions that allow you to define how frequently the value updates. By default the frequency is 0 (every frame), this parameter option will let users set the frequency to whatever they want, to better suite their need.
However, because no expression type expects multiple parameters, I will need to implement code to allow defining multiple parameters. Here is how this new frequency parameter would be used: `L:<property_name>,<frequency> <content>`. The frequency parameter will be optional.
