//
//  EventDetailView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI
import FirebaseAuth

struct EventDetailView: View {
    let event: Event

    @ObservedObject var viewModel: EventsViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var showingEditEvent = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteError: String?

    private var currentEvent: Event {
        viewModel.events.first { $0.id == event.id } ?? event
    }

    private var isOrganizer: Bool {
        currentEvent.organizerId == Auth.auth().currentUser?.uid
    }

    private var isAttending: Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            return false
        }

        return currentEvent.attendees.contains(userId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 12) {
                    Text(currentEvent.title)
                        .font(.largeTitle)
                        .bold()

                    Text(currentEvent.category)
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    if isOrganizer {
                        Label(
                            "Eres el organizador",
                            systemImage: "person.crop.circle.fill"
                        )
                        .foregroundColor(.blue)

                    } else if isAttending {
                        Label(
                            "Asistencia confirmada",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundColor(.green)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 18) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fecha y hora")
                                .font(.headline)

                            Text(
                                currentEvent.date,
                                format: .dateTime.day().month().year().hour().minute()
                            )
                            .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lugar o enlace")
                                .font(.headline)

                            Text(currentEvent.location)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.blue)
                    }

                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Capacidad")
                                .font(.headline)

                            Text("\(currentEvent.capacity) participantes")
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Descripción")
                        .font(.title2)
                        .bold()

                    Text(currentEvent.description)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Asistencia")
                        .font(.title2)
                        .bold()

                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(currentEvent.attendees.count)")
                                .font(.title)
                                .bold()

                            Text("Confirmados")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 5) {
                            Text("\(currentEvent.availableSpots)")
                                .font(.title)
                                .bold()
                                .foregroundColor(
                                    currentEvent.isFull ? .red : .green
                                )

                            Text("Cupos disponibles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    ProgressView(
                        value: Double(currentEvent.attendees.count),
                        total: Double(max(currentEvent.capacity, 1))
                    )
                    .tint(.blue)

                    if currentEvent.isFull {
                        Label(
                            "Evento lleno",
                            systemImage: "exclamationmark.circle"
                        )
                        .foregroundColor(.red)
                    }
                }

                // MARK: - Acciones del organizador

                if isOrganizer {
                    VStack(spacing: 12) {

                        // Consultar asistentes confirmados
                        NavigationLink {
                            AttendeesView(event: currentEvent)
                        } label: {
                            Label(
                                "Ver asistentes confirmados",
                                systemImage: "person.2"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        // Editar evento
                        Button {
                            showingEditEvent = true
                        } label: {
                            Label(
                                "Editar evento",
                                systemImage: "pencil"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isDeleting)

                        // Eliminar evento
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label(
                                "Eliminar evento",
                                systemImage: "trash"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isDeleting)

                        if viewModel.isDeleting {
                            ProgressView("Eliminando evento...")
                        }

                        if let deleteError = deleteError {
                            Text(deleteError)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                // MARK: - Confirmación de asistencia

                if !isOrganizer {
                    VStack(spacing: 12) {

                        if let error = viewModel.attendanceError {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            viewModel.updateAttendance(
                                eventId: currentEvent.id,
                                confirm: !isAttending
                            ) { _ in
                                // Firestore actualiza el listado.
                            }
                        } label: {
                            HStack {
                                Spacer()

                                if viewModel.isUpdatingAttendance {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(
                                        systemName: isAttending
                                            ? "xmark.circle"
                                            : "checkmark.circle"
                                    )

                                    Text(
                                        isAttending
                                            ? "Cancelar asistencia"
                                            : "Confirmar asistencia"
                                    )
                                }

                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isAttending ? .red : .blue)
                        .disabled(
                            viewModel.isUpdatingAttendance
                            || (!isAttending && currentEvent.isFull)
                            || currentEvent.date <= Date()
                        )
                    }
                }

                Spacer(minLength: 30)
            }
            .padding()
        }
        .navigationTitle("Detalle del evento")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditEvent) {
            EventFormView(
                viewModel: viewModel,
                event: currentEvent
            )
        }
        .alert(
            "Eliminar evento",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                deleteError = nil

                viewModel.deleteEvent(
                    eventId: currentEvent.id
                ) { success in
                    if success {
                        dismiss()
                    } else {
                        deleteError = viewModel.errorMessage
                            ?? "No se pudo eliminar el evento."
                    }
                }
            }
        } message: {
            Text(
                "¿Estás seguro de eliminar este evento? Esta acción no se puede deshacer y se perderán las confirmaciones de asistencia."
            )
        }
        .onAppear {
            viewModel.attendanceError = nil
            deleteError = nil
        }
    }
}
