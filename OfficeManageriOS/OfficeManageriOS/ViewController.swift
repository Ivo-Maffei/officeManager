//
//  ViewController.swift
//  OfficeManageriOS
//
//  Created by Ivo Maffei on 24/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import UIKit

class ViewController: UIViewController , UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: Properties
    @IBOutlet var time: UILabel!
    @IBOutlet var projectPicker: UIPickerView!
    @IBOutlet var categoryPicker: UIPickerView!
    @IBOutlet var playBtn: UIButton!
    @IBOutlet var syncBtn: UIButton!
    @IBOutlet var sessionDesc: UITextField!
    
    var projects : [String] = []
    var categories : [String] = []
    var timer = Timer(timeInterval: 1, repeats: false, block: {(t) in }) //dummy timer initialised
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        projects = getProjects()
        categories = getCategories()
        projectPicker.delegate = self
        projectPicker.dataSource = self
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
       // User.register(myUser: "puci", password: "1234")
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView == projectPicker) {
            return projects.count;
        } else {
            return categories.count;
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if( pickerView == projectPicker) {
            return projects[row]
        } else {
            return categories[row]
        }
    }

    //MARK: Actions
    var start = true //if button is start or stop sessison
    var date : String = ""
    @IBAction func startStopSession(_ sender: UIButton) {
        if(start) { //start session
            projectPicker.isUserInteractionEnabled = false
            projectPicker.alpha = 0.5
            categoryPicker.isUserInteractionEnabled = false
            categoryPicker.alpha = 0.5
            sessionDesc.isUserInteractionEnabled = false
            sessionDesc.alpha = 0.5
            sender.setTitle("Convalida sessione", for: UIControl.State.normal)
            time.text = "00:00"; //reset timer
            timer = startTimer(time)
            start = false
            
            //get date of start session
            let now = Date()
            date = now.description(with: nil)
            let space = date.firstIndex(of: " ")!
            let space2 = date.lastIndex(of: " ")!
            date = String(date[date.startIndex ..< space] + "T" + date[date.index(after: space) ..< space2])
            
        } else { //stop session
            timer.invalidate()
            projectPicker.isUserInteractionEnabled = true
            projectPicker.alpha = 1
            categoryPicker.isUserInteractionEnabled = true
            categoryPicker.alpha = 1
            sessionDesc.isUserInteractionEnabled = true
            sessionDesc.alpha = 1
            
            let pr = projects[projectPicker.selectedRow(inComponent: 0)]
            let cat = categories[categoryPicker.selectedRow(inComponent: 0)]
            var result = ""
            for c in sessionDesc.text! { //sanitze the string
                if(c == Character("\\") || c == Character("\"") ) {
                    result = result + "\\"
                }
                result = result + String(c)
            }
            convalidaSessione(user: "puci", project: pr, category: cat, description: result, time: time.text!, date: date)
            
            sender.setTitle("Inizia sessione", for: UIControl.State.normal)
            start = true
        }
    }
    
    
    @IBAction func SyncAll(_ sender: Any) {
        sync(what: "categories")
        sync(what: "projects")
        sync(what: "sessions")
    }
    
}

func startTimer(_ time : UILabel) -> Timer{
  let timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true, block: { (t) in
        //update the title to include the correct time
        print("timer was triggered")
        var text = time.text!
        var hour = Int(text[text.startIndex ..< text.index(text.startIndex,offsetBy: 2)])!
        var min = Int(text[text.index(text.startIndex, offsetBy: 3) ..< text.endIndex])!
        print(hour)
        print(min)
        if (min < 59) {
            min = min + 1
        } else {
            min = 0
            hour = hour + 1
        }
        
        text = ""
        if(hour < 10 ) {
            text = "0"
        }
        text = text + String(hour) + ":"
        if(min < 10 ) {
            text = text + "0"
        }
        text = text + String(min)
        
        time.text = text
        
    })
    timer.tolerance = 15.0
    
    return timer;
}
