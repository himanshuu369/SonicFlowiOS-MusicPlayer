import SwiftUI

struct WaveformView: View {
    let values: [CGFloat]
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(values.indices, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .bottom, endPoint: .top))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, values[index] * 54))
            }
        }
        .frame(height: 58)
        .animation(.easeOut(duration: 0.12), value: values)
    }
}

struct EqualizerView: View {
    let values: [CGFloat]
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(values.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cyan.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(5, values[index] * 72))
            }
        }
        .frame(height: 76)
        .animation(.linear(duration: 0.1), value: values)
    }
}

struct SpectrumView: View {
    let values: [CGFloat]
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(values.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .bottom, endPoint: .top))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(3, values[index] * 86))
            }
        }
        .frame(height: 90, alignment: .bottom)
        .animation(.easeOut(duration: 0.12), value: values)
    }
}
