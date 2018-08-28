//
//  messageHandling.swift
//  MenuBarOfficeManager
//
//  Created by Ivo Maffei on 22/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Foundation
import Cocoa

func messageHandling(_ msg : String) {
    
    let app = NSApplication.shared.delegate as! AppDelegate //AppDelegate method
    let atIndex = msg.firstIndex(of: "@");
    var command: String = ""
    if( atIndex != Optional.none) {
        command = String(msg[msg.startIndex ..< atIndex!]);
    } else {
        command = msg;
    }
    switch command {
    case "update":
        updateProjectsSubmenu(app.statusItem.menu!.item(withTitle: "Start Session")!.submenu!)
        print("updating menu")
    case "start":
        print("session starting")
        let title = String(msg[msg.index(atIndex!, offsetBy: 1) ..< msg.endIndex])
        app.sessionStarted(title)
    case "stop":
        print("stopping session")
        let title = String(msg[msg.index(atIndex!, offsetBy: 1) ..< msg.endIndex])
        app.sessionStopped(title)
    default:
        print("unknown message ", msg)
    }
}
