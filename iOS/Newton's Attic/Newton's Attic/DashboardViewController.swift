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
        static let accelX = "AX"
        static let accelY = "AY"
        static let accelZ = "AZ"
        static let gravityUnits = "G"
        
        static let velocity = "Velocity"
        static let velocityUnits = "m/s"

        static let position = "Position"
        static let positionUnits = "m"
    }
    
    @IBOutlet weak var gaugeView: GaugeView!
    @IBOutlet weak var gaugeView2: GaugeView!
    @IBOutlet weak var gaugeView3: GaugeView!
  
    /*
    private enum Graph1Modes {
        case accelX
        case accelY
        case accelZ
        case velocity
        case position
    }
    
    private var graph1Mode : Graph1Modes = .accelZ
    */
    

    // MARK: - Viewcontroller lifecycle
    
    override func viewDidAppear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedKinematicData, object: bleD!.pl!, queue: NSOperationQueue.mainQueue() ) { _ in self.physicsLabDisplay() }
        
        //graph1MakeSelection()
    
        gaugeView.name = DashboardText.velocity
        gaugeView.gaugeUnits = DashboardText.velocityUnits
        gaugeView.gaugeValueRange = (min: bleD!.pl!.pos.velocityRange.min, max:bleD!.pl!.pos.velocityRange.max)

        
        gaugeView2?.name = DashboardText.accelX
        gaugeView2?.gaugeUnits = DashboardText.gravityUnits
        gaugeView2?.gaugeValueRange = (min: -1 * Double(bleD!.pl!.accelerometer.range), max:Double(bleD!.pl!.accelerometer.range))

    
        gaugeView3?.name = DashboardText.accelZ
        gaugeView3?.gaugeUnits = DashboardText.gravityUnits
        gaugeView3?.gaugeValueRange = (min: -1 * Double(bleD!.pl!.accelerometer.range), max:Double(bleD!.pl!.accelerometer.range))
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - View Controller Display + Action Function

    func physicsLabDisplay() {
        
        /*
        if view.bounds.height < view.bounds.width {
            graph1Selection?.selectedSegmentIndex = 3
            graph1MakeSelection()
        }
*/
        
        //updateGraph1Display()
        gaugeView.needleValue = (current: bleD!.pl!.pos.velocity, min: bleD!.pl!.pos.minVelocity, max:bleD!.pl!.pos.maxVelocity)
        gaugeView2?.needleValue = (current: Double(bleD!.pl!.accelerometer.y), min: Double(bleD!.pl!.accelerometer.min.y), max: Double(bleD!.pl!.accelerometer.max.x))
        gaugeView3?.needleValue = (current: Double(bleD!.pl!.accelerometer.z), min: Double(bleD!.pl!.accelerometer.min.z), max: Double(bleD!.pl!.accelerometer.max.z))
        
    }

    
    @IBAction func resetMaxMin(sender: UIButton) {
        bleD!.pl?.resetMaxMin()
    }
    /*
    func updateGraph1Display()
    {
        if let pl = bleD?.pl
        {
            switch graph1Mode {
            case .accelX:
                gaugeView.needleValue = (current: pl.accelerometer.x, min: pl.accelerometer.min.x, max: pl.accelerometer.max.x)
            case .accelY:
                gaugeView.needleValue = (current: pl.accelerometer.y, min: pl.accelerometer.min.y, max: pl.accelerometer.max.y)

            case .accelZ:
                gaugeView.needleValue = (current: pl.accelerometer.z, min: pl.accelerometer.min.z, max:
                    pl.accelerometer.max.z)

            case .velocity:
                gaugeView.needleValue = (current: pl.pos.velocity, min: pl.pos.minVelocity, max:pl.pos.maxVelocity)

            }
        }
    }
    
    */
    /*
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
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.accelerometer.range), max:Double(bleD!.pl!.accelerometer.range))
        case 1:
            graph1Mode = .accelY
            gaugeView.name = DashboardText.accelY
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.accelerometer.range), max:Double(bleD!.pl!.accelerometer.range))
        case 2:
            graph1Mode = .accelZ
            gaugeView.name = DashboardText.accelZ
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.accelerometer.range), max:Double(bleD!.pl!.accelerometer.range))
        case 3:
            graph1Mode = .velocity
            gaugeView.name = DashboardText.velocity
            gaugeView.gaugeUnits = DashboardText.velocityUnits
            gaugeView.gaugeValueRange = (min: bleD!.pl!.pos.velocityRange.min, max:bleD!.pl!.pos.velocityRange.max)
        default:
            graph1Mode = .accelZ
            gaugeView.name = DashboardText.accelZ
            gaugeView.gaugeUnits = DashboardText.gravityUnits
            gaugeView.gaugeValueRange = (min: -1 * Double(bleD!.pl!.accelerometer.range), max:Double(bleD!.pl!.accelerometer.range))
        }
    }
*/
    
}
