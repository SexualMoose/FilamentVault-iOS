import Foundation
import UIKit

enum ImageStorage {
    static let folderName = "filament_images"

    static var folderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true
        )
        return url
    }

    static func url(forFilename filename: String) -> URL {
        folderURL.appendingPathComponent(filename)
    }

    /// Save a UIImage as JPEG to the app's images folder. Returns the filename.
    static func save(_ image: UIImage, prefix: String = "filament") -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let filename = "\(prefix)_\(UUID().uuidString).jpg"
        let url = folderURL.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            print("ImageStorage save failed: \(error)")
            return nil
        }
    }

    static func delete(_ filename: String?) {
        guard let filename = filename else { return }
        try? FileManager.default.removeItem(at: url(forFilename: filename))
    }

    static func load(_ filename: String?) -> UIImage? {
        guard let filename = filename else { return nil }
        return UIImage(contentsOfFile: url(forFilename: filename).path)
    }
}
