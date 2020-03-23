//
//  InterfaceController.swift
//  #saunalyfe WatchKit Extension
//
//  Created by Dan Hogan on 3/21/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var bottomButton: WKInterfaceButton!
    
    lazy var healthStore = HKHealthStore()
    var timer: Timer?
    var timerRunning = false
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWorkoutRecoveryNotification(_:)),
            name: NSNotification.Name.init(rawValue: kWorkoutRecoveryNotificationKey),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK- Action Handlers
    
    @IBAction func handleBottomButonSelected() {
        timerRunning = !timerRunning
        timer?.invalidate()
        timer = nil
        bottomButton.setTitle(timerRunning ? "Done" : "Start")
        if timerRunning {
            setTimer()
                        
            let start = Date()
            let config = HKWorkoutConfiguration()
            config.locationType = .indoor
            config.activityType = .other
            do {
                session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
                builder = session?.associatedWorkoutBuilder()
                builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
                builder?.beginCollection(withStart: start) { success, error in }
                session?.startActivity(with: start)
            } catch let error {
                self.presentAlert(string: error.localizedDescription)
            }
        } else {
            heartRateLabel.setText("--")
            timeLabel.setText("0:00")
            session?.end()
            builder?.endCollection(withEnd: Date()) { finished, error in
                if let error = error {
                    self.presentAlert(string: error.localizedDescription)
                } else {
                    self.builder?.finishWorkout() { workout, error in
                        if let workout = workout {
                            self.healthStore.save(workout) { success, error in }
                        } else {
                            self.presentAlert(string: error?.localizedDescription ?? "Error saving workout")
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleTimerFired(_ timer: Timer) {
        if let start = session?.startDate?.timeIntervalSince1970 {
            let time = timer.fireDate.timeIntervalSince1970 - start
            let hours = Int(time) / 3600
            let minutes = Int(time) / 60 % 60
            let seconds = Int(time) % 60
            if hours > 0 {
                if minutes > 9 {
                    timeLabel.setText(String(format: "%02i:%02i:%02i", hours, minutes, seconds))
                } else {
                    timeLabel.setText(String(format: "%01i:%02i:%02i", hours, minutes, seconds))
                }
            } else {
                if minutes > 9 {
                    timeLabel.setText(String(format: "%02i:%02i", minutes, seconds))
                } else {
                    timeLabel.setText(String(format: "%01i:%02i", minutes, seconds))
                }
            }
            
            startHeartRateQuery()
        }
    }

    //MARK:- Convenience
    
    func setTimer() {
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(handleTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
    }
    
    func presentAlert(string: String) {
        let action = WKAlertAction(title: "OK", style: .default) {}
        self.presentAlert(
            withTitle: string,
            message: nil,
            preferredStyle: .alert,
            actions: [ action ]
        )
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        if let sample = samples.last, timerRunning {
            if type == .heartRate {
                let rate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                heartRateLabel.setText(String(Int(rate)))
            }
        }
    }
    
    private func startHeartRateQuery() {
        let quantityTypeIdentifier: HKQuantityTypeIdentifier = .heartRate
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { query, samples, deletedObjects, queryAnchor, error in
            guard let samples = samples as? [HKQuantitySample] else { return }
            self.process(samples, type: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(
            type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
            predicate: devicePredicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler
        )
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    //MARK:- WKExtensionDelegate
    
    @objc func handleWorkoutRecoveryNotification(_ notification: Notification) {
        healthStore.recoverActiveWorkoutSession { session, error in
            if let session = session {
                session.resume()
                self.timer?.invalidate()
                self.timerRunning = true
                self.setTimer()
                self.bottomButton.setTitle("Done")
            } else {
                self.presentAlert(string: error?.localizedDescription ?? "Error recovering workout session")
            }
        }
    }
}
