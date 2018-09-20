//
//  ViewControllerOptions.swift
//  OfficeManageriOS
//
//  Created by Ivo Maffei on 01/09/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import UIKit

class ViewControllerOptions: UIViewController {
    
    // MARK: - Fields
    @IBOutlet var deviceIdLable: UILabel!
    @IBOutlet var hostText: UITextField!
    @IBOutlet var portText: UITextField!
    var mainUI : ViewController? = Optional.none

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hostText.text = User.host
        portText.text = String(User.port)
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - Actions
    @IBAction func goToRegister(_ sender: Any) {
        self.mainUI!.goRegister = true
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func saveOptions(_ sender: Any) {
        let path = getResourcesPath().appendingPathComponent("settings")
        let settings = "host:" + hostText.text! + "\nport:" + portText.text!
        User.host = hostText.text!
        User.port = Int32(portText.text!)!
        do{
            try settings.write(to: path, atomically: false, encoding: String.Encoding.utf8)
        } catch {
            let alert = UIAlertController(title: "Settings error", message: "There was an error with the settings file" + error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
