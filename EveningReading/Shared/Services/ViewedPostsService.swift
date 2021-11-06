//
//  ViewedPostsService.swift
//  EveningReading (iOS)
//
//  Created by Willie Zutz on 8/26/21.
//

import Foundation
import Compression
import Gzip

class CloudSetting {
    private struct ClientData: Hashable, Codable {
        public var data: String
    }
    
    static func getCloudSetting<T>(settingName: String, defaultValue: T, handler: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        let urlSession = URLSession.shared
        
        let username = UserUtils.getUserName()
        
        if username == "" { handler(.success(defaultValue)) }
        
        guard
            var urlComponents = URLComponents(string: "https://winchatty.com/v2/clientData/getClientData")
        else { preconditionFailure("Can't create url components...") }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "client", value: settingName)
        ]
        
        let request = URLRequest(url: urlComponents.url!)
        
        urlSession.dataTask(with: request, completionHandler: {responseData, response, error in
            guard error == nil else {
                handler(.failure(error!))
                return
            }
            guard let responseData = responseData else {
                handler(.failure(error!))
                return
            }
            do {
                let jsonDecoder = JSONDecoder()
                let clientData = try jsonDecoder.decode(ClientData.self, from: responseData)
                
                if clientData.data != "" {
                    if let compressedData = Data(base64Encoded: clientData.data) {
                        let decompressedData = try compressedData.gunzipped()
                        let jObj = try jsonDecoder.decode(T.self, from: decompressedData)
                        handler(.success(jObj))
                    } else {
                        print("Couldn't decode setting, returning default value. Setting value: \(clientData.data)")
                        // Couldn't decompress the data, return default
                        handler(.success(defaultValue))
                    }
                }
            }
            catch let err {
                print("Error retrieving cloud setting: \(err)")
                handler(.failure(err))
            }
        })
        .resume()
    }
    
    static func setCloudSetting<T>(settingName: String, value: T, handler: @escaping (Result<String, Error>) -> Void) where T : Encodable {
        let urlSession = URLSession.shared
        
        let username = UserUtils.getUserName()
        
        if username == "" { handler(.success("Username not set")) }
        
        let url = URL(string: "https://winchatty.com/v2/clientData/setClientData")!
        guard
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { preconditionFailure("Can't create url components...") }
        
        let jsonEncoder = JSONEncoder()
        let saveData = try? jsonEncoder.encode(value)
        let gzippedData = try? saveData!.gzipped().base64EncodedString().replacingOccurrences(of: "+", with: "%2B")
        
        urlComponents.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "client", value: settingName),
            URLQueryItem(name: "data", value: gzippedData!)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = urlComponents.query?.data(using: .utf8)
        
        urlSession.dataTask(with: request, completionHandler: {responseData, response, error in
            guard error == nil else {
                handler(.failure(error!))
                return
            }
            guard responseData != nil else {
                handler(.failure(error!))
                return
            }
            handler(.success("Saved setting"))
        })
        .resume()
    }
}

class ViewedPostsStore: ObservableObject {
    //    private let service: ViewedPostsService
    //    init(service: ViewedPostsService) {
    //        self.service = service
    //    }
    
    @Published var viewedPosts: Set<Int> = []
    private var dirty = false
    
    func getViewedPosts(_ handler: @escaping (Error?) -> Void) {
        CloudSetting.getCloudSetting(settingName: "werdSeenPosts", defaultValue: [] as Set<Int>) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let posts):
                    self?.viewedPosts = posts
                    handler(nil)
                case .failure(let err):
                    print("Error getting seen posts: \(err)")
                    self?.viewedPosts = []
                    handler(err)
                }
                self?.dirty = false
            }
        }
    }
    
    func syncViewedPosts(_ handler: @escaping (Error?) -> Void) {
        // If we haven't marked anything new, there's no reason to do any of this.
        if !self.dirty {
            handler(nil)
            return
        }
        
        print("Saving viewed posts...")
        // Merge with current cloud setting if it was updated by another instance.
        CloudSetting.getCloudSetting(settingName: "werdSeenPosts", defaultValue: [] as Set<Int>) { [weak self] result in
            var postsToSave = Set<Int>()
            switch result {
            case .success(var posts):
                posts = posts.union(self?.viewedPosts ?? Set<Int>())
                // Drop posts that are oldest first to keep the data set small-ish.
                if (posts.count > 25_000) {
                    posts = Set(self!.viewedPosts.sorted().dropFirst(5000))
                }
                postsToSave = posts
                CloudSetting.setCloudSetting(settingName: "werdSeenPosts", value: postsToSave, handler: { [weak self] result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            self?.viewedPosts = Set(postsToSave)
                            self?.dirty = false
                        }
                        handler(nil)
                    case .failure(let err):
                        print("Error saving seen posts: \(err)")
                        handler(err)
                    }
                })
            case .failure(let err):
                CloudSetting.setCloudSetting(settingName: "werdSeenPots", value: postsToSave, handler: { [weak self] result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            self?.viewedPosts = Set(postsToSave)
                            self?.dirty = false
                        }
                        handler(nil)
                    case .failure(let err):
                        handler(err)
                    }
                })
                print("Error getting seen posts while syncing: \(err)")
                handler(err)
            }
        }
    }
    
    // Create a temporary set, then assign that to viewedPosts to avoid excessive redraws
    public func markThreadViewed(thread: ChatThread, handler: @escaping (Error?) -> Void) {
        var threadIds = thread.posts.map({$0.id})
        threadIds.append(thread.threadId)
        self.markPostsViewed(postIds: threadIds, handler: handler)
    }
    
    public func markPostsViewed(postIds: [Int], handler: @escaping (Error?) -> Void) {
        let postsToMarkRead = Set<Int>(postIds)
        let originalCount = self.viewedPosts.count
        self.viewedPosts = postsToMarkRead.union(self.viewedPosts)
        if originalCount != self.viewedPosts.count {
            self.dirty = true
        }
        self.syncViewedPosts(handler)
    }
    
    public func markPostViewed(postId: Int) {
        let result = self.viewedPosts.insert(postId)
        if result.inserted {
            self.dirty = true
        }
    }
    
    public func isPostViewed(postId: Int) -> Bool {
        return self.viewedPosts.contains(postId)
    }
}
