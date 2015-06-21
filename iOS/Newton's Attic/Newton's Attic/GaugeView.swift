//
//  GaugeView.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/15/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

@IBDesignable
class GaugeView: UIView {

    
    private var scale : CGFloat = 0.9

    private var gaugeRadius : CGFloat {
        return min(bounds.width, bounds.height)/2 * scale
    }
    
    private let gaugeZero = 5*M_PI_4
    private let gaugeMax = -M_PI_4
    
    @IBInspectable var gaugeValueRange : (min:Double, max:Double) = (-2.0,2.0)
    
    @IBInspectable
    var gaugeTicks = 10
    
    var needleValue = (current:0.0, min: 0.0, max: 0.0) {
        didSet {
            if needleValue.current < gaugeValueRange.min {
                needleValue.current = gaugeValueRange.min
            }
            if needleValue.current > gaugeValueRange.max {
                needleValue.current = gaugeValueRange.max
            }

            if needleValue.max < gaugeValueRange.min {
                needleValue.max = gaugeValueRange.min
            }
            if needleValue.max > gaugeValueRange.max {
                needleValue.max = gaugeValueRange.max
            }
            
            if needleValue.min < gaugeValueRange.min {
                needleValue.min = gaugeValueRange.min
            }
            if needleValue.min > gaugeValueRange.max {
                needleValue.min = gaugeValueRange.max
            }
            
            setNeedsDisplay()
        }
    }
    
    
    @IBInspectable
    var name : NSString = " "
    var gaugeUnits : NSString = " "
    
    
    var needleWidth : CGFloat = 2.0
    var needleColor = UIColor.blueColor()
    var maxNeedleColor = UIColor.redColor()
    var minNeedleColor = UIColor.greenColor()
    
    private var gaugeColor = UIColor.blackColor()
    
    private var gaugeCenter: CGPoint {
        return	convertPoint(center, fromView: superview)
    }

    override func drawRect(rect: CGRect) {
        // Drawing code
        updateGui()
    }
    
    private func updateGui()
    {
                
        let bp = UIBezierPath()
        
        // draw the circle of the gauge
        gaugeColor.set()
        bp.lineWidth = 3
        bp.addArcWithCenter(gaugeCenter, radius: gaugeRadius, startAngle: CGFloat(0), endAngle: CGFloat(2*M_PI), clockwise: true)
        bp.stroke()
        
        drawTicksAndLabels()
        
        drawTitle()
        drawUnits()
        
        drawNeedle(.Current)
        drawNeedle(.Min)
        drawNeedle(.Max)
        
        
    }
    
    private func drawTitle()
    {

        
        //let printString = NSString(string: strng)
        
        let start = Double(gaugeRadius) * 0.2
        
        let sizeV = name.sizeWithAttributes(nil)
        
        let pnt = radiansToRectangular(r: CGFloat(start), angle: 3*M_PI_2 , offset: gaugeCenter)
        
        let pnt1 = CGPoint(x: pnt.x - sizeV.width/2, y: pnt.y - sizeV.height/2)
        
        let rect = CGRect(origin: pnt1, size: sizeV)
        
        name.drawInRect(rect, withAttributes: nil)
        
        
    }
    
    private func drawUnits()
    {
        
        
        //let printString = NSString(string: strng)
        
        let start = Double(gaugeRadius) * 0.3 // ARH Guess
        
        let sizeV = gaugeUnits.sizeWithAttributes(nil)
        
        let pnt = radiansToRectangular(r: CGFloat(start), angle: 3*M_PI_2 , offset: gaugeCenter)
        
        let pnt1 = CGPoint(x: pnt.x - sizeV.width/2, y: pnt.y - sizeV.height/2)
        
        let rect = CGRect(origin: pnt1, size: sizeV)
        
        gaugeUnits.drawInRect(rect, withAttributes: nil)
        
        
    }
    
    private func drawTicksAndLabels() {
        
        let incrementVal = (gaugeZero - gaugeMax) / Double(gaugeTicks)
        let scaleIncrementVal = (gaugeValueRange.max - gaugeValueRange.min) / Double(gaugeTicks)
        
        let startValTick = Double(gaugeRadius) * 0.8
        let startValLabel = Double(gaugeRadius) * 0.7
        let endVal = Double(gaugeRadius) * 1.0
        
        for i in 0...gaugeTicks {
            let angle = gaugeZero - (Double(i) * incrementVal)
            drawLinePolar(startR: startValTick, startAngle: angle, endR: endVal, endAngle: angle)
            
            // print the labels
            
            
            let printval = gaugeValueRange.min + Double(i) * scaleIncrementVal
            //let strng = "\(printval)"
            
            
            let x = NSNumberFormatter()
            x.numberStyle = .DecimalStyle
            x.minimumFractionDigits = 1
            x.maximumFractionDigits = 1

            if let printString = x.stringFromNumber(printval) {

            
            let sizeV = printString.sizeWithAttributes(nil)
           
            let pnt = radiansToRectangular(r: CGFloat(startValLabel), angle: angle, offset: gaugeCenter)
            
            let pnt1 = CGPoint(x: pnt.x - sizeV.width/2, y: pnt.y - sizeV.height/2)
            
            let rect = CGRect(origin: pnt1, size: sizeV)
            
            printString.drawInRect(rect, withAttributes: nil)
            }

        }
       
    }
    

    private func drawLinePolar(#startR: Double, startAngle: Double, endR: Double, endAngle: Double)
    {
        gaugeColor.set()
        let bp = UIBezierPath()
        bp.moveToPoint(radiansToRectangular(r: CGFloat(startR), angle: startAngle, offset: gaugeCenter))
        bp.addLineToPoint(radiansToRectangular(r: CGFloat(endR), angle: endAngle, offset: gaugeCenter))
        bp.stroke()
        
    }
    

    enum Needles {
        case Current
        case Min
        case Max
    }
    
    private func drawNeedle(needle : Needles)
    {
        
        var percent = 100.0
        
        switch(needle)
        {
        case .Current:
            percent = (needleValue.current - gaugeValueRange.min) / (gaugeValueRange.max - gaugeValueRange.min)
            needleColor.set()
        case .Min:
            percent = (needleValue.min - gaugeValueRange.min) / (gaugeValueRange.max - gaugeValueRange.min)
            minNeedleColor.set()
            
        case .Max:
            percent = (needleValue.max - gaugeValueRange.min) / (gaugeValueRange.max - gaugeValueRange.min)
            maxNeedleColor.set()
        }
        
        
        let needleLocation = gaugeZero - (percent * (gaugeZero - gaugeMax))
        drawNeedle(angle: needleLocation)
        
        
    }
    
    private func drawNeedle(#angle: Double)
    {
        var needlePath = UIBezierPath()
        

        //needleColor.set()
        needlePath.lineWidth = needleWidth
        
        needlePath.removeAllPoints()
        
        needlePath.moveToPoint(gaugeCenter)
        needlePath.addLineToPoint(radiansToRectangular(r:gaugeRadius, angle: angle, offset: gaugeCenter))
        needlePath.stroke()
    }
    
    private func radiansToRectangular(#r:CGFloat, angle:Double, offset: CGPoint) -> CGPoint
    {
        let x = Double(r)*cos(angle)
        let y = Double(r)*sin(angle) * -1.0
        return CGPoint(x: CGFloat(x) + offset.x , y: CGFloat (y) + offset.y )
        
    }

}
