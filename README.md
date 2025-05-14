

A simple Godot-4.4 plug-in that implements easy-to-use dynamic translation. Also offers GDScript execution on Nodes, without needing to attach a Script.

||PowerKey|Standard Translation|
|--|--|--
|Dynamic Values:|✅|❌
|Editor-Integration:|✅|❌
|Customization:|✅|❌
|Efficient Performance:|✅|✅

Refer to the in-editor guide to learn how to use PowerKey & all the features it has to offer.

# How to install:
If everything installed correctly, you should see a "PowerKey" tab near the upper-center of your Godot project, next to the "2D", "3D", "Script", "Game", & "AssetLib" tabs.
### From Asset Library:
 1. In your Godot project, navigate to the "Asset Library" tab & search for "PowerKey".
 2. Click "Download", then make sure only the `addons/PowerKey` folder is selected. You dont need any of the other files.
 2. Install the plugin, then refresh your project.

### From Github:
 1. Navigate to the latest release. Typically found on the right-hand side under "Releases".
 2. Download the ZIP file for the latest release.
 3. Unpack the ZIP file to a new folder & delete the ZIP file.
 4. Move the `addons/PowerKey` folder from your new folder to the "addons" folder in your Godot project.
 5. Activate the plugin from your project settings, then refresh the project.

# What are the advantages?
Here are some key points to consider when choosing PowerKey.
### Easier to implement:
There is no built-in CSV editor in Godot. Currently, you need to use a separate software to generate your translation files.
With PowerKey, everything you'll need is built-into the editor.
### Script-based values:
Because values are stored within a GDScript, they can be manipulated & change based on any factors (including system language).
The built-in translation system for Godot only lets you define static values that cannot change.
### GDScript execution without a script:
Say for example, you wanted to randomize some text or texture, or any property on a Node. You would need to create a whole new script file for your scene if you did not already have one.
Instead of doing that, you could simply add a line of text to the PKExpressions field in the Inspector for the Node that needs it.

This CAN be used for randomized translation but it is very much not limited to just translation. You can do anything with it that a GDScript can do, however, it is not meant to serve as a replacement for scripts! Use only for simple tasks.
### Fast & efficient:
You can rest assured that every system in PowerKey runs as smoothly as possible & has no noticeable effect on performance or RAM usage. The only time you may see issues with performance or memory is when you are using thousands of high impact expressions. And if you aren't using the more advanced features of PowerKey, and just use it for translation, then you have absolutely nothing to worry about as there is effectively ZERO impact when using "Assign" PKExpressions, even at massive quantities.
# TO-DO:
### "Eval" ("V") PKExpression type:
**Milestone:** ???

This PKExpression type will let you safely evaluate GDScript expressions with access to the Node's properties & Resource script's properties.
This lets you perform calculations without needing to rely on the unsafe & more expensive "Execute" PKExpression type.
The result is applied to the specified property on the Node. Just like the "Assign" PKExpression type, it is one-off so it only runs on the Node once.
### Global Translations:
**Milestone:** ???

"Translations" field in the Configuration menu in which you can add/modifiy translations.

Each translation has 3 properties:

1. Property: the property on the Node to translate.
2. Key: the key to look for in the Node's property before translation.
3. Value: the property in the Resources Script to assign to the Node's property, if the key matches the Node's property (before translation).

This works more like the translation system built-into Godot, but still provides all the advantages of PowerKey.
### Visual PKExpression builder:
**Milestone:** ???

A "Add Visually" button in the PKExpressions dropdown for the Inspector dock. Pressing the "Add Visually" button will show a pop-up form that makes it possible to add an expression without knowing the syntax. It will also be very helpful for getting started learning the syntax.
### Enhanced property access support:
✅ **Milestone:** 1.5.0

Currently, in "Link" & "Assign" PKExpressions you can only acess properties from objects of type `Dictionary`, `Object` & `Vector2`. I want to add the ability to access values from `Array`, `Rect2`, `Rect2i`, `Plane`, `Quaternion`, `AABB`, `Transform2D`, `Basis`, `Vector2i`, `Vector3`, `Vector3i`, `Vector4`, `Vector4i`, & `Color` types as well.
### "Frequency" parameter for "Link" PKExpressions:
**Milestone:** 1.5.0

A new parameter in Link expressions that allow you to define how frequently the value updates. By default the frequency is 0 (every frame), this parameter option will let users set the frequency to whatever they want, to better suite their need.
Here is how this new frequency parameter would be used: `L:<property_name>,<frequency> <content>`. The frequency parameter will be optional.
### Option to store parsed PKExpressions on Node:
**Milestone:** 1.5.0

A button under the "PKExpressions" dropdown in the Inspector, which would store the parsed PKExpressions onto the Node to be used during runtime instead of parsing it during runtime. The reason this would not be the default is because parsed PKExpression data is larger in size than the raw expression, & parsing times are negligable unless parsing very large quantities at once. But having this as an option will let users sacrifice file size for runtime performance, which could be useful for scenes with thousands of Nodes with PKExpressions as none of them would need to be parsed.
