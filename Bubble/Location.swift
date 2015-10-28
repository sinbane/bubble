//
//  Location.swift
//  Bubble
//
//  Created by Sinbane on 9/27/15.
//  Copyright © 2015 Sinbane. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {

// Insert code here to add functionality to your managed object subclass
    
    // read-only computed properties
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title: String? {
        if locationDescription.isEmpty {
            return "(No Description)"
        } else {
            return locationDescription
        }
    }
    
    var subtitle: String? {
        return category
    }

}
