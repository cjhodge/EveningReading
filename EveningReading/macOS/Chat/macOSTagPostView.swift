//
//  macOSTagPostView.swift
//  EveningReading (macOS)
//
//  Created by Chris Hodge on 6/10/21.
//

import Foundation

import SwiftUI

struct macOSTagPostView: View {
    @EnvironmentObject var appSession: AppSession
    
    var body: some View {
        if appSession.isSignedIn {
            Image(systemName: "tag")
                .imageScale(.large)
                .onTapGesture(count: 1) {
                }
        } else {
            EmptyView()
        }
    }
}
