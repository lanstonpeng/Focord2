//
//  PaperViewController.swift
//  CustomTransition
//
//  Created by Lanston Peng on 7/31/14.
//  Copyright (c) 2014 Vtm. All rights reserved.
//

import UIKit
import QuartzCore

class PaperViewController: UIViewController ,UIViewControllerTransitioningDelegate,UIGestureRecognizerDelegate,MotionManagerDelegate,GameCountingCircleDelegate{

    //MARK: helper property
    let sBounds = UIScreen.mainScreen().bounds
    var centerView : UIView?
    var animator: UIDynamicAnimator!
    
    //MARK: macro
    let RECORD_CELL_WIDTH:CGFloat = 120
    var interactSlideTransition:UIPercentDrivenInteractiveTransition?
    
    let CELL_FINAL_FRAME:CGRect
    //TODO:add page count support
    var pageCount = 5
    internal var currentIndex = 0
    internal var recodeIndex = 0
    
    var hasNextRecord:Bool = true
    var verticalLine:CAShapeLayer?
    
    
    //MARK: record cell property
    var pullDownSwipe:UIPanGestureRecognizer?
    
    var currentRecordCell:GameCountingCircleView?
    var copyRecordCell:GameCountingCircleView?
    
    var canDeleteRecordCell:Bool
    
    //MARK: cell drop gesture
    var dropCellPan:UIPanGestureRecognizer?
    var isLineAnimated:Bool
    
    //MARK: motionManager
    var motionManager:MotionManager?
    
    
    let WAITING_TIME:Int = 3
    required init(coder aDecoder: NSCoder)
    {
        
        CELL_FINAL_FRAME = CGRectMake(self.sBounds.width/2 - self.RECORD_CELL_WIDTH/2, self.sBounds.height/2 - self.RECORD_CELL_WIDTH/2, self.RECORD_CELL_WIDTH, self.RECORD_CELL_WIDTH)
        isLineAnimated = false
        canDeleteRecordCell = false
        super.init(coder: aDecoder)
    }
    func generateRandomColor() -> UIColor
    {
        let num = arc4random() % 4
        switch num
        {
        default:
            //return UIColor.whiteColor()
            //return UIColor(red: 77.0/255, green: 201.0/255, blue: 253.0/255, alpha: 1.0)
            //return UIColor(red: 254.0/255, green: 213.0/255, blue: 49.0/255, alpha: 1)
            return UIColor(red: 51.0/255, green: 51.0/255, blue: 51.0/255, alpha: 1)
        }
    }
    
    func initViewDecoration()
    {
        self.view.layer.shadowOpacity = 0.4
        self.view.layer.shadowOffset = CGSizeMake(0,2)
        self.view.layer.shadowColor = UIColor.blackColor().CGColor
        self.view.layer.shadowRadius = 5
        self.view.layer.masksToBounds = false
    }
    
    func addVisualRecordCellOnBoard(cell:RecordCell)
    {
        let tapGes:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handlePreviousRecordRellTap:")
        cell.addGestureRecognizer(tapGes)
        self.view.addSubview(cell)
    }
    
    //显示已记录cells
    func showPreviousRecordCell()
    {
        let recordData = DataManipulator.getAllRecords()
        
        let todayIDString = DataManipulator.getTodayStringID()
        
        if let todayRecord = recordData.objectForKey(todayIDString) as? NSDictionary
        {
            var idx:Int = 0
            for (key,item) in todayRecord
            {
                
                let f = CGRectMake( CGFloat(idx % 4) * (self.RECORD_CELL_WIDTH/2 + 10) + 10 , CGFloat(idx/4) * (self.RECORD_CELL_WIDTH/2 + 10) + 20, self.RECORD_CELL_WIDTH/2, self.RECORD_CELL_WIDTH/2)
                
                let cell = RecordCell(frame: f)
                cell.duration = item.objectForKey("duration") as CGFloat
                
                self.addVisualRecordCellOnBoard(cell)
                idx++
                recodeIndex = idx
            }
        }
        else
        {
            println("there's no today data")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //copy plist file
        DataManipulator.initFile()
        motionManager = MotionManager.instance
        motionManager?.delegate = self
        self.showPreviousRecordCell()
        self.createLine()
        
       
        
        
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
        
        //self.view.clipsToBounds = true
        let edgeSwipeGestureRight = UIScreenEdgePanGestureRecognizer(target: self, action: "handleTransitionRight:")
        edgeSwipeGestureRight.edges = .Right
        
        self.view.addGestureRecognizer(edgeSwipeGestureRight)
        
        self.view.backgroundColor = self.generateRandomColor()
        
        self.initViewDecoration()
        
        let edgeSwipeGestureLeft = UIScreenEdgePanGestureRecognizer(target: self, action: "handleTransitionLeft:")
        edgeSwipeGestureLeft.edges = .Left
        self.view.addGestureRecognizer(edgeSwipeGestureLeft)
        
        animator = UIDynamicAnimator(referenceView: view)
        centerView = UIView(frame: CELL_FINAL_FRAME)
        self.centerView?.alpha = 0
        
        self.addPullGesture()
        //self.initPic()
        
        
    }
    
    //MARK: touches Began
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        let t:UITouch = touches.anyObject() as UITouch
        if self.copyRecordCell != nil
        {
            if CGRectContainsPoint(CELL_FINAL_FRAME, t.locationInView(self.view))
            {
                self.removePullGesture()
            }
            else
            {
                if self.pullDownSwipe != nil
                {
                    //self.addPullGesture()
                }
            }
        }
        
    }
    //MARK: cell drop delete Gesture
    func addDropCellGesture()
    {
        dropCellPan = UIPanGestureRecognizer(target: self, action: "handleDropCell:")
        dropCellPan?.delegate = self
        self.copyRecordCell?.addGestureRecognizer(dropCellPan!)
    }
    func removeDropCellGesture()
    {
        self.copyRecordCell?.removeGestureRecognizer(dropCellPan!)
    }
    
    //MARK: paning copy record cell
    func handleDropCell(recognizer:UIPanGestureRecognizer)
    {
        if recognizer.state == .Began
        {
            self.removePullGesture()
            //var attach = UIAttachmentBehavior(item: self.currentRecordCell!, attachedToAnchor: CGPointMake(160, 300))
            //animator.addBehavior(attach)
        }
        else if recognizer.state == .Changed
        {
            let translation = recognizer.translationInView(self.view)
            
            recognizer.view.center = CGPoint(x:recognizer.view.center.x + translation.x,
                y:recognizer.view.center.y + translation.y)
            
            recognizer.setTranslation(CGPointZero, inView: recognizer.view)
        }
        else if recognizer.state == .Ended
        {
            let v = recognizer.velocityInView(self.view)
            
            if abs(v.x) < 50 && abs(v.y) < 50 || true
            {
                let curLocation = recognizer.locationInView(self.view)
                var factor:CGFloat = 1
                
                //if (v.x < 0 && v.y < 0 && ) || (v.x > 0 && v.y < 0) || (v.x > 0 && v.y > 0) || (v.x < 0 && v.y > 0)

                
                
                //TODO: determined the factor
                let velocity = sqrt(v.x * v.x + v.y * v.y)
                let dX = curLocation.x - sBounds.width/2
                let dY = curLocation.y - sBounds.height/2
                let distance = sqrt(dX * dX + dY * dY)
                
                UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: -velocity/distance, options: .CurveEaseOut | UIViewAnimationOptions.AllowUserInteraction, animations: {() -> Void in
                    
                    recognizer.view.center = CGPointMake(self.sBounds.width/2, self.sBounds.height/2)
                    
                    }, completion: { (completed) -> Void in
                        if self.pullDownSwipe?.delegate == nil
                        {
                            self.addPullGesture()
                        }
                })
            }
            else
            {
                //self.currentRecordCell?.removeFromSuperview()
                //canDeleteRecordCell = false
                //self.addPullGesture()
            }
        }

    }
    func removeRecordCell()
    {
    }
    
    //MARK: top pull down cell stuff
    func removePullGesture()
    {
        pullDownSwipe?.delegate = nil
        self.view.removeGestureRecognizer(pullDownSwipe!)
    }
    
    func addPullGesture()
    {
        pullDownSwipe = UIPanGestureRecognizer(target: self, action: "handlePullDown:")
        pullDownSwipe?.delegate = self
        self.view.addGestureRecognizer(pullDownSwipe!)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool
    {
        return true
    }
    
   
    //MARK: handle previous record cell tap 
    func handlePreviousRecordRellTap(recoginzer:UITapGestureRecognizer)
    {
        println(recoginzer.view)
    }
    
    
    //MARK: handle pull down
    func handlePullDown(recoginzer:UIPanGestureRecognizer)
    {
        let deltaY:CGFloat = recoginzer.translationInView(self.view).y
        
        let location:CGPoint = recoginzer.locationInView(self.view)
        
        
        if( recoginzer.state == UIGestureRecognizerState.Began)
        {
            //only accept pull down direction
            println("began \(deltaY)")
            if deltaY >= -0.5
            {
                canDeleteRecordCell = true
                //init a hidden record cell
                var recordCell:GameCountingCircleView = GameCountingCircleView(frame: CGRectMake(sBounds.width/2 - RECORD_CELL_WIDTH/2, -RECORD_CELL_WIDTH, RECORD_CELL_WIDTH, RECORD_CELL_WIDTH))
                recordCell.initData(toCount: 0, withStart: WAITING_TIME)
                
                
                /*
                self.copyRecordCell = self.currentRecordCell?.copy() as? RecordCell
                
                if self.copyRecordCell != nil
                {
                    self.view.addSubview(self.copyRecordCell!)
                }
                
                //if it has been dropped,remove it
                self.currentRecordCell?.removeFromSuperview()
                
                //self.copyRecordCell?.removeFromSuperview()
                */
                
                
                println("setting the new recordCell")
                self.currentRecordCell = recordCell
                self.view.addSubview(self.currentRecordCell!)
                self.removeDropCellGesture()
            }
        }
        
        
        //release your figure during the pulling
        if (recoginzer.state == UIGestureRecognizerState.Changed)
        {
            if(deltaY > 0)
            {
                //in pulling down process
                if(deltaY < 100)
                {
                    verticalLine!.path = self.getLinePathWithAmount(deltaY)
                    self.moveCopyRecordCell(deltaY)
                    self.currentRecordCell?.center.y = deltaY - RECORD_CELL_WIDTH
                    
                }
                // ready to present the dropping cell
                else
                {
                    canDeleteRecordCell = false
                    //self.removePullGesture()
                    self.animateLine(min(deltaY,100))
                    println("currentRecord Cell --- : \(self.currentRecordCell)")
                    self.presentRecordCell()
                }
            }
        }
        else if recoginzer.state == UIGestureRecognizerState.Ended
        {
            
            if deltaY > 0 && deltaY < 100
            {
                canDeleteRecordCell = true
                self.currentRecordCell?.removeFromSuperview()
                self.animateLine(deltaY)
                
                //back to original state
                
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                    self.copyRecordCell?.alpha = 1
                    self.copyRecordCell?.center = CGPointMake(self.sBounds.width/2, self.sBounds.height/2)
                    self.copyRecordCell?.transform = CGAffineTransformIdentity
                }, completion: { (completed) -> Void in
                })
                
            }
            else
            {
                
                
            }
            
        }
    }
    //MARK: record Cell
    func presentRecordCell()
    {
        self.removePullGesture()
        UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseIn, animations: {() -> Void in
            
                self.currentRecordCell!.frame = self.CELL_FINAL_FRAME
                if self.copyRecordCell != nil
                {
                    self.copyRecordCell!.frame = CGRectOffset(self.copyRecordCell!.frame,0,self.sBounds.height/2 + 100)
                }
            }, completion: {(completed:Bool ) -> Void in
            
                //copy the current record cell and remove it
                
                
                if self.copyRecordCell != nil
                {
                    //self.copyRecordCell?.layer.opacity = 0
                    self.copyRecordCell?.removeFromSuperview()
                }
                
                self.copyRecordCell = self.currentRecordCell?.copy() as GameCountingCircleView?
                self.copyRecordCell?.delegate = self
                
                println("present animation end")
                
                
                self.copyRecordCell?.frame = self.CELL_FINAL_FRAME
                
                self.view.addSubview(self.copyRecordCell!)
                
                self.currentRecordCell?.removeFromSuperview()
                self.currentRecordCell = nil
                self.addPullGesture()
                self.addDropCellGesture()
                
                self.copyRecordCell?.startCounting()
                self.motionManager?.startListen()
                
                
            })
    }
    
    //MARK: CAKeyFrameAnimation delegate
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool)
    {
        verticalLine!.path = self.getLinePathWithAmount(0.0)
        //self.addPullGesture()
        isLineAnimated = false
        
        if canDeleteRecordCell == true
        {
//            self.currentRecordCell?.removeFromSuperview()
//            self.currentRecordCell = nil
        }
        //motionManager!.boundView = currentRecordCell
        //self.currentRecordCell?.addBreathingAnimation()
        verticalLine?.removeAllAnimations()
        
    }
    
    func moveCopyRecordCell(PositionY:CGFloat)
    {
        let value = PositionY / sBounds.height/2 * 2;
        self.copyRecordCell?.alpha = 1 - value * 2
        self.copyRecordCell?.center.y = sBounds.height/2 + PositionY * 3.5
        self.copyRecordCell?.transform = CGAffineTransformMakeScale(1 - value * 2, 1 - value * 2)
    }
    func animateLine(PositionY:CGFloat)
    {
        if isLineAnimated == false
        {
            isLineAnimated = true
            let keyFA:CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "path")
            keyFA.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            let values:NSArray = [
                self.getLinePathWithAmount(PositionY),
                self.getLinePathWithAmount(-PositionY * 0.9),
                self.getLinePathWithAmount(PositionY * 0.6),
                self.getLinePathWithAmount(-PositionY * 0.4),
                self.getLinePathWithAmount(PositionY * 0.25),
                self.getLinePathWithAmount(PositionY * 0)
            ]
            keyFA.values = values
            keyFA.duration = 0.6
            keyFA.removedOnCompletion = false
            keyFA.fillMode = kCAFillModeForwards
            keyFA.delegate = self
            verticalLine?.addAnimation(keyFA, forKey: "pullAnimation")
        }
        
    }
    
    
    func createLine() -> Void
    {
        verticalLine = CAShapeLayer()
        //verticalLine!.strokeColor = UIColor.whiteColor().CGColor
        verticalLine!.strokeColor  = UIColor(red: 0.0/255, green: 206.0/255, blue: 97.0/255, alpha: 1.0).CGColor
        verticalLine!.lineWidth = 2.0
        verticalLine!.fillColor = UIColor(red: 0.0/255, green: 206.0/255, blue: 97.0/255, alpha: 1.0).CGColor
        self.view.layer.addSublayer(verticalLine)
    }
    
    
    func getLinePathWithAmount(amount:CGFloat)  -> CGPathRef
    {
        var bezierPath = UIBezierPath()
        var topPoint:CGPoint = CGPointMake(amount,-1)
        var midPoint:CGPoint = CGPointMake(self.view.bounds.size.width/2,amount)
        var bottomPoint:CGPoint = CGPointMake( self.view.bounds.size.width - amount,-1)
        
        bezierPath.moveToPoint(topPoint)
        bezierPath.addQuadCurveToPoint(bottomPoint, controlPoint: midPoint)
        return bezierPath.CGPath
    }
    
    
    
    //MARK: view controller 切换动画相关
    //MARK: Screen Edge Gesture
    func handleTransitionLeft(recognizer:UIScreenEdgePanGestureRecognizer)
    {
        
        var progress:CGFloat  = recognizer.locationInView(self.view.superview).x / (self.view.superview!.bounds.size.width * 1.0)
        progress = min(1.0,max(0.0,progress))
        if recognizer.state == .Began
        {
            self.interactSlideTransition = UIPercentDrivenInteractiveTransition()
            self.removePullGesture()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        else if recognizer.state == .Changed
        {
            self.interactSlideTransition?.updateInteractiveTransition(progress)
        }
        else if recognizer.state == .Ended || recognizer.state == .Cancelled
        {
            if progress > 0.5
            {
                self.interactSlideTransition?.finishInteractiveTransition()
            }
            else
            {
                self.interactSlideTransition?.cancelInteractiveTransition()
            }
            //self.interactSlideTransition = nil
        }
    }
    
    func handleTransitionRight(recognizer:UIScreenEdgePanGestureRecognizer)
    {
        var progress:CGFloat  = recognizer.locationInView(self.view.superview).x / (self.view.superview!.bounds.size.width * 1.0)
        progress = 1.0 - min(1.0,max(0.0,progress))
        //println("progress \(progress)")
        if recognizer.state == .Began
        {
            self.interactSlideTransition = UIPercentDrivenInteractiveTransition()
            self.removePullGesture()
            let toVC = self.storyboard.instantiateViewControllerWithIdentifier("PaperViewController") as PaperViewController
            toVC.currentIndex = self.currentIndex + 1
            toVC.interactSlideTransition = self.interactSlideTransition
            
            self.presentViewController(toVC, animated: true, completion: nil)
            
        }
        else if recognizer.state == .Changed
        {
            self.interactSlideTransition?.updateInteractiveTransition(progress)
        }
        else if recognizer.state == .Ended || recognizer.state == .Cancelled
        {
            if progress > 0.5
            {
                self.interactSlideTransition?.finishInteractiveTransition()
            }
            else
            {
                self.interactSlideTransition?.cancelInteractiveTransition()
            }
            //self.interactSlideTransition = nil
        }
    }
    
    func initPic()
    {
        var q = dispatch_queue_create("getimage", nil)
        let screen = UIScreen.mainScreen().bounds
        let url = NSURL(string: "http://lorempixel.com/320/568/")
        var data:NSData?
        var image:UIImage?
        let imageView:UIImageView = UIImageView(frame: screen)
        dispatch_async(q, {
            data = NSData(contentsOfURL: url)
            image = UIImage(data: data)
            dispatch_sync(dispatch_get_main_queue(), {
                imageView.image = image
                imageView.alpha = 0
                self.view.addSubview(imageView)
                UIView.animateWithDuration(0.3, animations: {()->Void in
                    imageView.alpha = 1
                    })
                })
            })
    }
    
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning!) -> UIViewControllerInteractiveTransitioning!
    {
        return self.interactSlideTransition
    }
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning!) -> UIViewControllerInteractiveTransitioning!
    {
        return  self.interactSlideTransition
    }

    func animationControllerForPresentedController(presented: UIViewController!, presentingController presenting: UIViewController!, sourceController source: UIViewController!) -> UIViewControllerAnimatedTransitioning!
    {
        if presented == self
        {
            return TransitionManager(isPresent: true)
        }
        return nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController!) -> UIViewControllerAnimatedTransitioning!
    {
        if dismissed == self
        {
            return TransitionManager(isPresent: false)
        }
        return nil
    }
    
    
    
    //MARK: Motion Delegate
    func deviceDidFlipToBack() {
        println("did flip to back \(motionManager!.duration)")
        
        //reset the circle view
        self.copyRecordCell?.pieCapacity = 360
        self.copyRecordCell?.currentCount = WAITING_TIME
        
        self.copyRecordCell?.stopCounting()
        self.copyRecordCell?.totalCount += 1
        self.copyRecordCell?.bigifyCircleByUnit()
    }
    
    func deviceDidFlipToFront() {
        println("did flip to front \(motionManager!.duration)")
        self.copyRecordCell?.startCounting()
    }
    
    //MARK: Game Counting Circle Delegate
    func  GameCountingCircleDidEndCount(circleKey: NSString) {
        self.copyRecordCell?.stopCounting()
        self.copyRecordCell?.delegate = nil
        
        //已经翻转过，记录过时间
        if self.copyRecordCell?.totalCount > 0
        {
            DataManipulator.addRecord(self.copyRecordCell!)
            self.moveToProperPlace(self.copyRecordCell!)
        }
        //未翻转，删除cell
        else
        {
            //self.removeCurrentRecord()
            self.moveToProperPlace(self.copyRecordCell!)
        }
    }
    
    func GameCountingCircleDidChange(circleKey: NSString) {
        
    }
    
    //放置拥有记录的cell
    func moveToProperPlace(cell:GameCountingCircleView)
    {
        
        let idx = recodeIndex + 1
        let f = CGRectMake( CGFloat(idx % 4) * (self.RECORD_CELL_WIDTH/2 + 10) + 10 , CGFloat(idx/4) * (self.RECORD_CELL_WIDTH/2 + 10) + 20, self.RECORD_CELL_WIDTH/2, self.RECORD_CELL_WIDTH/2)
        
        cell.stopCounting()
        /*
        UIView.animateWithDuration(2.3, animations: { () -> Void in
            cell.frame = f;
            }) { (completed:Bool) -> Void in
            self.removeCurrentRecord()
        }
        */
        //drop down
        cell.dropCicleView()
    }
    
    func removeCurrentRecord()
    {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.copyRecordCell?.alpha = 0
            self.copyRecordCell?.center.y += 30
            }) { (completed:Bool) -> Void in
                if completed
                {
                    self.copyRecordCell?.removeFromSuperview()
                }
        }
        self.copyRecordCell = nil
        motionManager?.stopListen()
    }
}
