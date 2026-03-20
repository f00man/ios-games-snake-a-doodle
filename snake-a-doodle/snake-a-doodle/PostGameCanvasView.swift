import SwiftUI
import UIKit
import PencilKit
import PhotosUI

// MARK: - Brush Type

enum BrushType: String, CaseIterable, Identifiable {
    case pen        = "Pen"
    case pencil     = "Pencil"
    case marker     = "Marker"
    case monoline   = "Mono"
    case fountain   = "Fountain"
    case watercolor = "Water"
    case crayon     = "Crayon"

    var id: String { rawValue }

    var inkType: PKInkingTool.InkType {
        switch self {
        case .pen:        return .pen
        case .pencil:     return .pencil
        case .marker:     return .marker
        case .monoline:   return .monoline
        case .fountain:   return .fountainPen
        case .watercolor: return .watercolor
        case .crayon:     return .crayon
        }
    }

    var icon: String {
        switch self {
        case .pen:        return "pencil"
        case .pencil:     return "pencil.tip"
        case .marker:     return "highlighter"
        case .monoline:   return "line.diagonal"
        case .fountain:   return "paintbrush.pointed"
        case .watercolor: return "drop"
        case .crayon:     return "scribble"
        }
    }
}

// MARK: - Post-Game Canvas View

struct PostGameCanvasView: View {
    let snakeBody: [SnakeSegment]
    let foods: [Food]
    let score: Int
    let onQuit: () -> Void
    let onRestart: () -> Void

    @State private var canvasView = PKCanvasView()
    @State private var drawColor: Color = .yellow
    @State private var brushType: BrushType = .pen
    @State private var toolMode: ToolMode = .draw
    @State private var placedStickers: [PlacedSticker] = []
    @State private var placedPhotos: [PlacedPhoto] = []
    @State private var showStickerPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var shareItem: UIImage?

    private let cellPad: CGFloat = 1
    private let toolbarH: CGFloat = 100  // brush row (36) + main row (64)

    enum ToolMode { case draw, erase }

    private var activeTool: PKTool {
        toolMode == .erase
            ? PKEraserTool(.bitmap)
            : PKInkingTool(brushType.inkType, color: UIColor(drawColor), width: 5)
    }

    var body: some View {
        GeometryReader { geo in
            // Board is square: cell size driven by width only, matching GameView
            let cellSize = geo.size.width / CGFloat(GameEngine.columns)
            let boardW = geo.size.width
            let boardH = boardW  // square

            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: onQuit) {
                            Label("Quit", systemImage: "xmark")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("Score: \(score)")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.yellow)
                        Spacer()
                        Button(action: onRestart) {
                            Label("Play Again", systemImage: "arrow.clockwise")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)

                    // Canvas area
                    ZStack {
                        Canvas { ctx, _ in
                            drawFrozenBoard(ctx: ctx, cellSize: cellSize, w: boardW, h: boardH)
                        }
                        .frame(width: boardW, height: boardH)

                        DrawingCanvasView(canvasView: $canvasView, tool: activeTool)
                            .frame(width: boardW, height: boardH)

                        ForEach($placedStickers) { $sticker in
                            DraggableStickerView(sticker: $sticker)
                        }
                        ForEach($placedPhotos) { $photo in
                            DraggablePhotoView(photo: $photo)
                        }
                    }
                    .frame(width: boardW, height: boardH)
                    .clipped()

                    Spacer()

                    canvasToolbar(cellSize: cellSize, boardW: boardW, boardH: boardH)
                        .frame(height: toolbarH)
                }
            }
        }
        .onChange(of: photoPickerItem) { _, item in loadPhoto(item) }
        .overlay {
            if showStickerPicker {
                stickerPickerSheet.transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showStickerPicker)
        .sheet(item: $shareItem) { image in
            ShareSheet(image: image)
        }
    }

    // MARK: Toolbar

    private func canvasToolbar(cellSize: CGFloat, boardW: CGFloat, boardH: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Brush type row — shown in draw mode
            if toolMode == .draw {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(BrushType.allCases) { brush in
                            Button {
                                brushType = brush
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: brush.icon)
                                        .font(.system(size: 14))
                                    Text(brush.rawValue)
                                        .font(.system(size: 9))
                                }
                                .foregroundStyle(brushType == brush ? .black : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(brushType == brush ? Color.yellow : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 36)
                .background(Color(white: 0.08))
            } else {
                Color(white: 0.08).frame(height: 36)
            }

            // Main tools row
            HStack(spacing: 18) {
                // Draw (enters draw mode)
                ToolBtn(icon: "pencil.tip", label: "Draw", active: toolMode == .draw) {
                    toolMode = .draw
                }

                // Color picker (draw mode only)
                if toolMode == .draw {
                    ColorPicker("", selection: $drawColor)
                        .labelsHidden()
                        .frame(width: 34, height: 34)
                }

                // Erase
                ToolBtn(icon: "eraser", label: "Erase", active: toolMode == .erase) {
                    toolMode = .erase
                }

                // Sticker
                ToolBtn(icon: "face.smiling", label: "Sticker", active: showStickerPicker) {
                    showStickerPicker.toggle()
                }

                // Photo
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    VStack(spacing: 2) {
                        Image(systemName: "photo").font(.system(size: 20))
                        Text("Photo").font(.system(size: 9))
                    }
                    .foregroundStyle(.white)
                }

                Spacer()

                // Clear
                ToolBtn(icon: "trash", label: "Clear", active: false) {
                    canvasView.drawing = PKDrawing()
                    placedStickers.removeAll()
                    placedPhotos.removeAll()
                }

                // Save / Share
                ToolBtn(icon: "square.and.arrow.up", label: "Save", active: false) {
                    shareItem = renderCanvas(cellSize: cellSize, boardW: boardW, boardH: boardH)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color(white: 0.1))
        }
    }

    // MARK: Sticker Picker

    private let availableStickers = ["⭐️","🔥","💀","🐍","❤️","😱","🎉","👏","💪","😂","🍎","🌟","🏆","💥","🎨","✏️"]

    private var stickerPickerSheet: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                HStack {
                    Text("Pick a sticker").font(.headline).foregroundStyle(.primary)
                    Spacer()
                    Button { showStickerPicker = false } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
                .padding()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                    ForEach(availableStickers, id: \.self) { emoji in
                        Button(emoji) {
                            placedStickers.append(
                                PlacedSticker(emoji: emoji, position: CGPoint(x: 100, y: 100))
                            )
                            showStickerPicker = false
                        }
                        .font(.system(size: 30))
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .onTapGesture { showStickerPicker = false }
    }

    // MARK: Frozen Board (SwiftUI Canvas)

    private func drawFrozenBoard(ctx: GraphicsContext, cellSize: CGFloat, w: CGFloat, h: CGFloat) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(.black))

        for (i, seg) in snakeBody.enumerated() {
            let rect = cellRect(col: seg.position.col, row: seg.position.row, cellSize: cellSize, inset: cellPad)
            let isHead = i == 0
            let color = isHead ? seg.color : seg.color.opacity(0.75)
            ctx.fill(
                Path(roundedRect: rect, cornerRadius: isHead ? cellSize * 0.35 : cellSize * 0.18),
                with: .color(color)
            )
        }

        for food in foods {
            switch food.type {
            case .grow:
                let r = cellRect(col: food.position.col, row: food.position.row, cellSize: cellSize, inset: cellPad * 2.5)
                ctx.fill(Path(ellipseIn: r), with: .color(.red))
            case .colorChange:
                let outer = cellRect(col: food.position.col, row: food.position.row, cellSize: cellSize, inset: cellPad)
                let inner = cellRect(col: food.position.col, row: food.position.row, cellSize: cellSize, inset: cellPad * 2.5)
                ctx.fill(Path(ellipseIn: inner), with: .color(food.displayColor))
                ctx.stroke(Path(ellipseIn: outer), with: .color(.white.opacity(0.7)), lineWidth: 1.5)
            }
        }

        ctx.stroke(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(.green.opacity(0.4)), lineWidth: 1)
    }

    private func cellRect(col: Int, row: Int, cellSize: CGFloat, inset: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(col) * cellSize + inset,
            y: CGFloat(row) * cellSize + inset,
            width: cellSize - inset * 2,
            height: cellSize - inset * 2
        )
    }

    // MARK: Canvas Rendering (Save / Share)

    private func renderCanvas(cellSize: CGFloat, boardW: CGFloat, boardH: CGFloat) -> UIImage {
        let scale = UIScreen.main.scale
        let size = CGSize(width: boardW, height: boardH)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let cg = ctx.cgContext

            // Board
            drawBoardCG(in: cg, cellSize: cellSize, w: boardW, h: boardH)

            // PencilKit strokes
            let ink = canvasView.drawing.image(from: CGRect(origin: .zero, size: size), scale: scale)
            ink.draw(in: CGRect(origin: .zero, size: size))

            // Stickers
            for sticker in placedStickers {
                let sz = 44 * sticker.scale
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: sz)]
                NSAttributedString(string: sticker.emoji, attributes: attrs)
                    .draw(at: CGPoint(x: sticker.position.x - sz / 2, y: sticker.position.y - sz / 2))
            }

            // Photos
            let base: CGFloat = 110
            for photo in placedPhotos {
                let s = base * photo.scale
                photo.image.draw(in: CGRect(x: photo.position.x - s / 2, y: photo.position.y - s / 2, width: s, height: s))
            }
        }
    }

    private func drawBoardCG(in ctx: CGContext, cellSize: CGFloat, w: CGFloat, h: CGFloat) {
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        for (i, seg) in snakeBody.enumerated() {
            let isHead = i == 0
            let rect = CGRect(
                x: CGFloat(seg.position.col) * cellSize + cellPad,
                y: CGFloat(seg.position.row) * cellSize + cellPad,
                width: cellSize - cellPad * 2, height: cellSize - cellPad * 2
            )
            let radius = isHead ? cellSize * 0.35 : cellSize * 0.18
            var uiColor = UIColor(seg.color)
            if !isHead { uiColor = uiColor.withAlphaComponent(0.75) }
            ctx.setFillColor(uiColor.cgColor)
            ctx.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
            ctx.fillPath()
        }

        for food in foods {
            switch food.type {
            case .grow:
                let r = CGRect(
                    x: CGFloat(food.position.col) * cellSize + cellPad * 2.5,
                    y: CGFloat(food.position.row) * cellSize + cellPad * 2.5,
                    width: cellSize - cellPad * 5, height: cellSize - cellPad * 5
                )
                ctx.setFillColor(UIColor.red.cgColor)
                ctx.fillEllipse(in: r)

            case .colorChange:
                let inner = CGRect(
                    x: CGFloat(food.position.col) * cellSize + cellPad * 2.5,
                    y: CGFloat(food.position.row) * cellSize + cellPad * 2.5,
                    width: cellSize - cellPad * 5, height: cellSize - cellPad * 5
                )
                ctx.setFillColor(UIColor(food.displayColor).cgColor)
                ctx.fillEllipse(in: inner)
            }
        }
    }

    // MARK: Photo Loading

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result,
                   let data, let uiImage = UIImage(data: data) {
                    placedPhotos.append(PlacedPhoto(image: uiImage, position: CGPoint(x: 120, y: 120)))
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

// MARK: - Data Types

struct PlacedSticker: Identifiable {
    let id = UUID()
    var emoji: String
    var position: CGPoint
    var scale: CGFloat = 1.0
}

struct PlacedPhoto: Identifiable {
    let id = UUID()
    var image: UIImage
    var position: CGPoint
    var scale: CGFloat = 1.0
}

// MARK: - Draggable Views

struct DraggableStickerView: View {
    @Binding var sticker: PlacedSticker
    @GestureState private var dragOffset = CGSize.zero
    @GestureState private var pinchScale: CGFloat = 1.0

    var body: some View {
        Text(sticker.emoji)
            .font(.system(size: 44 * sticker.scale * pinchScale))
            .position(x: sticker.position.x + dragOffset.width,
                      y: sticker.position.y + dragOffset.height)
            .gesture(DragGesture()
                .updating($dragOffset) { v, s, _ in s = v.translation }
                .onEnded { v in
                    sticker.position.x += v.translation.width
                    sticker.position.y += v.translation.height
                })
            .simultaneousGesture(MagnificationGesture()
                .updating($pinchScale) { v, s, _ in s = v }
                .onEnded { v in sticker.scale = max(0.4, min(3.0, sticker.scale * v)) })
    }
}

struct DraggablePhotoView: View {
    @Binding var photo: PlacedPhoto
    @GestureState private var dragOffset = CGSize.zero
    @GestureState private var pinchScale: CGFloat = 1.0
    private let base: CGFloat = 110

    var body: some View {
        Image(uiImage: photo.image)
            .resizable().scaledToFit()
            .frame(width: base * photo.scale * pinchScale,
                   height: base * photo.scale * pinchScale)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.5), lineWidth: 1))
            .position(x: photo.position.x + dragOffset.width,
                      y: photo.position.y + dragOffset.height)
            .gesture(DragGesture()
                .updating($dragOffset) { v, s, _ in s = v.translation }
                .onEnded { v in
                    photo.position.x += v.translation.width
                    photo.position.y += v.translation.height
                })
            .simultaneousGesture(MagnificationGesture()
                .updating($pinchScale) { v, s, _ in s = v }
                .onEnded { v in photo.scale = max(0.4, min(4.0, photo.scale * v)) })
    }
}

// MARK: - Toolbar Button

struct ToolBtn: View {
    let icon: String
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: 9))
            }
            .foregroundStyle(active ? .green : .white)
        }
    }
}
