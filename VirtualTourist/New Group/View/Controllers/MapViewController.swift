//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by admin on 2/8/18.
//  Copyright © 2018 DoughDoughTech. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var dataController:DataController!
    var pins = [Pin]()
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.action(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)
        
        persistMapLocation()
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadPins()
    }
    
    @objc func action(gestureRecognizer:UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
        }
        try? dataController.viewContext.save()
    }
    
    func persistMapLocation() {
        defaults.synchronize()
        
        if let region = defaults.object(forKey: "MapViewRegion") as! [CLLocationDegrees]! {
            
            let center = CLLocationCoordinate2D(latitude: region[0], longitude: region[1])
            let span = MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])
            let region = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(region, animated: true)
            mapView.regionThatFits(region)
        }
    }
    
    func loadPins() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        if let fetchResults = try? dataController.viewContext.fetch(fetchRequest) as! [Pin] {
            pins = fetchResults
            var pinAnnotations = [MKPointAnnotation]()
            for pin in pins {
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate.latitude = CLLocationDegrees(pin.latitude)
                newAnnotation.coordinate.longitude = CLLocationDegrees(pin.longitude)
                pinAnnotations.append(newAnnotation)
            }
            mapView.addAnnotations(pinAnnotations)
        }
    }
    
    //MARK: mapView data model methods
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region: [CLLocationDegrees] = [self.mapView.region.center.latitude, self.mapView.region.center.longitude, self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta]
        defaults.set(region, forKey: "MapViewRegion")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let controller = storyboard!.instantiateViewController(withIdentifier: "AlbumViewController") as! AlbumViewController
        controller.coordinates = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        navigationController?.pushViewController(controller, animated: true)
    }

}
