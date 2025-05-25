Godot-4.4 plug-in that implements easy-to-use advanced & dynamic translation. Also offers GDScript execution on Nodes, without needing to attach a Script.

||PowerKey|Standard Translation|
|--|--|--
|Dynamic Values:|✅|❌
|Editor-Integration:|✅|❌
|Customization:|✅|❌
|Efficient Performance:|✅|✅

Refer to the in-editor guide to learn how to use PowerKey & all the features it has to offer.

# Table of Contents:
- [Installation](#how-to-install)
- [Advantages](#what-are-the-advantages)
- [Features](#features)
  - [Translations](#global-translations)
  - [PKExpressions](#pkexpressions)

# How to install:
If everything installed correctly, you should see a "PowerKey" tab near the upper-center of your Godot project, next to the "2D", "3D", "Script", "Game", & "AssetLib" tabs.
### From Asset Library:
 1. In your Godot project, navigate to the "Asset Library" tab & search for ["PowerKey"](https://godotengine.org/asset-library/asset/3990).
 2. Click "Download" & make sure only the `addons/PowerKey` folder is selected, you dont need any of the other files.
 3. Click "Install" to merge the selected files with your project.
 4. Activate the plugin from `Project -> Project Setings -> Plugins`, then refresh the project.

### From Github:
 1. Navigate to the latest [Github](https://github.com/phosxd/PowerKey) release. Typically found on the right-hand side under "Releases".
 2. Download the ZIP file for the latest release.
 3. Unpack the ZIP file to a new folder & delete the ZIP file.
 4. Move the `addons/PowerKey` folder from your new folder to the "addons" folder in your Godot project.
 5. Activate the plugin from `Project -> Project Setings -> Plugins`, then refresh the project.

Alternatively, you can download from the "main" branch which may include new features but can also contain unfinished code or unexpected issues. Bug reports for unreleased versions are not accepted.

[Watch installation tutorial](https://youtu.be/KQRSI6Z-3Io)

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

This CAN be used for randomized translation but it is very much not limited to just translation. You can do anything with it that a GDScript can do, however, it is not meant to serve as a replacement for scripts! Use only for simple one-off tasks.
### Fast & efficient:
I work hard to keep everything running as smoothly as possible, I've spent hours optimizing for every microsecond when parsing & processing PKExpressions. Unless you are processing or parsing thousands of PKExpressions at the same time, you should not notice any performance or memory impact.
As for Global Translations, you should use them in moderation & instead opt for "Assign" PKExpressions when possible.
# Features:
## Global Translations:
Within the Resources script you can define translations that will run across every Node in your project when the project starts. These translations will check the specified Node property & compare it against a key, if the key matches the current value of the Node property, then the specified translation value gets applied to the Node property.
This system works much like the built-in translation system in Godot, but built to work with the advantages that PowerKey provides.

"Doesn't this make the Assign PKExpression obsolete?" No, the "Assign" PKExpression is meant to serve as a one-off translation for a single or couple of Nodes, while the Translations system is meant to handle repetitive &/or unified translations on many Nodes.
## PKExpressions:
PKExpressions are lines of code that can be written directly on a Node. It is meant for simple operations like assigning a value to a property of the Node but is capable of much more. There are currently 4 types of PKExpressions.
- **Assign**: Simply sets the value of the Node's property to a value from the Resources script.
- **Link**: Works just like the Assign type, except it runs every specified interval, allowing for dynamic changes.
- **Execute**: Allows you to run raw GDScript code on the Node, which is not validated or controlled, so it must be used with caution.
- **Eval**: Runs a GDExpression on the Node & assigns the result to a property on the Node. This allows for mathematical operations, value definitions, & even safe function calls. Unlike the Execute type, this is run in a controlled environment so you don't risk crashing your project during run-time.
### PKExp Editor:
The PKExpression Editor is accessible directly within the Godot Editor's Inspector panel under the `Node` category. It contains a text editor field with proper PKExpression & GDScript syntax highlighting. It also contains a PKExpression builder UI for those who are new to the plugin and aren't entirely familiar with the syntax.

# To-Do:
## Revamp Config System:
**Milestone:** v2
Don't store the plugin's configuration data in `config.json`, handling it with `PK_Config` class. Instead integrate with the `plugin.cfg` file & use the `ConfigFile` class already provided by Godot.
## Combine `Singleton.gd` & `plugin.gd`:
**Milestone:** v2
Combining these 2 scripts will make it easier to work with in-code & make the whole plugin accessible to code anywhere in the project.
## Hard-Code PKExp Syntax Highlighting:
**Milestone:** v2
Currently, the PKExpression Engine has to generate the highlighting data during parsing, slowing down the parser. Instead we can try to use a hard-coded syntax highlighter that doesn't rely on the parser.
## Recursive value setting in PKExps:
**Milestone:** v2
With PKExpressions, you can only set values to top-level Node properties. E.g. `<Node>.size` or `<Node>.position`. Currently something like `<Node>.size.x` is impossible, which is something I need to fix. It doesn't seem Godot provides a convenient way to do this which is why this wasn't implemented in the first place.
