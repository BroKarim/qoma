//
//  QomaApp.swift
//  Qoma
//
//  Created by dzulkiram hilmi on 04/02/26.
//

import SwiftUI

@main
struct QomaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
