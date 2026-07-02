# Godot Easy Icons

## Demo
<div style="display:flex;">
<img width="640" alt="screenshot_20260701_190307" src="https://github.com/user-attachments/assets/a6ab7da6-d3f9-44e2-9cb8-ed2cf8b3d590" />
<img width="427" alt="screenshot_20260701_190232" src="https://github.com/user-attachments/assets/f61a1c88-b6b1-4e38-b403-ab8737c7a18e" />
<img width="539" alt="screenshot_20260701_214128" src="https://github.com/user-attachments/assets/3a4aa37b-2e9b-437b-9736-99970c2acfd5" />
<img width="427" alt="screenshot_20260701_214913" src="https://github.com/user-attachments/assets/4b5f32b1-9ed4-4ebd-b07a-699d584130cd" />
</div>


> You can use `F3` and `Ctrl + .` as shortcut.

## Installation

Download it via [Asset Store](https://store.godotengine.org/asset/fellow-roach/godot-easy-icons/) or clone this repository and add the addon folder to yout project

## Art Styles Options

- [Pixelated](https://github.com/halfmage/pixelarticons) by @halfmage
- [@icons](https://github.com/Voxybuns/at-icons) by @voxybuns
- [Streamline](https://www.streamlinehq.com/icons/core-solid-free) by (guest what) streamline

I'm providing a few icons packs in `/icons`, they are very distint in style, and you should pick which one you are going to use, remember that you can always
come back here to get the other icons if you deleted, in fact, I encourage you to delete the icons that you are not going to use, as it takes time to load them and
to recalculate the colors of the current ones in use (they change if theme changes).

## Custom Node Icons

This tool allow you to add icons easily to GDscript nodes as well as C# nodes.

**GDScript:**
```gdscript
@icon ("res://addons/godot-easy-icons/...")
class_name MyNode
extends Node
```

**C#:**
```csharp
using Godot;

[GlobalClass, Icon("res://addons/godot-easy-icons/...")]
public partial class MyNode : Node
{
    ...
}
```

## Customization

If you have your own icons, and want to use this tool with your it, just remove all icons and add your in the icons folder, please, use monochromatic icons, this tool is mostly for UI elements, but if the tool gets traction maybe someone can help me solving this.

## Contributing

Feel free to send your Issue/PR

## Support the project

Checkout my other open source content at [Mold House](https://github.com/MoldyHouse)

## Inspiration

I really liked @voxybuns work on the icons, but his approach had huge flaw, that are completely understantable, making this addon was way harder than I thought it would, because as @icon uses a direct path, doesn't receive any other params, it basically causes a huge blocker for user friendly customizations.

## License

**Godot Easy Icons** is licensed under the MIT license. See [LICENSE](LICENSE).
