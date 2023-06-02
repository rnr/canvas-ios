import SwiftUI
import WebKit

public struct SUWebViewRepresentable: UIViewRepresentable {

    var configurator: WebViewConfigurator
    var isToolbarVisible: Bool = false

    @Binding var onLoaded: Bool

    public func makeUIView(context: Self.Context) -> SUToolbarWebView {
        let webView = SUToolbarWebView(
            frame: .zero,
            configuration: configurator.webViewConfiguration,
            isToolbarVisible: isToolbarVisible
        )
        webView.webView.navigationDelegate = context.coordinator
        webView.webView.uiDelegate = context.coordinator
        return webView
    }

    public func updateUIView(
        _ uiView: SUToolbarWebView,
        context: Self.Context
    ) {
        switch configurator.requestType {
        case .url(let url):
            guard url.path != context.coordinator.previousURL?.path else { return }
            context.coordinator.previousURL = url
            let request = URLRequest(url: url)
            uiView.webView.load(request)
        case let .indexURL(url, allowingReadAccessTo):
            guard url.path != context.coordinator.previousURL?.path else { return }
            context.coordinator.previousURL = url
            let request = URLRequest(url: url)
            uiView.webView.load(request)
            uiView.webView.loadFileURL(url, allowingReadAccessTo: allowingReadAccessTo)
        case .request(let request):
            guard request.url?.path != context.coordinator.previousRequest?.url?.path else { return }
            context.coordinator.previousRequest = request
            uiView.webView.load(request)
        }
    }

    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.onLoaded = { onLoaded in
            self.onLoaded = onLoaded
        }
        return coordinator
    }
}

extension SUWebViewRepresentable {
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        typealias LoadedClouser = ((Bool) -> Void)

        var previousRequest: URLRequest?
        var previousURL: URL?
        var onLoaded: LoadedClouser?

        public func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation,
            withError error: Error
        ) {
            onLoaded?(true)
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
            webView.evaluateJavaScript("document.readyState") { [weak self] result, _ in
                guard let self = self else { return }
                guard let result = result as? String, result == "complete" else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.webView(webView, didFinish: navigation)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.onLoaded?(true)
                }
            }
        }
    }
}
