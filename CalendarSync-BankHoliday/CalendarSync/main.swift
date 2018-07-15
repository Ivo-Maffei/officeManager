//
//  main.swift
//  CalendarSync-BankHoliday
//
//  Created by Ivo Maffei on 10/07/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Foundation
import EventKit

//creo date
let day = 24.0*60.0*60.0
let week = 7.0 * day
let month = 31.0 * day
let year = 364.0 * day
let startDate = Date() - 2.0*day
let endDate = Date() + day

//create event store
let eventStore = EKEventStore()

func createJSON() -> String {
    
    //get the calendars
    let calendariEventi = eventStore.calendars(for: EKEntityType.event)
//    let calendariRemainders = eventStore.calendars(for: EKEntityType.reminder)
    
    //creo predicato per query events
    let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendariEventi)
    
    //get the events
    let eventiCalendari = eventStore.events(matching: eventsPredicate)
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    
    //need to handle events which have same title
    //crete a dictionary of duplicates with thier count
    //use a set to check for duplicates; remove from set an item when you see it; if an item is not in the set is a duplicate
    var eventsSet : Set = Set(eventiCalendari.map({$0.title!}))
    var eventsDictionary : [String : Int] = [:]
    var eventsData : [(String,String,String)] = [] //this is the array I will add stuff to
    
    for ev in eventiCalendari {
        if(eventsSet.contains(ev.title!))  { //if there remove it and add nothing to title
            eventsSet.remove(ev.title!)
            eventsData.append( (ev.title!,formatter.string(from: ev.startDate), formatter.string(from: ev.endDate)) )
        } else { //we have a duplicate; increase the count in the dictionary
            var count = eventsDictionary[ev.title!, default: 0]
            count = count + 1
            eventsDictionary.updateValue(count, forKey: ev.title!)
            eventsData.append((ev.title! + String(count) ,formatter.string(from: ev.startDate), formatter.string(from: ev.endDate)) )
        }
    }
    
    //creates a JSON with list of events and then each event has its start/endDate
    var textToWrite = "{\n\t\"timestamp\" : \"" + formatter.string(from: Date()) + "\","
    textToWrite += "\n\t\"eventi\" : ["
    if (eventsData.count == 0) { textToWrite += "]\n}"; return textToWrite; }

    textToWrite += " \""+eventsData[0].0+"\""
    var first = true
    for s in eventsData { //if empty nothing happens
        if( first ) {
            first = false
            continue //skip fir iteration
        }
        textToWrite += ", "
        textToWrite += "\""+s.0+"\""
    }
    textToWrite += "]"
    
    //for each event write a list with start and end date
    for s in eventsData {
        textToWrite += ",\n\t"
        textToWrite += "\"" + s.0 + "\" : [\""
        textToWrite += s.1 + "\" ,\"" + s.2 + "\"]"
    }
    textToWrite += "\n}"
    
    return textToWrite
}

func writeToFile(content: String) {
    //get path and write a file
    let mainBundle = Bundle.main
    var path = mainBundle.bundleURL //get url of the folder where this executabble is
    //print(mainBundle.bundlePath)
    let file = "calendarFile" //file where to write
    path = path.appendingPathComponent(file) //now path is url of where to write
    let data = Data(content.utf8) //convert string to UTF-8
    do {
        try data.write(to: path)
    } catch {
        print("error: Cannot write to file")
    }
}

//check permissions
let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
if(status != EKAuthorizationStatus.authorized) { //if we have no permissions; ask them
    eventStore.requestAccess(to: EKEntityType.event, completion: { (access: Bool, error: Error?) in
        if(access == true) {
            writeToFile(content: createJSON())
        } else {
            print("error: Cannot sync Apple Calendar without permissions")
        }
    })
} else { //if we are already authorized
    writeToFile(content: createJSON())
}



