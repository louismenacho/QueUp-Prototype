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
    @ServerTimestamp var dateAdded: Timestamp?
    var id: String
    var host: Member
    var token: String = ""
    var userCount: Int = 0
}
