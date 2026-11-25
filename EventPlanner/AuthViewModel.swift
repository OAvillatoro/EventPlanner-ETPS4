//
//  AuthViewModel.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var profileName = ""
    @Published var profileOrganization = ""
    @Published var isLoading = false
    @Published var isCheckingSession = true
    @Published var needsProfile = false
    @Published var errorMessage: String?

    private var authListener: AuthStateDidChangeListenerHandle?
    private var isRegistering = false

    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                guard let self = self else { return }

                guard let firebaseUser = firebaseUser else {
                    self.user = nil
                    self.profileName = ""
                    self.profileOrganization = ""
                    self.needsProfile = false
                    self.isCheckingSession = false
                    return
                }

                if !self.isRegistering {
                    self.loadProfile(for: firebaseUser)
                }
            }
        }
    }

    deinit {
        if let authListener = authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // MARK: - Verificar perfil

    private func loadProfile(for firebaseUser: User) {
        isCheckingSession = true
        errorMessage = nil

        Firestore.firestore()
            .collection("users")
            .document(firebaseUser.uid)
            .getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    guard Auth.auth().currentUser?.uid == firebaseUser.uid else {
                        return
                    }

                    self.isCheckingSession = false

                    if let error = error {
                        self.user = nil
                        self.errorMessage = "Error al consultar el perfil: \(error.localizedDescription)"
                        return
                    }

                    if let data = document?.data() {
                        let name = data["name"] as? String ?? ""

                        self.profileName = name
                        self.profileOrganization = data["organization"] as? String ?? ""
                        self.user = firebaseUser
                        self.needsProfile = false

                        self.publishAttendeeName(
                            userId: firebaseUser.uid,
                            name: name
                        )
                    } else {
                        self.user = nil
                        self.profileName = ""
                        self.profileOrganization = ""
                        self.needsProfile = true
                    }
                }
            }
    }

    // MARK: - Publicar nombre visible

    private func publishAttendeeName(userId: String, name: String) {
        guard !name.isEmpty else { return }

        Firestore.firestore()
            .collection("attendeeProfiles")
            .document(userId)
            .setData(["name": name]) { error in
                if let error = error {
                    print("Error al publicar nombre del asistente: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - Iniciar sesión

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Registrar usuario

    func register(name: String, email: String, organization: String, password: String) {
        isLoading = true
        isRegistering = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in

            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.isRegistering = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.isRegistering = false
                    self?.errorMessage = "No se pudo crear el usuario."
                }
                return
            }

            let userData: [String: Any] = [
                "name": name,
                "email": firebaseUser.email ?? email,
                "organization": organization
            ]

            Firestore.firestore()
                .collection("users")
                .document(firebaseUser.uid)
                .setData(userData) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self = self else { return }

                        self.isLoading = false
                        self.isRegistering = false
                        self.isCheckingSession = false

                        if let error = error {
                            self.user = nil
                            self.needsProfile = true
                            self.errorMessage = "No se pudo guardar el perfil: \(error.localizedDescription)"
                        } else {
                            self.profileName = name
                            self.profileOrganization = organization
                            self.needsProfile = false
                            self.errorMessage = nil
                            self.user = firebaseUser

                            self.publishAttendeeName(
                                userId: firebaseUser.uid,
                                name: name
                            )
                        }
                    }
                }
        }
    }

    // MARK: - Completar perfil existente

    func completeProfile(name: String, organization: String) {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No hay una sesión activa."
            return
        }

        isLoading = true
        errorMessage = nil

        let userData: [String: Any] = [
            "name": name,
            "email": firebaseUser.email ?? "",
            "organization": organization
        ]

        Firestore.firestore()
            .collection("users")
            .document(firebaseUser.uid)
            .setData(userData) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "No se pudo completar el perfil: \(error.localizedDescription)"
                    } else {
                        self.profileName = name
                        self.profileOrganization = organization
                        self.needsProfile = false
                        self.errorMessage = nil
                        self.user = firebaseUser

                        self.publishAttendeeName(
                            userId: firebaseUser.uid,
                            name: name
                        )
                    }
                }
            }
    }

    // MARK: - Cerrar sesión

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            profileName = ""
            profileOrganization = ""
            needsProfile = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

