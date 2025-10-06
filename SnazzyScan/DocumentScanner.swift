//
//  DocumentScanner.swift
//  SnazzyScan
//
//  Created by Michael Fluharty on 10/5/25.
//

import SwiftUI
import VisionKit
import PDFKit
import QuickLook

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
            print("📸 Scan completed with \(scan.pageCount) pages")
            
            // Get all scanned pages
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                images.append(image)
                print("✅ Extracted page \(pageIndex + 1): \(image.size)")
            }
            
            print("📦 Total images collected: \(images.count)")
            parent.scannedImages = images
            
            // Create PDF and show share sheet
            print("🔨 Creating PDF from \(images.count) images...")
            if let pdfURL = createPDF(from: images) {
                print("✅ PDF created successfully at: \(pdfURL.path)")
                showShareSheet(url: pdfURL, from: controller)
            } else {
                print("❌ FAILED to create PDF")
                parent.dismiss()
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scan failed: \(error.localizedDescription)")
            parent.dismiss()
        }
        
        func createPDF(from images: [UIImage]) -> URL? {
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
            
            // Save to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)
            
            if let data = pdfDocument.dataRepresentation() {
                do {
                    try data.write(to: fileURL)
                    print("PDF created: \(fileURL.path)")
                    return fileURL
                } catch {
                    print("Error creating PDF: \(error.localizedDescription)")
                    return nil
                }
            }
            
            return nil
        }
        
        func showShareSheet(url: URL, from viewController: UIViewController) {
            print("📤 Presenting share sheet")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let activityVC = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                
                // For iPad: required to set popover source
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = viewController.view
                    popover.sourceRect = CGRect(
                        x: viewController.view.bounds.midX,
                        y: viewController.view.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    popover.permittedArrowDirections = []
                }
                
                // When share sheet is dismissed, dismiss scanner too
                activityVC.completionWithItemsHandler = { _, _, _, _ in
                    print("📤 Share sheet dismissed")
                    viewController.dismiss(animated: true)
                }
                
                print("✅ Presenting share sheet from scanner")
                viewController.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - QuickLook Preview Support

class PDFPreviewDataSource: NSObject, QLPreviewControllerDataSource {
    let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
}

class PDFPreviewDelegate: NSObject, QLPreviewControllerDelegate {
    var parent: DocumentScanner
    weak var scannerVC: UIViewController?
    
    init(parent: DocumentScanner, scannerVC: UIViewController) {
        self.parent = parent
        self.scannerVC = scannerVC
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        print("📱 QuickLook dismissed, now dismissing scanner")
        // When user closes PDF preview, dismiss the scanner too
        scannerVC?.dismiss(animated: true)
    }
}
