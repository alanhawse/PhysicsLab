//
//  PhysicsLabBarViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/10/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class PhysicsLabBarViewController: UITabBarController
{
    var bleD : BleDevice?

    private var recordButton : UIBarButtonItem?
    private var actionButton : UIBarButtonItem?
    private var bleConnectButton : UIBarButtonItem?
    private var loginButton : UIBarButtonItem?
    
    // MARK: - Viewcontroller life cycle
    
    override func viewWillAppear(animated: Bool) {
        self.tabBar.translucent = false
        setupTopBarRecord()
        
        let cnt = viewControllers!.count
    
        for i in viewControllers! {
            if let pldvc = i as? PhysicsLabDataViewController
            {
                pldvc.bleD = bleD
            }
            
            if let plenviro = i as? EnviroViewController {
                plenviro.bleD = bleD
            }

            if let pldashboard = i as? DashboardViewController {
                pldashboard.bleD = bleD
            }
            
            if let graph = i as? GraphViewController {
                graph.bleD = bleD
            }
            
            if let admin1 = i as? AdminTableViewController {
                admin1.bleD = bleD
                admin1.parentTabBar = self
                
            }
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHistory", name: PLNotifications.PLUpdatedHistory, object: bleD!.pl!)
        }
        
    }
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Setup GUI
    
    func setupTopBarConnect()
    {
        let img1 = UIImage(named: "bluetoothconnected")
        bleConnectButton = UIBarButtonItem(image: img1, style: .Plain, target: self, action: "bleConnect")
        bleConnectButton?.enabled = loggedIn
        let img2 = UIImage(named: "login")
        loginButton = UIBarButtonItem(image: img2, style: .Plain, target: self, action: "login")
        
        self.navigationItem.setRightBarButtonItems([bleConnectButton!,loginButton!], animated: true)
    }
    
    func setupTopBarRecord()
    {
        let img = UIImage(named: "recordbutton")
        recordButton = UIBarButtonItem(image: img, style: .Plain, target: self, action: "record")
        
        actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "action")
        self.navigationItem.setRightBarButtonItems([recordButton!,actionButton!], animated: true)
        
    }
   
    // MARK: - GUI Action Functions
    func bleConnect() {
        
        switch bleD!.peripheral!.state
        {
        case .Connected:
            bleLand?.disconnectDevice(bleD)
        case .Disconnected:
            bleLand?.connectToDevice(bleD?.peripheral)
        default: break
        }
    }

    
    func record()
    {
          bleD!.pl?.history.clearRecord()
          bleD!.pl?.history.arm(bleD!.pl!.cartPosition)
          updateHistory()
    }
 
    func action()
    {
        performSegueWithIdentifier("fileViewController", sender: nil)
        
    }
    
    // activated when the user presses the login button
    // creates a alert notification controller for user to type password
    // if the password is set then mark the gloabl variable loggedin... and
    // enable the BLE Connection Button
    func login() {
        
        let alertController = UIAlertController(title: "Login", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
            let passwordTextField = alertController.textFields![0] as! UITextField
            if passwordTextField.text == Global.password {
                loggedIn = true
                self.bleConnectButton?.enabled = true
            }
            else
            {
                loggedIn = false
                self.bleConnectButton?.enabled = false
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
    
    // MARK: - Notification action
    
    // this function updates the text at the top of the navigation controller
    func updateHistory()
    {
        if bleD!.pl!.history.recording {
            let x = NSNumberFormatter()
            x.numberStyle = .DecimalStyle
            x.minimumFractionDigits = 1
            x.maximumFractionDigits = 1
            self.navigationItem.title =  x.stringFromNumber(bleD!.pl!.history.lastTimeSeconds)
        }
        else
        {
            if bleD!.pl!.history.armed {
                self.navigationItem.title = "Armed"
            }
            else
            {
                self.navigationItem.title = ""
            }
        }
    }
}
