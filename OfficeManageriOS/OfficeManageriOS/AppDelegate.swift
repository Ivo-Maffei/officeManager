//
//  AppDelegate.swift
//  OfficeManageriOS
//
//  Created by Ivo Maffei on 24/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        do {
            try User.initialise()
        } catch {
            //problem with files
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("enter background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("will terminate")
    }


}

/*
func time () {
    print(Date.timeIntervalBetween1970AndReferenceDate)
    
    let day = 60*60*24; //secondi al giorno
    var countLeap = 0
    for year in 1970 ... 2000 {
        if( year % 4 != 0) {
            continue
        } else if (year % 100 != 0) {
            countLeap = countLeap + 1
            continue
        } else if (year % 400 != 0) {
            continue
        } else {
            countLeap = countLeap + 1
            continue
        }
    }
    
    let ndays = 365 * 31 + countLeap
    let myTime = ndays * day
    print(myTime)
    
    let now2 = Date().timeIntervalSinceReferenceDate
    let now1 = Date().timeIntervalSince1970
    print("now from 2001")
    print(now2)
    print("now from 1970")
    print(now1)
    print("now from 2001 + time between 1970 and 2001")
    print(now2 + Double(myTime))
}

func now(hour : Int, min: Int) {
    
    let now = Date()
    print(now.description)
    print(now.timeIntervalSinceReferenceDate)
    
    let day = 60*60*24; //secondi al giorno
    var countLeap = 0
    for year in 2001 ... 2017 {
        if( year % 4 != 0) {
            continue
        } else if (year % 100 != 0) {
            countLeap = countLeap + 1
            continue
        } else if (year % 400 != 0) {
            continue
        } else {
            countLeap = countLeap + 1
            continue
        }
    }
    
    var ndays = 365 * 17 + countLeap //days till 1/1/2018
    ndays = ndays + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 24
    
    let myTime = ndays * day + 60 * 60 * hour + 60 * min
    
    print(myTime)
    print("since 1/1/1")
    print(myTime + 63113904000)
    //print(time)
}

func final() {
    let now = Date()
    print(now.description)
    print(Int((now.timeIntervalSinceReferenceDate + 63113904000)*10000000))
}
*/
