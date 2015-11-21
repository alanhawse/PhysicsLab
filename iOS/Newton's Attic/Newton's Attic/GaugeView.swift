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

    // MARK: - Constants
    private struct GaugeViewDefaults {
        static let gaugePercentOfView : CGFloat = 0.9
        static let gaugeNumberOfTicks = 10 // number of ticks on the face
        static let needleWidth : CGFloat = 2
        static let circleWidth : CGFloat = 3
        static let tickWidth : CGFloat = 3
        
        static let gaugeColor = UIColor.blackColor()
        
        static let needleColor = UIColor.blueColor()
        static let needleMaxColor = UIColor.redColor()
        static let needleMinColor = UIColor.greenColor()
      
        // tickStart, tickEnd and tickLabelStart are all % of guage radius
        static let tickStart = 0.8
        static let tickEnd = 1.0
        static let tickLabelStart = 0.7
        
        // the zero is on the left at 5pi/4 and the maximum value is pi/4 on the right
        static let gaugeZero = 5*M_PI_4
        static let gaugeMax =  -M_PI_4
        
        // Position of the name on the guage as % of radius
        static let gaugeNamePercent = 0.2
        static let gaugeNameRadians = 3*M_PI_2
        // Position of the units on the gauge as % of the radius
        static let gaugeUnitsPercent = 0.35
        static let gaugeUnitsRadians = 3*M_PI_2
    }
    
    // MARK: - Public API
    
    // this should be overwritten when the gauge is setup
    var gaugeValueRange : (min:Double, max:Double) = (0.0,1.0)
    var name : NSString = " "
    var gaugeUnits : NSString = " "
    
    // the gauge keeps track of the maximum and minimum that it has seen
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
    
    // MARK: - Public but probably constant API
    
    // Unlikely that anyone will change these values...
    var gaugeTicks = GaugeViewDefaults.gaugeNumberOfTicks
    var needleWidth = GaugeViewDefaults.needleWidth
    var needleColor = GaugeViewDefaults.needleColor
    var needleMaxColor = GaugeViewDefaults.needleMaxColor
    var needleMinColor = GaugeViewDefaults.needleMinColor
    
    // MARK: - Private Helper Variable
    
    private enum Needles {
        case Current
        case Min
        case Max
    }
    
    private var gaugeRadius : CGFloat {
        return min(bounds.width, bounds.height)/2 * GaugeViewDefaults.gaugePercentOfView
    }
    
    private var gaugeCenter: CGPoint {
        return	convertPoint(center, fromView: superview)
    }

    // MARK: - Drawing functions
    
    override func drawRect(rect: CGRect) {
        updateGui()
    }
    
    private func updateGui()
    {
        let bp = UIBezierPath()
        
        // draw the circle of the gauge
        GaugeViewDefaults.gaugeColor.set()
        bp.lineWidth = GaugeViewDefaults.circleWidth
        bp.addArcWithCenter(gaugeCenter, radius: gaugeRadius, startAngle: CGFloat(0), endAngle: CGFloat(2*M_PI), clockwise: true)
        bp.stroke()
        
        drawTicksAndLabels()
        drawTextAtCoordinateRadians(name, percent: GaugeViewDefaults.gaugeNamePercent , angle: GaugeViewDefaults.gaugeNameRadians)
        drawTextAtCoordinateRadians(gaugeUnits, percent: GaugeViewDefaults.gaugeUnitsPercent , angle: GaugeViewDefaults.gaugeUnitsRadians)
        drawNeedle(.Current)
        drawNeedle(.Min)
        drawNeedle(.Max)
        
    }
    

    private func drawTextAtCoordinateRadians(text : NSString, percent: Double , angle: Double )
    {
        let sizeV = text.sizeWithAttributes(nil)
        let pnt = radiansToRectangular(r: gaugeRadius * CGFloat(percent), angle: angle , offset: gaugeCenter)
        let pnt1 = CGPoint(x: pnt.x - sizeV.width/2, y: pnt.y - sizeV.height/2)
        let rect = CGRect(origin: pnt1, size: sizeV)
        text.drawInRect(rect, withAttributes: nil)
        
    }
    
    
    private func drawTicksAndLabels() {
   
        let startValTick = Double(gaugeRadius) * GaugeViewDefaults.tickStart
        let endValTick = Double(gaugeRadius) * GaugeViewDefaults.tickEnd
        let labelLocationRadiusPercent = GaugeViewDefaults.tickLabelStart
        
        
        let incrementVal = (GaugeViewDefaults.gaugeZero - GaugeViewDefaults.gaugeMax) / Double(gaugeTicks)
        let scaleIncrementVal = (gaugeValueRange.max - gaugeValueRange.min) / Double(gaugeTicks)
        
        for i in 0...gaugeTicks {
            let angle = GaugeViewDefaults.gaugeZero - (Double(i) * incrementVal)
            drawLinePolar(startR: startValTick, startAngle: angle, endR: endValTick, endAngle: angle)
            
            // print the labels
            let printval = gaugeValueRange.min + Double(i) * scaleIncrementVal
            
            let x = NSNumberFormatter()
            x.numberStyle = .DecimalStyle
            x.minimumFractionDigits = 1
            x.maximumFractionDigits = 1
            
            if let printString = x.stringFromNumber(printval) {
                drawTextAtCoordinateRadians(printString, percent: labelLocationRadiusPercent , angle: angle)
            }
        }
        
    }
    

    private func drawLinePolar(startR startR: Double, startAngle: Double, endR: Double, endAngle: Double)
    {
        GaugeViewDefaults.gaugeColor.set()
        let bp = UIBezierPath()
        bp.moveToPoint(radiansToRectangular(r: CGFloat(startR), angle: startAngle, offset: gaugeCenter))
        bp.addLineToPoint(radiansToRectangular(r: CGFloat(endR), angle: endAngle, offset: gaugeCenter))
        bp.stroke()
        
    }
    
    private func drawNeedle(needle : Needles)
    {
        var percent = 0.0
        
        switch(needle)
        {
        case .Current:
            percent = (needleValue.current - gaugeValueRange.min) / (gaugeValueRange.max - gaugeValueRange.min)
            needleColor.set()
        case .Min:
            percent = (needleValue.min - gaugeValueRange.min) / (gaugeValueRange.max - gaugeValueRange.min)
            needleMinColor.set()
            
        case .Max:
            percent = (needleValue.max - gaugeValueRange.min) / (gaugeValueRange.max - gaugeValueRange.min)
            needleMaxColor.set()
        }
        
        // draw the needle
        let needlePath = UIBezierPath()
        needlePath.lineWidth = needleWidth
        needlePath.moveToPoint(gaugeCenter)
        let needleLocation = GaugeViewDefaults.gaugeZero - (percent * (GaugeViewDefaults.gaugeZero - GaugeViewDefaults.gaugeMax))
        needlePath.addLineToPoint(radiansToRectangular(r:gaugeRadius, angle: needleLocation, offset: gaugeCenter))
        needlePath.stroke()
    }
    
    // calculate x,y in coordinate space from the center of the guage in polar
    private func radiansToRectangular(r r:CGFloat, angle:Double, offset: CGPoint) -> CGPoint
    {
        let x = Double(r)*cos(angle)
        let y = Double(r)*sin(angle) * -1.0
        return CGPoint(x: CGFloat(x) + offset.x , y: CGFloat (y) + offset.y )
        
    }

}
