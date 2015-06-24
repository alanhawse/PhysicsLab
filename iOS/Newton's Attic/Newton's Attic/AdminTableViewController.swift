//
//  AdminTableViewController.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 6/18/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class AdminTableViewController: UITableViewController,PhysicsLabDisplayDelegate, UITextFieldDelegate {
    
    
    // this is setup by the parent navigation controller.
    var parentTabBar : PhysicsLabBarViewController?

    override func viewWillAppear(animated: Bool) {
        parentTabBar!.setupTopBarConnect()
    }
    
    override func viewDidDisappear(animated: Bool) {
        parentTabBar!.setupTopBarRecord()
        bleLand?.disconnectDevice(bleD)
        bleD?.pl?.delegate = nil
    }
   
    // if the user clicks anywhere outside of the text fields it will be on
    // the tableview.  When he does that then turn off the keyboard and end
    // editing.  When you "resignFirstResponder" it will call the end action
    // for that field
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        nameTextField.resignFirstResponder()
        cmsPerRotation.resignFirstResponder()
        zeroPosTextField.resignFirstResponder()
        actualPosition.resignFirstResponder()
    }

    var bleD : BleDevice?
    
    override func viewDidAppear(animated: Bool) {
        bleD!.pl?.delegate = self
        updateGui()
        changeEditing(false)
        
        cmsPerRotation.delegate = self
        zeroPosTextField.delegate = self
        nameTextField.delegate = self
        actualPosition.delegate = self
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        bleLand?.disconnectDevice(bleD)
        bleD?.pl?.delegate = nil
    }
    
    // if the user says he is done.. so be it.  The next call will
    // be automatically to the end ibaction as registered in the storyboard
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }
    
    
    // if the user says he is done.. so be it.  The next call will
    // be automatically to the end ibaction as registered in the storyboard
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
   // func textFieldDidEndEditing(textField: UITextField) {
   //     println("did end editing")
   // }
    
    // delegate display method.  If you are connected the PL will send you
    // a notification when a characteristic changes.. specifically the position
    func physicsLabDisplay(sender: PhysicsLab) {
        changeEditing(sender.bleConnectionInterface!.connectionComplete)
        currentPosition.text = format2(sender.cartPosition,digits:2)
    }
    
    func format2 (val: Float, digits: Int) -> String? {
        let x=NSNumberFormatter()
        x.numberStyle = .DecimalStyle
        x.minimumFractionDigits = digits
        x.maximumFractionDigits = digits
        return x.stringFromNumber(val)
        
    }
    
    @IBOutlet weak var currentPosition: UITextField!
    
    @IBOutlet weak var actualPosition: UITextField!
    
    @IBAction func actualPositionEnd(sender: UITextField) {
       // println("actual position end")
        let currentZero = bleD!.pl!.cartZero
        let currentCmsPerRotation = bleD!.pl!.cmsPerRotation
        
        if bleD!.pl!.cartPosition - currentZero < 0.1 {
            return
        }
        if let enteredActual = NSNumberFormatter().numberFromString(actualPosition.text)
        {
            if enteredActual.floatValue < currentZero {
                return
            }
            let scale =  (enteredActual.floatValue - currentZero) / (bleD!.pl!.cartPosition - currentZero)
            
            let newCmsPerRotation = currentCmsPerRotation * scale
            
            bleD!.pl!.cmsPerRotation = newCmsPerRotation
            bleD!.pl!.cartZero = currentZero
            bleD!.pl!.cartPosition = Float(enteredActual)
            currentPosition.text = actualPosition.text
        }
    }
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBAction func nameEndAction(sender: UITextField) {
        //println("name end action")
        bleD!.pl!.name = nameTextField.text
        
    }

    
    @IBOutlet weak var cmsPerRotation: UITextField!
    @IBAction func finishedCmPerRotation(sender: AnyObject) {
        
        //println("finished cms per rotation")
        if let rval = NSNumberFormatter().numberFromString(cmsPerRotation.text)
        {
            let currentZero = bleD!.pl!.cartZero
            bleD!.pl!.cmsPerRotation = rval.floatValue
            bleD!.pl!.cartZero = currentZero
        }
        else
        {
            //cmsPerRotation.text = "\(bleD!.pl!.cmsPerRotation)"
            cmsPerRotation.text = format2(bleD!.pl!.cmsPerRotation,digits:2)
        }
    }
    
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        
        if textField == nameTextField {
            var name :NSString = textField.text
            return bleD!.pl!.isNameLegal(String(name.stringByReplacingCharactersInRange(range, withString: string)))
        }
        
        let countdots = textField.text.componentsSeparatedByString(".").count - 1
        if countdots > 0 && string == "."
        {
            return false
        }
        return true
    }
    
    @IBOutlet weak var zeroPosTextField: UITextField!

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
            nameTextField.text = pl.name
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
        nameTextField.userInteractionEnabled = action
        nameTextField.enabled = action
        actualPosition.userInteractionEnabled = action
        actualPosition.enabled = action
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
