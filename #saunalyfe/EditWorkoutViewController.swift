//
//  EditWorkoutViewController.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 4/4/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit
import HealthKit

class EditWorkoutViewController: UIViewController, UITextFieldDelegate {

    typealias EditWorkoutCompletionType = ((Int) -> ())
    
    let workout: HKWorkout
    let completionHandler: EditWorkoutCompletionType
    
    let cancelButton = UIButton()
    let gridView = UIView()
    let textField = UITextField()
    let saveButton = RoundButton()

    var canSave: Bool {
        get {
            let woroutDuration = workout.endDate.timeIntervalSince1970 - workout.startDate.timeIntervalSince1970
            if let text = textField.text, let int = Int(text) {
                return (int * 60) <= Int(woroutDuration)
            }
            return false
        }
    }

    init(workout theWorkout: HKWorkout, completionHandler theCompletionHandler: @escaping EditWorkoutCompletionType) {
        workout = theWorkout
        completionHandler = theCompletionHandler
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview({
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            blurView.frame = view.frame
            
            return blurView
            }()
        )

        view.addSubview({
            gridView.frame = CGRect(x: 35.0, y: 60.0, width: view.frame.width - 50.0, height: 150.0)
        
            return gridView
            }()
        )
        
        view.addSubview({
            textField.keyboardType = .numberPad
            textField.textAlignment = .center
            let placeholder = NSAttributedString(string: "Change duration from start (min)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)])
            textField.attributedPlaceholder = placeholder
            textField.tintColor = UIColor.white
            textField.textColor = UIColor.white
            textField.font = UIFont.systemFont(ofSize: 26.0, weight: .thin)
            textField.addTarget(self, action: #selector(handleFieldEdtingChanged(_:)), for: .editingChanged)
            textField.frame = CGRect(
                x: 0.0,
                y: 60.0 + gridView.frame.height + 60.0,
                width: view.frame.width,
                height: textField.intrinsicContentSize.height
            )
            toggleSaveButton()

            return textField
            }()
        )
        
        view.addSubview({
            saveButton.setTitle("Save", for: .normal)
            saveButton.frame = CGRect(
                x: 0.0,
                y: 70.0 + gridView.frame.height + textField.frame.height + 70.0,
                width: self.saveButton.intrinsicContentSize.width + 50.0,
                height: kRoundButtonHeight
            )
            saveButton.center.x = view.center.x
            saveButton.addTarget(self, action: #selector(handleSaveButtonSelected(_:)), for: .touchUpInside)
            
            return saveButton
            }()
        )

        view.addSubview({
            cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.setTitleColor(UIColor.white, for: .normal)
            cancelButton.addTarget(self, action: #selector(handleCancelButtonSelected(_:)), for: .touchUpInside)
            cancelButton.frame = CGRect(
                x: 0.0,
                y: 60.0 + gridView.frame.height + textField.frame.height + saveButton.frame.height + 120.0,
                width: self.saveButton.intrinsicContentSize.width + 70.0,
                height: kRoundButtonHeight
            )
            cancelButton.center.x = view.center.x

            return cancelButton
            }()
        )
        
        let end = min(workout.startDate.timeIntervalSince1970 + 3600.0, workout.endDate.timeIntervalSince1970)
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: Date(timeIntervalSince1970: end),
            options: HKQueryOptions()
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let heartRateType: HKQuantityType   = HKQuantityType.quantityType(forIdentifier: kHeartRateQuantityTypeIdentifier)!

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: 0,
            sortDescriptors: [ sortDescriptor ]) { query, samples, error in
                DispatchQueue.main.async {
                    if let samples = samples  as? [ HKQuantitySample ] {
                        let maxHeartRate = samples.map({$0.quantity.doubleValue(for: kHeartRateUnit)}).max() ?? 1.0
                        let minHeartRate = samples.map({$0.quantity.doubleValue(for: kHeartRateUnit)}).min() ?? 1.0
                        
                        self.view.addSubview({
                            let maxLabel = UILabel()
                            maxLabel.text = "\(Int(maxHeartRate))"
                            maxLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
                            maxLabel.textColor = UIColor.white
                            maxLabel.frame = CGRect(
                                x: 2.0,
                                y: self.gridView.frame.minY - 7.0,
                                width: maxLabel.intrinsicContentSize.width,
                                height: maxLabel.intrinsicContentSize.height
                            )

                            return maxLabel
                            }()
                        )
                        
                        self.view.addSubview({
                            let minLabel = UILabel()
                            minLabel.text = "\(Int(minHeartRate))"
                            minLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
                            minLabel.textColor = UIColor.white
                            minLabel.frame = CGRect(
                                x: 2.0,
                                y: self.gridView.frame.maxY - 7.0,
                                width: minLabel.intrinsicContentSize.width,
                                height: minLabel.intrinsicContentSize.height
                            )


                            return minLabel
                            }()
                        )
                        
                        let range = maxHeartRate - minHeartRate
                        let workoutStart = self.workout.startDate.timeIntervalSince1970
                        let duration = end - workoutStart
                        
                        var increments = Int((duration / 60.0) / 5.0)
                        if increments == 0 {
                            increments = 1
                        }
                        for i in 0...increments - 1 {
                            self.view.addSubview({
                                let label = UILabel()
                                label.text = "\(i * 5)"
                                label.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
                                label.textColor = UIColor.white
                                label.frame = CGRect(
                                    x: self.gridView.frame.minX + self.gridView.frame.width * CGFloat(i)/CGFloat(increments),
                                    y: 70.0 + self.gridView.frame.height,
                                    width: label.intrinsicContentSize.width,
                                    height: label.intrinsicContentSize.height
                                )

                                return label
                                }()
                            )
                        }
                        
                        for sample in samples {
                            self.gridView.addSubview({
                                let sampleView = UIView()
                                sampleView.backgroundColor = UIColor.red
                                let diameter: CGFloat = 3.0
                                sampleView.layer.cornerRadius = diameter/2.0
                                sampleView.clipsToBounds = true
                                let sampleTime = sample.endDate.timeIntervalSince1970
                                let percentTime = (sampleTime - workoutStart) / duration
                                let percentHeartRate = (sample.quantity.doubleValue(for: kHeartRateUnit) - minHeartRate) / range
                                let height = self.gridView.frame.height
                                sampleView.frame = CGRect(
                                    x: self.gridView.frame.width * CGFloat(percentTime),
                                    y: height - (height * CGFloat(percentHeartRate)),
                                    width: diameter,
                                    height: diameter
                                )
                                
                                return sampleView
                                }()
                            )
                        }
                    }
                }
        }
        
        HKHealthStore().execute(query)
        
        textField.becomeFirstResponder()
    }
    
    //MARK:- Action Handlers
    
    @objc func handleFieldEdtingChanged(_ sender: UITextField) {
        toggleSaveButton()
    }
    
    @objc func handleSaveButtonSelected(_ sender: UIButton) {
        guard let text = textField.text, let int = Int(text), canSave else { return }
        dismiss(animated: true, completion: nil)
        completionHandler(int)
    }
    
    @objc func handleCancelButtonSelected(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Convenienve
    
    func toggleSaveButton() {
        saveButton.alpha = canSave ? 1.0 : 0.5
    }
}
