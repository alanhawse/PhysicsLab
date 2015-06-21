//
//  GraphView.swift
//  Calculator
//
//  Created by Alan Hawse on 4/29/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func getValYforX(x: Double) -> Float?
    func getValYforXPosition(x: Int, range: Int) -> [Int:Float]?
    
}

@IBDesignable
class GraphView: UIView {
    
    @IBInspectable var scale = 0.0

    var dataSource : GraphViewDataSource?
    
    var rangeX : (min:CGFloat,max:CGFloat) = (0.0,20.0)
    var rangeY : (min:CGFloat,max:CGFloat) = (-4.0,4.0)
    
    var xstart : CGFloat = 0.0 //  { bounds.width * 0.1}
    var ystart : CGFloat = 0.0 //{ bounds.height * 0.05 }
    
    var xend : CGFloat = 0.0 //{ bounds.width * 0.95 }
    var yend : CGFloat = 0.0 //{ bounds.height * 0.95 }
    
    let colorArray  = [UIColor.blueColor(), UIColor.redColor(), UIColor.purpleColor(), UIColor.greenColor(), UIColor.brownColor(), UIColor.blackColor()]
    
    var scatterMode = false
    
    
    func setupRanges(rect: CGRect)
    {
        xstart = rect.width * 0.1
        xend = rect.width * 0.95
        ystart = rect.height * 0.05
        yend = rect.height * 0.95
    
    }
    
    var xScale : CGFloat {
        get {
            return (rangeX.max-rangeX.min) / (xend - xstart)
        }
    }

    var yScale : CGFloat {
        get {
            return (rangeY.max-rangeY.min) / (yend - ystart)
        }
    }
    

    private func drawAxis()
    {
        UIColor.redColor().set()
        // draw x-axis
        let bp = UIBezierPath()
        
        let yaxis = ystart + (yend-ystart)/2
        
        bp.moveToPoint(CGPoint(x:xstart,y:yaxis))
        bp.addLineToPoint(CGPoint(x:xend,y:yaxis))
        
        
        // draw y-axis
        bp.moveToPoint(CGPoint(x:xstart,y:ystart))
        bp.addLineToPoint(CGPoint(x:xstart,y:yend))
        
        bp.stroke()
        bp.removeAllPoints()
        
        drawXTicksLabels(y:yaxis)
        drawYTicksLabels(x:xstart)

    }
    
    func drawScatterGraph()
    {
        
        let yaxis = ystart + (yend-ystart)/2
        let num = Int(xend-xstart)
        
        let increment = Float(rangeX.max - rangeX.min) / Float(num) * Float(100.0)

        //println("Start of graph print num=\(num) increment=\(increment)")
    
        for i in 0...num {
            
            let xfunc = Float(i) / Float(xend-xstart) * Float(rangeX.max - rangeX.min) * 100
        
            if let ys = dataSource?.getValYforXPosition(Int(xfunc), range: Int(increment))
            {
                //println("x = \(xfunc) datapoints = \(ys.count)")
                for evaly in ys {
                    let col = colorArray[evaly.0]
                    
                    col.set()
                    
                    // convert yval to iPhone coordinates
                    let a1 = CGFloat(evaly.1 - Float(rangeY.min))
                    let a2 = CGFloat(rangeY.max - rangeY.min)
                    let a3 = CGFloat(yend - ystart)
                    
                    let yVal = CGFloat(yend) - ( a1/a2*a3)
                   //let yVal = yend - ((CGFloat(evaly) - CGFloat(rangeY.min)) / CGFloat(rangeY.max - rangeY.min) *  CGFloat(yend - ystart) )
                    drawCross(x: Float(i)+Float(xstart), y: Float(yVal))
                }
            }
        }
        
    }
    
    // x + y are in the iPhone coordinates
    func drawCross(#x: Float, y: Float)
    {
        let bp = UIBezierPath()
        bp.moveToPoint(CGPoint(x:CGFloat(x),y:CGFloat(y+2)))
        bp.addLineToPoint(CGPoint(x:CGFloat(x),y:CGFloat(y-2)))
        bp.moveToPoint(CGPoint(x:CGFloat(x-2),y:CGFloat(y)))
        bp.addLineToPoint(CGPoint(x:CGFloat(x+2),y:CGFloat(y)))
        bp.stroke()
        
    }
    override func drawRect(rect: CGRect) {
        setupRanges(rect)
        drawAxis()
        if scatterMode {
            drawScatterGraph()
        }
        else
        {
            drawLineGraph()
 
        }
        
    }
    
    func drawLineGraph()
    {
        let yaxis = ystart + (yend-ystart)/2
        UIColor.blackColor().set()
        
        let num = Int(xend-xstart)
        let bp1 = UIBezierPath()
        
        bp1.lineWidth = 1.0
        
        bp1.moveToPoint(CGPoint(x:xstart,y:yaxis))
        
        for i in 0...num {
            let evalx = CGFloat(i) / CGFloat(num) * (rangeX.max - rangeX.min)
            if let evaly = dataSource?.getValYforX(Double(evalx))
            {
                let yVal = yend - ((CGFloat(evaly) - rangeY.min) / (rangeY.max - rangeY.min) *  CGFloat(yend - ystart) )
                
                bp1.addLineToPoint(CGPoint(x:CGFloat(i)+xstart,y:yVal))
            }
            
        }
        
        bp1.stroke()
    }
    
    func drawXTicksLabels(# y: CGFloat)
    {
        let bp = UIBezierPath()
        UIColor.redColor().set()

        bp.lineWidth=1
        
        //var numTicks = Int((xend - xstart) / 50)
        var numTicks = 4
        
        var increment = (xend-xstart) / CGFloat(numTicks)
        for i in 1...numTicks {
            let x = xstart + (CGFloat(i) * increment)
            bp.moveToPoint(CGPoint(x:x,y:y-5.0))
            bp.addLineToPoint(CGPoint(x:x,y:y+5))
            
            // transform the x from the screen coordinates to the graph coordinates
            //let transX = ( (x-xstart) / (xend - xstart) ) * (rangeX.max - rangeX.min)
            
            let transX = Int(rangeX.min) + i * Int(rangeX.max - rangeX.min) / numTicks
            
            // draw the label
            /*
            let ns = NSNumberFormatter()
            ns.numberStyle = .DecimalStyle
            ns.minimumFractionDigits = 1
            ns.maximumFractionDigits = 1
            let label = ns.stringFromNumber(transX)
            */
            let label = "\(transX)"
            let sizeV = label.sizeWithAttributes(nil)
            let pnt1 = CGPoint(x: x - sizeV.width/2, y: y + 10.0 - sizeV.height/2)
            let rect = CGRect(origin: pnt1, size: sizeV)
            label.drawInRect(rect, withAttributes: nil)
            
        }
        bp.stroke()
        
    }
    
    func drawYTicksLabels(# x: CGFloat)
    {
        let bp = UIBezierPath()
        UIColor.redColor().set()

        //let numTicks = (ymax - ymin) / 90
        let numTicks = 4
        let increment = (yend - ystart) / CGFloat(numTicks)
        
        for i in 0...Int(numTicks) {
            let calcy = yend - (CGFloat(i)*increment)
            bp.moveToPoint(CGPoint(x:x,y:calcy))
            bp.addLineToPoint(CGPoint(x:x+10.0,y:calcy)) // arh hardcoded size of tick
            
            
            //let transY = ( (yend-calcy) / (yend - ystart) ) * (rangeY.max - rangeY.min) + rangeY.min
           
            let transY = i*(Int(rangeY.max - rangeY.min) / numTicks) + Int(rangeY.min)
            let label = "\(transY)"
            let sizeV = label.sizeWithAttributes(nil)
            // arh 3 is a magic number
            let pnt1 = CGPoint(x: x - sizeV.width - 3, y: calcy - sizeV.height/2)
            let rect = CGRect(origin: pnt1, size: sizeV)
            label.drawInRect(rect, withAttributes: nil)
        }
        bp.stroke()
        
        
    }
    

}
