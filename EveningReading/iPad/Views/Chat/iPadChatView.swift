//
//  iPadChatView.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/3/21.
//

import SwiftUI

struct iPadChatView: View {
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    
    @State private var isGettingChat: Bool = false
    
    private func filteredThreads() -> [ChatThread] {
        let threads = chatService.threads.filter({ return appService.threadFilters.contains($0.posts.filter({ return $0.parentId == 0 })[0].category) && !appService.collapsedThreads.contains($0.posts.filter({ return $0.parentId == 0 })[0].threadId)})
        return Array(threads)
    }
        
    private func selectThreadById(threadId: Int) {
        chatService.activeThreadId = threadId
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack (alignment: .top, spacing: 0) {
                // Navigation
                VStack {
                    RefreshableScrollView(height: 70, refreshing: self.$chatService.gettingChat, scrollTarget: self.$chatService.scrollTargetChat, scrollTargetTop: self.$chatService.scrollTargetChatTop) {
                        
                        // All non-hidden threads
                        ForEach(filteredThreads(), id: \.threadId) { thread in
                            ThreadRow(threadId: .constant(thread.threadId), activeThreadId: $chatService.activeThreadId)
                                .environmentObject(appService)
                                .environmentObject(chatService)
                                .onTapGesture(count: 1) {
                                    chatService.postsToHighlight.removeAll()
                                    selectThreadById(threadId: thread.threadId)
                                }
                                .padding(.bottom, -20)
                                .id(thread.threadId)
                        }
                        
                        // Scroll to bottom / padding
                        VStack {
                            Spacer().frame(maxWidth: .infinity).frame(height: 30)
                        }.id(ScrollToBottomId)
                    }
                }
                .frame(width: geometry.size.width * 0.35)
                
                Divider()
                
                // Detail
                VStack {
                    if chatService.activeThreadId > 0 {
                        ThreadDetailView(threadId: $chatService.activeThreadId, postId: 0, replyCount: -1, isSearchResult: false)
                            .environmentObject(appService)
                            .environmentObject(chatService)
                    } else {
                        Spacer()
                        HStack {
                            Text("No thread selected.")
                                .font(.body)
                                .bold()
                                .foregroundColor(Color("NoDataLabel"))
                        }
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width * 0.65)
            }
        }
        
        // View settings
        .background(Color("PrimaryBackground").frame(height: BackgroundHeight).offset(y: BackgroundOffset))
        .edgesIgnoringSafeArea(.bottom)
        .navigationViewStyle(.stack)
        .navigationBarTitle("Chat", displayMode: .inline)
        .padding(.top, 1)
        
        // New thread button
        .navigationBarItems(leading: Spacer().frame(width: 26, height: 16), trailing: ComposePostView(isRootPost: true))
    }
}
