//
//  LandingViewController.swift
//  #saunalyfe WatchKit Extension
//
//  Created by Dan Hogan on 4/14/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit
import WatchKit

class LandingInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var startButton: WKInterfaceButton!
    
    @IBAction func handleStartButtonSelected() {
        WKInterfaceController.reloadRootPageControllers(
            withNames: [ "WorkoutInterfaceController" ],
            contexts: [],
            orientation: WKPageOrientation.vertical,
            pageIndex: 0
        )
    }
    
}
