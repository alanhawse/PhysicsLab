//
//  DashboardViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/15/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController, PhysicsLabDisplayDelegate {
    
    var bleD : BleDevice?
    
    @IBOutlet weak var gaugeView: GaugeView!

    @IBOutlet weak var gaugeView2: GaugeView!
    
    @IBOutlet weak var gaugeView3: GaugeView!
    
    func physicsLabDisplay(sender: PhysicsLab) {
        
        if view.bounds.height < view.bounds.width {
            graph1Selection.selectedSegmentIndex = 3
            graph1MakeSelection()
        }
        
      updateGraph1Display()
        
        gaugeView2.needleValue = (current: Double(bleD!.pl!.acceleration.y), min: Double(bleD!.pl!.minAcceleration.y), max: Double(bleD!.pl!.maxAcceleration.y))
        gaugeView3.needleValue = (current: Double(bleD!.pl!.acceleration.z), min: Double(bleD!.pl!.minAcceleration.z), max: Double(bleD!.pl!.maxAcceleration.z))

    }
    

    override func viewDidAppear(animated: Bool) {
        bleD?.pl?.delegate = self
        graph1MakeSelection()
        
        gaugeView2.name = "Acceleration Y"
        gaugeView2.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))

    
        gaugeView3.name = "Acceleration Z"
        gaugeView3.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        bleD?.pl?.delegate = nil
    }
    
    enum Graph1Modes {
        case AccelX
        case AccelY
        case AccelZ
        case Velocity
    }
    
    @IBAction func resetMaxMin(sender: UIButton) {
        bleD!.pl?.resetMax()
    }
    
    func updateGraph1Display()
    {
        if let pl = bleD?.pl
        {
            switch graph1 {
            case .AccelX:
                gaugeView.needleValue = (current: Double(pl.acceleration.x), min:Double(pl.minAcceleration.x), max: Double(bleD!.pl!.maxAcceleration.x))
            case .AccelY:
                gaugeView.needleValue = (current: Double(pl.acceleration.y), min:Double(pl.minAcceleration.y), max: Double(bleD!.pl!.maxAcceleration.y))

            case .AccelZ:
                gaugeView.needleValue = (current: Double(pl.acceleration.z), min:Double(pl.minAcceleration.z), max:Double(bleD!.pl!.maxAcceleration.z))

            case .Velocity:
                gaugeView.needleValue = (current: Double(pl.velocity), min: Double(pl.maxMinVelocity.min), max:Double(pl.maxMinVelocity.max))

            }
        }
    }
    
    var graph1 : Graph1Modes = .AccelZ
    
    
    @IBOutlet weak var graph1Selection: UISegmentedControl!
    
    @IBAction func graph1MakeSelection() {
          
        switch graph1Selection.selectedSegmentIndex {
        case 0:
            graph1 = .AccelX
            gaugeView.name = "Acceleration X"
            
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))

            
        case 1:
            graph1 = .AccelY
            gaugeView.name = "Acceleration Y"
 
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))


        case 2:
            graph1 = .AccelZ
            gaugeView.name = "Acceleration Z"
  
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))

        case 3:
            graph1 = .Velocity
            gaugeView.name = "Velocity"
      
            gaugeView.gaugeValueRange = (min: bleD!.pl!.velocityRange.min, max:bleD!.pl!.velocityRange.max)

            
        default:
            graph1 = .AccelZ
            gaugeView.name = "Acceleration Z"

            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))


        }
        
    }
    
    
    
    
}
