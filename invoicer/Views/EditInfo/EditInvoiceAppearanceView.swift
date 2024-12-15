import SwiftUI
import SwiftData

struct EditInvoiceAppearanceView: View {
    @Environment(\.modelContext) private var context
    @Query var companyInfos: [CompanyInfo]

    @State private var fontName = "Helvetica"
    @State private var fontSize = 12

    let availableFonts = ["Helvetica", "Times New Roman", "Courier New", "Avenir"]

    var body: some View {
        Form {
            Section(header: Text("Font")) {
                Picker("Font Name", selection: $fontName) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                Stepper("Font Size: \(fontSize)", value: $fontSize, in: 8...36)
            }
        }
        .onAppear {
            if let company = companyInfos.first {
                fontName = company.fontName
                fontSize = company.fontSize
            }
        }
        .onDisappear {
            if let company = companyInfos.first {
                company.fontName = fontName
                company.fontSize = fontSize
                try? context.save()
            } else {
                let company = CompanyInfo(fontName: fontName, fontSize: fontSize)
                context.insert(company)
                try? context.save()
            }
        }
        .navigationTitle("Invoice Appearance")
    }
}