![Candy Arts Logo](Logo.png)

[Official Site](https://candy-arts.com) | [Discord](https://discord.gg/CZ9RZxzmNf) | [Youtube](https://www.youtube.com/@CandyArtsStudio/playlists) | [Documentation](https://github.com/Candy-Arts/Extras/tree/Main/Candy%20Dialogue%20Engine/Guides) | [Godot Asset Store](https://store.godotengine.org/publisher/candy-arts/) | [Gumroad](https://candyarts.gumroad.com/)

# Candy Dialogue Creator
**Candy Dialogue Creator by [Candy Arts](https://candy-arts.com) is the free, standalone companion application to [Candy Dialogue Engine](https://github.com/Candy-Arts/Candy-Dialogue-Engine).**

![UI_Preview.png](https://candy-arts.com/wp-content/uploads/2026/08/Store-Screenshot-A.webp)

## Technical Specs
Available formats:
- Compiled executables
- Raw Godot project

Operating System:
- Linux
- Windows
- MacOS (untested and unsigned)
- Android (requires editing and compiling)

Godot:
- The compiled version is a standalone software and does not depend on Godot.
- The raw project format requires Godot 4.5 and above, due to the use of FoldableContainer nodes.

Hardware:
- The interface is designed for a resolution of 1920x1080. Visual quality may degrade on lower resolutions.

## Features
### Writing Efficiency
Candy Dialogue Creator provides a graphical user interface (GUI) to create, edit and translate dialogues with minimal typing and no special syntax.

- Easy dialogue structure navigation:
    - Select Conversation → Select Block → Add/edit Lines.
- Minimal typing:
    - Minimal special syntax (limited to special cases).
    - Add lines in one click.
    - Fill data into labeled fields, with tooltips, to configure Lines.
    - Type data or select options from drop-down lists.
- Synchronize with Godot project files and data:
    - Drop-down lists are auto-populated from variables and resource files in your Godot project.
    - Instant preview of image/audio/video files with mouse hover.
- Line List:
    - Always visible on screen for quick navigation and context-awarness.
    - Displays all lines in the selected Block.
    - Lines display relevant data.
    - Custom color-coding for Lines, for better readability.
- Cut/Copy/Paste/Duplicate Lines, even across Blocks and Conversations.
- Drag-and-drop Line/Block/Conversation re-ordering.
- Custom Line Presets:
    - Create Presets of one or more Lines, with custom data.
    - Insert Presets in one click.
- Add frequently used command Lines or Presets to your favorites list.
- One-click text Inserts:
    - Native UI buttons to insert BBCode tags and color codes.
    - Create custom Inserts for frequently used characters, words or text strings.
    - BBCode tags and custom Inserts automatically wrap around selected text.

### Spoken Lines
Character speech is of course the central part of game dialogues, so Spoken Lines get a lot of special features.

- On-screen speaker portrait for better context awareness.
- Voice playback, with play/pause, progress slider and volume control.
- Live preview of spoken text, with BBCode formatting.
- Character and word count.
- Configurable character limit count: ensure text doesn't exceed dialogue UI size.
- Hide unused/irrelevant data fields to reduce UI clutter.

### Translation & Variants
Translation features aren't an afterthought and are given serious consideration.

- Create languages and variants separately: Candy Dialogue Creator automatically forms all possible combinations.
- Specify a default text direction for each language.
- Option to provide each Line a specific text direction, for special cases.
- Easily write translations/variants to spoken Lines:
    - Select a ''working' language/variant in one click.
    - Select a 'template' language/variant in one click.
    - Template is displayed above the working language/variant for reference.
    - Template is displayed with both formatted and unformatted BBCode.
- Character and word count for templates + character and word difference vs. working language/variant.
- The language/variant selection list is color-coded to show which ones don't have text yet for the current Line.
- Separate voice playback controls for both the working and the template language/variant.
- The Line List always displays the spoken text in the selected working language/variant:
    - Quickly review all text for the selected language/variant.
    - See at a glance which lines lack text.
    - More convenient for context-awareness while writing.

### Export/Import
- Export dialogues directly to your project in a few clicks.
- Dialogues are exported as .txt files for easy compatibility and editing with third-party software.
- Re-import dialogues for further editing.
- Various options for final exports or import:
    - Merge into existing dialogue.
    - Update existing dialogue.
    - Merge/Update full Conversations or Blocks only.
    - Exclude specific Conversations/Blocks from export/import
- Two-click export for testing:
    - Click "Test" in the UI.
    - ALT+TAB to Godot.
    - Click 'Run'.

### Teamwork
A number of features make Candy Dialogue Creator great for teams, where simultaneous work and separation-of-concerns are essential:
- User and project profiles, with per-user and per-project settings.
- The 'Dialogue → Conversations → Blocks' structure + the ability to merge or update dialogue files enables splitting work between multiple people.
- Insert brief comments between Lines, give Lines a custom title/reference, or write longer comments inside of Lines to guide colleagues.
- The standalone design prevents unnecessary project access by writers and translators.
- Candy Dialogue Creator reads but doesn't edit project files (except for exported dialogues).
- Access to original project files not required: use a copy or 'dummy' project folder, with only the necessary data and resource files.

## Usage
Candy Dialogue Creator can be used in three different ways:

**[Recommended] Direct Executable:** Candy Dialogue Creator is provided as an executable file, which you can just download and run.
- This is the default intended use.
- Available for Linux, Windows, MacOS.
- MacOS is untested and unsigned: we don't have access to an Apple computer.
    - You will get a safety warning when launching.
    - It should work as well as the other versions, unless there are MacOS-specific things in Godot we're not aware of.
    - If you encounter Mac-specific bugs, please report them so we can fix them.

**[Optional] Raw Godot Project:** The raw project files are available for download, so you can open Candy Dialogue Creator in Godot like any of your own projects.
- Useful for checking the code if you have security concerns.
- Make custom modifications and compile your own version.

**[Advanced] Integrated:** The raw project files can be integrated into your game, so that players or devs can access the Candy Dialogue Creator while your game runs.
- This is an advanced, unintended option.
- Can be useful for debugging and modding.
- Instructions not provided at this time (coming soon).
- Not very difficult, but experience with Godot is recommended.
- Updating when new versions are released may require some extra work.

> [!Note]
> We plan to look into offering a compiled Android version in the future. Unfortunately, at this time, we do not have access to an Android tablet.
> You can try compiling your own Android version from the raw project. If you do so, you may need to make some edits to add compatibility with touch screens.

## Instructions
> [!WARNING]
> Dialogue and save files made in version 1.0 must be converted to version 1.1!
> See [this document](Dialogue_Conversion_Instructions.doc) for instructions.

Please see the following documents for instructions on using Candy Dialogue Creator:
- [Setup](Setup_Instructions.doc)

## Final Notes
### Project files
Access to your Godot project files is not required, but some convenience features will be unavailable.

If direct access to the actual project files isn't possible, you can provide access to a copy of the project: Candy Dialogue Creator won't be able to export dialogues to your actual project directly, but all other features will work.

### Bugs and issues
Bugs should be reported here on Github.

We really don't expect security issues considering the nature of Candy Dialogue Creator, but if you find any, please [report them directly to us](https://candy-arts.com/index.php/contact/) (don't report them publicly: someone could exploit them).

### Feedback
We're looking forward to [user feedback](https://github.com/Candy-Arts/Candy-Arts/discussions/categories/candy-dc-features) to help us improve Candy Dialogue Creator!

