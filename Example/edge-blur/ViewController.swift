//
//  ViewController.swift
//  edge-blur
//
//  Created by Gary Tokman on 10/02/2025.
//  Copyright (c) 2025 Gary Tokman. All rights reserved.
//

import UIKit
import edge_blur
import SwiftUI

class ViewController: UIViewController {
    private var hosting: UIHostingController<PreviewView>?


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        hosting = view.embedHosting(PreviewView())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


extension UIView {
    @discardableResult
    func embedHosting<Content: View>(_ rootView: Content) -> UIHostingController<Content> {
        let hc = UIHostingController(rootView: rootView)
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        hc.view.backgroundColor = .clear
        addSubview(hc.view)
        hc.view.setContentHuggingPriority(.required, for: .horizontal)
        hc.view.setContentHuggingPriority(.required, for: .vertical)
        hc.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        hc.view.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        return hc
    }
}
