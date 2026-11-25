//
//  MyEventsView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI
import FirebaseAuth

struct MyEventsView: View {
    @ObservedObject var viewModel: EventsViewModel

    private var myEvents: [Event] {
        guard let userId = Auth.auth().currentUser?.uid else {
            return []
        }

        return viewModel.events.filter {
            $0.organizerId == userId
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando eventos...")

            } else if myEvents.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 55))
                        .foregroundColor(.secondary)

                    Text("No has creado eventos")
                        .font(.headline)

                    Text("Los eventos que organices aparecerán aquí.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

            } else {
                List(myEvents) { event in
                    NavigationLink {
                        EventDetailView(
                            event: event,
                            viewModel: viewModel
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(event.title)
                                .font(.headline)

                            Text(event.category)
                                .font(.caption)
                                .foregroundColor(.blue)

                            Label {
                                Text(event.date, style: .date)
                            } icon: {
                                Image(systemName: "calendar")
                            }

                            Label(
                                "\(event.attendees.count) confirmados",
                                systemImage: "person.2"
                            )
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Mis eventos")
    }
}
