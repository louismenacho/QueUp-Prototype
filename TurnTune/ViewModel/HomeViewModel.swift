//
//  HomeViewModel.swift
//  TurnTune
//
//  Created by Louis Menacho on 12/23/21.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class HomeViewModel: NSObject {
    
    var currentMember: Member?
    var currentSession: Session?
    var currentSessionID: String = ""
    
    var spotifySessionManager: SPTSessionManager?
    var spotifyInitiateSessionCompletion: ((Result<Void, Error>) -> Void)?
    
    var spotifyConfig: SPTConfiguration?
    var spotifyScope: SPTScope = [
        .appRemoteControl,
        .userReadCurrentlyPlaying,
        .userReadRecentlyPlayed,
        .userReadPlaybackState,
        .userModifyPlaybackState,
        .userReadPrivate
    ]
    
    private func initSpotifyConfig(completion: @escaping (Result<Void, RepositoryError>) -> Void) {
        FirestoreRepository<SpotifyCredentials>(collectionPath: "spotify").get(id: "credentials") { result in
            completion( result.flatMap { credentials in
                let config = SPTConfiguration(clientID: credentials.clientID, redirectURL: URL(string: credentials.redirectURL)!)
                config.tokenSwapURL = URL(string: credentials.tokenSwapURL)
                config.tokenRefreshURL = URL(string: credentials.tokenRefreshURL)
                self.spotifyConfig = config
                return .success(())
            })
        }
    }
    
    private func initSpotifySession(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let config = spotifyConfig else {
            print("Could not initiate Spotify session, Spotify config is nil")
            return
        }
        let spotifySessionManager = SPTSessionManager(configuration: config, delegate: self)
        self.spotifySessionManager = spotifySessionManager
        
        DispatchQueue.main.async {
            let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
            sceneDelegate?.spotifySessionManager = spotifySessionManager
            spotifySessionManager.initiateSession(with: self.spotifyScope, options: .clientOnly)
        }
        
        spotifyInitiateSessionCompletion = { result in
            completion(result)
        }
    }
    
    private func getSpotifyUserSubscription(completion: @escaping (Result<String, ClientError>) -> Void) {
        guard let spotifySession = spotifySessionManager?.session else {
            print("Could not request Spotify user profile, Spotify session is nil")
            return
        }
        let spotifyUserProfileAPI = SpotifyAPIClient<SpotifyUserProfileAPI>()
        spotifyUserProfileAPI.auth = .bearer(token: spotifySession.accessToken)
        spotifyUserProfileAPI.request(.currentUserProfile) { (result: Result<UserProfileResponse, ClientError>) in
            completion( result.flatMap { userProfile in
                return .success((userProfile.product))
            })
        }
    }
    
    private func generateNewSessionID(completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signInAnonymously { authDataResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let newID = self.generateRandomCode(length: 4)
            FirestoreRepository<Session>(collectionPath: "sessions").get(id: newID) { result in
                switch result {
                case .failure(let error):
                    if case .notFound = error {
                        print("\(newID) does not exist. Using for new room")
                        self.currentSessionID = newID
                        completion(.success(newID))
                    } else {
                        completion(.failure(error))
                    }
                case .success:
                    print("\(newID) already exists. Regenerating room code")
                    self.generateNewSessionID(completion: completion)
                }
            }
        }
    }
    
    private func createNewSession(hostName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        guard let spotifySession = spotifySessionManager?.session else {
            return
        }
        let host = Member(documentID: currentUser.uid, id: currentUser.uid, displayName: hostName ,isHost: true)
        let session = Session(documentID: currentSessionID, id: currentSessionID, host: host, userCount: 1, spotifyToken: spotifySession.accessToken)
        let group = DispatchGroup()
        
        group.enter()
        FirestoreRepository<Session>(collectionPath: "sessions").create(session) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.currentSession = session
            group.leave()
        }
        
        group.enter()
        FirestoreRepository<Member>(collectionPath: "sessions/"+currentSessionID+"/members").create(host) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.currentMember = host
            group.leave()
        }
        
        group.notify(queue: .global()) {
            completion(.success(()))
        }
    }
    
    private func generateRandomCode(length: Int) -> String {
        let alphabeticRange = 65...90
        var code = ""
        while code.count < length {
            let unicodeScalar = Int.random(in: alphabeticRange)
            let letter = Character(UnicodeScalar(unicodeScalar)!)
            code = "\(code)\(letter)"
        }
        return code
    }
    
    func createRoom(hostName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async { [self] in
            
            initSpotifyConfig { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success:
                    print("initSpotifyConfig complete")
                }
            }
            
            semaphore.wait()
            initSpotifySession { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success:
                    print("initSpotifySession complete")
                }
            }
            
            semaphore.wait()
            getSpotifyUserSubscription { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success(let subscription):
                    print("getSpotifyUserSubscription complete: \(subscription)")
                }
            }
            
            semaphore.wait()
            generateNewSessionID { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success:
                    print("generateNewSessionID complete")
                }
            }
            
            semaphore.wait()
            createNewSession(hostName: hostName) { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success:
                    print("createNewSession complete")
                }
            }

            semaphore.wait()
            completion(.success(()))
        }
    }
    
    private func findSession(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signInAnonymously { authDataResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            FirestoreRepository<Session>(collectionPath: "sessions").get(id: id) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success(let session):
                    self.currentSession = session
                    self.currentSessionID = session.id
                    completion(.success(()))
                }
            }
        }
    }
    
    private func addSessionMember(memberName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        guard let currentSession = currentSession else {
            return
        }
        let newMember = Member(documentID: currentUser.uid, id: currentUser.uid, displayName: memberName, isHost: false)
        if newMember == currentSession.host {
            currentMember = currentSession.host
            completion(.success(()))
            return
        }
        FirestoreRepository<Member>(collectionPath: "sessions/"+currentSession.id+"/members").create(newMember) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.currentMember = newMember
            completion(.success(()))
        }
    }
    
    func joinRoom(sessionID: String, memberName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async { [self] in
            
            findSession(id: sessionID) { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success:
                    print("findSession complete")
                }
            }
            
            semaphore.wait()
            addSessionMember(memberName: memberName) { result in
                semaphore.signal()
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    return
                case .success:
                    print("addSessionMember complete")
                }
            }
            
            semaphore.wait()
            if currentMember?.id == currentSession?.host.id {
                print("host rejoining...")
                
                initSpotifyConfig { result in
                    semaphore.signal()
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    case .success:
                        print("initSpotifyConfig complete")
                    }
                }
                
                semaphore.wait()
                initSpotifySession { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    case .success:
                        print("initSpotifySession complete")
                    }
                }
            }
            
            completion(.success(()))
        }
    }
}

extension HomeViewModel: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("SPTSession didInitiate")
        spotifyInitiateSessionCompletion?(.success(()))
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("SPTSession didFailWith error")
        spotifyInitiateSessionCompletion?(.failure(error))
    }
}

