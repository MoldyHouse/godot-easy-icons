# Godot Easy Icons

## Demo
<img width="1920" height="1485" alt="screenshot_20260701_190307" src="https://github.com/user-attachments/assets/a6ab7da6-d3f9-44e2-9cb8-ed2cf8b3d590" />
<img width="1280" height="1340" alt="screenshot_20260701_190232" src="https://github.com/user-attachments/assets/f61a1c88-b6b1-4e38-b403-ab8737c7a18e" />
<img width="1280" height="1144" alt="screenshot_20260701_214913" src="https://github.com/user-attachments/assets/4b5f32b1-9ed4-4ebd-b07a-699d584130cd" />
<img width="1616" height="1049" alt="screenshot_20260701_214128" src="https://github.com/user-attachments/assets/3a4aa37b-2e9b-437b-9736-99970c2acfd5" />


You can use `F3` as shortcut in the scene tree, applying to the selected node.

## Installation

Download it via [Asset Store](https://store.godotengine.org/asset/fellow-roach/godot-easy-icons/) or clone this repository and add the addon folder to yout project

## Art Styles Options

- [Pixelated](https://github.com/halfmage/pixelarticons)
- [@icons](https://github.com/Voxybuns/at-icons) 
- [Streamline](https://www.streamlinehq.com/icons/core-solid-free)

I'm providing a few icons packs in `/icons`, they are very distint in style, and you should pick which one you are going to use, remember that you can always
come back here to get the other icons if you deleted, in fact, I encourage you to delete the icons that you are not going to use, as it takes time to load them and
to recalculate the colors of the current in use ones.

## Custom Node Icons

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

If you have your own icons, and want to use this tool with your it, just remove all icons and add your in the icons folder, please, use monochromatic icons.

## Contributing

## Support the project

## Inspiration

## License

**Godot Easy Icons** is licensed under the MIT license. See [LICENSE](LICENSE).
