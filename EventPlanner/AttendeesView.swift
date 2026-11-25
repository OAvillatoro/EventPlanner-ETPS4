//
//  AttendeesView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI
import FirebaseFirestore

struct AttendeesView: View {
    let event: Event

    @State private var attendeeNames: [String: String] = [:]
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando asistentes...")

            } else if event.attendees.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 55))
                        .foregroundColor(.secondary)

                    Text("Sin asistentes confirmados")
                        .font(.headline)

                    Text("Los participantes aparecerán aquí cuando confirmen su asistencia.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

            } else {
                List {
                    Section {
                        ForEach(event.attendees, id: \.self) { userId in
                            HStack(spacing: 12) {

                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(
                                        attendeeNames[userId]
                                            ?? "Nombre no disponible"
                                    )
                                    .font(.headline)

                                    Text("Asistencia confirmada")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Asistentes confirmados: \(event.attendees.count)")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Asistentes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAttendeeNames()
        }
    }

    // MARK: - Consultar nombres de asistentes

    private func loadAttendeeNames() {
        guard !event.attendees.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        attendeeNames = [:]

        let group = DispatchGroup()

        for userId in event.attendees {
            group.enter()

            db.collection("attendeeProfiles")
                .document(userId)
                .getDocument { document, error in

                    if error == nil,
                       let name = document?.data()?["name"] as? String {
                        DispatchQueue.main.async {
                            attendeeNames[userId] = name
                        }
                    }

                    group.leave()
                }
        }

        group.notify(queue: .main) {
            isLoading = false
        }
    }
}
