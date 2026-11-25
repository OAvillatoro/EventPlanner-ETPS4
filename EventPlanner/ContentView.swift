//
//  ContentView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isCheckingSession {
                ProgressView("Verificando sesión...")

            } else if let user = authViewModel.user {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Bienvenido a EventPlanner")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text(user.email ?? "")
                        .foregroundColor(.secondary)

                    Button("Cerrar sesión") {
                        authViewModel.signOut()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

            } else if authViewModel.needsProfile {
                CompleteProfileView(viewModel: authViewModel)

            } else {
                AuthView(viewModel: authViewModel)
            }
        }
    }
}

// MARK: - Completar perfil

struct CompleteProfileView: View {
    @ObservedObject var viewModel: AuthViewModel

    @State private var name = ""
    @State private var organization = ""

    private var validName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Completar perfil")
                .font(.largeTitle)
                .bold()

            Text("Tu cuenta ya existe. Completa tus datos para continuar.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 15) {
                TextField("Nombre completo", text: $name)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)

                TextField("Organización (opcional)", text: $organization)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.top, 15)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.completeProfile(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    organization: organization.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Guardar perfil")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!validName || viewModel.isLoading)

            Button("Cerrar sesión") {
                viewModel.signOut()
            }
            .disabled(viewModel.isLoading)

            Spacer()
        }
        .padding(25)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

