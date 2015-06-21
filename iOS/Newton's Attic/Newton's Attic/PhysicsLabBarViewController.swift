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
   // var bleLand : BlueToothNeighborhood?

    var recordButton : UIBarButtonItem?
    var actionButton : UIBarButtonItem?
    var bleConnectButton : UIBarButtonItem?
    var loginButton : UIBarButtonItem?
    
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
            if let plenviro = i as? AdminViewController {
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
            
            bleD!.pl?.history.delegate = self
            
        }
        
    }
    
    
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
    


    func bleConnect() {
        
        switch bleD!.peripheral!.state
        {
        case .Connected:
            bleLand?.disconnectDevice(bleD)
       //     println("performing disconnect")
        case .Disconnected:
         //   println("peripheral = \(bleD?.peripheral!.identifier)")
            bleLand?.connectToDevice(bleD?.peripheral)
          //  println("performing connect")
        default: break
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
        performSegueWithIdentifier("fileViewController", sender: nil)
        
    }
    
    func login() {
        
        let alertController = UIAlertController(title: "Login", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
            let passwordTextField = alertController.textFields![0] as! UITextField
            // 1225 is newtons birthday
            if passwordTextField.text == "1225" {
                loggedIn = true
                //self.changeEditing(true)
   //             self.connectButton.userInteractionEnabled = true
   //             self.connectButton.enabled = true

                self.bleConnectButton?.enabled = true
            }
            else
            {
                loggedIn = false
                self.bleConnectButton?.enabled = false
                //self.changeEditing(false)
    //            self.connectButton.userInteractionEnabled = false
    //            self.connectButton.enabled = false
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

    
    
}
