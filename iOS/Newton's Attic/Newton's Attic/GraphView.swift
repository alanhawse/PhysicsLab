//
//  GraphView.swift
//  Calculator
//
//  Created by Alan Hawse on 4/29/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    // Used for the line graph
    func getValYforX(x: Double) -> Double?
    // Used for the Scatter Graph
    // the return Int is the pass #
    // the return Float is the yvalue
    func getValYforXPosition(x: Int, range: Int) -> [Int:Double]?
    
}

@IBDesignable
class GraphView: UIView {
    
    private struct GraphViewDefaults {
        
        static let graphLineWidth : CGFloat = 1
        static let graphLineColor = UIColor.blackColor()
        
        static let axisColor = UIColor.redColor()
        
        static let numOfYTicks = 4
        static let sizeOfYTick : CGFloat = 10
        static let yTickLabelOffset : CGFloat = 3 // how far left of the tickmark
        static let yTickColor = UIColor.redColor()
        
        static let numOfXTicks = 4
        static let sizeOfXTick : CGFloat = 5
        static let xTickLabelOffset : CGFloat = 10 // how far below the tickmark
        static let xTickColor = UIColor.redColor()
        
        static let sizeOfCross : Double = 2.0
        static let crossColorArray  = [UIColor.blueColor(), UIColor.redColor(), UIColor.purpleColor(), UIColor.greenColor(), UIColor.brownColor(), UIColor.blackColor()]
        
        
        // left right top and bottom "margin"
        static let graphPercentOfXMin : CGFloat = 0.1
        static let graphPercentOfXMax : CGFloat = 0.95
        static let graphPercentOfYMin : CGFloat = 0.05
        static let graphPercentOfYMax : CGFloat = 0.95
        
    }
    
    // MARK: - Public Interface
    var dataSource : GraphViewDataSource?
    
    var xAxisLabel = "s"
    var yAxisLabel = "g"
    
    // rangeX and rangeY is almost certainly overwritten when you start
    var rangeX : (min:CGFloat,max:CGFloat) = (0.0,20.0) { didSet {self.setNeedsDisplay()} }
    var rangeY : (min:CGFloat,max:CGFloat) = (-4.0,4.0) { didSet {self.setNeedsDisplay()} }
    
    enum GraphTypes {
        case Line
        case Scatter
    }
    
    var graphType : GraphTypes = .Line { didSet {self.setNeedsDisplay()} }
    
    
    // MARK: - Private Configuration
    
    private var xstart : CGFloat { return bounds.width * GraphViewDefaults.graphPercentOfXMin }
    private var xend : CGFloat { return bounds.width * GraphViewDefaults.graphPercentOfXMax }
    private var ystart : CGFloat { return bounds.height * GraphViewDefaults.graphPercentOfYMin }
    private var yend : CGFloat { return bounds.height * GraphViewDefaults.graphPercentOfYMax }
    
    private var yaxis : CGFloat {return ystart + (yend-ystart)/2 }
    
    private var xScale : CGFloat { return (rangeX.max-rangeX.min) / (xend - xstart)  }

    private var yScale : CGFloat {return (rangeY.max-rangeY.min) / (yend - ystart) }
 
    
    // MARK: - Drawing functions
    override func drawRect(rect: CGRect) {
        drawAxis()
        
        switch graphType
        {
        case .Line:
            drawLineGraph()
        case .Scatter:
            drawScatterGraph()
        }
    }
    
    
    private func drawAxis()
    {
        GraphViewDefaults.axisColor.set()
        let bp = UIBezierPath()

        // draw x-axis
        bp.moveToPoint(CGPoint(x:xstart,y:yaxis))
        bp.addLineToPoint(CGPoint(x:xend,y:yaxis))
        
        // draw y-axis
        bp.moveToPoint(CGPoint(x:xstart,y:ystart))
        bp.addLineToPoint(CGPoint(x:xstart,y:yend))
        bp.stroke()
        
        drawYAxisLabel(x: xstart, y: yaxis)
        
        drawXTicksLabels(y:yaxis)
        drawYTicksLabels(x:xstart)
        
        drawXAxisLabel(x: xend, y: yaxis)
    }
    
    private func drawXTicksLabels(y  y: CGFloat)
    {
        let bp = UIBezierPath()
        GraphViewDefaults.xTickColor.set()
   
        let increment = (xend-xstart) / CGFloat(GraphViewDefaults.numOfXTicks)
        for i in 1...GraphViewDefaults.numOfXTicks {
            let x = xstart + (CGFloat(i) * increment)
            bp.moveToPoint(CGPoint(x:x,y:y-GraphViewDefaults.sizeOfXTick))
            bp.addLineToPoint(CGPoint(x:x,y:y+GraphViewDefaults.sizeOfXTick))

            let transX = Int(rangeX.min) + i * Int(rangeX.max - rangeX.min) / GraphViewDefaults.numOfXTicks
            
            let label = "\(transX)"
            let sizeV = label.sizeWithAttributes(nil)
            let pnt1 = CGPoint(x: x - sizeV.width/2, y: y + GraphViewDefaults.xTickLabelOffset - sizeV.height/2)
            let rect = CGRect(origin: pnt1, size: sizeV)
            label.drawInRect(rect, withAttributes: nil)
        }
        bp.stroke()
    }
    
    private func drawYTicksLabels(x  x: CGFloat)
    {
        let bp = UIBezierPath()
        GraphViewDefaults.yTickColor.set()
        
        let increment = (yend - ystart) / CGFloat(GraphViewDefaults.numOfYTicks)
        
        for i in 0...Int(GraphViewDefaults.numOfYTicks) {
            let calcy = yend - (CGFloat(i)*increment)
            bp.moveToPoint(CGPoint(x:x,y:calcy))
            bp.addLineToPoint(CGPoint(x:x+GraphViewDefaults.sizeOfYTick,y:calcy))
            let transY = i*(Int(rangeY.max - rangeY.min) / GraphViewDefaults.numOfYTicks) + Int(rangeY.min)
            let label = "\(transY)"
            let sizeV = label.sizeWithAttributes(nil)
            let pnt1 = CGPoint(x: x - sizeV.width - GraphViewDefaults.yTickLabelOffset, y: calcy - sizeV.height/2)
            let rect = CGRect(origin: pnt1, size: sizeV)
            label.drawInRect(rect, withAttributes: nil)
        }
        bp.stroke()
    }
    
    private func drawYAxisLabel( x x: CGFloat, y: CGFloat)
    {
        //let label = "g"
        
        let sizeV = yAxisLabel.sizeWithAttributes(nil)
        let pnt1 = CGPoint(x: 0, y: y  /*- sizeV.height/2*/)
        let rect = CGRect(origin: pnt1, size: sizeV)
        yAxisLabel.drawInRect(rect, withAttributes: nil)
      
    }
    
    private func drawXAxisLabel( x x: CGFloat, y: CGFloat)
    {
        //let xlabel = "s"

        let sizeV = xAxisLabel.sizeWithAttributes(nil)
        let pnt1 = CGPoint(x: x - 0*sizeV.width, y: y + sizeV.height)
        let rect = CGRect(origin: pnt1, size: sizeV)
        xAxisLabel.drawInRect(rect, withAttributes: nil)
        
    }

    // MARK: - Plotting Functions
    
    private func drawLineGraph()
    {
        GraphViewDefaults.graphLineColor.set()
        
        let num = Int(xend-xstart)
        let bp = UIBezierPath()
        
        bp.lineWidth = GraphViewDefaults.graphLineWidth
        
        bp.moveToPoint(CGPoint(x:xstart,y:yaxis))
        
        for i in 0...num {
            let evalx = CGFloat(i) / CGFloat(num) * (rangeX.max - rangeX.min)
            if let evaly = dataSource?.getValYforX(Double(evalx))
            {
                let yVal = yend - ((CGFloat(evaly) - rangeY.min) / (rangeY.max - rangeY.min) *  CGFloat(yend - ystart) )
                bp.addLineToPoint(CGPoint(x:CGFloat(i)+xstart,y:yVal))
            }
        }
        bp.stroke()
    }
    
    private func drawScatterGraph()
    {
        let num = Int(xend-xstart)
        
        let increment = Double(rangeX.max - rangeX.min) / Double(num) * Double(100.0)
        
        for i in 0...num {
            let xfunc = Double(i) / Double(xend-xstart) * Double(rangeX.max - rangeX.min) * 100
            if let ys = dataSource?.getValYforXPosition(Int(xfunc), range: Int(increment))
            {
                for evaly in ys {
                    GraphViewDefaults.crossColorArray[evaly.0].set()
                    // convert yval to iPhone coordinates
                    let a1 = CGFloat(evaly.1 - Double(rangeY.min))
                    let a2 = CGFloat(rangeY.max - rangeY.min)
                    let a3 = CGFloat(yend - ystart)
                    let yVal = CGFloat(yend) - ( a1/a2*a3)
                    drawCross(x: Double(i)+Double(xstart), y: Double(yVal))
                }
            }
        }
    }
    
    // x + y are in the iPhone coordinates
    private func drawCross(x x: Double, y: Double)
    {
        let bp = UIBezierPath()
        bp.moveToPoint(CGPoint(x:CGFloat(x),y:CGFloat(y+GraphViewDefaults.sizeOfCross)))
        bp.addLineToPoint(CGPoint(x:CGFloat(x),y:CGFloat(y-GraphViewDefaults.sizeOfCross)))
        bp.moveToPoint(CGPoint(x:CGFloat(x-GraphViewDefaults.sizeOfCross),y:CGFloat(y)))
        bp.addLineToPoint(CGPoint(x:CGFloat(x+GraphViewDefaults.sizeOfCross),y:CGFloat(y)))
        bp.stroke()
    }
}
