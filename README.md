# TextButler: Auto-completing text utility for macOS.

## Installation
- Create a file called ~/.textbutler.json.
- Fill it with snippets in the form shown below.
- Run the application once, then quit it.
- Go to System Preferences > Security > Privacy > Accessibility and enable TextButler.

## Example ~/.textbutler.json file

    [
        {
          "shortcut": ";sig",
          "text": "Kind Greetings,\n\nJohn Doe"
        },
        {
        {
          "shortcut": ",body",
          "text": "<body>\n\n\n</body>"
        }
    ]

## TODO
- Watch the ~/.textbutler.json file for updates, and reload the snippets as needed.
- Allow the user to edit the snippets file.
- Create a default file when nothing is available.
