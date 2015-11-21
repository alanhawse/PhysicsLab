//
//  PhysicsLabViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/6/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class PhysicsLabDataViewController: UIViewController {

    var bleD : BleDevice?

    // if it is true then displaying max rather than current
    private var displayMax = false
    
    @IBOutlet weak var accelX: UILabel!
    @IBOutlet weak var accelY: UILabel!
    @IBOutlet weak var accelZ: UILabel!
    @IBOutlet weak var magX: UILabel!
    @IBOutlet weak var magY: UILabel!
    @IBOutlet weak var magZ: UILabel!
    @IBOutlet weak var gyroX: UILabel!
    @IBOutlet weak var gyroY: UILabel!
    @IBOutlet weak var gyroZ: UILabel!
    @IBOutlet weak var position: UILabel!
    @IBOutlet weak var velocity: UILabel!
    @IBOutlet weak var heading: UILabel!
    
    
    // MARK: - Viewcontroller lifecycle functions
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedKinematicData, object: bleD!.pl!, queue: NSOperationQueue.mainQueue()) { _ in self.physicsLabUpdateDisplay() }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Action functions
    @IBAction func resetMax(sender: UIButton) {
        bleD?.pl?.resetMaxMin()
    }
    
    @IBAction func changeMax(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            displayMax = false
        }
        else
        {
            displayMax = true
        }
    }
    
    // MARK: - Display function
    func physicsLabUpdateDisplay() {
        let x = NSNumberFormatter()
        x.numberStyle = .DecimalStyle
        x.minimumFractionDigits = 2
        x.maximumFractionDigits = 2
        
        heading.text = x.stringFromNumber(bleD!.pl!.mag.heading)
        
        if !displayMax {
        
        accelX.text = x.stringFromNumber(bleD!.pl!.accelerometer.x)
        accelY.text = x.stringFromNumber(bleD!.pl!.accelerometer.y)
        accelZ.text = x.stringFromNumber(bleD!.pl!.accelerometer.z)
        
        magX.text = x.stringFromNumber(bleD!.pl!.mag.x)
        magY.text = x.stringFromNumber(bleD!.pl!.mag.y)
        magZ.text = x.stringFromNumber(bleD!.pl!.mag.z)
        
        gyroX.text = x.stringFromNumber(bleD!.pl!.gyro.x)
        gyroY.text = x.stringFromNumber(bleD!.pl!.gyro.y)
        gyroZ.text = x.stringFromNumber(bleD!.pl!.gyro.z)
        
        position.text = x.stringFromNumber(bleD!.pl!.pos.cartPosition)
            velocity.text = x.stringFromNumber(bleD!.pl!.pos.velocity)
        }
        else {
            accelX.text = x.stringFromNumber(bleD!.pl!.accelerometer.max.x)
            accelY.text = x.stringFromNumber(bleD!.pl!.accelerometer.max.y)
            accelZ.text = x.stringFromNumber(bleD!.pl!.accelerometer.max.z)
            
            magX.text = x.stringFromNumber(bleD!.pl!.mag.max.x)
            magY.text = x.stringFromNumber(bleD!.pl!.mag.max.y)
            magZ.text = x.stringFromNumber(bleD!.pl!.mag.max.z)
            
            gyroX.text = x.stringFromNumber(bleD!.pl!.gyro.max.x)
            gyroY.text = x.stringFromNumber(bleD!.pl!.gyro.max.y)
            gyroZ.text = x.stringFromNumber(bleD!.pl!.gyro.max.z)
            
            position.text = x.stringFromNumber(bleD!.pl!.pos.maxCartPosition)
            velocity.text = x.stringFromNumber(bleD!.pl!.pos.maxVelocity)
        }
    }
}
