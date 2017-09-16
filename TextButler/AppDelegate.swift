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
            alert.addButton(withTitle: "Open Security & Privacy Settings…")
            alert.messageText = "TextButler Requires Accessibility Access."
            alert.informativeText = "TextButler needs accessibility settings to read global keystrokes.\n\nPlease go to the Security & Privacy settings pane and check TextButler under Accessibility. You may need to click the lock button first.\n\nTextButler will quit now."
            alert.alertStyle = NSAlertStyle.critical
            alert.runModal()
            
            let p = Process()
            p.launchPath = "/usr/bin/open"
            p.arguments = ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]
            p.launch()
            
            NSApp.terminate(self)
        }
    }
    
    func appDir() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appDir = documentsDir.appendingPathComponent("TextButler")
        return appDir
    }
    
    func snippetsFile() -> URL {
        let file = appDir().appendingPathComponent("snippets.json")
        return file
    }
    
    func ensureAppDirectory() {
        let dir = appDir()
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Could not create TextButler directory (\(dir.path)): \(error.localizedDescription)")
            }
        }
    }
    
    func ensureSnippetsFile() {
        let file = snippetsFile()
        if !FileManager.default.fileExists(atPath: file.path) {
            let defaultFile = Bundle.main.url(forResource: "default-snippets", withExtension: "json")!
            do {
                try FileManager.default.copyItem(at: defaultFile, to: file)
            } catch let error {
                print("Could not copy file \(defaultFile) to \(file): \(error.localizedDescription)")
            }
        }
    }

    func reloadSnippetsFile(showNotification: Bool = false) {
        let file = snippetsFile()
        snippets.removeAll()
        let str: String
        do {
            str = try String(contentsOf: file, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to load snippets.json: \(error.localizedDescription)")
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
        } catch let error {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        if showNotification {
            let notification = NSUserNotification()
            notification.title = "TextButler"
            notification.informativeText = "Reloaded snippets file."
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    func startWatchingSnippetsFile() {
        
        func callback(
            _ stream: ConstFSEventStreamRef,
            clientCallbackInfo: UnsafeMutableRawPointer?,
            numEvents: Int,
            eventPaths: UnsafeMutableRawPointer,
            eventFlags: UnsafePointer<FSEventStreamEventFlags>?,
            eventIDs: UnsafePointer<FSEventStreamEventId>?) -> Void {
            //if let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] {
            //    print("paths \(paths)")
            //}
            let appDelegate = unsafeBitCast(clientCallbackInfo, to: AppDelegate.self)
            appDelegate.reloadSnippetsFile(showNotification: true)
        }
        
        var context = FSEventStreamContext()
        context.info = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        let paths = [snippetsFile().path]
        
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        
        let stream = FSEventStreamCreate(kCFAllocatorDefault, callback, &context, paths as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), TimeInterval(0.2), flags)!
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
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

    @IBAction func openSnippetsFile(_ sender: AnyObject) {
        let p = Process()
        p.launchPath = "/usr/bin/open"
        p.arguments = ["-e", snippetsFile().path]
        p.launch()
    }
    
    @IBAction func quit(_ sender: AnyObject) {
        NSApp.terminate(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkIfAccessibilityEnabled()
        ensureAppDirectory()
        ensureSnippetsFile()
        reloadSnippetsFile()
        startWatchingSnippetsFile()
        initializeStatusMenu()
        enableMonitor()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
