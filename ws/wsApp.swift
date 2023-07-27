//
//  wsApp.swift
//  ws
//
//  Created by Yeonwoo Lee on 2023/07/16.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin


@main
struct wsApp: App {
    
    func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Successfully configured Amplify")
        } catch {
            print("Failed to initialize Amplify:", error)
        }
    }
    
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
        }
    }
}
