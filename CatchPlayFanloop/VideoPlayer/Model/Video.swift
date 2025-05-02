//
//  Video.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/2.
//

import Foundation

// MARK: - Video
struct Video: Codable {
    let id: Int
    let filename: String
    let title: String
    let description: String
    let hashId: String
    
    var url: URL? {
        Bundle.main.url(forResource: filename.replacingOccurrences(of: ".mp4", with: ""), withExtension: "mp4")
    }
}
