//
//  Local.swift
//  OfficeManageriOS
//
//  Created by Ivo Maffei on 24/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Foundation

func getResourcesPath() -> URL {
    let path = Bundle.main.bundleURL
    return path
    
}

func getProjects() -> [String] {
    var pr = getProjectsWithId(server: true)
    func first( tuple: (String,String)) -> String {
        return tuple.0
    }
    return (pr.map(first))
}

func getProjectsWithId(server: Bool) -> [(String, String)] {
    if(server) {
        sync(what: "projects")
    }
    var path = getResourcesPath()
    path = path.appendingPathComponent("Projects.db")
    
    var result : [(String, String)] = []
    
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
            let id = jsonResult!["_id"] as! Int
            result.append((name,String(id)))
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

func getCategories() -> [String] {
    sync(what: "categories")
    
    var path = getResourcesPath()
    path = path.appendingPathComponent("Categories.db")
    
    var result : [String] = ["None"]
    
    do {
        let data = try Data(contentsOf: path, options: .mappedIfSafe)
        let jsonStrings = splitJsons(String(data: data, encoding: String.Encoding.utf8)!)
        for string in jsonStrings {
            let jsonResult = try JSONSerialization.jsonObject(with: string.data(using: String.Encoding.utf8)!, options: .mutableLeaves) as? Dictionary<String, AnyObject>
            result.append(jsonResult!["_id"] as! String)
        }
    } catch let err {
        print("Cannot read categories file")
        print(err)
        return []
    }
    
    return result;
}

func convalidaSessione( user:String, project: String, category: String, description : String, time: String, date: String) {
    //id is hnseconds from 00:00 of 01/01/0001 AD UTC
    //Date().timeIntervalSinceReferenceDate is seconds since 00:00 of 01/01/2001 AD UTC
    //So number of hnsecods from 00:00 of 01/01/0001 AD UTC to 00:00 of 01/01/2001 AD UTC is
    //631139040000000000
    let id = Int((Date().timeIntervalSinceReferenceDate + 63113904000)*10000000)
    
    //get projID from projectName: read from file Projects.db
    let list = getProjectsWithId(server: false)
    var prId = ""
    for t in list {
        if(t.0 == project) {
            prId = t.1
            break;
        }
    }
    
    //create string representing the JSON of the new session to sync [so add "status": "new"]
    let jsonStr = "\n{\n\t\"_id\": " + String(id) + ",\n\t\"category\": " + "\"" + category + "\",\n\t" + "\"dateTime\": \"" + date + "\",\n\t\"description\": \"" + description + "\",\n\t\"duration\": \"" + time + "\",\n\t\"project\": " + prId + ",\n\t\"status\": \"new\",\n\t\"tantum\": false,\n\t\"user\": \"" + user + "\"\n}"
    
    //write this to the SessionsSync.db file
    let file = getResourcesPath().appendingPathComponent("SessionsSync.db")
    
    do {
        let fileHandle = try FileHandle(forWritingTo: file)
        fileHandle.seekToEndOfFile()
        fileHandle.write(jsonStr.data(using: String.Encoding.utf8)!)
        fileHandle.closeFile()
    } catch let error {
        print("something went wrong with sessions file")
        print(error)
    }
    
    do {
        let data = try Data(contentsOf: file, options: .mappedIfSafe)
        print(String(data: data, encoding: String.Encoding.utf8)!)
    } catch {
        
    }
    
    sync(what:"sessions")
}

func send(_ message: String) -> String { //sends message and return server response
    var response = Optional("OK")
    let address = "127.0.0.1"
    let port :Int32 = 27018
    do{
        let socket = try Socket.create()
        try socket.connect(to: address, port: port)
        try socket.write(from: message)
        print("message sent: ",message )
        response = try socket.readString()
    }catch {
        print(error)
    }
    if(response == Optional.none) {
        return "fail"
    } else {
        return response!
    }
}

func sync( what: String) {
    var message = "puci"
    let password = "1234" //get user password
    var file = getResourcesPath() //file to write to
    print("now syncing")
    switch what {
    case "projects":
        message = message + ":" + password + "@get@projects"
        file.appendPathComponent("Projects.db")
    case "categories":
        message = message + ":" + password + "@get@categories"
        file.appendPathComponent("Categories.db")
    case "passwords":
        message = message + "@get@passwords"
        file.appendPathComponent("pass")
    case "sessions":
        message = message + ":" + password + "@newSession@"
        let path = getResourcesPath().appendingPathComponent("SessionsSync.db")
        file.appendPathComponent("SessionsSync.db")
        do{
            let data = try Data(contentsOf: path, options: .mappedIfSafe)
            let string = String(data: data, encoding: String.Encoding.utf8);
            message = message + string!
        } catch {
            print(error)
        }
    default:
        print("error I don't know what to sync")
    }
    
    print("now sending message")
    let response = send(message)
    print("response received: ", response)
    if( response == "fail" ) {
        //display message that we can't sync
        return;
    }
    do {
        try response.write(to: file, atomically: false, encoding: String.Encoding.utf8)
    }catch {
        print(error)
    }
}
