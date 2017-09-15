import Cocoa
import Carbon.HIToolbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var menu: NSMenu!

    var currentKeyStream: String = ""
    var snippets = [String:String]()
    var longestShortcutLength = 0
    var statusItem: NSStatusItem!
    var monitoringEnabled = false
    var eventMonitor: Any!
    
    func _postKeyEvent(_ keyCode: Int, keyDown: Bool) {
        let eventSource = CGEventSource.init(stateID: CGEventSourceStateID.hidSystemState)
        let keyEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(keyCode), keyDown: keyDown)
        let loc = CGEventTapLocation.cghidEventTap
        keyEvent!.post(tap: loc)
    }
    
    func typeKey(keyCode: Int) {
        _postKeyEvent(keyCode, keyDown: true)
        _postKeyEvent(keyCode, keyDown: false)
    }
    
    func typeLetter(c: UniChar) {
        let slice: [UniChar] = [c]
        let eventSource = CGEventSource.init(stateID: CGEventSourceStateID.hidSystemState)
        let keyEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(0), keyDown: true)
        keyEvent?.keyboardSetUnicodeString(stringLength: 1, unicodeString: Array(slice))
        let loc = CGEventTapLocation.cghidEventTap
        keyEvent!.post(tap: loc)
    }
    
    func typeString(_ text: String) {
        for c in text.utf16 {
            if c == 10 {
                typeKey(keyCode: kVK_Return)
            } else {
                typeLetter(c: c)
            }
        }
    }
    
    func onGlobalKeyDown(_ event: NSEvent) {
        let text = event.characters!
        currentKeyStream += text
        
        // Keep only as much characters as needed.
        if currentKeyStream.characters.count > longestShortcutLength {
            let endIndex = currentKeyStream.index(currentKeyStream.endIndex, offsetBy: -longestShortcutLength)
            currentKeyStream.removeSubrange(currentKeyStream.startIndex..<endIndex)
        }
        // print("STREAM \(currentKeyStream)")
        
        for (shortcut, text) in snippets {
            if currentKeyStream.contains(shortcut) {
                currentKeyStream = ""
                
                // Backspace the abbreviation
                for _ in 1...(shortcut.characters.count) {
                    typeKey(keyCode: kVK_Delete)
                }
                
                // Type the new text
                typeString(text)
                
            }
        }
    }
    
    func initializeStatusMenu() {
        self.statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        statusItem.menu = self.menu
        statusItem.button!.image = NSImage.init(named: "MenuIcon")
    }
    
    func checkIfAccessibilityEnabled() {
        if !AXIsProcessTrusted() {
            let alert = NSAlert.init()
            alert.addButton(withTitle: "Quit")
            alert.messageText = "Enable access for assistive devices."
            alert.informativeText = "TextButler needs access for assistive devices. Please enable it in the System Preferences."
            alert.alertStyle = NSAlertStyle.critical
            alert.runModal()
            NSApp.terminate(self)
        }
    }

    func reloadSnippetsFile() {
        let user = ProcessInfo().environment["USER"]!
        let usersDir = FileManager.default.urls(for: .userDirectory, in: .localDomainMask).first!
        let homeDir = usersDir.appendingPathComponent(user)
        let file = homeDir.appendingPathComponent(".textbutler.json")
        
        snippets.removeAll()
        let str: String
        do {
            str = try String(contentsOf: file, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to load .textbutler.json: \(error.localizedDescription)")
            str = "[]"
        }
        let data = str.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]
            longestShortcutLength = 0
            for item in json {
                let shortcut = item["shortcut"] as! String
                let text = item["text"] as! String
                snippets[shortcut] = text
                if shortcut.characters.count  > longestShortcutLength {
                    longestShortcutLength = shortcut.characters.count
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    func enableMonitor() {
        if !monitoringEnabled {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: NSEventMask.keyDown, handler:onGlobalKeyDown)!
            monitoringEnabled = true
        }
    }
    
    func disableMonitor() {
        monitoringEnabled = false
        NSEvent.removeMonitor(eventMonitor)
        
    }

    @IBAction func toggleEnabled(_ sender: AnyObject) {
        let enabledMenuItem = self.menu.item(at: 0)!
        if monitoringEnabled {
            disableMonitor()
            enabledMenuItem.state = NSOffState
        } else {
            enableMonitor()
            enabledMenuItem.state = NSOnState
        }
    }

    @IBAction func reload(_ sender: AnyObject) {
        reloadSnippetsFile()
        
        let notification = NSUserNotification()
        notification.title = "TextButler"
        notification.informativeText = "Has Reloaded"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        
    }
    
    @IBAction func quit(_ sender: AnyObject) {
        NSApp.terminate(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkIfAccessibilityEnabled()
        reloadSnippetsFile()
        initializeStatusMenu()
        enableMonitor()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
