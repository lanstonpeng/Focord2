//
//  CircleView.swift
//  Focord2
//
//  Created by Lanston Peng on 8/12/14.
//  Copyright (c) 2014 Vtm. All rights reserved.
//

import UIKit
import QuartzCore

class CircleView: UIView {

    
    var radius:CGFloat = 40//半径
    var startX:CGFloat = 50//圆心x坐标
    var startY:CGFloat = 50//圆心y坐标
    var pieStart:CGFloat = 0//起始的角度
    var pieCapacity:CGFloat = 10//角度增量值
    var clockwise:Int32 = 1//0=逆时针,1=顺时针
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect) {
        startX = 20
        startY = 20
        //NSTimer.scheduledTimerWithTimeInterval(1/60, target: self, selector: "updateSector", userInfo: nil, repeats: true)
        super.init(frame: frame)
    }
    func radians(degree:CGFloat) -> CGFloat
    {
       return 3.1415926 * degree / 180
    }
    
    func updateSector()
    {
        pieCapacity += 0.1
        self.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect)
    {
        let context:CGContextRef = UIGraphicsGetCurrentContext()
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1)
        //CGContextSetLineWidth(context, 0.6)
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0)
        CGContextMoveToPoint(context, startX, startY)
        CGContextAddArc(context, startX, startY, radius, radians(pieStart), radians(pieStart+pieCapacity), clockwise)
        CGContextFillPath(context)
        CGContextClosePath(context)
        //CGContextDrawPath(context, kCGPathEOFillStroke)
    }

}
