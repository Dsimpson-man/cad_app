import Foundation
import SwiftUI

struct MainWorkspaceView: View {
    @StateObject private var model = CADViewModel()
    @State private var width = "50"
    @State private var depth = "40"
    @State private var height = "30"
    @State private var pushPull = "5"

    var body: some View {
        ZStack(alignment: .top) {
            CADViewport(model: model).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                HStack(alignment: .bottom) {
                    statusPill
                    Spacer()
                    inspector
                }
                .padding(14)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: model.resetBox) {
                Label("Box", systemImage: "cube")
            }
            .buttonStyle(.borderedProminent)

            Divider().frame(height: 24)

            Label("D-One CAD", systemImage: "scribble.variable")
                .font(.headline)

            Spacer()

            Text(model.coreLabel)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.thinMaterial)
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.selectedFaceID == nil ? "BODY" : "FACE \((model.selectedFaceID ?? 0) + 1)")
                .font(.caption.bold()).foregroundStyle(.secondary)

            HStack {
                field("W", text: $width)
                field("D", text: $depth)
                field("H", text: $height)
            }
            Button("Apply Box Size") {
                guard let w=Float(width), let d=Float(depth), let h=Float(height) else { return }
                model.setBox(width: w, depth: d, height: h)
            }
            .buttonStyle(.bordered)

            if model.selectedFaceID != nil {
                HStack {
                    TextField("mm", text: $pushPull).textFieldStyle(.roundedBorder).frame(width: 82)
                    Button("Push / Pull") {
                        if let d=Float(pushPull) { model.pushPull(distance: d) }
                    }.buttonStyle(.borderedProminent)
                }
            }

            Text("Pencil: tap a face, then drag vertically\nFinger: orbit · two fingers: pan/zoom")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusPill: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(model.status).font(.caption.weight(.medium))
            Text(String(format: "%.1f × %.1f × %.1f mm", model.dimensions.x, model.dimensions.y, model.dimensions.z))
                .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField(label, text: text).textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
        }
    }
}
