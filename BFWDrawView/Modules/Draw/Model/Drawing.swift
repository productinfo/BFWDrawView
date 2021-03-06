//
//  BFWStyleKitDrawing.swift
//  BFWDrawView
//
//  Created by Tom Brodhurst-Hill on 19/07/2015.
//  Free to use at your own risk, with acknowledgement to BareFeetWare.
//

import Foundation

open class Drawing {

    internal struct FileName {
        static let drawPrefix = "draw"
    }

    open var styleKit: StyleKit
    open var name: String
    fileprivate var didSetDrawnSize = false

    fileprivate enum Key: String {
        case sizes, sizesByPrefix
    }
    
    // MARK: - Init

    init(styleKit: StyleKit, name: String) {
        self.styleKit = styleKit
        self.name = name
    }
    
    // MARK: Variables

    internal lazy var methodName: String? = {
        return self.styleKit.classMethodName(forDrawingName: self.name)
    }()

    lazy var methodParameters: [String] = {
        let methodParameters: [String]
        if let methodNameComponents = self.methodName?.methodNameComponents,
            methodNameComponents.count > 1
        {
            methodParameters = Array(methodNameComponents.suffix(from: 1)) 
        } else {
            methodParameters = []
            debugPrint("found no method parameters for drawing \"\(self.name)\"")
        }
        return methodParameters
    }()
    
    lazy var lookupName: String = {
        return self.name.lowercasedWords
    }()

    lazy var drawnSize: CGSize? = {
        let parameterDict = self.styleKit.parameterDict
        let sizeString: String?
        if let sizesDict = parameterDict[Key.sizes.rawValue] as? [String: Any],
            let matchedSizeString = sizesDict.object(forWordsKey: self.lookupName) as? String
        {
            sizeString = matchedSizeString
        } else if let sizesDict = parameterDict[Key.sizesByPrefix.rawValue] as? [String: Any] {
            sizeString = sizesDict.object(forLongestPrefixKeyMatchingWordsIn: self.lookupName) as? String
        } else {
            sizeString = nil
        }
        return sizeString.flatMap { NSCoder.cgSize(for: $0) }
    }()

    var intrinsicFrame: CGRect? {
        guard let drawnSize = drawnSize
            else { return nil }
        return CGRect(origin: CGPoint.zero, size: drawnSize)
    }

}
