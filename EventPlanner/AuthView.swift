//
//  AuthView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 65))
                    .foregroundColor(.blue)

                Text("EventPlanner")
                    .font(.largeTitle)
                    .bold()

                Text("Organiza eventos y confirma tu asistencia")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 15) {
                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Contraseña", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.top, 25)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button {
                    viewModel.signIn(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Iniciar sesión")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(
                    email.isEmpty ||
                    password.isEmpty ||
                    viewModel.isLoading
                )

                Spacer()

                HStack {
                    Text("¿No tienes una cuenta?")

                    NavigationLink {
                        RegisterView(viewModel: viewModel)
                    } label: {
                        Text("Regístrate")
                            .bold()
                    }
                }
                .font(.footnote)
            }
            .padding(25)
        }
    }
}
