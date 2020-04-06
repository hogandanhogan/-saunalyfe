//
//  AlertControllerHandler.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 4/4/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit

class AlertControllerHandler {

    class func showError(presentingViewController: UIViewController, error: Error?) {
        let ac = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(okAction)
        presentingViewController.present(ac, animated: true, completion: nil)
    }
    
}
