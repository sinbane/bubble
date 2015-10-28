//
//  MapViewController.swift
//  Bubble
//
//  Created by Sinbane on 10/21/15.
//  Copyright © 2015 Sinbane. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext!
    var locations = [Location]()
    
    @IBAction func showUser() {
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction func showLocations() {
        
    }
    
    func updateLocations() {
        mapView.removeAnnotations(locations)
        
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedObjectContext)
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Location]
        mapView.addAnnotations(locations)
    }
    
    func regionForAnnotations(annotations: [MKAnnotation]) -> MKCoordinateRegion {
        var region: MKCoordinateRegion
        switch annotations.count {
            case 0:
                region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
            case 1:
                let annotation = annotations[annotations.count - 1]
                region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
            default:
                var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
                var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
                for annotation in annotations {
                    topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
                    topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
                    bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
                    bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
                }
                let center = CLLocationCoordinate2D(
                    latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude)/2,
                    longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude)/2
                )
                
                let extraSpace = 1.1
                let span = MKCoordinateSpan(
                    latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace,
                    longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace
                )
                region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
    }
}

extension MapViewController: MKMapViewDelegate {
    
}
