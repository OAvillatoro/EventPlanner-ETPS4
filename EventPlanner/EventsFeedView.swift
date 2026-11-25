//
//  EventsFeedView.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI

struct EventsFeedView: View {
    @ObservedObject var authViewModel: AuthViewModel

    @StateObject private var viewModel = EventsViewModel()
    @State private var selectedCategory = "Todos"
    @State private var showingCreateEvent = false

    private let categories = [
        "Todos", "Académico", "Social", "Deportivo", "Cultural"
    ]

    // Mostrar únicamente próximos eventos en Explorar
    private var filteredEvents: [Event] {
        viewModel.events.filter { event in
            event.date >= Date()
            && (
                selectedCategory == "Todos"
                || event.category == selectedCategory
            )
        }
    }

    var body: some View {
        TabView {

            // MARK: - Explorar eventos

            NavigationStack {
                VStack(spacing: 0) {

                    Picker("Categoría", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Cargando eventos...")
                        Spacer()

                    } else if let error = viewModel.errorMessage {
                        Spacer()

                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)

                            Text("No se pudieron cargar los eventos")
                                .font(.headline)

                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()

                        Spacer()

                    } else if filteredEvents.isEmpty {
                        Spacer()

                        VStack(spacing: 15) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 55))
                                .foregroundColor(.secondary)

                            Text("No hay eventos disponibles")
                                .font(.headline)

                            Text("Los próximos eventos aparecerán aquí.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()

                        Spacer()

                    } else {
                        List(filteredEvents) { event in
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
                                    .font(.subheadline)

                                    Label(event.location, systemImage: "mappin")
                                        .font(.subheadline)

                                    HStack {
                                        Image(systemName: "person.2.fill")

                                        Text("\(event.availableSpots) cupos disponibles")
                                    }
                                    .font(.caption)
                                    .foregroundColor(
                                        event.isFull ? .red : .green
                                    )
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("EventPlanner")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCreateEvent = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Crear evento")
                    }
                }
            }
            .tabItem {
                Label("Explorar", systemImage: "calendar")
            }

            // MARK: - Mis eventos

            NavigationStack {
                MyEventsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Mis eventos", systemImage: "calendar.badge.clock")
            }

            // MARK: - Perfil

            NavigationStack {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Mi perfil")
                        .font(.title)
                        .bold()

                    if !authViewModel.profileName.isEmpty {
                        Text(authViewModel.profileName)
                            .font(.title3)
                            .bold()
                            .multilineTextAlignment(.center)
                    }

                    if let email = authViewModel.user?.email {
                        Text(email)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if !authViewModel.profileOrganization.isEmpty {
                        Label(
                            authViewModel.profileOrganization,
                            systemImage: "building.2"
                        )
                        .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Label(
                            "Cerrar sesión",
                            systemImage: "rectangle.portrait.and.arrow.right"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 30)
                    .padding(.top, 15)

                    Spacer()
                }
                .padding()
                .navigationTitle("Perfil")
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle")
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            EventFormView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchEvents()
        }
    }
}

