//
//  MemoriesViewModel.swift
//  HappyDays
//
//  Created by Philipp on 09.08.20.
//

import Foundation
import UIKit

class MemoriesViewModel: ObservableObject {

    @Published var memories = [Memory]()

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func loadMemories() {
        var memories = [Memory]()

        let documentsDirectory = getDocumentsDirectory()
        print("documentsDirectory=\(documentsDirectory)")

        // attempt to load all the memories in our documents directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: documentsDirectory,
                                                                       includingPropertiesForKeys: nil, options: []) else {
            return
        }

        // loop over every file found
        for file in files {
            let filename = file.lastPathComponent

            // check it ends with ".thumb" so we don't count each memory more than once
            if filename.hasSuffix(".thumb") {
                // get the root name of the memory (i.e., without its path extension)
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")

                // create a full path from the memory
                let memoryPath = documentsDirectory.appendingPathComponent(noExtension)

                // add it to our array
                memories.append(Memory(baseUrl: memoryPath))
            }

        }
        memories.sort()
        self.memories = memories
    }

    func saveNewMemory(image: UIImage) {
        // create a unique name for this memory
        let memoryName = "memory-\(Date().timeIntervalSince1970)"

        // use the unique name to create filenames for the full-size image and the thumbnail
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"

        let documentsDirectory = getDocumentsDirectory()

        do {
            // create a URL where we can write the JPEG to
            let imagePath = documentsDirectory.appendingPathComponent(imageName)

            // convert the UIImage into a JPEG data object
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                // write that data to the URL we created
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }

            // create thumbnail here
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = documentsDirectory.appendingPathComponent(thumbnailName)
                if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
        } catch {
            print("Failed to save to disk.")
        }
    }

    private func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        // calculate how much we need to bring the width down to match our target size
        let scale = width / image.size.width

        // bring the height down by the same amount so that the aspect ratio is preserved
        let height = image.size.height * scale

        // create a new image context we can draw into
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)

        // draw the original image into the context
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))

        // pull out the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        // end the context so UIKit can clean up
        UIGraphicsEndImageContext()

        // send it back to the caller
        return newImage
    }
}
