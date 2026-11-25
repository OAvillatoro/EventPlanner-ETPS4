//
//  RegisterView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var organization = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var isValid: Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        return !cleanName.isEmpty
            && cleanEmail.contains("@")
            && cleanEmail.contains(".")
            && password.count >= 6
            && password == confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Crear cuenta")
                    .font(.largeTitle)
                    .bold()

                Text("Regístrate para organizar eventos")
                    .foregroundColor(.secondary)

                VStack(spacing: 15) {
                    TextField("Nombre completo", text: $name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    TextField("Organización (opcional)", text: $organization)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Contraseña (mínimo 6 caracteres)", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirmar contraseña", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.top, 15)

                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Las contraseñas no coinciden.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    viewModel.register(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        organization: organization.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Registrarme")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isValid || viewModel.isLoading)
            }
            .padding(25)
        }
        .navigationTitle("Registro")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.errorMessage = nil
        }
    }
}

