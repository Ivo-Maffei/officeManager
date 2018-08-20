//
//  main.swift
//  SystemIdleTime
//
//  Created by Ivo Maffei on 20/08/18.
//  Copyright © 2018 Ivo Maffei. All rights reserved.
//

import Foundation

public func SystemIdleTime() -> Double? {
    var iterator: io_iterator_t = 0
    defer { IOObjectRelease(iterator) }
    guard IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHIDSystem"), &iterator) == KERN_SUCCESS else {
        return nil }
    
    let entry: io_registry_entry_t = IOIteratorNext(iterator)
    defer { IOObjectRelease(entry) }
    guard entry != 0 else { return nil }
    
    var unmanagedDict: Unmanaged<CFMutableDictionary>? = nil
    defer { unmanagedDict?.release() }
    guard IORegistryEntryCreateCFProperties(entry, &unmanagedDict, kCFAllocatorDefault, 0) == KERN_SUCCESS else { return nil }
    guard let dict = unmanagedDict?.takeUnretainedValue() else { return nil }
    
    let key: CFString = "HIDIdleTime" as CFString
    let value = CFDictionaryGetValue(dict, Unmanaged.passUnretained(key).toOpaque())
    let number: CFNumber = unsafeBitCast(value, to: CFNumber.self)
    var nanoseconds: Int64 = 0
    guard CFNumberGetValue(number, CFNumberType.sInt64Type, &nanoseconds) else { return nil }
    let interval = Double(nanoseconds) / Double(NSEC_PER_SEC)
    
    return interval
}

func writeToFile(content: String) {
    //get path and write a file
    let mainBundle = Bundle.main
    var path = mainBundle.bundleURL //get url of the folder where this executabble is
    //print(mainBundle.bundlePath)
    let file = "SystemPause" //file where to write
    path = path.appendingPathComponent(file) //now path is url of where to write
    let data = Data(content.utf8) //convert string to UTF-8
    do {
        try data.write(to: path)
    } catch {
        print("error: Cannot write to file")
    }
}

let time = SystemIdleTime();
var string = "nil";
if (time != Optional.none){
    string = String(format:"%.1f", time!);
}
writeToFile(content: string);
