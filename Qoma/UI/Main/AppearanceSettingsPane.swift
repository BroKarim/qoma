import SwiftUI

struct AppearanceSettingsPane: View {
    @AppStorage("qyube.coveAtmosphere") private var atmosphere = "Auto"
    var body: some View {
        Form {
            Picker("Cove atmosphere", selection: $atmosphere) {
                ForEach(["Auto", "Morning", "Sunset", "Night"], id: \.self) { Text($0) }
            }
        }.formStyle(.grouped)
    }
}
