import UIKit

@available(iOS 13.0, *)
extension DownloadButton {
    
    func transition(from currentState: State, to nextState: State) {
        let trasitionCompletionHandler: (Bool) -> Void = { _ in
            self.animationDispatchGroup.leave()
            self.resetOtherViews(currentState: nextState)
        }
        switch (currentState, nextState) {
        case (.idle, .waiting):
            handleTransitionFromIdleToWaiting(completionHandler: trasitionCompletionHandler)
        case (.idle, .downloading):
            handleTransitionFromIdleToDownloading(completionHandler: trasitionCompletionHandler)
        case (.waiting, .idle):
            handleTransitionFromWaitingToIdle(completionHandler: trasitionCompletionHandler)
        case (.waiting, .downloading):
            handleTransitionFromWaitingToDownloading(completionHandler: trasitionCompletionHandler)
        case (.downloading, .downloaded):
            handleTransitionFromDownloadingToDownloaded(completionHandler: trasitionCompletionHandler)
        case (.downloading, .idle):
            handleTransitionFromDownloadingToIdle(completionHandler: trasitionCompletionHandler)
        default:
            self.handleUnknownTransition(state: nextState, completionHandler: trasitionCompletionHandler)
        }
    }

    // MARK: - Transition Functions -

    func handleTransitionFromIdleToWaiting(completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            self.idleButton.alpha = 0
        } completion: { completed in
            completionHandler(completed)
            self.waitingView.alpha = 1
        }
    }

    func handleTransitionFromIdleToDownloading(completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            self.idleButton.alpha = 0
        } completion: { completed in
            completionHandler(completed)
            self.downloadingButton.alpha = 1
        }
    }

    func handleTransitionFromWaitingToIdle(completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            self.waitingView.alpha = 0
        } completion: { completed in
            completionHandler(completed)
            self.idleButton.alpha = 1
        }
    }

    func handleTransitionFromWaitingToDownloading(completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            self.waitingView.alpha = 0
        } completion: { completed in
            completionHandler(completed)
            self.downloadingButton.alpha = 1
        }
    }

    func handleTransitionFromDownloadingToDownloaded(completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            self.downloadingButton.alpha = 0
        } completion: { completed in
            completionHandler(completed)
            self.downloadedButton.alpha = 1
        }
    }

    func handleTransitionFromDownloadingToIdle(completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            self.downloadingButton.alpha = 0
        } completion: { completed in
            completionHandler(completed)
            self.idleButton.alpha = 1
        }
    }

    func handleUnknownTransition(state: State, completionHandler: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animationDuration) {
            switch state {
            case .idle:
                self.idleButton.alpha = 1
            case .waiting:
                self.waitingView.alpha = 1
            case .downloading:
                self.downloadingButton.alpha = 1
            case .downloaded:
                self.downloadedButton.alpha = 1
            }
        }
        completionHandler(true)
    }

    // MARK: - Reset Other Views -

    func resetOtherViews(currentState: State) {
        if currentState != .idle {
            self.idleButton.alpha = 0
        }
        if currentState != .waiting {
            self.waitingView.alpha = 0
        }
        if currentState != .downloading {
            self.downloadingButton.alpha = 0
        }
        if currentState != .downloaded {
            self.downloadedButton.alpha = 0
        }
    }
}
