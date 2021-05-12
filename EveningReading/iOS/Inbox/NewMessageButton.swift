//
//  NewMessageButton.swift
//  iOS
//
//  Created by Chris Hodge on 8/30/20.
//

import SwiftUI

struct NewMessageButton: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSessionStore: AppSessionStore
    
    var isReply: Bool
    @Binding var showingNewMessageSheet: Bool
    
    var body: some View {
        if appSessionStore.isSignedIn {
            Button(action: {
                DispatchQueue.main.async {
                    self.showingNewMessageSheet = true
                }
            }) {
                Image(systemName: self.isReply ? "arrowshape.turn.up.left" : "square.and.pencil")
                    .imageScale(.large)
                    .foregroundColor(self.colorScheme == .dark ? Color(UIColor.white) : Color(UIColor.systemBlue))
            }
        } else {
            EmptyView()
        }
    }
}

struct NewMessageButton_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageButton(isReply: false, showingNewMessageSheet: .constant(false))
            .environmentObject(AppSessionStore(service: AuthService()))
    }
}
