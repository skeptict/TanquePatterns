import SwiftUI

struct ControlSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let display: (Double) -> String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#9a938b"))
                Spacer()
                Text(display(value))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#c9a058"))
            }
            Slider(value: $value, in: range, step: step)
                .tint(Color(hex: "#c9a058"))
        }
        .padding(.bottom, 11)
    }
}
