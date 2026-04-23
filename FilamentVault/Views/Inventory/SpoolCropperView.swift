import SwiftUI
import UIKit

/// Full-screen cropper: pan/zoom the source image behind a vertical capsule
/// silhouette mask. Tapping "Use photo" renders the masked region to a JPEG
/// and returns the filename via onCropped.
struct SpoolCropperView: View {
    let sourceFilename: String
    let onCropped: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var viewportSize: CGSize = .zero
    @State private var saving = false

    private var sourceImage: UIImage? {
        ImageStorage.load(sourceFilename)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Position the filament inside the spool outline")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 16)

                Text("Drag · Pinch to zoom · Use buttons to rotate")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                GeometryReader { geo in
                    ZStack {
                        if let img = sourceImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .scaleEffect(scale)
                                .rotationEffect(rotation)
                                .offset(offset)
                        }

                        // Mask overlay
                        SpoolMaskOverlay()
                            .allowsHitTesting(false)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { v in
                                    scale = max(0.3, min(6, lastScale * v))
                                }
                                .onEnded { _ in lastScale = scale },
                            DragGesture()
                                .onChanged { v in
                                    offset = CGSize(
                                        width: lastOffset.width + v.translation.width,
                                        height: lastOffset.height + v.translation.height
                                    )
                                }
                                .onEnded { _ in lastOffset = offset }
                        )
                    )
                    .onAppear { viewportSize = geo.size }
                    .onChange(of: geo.size) { _, new in viewportSize = new }
                }

                // Rotation buttons
                HStack(spacing: 24) {
                    rotButton(icon: "rotate.left") {
                        rotation -= .degrees(90)
                    }
                    rotButton(icon: "arrow.counterclockwise") {
                        rotation -= .degrees(15)
                    }
                    rotButton(icon: "arrow.clockwise") {
                        rotation += .degrees(15)
                    }
                    rotButton(icon: "rotate.right") {
                        rotation += .degrees(90)
                    }
                }
                .padding(.bottom, 8)

                HStack(spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                    }
                    Button {
                        Task { await crop() }
                    } label: {
                        Text(saving ? "Saving..." : "Use photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(saving)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }

    private func rotButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
    }

    // MARK: - Crop rendering

    private func crop() async {
        guard let source = sourceImage, viewportSize.width > 0 else { return }
        saving = true
        let result = await Task.detached(priority: .userInitiated) { () -> String? in
            return renderCrop(
                source: source,
                viewportSize: viewportSize,
                scale: scale,
                offset: offset,
                rotationRadians: rotation.radians
            )
        }.value
        saving = false
        if let filename = result {
            onCropped(filename)
        } else {
            dismiss()
        }
    }

    private func renderCrop(
        source: UIImage,
        viewportSize: CGSize,
        scale: CGFloat,
        offset: CGSize,
        rotationRadians: Double
    ) -> String? {
        let w = viewportSize.width
        let h = viewportSize.height

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let out = renderer.image { ctx in
            let cg = ctx.cgContext
            // Fill background (shows through mask)
            cg.setFillColor(UIColor(white: 0.07, alpha: 1).cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

            // Apply the same transform stack the preview uses:
            // scaledToFit within viewport → rotation around center → scale around center → offset
            let imgSize = source.size
            let fitScale = min(w / imgSize.width, h / imgSize.height)
            let fittedW = imgSize.width * fitScale
            let fittedH = imgSize.height * fitScale
            let fittedX = (w - fittedW) / 2
            let fittedY = (h - fittedH) / 2

            cg.saveGState()
            cg.translateBy(x: w / 2, y: h / 2)
            cg.translateBy(x: offset.width, y: offset.height)
            cg.scaleBy(x: scale, y: scale)
            cg.rotate(by: CGFloat(rotationRadians))
            cg.translateBy(x: -w / 2, y: -h / 2)
            source.draw(in: CGRect(x: fittedX, y: fittedY, width: fittedW, height: fittedH))
            cg.restoreGState()
        }

        // Apply mask: keep only inside the capsule region
        let maskedImage = applySpoolMask(to: out, viewportSize: viewportSize)

        // Save JPEG
        return ImageStorage.save(maskedImage, prefix: "spool")
    }

    private func applySpoolMask(to image: UIImage, viewportSize: CGSize) -> UIImage {
        let w = viewportSize.width
        let h = viewportSize.height
        let maskInset = w * 0.12
        let maskRect = CGRect(
            x: maskInset,
            y: h * 0.05,
            width: w - 2 * maskInset,
            height: h * 0.90
        )
        let radius = maskRect.width / 2

        let renderer = UIGraphicsImageRenderer(size: viewportSize)
        return renderer.image { ctx in
            // Fill whole viewport with a neutral dark background
            UIColor(white: 0.07, alpha: 1).setFill()
            ctx.cgContext.fill(CGRect(origin: .zero, size: viewportSize))

            // Clip to the capsule shape
            let path = UIBezierPath(roundedRect: maskRect, cornerRadius: radius)
            path.addClip()
            image.draw(at: .zero)
        }
    }
}

/// Draws the dim mask + bright outline matching the crop region.
struct SpoolMaskOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let maskInset = w * 0.12
            let maskRect = CGRect(
                x: maskInset,
                y: h * 0.05,
                width: w - 2 * maskInset,
                height: h * 0.90
            )
            let radius = maskRect.width / 2

            // Outer rectangle minus inner capsule → dim area
            let outer = Path(CGRect(origin: .zero, size: size))
            let inner = Path(roundedRect: maskRect, cornerRadius: radius)
            var dim = outer
            dim.addPath(inner)
            ctx.fill(dim, with: .color(.black.opacity(0.78)), style: FillStyle(eoFill: true))

            // Bright outline
            ctx.stroke(
                Path(roundedRect: maskRect, cornerRadius: radius),
                with: .color(.white.opacity(0.9)),
                lineWidth: 3
            )
        }
    }
}
