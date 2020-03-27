//
//  ViewController.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 3/21/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit
import HealthKit

private let kWorkoutsButtonHeight: CGFloat = 40.0

class ViewController: UIViewController {

    let store = HKHealthStore()
    
    let label = UILabel()
    let workoutsButton = UIButton()
    
    var workouts = [ HKWorkout ]()

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

        view.addGradientLayer()
        
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
        
        view.addSubview({
            workoutsButton.setTitleColor(UIColor.white, for: .normal)
            //workoutsButton.backgroundColor = UIColor(red: 236.0/255.0, green: 77.0/255.0, blue: 92.0/255.0, alpha: 1.0)
            workoutsButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
            workoutsButton.layer.cornerRadius = kWorkoutsButtonHeight/2.0
            workoutsButton.clipsToBounds = true
            workoutsButton.alpha = 0.0
            workoutsButton.addTarget(self, action: #selector(handleWorkoutsButtonSelected(_:)), for: .touchUpInside)
                        
            return workoutsButton
            }()
        )
        
        loadSaunaLyfeWorkouts() {
            if self.workouts.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: 0.5.dispatchTimeInSeconds) {
                    self.workoutsButton.setTitle("\(self.workouts.count) Sessions", for: .normal)
                    self.workoutsButton.frame = CGRect(x: 0.0, y: self.view.frame.height - 100.0, width: self.workoutsButton.intrinsicContentSize.width + 50.0, height: kWorkoutsButtonHeight)
                    self.workoutsButton.center.x = self.view.center.x
                    let wokroutButtonGradientLayer = CAGradientLayer()
                    let bottomColor = UIColor(red: 236.0/255.0, green: 77.0/255.0, blue: 92.0/255.0, alpha: 1.0).cgColor
                    let topColor = UIColor(red: 124.0/255.0, green: 44.0/255.0, blue: 116.0/255.0, alpha: 1.0).cgColor
                    wokroutButtonGradientLayer.colors = [ topColor, bottomColor  ]
                    wokroutButtonGradientLayer.frame = self.workoutsButton.bounds
                    wokroutButtonGradientLayer.locations = [ 0.0, 1.0 ]
                    self.workoutsButton.layer.insertSublayer(wokroutButtonGradientLayer, at: 0)

                    UIView.animate(withDuration: 0.5) {
                        self.workoutsButton.alpha = 1.0
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handlePermissions()
    }
    
    //MARK:- Action Handlers
    
    @objc func handleWorkoutsButtonSelected(_ sender: UIButton) {
        present(WorkoutsViewController(workouts: workouts), animated: true, completion: nil)
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
    
    //MARK:- Convenience
    
    func loadSaunaLyfeWorkouts(completion: @escaping (() -> ())) {
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .other)
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates:
            [workoutPredicate, sourcePredicate])
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: compound,
            limit: 0,
            sortDescriptors: [ sortDescriptor ]) { query, samples, error in
                DispatchQueue.main.async {
                    guard let samples = samples as? [ HKWorkout ], error == nil else {
                        completion()
                        return
                    }
                    
                    self.workouts = samples
                    completion()
                }
        }
        
        HKHealthStore().execute(query)
    }

}

extension UIView {
    
    func addGradientLayer() {
        let layer = CAGradientLayer()
        let topColor = UIColor(red: 0.0/255.0, green: 36.0/255.0, blue: 245.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor(red: 140.0/255.0, green: 240.0/255.0, blue: 220.0/255.0, alpha: 1.0).cgColor
        layer.colors = [ topColor, bottomColor ]
        layer.locations = [ 0.0, 1.0 ]
        layer.frame = self.frame
        self.layer.insertSublayer(layer, at: 0)
    }
    
}

extension Double {
    var dispatchTimeInSeconds: DispatchTime {
        get {
            return DispatchTime.now() + Double(Int64(self * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        }
    }
}
