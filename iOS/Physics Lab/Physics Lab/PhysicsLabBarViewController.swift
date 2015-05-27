//
//  PhysicsLabBarViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/10/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class PhysicsLabBarViewController: UITabBarController, CartHistoryDisplayDelegate {

    var bleD : BleDevice?
    var bleLand : BlueToothNeighborhood?

    var recordButton : UIBarButtonItem?
    var actionButton : UIBarButtonItem?
    
    override func viewWillAppear(animated: Bool) {
        
        recordButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "action")
        actionButton = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "record")
        self.navigationItem.setRightBarButtonItems([recordButton!,actionButton!], animated: true)

        
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
            
            if let graph = i as? GraphViewController {
                graph.bleD = bleD
            }
            
            bleD!.pl?.history.delegate = self
            
        }
        
    }
    
    func record()
    {
          bleD!.pl?.history.clearRecord()
          bleD!.pl?.history.arm(bleD!.pl!.cartPosition)
          display(bleD!.pl!.history)
    }
    
    
    func display(sender : CartHistory)
    {
        if sender.recording {

        let x = NSNumberFormatter()
        x.numberStyle = .DecimalStyle
        x.minimumFractionDigits = 1
        x.maximumFractionDigits = 1
        self.navigationItem.title =  x.stringFromNumber(sender.lastTimeSeconds)
        }
        else
        {
            if sender.armed {
                self.navigationItem.title = "Armed"
                
            }
            else
            {
                self.navigationItem.title = ""
            }
        }
    }
    
    func action()
    {
        
    }
    
    
}
