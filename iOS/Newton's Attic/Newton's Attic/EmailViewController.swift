//
//  EmailViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 6/2/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit
import MessageUI

class EmailViewController: MFMailComposeViewController, MFMailComposeViewControllerDelegate {

    override func viewWillAppear(animated: Bool) {
        mailComposeDelegate = self
    }
    
    // if they send or cancel dismiss the view controller and go back
    // to the file screen
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // create the attachments and attach them to the mail message
    func setupAttachments(#docsDir : String, fileNames : [String])
    {
        for i in fileNames {
            let filePath = docsDir + "/" + i
            if let fileData = NSData(contentsOfFile: filePath) {
                addAttachmentData(fileData, mimeType: "csv", fileName: i)
            }
        }
    }
    
}
