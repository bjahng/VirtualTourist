//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by admin on 2/12/18.
//  Copyright © 2018 DoughDoughTech. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class AlbumViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin!
    var coordinates: CLLocationCoordinate2D!
    var dataController:DataController!
    var photos = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
//        collectionView.delegate = self
//        collectionView.dataSource = self
        
        noImagesLabel.isHidden = true
        
        updateNewCollectionButtonState(isEnabled: false)
        
        generateMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
    
    func updateNewCollectionButtonState(isEnabled: Bool) {
        newCollectionButton.isEnabled = isEnabled
    }
    
    func generateMap() {
        let annotation = MKPointAnnotation()
        let regionRadius: CLLocationDistance = 10000
        annotation.coordinate = coordinates
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius * 2.0, regionRadius * 1.0)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(annotation)
    }
    
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
}

//extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        return 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        return 0
//    }
//
//}

