//
//  UICollectionView+Cell.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/3.
//

import Foundation
import UIKit

extension UICollectionView {
    func dequeueCell<T: UICollectionViewCell>(ofType type: T.Type, for indexPath: IndexPath) -> T? {
        return dequeueReusableCell(withReuseIdentifier: String(describing: type), for: indexPath) as? T
    }
}
