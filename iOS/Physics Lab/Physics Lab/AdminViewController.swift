//
//  AdminViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/11/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class AdminViewController: UIViewController, PhysicsLabDisplayDelegate, UITextFieldDelegate {

    
    var bleD : BleDevice?
    
    override func viewDidAppear(animated: Bool) {
        bleD!.pl?.delegate = self
        updateGui()
        changeEditing(false)
        
        self.connectButton.userInteractionEnabled = loggedIn
        self.connectButton.enabled = loggedIn
        
        cmsPerRotation.delegate = self
        zeroPosTextField.delegate = self

    }
    
    override func viewWillDisappear(animated: Bool) {
       // super.viewWillDisappear(animated)
        bleLand?.disconnectDevice(bleD)
        bleD?.pl?.delegate = nil
    }
    
    func physicsLabDisplay(sender: PhysicsLab) {
        
        switch bleD!.peripheral!.state {
        case .Connected:
            connectButton.setTitle("Disconnect", forState: .Normal)
        case .Disconnected:
            connectButton.setTitle("Connect", forState: .Normal)
        default: break
        }
        
       // println("changing editing \(sender.connectionComplete)")
        changeEditing(sender.connectionComplete)
        
        
    }
    
    
    @IBOutlet weak var cmsPerRotation: UITextField!
    @IBAction func finishedCmPerRotation(sender: AnyObject) {
        
        if let rval = NSNumberFormatter().numberFromString(cmsPerRotation.text)
        {
            bleD!.pl!.cmsPerRotation = rval.floatValue
        }
        else
        {
            cmsPerRotation.text = "\(bleD!.pl!.cmsPerRotation)"
        }

        
    }
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        let countdots = textField.text.componentsSeparatedByString(".").count - 1
        
        if countdots > 0 && string == "."
        {
            return false
        }
        return true
    }
    
    @IBAction func startEditing(sender: UITextField) {
        tapGesture.enabled = true
    }
    
    
    @IBOutlet weak var zeroPosTextField: UITextField!
    
    @IBAction func zeroFieldStart(sender: AnyObject) {
        tapGesture.enabled = true
    }
    @IBAction func zeroPosTextFieldAction(sender: UITextField) {
        if let rval = NSNumberFormatter().numberFromString(zeroPosTextField.text)
        {
            bleD!.pl!.cartZero = rval.floatValue
        }
        else
        {
            cmsPerRotation.text = "\(bleD!.pl!.cartZero)"
        }
    }
    
    func updateGui()
    {
        if let pl = bleD?.pl {
            
            accelerometerRange.selectedSegmentIndex = pl.LSM9DSOAccelMode
            magRange.selectedSegmentIndex = pl.LSM9DS0MagMode
            gyroRange.selectedSegmentIndex = pl.LSM9DSOGyroMode
            
            cmsPerRotation.text = "\(pl.cmsPerRotation)"
            let x=NSNumberFormatter()
            x.numberStyle = .DecimalStyle
            x.minimumFractionDigits = 2
            x.maximumFractionDigits = 2
            zeroPosTextField.text = x.stringFromNumber(pl.cartZero)
        }
    }
    
    @IBAction func loginButton(sender: AnyObject) {

        login()
    }
    
    func login() {

        let alertController = UIAlertController(title: "Login", message: "", preferredStyle: UIAlertControllerStyle.Alert)
    
        let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
            let passwordTextField = alertController.textFields![0] as! UITextField
            // 1225 is newtons birthday
            if passwordTextField.text == "1225" {
                loggedIn = true
                //self.changeEditing(true)
                self.connectButton.userInteractionEnabled = true
                self.connectButton.enabled = true
            }
            else
            {
                loggedIn = false
                //self.changeEditing(false)
                self.connectButton.userInteractionEnabled = false
                self.connectButton.enabled = false
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true) {
        }
    }
    
    @IBOutlet weak var connectButton: UIButton!
    @IBAction func connect(sender: UIButton) {
        
        switch bleD!.peripheral!.state
        {
            case .Connected:
            bleLand?.disconnectDevice(bleD)
            
            case .Disconnected:
            bleLand?.connectToDevice(bleD?.peripheral)
        default: break
        }
    }
    
    func changeEditing(action: Bool)
    {
        accelerometerRange.userInteractionEnabled = action
        accelerometerRange.enabled = action
        magRange.userInteractionEnabled = action
        magRange.enabled = action
        gyroRange.userInteractionEnabled = action
        gyroRange.enabled = action
        
        cmsPerRotation.userInteractionEnabled = action
        cmsPerRotation.enabled = action
        zeroPosTextField.userInteractionEnabled = action
        zeroPosTextField.enabled = action

        
    }

    @IBOutlet var tapGesture: UITapGestureRecognizer!

    @IBAction func tapOutside(sender: AnyObject) {
        
        tapGesture.enabled = false
        
        if cmsPerRotation.editing {
            finishedCmPerRotation(cmsPerRotation)
            cmsPerRotation.resignFirstResponder()
        }
        
        if zeroPosTextField.editing {
            zeroPosTextFieldAction(zeroPosTextField)
            zeroPosTextField.resignFirstResponder()
        }

        
    }
    
    @IBOutlet weak var accelerometerRange: UISegmentedControl!
    @IBAction func changeAccel(sender: UISegmentedControl) {
        bleD?.pl?.LSM9DSOAccelMode = sender.selectedSegmentIndex
        
    }
    
    
    @IBOutlet weak var magRange: UISegmentedControl!
    @IBAction func magRangeChange(sender: UISegmentedControl) {
        bleD?.pl?.LSM9DS0MagMode = sender.selectedSegmentIndex
    }
    
    @IBOutlet weak var gyroRange: UISegmentedControl!
    @IBAction func gyroRangeChange(sender: UISegmentedControl) {
        bleD?.pl?.LSM9DSOGyroMode = sender.selectedSegmentIndex
    }
    
    


}
