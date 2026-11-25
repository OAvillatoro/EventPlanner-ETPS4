//
//  EventFormView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI

struct EventFormView: View {
    @ObservedObject var viewModel: EventsViewModel

    var event: Event? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category = "Académico"
    @State private var location = ""
    @State private var date = Date().addingTimeInterval(3600)
    @State private var capacity = 20

    private let categories = [
        "Académico", "Social", "Deportivo", "Cultural"
    ]

    private var isEditing: Bool {
        event != nil
    }

    private var minimumCapacity: Int {
        max(1, event?.attendees.count ?? 0)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && date > Date()
        && capacity >= minimumCapacity
        && capacity <= 500
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información del evento") {
                    TextField("Título", text: $title)

                    TextField("Descripción", text: $description, axis: .vertical)
                        .lineLimit(3...5)

                    Picker("Categoría", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }

                    TextField("Lugar o enlace", text: $location)
                }

                Section("Fecha y capacidad") {
                    DatePicker(
                        "Fecha del evento",
                        selection: $date,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Stepper(
                        "Cupo máximo: \(capacity)",
                        value: $capacity,
                        in: minimumCapacity...500
                    )

                    if isEditing {
                        Text("\(event?.attendees.count ?? 0) asistentes confirmados")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        saveEvent()
                    } label: {
                        HStack {
                            Spacer()

                            if viewModel.isSaving {
                                ProgressView()
                            } else {
                                Text(isEditing ? "Guardar cambios" : "Crear evento")
                                    .bold()
                            }

                            Spacer()
                        }
                    }
                    .disabled(!isValid || viewModel.isSaving)
                }
            }
            .navigationTitle(isEditing ? "Editar evento" : "Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onAppear {
                viewModel.errorMessage = nil

                if let event = event {
                    title = event.title
                    description = event.description
                    category = event.category
                    location = event.location
                    date = event.date
                    capacity = event.capacity
                }
            }
        }
    }

    private func saveEvent() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        let completion: (Bool) -> Void = { success in
            if success {
                dismiss()
            }
        }

        if let event = event {
            viewModel.updateEvent(
                eventId: event.id,
                title: cleanTitle,
                description: cleanDescription,
                category: category,
                location: cleanLocation,
                date: date,
                capacity: capacity,
                completion: completion
            )
        } else {
            viewModel.createEvent(
                title: cleanTitle,
                description: cleanDescription,
                category: category,
                location: cleanLocation,
                date: date,
                capacity: capacity,
                completion: completion
            )
        }
    }
}
