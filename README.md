# TextButler

Auto-completing text utility for macOS.

![TextButler Icon](https://raw.githubusercontent.com/fdb/textbutler/master/artwork/icon-256.png)

TextButler sits in your menubar and listens for keyboard shortcuts that you have defined. It then quickly fills in the text of your choosing. So, instead of typing:

> Dear Customer,
>
> Thank you so much for your question. I've forwarded this to our customer support and they will look at it as soon as possible.
>
> Kind regards,
>
> ThingCo Support Staff

You can set it up to just write `;fwdsupp` and let TextButler type the full text automatically.

Also, it has the cutest menu bar icon:

![TextButler Menu Bar Icon](https://raw.githubusercontent.com/fdb/textbutler/master/artwork/menubar.png)

## Download

Download the ZIP file from the [releases page](https://github.com/fdb/textbutler/releases).

**The releases are currently unsigned. Once downloaded, right-click the app and choose "Open".**

## Building on macOS Sierra

    git clone https://github.com/fdb/textbutler.git
    cd textbutler
    xcodebuild
    open build/Release/TextButler.app

## Example snippets file

Snippets are stored under `/Users/username/Documents/TextButler/snippets.json`. Changes are automatically picked up.

    [
        {
          "shortcut": ";sig",
          "text": "Kind Greetings,\n\nJohn Doe"
        },
        {
          "shortcut": ",body",
          "text": "<body>\n\n\n</body>"
        }
    ]

## TODO
- Allow the user to edit the snippets in a custom GUI.
- Allow snippets to control customer placement (e.g. between HTML tags).
- Add an option to start the application at login.
- Welcome screen explaining where to find snippet file, how to do expansions.
- Create signed releases of the application.
- Customizable location for snippets file.
- Remove icon from dock.
