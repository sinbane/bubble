//
//  MyTabBarController.swift
//  Bubble
//
//  Created by Sinbane on 11/9/15.
//  Copyright © 2015 Sinbane. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
