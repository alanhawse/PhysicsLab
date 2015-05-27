//
//  GraphView.swift
//  Calculator
//
//  Created by Alan Hawse on 4/29/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func getValYforX(x: Double) -> Double?
}

@IBDesignable
class GraphView: UIView {
    

    var dataSource : GraphViewDataSource?
    
    
    @IBInspectable
    
    var scale: CGFloat = 50 {
        
        didSet {
            setNeedsDisplay()
        }
    }
    
    var oldBounds : CGRect?
    
    var maxXY : CGPoint?
    var minXY : CGPoint?
    
    var origin : CGPoint? {
        
        didSet {
            setNeedsDisplay()

        }
    }
    
    func graphToViewX(x: Double) -> CGFloat {
        return CGFloat(x*Double(scale) + Double(origin!.x))
    }
    
    func graphToViewY(y: Double) -> CGFloat {
        return CGFloat(Double(origin!.y) - y*Double(scale) )
    }
    
    func viewToGraphX(x: CGFloat) -> Double {
        return Double((x-origin!.x) / scale)
    }
    
    func viewToGraphY(y: CGFloat) -> Double {
        return Double((origin!.y - y) / scale)
    }
    
  
    func drawGraph(rect: CGRect) -> UIBezierPath?
    {

        if dataSource == nil {
            return nil
        }
        
        
        
        let bp = UIBezierPath()
        
        bp.lineWidth = 3.0
        UIColor.blackColor()
        
        if let yval = dataSource!.getValYforX( viewToGraphX(0))
        {
            let start = CGPoint(x: rect.minX, y: graphToViewY(yval))
            maxXY = CGPoint(x: viewToGraphX(0), y:yval)
            minXY = CGPoint(x: viewToGraphX(0), y:yval)
            
            bp.moveToPoint(start)
        }
        
        for i in Int(rect.minX+1)...Int(rect.maxX) {

            if let yval = dataSource!.getValYforX( viewToGraphX(CGFloat(i)))
            {
                
                let start = CGPoint(x: CGFloat(i), y: graphToViewY(yval))
                
                if graphToViewY(yval) > maxXY?.y {
                    maxXY = CGPoint(x: viewToGraphX(CGFloat(i)), y: yval)
                }
 
                if graphToViewY(yval) < minXY?.y {
                    maxXY = CGPoint(x: viewToGraphX(CGFloat(i)), y: yval)
                }
                
                bp.addLineToPoint(start)
            }

            
        }
        return bp
    }
       
    override func drawRect(rect: CGRect) {
        if origin == nil {
            origin = convertPoint(center, fromView: superview)
        }
        
        if oldBounds == nil {
            oldBounds = rect
        }
        else {
            if oldBounds != rect {
                let oDeltaX = oldBounds!.midX - origin!.x
                let oDeltaY = oldBounds!.midY - origin!.y
                
                origin = CGPoint(x: center.x - oDeltaX , y: center.y - oDeltaY)

            }
        }
        
        drawGraph(rect)?.stroke()
        
        let axes = AxesDrawer()
        axes.drawAxesInRect(rect, origin: origin!, pointsPerUnit: scale)
        
    }
    
   

}
