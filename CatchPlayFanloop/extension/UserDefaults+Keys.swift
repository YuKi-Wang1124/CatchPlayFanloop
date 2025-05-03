//
//  UserDefaults+Keys.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/2.
//

import Foundation

extension UserDefaults {
    enum Keys {
        static let muteSetting = "MuteSetting"
    }

    var isMuted: Bool {
        get { bool(forKey: Keys.muteSetting) }
        set { set(newValue, forKey: Keys.muteSetting) }
    }
}
