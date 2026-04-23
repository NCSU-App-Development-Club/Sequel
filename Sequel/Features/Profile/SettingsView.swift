import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("Display") {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }

                NavigationLink {
                    SpoilerProtectionSettingsView()
                } label: {
                    Label("Spoiler Protection", systemImage: "eye.slash")
                }
            }

            Section("Account") {
                NavigationLink {
                    AccountSettingsView()
                } label: {
                    Label("Account Management", systemImage: "person.crop.circle")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appearancePreference") private var appearancePreference = AppAppearance.system.rawValue

    private var selectedAppearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearancePreference) ?? .system },
            set: { appearancePreference = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: selectedAppearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.label).tag(appearance)
                    }
                }
                .pickerStyle(.inline)
            } footer: {
                Text("This mock preference is stored locally and applied by the app shell.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SpoilerProtectionSettingsView: View {
    @AppStorage("spoilerProtectionEnabled") private var spoilerProtectionEnabled = true
    @State private var gates = SpoilerGate.mockGates

    var body: some View {
        Form {
            Section {
                Toggle("Enable spoiler protection", isOn: $spoilerProtectionEnabled)
            } footer: {
                Text("Frontend-only gating preview. Backend enforcement and per-user sync come later.")
            }

            Section("Caught Up Through") {
                ForEach($gates) { $gate in
                    Stepper(value: $gate.caughtUpSeason, in: 1...gate.totalSeasons) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(gate.showTitle)
                                .font(.subheadline.weight(.semibold))
                            Text("Season \(gate.caughtUpSeason) of \(gate.totalSeasons)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!spoilerProtectionEnabled)
                }
            }
        }
        .navigationTitle("Spoiler Protection")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountSettingsView: View {
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var accountMessage: String?

    var body: some View {
        Form {
            Section {
                Button {
                    accountMessage = "Email change flow is mocked for this PR."
                } label: {
                    Label("Change Email", systemImage: "envelope")
                }

                Button {
                    accountMessage = "Password reset flow is mocked for this PR."
                } label: {
                    Label("Change Password", systemImage: "key")
                }
            }

            Section {
                Button(role: .destructive) {
                    showingSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            } footer: {
                Text("Account actions are frontend-only in this PR and do not call Auth or Firestore.")
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Sign out?", isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                accountMessage = "Signed out locally for preview."
            }
        }
        .confirmationDialog("Delete account?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                accountMessage = "Delete account flow is mocked for this PR."
            }
        }
        .alert("Account", isPresented: Binding(get: { accountMessage != nil }, set: { if !$0 { accountMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountMessage ?? "")
        }
    }
}

struct SpoilerGate: Identifiable, Hashable {
    let id: Int
    let showTitle: String
    let totalSeasons: Int
    var caughtUpSeason: Int

    static let mockGates = [
        SpoilerGate(id: 95396, showTitle: "Severance", totalSeasons: 2, caughtUpSeason: 1),
        SpoilerGate(id: 66732, showTitle: "Stranger Things", totalSeasons: 5, caughtUpSeason: 4),
        SpoilerGate(id: 1399, showTitle: "The Last Kingdom", totalSeasons: 5, caughtUpSeason: 3),
        SpoilerGate(id: 76479, showTitle: "The Boys", totalSeasons: 4, caughtUpSeason: 2)
    ]
}
