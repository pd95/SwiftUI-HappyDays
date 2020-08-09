//
//  Memory.swift
//  HappyDays
//
//  Created by Philipp on 09.08.20.
//

import Foundation

struct Memory {
    let baseUrl: URL

    var imageURL: URL {
        baseUrl.appendingPathExtension("jpg")
    }

    var thumbnailURL: URL {
        baseUrl.appendingPathExtension("thumb")
    }

    var audioURL: URL {
        baseUrl.appendingPathExtension("m4a")
    }

    var transcriptionURL: URL {
        baseUrl.appendingPathExtension("txt")
    }
}

extension Memory: Comparable {
    static func < (lhs: Memory, rhs: Memory) -> Bool {
        lhs.baseUrl.path < rhs.baseUrl.path
    }
}
