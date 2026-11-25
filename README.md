# EventPlanner - Proyecto Final ETPS4

Aplicación iOS desarrollada con SwiftUI y Firebase para
organizar eventos y gestionar confirmaciones de asistencia (RSVP).

## Tecnologías

- Swift
- SwiftUI
- Arquitectura MVVM
- Firebase Authentication
- Cloud Firestore
- Xcode 14.2
- iOS 16.2

## Funcionalidades

- Registro e inicio de sesión.
- Perfil con nombre, correo y organización.
- Listado de próximos eventos.
- Filtros por categoría.
- Creación, consulta, edición y eliminación de eventos.
- Confirmación y cancelación de asistencia.
- Control de capacidad mediante transacciones.
- Lista de asistentes con nombres.
- Actualizaciones en tiempo real mediante SnapshotListener.

## Configuración

1. Clonar el repositorio.
2. Abrir EventPlanner.xcodeproj en Xcode.
3. Agregar GoogleService-Info.plist al target EventPlanner.
4. Esperar a que Xcode resuelva las dependencias de Firebase.
5. Seleccionar un simulador compatible con iOS 16.2 o posterior.
6. Compilar y ejecutar.

## Firebase

El proyecto utiliza:

- users: perfiles privados.
- attendeeProfiles: nombres visibles de asistentes.
- events: eventos y confirmaciones RSVP.

Las reglas utilizadas se encuentran en firestore.rules.

El archivo GoogleService-Info.plist no está incluido en el repositorio.
Debe solicitarse al responsable del proyecto.

## Integrantes

- Oscar Villatoro: desarrollo de la aplicación.
- Sandra Martínez: documentación PDF.
- Alan Reyes: presentación y material explicativo.

## Entrega

03 de diciembre de 2026.
