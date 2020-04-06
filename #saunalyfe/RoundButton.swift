//
//  RoundButton.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 4/4/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit

public let kRoundButtonHeight: CGFloat = 40.0
let kActionColor = UIColor(red: 236.0/255.0, green: 77.0/255.0, blue: 92.0/255.0, alpha: 1.0)

class RoundButton: UIButton {

    init() {
        super.init(frame: .zero)
        setTitleColor(UIColor.white, for: .normal)
        setBackgroundImage(kActionColor.image(), for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        layer.cornerRadius = kRoundButtonHeight/2.0
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
