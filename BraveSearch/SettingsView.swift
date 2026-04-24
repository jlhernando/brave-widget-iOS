import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editingKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $editingKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Brave Search API Key")
                } footer: {
                    Text("Get your API key at brave.com/search/api\nFree tier includes ~1,000 queries/month.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("1. Go to brave.com/search/api", systemImage: "1.circle.fill")
                        Label("2. Click \"Get Started\" and create an account", systemImage: "2.circle.fill")
                        Label("3. Subscribe (free $5 monthly credit)", systemImage: "3.circle.fill")
                        Label("4. Copy your API key from the dashboard", systemImage: "4.circle.fill")
                        Label("5. Paste it above and tap Save", systemImage: "5.circle.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                    Link(destination: URL(string: "https://brave.com/search/api/")!) {
                        HStack {
                            Text("Open Brave Search API")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                } header: {
                    Text("How to get an API key")
                } footer: {
                    Text("You get $5 in free credits every month (~1,000 searches). No charge unless you go over.")
                }

                Section {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Powered by", value: "Brave Search")
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        KeychainHelper.saveAPIKey(editingKey)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                editingKey = KeychainHelper.loadAPIKey()
            }
        }
    }
}
