import SwiftUI

struct MinimalControlPanel: View {
    @ObservedObject var vm: PatternViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TANQUE")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#e3dfd8"))
                        .tracking(2)
                    Text("PATTERNS")
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#6c6760"))
                        .tracking(8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(Color.white.opacity(0.07))

                VStack(spacing: 0) {
                    ControlSlider(
                        label: "Columns",
                        value: Binding(
                            get: { Double(vm.state.gridSpec.columns) },
                            set: { vm.state.gridSpec.columns = max(2, min(8, Int($0))) }
                        ),
                        range: 2...8, step: 1,
                        display: { "\(Int($0))" }
                    )

                    ControlSlider(
                        label: "Rows",
                        value: Binding(
                            get: { Double(vm.state.gridSpec.rows) },
                            set: { vm.state.gridSpec.rows = max(1, min(8, Int($0))) }
                        ),
                        range: 1...8, step: 1,
                        display: { "\(Int($0))" }
                    )

                    ControlSlider(
                        label: "Star depth",
                        value: Binding(
                            get: { vm.state.gridSpec.contactT },
                            set: { vm.state.gridSpec.contactT = $0 }
                        ),
                        range: 0.10...0.45, step: 0.01,
                        display: { "\(Int($0 * 180))°" }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }
        }
        .background(Color(hex: "#131416"))
    }
}
