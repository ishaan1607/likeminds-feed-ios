//
//  LMFeedCore.swift
//  likeminds-feed-iOS
//
//  Created by Devansh Mohata on 28/12/23.
//

import FirebaseCore
import FirebaseMessaging
import LikeMindsFeedUI
import LikeMindsFeed

// Keep Only Auth Logic
public class LMFeedCore {
    
    private init() {}
    
    public static var shared: LMFeedCore = .init()
    static var analytics: LMFeedAnalyticsProtocol?
    static private(set) var isInitialized: Bool = false
    
    public func setupLikeMindsFeed(apiKey: String, analytics: LMFeedAnalyticsProtocol? = nil) {
        LocalPreferences.apiKey = apiKey
        Self.analytics = analytics
        LMAWSManager.shared.initialize()
    }
    
    public func initiateLikeMindsFeed(username: String, userId: String, completionHandler: ((Result<Void, LMFeedError>) -> Void)?) {
        guard let apiKey = LocalPreferences.apiKey else {
            completionHandler?(.failure(.feedNotInitialized))
            return
        }
        
        let request = InitiateUserRequest.builder()
            .apiKey(apiKey)
            .userName(username)
            .uuid(userId)
            .isGuest(false)
            .build()
        
        LMFeedClient.shared.initiateUser(request: request) { [weak self] response in
            guard response.success,
                  let user = response.data?.user else {
                completionHandler?(.failure(.apiInitializationFailed(error: response.errorMessage)))
                return
            }
            
            if response.data?.appAccess == false {
                self?.logout(response.data?.refreshToken ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
                completionHandler?(.failure(.appAccessFalse))
                return
            }
            
            LocalPreferences.apiKey = apiKey
            LocalPreferences.userObj = user
            
            Self.isInitialized = true
            
            completionHandler?(.success(()))
        }
    }
    
    public func registerDeviceToken(with fcmToken: String, deviceID: String, completion: ((Result<Void, LMFeedError>) -> Void)? = nil) {
        let request = RegisterDeviceRequest.builder()
            .token(fcmToken)
            .deviceId(deviceID)
            .build()
        
        LMFeedClient.shared.registerDevice(request: request) { response in
            if response.success {
                completion?(.success(()))
            } else {
                completion?(.failure(.notificationRegisterationFailed(error: response.errorMessage)))
            }
        }
    }
    
    public func logout(_ refreshToken: String, deviceId: String, completion: ((Result<Void, LMFeedError>) -> Void)? = nil) {
        let request = LogoutRequest.builder()
            .refreshToken(refreshToken)
            .deviceId(deviceId)
            .build()
        
        LMFeedClient.shared.logout(request: request) { response in
            if response.success {
                completion?(.success(()))
            } else {
                completion?(.failure(.logoutFailed(error: response.errorMessage)))
            }
        }
    }
    
    public func didReceiveNotification(_ notification: UNNotificationRequest, completion: ((Result<LMViewController, LMFeedError>) -> Void)?) {
        guard Self.isInitialized,
              let apiKey = LocalPreferences.apiKey,
              let userUUID = LocalPreferences.userObj?.clientUUID,
              let userName = LocalPreferences.userObj?.name,
              let route = notification.content.userInfo["route"] as? String else {
            completion?(.failure(.feedNotInitialized))
            return
        }
        
        let request = InitiateUserRequest.builder()
            .apiKey(apiKey)
            .userName(userName)
            .uuid(userUUID)
            .isGuest(false)
            .build()
        
        LMFeedClient.shared.initiateUser(request: request) { [weak self] response in
            guard response.success else {
                completion?(.failure(.apiInitializationFailed(error: response.errorMessage)))
                return
            }
            
            if response.data?.appAccess == false {
                self?.logout(response.data?.refreshToken ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "")
                completion?(.failure(.appAccessFalse))
                return
            }
            
            Self.isInitialized = true
            
            LMFeedRouter.fetchRoute(from: route) { result in
                switch result {
                case .success(let viewcontroller):
                    completion?(.success(viewcontroller))
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
    }
}
