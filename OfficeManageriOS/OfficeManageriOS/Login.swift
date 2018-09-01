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
    static func initialise() {//get device id
        let thisDevice = UIDevice.current
     //   print(thisDevice.name)
//        print(thisDevice.model)
       // print(thisDevice.identifierForVendor)
        
        for _ in 0...100 {
            if(thisDevice.identifierForVendor == Optional.none) {
                continue;
            }
            id = thisDevice.identifierForVendor!
            print(id.description)
//            print(id.debugDescription)
            break;
        }
        var path = getResourcesPath()
        path = path.appendingPathComponent("device")
        do{
            let data = try Data(contentsOf: path, options: .mappedIfSafe)
            user = String(data: data, encoding: String.Encoding.utf8)!
            if(user.last! == Character("\n")) {
                user = String(user.dropLast())
            }
        } catch {
            print(error)
        }
        
        if( user != "@@none@@") {
            needRegister = false;
        }
    }
    
    static func register (myUser: String, password: String) { //register this device to the given user
        let message = myUser + ":" + password + "@registerDevice@" + id.description
        let response = send(message)
        
        print(response)
        if(response == "fail") {
            //show message
            needRegister = true
        } else {
            User.user = myUser;
            let path = getResourcesPath().appendingPathComponent("device")
            do {
                try myUser.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                print(error)
            }
            
            needRegister = false
        }
    }
    
    static func connect() -> String {
        var result = "fail"
        let message = id.description + "@connect"
        result = send(message) //server will try to connect with these credentials
        return result
    }
    
    
    
}
