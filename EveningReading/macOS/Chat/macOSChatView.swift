//
//  macOSChatView.swift
//  EveningReading (macOS)
//
//  Created by Chris Hodge on 6/10/21.
//

import SwiftUI

struct macOSChatView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    @EnvironmentObject var chatStore: ChatStore
    
    @State private var showingGuidelinesView = false
    @State private var guidelinesAccepted = false

    private func fetchChat() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil || chatStore.threads.count > 0
        {
            return
        }
        chatStore.getChat()
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack (alignment: .top, spacing: 0) {
                    
                // Check if guidelines accepted
                Spacer().frame(width: 0, height: 0)
                .onAppear() {
                    DispatchQueue.main.async {
                        let defaults = UserDefaults.standard
                        //defaults.removeObject(forKey: "GuidelinesAccepted")
                        self.guidelinesAccepted = defaults.object(forKey: "GuidelinesAccepted") as? Bool ?? false
                        self.showingGuidelinesView = !self.guidelinesAccepted
                    }
                }
                .navigationTitle("Chat")

                
                // Guidelines
                if self.showingGuidelinesView {
                    macOSGuidelinesView(showingGuidelinesView: $showingGuidelinesView, guidelinesAccepted: self.$guidelinesAccepted)
                }
                
                if self.guidelinesAccepted {
                    ScrollView {
                        LazyVStack (spacing: 0) {
                            macOSThreadList()
                        }
                        .padding(.top, 20)
                    }
                    .frame(width: geometry.size.width * 0.35)
                    
                    Divider()
                    
                    ScrollView {
                        ScrollViewReader { scrollProxy in
                            LazyVStack {
                                if chatStore.activeThreadId == 0 {
                                    Text("No thread selected.")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(Color("NoDataLabel"))
                                } else {
                                    macOSThreadView(threadId: $chatStore.activeThreadId)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .frame(width: geometry.size.width * 0.65)
                }
            }
            .onAppear(perform: fetchChat)
        }
    }
}

struct macOSChatView_Previews: PreviewProvider {
    static var previews: some View {
        macOSChatView()
            .previewLayout(.fixed(width: 640, height: 480))
            .environmentObject(AppSessionStore(service: AuthService()))
            .environmentObject(ChatStore(service: ChatService()))
    }
}
