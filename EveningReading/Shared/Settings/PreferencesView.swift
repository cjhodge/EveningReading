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
            Toggle(isOn: self.$appSessionStore.displayPostAuthor) {
                Text("Display Authors")
            }
            Toggle(isOn: self.$appSessionStore.abbreviateThreads) {
                Text("Abbreviate Threads")
            }
            Toggle(isOn: self.$appSessionStore.threadNavigation) {
                Text("Thread Navigation")
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(AppSessionStore())
    }
}