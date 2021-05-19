//
//  NotificationService.swift
//  EveningReading Extension
//
//  Created by Chris Hodge on 5/14/21.
//

import Foundation
import SwiftUI

struct RegisterPushResponse {
    var status: Int
    var message: String
}

class NotificationService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    public func register(username: String, deviceName: String, deviceToken: String, handler: @escaping (Result<RegisterPushResponse, Error>) -> Void) {
        if let apnsKey = Bundle.main.infoDictionary?["APNS_KEY"] as? String {
            guard
                var urlComponents = URLComponents(string: "https://www.erapns.com/APNS/adduser.php")
                else { preconditionFailure("Can't create url components...") }

            urlComponents.queryItems = [
             URLQueryItem(name: "key", value: apnsKey),
             URLQueryItem(name: "username", value: username),
             URLQueryItem(name: "device", value: deviceName),
             URLQueryItem(name: "token", value: deviceToken)
            ]
            
            guard
                let url = urlComponents.url
                else { preconditionFailure("Can't create url from url components...") }
            
            let urlSession: URLSession = .shared
            
            urlSession.dataTask(with: url) { [weak self] data, _, error in
                if let error = error {
                    print("push register user error \(error)")
                    //handler(.failure(error))
                    handler(.success(RegisterPushResponse(status: 0, message: "fail")))
                } else {
                    do {
                        let data = data ?? Data()
                        print("push register user success")
                        print("\(data)")
                        handler(.success(RegisterPushResponse(status: 1, message: "success")))
                    } catch {
                        //handler(.failure(error))
                        print("push register user error \(error)")
                        handler(.success(RegisterPushResponse(status: 0, message: "fail")))
                    }
                }
            }.resume()
        } else {
            handler(.success(RegisterPushResponse(status: 0, message: "fail")))
        }
    }
}

class NotificationStore: ObservableObject {
    
    private let service: NotificationService
    init(service: NotificationService) {
        self.service = service
    }
    
    @Published private(set) var registerPushResponse: RegisterPushResponse = RegisterPushResponse(status: 0, message: "")
        
    func register() {
       let username: String? = KeychainWrapper.standard.string(forKey: "Username")
       let defaults = UserDefaults.standard
       let deviceTokenClean = defaults.object(forKey: "PushNotificationToken") as? String ?? ""
       let deviceName = defaults.object(forKey: "PushNotificationName") as? String ?? ""

       if username != nil && username != "" && deviceTokenClean != "" {
           let alphaNumericOnly = "[^A-Za-z0-9]+"
           if let cleanUsername = username?.replacingOccurrences(of: alphaNumericOnly, with: "", options: [.regularExpression]) {
               print("registering user for push")
               service.register(username: cleanUsername, deviceName: deviceName, deviceToken: deviceTokenClean) { [weak self] result in
                   DispatchQueue.main.async {
                       switch result {
                       case .success(let response):
                           self?.registerPushResponse = response
                       case .failure:
                           self?.registerPushResponse = RegisterPushResponse(status: 0, message: "error")
                       }
                   }
               }
           }
       }
   }
}

#if os(iOS)
class Notifications: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = Notifications()
    
    @Published var notificationData: UNNotificationResponse?
    @Published var notificationLink: String = ""
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func setNotificationLink(_ link: String) {
        self.notificationLink = link
    }
}

extension Notifications {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("UNNotificationResponse received")
        notificationData = response
        let userInfo = response.notification.request.content.userInfo
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            // Do what you want with the notification
            Notifications.shared.notificationLink = aps.description
        }
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) { }
}
#endif
