import AppKit

// No "bucket" SF Symbol exists (checked against the system's SF Symbols
// catalog), so this draws one procedurally as a template image. Shared by
// the menu bar status item and the onboarding step that references it.
enum BucketIcon {
    private static let kappa: CGFloat = 0.5522847498

    private static var handlePath: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 7, y: 6))
        path.addCurve(
            to: CGPoint(x: 12, y: 1),
            control1: CGPoint(x: 7, y: 6 - 5 * kappa),
            control2: CGPoint(x: 12 - 5 * kappa, y: 1)
        )
        path.addCurve(
            to: CGPoint(x: 17, y: 6),
            control1: CGPoint(x: 12 + 5 * kappa, y: 1),
            control2: CGPoint(x: 17, y: 6 - 5 * kappa)
        )
        return path
    }

    private static var bodyPath: CGPath {
        let path = CGMutablePath()
        let rimLeft = CGPoint(x: 3, y: 6)
        let rimRight = CGPoint(x: 21, y: 6)
        path.move(to: rimLeft)
        path.addLine(to: rimRight)
        path.addArc(tangent1End: CGPoint(x: 18, y: 20), tangent2End: CGPoint(x: 6, y: 20), radius: 1.5)
        path.addArc(tangent1End: CGPoint(x: 6, y: 20), tangent2End: rimLeft, radius: 1.5)
        path.closeSubpath()
        return path
    }

    static func image(pointSize: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize), flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.saveGState()
            ctx.scaleBy(x: pointSize / 24, y: pointSize / 24)

            ctx.addPath(bodyPath)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath()

            ctx.addPath(handlePath)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(2.2)
            ctx.setLineCap(.round)
            ctx.strokePath()

            ctx.restoreGState()
            return true
        }
        image.isTemplate = true
        return image
    }
}
