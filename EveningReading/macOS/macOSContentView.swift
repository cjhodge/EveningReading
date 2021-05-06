//
//  macOSContentView.swift
//  Shared
//
//  Created by Chris Hodge on 4/28/21.
//

import SwiftUI

struct macOSWindowSize {
    let minWidth : CGFloat = 800
    let minHeight : CGFloat = 600
}

struct macOSContentView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    @EnvironmentObject var chatStore: ChatStore
        
    @State private var showingChatView = false
    
    
    
    var body: some View {
        HStack() {
            NavigationView {
                
                // Navigation
                List {
                    Text("Evening Reading")
                        .font(.caption2)
                        .foregroundColor(Color("macOSSidebarHeader"))
                        .bold()
                    SidebarButtons()
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Evening Reading")
                .frame(minWidth: 150, idealWidth: 250, maxWidth: 300)
                .toolbar {
                    // Collapse Sidebar
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                        }, label: {
                            Image(systemName: "sidebar.left")
                        })
                    }
                    // Toolbar Buttons
                    ToolbarItemGroup(placement: .navigation) {
                        if appSessionStore.showingChatView {
                            Button(action: {
                                // refresh
                            }, label: {
                                Image(systemName: "arrow.counterclockwise")
                            })
                            Button(action: {
                                // compose
                            }, label: {
                                Image(systemName: "square.and.pencil")
                            })
                        } else if appSessionStore.showingInboxView {
                            Button(action: {
                                // refresh
                            }, label: {
                                Image(systemName: "arrow.counterclockwise")
                            })
                            Button(action: {
                                // compose
                            }, label: {
                                Image(systemName: "square.and.pencil")
                            })
                        } else {
                            EmptyView()
                        }
                    }
                }
                
                // Detail View
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
            .environmentObject(ChatStore(service: ChatService()))
    }
}