//
//  iPhoneHomeButtons.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import SwiftUI

struct iPhoneHomeButtons: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    @EnvironmentObject var chatStore: ChatStore
    
    private func navigateTo(_ goToDestination: inout Bool) {
        appSessionStore.resetNavigation()
        goToDestination = true
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: 40)
            
            HStack(alignment: .top) {
                iPhoneHomeButton(title: .constant("Chat"), imageName: .constant("glyphicons-basic-238-chat-message"), buttonBackground: .constant(Color("HomeButtonChat")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingChatView)
                }
                Spacer()
                iPhoneHomeButton(title: .constant("Inbox"), imageName: .constant("glyphicons-basic-122-envelope-empty"), buttonBackground: .constant(Color("HomeButtonInbox")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingInboxView)
                }
                Spacer()
                iPhoneHomeButton(title: .constant("Search"), imageName: .constant("glyphicons-basic-28-search"), buttonBackground: .constant(Color("HomeButtonSearch")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingSearchView)
                }
                Spacer()
                iPhoneHomeButton(title: .constant("Tags"), imageName: .constant("glyphicons-basic-67-tags"), buttonBackground: .constant(Color("HomeButtonTags")))
                .onTapGesture(count: 1) {
                    navigateTo(&appSessionStore.showingTagsView)
                }
            }
            .padding(.horizontal, 15)
            
            Spacer()
            
            // Home Screen Navigation
            VStack {
                // go to chat
                NavigationLink(destination: ChatView(), isActive: $appSessionStore.showingChatView) {
                    EmptyView()
                }
                
                // go to inbox
                NavigationLink(destination: InboxView(), isActive: $appSessionStore.showingInboxView) {
                    EmptyView()
                }
                
                // go to search
                NavigationLink(destination: SearchView(populateTerms: .constant(""), populateAuthor: .constant(""), populateParent: .constant("")), isActive: $appSessionStore.showingSearchView) {
                    EmptyView()
                }
                
                // go to tags
                NavigationLink(destination: TagsView(), isActive: $appSessionStore.showingTagsView) {
                    EmptyView()
                }
                
                // go to settings
                NavigationLink(destination: SettingsView(), isActive: $appSessionStore.showingSettingsView) {
                    EmptyView()
                }
            }
            
        }
    }
}

struct iPhoneHomeButtons_Previews: PreviewProvider {
    static var previews: some View {
        iPhoneHomeButtons()
            .environmentObject(AppSessionStore(service: AuthService()))
            .environmentObject(ChatStore(service: ChatService()))
    }
}
