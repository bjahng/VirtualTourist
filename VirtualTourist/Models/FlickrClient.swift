//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by admin on 2/14/18.
//  Copyright © 2018 DoughDoughTech. All rights reserved.
//

import UIKit

class FlickrClient: UIViewController {
    
    var methodParameters: [String:AnyObject] = [
        Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey as AnyObject,
        Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
        Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL as AnyObject,
        Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
        Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
    ]
    
    // MARK: Flickr API
    
    func getRandomPhotoPage(_ pin: Pin, completionHandler: @escaping (_ page: Int?, _ success: Bool, _ error: String?) -> Void) {

        methodParameters[Constants.FlickrParameterKeys.Lat] = pin.latitude as AnyObject
        methodParameters[Constants.FlickrParameterKeys.Long] = pin.longitude as AnyObject
        let session = URLSession.shared
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters as [String:AnyObject])
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)

        let task = session.dataTask(with: request) { (data, response, error) in

            guard (error == nil) else {
                completionHandler(nil, false, error?.localizedDescription)
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, false, "Request returned a status code other than 2xx!")
                return
            }

            guard let data = data else {
                completionHandler(nil, false, "No data was returned by the request!")
                return
            }

            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandler(nil, false, "Could not parse JSON: '\(data)'")
                return
            }

            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandler(nil, false, "Flickr API returned an error: \(parsedResult)")
                    return
            }

            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(nil, false, "Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }

            guard let numOfPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                completionHandler(nil, false, "Cannot find number of pages")
                return
            }

            let pageLimit = min(numOfPages, 50)
            let randomPage = pageLimit == 1 ? 1 : Int(arc4random_uniform(UInt32(pageLimit)))

            completionHandler(randomPage, true, nil)
        }
        task.resume()
    }
    
    func getRandomPhotosFromPage(_ pin: Pin, withPageNumber: Int, completionHandler: @escaping (_ photosURL:[String]?, _ success: Bool, _ error: String?) -> Void) {

        methodParameters[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject
        let session = URLSession.shared
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters as [String:AnyObject])
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        
        let task = session.dataTask(with: request){ (data, response, error) in
            
            guard (error == nil) else {
                completionHandler(nil, false, error?.localizedDescription)
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(nil, false, "Request returned a status code other than 2xx!")
                return
            }

            guard let data = data else {
                completionHandler(nil, false, "No data was returned by the request!")
                return
            }

            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandler(nil, false, "Could not parse JSON: '\(data)'")
                return
            }

            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                    completionHandler(nil, false, "Flickr API returned an error: \(parsedResult)")
                    return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(nil, false, "Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            guard let total = photosDictionary[Constants.FlickrResponseKeys.Total] as? String else {
                completionHandler(nil, false, "Cannot find key '\(Constants.FlickrResponseKeys.Total)' in \(photosDictionary)")
                return
            }
            
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                completionHandler(nil, false, "Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            // Get 15 random photos
            var selected = [Int]()
            var photosURL = [String]()
            let perPage = min(Int(total)!, 90)
            let numberOfPhotos = min(Int(total)!, 15)
            if numberOfPhotos > 0 {
                for _ in 0...numberOfPhotos - 1 {
                    var random = Int(arc4random_uniform(UInt32(perPage)))
                    while selected.contains(random) {
                        random = Int(arc4random_uniform(UInt32(perPage)))
                    }
                    selected.append(random)
                    let photo = photosArray[random] as [String:AnyObject]
                    if let photoUrl = photo[Constants.FlickrResponseKeys.MediumURL] as? String {
                        photosURL.append(photoUrl)
                    }
                }
            }
            completionHandler(photosURL, true, nil)
        }
        task.resume()
    }
    
    func getSinglePhoto(_ photoURL: String, completionHandler: @escaping (_ imageData: Data?, _ success: Bool) -> Void) {
        let session = URLSession.shared
        let imageURL = URL(string: photoURL)
        let request: URLRequest = URLRequest(url: imageURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if error != nil {
                completionHandler(nil, false)
            } else {
                completionHandler(data, true)
            }
        }
        task.resume()
    }
    
    // MARK: Helper for Escaping Parameters in URL
    
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                let stringValue = "\(value)"
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}
