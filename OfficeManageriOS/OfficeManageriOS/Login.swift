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
    static var host : String = "127.0.0.1"
    static var port : Int32 = 27017
    
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
        var path = getResourcesPath()
        path = path.appendingPathComponent("device")
    
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
        
        path = getResourcesPath().appendingPathComponent("settings")
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
            let path = getResourcesPath().appendingPathComponent("device")
            do {
                try myUser.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
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
