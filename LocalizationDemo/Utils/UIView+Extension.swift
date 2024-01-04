//
//  UIView + Extension.swift
//  HappySound
//
//  Created by Sun on 2023/1/29.
//

import UIKit
import SnapKit

// MARK: SnapKit Extensions
extension UIView {
    @discardableResult
    public func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> Self {
        self.snp.makeConstraints(closure)
        return self
    }
    
    @discardableResult
    public func remakeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> Self {
        self.snp.remakeConstraints(closure)
        return self
    }
    
    @discardableResult
    public func updateConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> Self {
        self.snp.updateConstraints(closure)
        return self
    }
    
    @discardableResult
    public func removeConstraints() -> Self {
        self.snp.removeConstraints()
        return self
    }
}
