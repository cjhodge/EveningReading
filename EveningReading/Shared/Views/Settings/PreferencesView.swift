//
//  PreferencesView.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    var body: some View {
        Group {
            #if os(iOS)
            Toggle(isOn: self.$appSessionStore.displayPostAuthor) {
                Text("Display Authors")
            }
            Toggle(isOn: self.$appSessionStore.abbreviateThreads) {
                Text("Abbreviate Threads")
            }
            Toggle(isOn: self.$appSessionStore.isDarkMode) {
                Text("Dark Mode")
            }
            Toggle(isOn: self.$appSessionStore.threadNavigation) {
                Text("Thread Navigation")
            }
            Toggle(isOn: self.$appSessionStore.useYoutubeApp) {
                Text("Use YouTube App")
            }
            Toggle(isOn: self.$appSessionStore.showLinkCopyButton) {
                Text("Copy Link Button")
            }
            #endif
            Toggle(isOn: self.$appSessionStore.disableAnimation) {
                Text("Disable Animation")
            }
        }
    }
}