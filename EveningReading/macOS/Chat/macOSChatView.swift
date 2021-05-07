//
//  macOSChatView.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import SwiftUI

struct macOSChatView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    @EnvironmentObject var chatStore: ChatStore
    
    private func fetchChat() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil || self.chatStore.threads.count > 0
        {
            return
        }
        chatStore.getChat()
    }
    
    private func filteredThreads() -> [ChatThread] {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
        {
            return Array(chatData.threads)
        }
        
        let threads = self.chatStore.threads.filter({ return self.appSessionStore.threadFilters.contains($0.posts.filter({ return $0.parentId == 0 })[0].category) && !self.appSessionStore.collapsedThreads.contains($0.posts.filter({ return $0.parentId == 0 })[0].threadId)})
        
        if threads.count > 0 {
            return Array(threads)
        } else {
            return Array(chatData.threads)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack (alignment: .leading) {
                ScrollViewReader { scrollProxy in
                    VStack {
                        Spacer().frame(maxWidth: .infinity).frame(height: 30)
                    }.id(9999999999991)
                    ForEach(filteredThreads(), id: \.threadId) { thread in
                        FullThreadView(threadId: .constant(thread.threadId))
                    }
                    VStack {
                        Spacer().frame(maxWidth: .infinity).frame(height: 30)
                    }.id(9999999999993)
                }
            }
            .onAppear(perform: fetchChat)
        }
        .frame(maxHeight: .infinity)
        .navigationTitle("Chat")
    }
}

struct macOSChatView_Previews: PreviewProvider {
    static var previews: some View {
        macOSChatView()
            .environmentObject(AppSessionStore())
            .environmentObject(ChatStore(service: ChatService()))
    }
}
