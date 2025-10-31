//
//  HTMLWebView.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/2/25.
//

// Views/HTMLWebView.swift
import SwiftUI
import WebKit

struct HTMLWebView: UIViewRepresentable {
    let html: String
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = false
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = true   // 자체 스크롤
        return web
    }
    
    func updateUIView(_ web: WKWebView, context: Context) {
        // 같은 HTML을 계속 로드해 깜빡임/루프가 생기지 않게 간단 캐시
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            web.loadHTMLString(html, baseURL: nil)
        }
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow); return
            }
            
            // 우리가 올린 HTML (about:blank) 및 동일 문서 내 앵커 이동 등은 허용
            if url.scheme == "about" || url.scheme == "data" {
                decisionHandler(.allow); return
            }
            
            // http/https 외부 링크는 막거나, 외부로 여는 로직으로 분기
            if url.scheme == "http" || url.scheme == "https" {
                // 외부로 열고 웹뷰 내 탐색은 막기
                decisionHandler(.cancel)
                // UIApplication.shared.open(url) // 필요 시 외부로 열기
                return
            }
            
            // 전화/메일 등의 스키마는 취향에 맞게 처리
            decisionHandler(.cancel)
        }
    }
}
