import UIKit
@available(iOS 13.0, *)
final class RoundButton: UIButton {

    // MARK: Properties -

    var image = UIImage(systemName: "arrow.down.circle") {
        didSet {
            commonInit()
        }
    }

    // MARK: Initializers -

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: Helper methods -

    private func commonInit() {
       setImage(image, for: .normal)
       contentHorizontalAlignment = .fill
       contentVerticalAlignment = .fill
       imageView?.contentMode = .scaleAspectFit
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }

}
