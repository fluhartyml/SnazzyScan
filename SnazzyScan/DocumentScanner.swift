//
//  DocumentScanner.swift
//  SnazzyScan
//
//  Created by Michael Fluharty on 10/5/25.
//

import SwiftUI
import VisionKit
import PDFKit

struct DocumentScanner: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScanner
        
        init(_ parent: DocumentScanner) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Get all scanned pages
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                parent.scannedImages.append(image)
            }
            
            // Save to Files app
            savePDFToFiles(images: parent.scannedImages)
            
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scan failed: \(error.localizedDescription)")
            parent.dismiss()
        }
        
        func savePDFToFiles(images: [UIImage]) {
            let pdfDocument = PDFDocument()
            
            for (index, image) in images.enumerated() {
                if let pdfPage = PDFPage(image: image) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            // Create filename with timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let filename = "Scan_\(timestamp).pdf"
            
            // Get iCloud Drive URL
            if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                let snazzyScanFolder = iCloudURL.appendingPathComponent("SnazzyScan")
                
                // Create SnazzyScan folder if it doesn't exist
                try? FileManager.default.createDirectory(at: snazzyScanFolder, withIntermediateDirectories: true)
                
                let fileURL = snazzyScanFolder.appendingPathComponent(filename)
                
                if let data = pdfDocument.dataRepresentation() {
                    do {
                        try data.write(to: fileURL)
                        print("PDF saved to iCloud Drive: \(fileURL.path)")
                    } catch {
                        print("Error saving PDF: \(error.localizedDescription)")
                    }
                }
            } else {
                print("iCloud Drive not available")
            }
        }
    }
}
