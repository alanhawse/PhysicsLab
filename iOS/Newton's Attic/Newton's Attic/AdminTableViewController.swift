//
//  AdminTableViewController.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 6/18/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}



class AdminTableViewController: UITableViewController, UITextFieldDelegate {
    
    
    // this is setup by the parent navigation controller.
    var parentTabBar : PhysicsLabBarViewController?
    var bleD : BleDevice?
    
    // MARK: - ViewController Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        parentTabBar!.setupTopBarConnect()
        
        updateGui()
        changeEditing(false)
        
        
        trackLengthSlider.minimumValue = Float(Global.trackLengthMin)
        trackLengthSlider.maximumValue = Float(Global.trackLengthMax)
        trackLengthSlider.value = Float(Global.trackLength)
        
        trackLengthLabel.text = "\(Global.trackLength)m"
        
        
        recordingTimeSlider.minimumValue = Float(GlobalHistoryConfig.maxRecordingTimeMin)
        recordingTimeSlider.maximumValue = Float(GlobalHistoryConfig.maxRecordingTimeMax)
        recordingTimeSlider.value = Float(GlobalHistoryConfig.maxRecordingTime)

        recordingTimeLabel.text = "\(Int(GlobalHistoryConfig.maxRecordingTime))s"
        
        // textFields need to have their editing delegates set
        cmsPerRotation.delegate = self
        nameTextField.delegate = self
        actualPosition.delegate = self
      
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.pLUpdatedKinematicData, object: bleD!.pl!, queue: NSOperationQueue.mainQueue()) { _ in self.currentPosition.text = self.formatValNumDigits(self.bleD!.pl!.pos.cartPosition,digits:2) }
        
        // can only happen if you are disconnected... when a advertising packet of type 2 arrives
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.pLUpdatedAdmin, object: bleD!.pl!, queue: NSOperationQueue.mainQueue()) { _ in self.updateGui() }
            
        // Either make the fields editable or not
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.bLEConnected, object: bleD!.pl!, queue: NSOperationQueue.mainQueue()) { _ in self.changeEditing(true) }
        
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.bLEDisconnected, object: bleD!.pl!, queue: NSOperationQueue.mainQueue()) { _ in self.changeEditing(false) }
        
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        parentTabBar!.setupTopBarRecord()
        bleLand?.disconnectDevice(bleD)
    }
    

    // MARK: - Table View Delegate Functions
   
    // if the user clicks anywhere outside of the text fields it will be on
    // the tableview.  When he does that then turn off the keyboard and end
    // editing.  When you "resignFirstResponder" it will call the end action
    // for that field
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        nameTextField.resignFirstResponder()
        cmsPerRotation.resignFirstResponder()
        actualPosition.resignFirstResponder()
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
    
    
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        
        if textField == nameTextField {
            let name : NSString = textField.text!
            return bleD!.pl!.isNameLegal(String(name.stringByReplacingCharactersInRange(range, withString: string)))
        }
        
        let countdots = textField.text!.componentsSeparatedByString(".").count - 1
        if countdots > 0 && string == "."
        {
            return false
        }
        return true
    }

    // MARK: - Configure GUI
    
    private func updateGui()
    {
        if let pl = bleD?.pl {
            
            accelerometerRange.selectedSegmentIndex = pl.accelerometer.mode
            magRange.selectedSegmentIndex = pl.mag.mode
            gyroRange.selectedSegmentIndex = pl.gyro.mode
            
            cmsPerRotation.text = "\(pl.pos.cmsPerRotation)"

            nameTextField.text = pl.name
        }
    }
    
    
    private func changeEditing(action: Bool)
    {
        accelerometerRange.userInteractionEnabled = action
        accelerometerRange.enabled = action
        magRange.userInteractionEnabled = action
        magRange.enabled = action
        gyroRange.userInteractionEnabled = action
        gyroRange.enabled = action
        
        cmsPerRotation.userInteractionEnabled = action
        cmsPerRotation.enabled = action
        
        nameTextField.userInteractionEnabled = action
        nameTextField.enabled = action
        actualPosition.userInteractionEnabled = action
        actualPosition.enabled = action
    }
    

    
    private func formatValNumDigits (val: Double, digits: Int) -> String? {
        let x=NSNumberFormatter()
        x.numberStyle = .DecimalStyle
        x.minimumFractionDigits = digits
        x.maximumFractionDigits = digits
        return x.stringFromNumber(val)
        
    }
    
    // MARK: - Interact with GUI
    
    @IBOutlet weak var recordingTimeLabel: UILabel!
    
    @IBOutlet weak var recordingTimeSlider: UISlider!
    @IBAction func recordingTimeAction(sender: AnyObject) {
        GlobalHistoryConfig.maxRecordingTime = Double(Int(recordingTimeSlider.value))
        
        recordingTimeLabel.text = "\(Int(GlobalHistoryConfig.maxRecordingTime))s"

    }
    
    @IBOutlet weak var trackLengthLabel: UILabel!
    
    @IBOutlet weak var trackLengthSlider: UISlider!
    
    @IBAction func trackLengthSliderAction(sender: UISlider) {
        Global.trackLength = Double(trackLengthSlider.value).roundToPlaces(1)
        trackLengthLabel.text = "\(Global.trackLength)m"

    }
    
    
    @IBOutlet weak var currentPosition: UITextField!
    
    
    @IBOutlet weak var actualPosition: UITextField!
    
    
    
    // This is essentially a calibrate function
    @IBAction func actualPositionEnd(sender: UITextField) {
       // println("actual position end")
        //let currentZero = bleD!.pl!.pos.cartZero
        let currentCmsPerRotation = bleD!.pl!.pos.cmsPerRotation
        
        // If you have not moved it very far (0.1Meter hardcoded)... ignore the user input
        if bleD!.pl!.pos.cartPosition < 0.1 {
            return
        }
        if let enteredActual = NSNumberFormatter().numberFromString(actualPosition.text!)
        {
            // you need to move forward
            if enteredActual.doubleValue < 0 {
                return
            }
            
            // how much do you need to change the current wheelsize so that you would
            // end up with the right distance
            let scale =  (enteredActual.doubleValue ) / (bleD!.pl!.pos.cartPosition )
            
            let newCmsPerRotation = currentCmsPerRotation * scale
            
            bleD!.pl!.pos.cmsPerRotation = newCmsPerRotation
            bleD!.pl!.bleConnectionInterface?.writeCmsPerRotation()

            //bleD!.pl!.pos.cartZero = currentZero
            //bleD!.pl!.bleConnectionInterface?.writeResetPosition()

            bleD!.pl!.pos.cartPosition = Double(enteredActual)
            currentPosition.text = actualPosition.text
        }
    }
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBAction func nameEndAction(sender: UITextField) {
        bleD!.pl!.name = nameTextField.text
        bleD!.pl!.bleConnectionInterface?.writeName()
    }

    
    @IBOutlet weak var cmsPerRotation: UITextField!
    @IBAction func finishedCmPerRotation(sender: AnyObject) {
        if let rval = NSNumberFormatter().numberFromString(cmsPerRotation.text!)
        {
            //let currentZero = bleD!.pl!.pos.cartZero
            bleD!.pl!.pos.cmsPerRotation = rval.doubleValue
            //bleD!.pl!.pos.cartZero = currentZero
            bleD!.pl!.bleConnectionInterface?.writeCmsPerRotation()
            
            
        }
        else
        {
            cmsPerRotation.text = formatValNumDigits(bleD!.pl!.pos.cmsPerRotation,digits:2)
        }
    }
   
    

    
    @IBOutlet weak var accelerometerRange: UISegmentedControl!
    @IBAction func changeAccel(sender: UISegmentedControl) {
        bleD?.pl?.accelerometer.mode = sender.selectedSegmentIndex
        bleD?.pl?.bleConnectionInterface?.writeAccelMode()

    }
    
    
    @IBOutlet weak var magRange: UISegmentedControl!
    @IBAction func magRangeChange(sender: UISegmentedControl) {
        bleD?.pl?.mag.mode = sender.selectedSegmentIndex
        bleD?.pl?.bleConnectionInterface?.writeMagMode()
    }
    
    @IBOutlet weak var gyroRange: UISegmentedControl!
    @IBAction func gyroRangeChange(sender: UISegmentedControl) {
        bleD?.pl?.gyro.mode = sender.selectedSegmentIndex
        bleD?.pl?.bleConnectionInterface?.writeGyroMode()

    }
}



