//
//  DrawingTabBarItem.swift
//  BFWDrawView
//
//  Created by Tom Brodhurst-Hill on 5/7/17.
//  Copyright © 2017 BareFeetWare. All rights reserved.
//  Free to use at your own risk, with acknowledgement to BareFeetWare.
//

import UIKit

@IBDesignable class DrawingTabBarItem: UITabBarItem {
    
    @IBInspectable var drawingName: String? { didSet { updateImage() }}
    @IBInspectable var styleKit: String? { didSet { updateImage() }}
    
    var defaultSize = CGSize(width: 32, height: 32)
    
    private func updateImage() {
        if let drawingImage = UIImage.image(styleKitName: styleKit,
                                            drawingName: drawingName,
                                            size: defaultSize)
        {
            // TODO: Maybe delay creating the image until image get, so it's not possibly created twice for each change to drawingName and styleKitName.
            image = drawingImage
        }
    }
    
}
