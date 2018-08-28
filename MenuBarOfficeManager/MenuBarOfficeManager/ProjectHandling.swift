//
//  ProjectHandling.swift
//  MenuBarOfficeManager
//
//  Created by Ivo Maffei on 22/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Foundation
import Cocoa

func getProjects() -> [String] {
    
    var path = Bundle.main.bundleURL
    path.deleteLastPathComponent()
    path = path.appendingPathComponent("Projects.db")

    var result : [String] = []
    
    do {
        let data = try Data(contentsOf: path, options: .mappedIfSafe)
        let jsonStrings = splitJsons(String(data: data, encoding: String.Encoding.utf8)!)
        for string in jsonStrings {
            let jsonResult = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .mutableLeaves) as? Dictionary<String, AnyObject>
            let prName = jsonResult!["name"] as! String
            let number = jsonResult!["number"] as! Int
            var name : String = ""
            if( number < 10) {
                name = "[0000"
            } else if (number < 100) {
                name = "[000"
            } else if (number < 1000) {
                name = "[00"
            } else if (number < 10000) {
                name = "[0"
            } else {
                name = "["
            }
            name = name + String(number) + "] - " + prName
            result.append(name)
        }
    } catch let err {
        print("Cannot read projects file")
        print(err)
        return []
    }
    
    return result
}

func splitJsons(_ data: String) -> [String] {
    var result :[String] = []
    var depth = 0
    var json : String = "" //comulative json
    
    let open : Character = "{"
    let close : Character = "}"
    
    for i in data.indices {//go through characters
        
        if( data[i] == open) {
          depth = depth + 1
        }
        if(depth != 0) {
            json = json + String(data[i])
        }
        if( data[i] == close) {
            depth = depth - 1
        }
        if(depth == 0 && json != "") {
            result.append(json)
            json = "";
        }
    }
    return result;
}

func updateProjectsSubmenu(_ menu : NSMenu) {
    
    menu.removeAllItems()
    let projects = getProjects()
    print(projects)
    var i = 1
    for title in projects {
        menu.addItem(NSMenuItem(title: title, action: #selector(AppDelegate.startSession(_: )), keyEquivalent: String(i)))
        i = i + 1
    }
}
