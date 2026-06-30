import SwiftUI

struct ExtensionsSettingsPane: View {
    @ObservedObject private var extensionManager = ExtensionManager.shared

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Extensions",
                    subtitle: "Activate optional modules that extend the floating timer panel."
                )

                VStack(alignment: .leading, spacing: 12) {
                    

                    LazyVGrid(columns: self.columns, spacing: 12) {
                        if extensionManager.registered.isEmpty {
                            self.comingSoonCard
                        } else {
                            ForEach(extensionManager.registered, id: \.id) { ext in
                                SettingsSurfaceCard {
                                    self.extensionCard(
                                        title: ext.title,
                                        description: ext.description,
                                        icon: ext.systemImage,
                                        isEnabled: extensionManager.binding(for: ext)
                                    )
                                }
                            }

                            if extensionManager.registered.count % 2 != 0 {
                                self.comingSoonCard
                            }
                        }
                    }
                }
            }
            .padding(24)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

private var comingSoonCard: some View {
    SettingsSurfaceCard {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Row 1: Icon + Title -> Flex-start (Justify Start)
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.qoma(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                    
                    Text("Coming soon")
                        .font(.qoma(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Row 2: Full-width Description (Memotong dengan ... jika kepanjangan)
                Text("More extensions coming in future updates.")
                    .font(.qomaSubheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2) // Batasi baris agar seragam (misal 2 atau 3 baris)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20) 
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(maxHeight: .infinity, alignment: .topLeading) // Memaksa tinggi card mengisi ruang grid secara penuh
        }
    }
}

private func extensionCard(
    title: String,
    description: String,
    icon: String,
    isEnabled: Binding<Bool>
) -> some View {
    VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 8) {
            // Row 1: Icon + Title (Left) & Toggle (Right) -> Justify Between
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.qoma(size: 15, weight: .regular))
                        .foregroundColor(isEnabled.wrappedValue ? .accentColor : .secondary)
                        .frame(width: 22, height: 22)
                    
                    Text(title)
                        .font(.qoma(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Toggle("", isOn: isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }
            
            // Row 2: Full-width Description (Memotong dengan ... jika kepanjangan)
            Text(description)
                .font(.qomaSubheadline)
                .foregroundColor(.secondary)
                .lineLimit(2) // Batasi baris agar seragam (misal 2 atau 3 baris)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20) 
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .topLeading) // Memaksa tinggi card mengisi ruang grid secara penuh
    }
}
}
