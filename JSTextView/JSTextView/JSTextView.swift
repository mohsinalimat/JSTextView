//
//  JSTextView.swift
//  JSTextView
//
//  Created by Jesse Seidman on 11/10/17.
//  Copyright © 2017 Jesse Seidman. All rights reserved.
//

import UIKit

class JSTextView: UITextView
{
  //PRIVATE VARIABLES

  private let jumpingPress   = UILongPressGestureRecognizer() //The long press which activates the jump scroll
  private var jumpLabelArray = [NSRange]()                    //The array of ranges that the user can jump to
  private var jumpLabel      = UILabel()
  private var startedJumping = false
  private var jumpLabelColor = UIColor(red: 26/255.0, green: 140/255.0, blue: 255/255.0, alpha: 1)
  
  //INITIALIZERS
    
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    
    startUp()
  }
  
  override init(frame: CGRect, textContainer: NSTextContainer?)
  {
    super.init(frame: frame, textContainer: textContainer)
    
    startUp()
  }
  
  required init(frame: CGRect, textContainer: NSTextContainer?, labelColor: UIColor) {
    super.init(frame: frame, textContainer: textContainer)
    jumpLabelColor = labelColor
    startUp()
  }
  
  //PRIVATE FUNCTIONS
    
  private func startUp()
  {
    // Add Long press
    jumpingPress.addTarget(self, action: #selector(handleLongPressGesture))
    jumpingPress.cancelsTouchesInView = false
    jumpingPress.delegate = self
    self.addGestureRecognizer(jumpingPress)
    
    // Make Jump Label
    //jumpLabel = jumpingLabel(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0))
    jumpLabel = jumpingLabel(padding: UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5))
    jumpLabel.layer.backgroundColor = jumpLabelColor.cgColor
    jumpLabel.font = UIFont.systemFont(ofSize: 20)
    jumpLabel.textAlignment = .left
  }
    
  private func createLabelArray<T:Equatable> (attributeName:NSAttributedStringKey, attributeValue:T)
  {
    
    let storage = self.textStorage
   
    storage.enumerateAttribute(attributeName, in: NSMakeRange(0, textStorage.length), options: [], using:
        {
            (value,range,stop) in
                print((attributeValue as! UIFont).pointSize)
                if value as? T == attributeValue
                {
                    jumpLabelArray.append(range)
                }
        })
  }
  
  private func jumpToValueAt(yPosition:CGFloat, begin:Bool)
  {
    let jumpIndex = Int(yPosition / self.frame.height * CGFloat(self.jumpLabelArray.count))

    if jumpIndex >= 0 && jumpIndex < jumpLabelArray.count
    {
        self.startedJumping = true
        let startPosition   = self.position(from: self.beginningOfDocument, offset: jumpLabelArray[jumpIndex].lowerBound)
        let endPosition     = self.position(from: self.beginningOfDocument, offset: jumpLabelArray[jumpIndex].upperBound)
        let textRange       = self.textRange(from: startPosition! , to: endPosition!)
        
        jumpLabel.text = self.text(in: textRange!)
        jumpLabel.sizeToFit()
        
        jumpLabel.frame.size.width = jumpLabel.frame.width * 2
        jumpLabel.frame.size.height = jumpLabel.frame.height * 2
        jumpLabel.frame.origin = CGPoint(x: self.frame.maxX - jumpLabel.frame.width, y: yPosition)
      
        if begin
        {
            self.superview?.addSubview(jumpLabel)
            jumpLabel.frame.origin = CGPoint(x: self.frame.maxX + jumpLabel.frame.width, y: yPosition)
            
            UIView.animate(withDuration: 0.15, animations:
                {
                    self.jumpLabel.frame.origin = CGPoint(x: self.frame.maxX - self.jumpLabel.frame.width, y: yPosition)
                })
        }
        
        self.scrollRectToVisible(firstRect(for: textRange!), animated: false)
    }
  }
    
  // PUBLIC FUNCTIONS
    
  public func setLabelArray<T:Equatable> (attributeName:NSAttributedStringKey, attributeValue:T)
  {
    createLabelArray(attributeName: attributeName, attributeValue: attributeValue)
    
    print(jumpLabelArray)
  }
    
  //GESTURE ACTION FUNCTIONS
    
  @objc func handleLongPressGesture(gesture: UILongPressGestureRecognizer)
  {
    let xPosition = jumpingPress.location(in: self).x
    let yPosition = jumpingPress.location(in: superview).y - self.frame.minY

    // Check if touch is in hot zone and the jumping press state is began
    if jumpingPress.state == .began && xPosition >= self.frame.minX + self.frame.width * 0.9 && xPosition <= self.frame.minX + self.frame.width
    {
      self.isUserInteractionEnabled = false
      jumpToValueAt(yPosition: yPosition, begin: true)
    }
    
    //check if the jumping press state is changed
    else if startedJumping && jumpingPress.state == .changed
    {
      jumpToValueAt(yPosition: yPosition, begin: false)
    }
    
    //check if the jumping press state is ending
    else if jumpingPress.state == .ended || jumpingPress.state == .cancelled || jumpingPress.state == .failed
    {
      self.isUserInteractionEnabled = true
      self.startedJumping           = false
        
      UIView.animate(withDuration: 0.15, delay: 0.0, options: [], animations:
        {
           self.jumpLabel.frame.origin = CGPoint(x: self.frame.maxX + self.jumpLabel.frame.width, y: yPosition)
        },completion:
        {
           (completed) in
            if completed {self.jumpLabel.removeFromSuperview()}
        })
    }
  }
  
}

//the extension which ensures that the gestures are recognized in the textview
extension JSTextView: UIGestureRecognizerDelegate
{
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
  {
    return true
  }
}

