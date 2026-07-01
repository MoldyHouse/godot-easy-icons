# Godot Easy Icons

## Demo


You can use `F3` as shortcut in the scene tree, applying to the selected node.

## Installation

Download it via Asset Store

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
