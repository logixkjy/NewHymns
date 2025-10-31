//
//  ZoomableImage.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/14/25.
//

import SwiftUI
import UIKit

struct ZoomableImage: UIViewRepresentable {
    let image: UIImage
    let containerSize: CGSize
    let topAligned: Bool = false
    
    func makeCoordinator() -> Coordinator {
        Coordinator(topAligned: topAligned)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.bouncesZoom = false
        scroll.bounces = false
        scroll.backgroundColor = .clear
        scroll.decelerationRate = .fast
        scroll.contentInsetAdjustmentBehavior = .never
        
        let iv = context.coordinator.imageView
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = true
        
        scroll.addSubview(iv)
        
        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)
        
        context.coordinator.scrollView = scroll
        context.coordinator.startOrientationNotifications()
        
        return scroll
    }
    
    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.replaceImage(image, in: scroll)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        var imageView = UIImageView()
        private(set) var minScale: CGFloat = 1.0
        private(set) var maxScale: CGFloat = 1.0
        private var didInit = false
        private var topAligned: Bool
        
        private var isGenerating = false
        
        init(topAligned: Bool) {
            self.topAligned = topAligned
        }
        
        deinit {
            stopOrientationNotifications()
        }
        
        func startOrientationNotifications() {
            guard !isGenerating else { return }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleOrientationChange),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
            isGenerating = true
        }
        
        func stopOrientationNotifications() {
            if isGenerating {
                NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
                isGenerating = false
            }
        }
        
        @objc private func handleOrientationChange() {
            // 기기 방향 노티는 UI 회전과 정확히 일치하지 않을 수 있으니,
            // 다음 런루프(혹은 한 프레임 뒤)에 재계산하여 레이아웃이 안정된 뒤 처리
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let scroll = self.scrollView, let img = imageView.image else { return }
                
                let height = (scroll.bounds.size.width * img.size.height) / img.size.width
                imageView.frame = CGRect(origin: .zero, size: CGSize(width: scroll.bounds.size.width, height: height))
                scroll.contentSize = imageView.bounds.size
                
                self.configureZoomAfterLayout(scroll: scroll)
            }
        }
        
        private func fixedOrientation(_ image: UIImage) -> UIImage {
            guard image.imageOrientation != .up else { return image }
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let normalized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return normalized ?? image
        }
        
        func replaceImage(_ newImage: UIImage, in scroll: UIScrollView) {
            guard scroll.bounds.width > 0, scroll.bounds.height > 0 else {
                DispatchQueue.main.async { [weak self, weak scroll] in
                    guard let self, let scroll = scroll else { return }
                    self.replaceImage(newImage, in: scroll)
                }
                return
            }
            
            let img = fixedOrientation(newImage)
            
            imageView.image = img
            imageView.translatesAutoresizingMaskIntoConstraints = true
            let height = (scroll.bounds.size.width * img.size.height) / img.size.width
            imageView.frame = CGRect(origin: .zero, size: CGSize(width: scroll.bounds.size.width, height: height))
            scroll.contentSize = imageView.bounds.size
            
            DispatchQueue.main.async { [weak self, weak scroll] in
                guard let self, let scroll = scroll else { return }
                self.configureZoomAfterLayout(scroll: scroll)
            }
        }
        
        private func configureZoomAfterLayout(scroll: UIScrollView) {
            guard scroll.bounds.width > 0, scroll.bounds.height > 0 else {
                DispatchQueue.main.async { [weak self, weak scroll] in
                    guard let self, let scroll = scroll else { return }
                    self.configureZoomAfterLayout(scroll: scroll)
                }
                return
            }
            
            // 3) "줌 기준"은 항상 imageView.bounds (pt)
            let bounds = scroll.bounds.size
            let base   = imageView.bounds.size
            guard base.width > 0, base.height > 0 else { return }
            
            let xScale = bounds.width / base.width
            let yScale = bounds.height / base.height
            let yScale2 = max((bounds.height / base.height), 0.85)
            let newMin = (xScale > yScale) ? yScale : xScale
            let newMax = 2.0
            let viewZoom = (xScale > yScale2) ? yScale2 : xScale
//            print("testLog bounds \(bounds), base \(base)")
//            print("testLog min \(newMin), max \(newMax), view \(viewZoom)")
            
            scroll.minimumZoomScale = newMin
            scroll.maximumZoomScale = newMax
            minScale = newMin
            maxScale = newMax
            
            // 화면 맞춤
            scroll.setZoomScale(1, animated: false)
            centerOrTopAlign(scroll: scroll)
            didInit = true
        }
        
        @objc func handleDoubleTap(_ gr: UITapGestureRecognizer) {
            guard let scroll = gr.view as? UIScrollView else { return }
            let point = gr.location(in: imageView)
            if abs(scroll.zoomScale - minScale) < 0.001 {
                let target = min(scroll.zoomScale * 3, maxScale)
                let w = scroll.bounds.width / target
                let h = scroll.bounds.height / target
                let rect = CGRect(x: point.x - w/2, y: point.y - h/2, width: w, height: h)
                scroll.zoom(to: rect, animated: true)
            } else {
                scroll.setZoomScale(minScale, animated: true)
                centerOrTopAlign(scroll: scroll)
            }
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let bounds = scrollView.bounds.size
            let base   = imageView.bounds.size
            
            let contentW = base.width  * scrollView.zoomScale
            let contentH = base.height * scrollView.zoomScale
            
            var topInset = UIDevice.current.userInterfaceIdiom == .pad ? (bounds.height - contentH) * 0.5 : 0
            var sideInset = (bounds.width - contentW) * 0.5
            if topInset < 0.0 { topInset = 0.0 }
            if sideInset < 0.0 { sideInset = 0.0}
            
            let inset = UIEdgeInsets(top: 0, left: sideInset, bottom: -topInset, right: -sideInset)
            scrollView.contentInset = inset
        }
        
        func centerOrTopAlign(scroll: UIScrollView) {
            let bounds = scroll.bounds.size
            let base   = imageView.bounds.size
            
            let contentW = base.width  * scroll.zoomScale
            let contentH = base.height * scroll.zoomScale
            
            var topInset = UIDevice.current.userInterfaceIdiom == .pad ? (bounds.height - contentH) * 0.5 : 0
            var sideInset = (bounds.width - contentW) * 0.5
            if topInset < 0.0 { topInset = 0.0 }
            if sideInset < 0.0 { sideInset = 0.0}
            
            let inset = UIEdgeInsets(top: 0, left: sideInset, bottom: -topInset, right: -sideInset)
            scroll.contentInset = inset
            scroll.scrollIndicatorInsets = inset
            
            let target = CGPoint(x: -inset.left, y: -inset.top)
            if scroll.contentOffset != target {
                scroll.setContentOffset(target, animated: false)
            }
        }
    }
}
