import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    let invoice: Invoice
    @State private var pdfURL: URL?
    @State private var showPDFPreview = false
    @State private var showMailSheet = false
    @Query var companyInfos: [CompanyInfo]

    var body: some View {
        VStack(spacing: 20) {
            Text("Invoice \(invoice.invoiceNumber)")
                .font(.title)
                .fontWeight(.bold)
            Text("Customer: \(invoice.customer?.name ?? "N/A")")
            Text("Status: \(invoice.isPaid ? "Paid" : "Outstanding")")
                .foregroundColor(invoice.isPaid ? .green : .red)
            Text("Due Date: \(DateFormatter.localizedString(from: invoice.dueDate, dateStyle: .medium, timeStyle: .none))")

            Button("Preview Invoice") {
                PDFGenerator.generatePDF(invoice: invoice) { url in
                    if let url = url {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            pdfURL = url
                            showPDFPreview = true
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            if pdfURL != nil {
                Button("Send Invoice") {
                    showMailSheet = true
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Invoice Detail")
        .sheet(isPresented: $showPDFPreview) {
            if let url = pdfURL {
                NavigationStack {
                    PDFPreviewView(pdfURL: url)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Share") {
                                    showMailSheet = true
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showMailSheet) {
            if let url = pdfURL, let company = companyInfos.first {
                let subject = "Invoice \(invoice.invoiceNumber)"
                let body = "Dear \(invoice.customer?.name ?? ""),\n\nPlease find attached your invoice.\n\nBest regards,\n\(company.name)"
                let cc = company.ccEmail.isEmpty ? nil : company.ccEmail
                let to = invoice.customer?.email.isEmpty == false ? invoice.customer!.email : nil
                presentMailCompose(to: to, cc: cc, subject: subject, body: body, pdfURL: url)
            }
        }
    }
}