//
//  CatchPlayFanloopTests.swift
//  CatchPlayFanloopTests
//
//  Created by 王昱淇 on 2025/4/29.
//

import Testing
import XCTest
@testable import CatchPlayFanLoop

final class VideoCellVisibilityHelperTests: XCTestCase {

    func testFindMostVisibleCell_indexPathWithLargestVisibleAreaIsReturned() {
        // Given
        let visibleArea = CGRect(x: 0, y: 0, width: 320, height: 568)

        let frames: [(IndexPath, CGRect)] = [
            (IndexPath(item: 0, section: 0), CGRect(x: 0, y: 0, width: 320, height: 200)),   // fully visible
            (IndexPath(item: 1, section: 0), CGRect(x: 0, y: 200, width: 320, height: 400)), // partially visible
            (IndexPath(item: 2, section: 0), CGRect(x: 0, y: 600, width: 320, height: 300))  // not visible
        ]

        // When
        let result = VideoCellVisibilityHelper.findMostVisibleCell(from: frames, in: visibleArea)

        // Then
        XCTAssertEqual(result, IndexPath(item: 1, section: 0)) // item 1 has the largest visible area (368)
    }

    func testFindMostVisibleCell_returnsNilWhenNoVisibleCell() {
        // Given
        let visibleArea = CGRect(x: 0, y: 0, width: 320, height: 568)
        let frames: [(IndexPath, CGRect)] = [
            (IndexPath(item: 0, section: 0), CGRect(x: 0, y: 600, width: 320, height: 200))
        ]

        // When
        let result = VideoCellVisibilityHelper.findMostVisibleCell(from: frames, in: visibleArea)

        // Then
        XCTAssertNil(result)
    }
}

struct VideoCellVisibilityHelper {
    static func findMostVisibleCell(from frames: [(IndexPath, CGRect)], in visibleArea: CGRect) -> IndexPath? {
        var maxVisibleHeight: CGFloat = 0
        var targetIndexPath: IndexPath?

        for (indexPath, frame) in frames {
            let intersection = visibleArea.intersection(frame)
            let visibleHeight = intersection.height

            if visibleHeight > maxVisibleHeight {
                maxVisibleHeight = visibleHeight
                targetIndexPath = indexPath
            }
        }

        return targetIndexPath
    }
}
