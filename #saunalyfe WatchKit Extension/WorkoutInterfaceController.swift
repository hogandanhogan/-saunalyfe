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

class WorkoutInterfaceController: WKInterfaceController {

    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var doneButton: WKInterfaceButton!
    @IBOutlet weak var lockButton: WKInterfaceButton!
    
    lazy var healthStore = HKHealthStore()
    var timer: Timer?
    var locked = true
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    var heartReadings = [ Int ]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
                
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWorkoutRecoveryNotification(_:)),
            name: NSNotification.Name.init(rawValue: kWorkoutRecoveryNotificationKey),
            object: nil
        )
        
        handleLockState()
        
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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK- Action Handlers
    
    @IBAction func handleLockButtonSelected() {
        locked = !locked
        handleLockState()
    }
    
    @IBAction func handleDoneButtonSelected() {
        if locked {
            return
        }
        
        timer?.invalidate()
        timer = nil
        session?.end()
        builder?.endCollection(withEnd: Date()) { finished, error in
            func pop() {
                WKInterfaceController.reloadRootPageControllers(
                    withNames: [ "LandingInterfaceController" ],
                    contexts: [],
                    orientation: WKPageOrientation.vertical,
                    pageIndex: 0
                )
            }
            if let error = error {
                self.presentAlert(string: error.localizedDescription) {
                    pop()
                }
            } else {
                self.builder?.finishWorkout() { workout, error in
                    if let workout = workout {
                        self.healthStore.save(workout) { success, error in
                            if let error = error {
                                self.presentAlert(string: error.localizedDescription) {
                                    pop()
                                }
                            } else {
                                let action = WKAlertAction(title: "OK", style: .default) {
                                    pop()
                                }

                                let start = workout.startDate.timeIntervalSince1970
                                let end = workout.endDate.timeIntervalSince1970
                                let duration = (end - start).formattedTime

                                workout.averageHeartRate(healthStore: self.healthStore) { averageRate in
                                    let rateString = averageRate == nil ? "" : ", \(averageRate!) bpm"
                                    self.presentAlert(
                                        withTitle: "Workout saved",
                                        message: "\(duration)\(rateString)",
                                        preferredStyle: .alert,
                                        actions: [ action ]
                                    )
                                }
                            }
                        }
                    } else {
                        self.presentAlert(string: error?.localizedDescription ?? "Error saving workout") {
                            pop()
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleTimerFired(_ timer: Timer) {
        if let start = session?.startDate?.timeIntervalSince1970 {
            let text = (timer.fireDate.timeIntervalSince1970 - start).formattedTime
            timeLabel.setText(text)
            
            updateHeartRate()
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
    
    func presentAlert(string: String, completion: (() -> ())? = nil) {
        let action = WKAlertAction(title: "OK", style: .default) {
            completion?()
        }
        
        self.presentAlert(
            withTitle: string,
            message: nil,
            preferredStyle: .alert,
            actions: [ action ]
        )
    }
    
    private func updateHeartRate() {
        if let builder = builder {
            let statistics = builder.statistics(for: kHeartRateQuantityType)
            let value = statistics?.mostRecentQuantity()?.doubleValue(for: kHeartRateUnit)
            if let value = value {
                let value = Int(round(value))
                heartReadings.append(value)
                heartRateLabel.setText("\(value)")
            } else {
                heartRateLabel.setText("--")
            }
        }
    }
    
    func handleLockState() {
        doneButton.setAlpha(locked ? 0.5 : 1.0)
        lockButton.setTitle(locked ? "Unlock" : "Lock")
    }
    
    //MARK:- WKExtensionDelegate Notification
    
    @objc func handleWorkoutRecoveryNotification(_ notification: Notification) {
        healthStore.recoverActiveWorkoutSession { session, error in
            if let session = session {
                session.resume()
                self.timer?.invalidate()
                self.setTimer()
                self.doneButton.setTitle("Done")
            } else {
                self.presentAlert(string: error?.localizedDescription ?? "Error recovering workout session")
            }
        }
    }
}
