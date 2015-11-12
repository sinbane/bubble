//
//  BubbleControl.swift
//  BubbleControl-Swift
//
//  Created by Cem Olcay on 11/12/14.
//  Copyright (c) 2014 Cem Olcay. All rights reserved.
//
//  https://github.com/cemolcay/BubbleControl-Swift

import UIKit

let APPDELEGATE: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate



// MARK: - Animation Constants

private let BubbleControlMoveAnimationDuration: NSTimeInterval = 0.5
private let BubbleControlSpringDamping: CGFloat = 0.6
private let BubbleControlSpringVelocity: CGFloat = 0.6


// MARK: - UIView Extension

extension UIView {
    
    
    // MARK: Frame Extensions
    
    var x: CGFloat {
        get {
            return self.frame.origin.x
        } set (value) {
            self.frame = CGRect (x: value, y: self.y, width: self.w, height: self.h)
        }
    }
    
    var y: CGFloat {
        get {
            return self.frame.origin.y
        } set (value) {
            self.frame = CGRect (x: self.x, y: value, width: self.w, height: self.h)
        }
    }
    
    var w: CGFloat {
        get {
            return self.frame.size.width
        } set (value) {
            self.frame = CGRect (x: self.x, y: self.y, width: value, height: self.h)
        }
    }
    
    var h: CGFloat {
        get {
            return self.frame.size.height
        } set (value) {
            self.frame = CGRect (x: self.x, y: self.y, width: self.w, height: value)
        }
    }
    
    
    var position: CGPoint {
        get {
            return self.frame.origin
        } set (value) {
            self.frame = CGRect (origin: value, size: self.frame.size)
        }
    }
    
    var size: CGSize {
        get {
            return self.frame.size
        } set (value) {
            self.frame = CGRect (origin: self.frame.origin, size: size)
        }
    }
    
    
    var left: CGFloat {
        get {
            return self.x
        } set (value) {
            self.x = value
        }
    }
    
    var right: CGFloat {
        get {
            return self.x + self.w
        } set (value) {
            self.x = value - self.w
        }
    }
    
    var top: CGFloat {
        get {
            return self.y
        } set (value) {
            self.y = value
        }
    }
    
    var bottom: CGFloat {
        get {
            return self.y + self.h
        } set (value) {
            self.y = value - self.h
        }
    }
    
    
    
    func leftWithOffset (offset: CGFloat) -> CGFloat {
        return self.left - offset
    }
    
    func rightWithOffset (offset: CGFloat) -> CGFloat {
        return self.right + offset
    }
    
    func topWithOffset (offset: CGFloat) -> CGFloat {
        return self.top - offset
    }
    
    func botttomWithOffset (offset: CGFloat) -> CGFloat {
        return self.bottom + offset
    }
    
    
    
    func spring (animations: ()->Void, completion:((Bool)->Void)?) {
        UIView.animateWithDuration(BubbleControlMoveAnimationDuration,
            delay: 0,
            usingSpringWithDamping: BubbleControlSpringDamping,
            initialSpringVelocity: BubbleControlSpringVelocity,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: animations,
            completion: completion)
    }
    
    
    func moveY (y: CGFloat) {
        var moveRect = self.frame
        moveRect.origin.y = y
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    func moveX (x: CGFloat) {
        var moveRect = self.frame
        moveRect.origin.x = x
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    func movePoint (x: CGFloat, y: CGFloat) {
        var moveRect = self.frame
        moveRect.origin.x = x
        moveRect.origin.y = y
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    func movePoint (point: CGPoint) {
        var moveRect = self.frame
        moveRect.origin = point
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    
    func setScale (s: CGFloat) {
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / -1000.0
        transform = CATransform3DScale(transform, s, s, s)
        
        self.layer.transform = transform
    }
    
    func alphaTo (to: CGFloat) {
        UIView.animateWithDuration(BubbleControlMoveAnimationDuration,
            animations: {
                self.alpha = to
        })
    }
    
    func bubble () {
        
        self.setScale(1.2)
        spring({ () -> Void in
            self.setScale(1)
            }, completion: nil)
    }
}


// MARK: - BubbleControl

class BubbleControl: UIControl {
    
    
    // MARK: Constants
    
    let popTriggerDuration: NSTimeInterval = 0.5
    let popAnimationDuration: NSTimeInterval = 1
    let popAnimationShakeDuration: NSTimeInterval = 0.10
    let popAnimationShakeRotations: (CGFloat, CGFloat) = (-30, 30)
    let popAnimationScale: CGFloat = 1.2
    
    let snapOffsetMin: CGFloat = 10
    let snapOffsetMax: CGFloat = 50
    
    
    
    // MARK: Optionals
    
    var contentView: UIView?
    
    var snapsInside: Bool = false
    var popsToNavBar: Bool = true
    var movesBottom: Bool = false
    
    
    
    // MARK: Actions
    
    var didToggle: ((Bool) -> ())?
    var didNavigationBarButtonPressed: (() -> ())?
    var didPop: (()->())?
    
    var setOpenAnimation: ((contentView: UIView, backgroundView: UIView?)->())?
    var setCloseAnimation: ((contentView: UIView, backgroundView: UIView?) -> ())?
    
    
    
    // MARK: Bubble State
    
    enum BubbleControlState {
        case Snap       // snapped to edge
        case Drag       // dragging around
        case Pop        // long pressed and popping
        case NavBar     // popped and went to nav bar
    }
    
    var bubbleState: BubbleControlState = .Snap {
        didSet {
            if bubbleState == .Snap {
                setupSnapInsideTimer()
            } else {
                snapOffset = snapOffsetMin
            }
        }
    }
    
    
    
    // MARK: Snap
    
    private var snapOffset: CGFloat!
    
    private var snapInTimer: NSTimer?
    private var snapInInterval: NSTimeInterval = 2
    
    
    
    // MARK: Toggle
    
    private var positionBeforeToggle: CGPoint?
    
    var toggle: Bool = false {
        didSet {
            didToggle? (toggle)
            if toggle {
                openContentView()
            } else {
                closeContentView()
            }
        }
    }
    
    
    
    // MARK: Navigation Button
    
    private var barButtonItem: UIBarButtonItem?
    
    
    
    // MARK: Badge
    
    private var badgeLabel: UILabel?
    
    var badgeCount: Int = 0 {
        didSet {
            if badgeCount < 0 {
                badgeCount = 0
            } else if badgeCount > 0 {
                badgeLabel?.hidden = false
                badgeLabel?.text = "\(badgeCount)"
                badgeLabel?.bubble()
            } else {
                badgeLabel?.hidden = true
            }
            
            barButtonItem?.setBadgeValue(badgeCount)
        }
    }
    
    
    
    // MARK: Image
    
    var imageView: UIImageView?
    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
    
    
    
    // MARK: Init
    
    init (size: CGSize) {
        super.init(frame: CGRect (origin: CGPointZero, size: size))
        defaultInit()
    }
    
    init (image: UIImage) {
        let size = image.size
        super.init(frame: CGRect (origin: CGPointZero, size: size))
        self.image = image
        
        defaultInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func defaultInit () {
        
        // self
        snapOffset = snapOffsetMin
        layer.cornerRadius = w/2
        
        
        // image view
        imageView = UIImageView (frame: CGRectInset(frame, 20, 20))
        addSubview(imageView!)
        
        
        // circle border
        let borderView = UIView (frame: frame)
        borderView.layer.borderColor = UIColor.blackColor().CGColor
        borderView.layer.borderWidth = 2
        borderView.layer.cornerRadius = w/2
        borderView.layer.masksToBounds = true
        borderView.userInteractionEnabled = false
        addSubview(borderView)
        
        
        // badge label
        badgeLabel = UILabel (frame: CGRectInset(frame, 25, 25))
        badgeLabel?.center = CGPointMake(left + badgeLabel!.w/2, top + badgeLabel!.h/2)
        badgeLabel?.backgroundColor = UIColor.redColor()
        badgeLabel?.textAlignment = NSTextAlignment.Center
        badgeLabel?.textColor = UIColor.whiteColor()
        badgeLabel?.text = "\(badgeCount)"
        badgeLabel?.layer.cornerRadius = badgeLabel!.w/2
        badgeLabel?.layer.masksToBounds = true
        addSubview(badgeLabel!)
        
        badgeCount = 0
        
        
        // events
        addTarget(self, action: "touchDown", forControlEvents: UIControlEvents.TouchDown)
        addTarget(self, action: "touchUp", forControlEvents: UIControlEvents.TouchUpInside)
        addTarget(self, action: "touchDrag:event:", forControlEvents: UIControlEvents.TouchDragInside)
        
        let longPress = UILongPressGestureRecognizer (target: self, action: "longPressHandler:")
        longPress.minimumPressDuration = 0.75
        addGestureRecognizer(longPress)
        
        
        // place
        center.x = APPDELEGATE.window!.w - w/2 + snapOffset
        center.y = 84 + h/2
        snap()
    }
    
    
    
    // MARK: Snap To Edge
    
    func snap () {
        let window = APPDELEGATE.window!
        
        // if control on left side
        var targetX = window.leftWithOffset(snapOffset)
        var badgeTargetX = w - badgeLabel!.w
        
        
        // if control on right side
        if center.x > window.w/2 {
            targetX = window.rightWithOffset(snapOffset) - w
            badgeTargetX = 0
        }
        
        // move to snap position
        moveX(targetX)
        badgeLabel!.moveX(badgeTargetX)
    }
    
    func snapInside () {
        print("snap inside !")
        if !toggle && bubbleState == .Snap {
            snapOffset = snapOffsetMax
            snap()
        }
    }
    
    func setupSnapInsideTimer () {
        if !snapsInside {
            return
        }
        
        if let timer = snapInTimer {
            if timer.valid {
                timer.invalidate()
            }
        }
        
        snapInTimer = NSTimer.scheduledTimerWithTimeInterval(snapInInterval,
            target: self,
            selector: Selector("snapInside"),
            userInfo: nil,
            repeats: false)
    }
    
    
    func lockInWindowBounds () {
        let window = APPDELEGATE.window!
        
        if top < 64 {
            var rect = frame
            rect.origin.y = 64
            frame = rect
        }
        
        if left < 0 {
            var rect = frame
            rect.origin.x = 0
            frame = rect
        }
        
        
        if bottom > window.h {
            var rect = frame
            rect.origin.y = window.botttomWithOffset(-h)
            frame = rect
        }
        
        if right > window.w {
            var rect = frame
            rect.origin.x = window.rightWithOffset(-w)
            frame = rect
        }
    }
    
    
    
    // MARK: Events
    
    func touchDown () {
        bubble()
    }
    
    func touchUp () {
        if bubbleState == .Snap {
            toggle = !toggle
        } else {
            bubbleState = .Snap
            snap()
        }
    }
    
    func touchDrag (sender: BubbleControl, event: UIEvent) {
        bubbleState = .Drag
        
        if toggle {
            toggle = false
        }
        
        let touch = event.allTouches()!.first! 
        let location = touch.locationInView(APPDELEGATE.window!)
        
        center = location
        lockInWindowBounds()
    }
    
    
    func longPressHandler (press: UILongPressGestureRecognizer) {
        
        if toggle {
            return
        }
        
        switch press.state {
        case .Began:
            pop()
        case .Ended:
            if bubbleState == .Pop {
                cancelPop()
            }
        default:
            return
        }
    }
    
    func navButtonPressed (sender: AnyObject) {
        didNavigationBarButtonPressed? ()
    }
    
    
    
    // MARK: Animations
    
    override func animationDidStop(anim: CAAnimation,
        finished flag: Bool) {
            if flag {
                if anim == layer.animationForKey("pop") {
                    layer.removeAnimationForKey("pop")
                    
                    didPop? ()
                    
                    if popsToNavBar {
                        popToNavBar()
                    }
                }
            }
    }
    
    func degreesToRadians (angle: CGFloat) -> CGFloat {
        return (CGFloat (M_PI) * angle) / 180.0
    }
    
    
    
    // MARK: Pop
    
    func pop () {
        bubbleState = .Pop
        snap()
        
        let shake = CABasicAnimation(keyPath: "transform.rotation")
        shake.fromValue = degreesToRadians(popAnimationShakeRotations.0)
        shake.toValue = degreesToRadians(popAnimationShakeRotations.1)
        shake.duration = popAnimationShakeDuration
        shake.repeatCount = Float.infinity
        shake.autoreverses = true
        
        let grow = CABasicAnimation (keyPath: "transform.scale")
        grow.fromValue = 1
        grow.toValue = popAnimationScale
        grow.duration = popAnimationDuration
        
        let anims = CAAnimationGroup ()
        anims.animations = [shake, grow]
        anims.duration = popAnimationDuration
        anims.delegate = self
        anims.removedOnCompletion = false
        
        layer.addAnimation(anims, forKey: "pop")
    }
    
    func cancelPop () {
        snap()
        layer.removeAnimationForKey("pop")
    }
    
    
    func popToNavBar () {
        bubbleState = .NavBar
        
        spring({ () -> Void in
            self.setScale(0)
            self.alpha = 0.5
            }, completion: { finished in
                self.setScale(1)
                self.hidden = true
        })
        
        
        var barButton: UIBarButtonItem?
        
        if let _ = image {
            let navButton = UIButton (frame: CGRect (x: 0, y: 0, width: 20, height: 20))
            navButton.setBackgroundImage(image!, forState: .Normal)
            navButton.addTarget(self, action: "navButtonPressed:",
                forControlEvents: .TouchUpInside)
            
            barButton = UIBarButtonItem (customView: navButton)
        } else {
            barButton = UIBarButtonItem (barButtonSystemItem: UIBarButtonSystemItem.Action
                , target: self, action: "navButtonPressed:")
        }
        
        barButtonItem = barButton
        barButtonItem?.setBadgeValue(badgeCount)
        
        if let last = APPDELEGATE.window!.rootViewController as? UINavigationController {
            let vc = last.viewControllers[0] 
            vc.navigationItem.setRightBarButtonItem(barButtonItem!, animated: true)
        }
    }
    
    func popFromNavBar () {
        if let last = APPDELEGATE.window!.rootViewController as? UINavigationController {
            let vc = last.viewControllers[0] 
            vc.navigationItem.rightBarButtonItem = nil
            
            bubbleState = .Snap
            self.barButtonItem = nil
            self.hidden = false
            
            let toPosition = self.frame.origin
            self.position = CGPoint(x: APPDELEGATE.window!.right, y: APPDELEGATE.window!.top)
            self.movePoint(toPosition)
            self.alphaTo(1)
        }
    }
    
    
    
    // MARK: Toggle
    
    func openContentView () {
        if let v = contentView {
            let win = APPDELEGATE.window!
            win.addSubview(v)
            win.bringSubviewToFront(self)
            
            snapOffset = snapOffsetMin
            snap()
            positionBeforeToggle = frame.origin
            
            if let anim = setOpenAnimation {
                anim (contentView: v, backgroundView: win.subviews[0])
            } else {
                v.bottom = win.bottom
            }
            
            if movesBottom {
                movePoint(CGPoint (x: win.center.x - w/2, y: win.bottom - h - snapOffset))
            } else {
                moveY(v.top - h - snapOffset)
            }
        }
    }
    
    func closeContentView () {
        if let v = contentView {
            
            if let anim = setCloseAnimation {
                anim (contentView: v, backgroundView: APPDELEGATE.window!.subviews[0])
            } else {
                v.removeFromSuperview()
            }
            
            if (bubbleState == .Snap) {
                setupSnapInsideTimer()
                movePoint(positionBeforeToggle!)
            }
        }
    }
}



// MARK: - UIBarButtonItem Badge Extension

private var barButtonAssociatedObjectBadge: UInt8 = 0
extension UIBarButtonItem {
    
    private var badgeLabel: UILabel? {
        get {
            return objc_getAssociatedObject(self, &barButtonAssociatedObjectBadge) as! UILabel?
        } set (value) {
            objc_setAssociatedObject(self, &barButtonAssociatedObjectBadge, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func setBadgeValue (value: Int) {
        print("value \(value)")
        if let label = badgeLabel {
            if value > 0 {
                label.hidden = false
                label.text = "\(value)"
                label.bubble()
            } else {
                label.hidden = true
            }
        } else {
            let view = valueForKey("view") as? UIView
            
            badgeLabel = UILabel (frame: CGRect (x: 0, y: 0, width: 20, height: 20))
            badgeLabel?.center = CGPoint (x: view!.right, y: view!.top)
            badgeLabel?.backgroundColor = UIColor.redColor()
            
            badgeLabel?.layer.cornerRadius = badgeLabel!.h/2
            badgeLabel?.layer.masksToBounds = true
            
            badgeLabel?.textAlignment = NSTextAlignment.Center
            badgeLabel?.textColor = UIColor.whiteColor()
            badgeLabel?.font = UIFont.systemFontOfSize(15)
            badgeLabel?.text = "\(value)"
            
            
            if value == 0 {
                badgeLabel?.hidden = true
            }
            
            view?.addSubview(badgeLabel!)
        }
    }
}
