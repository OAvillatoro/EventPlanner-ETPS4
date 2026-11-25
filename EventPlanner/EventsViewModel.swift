//
//  EventsViewModel.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class EventsViewModel: ObservableObject {

    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isDeleting = false
    @Published var isUpdatingAttendance = false
    @Published var errorMessage: String?
    @Published var attendanceError: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Escuchar eventos en tiempo real

    func fetchEvents() {
        listener?.remove()
        isLoading = true
        errorMessage = nil

        listener = db.collection("events")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.errorMessage = nil

                    guard let documents = snapshot?.documents else {
                        self.events = []
                        return
                    }

                    // Conservar todos los eventos, incluidos los pasados.
                    self.events = documents
                        .compactMap { Event(document: $0) }
                        .sorted { $0.date < $1.date }
                }
            }
    }

    // MARK: - Crear evento

    func createEvent(
        title: String,
        description: String,
        category: String,
        location: String,
        date: Date,
        capacity: Int,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Debes iniciar sesión para crear un evento."
            completion(false)
            return
        }

        isSaving = true
        errorMessage = nil

        let eventData: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "location": location,
            "date": Timestamp(date: date),
            "capacity": capacity,
            "organizerId": userId,
            "attendees": []
        ]

        db.collection("events").addDocument(data: eventData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    // MARK: - Editar evento

    func updateEvent(
        eventId: String,
        title: String,
        description: String,
        category: String,
        location: String,
        date: Date,
        capacity: Int,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Debes iniciar sesión para editar un evento."
            completion(false)
            return
        }

        guard capacity > 0, date > Date() else {
            errorMessage = "Verifica la fecha y la capacidad del evento."
            completion(false)
            return
        }

        isSaving = true
        errorMessage = nil

        let reference = db.collection("events").document(eventId)

        let updatedData: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "location": location,
            "date": Timestamp(date: date),
            "capacity": capacity
        ]

        db.runTransaction({ transaction, errorPointer -> Any? in

            let document: DocumentSnapshot

            do {
                document = try transaction.getDocument(reference)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = document.data(),
                  let organizerId = data["organizerId"] as? String,
                  let attendees = data["attendees"] as? [String]
            else {
                errorPointer?.pointee = NSError(
                    domain: "EventPlanner",
                    code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "No se pudo consultar el evento."
                    ]
                )
                return nil
            }

            guard organizerId == userId else {
                errorPointer?.pointee = NSError(
                    domain: "EventPlanner",
                    code: 4,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Solo el organizador puede editar este evento."
                    ]
                )
                return nil
            }

            guard capacity >= attendees.count else {
                errorPointer?.pointee = NSError(
                    domain: "EventPlanner",
                    code: 5,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "La capacidad no puede ser menor que los asistentes confirmados."
                    ]
                )
                return nil
            }

            transaction.updateData(updatedData, forDocument: reference)

            return nil

        }) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isSaving = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self?.errorMessage = nil
                    completion(true)
                }
            }
        }
    }

    // MARK: - Eliminar evento

    func deleteEvent(
        eventId: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Debes iniciar sesión para eliminar un evento."
            completion(false)
            return
        }

        guard let event = events.first(where: { $0.id == eventId }),
              event.organizerId == userId else {
            errorMessage = "Solo el organizador puede eliminar este evento."
            completion(false)
            return
        }

        isDeleting = true
        errorMessage = nil

        db.collection("events")
            .document(eventId)
            .delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.isDeleting = false

                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        self?.errorMessage = nil
                        completion(true)
                    }
                }
            }
    }

    // MARK: - Confirmar o cancelar asistencia

    func updateAttendance(
        eventId: String,
        confirm: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            attendanceError = "Debes iniciar sesión."
            completion(false)
            return
        }

        isUpdatingAttendance = true
        attendanceError = nil

        let reference = db.collection("events").document(eventId)

        db.runTransaction({ transaction, errorPointer -> Any? in

            let document: DocumentSnapshot

            do {
                document = try transaction.getDocument(reference)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = document.data(),
                  let attendees = data["attendees"] as? [String],
                  let capacity = data["capacity"] as? Int,
                  let organizerId = data["organizerId"] as? String,
                  let eventDate = data["date"] as? Timestamp
            else {
                errorPointer?.pointee = NSError(
                    domain: "EventPlanner",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "No se pudo consultar el evento."
                    ]
                )
                return nil
            }

            var updatedAttendees = attendees
            var message: String?

            if organizerId == userId {
                message = "El organizador no puede confirmar asistencia."

            } else if eventDate.dateValue() <= Date() {
                message = "Este evento ya ha comenzado."

            } else if confirm {
                if attendees.contains(userId) {
                    message = "Ya confirmaste tu asistencia."
                } else if attendees.count >= capacity {
                    message = "No hay cupos disponibles."
                } else {
                    updatedAttendees.append(userId)
                }

            } else {
                if !attendees.contains(userId) {
                    message = "No tienes una asistencia confirmada."
                } else {
                    updatedAttendees.removeAll { $0 == userId }
                }
            }

            if let message = message {
                errorPointer?.pointee = NSError(
                    domain: "EventPlanner",
                    code: 2,
                    userInfo: [
                        NSLocalizedDescriptionKey: message
                    ]
                )
                return nil
            }

            transaction.updateData(
                ["attendees": updatedAttendees],
                forDocument: reference
            )

            return nil

        }) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isUpdatingAttendance = false

                if let error = error {
                    self?.attendanceError = error.localizedDescription
                    completion(false)
                } else {
                    self?.attendanceError = nil
                    completion(true)
                }
            }
        }
    }

    // MARK: - Detener escucha

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }
}

