//
//  AppDelegate.swift
//  MenuBarOfficeManager
//
//  Created by Ivo Maffei on 20/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    public let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength);
    var thisPort: Int = 2121;
    var OMPort : Int32 = 2122;
    
    func send(message: String) { //sends message to port 2122
        var mySocket: Socket
        do {
            mySocket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
        } catch let error {
            print("Cannot create socket")
            print(error)
            return
        }
        
        do {
            try mySocket.connect(to: "localhost", port: OMPort)
        } catch let error {
            print("Cannot connect to socket")
            print("sending to 127.0.0.1 on port ", OMPort)
            print(error)
            return
        }
        
        do {
            try mySocket.write( from: message)
            print("message written : " + message)
        } catch let error {
            print("Cannot write to socket")
            print(error)
        }
    }
    @objc func dummy(_ any: Any?) {
        //do nothing
    }
    @objc func startSession(_ sender: NSMenuItem) { //sends startSession - projectName on port 2122
        
        if( !(sender.parent!.menu!.items.filter({$0.title.range(of: sender.title) != nil}).isEmpty) ) {
            return; //we cannot start an active session since there is already one with this project
        }
        // create TCP connection and send the string "startSession - projectName
        let message: String = "start@" + sender.title //sender.title is the project name
        //print(message)
        send(message: message)
        
        sessionStarted(sender.title)//now the session was started
    }
    
    @objc func stopSession(_ sender : NSMenuItem) {
        let title = sender.title
        let projName = String(title[title.index(title.startIndex, offsetBy: 9) ..< title.endIndex])
        let message = "stop@" + projName
        send(message: message)
        statusItem.menu!.removeItem(sender)
    }
    
    @objc func quitAll(_ sender: Any?) {
        send(message: "quitAll")
        NSRunningApplication.current.terminate()
    }
    
    @objc func quit(_ sender : Any?) {
        send(message: "quit")
        NSRunningApplication.current.terminate()
    }
    
    func sessionStarted(_ title: String) { //to call when Local.startSession is called
        let menu = statusItem.menu!
        
        //add the new session
        let session = NSMenuItem(title: "\t00:00 - " + title, action: #selector(AppDelegate.stopSession(_:)), keyEquivalent: "")
        menu.insertItem(session, at: 1)
        
        RunLoop.current.add(Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true, block: { (t) in
            //update the title to include the correct time
            print("timer was triggered")
            let item = session
            var title = item.title
            let projName = String(title[title.index(title.startIndex, offsetBy: 9) ..< title.endIndex])
            let time = String(title[title.index(title.startIndex, offsetBy: 1) ..< title.index(title.startIndex, offsetBy: 6)])
            //get the time
            var min = Int(String(time[time.index(time.startIndex, offsetBy: 3) ..< time.endIndex ]))!
            var hour = Int(String(time[time.startIndex ..< time.index(time.startIndex, offsetBy: 2)]))!
            if( min < 59){
                min = min + 1
            } else {
                min = 0
                hour = hour + 1
            }
            //build the title back
            title = "\t"
            if(hour < 10) {
                title = title + "0"
            }
            title = title + String(hour) + ":"
            if(min < 10) {
                title = title + "0"
            }
            title = title + String(min) + " - " + projName
            
            item.title = title
            
        }), forMode: RunLoop.Mode.common)
    }
    
    func sessionStopped(_ name: String) { //to call after Local.stopSession
        let item = statusItem.menu!.items.filter({$0.title.range(of: name) != nil}).first
        if (item == Optional.none) {
            print("Can't find session to stop")
            return;
        }
        statusItem.menu!.removeItem(item!)
    }
    
    //ENTRY POINT OF APPLICATION
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named:"StatusBarButtonImage")
            //button.action = #selector(printQuote(_:))
        }

        var path = Bundle.main.bundleURL
        path.deleteLastPathComponent()
        path = path.appendingPathComponent("settings")
        
        do {
            let data = try Data(contentsOf: path, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? Dictionary<String, AnyObject>
            thisPort = jsonResult!["menuBarPort"] as! Int
            OMPort = jsonResult!["OMPort"] as! Int32
            
        } catch let err {
            print("Cannot read settings file")
            print(err)
        }

        constructMenu();
        
        let secondThread = ServerThread()
        secondThread.setPort(thisPort)
        secondThread.start();
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func constructMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title:"Active Sessions:", action: #selector(AppDelegate.dummy(_:)), keyEquivalent : ""))
        menu.addItem(NSMenuItem.separator())
        let startStopSession = NSMenuItem(title: "Start Session", action: Optional.none, keyEquivalent: "s")
        menu.addItem(startStopSession)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Close MenuBar", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "Quit Office Manager", action: #selector(AppDelegate.quitAll(_:)), keyEquivalent: "q"))
        
        let projectSelection = NSMenu()
        menu.setSubmenu(projectSelection, for: startStopSession)
        statusItem.menu = menu
        
        updateProjectsSubmenu(projectSelection)
    }
    
}

class ServerThread : Thread { //listen on port 2121 and react
    
    var port : Int = 0
    
    func setPort(_ number: Int){
        port = number
    }
    
    override func main () {
        let mySocket: Socket
        
        do {
            mySocket = try Socket.create(family: .inet6, type: .stream, proto: .tcp)
          //  mySocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
            print("now listening ...")
            try mySocket.listen(on: port)
        } catch let error {
            print("Cannot create socket")
            print(error)
            return
        }
        
        while(true) { //keep waiting for many connections
            do{
                let client = try mySocket.acceptClientConnection()
                print("connection accepted")
                let s = try client.readString()
                if( s != Optional.none) {
                    print(s!)
                    if( s == "quit") {
                        let app = NSApplication.shared.delegate as! AppDelegate //AppDelegate
                        DispatchQueue.main.async { //do this in the main thread. Cannot close from secondary thread
                            app.quit(Optional.none)
                        }
                        return;
                    }
                    messageHandling(s!) //this will handle the message
                }
            } catch let error {
                print("Cannot do proper connection")
                print(error)
            }
        }//end while
    }// end func main
}
