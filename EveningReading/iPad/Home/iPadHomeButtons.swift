//
//  iPadHomeButtons.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import SwiftUI

struct iPadHomeButtons: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    
    private func navigateTo(_ goToDestination: inout Bool) {
        appSessionStore.resetNavigation()
        goToDestination = true
    }

    var body: some View {
        HStack() {
            Spacer().frame(width: 20)
            
            iPadHomeButton(title: .constant("Chat"), imageName: .constant("glyphicons-basic-238-chat-message"), buttonBackground: .constant(Color("HomeButtonChat")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingChatView)
                }
            
            iPadHomeButton(title: .constant("Inbox"), imageName: .constant("glyphicons-basic-122-envelope-empty"), buttonBackground: .constant(Color("HomeButtonInbox")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingInboxView)
                }
            
            iPadHomeButton(title: .constant("Search"), imageName: .constant("glyphicons-basic-28-search"), buttonBackground: .constant(Color("HomeButtonSearch")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingSearchView)
                }
            
            iPadHomeButton(title: .constant("Tags"), imageName: .constant("glyphicons-basic-67-tags"), buttonBackground: .constant(Color("HomeButtonTags")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingTagsView)
                }
            Spacer().frame(width: 20)
        }
        .padding(.top, 10)
    }
}

struct iPadHomeButtons_Previews: PreviewProvider {
    static var previews: some View {
        iPadHomeButtons()
            .environmentObject(AppSessionStore())
    }
}
