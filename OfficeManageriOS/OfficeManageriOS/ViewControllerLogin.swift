//
//  ViewControllerLogin.swift
//  OfficeManageriOS
//
//  Created by Ivo Maffei on 31/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import UIKit

class ViewControllerLogin: UIViewController {
    
    // MARK: - Fields
    @IBOutlet var deviceIDLable: UILabel!
    @IBOutlet var userInput: UITextField!
    @IBOutlet var passwordInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceIDLable.text = "DeviceId:\n" + User.id.description
        if(!User.needRegister) {
            print("let's go")
            //set a timer so the function is triggered after we exit viewDidLoad()
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (t) in
                self.performSegue(withIdentifier: "ToMainUI", sender: self)
                })
        }
    }
    
    // MARK: - Actions
    @IBAction func Login(_ sender: Any) {
        User.register(myUser: userInput.text!, password: passwordInput.text!)
        print("done registering")
        if(!User.needRegister) {
            print("let's go")
                performSegue(withIdentifier: "ToMainUI", sender: self)
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
