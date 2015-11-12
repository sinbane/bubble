//
//  Functions.swift
//  Bubble
//
//  Created by Sinbane on 9/27/15.
//  Copyright © 2015 Sinbane. All rights reserved.
//

import Foundation
import Dispatch // Grand Central Dispatch

// free function
func afterDelay(seconds: Double, closure: () -> ()) { // Void -> Void, (parameter list) -> return type
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC))) // nanoseconds
    dispatch_after(when, dispatch_get_main_queue(), closure)
}

let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    return paths[0]
}()
