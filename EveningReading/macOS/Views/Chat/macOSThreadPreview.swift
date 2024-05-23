//
//  macOSThreadPreview.swift
//  EveningReading (macOS)
//
//  Created by Chris Hodge on 6/11/21.
//

import SwiftUI

struct macOSThreadPreview: View {
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    
    var threadId: Int
    
    @State private var rootPostCategory: String = "ontopic"
    @State private var rootPostAuthor: String = ""
    @State private var rootPostBody: String = ""
    @State private var rootPostDate: String = "2020-08-14T21:05:00Z"
    @State private var rootPostLols: [ChatLols] = [ChatLols]()
    @State private var contributed: Bool = false
    @State private var replyCount: Int = 0
    
    @State private var showingHideAlert = false
    @State private var hideThread = false
    
    private func getThreadData() {
        let threads = chatService.threads.filter({ return appService.threadFilters.contains($0.posts.filter({ return $0.parentId == 0 })[0].category) && !appService.collapsedThreads.contains($0.posts.filter({ return $0.parentId == 0 })[0].threadId)})
        
        if let thread = threads.filter({ return $0.threadId == self.threadId }).first {
            self.contributed = PostDecorator.checkParticipatedStatus(thread: thread, author: self.rootPostAuthor)
            if let rootPost = thread.posts.filter({ return $0.parentId == 0 }).first {
                self.rootPostCategory = rootPost.category
                self.rootPostAuthor = rootPost.author
                self.rootPostBody = rootPost.body.getPreview
                self.rootPostDate = rootPost.date
                self.rootPostLols = rootPost.lols
            }
            self.replyCount = thread.posts.count - 1
        }
    }
    
    func loadThread() {
        if chatService.activeThreadId == self.threadId {
            return
        }
        chatService.activeThreadId = self.threadId
        chatService.activeParentId = 0
        chatService.hideReplies = true
        chatService.postsToHighlight.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            chatService.hideReplies = false
        }
    }
    
    var body: some View {
        ZStack {
            
            // Thread preview
            VStack (alignment: .leading) {
                HStack {
                    AuthorNameView(name: self.rootPostAuthor, postId: self.threadId)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 1) {
                            loadThread()
                        }
                    
                    ContributedView(contributed: self.contributed)

                    Text("")
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 1) {
                            loadThread()
                        }

                    LolView(lols: self.rootPostLols, expanded: false, capsule: false, postId: self.threadId)

                    ReplyCountView(replyCount: self.replyCount)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 1) {
                            loadThread()
                        }

                    TimeRemainingIndicator(percent: .constant(self.rootPostDate.getTimeRemaining()))
                        .frame(width: 12, height: 12)
                        .padding(.horizontal, 2)
                    
                    macOSPostActionsView(name: self.rootPostAuthor, postId: self.threadId, showingHideThread: true)
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                
                // Root post body
                HStack (alignment: .top) {
                    Text(appService.getPostBodyFor(name: self.rootPostAuthor, body: self.rootPostBody))
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .onTapGesture(count: 1) {
                    loadThread()
                }
                /*
                .contextMenu {
                    Button(action: {
                        // block user
                        self.showingHideAlert = true
                    }) {
                        Text("Hide Thread")
                        Image(systemName: "eye.slash")
                    }
                }
                .alert(isPresented: self.$showingHideAlert) {
                    Alert(title: Text("Hide thread?"), message: Text(""), primaryButton: .default(Text("Yes")) {
                        // collapse thread
                        appService.collapsedThreads.append(self.threadId)
                        chatService.activeThreadId = 0
                        self.hideThread = true
                    }, secondaryButton: .cancel() {
                        
                    })
                }
                */
                
                Divider()
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
            .background(self.contributed ? (chatService.activeThreadId == self.threadId ? Color("ChatBubbleSecondaryContributed") : Color("ChatBubblePrimaryContributed")) : (chatService.activeThreadId == self.threadId ? Color("ChatBubbleSecondary") : Color.clear))
            
            VStack {
                Rectangle()
                    .fill(Color.red.opacity(0.0))
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 1) {
                loadThread()
            }

            // Category Color
            HStack {
                GeometryReader { categoryGeo in
                    Path { categoryPath in
                        categoryPath.move(to: CGPoint(x: 0, y: 0))
                        categoryPath.addLine(to: CGPoint(x: 0, y: categoryGeo.size.height))
                        categoryPath.addLine(to: CGPoint(x: categoryGeo.size.width, y: categoryGeo.size.height))
                        categoryPath.addLine(to: CGPoint(x: categoryGeo.size.width, y: 0))
                    }
                    .fill(ThreadCategoryColor[self.rootPostCategory]!)
                }
                .frame(width: 3)
                Spacer()
            }
            
        }
        .onAppear(perform: getThreadData)
        .onReceive(chatService.$didGetChatFinish) { value in
            getThreadData()
        }
    }
}
