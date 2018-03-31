//
//  UIViewControllerExtension.swift
//  VirtualTourist
//
//  Created by admin on 2/21/18.
//  Copyright © 2018 DoughDoughTech. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func displayAlert(_ message: String, dismissButtonTitle: String = "OK") {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: dismissButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
