//
//  RotationGuardController.swift
//  OldHymns
//
//  Created by JooYoung Kim on 10/25/25.
//

import UIKit

final class RotationGuardController: UIViewController {
    var mask: UIInterfaceOrientationMask = .all
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { mask }
    override var shouldAutorotate: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        modalPresentationStyle = .overFullScreen
        definesPresentationContext = true
    }

    func applyUpdate() {
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
