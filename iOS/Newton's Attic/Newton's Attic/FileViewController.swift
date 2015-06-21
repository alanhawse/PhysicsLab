//
//  FileViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/31/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit
import MessageUI


class FileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var fileNames = [String]()
    var docsDir: String?
    
    var checkState = [UITableViewCellAccessoryType]()

    @IBOutlet weak var fileListTable: UITableView!


    override func viewWillAppear(animated: Bool) {
        readFiles()
        fileTable.dataSource = self
        fileTable.delegate = self
    }
    
    @IBAction func trashAction(sender: UIButton) {
        trashFiles(getList())
        readFiles()
        fileListTable.reloadData()
    }
    
    @IBAction func markAll(sender: UIButton) {
       
        var ip = NSIndexPath()
        
        var count = 0
        
        // iterate over all of the cells
        for i in 0..<fileNames.count {
            if checkState[i] != .None
            {
              count = count + 1
            }
        }
        
        var setCheck = false
        if count <= fileNames.count / 2 {
                setCheck = true
        }
        
        for i in 0..<fileNames.count {
            ip = NSIndexPath(forRow: i, inSection: 0)
            if let cell = fileTable.cellForRowAtIndexPath(ip)
            {
                if setCheck {
                    cell.accessoryType = .Checkmark
                    checkState[i] = .Checkmark
                }
                else
                {
                    cell.accessoryType = .None
                    checkState[i] = .None
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("Segue to email")
        
    }
    
    @IBOutlet weak var fileTable: UITableView!
    
    @IBAction func emailAction(sender: UIButton) {
        let emvc = EmailViewController()
        if MFMailComposeViewController.canSendMail()
        {
            var files = [String]()
            for i in 0..<fileNames.count {
                if checkState[i] != .None {
                    files.append(fileNames[i])
                }
            }
            emvc.setupAttachments(docsDir: docsDir!, fileNames: files)
            presentViewController(emvc, animated: true, completion: nil)
        }
        
    }
    
    
    // this function reads all of the files in the documents directory and adds them to the list of files that the program knows about
    func readFiles() {
        
        fileNames.removeAll(keepCapacity: true)
        checkState.removeAll(keepCapacity: true)
        
        let fileManager = NSFileManager.defaultManager()
        //var docsDir: String?
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        docsDir = dirPaths[0] as? String
        let enumerator = fileManager.enumeratorAtPath(docsDir!)
        
        var count = 0
        
        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".csv") { // checks the extension
                fileNames.append(element)
                checkState.append(.None)
            }
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileName", forIndexPath: indexPath) as! UITableViewCell
        
        let ip = indexPath.row
        cell.textLabel?.text = fileNames[ip]
        cell.accessoryType = checkState[ip]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        flipCellState(cell!)
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        flipCellState(cell!)
    }
    
    func flipCellState(cell : UITableViewCell)
    {
        for i in 0..<fileNames.count
        {
            if cell.textLabel?.text == fileNames[i] {
                if checkState[i] == .None {
                    checkState[i] = .Checkmark
                }
                else
                {
                    checkState[i] = .None
                }
                cell.accessoryType = checkState[i]
            }
        }
    }
    
    func getList() -> [String] {
        var rval = [String]()
        
        var ip = NSIndexPath()
        
        // iterate over all of the cells
        for i in 0..<fileNames.count {
            if checkState[i] != .None {
                rval.append(fileNames[i])
            }

        }
        
        
        return rval
    }
    
    func trashFiles(fileList: [String]) {
        let fileManager = NSFileManager.defaultManager()
        var docsDir: String?
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        docsDir = dirPaths[0] as? String
        
        for i in fileList {
            let fname = docsDir! + "/" + i
            fileManager.removeItemAtPath(fname, error: nil)
        }
        
    }


}
