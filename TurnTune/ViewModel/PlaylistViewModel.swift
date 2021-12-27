//
//  PlaylistViewModel.swift
//  TurnTune
//
//  Created by Louis Menacho on 12/25/21.
//

import Foundation

class PlaylistViewModel: NSObject {

    var spotifySessionManager: SPTSessionManager
    
    init(_ spotifySessionManager: SPTSessionManager) {
        self.spotifySessionManager = spotifySessionManager
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        sceneDelegate?.spotifySessionManager = spotifySessionManager
    }
    
}

extension PlaylistViewModel: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        
    }
}