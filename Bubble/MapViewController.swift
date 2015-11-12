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
    
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification,
                object: managedObjectContext, queue: NSOperationQueue.mainQueue()) {
                notification in
                    if let dictionary = notification.userInfo {
                        print(dictionary["inserted"])
                        print(dictionary["deleted"])
                        print(dictionary["updated"])
                    }
                    
                    if self.isViewLoaded() {
                        self.updateLocations()
                    }
            }
        }
    }
    var locations = [Location]()
    
    @IBAction func showUser() {
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction func showLocations() {
        let region = regionForAnnotations(locations)
        mapView.setRegion(region, animated: true)
    }
    
    func showLocationDetails(sender: UIButton) {
        performSegueWithIdentifier("EditLocation", sender: sender)
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
        
        if !locations.isEmpty {
            showLocations()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Location else {
            return nil
        }
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.animatesDrop = false
            annotationView.tintColor = UIColor(white: 0.0, alpha: 0.5)
            if #available(iOS 9.0, *) {
                annotationView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            } else {
                // Fallback on earlier versions
            }
            let rightButton = UIButton(type: .DetailDisclosure)
            rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)
            annotationView.rightCalloutAccessoryView = rightButton
        } else {
            annotationView.annotation = annotation
        }
        let button = annotationView.rightCalloutAccessoryView as! UIButton
        if let index = locations.indexOf(annotation as! Location) {
            button.tag = index
        }
        
        return annotationView
    }
}

extension MapViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}
