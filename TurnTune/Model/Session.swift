//
//  Session.swift
//  TurnTune
//
//  Created by Louis Menacho on 12/27/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Session: FirestoreDocument {
    @DocumentID var documentID: String?
    var dateAdded: Timestamp?
    var code: String
    var host: User
    var token: String = ""
    var userCount: Int = 0
}