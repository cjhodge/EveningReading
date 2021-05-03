//
//  macOSContentView.swift
//  Shared
//
//  Created by Chris Hodge on 4/28/21.
//

import SwiftUI

#if os(OSX)
struct macOSWindowSize {
    let minWidth : CGFloat = 800
    let minHeight : CGFloat = 600
}
#endif

struct macOSContentView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
        
    private func navigateTo(_ goToDestination: inout Bool) {
        appSessionStore.resetNavigation()
        goToDestination = true
    }
    
    var body: some View {
        HStack() {
            NavigationView {
                List {
                    Text("Evening Reading")
                        .font(.caption2)
                        .foregroundColor(Color("macOSSidebarHeader"))
                        .bold()
                    
                    VStack (alignment: .leading, spacing: 10) {
                        macOSSidebarButton(text: .constant("Chat"), imageName: .constant("text.bubble"), selected: $appSessionStore.showingChatView)
                            .onTapGesture(count: 1) {
                                navigateTo(&appSessionStore.showingChatView)
                            }
                        
                        macOSSidebarButton(text: .constant("Inbox"), imageName: .constant("envelope.open"), selected: $appSessionStore.showingInboxView)
                            .onTapGesture(count: 1) {
                                navigateTo(&appSessionStore.showingInboxView)
                            }
                        
                        macOSSidebarButton(text: .constant("Search"), imageName: .constant("magnifyingglass"), selected: $appSessionStore.showingSearchView)
                            .onTapGesture(count: 1) {
                                navigateTo(&appSessionStore.showingSearchView)
                            }
                        
                        macOSSidebarButton(text: .constant("Tags"), imageName: .constant("tag"), selected: $appSessionStore.showingTagsView)
                            .onTapGesture(count: 1) {
                                navigateTo(&appSessionStore.showingTagsView)
                            }
                        
                        macOSSidebarButton(text: .constant("Settings"), imageName: .constant("gear"), selected: $appSessionStore.showingSettingsView)
                            .onTapGesture(count: 1) {
                                navigateTo(&appSessionStore.showingSettingsView)
                            }
                    }
                    
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Explore")
                .frame(minWidth: 150, idealWidth: 250, maxWidth: 300)
                .toolbar{
                    //Toggle Sidebar Button
                    ToolbarItem(placement: .navigation){
                        Button(action: {
                            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                        }, label: {
                            Image(systemName: "sidebar.left")
                        })
                    }
                }
                
                // Content
                if appSessionStore.showingChatView {
                    macOSChatView()
                } else if appSessionStore.showingInboxView {
                    macOSInboxView()
                } else if appSessionStore.showingSearchView {
                    macOSSearchView()
                } else if appSessionStore.showingTagsView {
                    macOSTagsView()
                } else if appSessionStore.showingSettingsView {
                    macOSSettingsView()
                } else {
                    EmptyView()
                }
            }
        }
        .frame(minWidth: macOSWindowSize().minWidth, minHeight: macOSWindowSize().minHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            appSessionStore.showingChatView = true
        }
    }
}

struct macOSContentView_Previews: PreviewProvider {
    static var previews: some View {
        macOSContentView()
            .environmentObject(AppSessionStore())
    }
}
