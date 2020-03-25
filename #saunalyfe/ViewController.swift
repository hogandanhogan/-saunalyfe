//
//  ViewController.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 3/21/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    let store = HKHealthStore()
    
    let label = UILabel()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [ .portrait ]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundNotification(_:)),
            name: UIScene.didEnterBackgroundNotification, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForegroundNotification(_:)),
            name: UIScene.didActivateNotification, object: nil
        )
        
        let layer = CAGradientLayer()
        let topColor = UIColor(red: 0.0/255.0, green: 36.0/255.0, blue: 245.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor(red: 140.0/255.0, green: 247.0/255.0, blue: 198.0/255.0, alpha: 1.0).cgColor
        layer.colors = [ topColor, bottomColor ]
        layer.locations = [ 0.0, 1.0 ]
        layer.frame = view.frame
        view.layer.insertSublayer(layer, at: 0)
        
        view.addSubview({
            label.textColor = UIColor.white
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 21.0, weight: .thin)
            label.alpha = 0.0
            label.textAlignment = .center
            let width = view.frame.width - 40.0
            label.frame = CGRect(x: 0.0, y: 80.0, width: width, height: 0.0)
            label.center.x = view.center.x
            
            return label
            }()
        )
        
        view.addSubview({
            let imageView = UIImageView()
            imageView.image = UIImage(named: "sauna")!
            let width = view.frame.width / 2.0
            imageView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: width)
            imageView.center = view.center

            return imageView
            }()
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handlePermissions()
    }
    
    //MARK:- Notification
    
    @objc func handleForegroundNotification(_ notification: Notification) {
        handlePermissions()
    }
    
    @objc func handleBackgroundNotification(_ notification: Notification) {
        label.alpha = 0.0
    }
    
    func handlePermissions() {
        let types = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .heartRate)!])
        store.requestAuthorization(toShare: types, read: types) { success, error in
            let workoutAuthorized = self.store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
            let heartAuthorized = self.store.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!) == .sharingAuthorized
            DispatchQueue.main.async {
                if success, workoutAuthorized, heartAuthorized {
                    self.label.text = "You are ready to live the #saunalyfe! Use the watch app to record a sauna session."
                } else {
                    self.label.text = "Please enable all health permissions to start living the #saunalyfe"
                }
                self.label.sizeToFit()

                DispatchQueue.main.asyncAfter(deadline: 0.5.dispatchTimeInSeconds) {
                    UIView.animate(withDuration: 0.5) {
                        self.label.alpha = 1.0
                    }
                }
            }
        }
    }
}

extension Double {
    var dispatchTimeInSeconds: DispatchTime {
        get {
            return DispatchTime.now() + Double(Int64(self * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        }
    }
}
