//
//  VideoListViewModel.swift
//  CatchPlayFanLoop
//
//  Created by 王昱淇 on 2025/5/2.
//

import Foundation

// MARK: - VideoListViewModel
class VideoListViewModel {
    @Published private(set) var videos: [Video] = []
    
    func loadVideoData() {
        DispatchQueue.global().async {
            guard let url = Bundle.main.url(forResource: "video_data", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([Video].self, from: data) else {
                print("Failed to load video_data.json")
                return
            }
            
            DispatchQueue.main.async {
                self.videos = decoded
            }
        }
    }
    
    func video(at index: Int) -> Video? {
        guard index >= 0 && index < videos.count else { return nil }
        return videos[index]
    }
    
    var videoCount: Int {
        return videos.count
    }
}
