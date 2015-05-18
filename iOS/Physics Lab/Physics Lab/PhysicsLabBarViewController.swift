//
//  PhysicsLabBarViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/10/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class PhysicsLabBarViewController: UITabBarController {

    var bleD : BleDevice?
    var bleLand : BlueToothNeighborhood?

    
    override func viewWillAppear(animated: Bool) {
        
        let cnt = viewControllers!.count
    
        for i in viewControllers! {
            if let pldvc = i as? PhysicsLabDataViewController
            {
                pldvc.bleD = bleD
            }
            
            if let plenviro = i as? EnviroViewController {
                plenviro.bleD = bleD
            }
            if let plenviro = i as? AdminViewController {
                plenviro.bleD = bleD
            }
            if let pldashboard = i as? DashboardViewController {
                pldashboard.bleD = bleD
            }
        }
        
    }
}
