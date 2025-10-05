import SwiftUI
import VisionKit

struct ContentView: View {
    @State private var showScanner = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("SnazzyScan")
                    .font(.largeTitle)
                    .bold()
                
                Text("Tap the button to scan a document")
                    .foregroundColor(.gray)
                
                Button {
                    showScanner = true
                } label: {
                    Label("Scan Document", systemImage: "camera")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("SnazzyScan")
            .sheet(isPresented: $showScanner) {
                DocumentScanner(scannedImages: $scannedImages)
            }
        }
    }
}

#Preview {
    ContentView()
}
