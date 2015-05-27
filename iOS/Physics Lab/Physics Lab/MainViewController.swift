//
//  ViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/3/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

var loggedIn : Bool = true
var bleLand = BlueToothNeighborhood?()


class MainViewController: UITableViewController, BlueToothNeighborhoodUpdate {
    
    
    var tagToId = [Int: BleDevice]()
    
    
    @IBOutlet var devicesTable: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        if bleLand == nil
        {
            bleLand = BlueToothNeighborhood()
            bleLand?.startUpCentralManager()
        }
        
        bleLand?.delegate = self
        
    }
    
    override func viewDidAppear(animated: Bool) {
        bleLand?.delegate = self
    }
    
    func addedDevice() {
        devicesTable.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
        
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return bleLand?.blePeripheralsPhysicsLab.count ?? 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bledevice", forIndexPath: indexPath) as! UITableViewCell
        
        let ip = indexPath.row
        
        if bleLand?.blePeripheralsPhysicsLab.count > 0 {
            if let bleD = bleLand?.blePeripheralsPhysicsLab[ip]
            {
                if let nm = bleD.pl?.name
                {
                    cell.textLabel!.text = nm
                }
                else
                {
                    cell.textLabel!.text = bleD.peripheral?.identifier.UUIDString
                }
                cell.tag = tagToId.count
                tagToId[tagToId.count+1] = bleD
            
            }
        }
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
               
        var destination = segue.destinationViewController as? UIViewController
        
        if let navCon = destination as? UINavigationController
        {
            println("Navigation Controller")
            destination = navCon.visibleViewController
        }
        
        if let tbc = destination as? PhysicsLabBarViewController
        {
            if let tvc = sender as? UITableViewCell {
                //let i = devicesTable.indexPathForCell(tvc)!.row
                tbc.bleD = tagToId[tvc.tag]
               // tbc.bleD = bleLand?.blePeripheralsPhysicsLab[i]
            }
        }
        bleLand?.delegate = nil
    }

}

