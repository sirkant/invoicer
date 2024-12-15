import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfURL: URL

    var body: some View {
        PDFKitView(url: pdfURL)
            .navigationTitle("Invoice Preview")
            .navigationBarTitleDisplayMode(.inline)
    }
}