//
//  AppDelegate.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var backgroundCompletionHandler: (() -> Void)?
    var backgroundSessionCompletionHandler: (() -> Void)?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
        HomeViewModel.shared.reconnectBackgroundSession(identifier: identifier)
    }

}

