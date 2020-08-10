//
//  MemoriesViewModel.swift
//  HappyDays
//
//  Created by Philipp on 09.08.20.
//

import Foundation
import UIKit
import os.log
import AVFoundation
import Speech
import CoreSpotlight
import MobileCoreServices

class MemoriesViewModel: NSObject, ObservableObject {

    let logger = Logger(subsystem: "MemoriesViewModel", category: "General")

    @Published var memories = [Memory]()

    @Published var filteredMemories = [Memory]()
    @Published var isSearching: Bool = false
    @Published var searchText: String = ""

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func loadMemories() {
        logger.debug("loadMemories")
        var memories = [Memory]()

        let documentsDirectory = getDocumentsDirectory()

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
        self.filteredMemories = memories
    }

    func saveNewMemory(image: UIImage) {
        logger.debug("saveNewMemory")
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
            logger.error("Failed to save to disk.")
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

    @Published private(set) var activeMemory: Memory?

    var isRecording: Bool {
        activeMemory != nil
    }

    func isRecording(_ memory: Memory) -> Bool {
        activeMemory == memory
    }

    private var audioRecorder: AVAudioRecorder?
    private lazy var recordingURL: URL = {
        getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }()

    func record(memory: Memory) {
        guard activeMemory == nil else {
            logger.warning("Called record without activeMemory set")
            return
        }

        audioPlayer?.stop()

        // 1: the easy bit!

        // remember current memory for which we are recording
        activeMemory = memory

        // this just saves me writing AVAudioSession.sharedInstance() everywhere
        let recordingSession = AVAudioSession.sharedInstance()

        do {
            // 2. configure the session for recording and playback through the speaker
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true)

            // 3. set up a high-quality recording session
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // 4. create the audio recording, and assign ourselves as the delegate
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            // failed to record!
            logger.error("Failed to record: \(error.localizedDescription)")
            finishRecording(success: false)
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder?.stop()

        if success, let memory = activeMemory {
            do {
                let memoryAudioURL = memory.audioURL
                let fm = FileManager.default

                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }

                try fm.moveItem(at: recordingURL, to: memoryAudioURL)

                transcribeAudio(memory: memory)
            } catch let error {
                logger.error("Failure finishing recording: \(error.localizedDescription)")
            }
        }

        activeMemory = nil
    }

    private func transcribeAudio(memory: Memory) {
        // get paths to where the audio is, and where the transcription should be
        let audio = memory.audioURL
        let transcription = memory.transcriptionURL

        // create a new recognizer and point it at our audio
        print("Locale.current=\(Locale.current.languageCode)")
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                logger.error("Failed recognitionTask: error = \(error!.localizedDescription)")
                return
            }

            // if we got the final transcription back, we need to write it to disk
            if result.isFinal {
                // pull out the best transcription...
                let text = result.bestTranscription.formattedString

                // ...and write it to disk at the correct filename for this memory.
                do {
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    self.index(memory: memory, text: text)
                } catch {
                    logger.error("Failed to save transcription: \(error.localizedDescription)")
                }
            }
        }
    }

    private func index(memory: Memory, text: String) {
        logger.debug("index")
        // create a basic attribute set
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = memory.thumbnailURL

        // wrap it in a searchable item, using the memory's full path as its unique identifier
        let item = CSSearchableItem(uniqueIdentifier: memory.baseUrl.lastPathComponent, domainIdentifier: "com.hackingwithswift", attributeSet: attributeSet)

        // make it never expire
        item.expirationDate = Date.distantFuture

        // ask Spotlight to index the item
        CSSearchableIndex.default().indexSearchableItems([item]) { [weak self] error in
            if let error = error {
                self?.logger.error("Indexing error: \(error.localizedDescription)")
            } else {
                self?.logger.debug("Search item successfully indexed: \(text)")
            }
        }
    }

    private var audioPlayer: AVAudioPlayer?

    func playAudio(for memory: Memory) {
        let fm = FileManager.default

        do {
            let audioName = memory.audioURL
            let transcriptionName = memory.transcriptionURL

            if fm.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }

            if fm.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                logger.log("transcription=\(contents)")
                print(contents)
            }
        } catch {
            logger.error("Error loading audio: \(error.localizedDescription)")
        }
    }


    var searchQuery: CSSearchQuery?

    func filterMemories(text: String) {
        guard text.count > 0 else {
            filteredMemories = memories
            return
        }

        var allItems = [CSSearchableItem]()

        searchQuery?.cancel()

        let queryString = "contentDescription == \"*\(text)*\"c"
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)

        searchQuery?.foundItemsHandler = { items in
            allItems.append(contentsOf: items)
        }

        searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allItems)
            }
        }

        searchQuery?.start()
    }

    func activateFilter(matches: [CSSearchableItem]) {
        filteredMemories = matches.map { item in
            Memory(baseUrl: getDocumentsDirectory().appendingPathComponent(item.uniqueIdentifier))
        }
    }
}

extension MemoriesViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            logger.warning("audioRecorderDidFinishRecording: flag=\(flag)")
            finishRecording(success: false)
        }
    }
}
