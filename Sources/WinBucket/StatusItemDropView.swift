import AppKit

// ponytail: NSStatusItem.button can't be subclassed, so a custom NSView (via
// the deprecated-but-functional NSStatusItem.view) is the only way to get
// draggingEntered/Exited callbacks on the menu bar icon itself. Migrate if
// Apple ever ships a supported drag-callback API for NSStatusItem.button.
final class StatusItemDropView: NSView {
    private let imageView = NSImageView()
    private var hoverTimer: Timer?

    var onClick: (() -> Void)?
    var onRightClick: ((NSEvent) -> Void)?
    var onHoverOpen: (() -> Void)?
    var onDirectDrop: ((URL) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageView.frame = frameRect.insetBy(dx: 4, dy: 4)
        imageView.autoresizingMask = [.width, .height]
        let icon = BucketIcon.image(pointSize: 18)
        icon.accessibilityDescription = "Win Bucket"
        imageView.image = icon
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.contentTintColor = .labelColor
        addSubview(imageView)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(event)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        hoverTimer?.invalidate()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onHoverOpen?()
            }
        }
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        hoverTimer?.invalidate()
        hoverTimer = nil

        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
              let url = urls.first else {
            onHoverOpen?()
            return false
        }
        onDirectDrop?(url)
        return true
    }
}
