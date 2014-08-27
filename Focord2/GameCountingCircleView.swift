//
//  GameCountingCircleView.swift
//  Focord2
//
//  Created by Lanston Peng on 8/20/14.
//  Copyright (c) 2014 Vtm. All rights reserved.
//

import UIKit
import CoreMotion


protocol GameCountingCircleDelegate:NSObjectProtocol
{
    func GameCountingCircleDidEndCount(circleKey:NSString)
    func GameCountingCircleDidChange(circleKey:NSString)
}

class GameCountingCircleView: UIView,NSCopying {

    var indicatorLabel:UILabel?
    
    var pieCapacity:CGFloat{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var clockWise:Int32!//0=逆时针,1=顺时针
    
    var currentCount:Int
    
    var deltaCount:Int!
    
    var destinationCount:Int
    
    var circleKey:NSString!
    
    var frontColor:UIColor!
    
    var circleColor:UIColor!
    
    var delegate:GameCountingCircleDelegate?
    
    let frontLayer:CALayer!
    
    let frontBgLayer:CALayer!
    
    let circleLayer:CAShapeLayer!
    
    var timer:NSTimer?
    
    var startX:CGFloat!
    var startY:CGFloat!
    var radius:CGFloat!
    var pieStart:CGFloat!
//    func addCount(deltaNum:Int)
//    func addCount(deltaNum:Int isReverse:Bool)
//    func initShapeLayer()

    internal var f:CGRect!
    internal var addCountCurrentNumber:CGFloat
    
    var animator:UIDynamicAnimator!
    var gravity:UIGravityBehavior!
    var collision:UICollisionBehavior!
    
    var totalCount: Int {
        didSet {
            self.indicatorLabel?.text = "\(totalCount)"
        }
    }
    override init(frame: CGRect) {
        f = frame
        addCountCurrentNumber = 0
        pieStart = 270
        pieCapacity = 360
        clockWise = 0
        currentCount = 0
        deltaCount = 0
        destinationCount = 0
        circleKey = "timeCount"
        
        frontLayer = CALayer()
        frontBgLayer = CALayer()
        circleLayer = CAShapeLayer()
        totalCount = 0
        
        super.init(frame: frame)
        
        let smallerFrame:CGRect = CGRectInset(self.bounds, 10, 10)
        radius = smallerFrame.size.width/2 + 1
        startX = self.bounds.size.width/2
        startY = self.bounds.size.height/2
        self.backgroundColor = UIColor.clearColor()
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        
        frontLayer.frame = smallerFrame
        frontLayer.backgroundColor = UIColor(red: 0.0/255, green: 206.0/255, blue: 97.0/255, alpha: 1.0).CGColor
        frontLayer.cornerRadius = smallerFrame.size.width / 2;
        
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.strokeStart = 0;
        circleLayer.strokeEnd = 1;
        circleLayer.lineWidth = 5;
        circleLayer.lineCap = "round";
        
        self.layer.addSublayer(frontLayer)
        self.layer.insertSublayer(circleLayer, below:frontLayer)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        f = CGRectZero
        currentCount = 0
        addCountCurrentNumber = 0
        destinationCount = 0
        pieCapacity = 360
        totalCount = 0
        
        
        //super.init()
        super.init(coder: aDecoder)
        
    }
    
    func startCounting()
    {
        if timer == nil
        {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0/30, target: self, selector: "updateSector", userInfo: nil, repeats: true)
        }
    }
    
    func stopCounting(){
        timer?.invalidate()
        timer = nil
    }
    
    func initData(toCount desCount:Int,withStart startCount:Int)
    {
        indicatorLabel = UILabel(frame:self.bounds)
        self.currentCount = startCount;
        destinationCount = desCount;
        deltaCount = abs(destinationCount - startCount)
        indicatorLabel?.textAlignment = NSTextAlignment.Center
        //indicatorLabel?.textColor = UIColor(red: 254.0/255, green: 213.0/255, blue: 49.0/255, alpha: 1)
        indicatorLabel?.textColor = UIColor.whiteColor()
        indicatorLabel?.font = UIFont(name: "AppleSDGothicNeo-Thin", size: 40.0)
        indicatorLabel?.adjustsFontSizeToFitWidth = true
        indicatorLabel?.layer.shadowOpacity = 0.5
        indicatorLabel?.layer.shadowOffset = CGSizeMake(0,2)
        indicatorLabel?.layer.shadowColor = UIColor.blackColor().CGColor
        indicatorLabel?.layer.shadowRadius = 1.5
        indicatorLabel?.layer.masksToBounds = false
        indicatorLabel?.text = "0"
        self.addSubview(indicatorLabel!)
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject! {
        let c:GameCountingCircleView = GameCountingCircleView(frame: self.f)
        c.initData(toCount: self.destinationCount, withStart: self.currentCount)
        c.indicatorLabel?.text = self.indicatorLabel?.text
        return c
    }
    
    func bigifyCircleByUnit()
    {
        frontLayer.frame = CGRectInset(frontLayer.frame, -1, -1)
        self.bounds = CGRectInset(self.bounds, -1, -1)
        frontLayer.cornerRadius = frontLayer.frame.size.width / 2;
        radius = frontLayer.frame.size.width/2 + 1
    }
    
    func dropCicleView()
    {
        if animator == nil
        {
            animator = UIDynamicAnimator(referenceView: self.superview)
            collision = UICollisionBehavior(items: [self])
            collision.translatesReferenceBoundsIntoBoundary = true
            gravity = UIGravityBehavior(items: [self])
            animator.addBehavior(collision)
            
            MotionManager.instance.startListenDeviceMotion({ (deviceMotion:CMDeviceMotion!, error:NSError!) -> Void in
                let gravityVector:CMAcceleration = deviceMotion.gravity
                self.gravity.gravityDirection = CGVectorMake(CGFloat(gravityVector.x), CGFloat(-gravityVector.y))
            })
        }
        animator.addBehavior(gravity)
    }
    
    func updateSector()
    {
        //pieCapacity += 360.0 / CGFloat(destinationCount / (1.0) / 30.0 )
        pieCapacity -= 18 * 1/30
        
        addCountCurrentNumber += 1
        if addCountCurrentNumber >= 30
        {
            addCountCurrentNumber = 0
            currentCount -= 1
            if  currentCount == destinationCount
            {
                self.delegate?.GameCountingCircleDidEndCount(self.circleKey)
            }
            else
            {
                self.delegate?.GameCountingCircleDidChange(self.circleKey)
            }
        }
        //self.setNeedsDisplay()
        
    }
    func DEG2RAD(angle:CGFloat) -> CGFloat
    {
        return ( angle ) * 3.1415926 / 180.0
    }
    
    override func drawRect(rect: CGRect) {
        let context:CGContextRef = UIGraphicsGetCurrentContext();
        //CGContextSetRGBStrokeColor(context, 0, 1, 1, 1);
        CGContextSetStrokeColorWithColor(context, UIColor(red: 254.0/255, green: 213.0/255, blue: 49.0/255, alpha: 1).CGColor);
        CGContextSetLineWidth(context, 5);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextAddArc(context, startX, startY, radius, self.DEG2RAD(pieStart), self.DEG2RAD(pieStart + pieCapacity), clockWise);
        CGContextStrokePath(context);
    }
    
}
