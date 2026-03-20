import SwiftUI
import PencilKit

/// UIViewRepresentable wrapper around PKCanvasView for the post-game drawing layer.
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var tool: PKTool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = tool
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = tool
    }
}
