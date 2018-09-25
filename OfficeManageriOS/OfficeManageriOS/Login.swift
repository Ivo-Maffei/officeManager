//
//  Login.swift
//  OfficeManageriOS
//
//  Created by Ivo Maffei on 30/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Foundation
import UIKit

class User {
    
    static var id : UUID = UUID()
    static var user : String = "@@none@@"
    static var needRegister : Bool = true
    static var host : String = "79.2.254.77"
    static var port : Int32 = 27018
    
    static func initialise()  throws {//get device id
        let thisDevice = UIDevice.current
        
        for _ in 0...100 {
            if(thisDevice.identifierForVendor == Optional.none) {
                continue;
            }
            id = thisDevice.identifierForVendor!
            print(id.description)
            break;
        }
        
        //check that all file exists; otherwise create
        let fileManager = FileManager.default
        do{
        var pathString = getResourcesPath().appendingPathComponent("device.data").path
        if(!(fileManager.fileExists(atPath: pathString))) {
            try user.write(toFile: pathString, atomically: false ,encoding: String.Encoding.utf8)
        }
        pathString = getResourcesPath().appendingPathComponent("settings.data").path
        if(!(fileManager.fileExists(atPath: pathString))) {
//            fileManager.createFile(atPath: pathString, contents: data, attributes: nil)
            try ("host:" + host + "\nport:" + String(port)).write(toFile:pathString, atomically: false ,encoding: String.Encoding.utf8)
        }
        pathString = getResourcesPath().appendingPathComponent("Categories.db").path
        if(!(fileManager.fileExists(atPath: pathString))) {
            try "\n".write(toFile: pathString, atomically: false, encoding: String.Encoding.utf8)
        }
        pathString = getResourcesPath().appendingPathComponent("Projects.db").path
        if(!(fileManager.fileExists(atPath: pathString))) {
            try "\n".write(toFile: pathString, atomically: false, encoding: String.Encoding.utf8)
        }
        pathString = getResourcesPath().appendingPathComponent("SessionsSync.db").path
        if(!(fileManager.fileExists(atPath: pathString))) {
            try "\n".write(toFile: pathString, atomically: false, encoding: String.Encoding.utf8)
        }
        } catch{
            throw LoginError.DeviceFileError(error.localizedDescription)
        }
        
        var path = getResourcesPath().appendingPathComponent("device.data")
        do {
            let data = try Data(contentsOf: path, options: .mappedIfSafe)
            user = String(data: data, encoding: String.Encoding.utf8)!
        } catch {
            throw LoginError.DeviceFileError(error.localizedDescription)
        }
        if(user.last == Optional(Character("\n"))) {
            user = String(user.dropLast())
        }
        print(user)
        if( user != "@@none@@") {
            needRegister = false;
        }
        
        path = getResourcesPath().appendingPathComponent("settings.data")
        do {
            let str = try String(data: Data(contentsOf: path, options: .mappedIfSafe), encoding: String.Encoding.utf8)!
            let newLine = str.firstIndex(of: Character("\n"))!
            let line1 = String(str[str.startIndex ..< newLine])
            let line2 = String(str[str.index(after: newLine) ..< str.endIndex])
            print(line1)
            print(line2)
            host = String(line1[line1.index(after: line1.firstIndex(of: Character(":"))!) ..< line1.endIndex])
            port = Int32(line2[line2.index(after: line2.firstIndex(of: Character(":"))!) ..< line2.endIndex])!
            print(host)
            print(port)
        } catch {
            print("can't write to settings file", error.localizedDescription)
            throw LoginError.SettingsFileError(error.localizedDescription)
        }
    }
    
    static func register (myUser: String, password: String)  throws { //register this device to the given user
        print("in register")
        let message = myUser + ":" + password + "@registerDevice@" + UIDevice.current.name + "@" + id.description
        print("message to be sent: ", message)
        let response = try send(message)
        
        print("server Response: ", response)
        if(response == "fail") {
            needRegister = true
            throw LoginError.ServerError("Server replyied with fail")
        } else {
            User.user = myUser;
            let path = getResourcesPath().appendingPathComponent("device.data")
            do {
                try myUser.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                print("can't write to device file", error.localizedDescription)
                throw LoginError.DeviceFileError(error.localizedDescription)
            }
            needRegister = false
        }
    }
    
    static func connect() throws -> String {
        var result = "fail"
        let message = id.description + "@connect"
        result = try send(message) //server will try to connect with these credentials
        return result
    }
    
    
    
}

enum LoginError: Error {
    case ServerError(String)
    case DeviceFileError(String)
    case SettingsFileError(String)
}
