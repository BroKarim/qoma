//
//  dzennApp.swift
//  dzenn
//
//  Created by dzulkiram hilmi on 04/02/26.
//

import SwiftUI

@main
struct DzennApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
