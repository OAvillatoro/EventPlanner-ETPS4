//
//  Event.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable {
    var id: String
    var title: String
    var description: String
    var category: String
    var location: String
    var date: Date
    var capacity: Int
    var organizerId: String
    var attendees: [String]

    var availableSpots: Int {
        max(0, capacity - attendees.count)
    }

    var isFull: Bool {
        availableSpots == 0
    }

    init(
        id: String,
        title: String,
        description: String,
        category: String,
        location: String,
        date: Date,
        capacity: Int,
        organizerId: String,
        attendees: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.date = date
        self.capacity = capacity
        self.organizerId = organizerId
        self.attendees = attendees
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let category = data["category"] as? String,
              let location = data["location"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let capacity = data["capacity"] as? Int,
              let organizerId = data["organizerId"] as? String,
              let attendees = data["attendees"] as? [String]
        else {
            return nil
        }

        self.id = document.documentID
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.date = timestamp.dateValue()
        self.capacity = capacity
        self.organizerId = organizerId
        self.attendees = attendees
    }
}

