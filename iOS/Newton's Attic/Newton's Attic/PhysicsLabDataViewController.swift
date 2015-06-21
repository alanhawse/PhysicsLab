//
//  PhysicsLabViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/6/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class PhysicsLabDataViewController: UIViewController, PhysicsLabDisplayDelegate {

    var bleD : BleDevice?

    @IBAction func resetMax(sender: UIButton) {
        bleD?.pl?.resetMax()
        
    }
    
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
    
    var displayMax = false
    
    @IBAction func changeMax(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            displayMax = false
        }
        else
        {
            displayMax = true
        }
    }
    func physicsLabDisplay(sender: PhysicsLab) {
        let x = NSNumberFormatter()
        x.numberStyle = .DecimalStyle
        x.minimumFractionDigits = 2
        x.maximumFractionDigits = 2
        
        heading.text = x.stringFromNumber(sender.heading)
        
        
        
        if !displayMax {
        
        accelX.text = x.stringFromNumber(sender.acceleration.x)
        accelY.text = x.stringFromNumber(sender.acceleration.y)
        accelZ.text = x.stringFromNumber(sender.acceleration.z)
        
        magX.text = x.stringFromNumber(sender.mag.x)
        magY.text = x.stringFromNumber(sender.mag.y)
        magZ.text = x.stringFromNumber(sender.mag.z)
        
        gyroX.text = x.stringFromNumber(sender.gyro.x)
        gyroY.text = x.stringFromNumber(sender.gyro.y)
        gyroZ.text = x.stringFromNumber(sender.gyro.z)
        
        position.text = x.stringFromNumber(sender.cartPosition)
            velocity.text = x.stringFromNumber(sender.velocity)
        }
        else {
            accelX.text = x.stringFromNumber(sender.maxAcceleration.x)
            accelY.text = x.stringFromNumber(sender.maxAcceleration.y)
            accelZ.text = x.stringFromNumber(sender.maxAcceleration.z)
            
            magX.text = x.stringFromNumber(sender.maxMag.x)
            magY.text = x.stringFromNumber(sender.maxMag.y)
            magZ.text = x.stringFromNumber(sender.maxMag.z)
            
            gyroX.text = x.stringFromNumber(sender.maxGyro.x)
            gyroY.text = x.stringFromNumber(sender.maxGyro.y)
            gyroZ.text = x.stringFromNumber(sender.maxGyro.z)
            
            position.text = x.stringFromNumber(sender.maxCartPosition)
            velocity.text = x.stringFromNumber(sender.maxMinVelocity.max)
        }
       
    }
    

    
    override func viewDidAppear(animated: Bool) {
        //super.viewWillAppear(animated: Bool)
        bleD?.pl?.delegate = self
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        bleD?.pl?.delegate = nil
    }



   
}
