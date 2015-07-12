//
//  DashboardViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/15/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController {
    
    var bleD : BleDevice?

    private struct DashboardText {
        static let accelX = "Acceleration X"
        static let accelY = "Acceleration Y"
        static let accelZ = "Acceleration Z"
        static let gravityUnits = "G"
        
        static let velocity = "Velocity"
        static let velocityUnits = "m/s"
    }
    
    @IBOutlet weak var gaugeView: GaugeView!
    @IBOutlet weak var gaugeView2: GaugeView!
    @IBOutlet weak var gaugeView3: GaugeView!
    
    private enum Graph1Modes {
        case accelX
        case accelY
        case accelZ
        case velocity
    }
    
    private var graph1Mode : Graph1Modes = .accelZ
    

    // MARK: - Viewcontroller lifecycle
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "physicsLabDisplay", name: PLNotifications.PLUpdatedKinematicData, object: bleD!.pl!)
        
        graph1MakeSelection()
        
        gaugeView2.name = DashboardText.accelX
        gaugeView2.gaugeUnits = DashboardText.gravityUnits
        gaugeView2.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))

    
        gaugeView3.name = DashboardText.accelZ
        gaugeView3.gaugeUnits = DashboardText.gravityUnits
        gaugeView3.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - View Controller Display + Action Function

    func physicsLabDisplay() {
        if view.bounds.height < view.bounds.width {
            graph1Selection?.selectedSegmentIndex = 3
            graph1MakeSelection()
        }
        
        updateGraph1Display()
        
        gaugeView2?.needleValue = (current: Double(bleD!.pl!.acceleration.y), min: Double(bleD!.pl!.minAcceleration.y), max: Double(bleD!.pl!.maxAcceleration.x))
        gaugeView3?.needleValue = (current: Double(bleD!.pl!.acceleration.z), min: Double(bleD!.pl!.minAcceleration.z), max: Double(bleD!.pl!.maxAcceleration.z))
        
    }

    
    @IBAction func resetMaxMin(sender: UIButton) {
        bleD!.pl?.resetMax()
    }
    
    func updateGraph1Display()
    {
        if let pl = bleD?.pl
        {
            switch graph1Mode {
            case .accelX:
                gaugeView.needleValue = (current: Double(pl.acceleration.x), min:Double(pl.minAcceleration.x), max: Double(bleD!.pl!.maxAcceleration.x))
            case .accelY:
                gaugeView.needleValue = (current: Double(pl.acceleration.y), min:Double(pl.minAcceleration.y), max: Double(bleD!.pl!.maxAcceleration.y))

            case .accelZ:
                gaugeView.needleValue = (current: Double(pl.acceleration.z), min:Double(pl.minAcceleration.z), max:Double(bleD!.pl!.maxAcceleration.z))

            case .velocity:
                gaugeView.needleValue = (current: Double(pl.velocity), min: Double(pl.maxMinVelocity.min), max:Double(pl.maxMinVelocity.max))

            }
        }
    }
    
    
    @IBOutlet weak var graph1Selection: UISegmentedControl!
    
    @IBAction func graph1MakeSelection() {
        // I dont think that this can happen
        if graph1Selection == nil {
            return
        }
        
        switch graph1Selection!.selectedSegmentIndex {
        case 0:
            graph1Mode = .accelX
            gaugeView.name = DashboardText.accelX
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))
        case 1:
            graph1Mode = .accelY
            gaugeView.name = DashboardText.accelY
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))
        case 2:
            graph1Mode = .accelZ
            gaugeView.name = DashboardText.accelZ
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))

        case 3:
            graph1Mode = .velocity
            gaugeView.name = DashboardText.velocity
            gaugeView.gaugeUnits = DashboardText.velocityUnits
            gaugeView.gaugeValueRange = (min: bleD!.pl!.velocityRange.min, max:bleD!.pl!.velocityRange.max)
        default:
            graph1Mode = .accelZ
            gaugeView.name = DashboardText.accelZ
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.LSM9DSOAccelRange), max:Double(bleD!.pl!.LSM9DSOAccelRange))
        }
    }
}
