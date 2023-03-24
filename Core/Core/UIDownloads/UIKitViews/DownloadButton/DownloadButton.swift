import UIKit

@available(iOS 13.0, *)
public final class DownloadButton: UIView {

    // MARK: - States -

    public enum State {
        case idle
        case waiting
        case downloading
        case downloaded
    }

    // MARK: - Attributes , Colors and Fonts -

    public var mainTintColor: UIColor = .blue {
        didSet {
            idleButton.tintColor = mainTintColor
            waitingView.strokeColor = mainTintColor
            downloadingButton.mainTintColor = mainTintColor
            downloadedButton.tintColor = mainTintColor
        }
    }
    public var idleButtonImage: UIImage = UIImage(systemName: "arrow.down.circle")! {
        didSet {
            self.idleButton.setImage(idleButtonImage, for: .normal)
        }
    }
    public var downloadedButtonImage: UIImage = UIImage(systemName: "trash.circle")! {
        didSet {
            self.idleButton.setImage(idleButtonImage, for: .normal)
        }
    }
    public var progress: Float = 0 {
        didSet {
            downloadingButton.progress = progress
        }
    }
    public var animationDuration  = 0.3
    public var currentState: State = .idle {
        didSet {
            // MARK: - Current State Changed
            let delay: TimeInterval = 0

            animationQueue.async { [self] in
                animationDispatchGroup.enter()
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.transition(from: oldValue, to: self.currentState)
                }
                animationDispatchGroup.wait()
            }
            onState?(currentState)
        }
    }
    var onState: ((State) -> Void)?

    // MARK: - Private Properties -

    let idleButton: RoundButton = RoundButton()
    let waitingView: WaitingView = WaitingView()
    let downloadingButton: ProgressButton = ProgressButton()
    let downloadedButton: RoundButton = RoundButton()

    // MARK: - CallBacks -

    public var onTap: ((State) -> Void)?
    let animationDispatchGroup = DispatchGroup()
    let animationQueue = DispatchQueue(label: "MUDownloadButtonAnimationQueue")

    // MARK: - Inits -

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        addSubview(idleButton)
        setIdleButtonConstraints()
        idleButton.image = idleButtonImage
        idleButton.tintColor = mainTintColor
        idleButton.addTarget(self, action: #selector(currentButtonTapped), for: .touchUpInside)

        addSubview(waitingView)
        setWaitingButtonConstraints()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(currentButtonTapped))
        waitingView.addGestureRecognizer(tapGesture)
        waitingView.strokeColor = mainTintColor

        addSubview(downloadingButton)
        setDownloadingButtonConstraints()
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(currentButtonTapped))
        downloadingButton.addGestureRecognizer(tapGesture2)
        progress = 0
        downloadingButton.mainTintColor = mainTintColor

        addSubview(downloadedButton)
        setDownloadedButtonConstraints()
        downloadedButton.image = downloadedButtonImage
        downloadedButton.tintColor = mainTintColor
        downloadedButton.addTarget(self, action: #selector(currentButtonTapped), for: .touchUpInside)
    }

    // MARK: - Setup Constraitns -

    private func setIdleButtonConstraints() {
        idleButton.pinToSuperview()
    }

    private func setWaitingButtonConstraints() {
        waitingView.pinToSuperview(constant: 2)
    }

    private func setDownloadingButtonConstraints() {
        downloadingButton.pinToSuperview()
    }

    private func setDownloadedButtonConstraints() {
        downloadedButton.pinToSuperview()
    }

    // MARK: - Actions -

    @objc private func currentButtonTapped(_ sender: UITapGestureRecognizer? = nil) {
        print("tap0ped")
        onTap?(currentState)
    }
}
