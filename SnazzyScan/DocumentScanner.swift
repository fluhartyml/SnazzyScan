//  DocumentScanner.swift
//  SnazzyScan
//
//  Created by Michael Fluharty on 2025-10-05 19:05
//

import SwiftUI
import VisionKit
import PDFKit

struct DocumentScanner: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        init(_ parent: DocumentScanner) { self.parent = parent }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scan failed: \(error.localizedDescription)")
            parent.dismiss()
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            for i in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: i))
            }
            savePDFToICloud(images: scannedImages)
            parent.dismiss()
        }
        func savePDFToICloud(images: [UIImage]) {
            let pdf = PDFDocument()
            for (index, image) in images.enumerated() {
                if let page = PDFPage(image: image) {
                    pdf.insert(page, at: index)
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let filename = "Scan_\(timestamp).pdf"
            let containerID = "iCloud.com.inkwell.SnazzyScan"
            DispatchQueue.global(qos: .utility).async {
                guard let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
                    print("[ERROR] iCloud container URL is nil. PDF not saved.")
                    return
                }
                let docsFolder = icloudURL.appendingPathComponent("Documents")
                let destFolder = docsFolder.appendingPathComponent("SnazzyScan")
                do {
                    try FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true, attributes: nil)
                    let fileURL = destFolder.appendingPathComponent(filename)
                    if let data = pdf.dataRepresentation() {
                        try data.write(to: fileURL, options: .atomic)
                        print("SUCCESS: PDF saved to iCloud Drive at: \(fileURL.path)")
                    }
                } catch {
                    print("[ERROR] Failed to save PDF: \(error.localizedDescription)")
                }
            }
        }
    }
}
