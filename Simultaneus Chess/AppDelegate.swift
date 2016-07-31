//
//  AppDelegate.swift
//  Simultaneus Chess
//
//  Created by Nicholas Adam Johnson on 08/05/2016.
//  Copyright © 2016 Nicholas Adam Johnson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let mainWindow = UIWindow()
    mainWindow.rootViewController = ChessCollectionViewController()
    mainWindow.makeKeyAndVisible()
    self.window = mainWindow
    return true
  }
}

