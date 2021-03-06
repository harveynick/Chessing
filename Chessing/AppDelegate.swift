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

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    let mainWindow = UIWindow()
    let game = Game(rules: RegularRules())
    let chessController = ChessCollectionViewController(game: game, player: .black)
    
    mainWindow.rootViewController = UINavigationController(rootViewController: chessController)
    mainWindow.makeKeyAndVisible()
    self.window = mainWindow
    return true
  }
}

