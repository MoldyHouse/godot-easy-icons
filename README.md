<img width="1920" height="560" alt="GodotEasyIconsBanner" src="https://github.com/user-attachments/assets/ba896c78-ee50-46f9-b0bb-6aac268da931" />

# Godot Easy Icons


Adding custom icons to your Godot editor nodes, made easy.

## Installation

*   **Asset Library:** Download it directly via the [Godot Asset Store](https://store.godotengine.org/asset/fellow-roach/godot-easy-icons/).
*   **Manual:** Clone this repository and drop the `addons/` folder into your project directory.

---

## Icon Styles Included

The repository includes a few distinct icon packs inside the `/icons` folder:

*   [Pixelated](https://github.com/halfmage/pixelarticons) by @halfmage
*   [@icons](https://github.com/Voxybuns/at-icons) by @voxybuns
*   [Streamline Core](https://www.streamlinehq.com/icons/core-solid-free) by Streamline

### ⚠️ Performance & Style Note
I highly recommend deleting the icon packs you don't plan on using. Better for project coherence and keeping them all increases project load times, as the addon recalculates icon colors whenever your Godot editor theme changes. Don't worry about losing them, you can always grab them from this repo later.

## Using Your Own Icons

If you want to use this tool with your own custom asset library, simply clear out the default files in the icons folder and drop your own in.

> Note: For the best results, please use monochromatic icons. The color-shifting feature is tailored for UI elements. If the project gets enough traction, expanding support for multi-colored icons is definitely on the table!


## Demo

| | |
| :---: | :---: |
| <img width="100%" alt="screenshot_20260701_190232" src="https://github.com/user-attachments/assets/fa179f46-acba-4200-9e3e-ae379ce2b7be" /> | <img width="100%" alt="screenshot_20260701_190307" src="https://github.com/user-attachments/assets/d5f4d2cb-880d-49c0-9f55-facc32903126" /> |
| <img width="100%" alt="screenshot_20260701_214913" src="https://github.com/user-attachments/assets/a80fb243-17fb-4156-9d4f-af32bf5279fa" /> | <img width="100%" alt="screenshot_20260701_214128" src="https://github.com/user-attachments/assets/6172afef-7da5-4f00-9370-6222b9480f76" /> |


<video src="https://github.com/user-attachments/assets/5b054db7-4ecf-4bf8-82dd-3dcdd739bef2" autoplay loop muted playsinline width="100%"></video>

> **Tip** You can use `F3` and `Ctrl + .` as shortcut.

---

## GDScript and C# Support

This tool allows you to easily assign icons to both GDScript and C# nodes.

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

## Inspiration

This project was heavily inspired by @voxybuns' work on @icons. His approach had a few limitations, which are completely understandable, because making an addon like this is surprisingly tricky. Since Godot's @icon annotation takes a strict static path and doesn't accept dynamic parameters, it creates a massive roadblock for user-friendly customization. This addon is an attempt to solve that problem.

## Contributing & Support

- Contributions: Found a bug or have an improvement? Feel free to open an Issue or submit a Pull Request!

- Support: Check out my other open-source tools and projects at [Mold House](https://github.com/MoldyHouse).

## License

Godot Easy Icons is licensed under the MIT license. See [LICENSE](./LICENSE) for details.
