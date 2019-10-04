//
//  MapViewController.swift
//  SODASample
//
//  Created by Frank A. Krueger on 8/10/14.
//  Copyright (c) 2014 Socrata, Inc. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var data: [[String: Any]]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        update(withData: data, animated: true)
    }
    
    func update(withData data: [[String: Any]]!, animated: Bool) {
        
        // Remember the data because we may not be able to display it yet
        self.data = data
        
        if (!isViewLoaded) {
            return
        }
        
        // Clear old annotations
        if mapView.annotations.count > 0 {
            let ex = mapView.annotations
            mapView.removeAnnotations(ex)
        }
        
        // Longitude and latitude limits
        var minLatitude : CLLocationDegrees = 90.0
        var maxLatitude : CLLocationDegrees = -90.0
        var minLongitude : CLLocationDegrees = 180.0
        var maxLongitude : CLLocationDegrees = -180.0

        // Create annotations for the data
        var anns : [MKAnnotation] = []
        for item in data {
            
            // item["incident_location"] != nil
            guard let lat = (item["latitude"] as? NSString)?.doubleValue,
                let lon = (item["longitude"] as? NSString)?.doubleValue else { continue }
            
            minLatitude = min(minLatitude, lat)
            maxLatitude = max(maxLatitude, lat)
            minLongitude = min(minLongitude, lon)
            maxLongitude = max(maxLongitude, lon)

            let a = MKPointAnnotation()
            a.title = item["event_clearance_description"] as? String ?? ""
            a.coordinate = CLLocationCoordinate2D (latitude: lat, longitude: lon)
            a.subtitle = item["at_scene_time"] as? String ?? item["event_clearance_date"] as? String ?? ""
            anns.append(a)
        }
        
        // Set the annotations and center the map
        if (anns.count > 0) {
            mapView.addAnnotations(anns)
            let span = MKCoordinateSpan(latitudeDelta: maxLatitude - minLatitude, longitudeDelta: maxLongitude - minLongitude)
            let center = CLLocationCoordinate2D(latitude: (maxLatitude + minLatitude)/2.0, longitude: (maxLongitude + minLongitude)/2.0)
            let region = MKCoordinateRegion(center: center, span: span)
//            let r = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: lata*w, longitude: lona*w), 2000, 2000)
            mapView.setRegion(region, animated: animated)
        }
    }
}

