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

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var pin: Pin!
    var coordinates: CLLocationCoordinate2D!
    var dataController: DataController!
    var photos = [Photo]()
    let spaceBetweenItems: CGFloat = 5.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Flow Layout
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = spaceBetweenItems
        flowLayout.minimumLineSpacing = spaceBetweenItems
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        noImagesLabel.isHidden = true
        newCollectionButton.isEnabled = false
        
        generateMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getPhotos { (thereArePhotos) in
            if !thereArePhotos {
                DispatchQueue.main.async {
                    self.noImagesLabel.isHidden = false
                }
            }
        }
    }
    
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        for photo in photos {
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
        newCollectionButton.isEnabled = false
        photos.removeAll()
        
        getPhotosFromFlickr { (success) in
            if success {
                self.collectionView.reloadData()
                
                // Scroll to top of collectionView
                self.collectionView.setContentOffset(CGPoint(x:0,y:0), animated: false)
                self.newCollectionButton.isEnabled = true
            }
        }
    }
    
    func generateMap() {
        let annotation = MKPointAnnotation()
        let regionRadius: CLLocationDistance = 10000
        annotation.coordinate = coordinates
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius * 2.0, regionRadius * 1.0)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.addAnnotation(annotation)
    }

    func getPhotos(completionHandler: @escaping (_ thereArePhotos: Bool) -> Void) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        // Get photos from core data
        if let fetchResults = try? dataController.viewContext.fetch(fetchRequest) as! [Photo] {
            photos = fetchResults
            
            if photos.count == 0 {
                getPhotosFromFlickr(completionHandler: { (success) in
                    if success {
                        if self.photos.count == 0 {
                            completionHandler(false)
                        } else {
                            self.collectionView.reloadData()
                            self.newCollectionButton.isEnabled = true
                        }
                    } else {
                        self.displayAlert("Error downloading photos from Flickr")
                    }
                })
            } else {
                self.newCollectionButton.isEnabled = true
            }
        } else {
            displayAlert("Error getting photos from core data")
        }
    }

    func getPhotosFromFlickr(completionHandler: @escaping (_ success: Bool) -> Void) {
        FlickrClient.sharedInstance().getRandomPhotoPage(pin) { (pageNumber, success, error) in
            if success {
                FlickrClient.sharedInstance().getRandomPhotosFromPage(self.pin, withPageNumber: pageNumber!, completionHandler: { (photoID, success, error) in
                    if success {
                        DispatchQueue.main.async {
                            for id in photoID! {
                                let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: self.dataController.viewContext) as! Photo
                                photo.photoID = id
                                photo.pin = self.pin
                                self.photos.append(photo)
                            }
                            try? self.dataController.viewContext.save()
                            completionHandler(true)
                        }
                    } else {
                        self.displayAlert(error!)
                    }
                })
            } else {
                self.displayAlert(error!)
            }
        }
    }
    
}

extension AlbumViewController: MKMapViewDelegate {
    
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

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CollectionViewCell
        let photo = photos[indexPath.item]
        
        if let photoData = photo.imageData {
            cell.imageView.image = UIImage(data: photoData as Data)
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
        } else {
            cell.imageView.contentMode = .center
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
            
            FlickrClient.sharedInstance().getSinglePhoto(photo.photoID!, completionHandler: { (data, success) in
                if success {
                    DispatchQueue.main.async {
                        cell.imageView.image = UIImage(data: data!)
                        cell.imageView.contentMode = .scaleAspectFill
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                        photo.imageData = data
                        try? self.dataController.viewContext.save()
                    }
                }
            })
        }
        return cell
    }

    // Delete photo if selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if newCollectionButton.isEnabled {
            let index = indexPath.row
            let photo = photos[index]
            if photo.imageData != nil {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
                photos.remove(at: index)
                collectionView.deleteItems(at: [indexPath])
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width / 3 - spaceBetweenItems
        let height = width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spaceBetweenItems
    }
}
