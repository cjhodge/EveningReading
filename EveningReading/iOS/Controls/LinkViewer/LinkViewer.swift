//
//  LinkViewer.swift
//  iOS
//
//  Created by Chris Hodge on 8/25/20.
//

import SwiftUI
import Combine
import WebKit

struct LinkViewerSheet : View {
    @ObservedObject var linkViewerStore = LinkViewerStore()
    @Binding public var hyperlinkUrl: String?
    @Binding public var showingWebView: Bool
    @State private var webViewProgress: Double = 0
    @State private var webViewLoading: Bool = true
    
    func getHyperlink() -> String {
        guard let hyperlinkUrl = hyperlinkUrl else { return "about:blank" }
        return hyperlinkUrl
    }

    func goBack() {
        linkViewerStore.webView.goBack()
    }

    func goForward() {
        linkViewerStore.webView.goForward()
    }

    func openInSafari() {
        let hyperlink = linkViewerStore.webView.url?.absoluteString ?? getHyperlink()
        UIApplication.shared.open((URL.init(string: hyperlink))!)
        //showingWebView = false
    }
    
    var body: some View {
        VStack {
            Spacer().frame(width: 0, height: 0)
            .sheet(isPresented: $showingWebView) {
                VStack {
                    Spacer()
                        .frame(height: 10)
                    HStack {
                        Spacer()
                        Button(action: { self.showingWebView = false }) {
                            Rectangle()
                                .foregroundColor(Color(UIColor.systemFill))
                                .frame(width: 40, height: 5)
                                .cornerRadius(3)
                                .opacity(0.5)
                        }
                        Spacer()
                    }
                    NavigationView {
                        VStack {
                            if self.webViewLoading {
                                ProgressView(value: self.webViewProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor.systemBlue)))
                                    .frame(maxWidth: .infinity)
                            } else {
                                Color(UINavigationBar.appearance().barTintColor ?? UIColor.clear).frame(maxWidth: .infinity).frame(height: 4)
                            }
                            if showingWebView {
                                LinkViewerWebView(webView: self.linkViewerStore.webView, viewModel: self.linkViewerStore, estimatedProgress: self.$webViewProgress, isLoading: self.$webViewLoading, loadUrl: Binding.constant(getHyperlink()))
                            }
                            Spacer()
                            .navigationBarTitle(Text(verbatim: self.linkViewerStore.webView.title ?? ""), displayMode: .inline)
                        }
                        .navigationBarItems(trailing: HStack {
                            Button(action: self.goBack) {
                                Image(systemName: "chevron.left")
                                  .imageScale(.large)
                                  .aspectRatio(contentMode: .fit)
                            }.disabled(!self.linkViewerStore.webView.canGoBack)
                            Spacer().frame(width: 30)
                            Button(action: self.goForward) {
                                Image(systemName: "chevron.right")
                                  .imageScale(.large)
                                  .aspectRatio(contentMode: .fit)
                            }.disabled(!self.linkViewerStore.webView.canGoForward)
                            Spacer().frame(width: 30)
                            Button(action: self.openInSafari) {
                                Image(systemName: "safari") // square.and.arrow.up
                                  .imageScale(.large)
                                  .aspectRatio(contentMode: .fit)
                            }
                            .foregroundColor(Color.blue)
                            //.disabled(self.linkViewerStore.webView.isLoading)
                        })
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            if let url = URL(string: self.getHyperlink()) {
                                self.linkViewerStore.webView.load(URLRequest(url: url))
                            }
                        }
                    }
                    .onDisappear {
                        self.linkViewerStore.webView.load(URLRequest(url: URL(string: "about:blank")!))
                    }
                    Spacer()
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

public class LinkViewerStore: ObservableObject {
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }

    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        setupObservers()
    }
  
    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }
        observers = [
            subscriber(for: \.title),
            subscriber(for: \.url),
            subscriber(for: \.isLoading),
            subscriber(for: \.estimatedProgress),
            subscriber(for: \.hasOnlySecureContent),
            subscriber(for: \.serverTrust),
            subscriber(for: \.canGoBack),
            subscriber(for: \.canGoForward)
        ]
    }
  
    private var observers: [NSKeyValueObservation] = []
  
    deinit {
        observers.forEach {
            $0.invalidate()
        }
    }
}

public struct LinkViewerWebView: View, UIViewRepresentable {
    public let webView: WKWebView
    
    private var viewModel: LinkViewerStore
    @Binding var estimatedProgress: Double
    @Binding var isLoading: Bool
    @Binding var loadUrl: String

    public typealias UIViewType = LinkViewerContainerView<WKWebView>
  
    public init(webView: WKWebView, viewModel: LinkViewerStore, estimatedProgress: Binding<Double>, isLoading: Binding<Bool>, loadUrl: Binding<String>) {
        
        self.webView = webView
        self.viewModel = LinkViewerStore()
        self._estimatedProgress = estimatedProgress
        self._isLoading = isLoading
        self._loadUrl = loadUrl
    }
  
    public func makeUIView(context: UIViewRepresentableContext<LinkViewerWebView>) -> LinkViewerWebView.UIViewType {
        
        self.webView.navigationDelegate = context.coordinator
                
        return LinkViewerContainerView()
    }
  
    public func updateUIView(_ uiView: LinkViewerWebView.UIViewType, context: UIViewRepresentableContext<LinkViewerWebView>) {
        if uiView.contentView !== webView {
            DispatchQueue.main.async {
                uiView.contentView = webView
            }
        }
        
        if webView.url?.description == "about:blank" {
            if let url = URL(string: loadUrl) {
                let req = URLRequest(url: url)
                webView.load(req)
            }
        }
        
        // For progress tracking
        if self.webView.estimatedProgress >= 1.0 {
            DispatchQueue.main.async {
                self.estimatedProgress = 1.0
            }
        } else {
            DispatchQueue.main.async {
                self.estimatedProgress = self.webView.estimatedProgress
            }
        }
        
        if !self.webView.isLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async {
                self.isLoading = true
            }
        }
    }
    
    public func makeCoordinator() -> LinkViewerWebView.Coordinator {
        Coordinator(self)
    }
  
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: LinkViewerWebView
    
        init(_ parent: LinkViewerWebView) {
            self.parent = parent
        }
    
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
        }
        
        private func webViewWebContentProcessDidTerminate() {
            
        }
        
    }
}

public class LinkViewerContainerView<ContentView: UIView>: UIView {
    var contentView: ContentView? {
        willSet {
            contentView?.removeFromSuperview()
        }
        didSet {
            if let contentView = contentView {
                addSubview(contentView)
                contentView.backgroundColor = UIColor.systemBackground
                contentView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    contentView.topAnchor.constraint(equalTo: topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
}
