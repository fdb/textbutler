# TextButler

Auto-completing text utility for macOS.

![TextButler Icon](https://raw.githubusercontent.com/fdb/textbutler/master/artwork/icon-512.png)

TextButler sits in your menubar and listens for keyboard shortcuts that you have defined. It then quickly fills in the text of your choosing. So, instead of typing:

> Dear Customer,
>   
> Thank you so much for your question. I've forwarded this to our customer support and they will look at it as soon as possible.
>  
> Kind regards,
>    
> ThingCo Support Staff
    
You can set it up to just write `;fwdsupp`, and let TextButler type the full text automatically.

## Installation
Application installation is quite involved right now. I'm working on improving this.

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
          "shortcut": ",body",
          "text": "<body>\n\n\n</body>"
        }
    ]

## TODO
- Watch the ~/.textbutler.json file for updates, and reload the snippets as needed.
- Allow the user to edit the snippets file.
- Create a default file when nothing is available.
