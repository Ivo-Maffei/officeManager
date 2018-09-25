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
    @IBOutlet var backBtn: UIButton!
    
    var canGoOptions = false;
    var mustGoOptions = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try User.initialise()
        } catch {
            let alert = UIAlertController(title: "Initialization Error", message: "There was a problem during the startup.\nError: " + error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        deviceIDLable.text = "DeviceId:\n" + User.id.description
        if(!User.needRegister) {
            print("going to main view")
            //set a timer so the function is triggered after we exit viewDidLoad()
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (t) in
                self.performSegue(withIdentifier: "ToMainUI", sender: self)
                })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(canGoOptions) {
            backBtn.isHidden = false
            canGoOptions = false
        } else {
            backBtn.isHidden = true
        }
    }
    
   
    
    // MARK: - Actions
    @IBAction func Login(_ sender: Any) {
        var fail = false;
        var message :String = ""
        do {
            try User.register(myUser: userInput.text!, password: passwordInput.text!)
        } catch LoginError.ServerError(let  errmessage ){
            fail = true
            message = "server error: " + errmessage
        } catch LoginError.DeviceFileError(let errmessage) {
            fail = true
            message = "file error: " + errmessage
        } catch LocalError.SocketError( let errmessage) {
            fail = true
            message = "network error: " + errmessage
        }catch {
            fail = true
            message = error.localizedDescription
        }
        if(fail){
            let alert = UIAlertController(title: "Registration Error", message: "There was a problem during the registration.\n Check you internet connection and try again.\nError: " + message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        if(!User.needRegister) {
            performSegue(withIdentifier: "ToMainUI", sender: self)
        }
    }
    
    @IBAction func goOptions(_ sender: Any) {
        mustGoOptions = true
        performSegue(withIdentifier: "ToMainUI", sender: self)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let mainUI : ViewController = segue.destination as! ViewController
        mainUI.loginUI = Optional(self);
        if(mustGoOptions) {
            mainUI.goOptions = true;
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
