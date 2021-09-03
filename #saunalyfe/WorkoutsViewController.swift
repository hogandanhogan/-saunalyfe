//
//  WorkoutsViewController.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 3/25/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit
import HealthKit

private let kCellId = "CellId"

class WorkoutsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let healthStore = HKHealthStore()
    
    let closeButton = UIButton()
    
    let tableView = UITableView()
    var workouts: [ HKWorkout ]
    var heartRateDict = [ Int : Int ]()

    init(workouts theWorkouts: [ HKWorkout ]) {
        workouts = theWorkouts
        super.init(nibName: nil, bundle: nil)
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
            tableView.contentInset.top = 40.0
            tableView.dataSource = self
            tableView.delegate = self
            tableView.frame = view.frame
            tableView.backgroundColor = UIColor.clear
            tableView.separatorColor = UIColor.white
            tableView.tableFooterView = UIView()
            
            return tableView
            }()
        )
        
        view.addSubview({
            closeButton.setBackgroundImage(kActionColor.image(), for: .normal)
            closeButton.clipsToBounds = true
            closeButton.layer.cornerRadius = 25.0
            closeButton.frame = CGRect(x: 0.0, y: self.view.frame.height - 140.0, width: 50.0, height: 50.0)
            closeButton.center.x = view.center.x
            closeButton.addTarget(self, action: #selector(handleCloseButtonSelected(_:)), for: .touchUpInside)

            closeButton.addSubview({
                let imageView = UIImageView(image: UIImage(named: "xButton")!)
                imageView.contentMode = .center
                imageView.frame = CGRect(x: 0.0, y: 0.0, width: closeButton.frame.width, height: closeButton.frame.height)

                return imageView
                }()
            )

            return closeButton
            }()
        )
    }
    
    //MARK:- Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + 80.0
    }
    
    //MARK:- Action Handlers
    
    @objc func handleCloseButtonSelected(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    
    //MARK:- Tableview

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let _cell = tableView.dequeueReusableCell(withIdentifier: kCellId) {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: kCellId)
        }
        
        let row = indexPath.row
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.clear
        let workout = workouts[row]
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 24.0, weight: .medium)
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 21.0, weight: .thin)
        let start = workout.startDate.timeIntervalSince1970
        let end = workout.endDate.timeIntervalSince1970
        let duration = end - start
        cell.textLabel?.text = duration.formattedTime
        cell.detailTextLabel?.text = start.monthDayTime + " - " + end.timeOnly
        
        if let bpm = heartRateDict[row] {
            cell.textLabel!.text! += ", \(bpm) bpm"
        } else {
            workout.averageHeartRate(healthStore: healthStore) { averageRate in
                if let averageRate = averageRate {
                    self.heartRateDict[row] = averageRate
                    DispatchQueue.main.async {
                        tableView.reloadRows(at: [ indexPath ], with: .automatic)
                    }
                }
            }
        }
        
        return cell
    }
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Edit") { action, view, completion in
            let vc = EditWorkoutViewController(workout: self.workouts[indexPath.row]) { minutes in
                let workout = self.workouts[indexPath.row]
                let end = workout.startDate.timeIntervalSince1970 + (Double(minutes) * 60.0)
                self.edit(workout: workout, end: end)
            }
            
            self.present(vc, animated: true, completion: nil)
            completion(true)
        }
        
        action.backgroundColor = kActionColor

        return UISwipeActionsConfiguration(actions: [ action ])
    }
    
    //MARK:- Convenience
    
    func edit(workout: HKWorkout, end: TimeInterval) {
        let edit = HKWorkout(
            activityType: workout.workoutActivityType,
            start: workout.startDate,
            end: Date(timeIntervalSince1970: end),
            workoutEvents: workout.workoutEvents,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: workout.metadata
        )
        
        healthStore.save(edit) { success, error in
            if error == nil {
                self.healthStore.delete(workout) { finished, error in
                    if error == nil {
                        if let i = self.workouts.firstIndex(of: workout) {
                            DispatchQueue.main.async {
                                 self.workouts[i] = edit
                                 self.tableView.reloadRows(at: [ IndexPath(item: i, section: 0) ], with: .automatic)
                            }
                        }
                    } else {
                        AlertControllerHandler.showError(presentingViewController: self, error: error)
                    }
                }
            } else {
                AlertControllerHandler.showError(presentingViewController: self, error: error)
            }
        }
    }
}
