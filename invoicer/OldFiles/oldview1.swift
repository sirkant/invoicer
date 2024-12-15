
import SwiftUI
import SwiftData
import PDFKit
import UIKit
import PhotosUI
import MessageUI

/*
// MARK: - Payment Terms Enumeration
enum PaymentTerms: String, CaseIterable, Identifiable {
    case net10 = "Net 10"
    case net30 = "Net 30"
    case net60 = "Net 60"
    case net90 = "Net 90"
    case other = "Other"

    var id: String { self.rawValue }

    var days: Int {
        switch self {
        case .net10: return 10
        case .net30: return 30
        case .net60: return 60
        case .net90: return 90
        case .other: return 0
        }
    }
}

// MARK: - Mock Currency Converter
class CurrencyConverter {
    static func getRate(from: String, to: String) -> Double {
        // Placeholder for an external API call
        return 1.0
    }
}

// MARK: - Models

@Model
class CompanyInfo {
    var name: String
    var streetAddress: String
    var postCode: String
    var city: String
    var country: String
    var taxID: String
    var taxLabel: String
    var taxRate: Int // 0-100
    var logoData: Data?
    var footerText: String
    var fontName: String
    var fontSize: Int
    var bankAccount: String
    var paymentInstructions: String
    var ccEmail: String

    init(name: String = "",
         streetAddress: String = "",
         postCode: String = "",
         city: String = "",
         country: String = "",
         taxID: String = "",
         taxLabel: String = "VAT",
         taxRate: Int = 0,
         logoData: Data? = nil,
         footerText: String = "",
         fontName: String = "Helvetica",
         fontSize: Int = 12,
         bankAccount: String = "",
         paymentInstructions: String = "Please pay to {bankAccount} referencing invoice {invoiceNumber}",
         ccEmail: String = "") {
        self.name = name
        self.streetAddress = streetAddress
        self.postCode = postCode
        self.city = city
        self.country = country
        self.taxID = taxID
        self.taxLabel = taxLabel
        self.taxRate = taxRate
        self.logoData = logoData
        self.footerText = footerText
        self.fontName = fontName
        self.fontSize = fontSize
        self.bankAccount = bankAccount
        self.paymentInstructions = paymentInstructions
        self.ccEmail = ccEmail
    }

    var logoImage: UIImage? {
        guard let data = logoData else { return nil }
        return UIImage(data: data)
    }

    func uiFont(weight: UIFont.Weight = .regular) -> UIFont {
        let size = CGFloat(fontSize)
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
    }
}

@Model
class Product {
    var name: String
    var price: Double
    var taxRate: Int? // 0-100, optional override
    var currency: String

    init(name: String, price: Double, taxRate: Int? = nil, currency: String = "USD") {
        self.name = name
        self.price = price
        self.taxRate = taxRate
        self.currency = currency
    }
}

@Model
class Customer {
    var name: String
    var address: String
    var email: String
    var phone: String

    init(name: String = "", address: String = "", email: String = "", phone: String = "") {
        self.name = name
        self.address = address
        self.email = email
        self.phone = phone
    }
}

@Model
class InvoiceItem {
    var product: Product
    var quantity: Int
    var discountRate: Double

    init(product: Product, quantity: Int = 1, discountRate: Double = 0.0) {
        self.product = product
        self.quantity = quantity
        self.discountRate = discountRate
    }

    func baseAmount() -> Double {
        (product.price * (1 - discountRate)) * Double(quantity)
    }
}

@Model
class Invoice {
    var uuid: UUID
    var companyInfo: CompanyInfo
    var items: [InvoiceItem]
    var invoiceNumber: String
    var date: Date
    var isPaid: Bool
    var customer: Customer?
    var paymentTermsRaw: String

    init(companyInfo: CompanyInfo,
         items: [InvoiceItem] = [],
         invoiceNumber: String,
         date: Date,
         isPaid: Bool = false,
         customer: Customer? = nil,
         paymentTermsRaw: String = PaymentTerms.net30.rawValue) {
        self.companyInfo = companyInfo
        self.items = items
        self.invoiceNumber = invoiceNumber
        self.date = date
        self.isPaid = isPaid
        self.customer = customer
        self.uuid = UUID()
        self.paymentTermsRaw = paymentTermsRaw
    }

    var paymentTerms: PaymentTerms {
        PaymentTerms(rawValue: paymentTermsRaw) ?? .net30
    }

    var dueDate: Date {
        guard paymentTerms.days > 0 else { return date }
        return Calendar.current.date(byAdding: .day, value: paymentTerms.days, to: date) ?? date
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.baseAmount() }
    }

    var taxAmount: Double {
        items.reduce(0) { partial, item in
            let effectiveTaxRate = Double(item.product.taxRate ?? companyInfo.taxRate)/100.0
            return partial + (item.baseAmount() * effectiveTaxRate)
        }
    }

    var totalAmount: Double {
        subtotal + taxAmount
    }
}

// MARK: - PDF Generator
class PDFGenerator {
    static func generatePDF(invoice: Invoice, completion: @escaping (URL?) -> Void) {
        let pdfMetaData = [
            kCGPDFContextCreator: "InvoiceApp",
            kCGPDFContextAuthor: "Your Startup",
            kCGPDFContextTitle: "Invoice \(invoice.invoiceNumber)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 612.0
        let pageHeight: CGFloat = 792.0
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Invoice-\(invoice.invoiceNumber).pdf")

        let fontRegular = invoice.companyInfo.uiFont(weight: .regular)
        let fontBold = invoice.companyInfo.uiFont(weight: .bold)
        let fontSemi = invoice.companyInfo.uiFont(weight: .semibold)

        do {
            try renderer.writePDF(to: url, withActions: { (context) in
                context.beginPage()

                let cgContext = context.cgContext
                let leftPadding: CGFloat = 40
                var topPadding: CGFloat = 40

                // Logo if available
                if let logo = invoice.companyInfo.logoImage {
                    let logoRect = CGRect(x: leftPadding, y: topPadding, width: 100, height: 100)
                    logo.draw(in: logoRect)
                    topPadding += 120
                }

                // Company Info (top-left)
                let companyInfoText = """
                \(invoice.companyInfo.name)
                \(invoice.companyInfo.streetAddress)
                \(invoice.companyInfo.postCode) \(invoice.companyInfo.city)
                \(invoice.companyInfo.country)
                Tax ID: \(invoice.companyInfo.taxID)
                """
                drawText(companyInfoText, x: leftPadding, y: topPadding, font: fontBold)

                // Customer info (top-right)
                let rightPadding: CGFloat = 400
                if let customer = invoice.customer {
                    let customerText = "Customer:\n\(customer.name)\n\(customer.address)\nEmail: \(customer.email)\nPhone: \(customer.phone)"
                    drawText(customerText, x: rightPadding, y: topPadding, font: fontRegular)
                } else {
                    drawText("Customer:\nN/A", x: rightPadding, y: topPadding, font: fontRegular)
                }

                topPadding += 100
                drawLine(cgContext: cgContext, from: CGPoint(x: leftPadding, y: topPadding), to: CGPoint(x: 572, y: topPadding))
                topPadding += 20

                // Invoice Info
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let dueDateString = dateFormatter.string(from: invoice.dueDate)
                let invoiceInfoText = """
                Invoice Number: \(invoice.invoiceNumber)
                Date: \(dateFormatter.string(from: invoice.date))
                Due Date: \(dueDateString)
                Status: \(invoice.isPaid ? "Paid" : "Outstanding")
                Terms: \(invoice.paymentTermsRaw)
                """
                drawText(invoiceInfoText, x: leftPadding, y: topPadding, font: fontRegular)

                topPadding += 100
                drawLine(cgContext: cgContext, from: CGPoint(x: leftPadding, y: topPadding), to: CGPoint(x: 572, y: topPadding))
                topPadding += 10

                // Header row with gray background
                let headerRect = CGRect(x: leftPadding, y: topPadding, width: 532 - leftPadding, height: 20)
                cgContext.setFillColor(UIColor(white: 0.9, alpha: 1.0).cgColor)
                cgContext.fill(headerRect)

                drawText("Item", x: leftPadding, y: topPadding, font: fontSemi)
                drawText("Qty", x: leftPadding+150, y: topPadding, font: fontSemi)
                drawText("Price", x: leftPadding+200, y: topPadding, font: fontSemi)
                drawText("Tax%", x: leftPadding+280, y: topPadding, font: fontSemi)
                drawText("Line Total", x: leftPadding+360, y: topPadding, font: fontSemi)
                drawText("Curr.", x: leftPadding+450, y: topPadding, font: fontSemi)

                topPadding += 20
                drawLine(cgContext: cgContext, from: CGPoint(x: leftPadding, y: topPadding), to: CGPoint(x: 572, y: topPadding))
                topPadding += 10

                // Items
                for item in invoice.items {
                    let effectiveTaxRate = Double(item.product.taxRate ?? invoice.companyInfo.taxRate)
                    let base = item.baseAmount()
                    let lineTotal = base + (base * (effectiveTaxRate/100.0))
                    drawText(item.product.name, x: leftPadding, y: topPadding, font: fontRegular)
                    drawText("\(item.quantity)", x: leftPadding+150, y: topPadding, font: fontRegular)
                    drawText(String(format: "%.2f", item.product.price), x: leftPadding+200, y: topPadding, font: fontRegular)
                    drawText("\(Int(effectiveTaxRate))%", x: leftPadding+280, y: topPadding, font: fontRegular)
                    drawText(String(format: "%.2f", lineTotal), x: leftPadding+360, y: topPadding, font: fontRegular)
                    drawText(item.product.currency, x: leftPadding+450, y: topPadding, font: fontRegular)
                    topPadding += 20
                }

                topPadding += 10
                drawLine(cgContext: cgContext, from: CGPoint(x: leftPadding, y: topPadding), to: CGPoint(x: 572, y: topPadding))
                topPadding += 10

                // Summary
                drawText("Subtotal: \(String(format: "%.2f", invoice.subtotal))", x: leftPadding+360, y: topPadding, font: fontRegular)
                topPadding += 20
                drawText("\(invoice.companyInfo.taxLabel) Total: \(String(format: "%.2f", invoice.taxAmount))", x: leftPadding+360, y: topPadding, font: fontRegular)
                topPadding += 20
                drawText("Total: \(String(format: "%.2f", invoice.totalAmount))", x: leftPadding+360, y: topPadding, font: fontBold)
                topPadding += 20

                // Move footer near bottom
                let footerStartY: CGFloat = 700 // near bottom of the page
                if topPadding < footerStartY {
                    topPadding = footerStartY
                }

                if !invoice.companyInfo.footerText.isEmpty || !invoice.companyInfo.bankAccount.isEmpty {
                    drawLine(cgContext: cgContext, from: CGPoint(x: leftPadding, y: topPadding), to: CGPoint(x: 572, y: topPadding))
                    topPadding += 20
                    let paymentInstruction = invoice.companyInfo.paymentInstructions
                        .replacingOccurrences(of: "{bankAccount}", with: invoice.companyInfo.bankAccount)
                        .replacingOccurrences(of: "{invoiceNumber}", with: invoice.invoiceNumber)

                    let footerText = invoice.companyInfo.footerText.isEmpty ?
                    paymentInstruction :
                    "\(invoice.companyInfo.footerText)\n\n\(paymentInstruction)"

                    drawText(footerText, x: leftPadding, y: topPadding, font: fontRegular)
                }
            })
            completion(url)
        } catch {
            print("Error generating PDF: \(error)")
            completion(nil)
        }
    }

    private static func drawText(_ text: String, x: CGFloat, y: CGFloat, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
    }

    private static func drawLine(cgContext: CGContext, from start: CGPoint, to end: CGPoint) {
        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(1)
        cgContext.move(to: start)
        cgContext.addLine(to: end)
        cgContext.strokePath()
    }
}

// MARK: - Mail and Share Sheets

struct MailView: UIViewControllerRepresentable {
    let toRecipients: [String]?
    let ccRecipients: [String]?
    let subject: String
    let body: String
    let attachments: [(Data, String)]

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(toRecipients)
        if let cc = ccRecipients, !cc.isEmpty {
            vc.setCcRecipients(cc)
        }
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            vc.addAttachmentData(attachment.0, mimeType: "application/pdf", fileName: attachment.1)
        }
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        init(_ parent: MailView) {
            self.parent = parent
        }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

func presentMailCompose(to: String?, cc: String?, subject: String, body: String, pdfURL: URL) -> some View {
    if MFMailComposeViewController.canSendMail() {
        let pdfData = (try? Data(contentsOf: pdfURL)) ?? Data()
        return AnyView(MailView(toRecipients: to != nil ? [to!] : nil,
                                ccRecipients: cc != nil && !cc!.isEmpty ? [cc!] : nil,
                                subject: subject,
                                body: body,
                                attachments: [(pdfData, "Invoice.pdf")]))
    } else {
        return AnyView(ShareSheet(activityItems: [pdfURL]))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

// MARK: - PDF Preview
struct PDFPreviewView: View {
    let pdfURL: URL

    var body: some View {
        PDFKitView(url: pdfURL)
            .navigationTitle("Invoice Preview")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Intro View
struct IntroView: View {
    @State private var navigateToMain = false

    var body: some View {
        VStack(spacing: 50) {
            Spacer()
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Text("BoringSoftwareThatWorks")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                navigateToMain = true
            }
        }
        .fullScreenCover(isPresented: $navigateToMain) {
            MainMenuView()
        }
    }
}

// MARK: - Due Calendar View
struct DueCalendarView: View {
    @Query var invoices: [Invoice]

    var body: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let days = (0..<30).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }

        List(days, id: \.self) { day in
            let dueInvoices = invoices.filter { !$0.isPaid && Calendar.current.isDate($0.dueDate, inSameDayAs: day) }
            let totalDue = dueInvoices.reduce(0) { $0 + $1.totalAmount }

            HStack {
                Text(DateFormatter.localizedString(from: day, dateStyle: .medium, timeStyle: .none))
                Spacer()
                if totalDue > 0 {
                    Text(String(format: "%.2f", totalDue))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                } else {
                    Text("No invoices due")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Upcoming Due Invoices")
    }
}

// MARK: - Main Menu View
struct MainMenuView: View {
    @Query var invoices: [Invoice]
    @Query var companyInfos: [CompanyInfo]

    let backgroundColor = Color(red: 0.0/255, green: 39.0/255, blue: 86.0/255)

    var outstandingInvoices: [Invoice] {
        invoices.filter { !$0.isPaid }
    }

    var totalOutstanding: Double {
        outstandingInvoices.reduce(0) { $0 + $1.totalAmount }
    }

    var overdueInvoices: [Invoice] {
        invoices.filter { !$0.isPaid && $0.dueDate < Date() }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    VStack(spacing: 20) {
                        HStack {
                            if let company = companyInfos.first, let logo = company.logoImage {
                                Image(uiImage: logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .padding(.leading)
                            } else {
                                Image(systemName: "building")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .padding(.leading)
                            }
                            Spacer()
                            Image(systemName: "doc.text.fill.viewfinder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding(.trailing, geo.size.width/2 - 25)
                        }
                        .padding(.top, 50)

                        Spacer()

                        VStack(spacing: 10) {
                            Text("Outstanding Invoices: \(outstandingInvoices.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Total Outstanding: \(String(format: "%.2f", totalOutstanding))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("Overdue: \(overdueInvoices.count)")
                                .font(.headline)
                                .foregroundColor(.red)

                            NavigationLink("View Due Calendar", destination: DueCalendarView())
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 10)
                        }

                        Spacer()

                        let buttonHeight = geo.size.height * 0.35
                        HStack {
                            NavigationLink(destination: CreateInvoiceView()) {
                                VStack {
                                    Image(systemName: "square.and.pencil")
                                    Text("New Invoice")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: buttonHeight)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }

                            NavigationLink(destination: ViewInvoicesView()) {
                                VStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("Invoices")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: buttonHeight)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }

                            NavigationLink(destination: EditInfoView()) {
                                VStack {
                                    Image(systemName: "gearshape")
                                    Text("Edit Info")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: buttonHeight)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                        .padding([.leading, .trailing], 20)
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Create Invoice View
struct CreateInvoiceView: View {
    @Environment(\.modelContext) private var context
    @Query var companyInfos: [CompanyInfo]
    @Query var products: [Product]
    @Query var customers: [Customer]

    @State private var selectedCustomer: Customer?
    @State private var newCustomerName = ""
    @State private var newCustomerAddress = ""
    @State private var newCustomerEmail = ""
    @State private var newCustomerPhone = ""

    @State private var selectedProduct: Product?
    @State private var quantity: Int = 1

    @State private var invoiceNumber = "INV-\(Int.random(in: 1000...9999))"
    @State private var showPDF = false
    @State private var pdfURL: URL?
    @State private var showPDFPreview = false
    @State private var showSavedAlert = false
    @State private var showMailSheet = false
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPaymentTerms: PaymentTerms = .net30

    var body: some View {
        Form {
            Section(header: Text("Customer").font(.headline)) {
                Picker("Select Customer", selection: $selectedCustomer) {
                    Text("None").tag(Customer?.none)
                    ForEach(customers, id: \.id) { customer in
                        Text(customer.name).tag(Customer?.some(customer))
                    }
                }

                TextField("New Customer Name", text: $newCustomerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("New Customer Address", text: $newCustomerAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Customer Email", text: $newCustomerEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Customer Phone", text: $newCustomerPhone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Add New Customer") {
                    guard !newCustomerName.isEmpty, (!newCustomerEmail.isEmpty || !newCustomerPhone.isEmpty) else { return }
                    let c = Customer(name: newCustomerName, address: newCustomerAddress, email: newCustomerEmail, phone: newCustomerPhone)
                    context.insert(c)
                    try? context.save()
                    selectedCustomer = c
                    newCustomerName = ""
                    newCustomerAddress = ""
                    newCustomerEmail = ""
                    newCustomerPhone = ""
                }
                .buttonStyle(.borderedProminent)
            }

            Section(header: Text("Product").font(.headline)) {
                Picker("Select Product", selection: $selectedProduct) {
                    Text("None").tag(Product?.none)
                    ForEach(products, id: \.id) { product in
                        Text("\(product.name) - \(String(format: "%.2f", product.price)) \(product.currency)")
                            .tag(Product?.some(product))
                    }
                }

                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
            }

            Section(header: Text("Payment Terms")) {
                Picker("Select Terms", selection: $selectedPaymentTerms) {
                    ForEach(PaymentTerms.allCases) { term in
                        Text(term.rawValue).tag(term)
                    }
                }
            }

            if let company = companyInfos.first,
               let product = selectedProduct,
               let customer = selectedCustomer {
                Section(header: Text("Summary").font(.headline)) {
                    let base = Double(quantity) * product.price
                    let effectiveTaxRate = Double(product.taxRate ?? company.taxRate) / 100.0
                    let taxAmount = base * effectiveTaxRate
                    let total = base + taxAmount

                    Text("Invoice Number: \(invoiceNumber)")
                    Text("Subtotal: \(String(format: "%.2f", base))")
                    Text("\(company.taxLabel) (\(Int(effectiveTaxRate*100))%): \(String(format: "%.2f", taxAmount))")
                    Text("Total: \(String(format: "%.2f", total))")
                        .fontWeight(.bold)

                    HStack {
                        Button("Preview Invoice") {
                            let invoiceItem = InvoiceItem(product: product, quantity: quantity)
                            let invoice = Invoice(companyInfo: company,
                                                  items: [invoiceItem],
                                                  invoiceNumber: invoiceNumber,
                                                  date: Date(),
                                                  isPaid: false,
                                                  customer: customer,
                                                  paymentTermsRaw: selectedPaymentTerms.rawValue)
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

                        Button("Finalize & Save") {
                            let invoiceItem = InvoiceItem(product: product, quantity: quantity)
                            let invoice = Invoice(companyInfo: company,
                                                  items: [invoiceItem],
                                                  invoiceNumber: invoiceNumber,
                                                  date: Date(),
                                                  isPaid: false,
                                                  customer: customer,
                                                  paymentTermsRaw: selectedPaymentTerms.rawValue)
                            context.insert(invoice)
                            context.insert(invoiceItem)
                            try? context.save()
                            showSavedAlert = true
                        }
                        .buttonStyle(.bordered)
                    }

                    if pdfURL != nil {
                        Button("Send Invoice") {
                            showMailSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Section {
                    Text("Select company info, a customer (with email/phone), and a product to proceed.")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Create New Invoice")
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
        .alert("Invoice saved successfully", isPresented: $showSavedAlert) {
            Button("OK") {
                dismiss()
            }
        }
        .sheet(isPresented: $showMailSheet) {
            if let pdfURL = pdfURL, let company = companyInfos.first {
                let subject = "Invoice \(invoiceNumber)"
                let body = "Dear \(selectedCustomer?.name ?? ""),\n\nPlease find attached your invoice.\n\nBest regards,\n\(company.name)"
                let cc = company.ccEmail.isEmpty ? nil : company.ccEmail
                let to = selectedCustomer?.email.isEmpty == false ? selectedCustomer!.email : nil

                presentMailCompose(to: to, cc: cc, subject: subject, body: body, pdfURL: pdfURL)
            }
        }
    }
}

// MARK: - View Invoices & Detail

enum InvoiceGrouping: String, CaseIterable {
    case none = "None"
    case byCustomer = "Customer"
    case byStatus = "Status"
}

struct ViewInvoicesView: View {
    @Environment(\.modelContext) private var context
    @Query var invoices: [Invoice]

    @State private var grouping: InvoiceGrouping = .none
    @State private var hidePaid = false
    @State private var showCSVShare = false
    @State private var csvURL: URL?

    var filteredInvoices: [Invoice] {
        hidePaid ? invoices.filter { !$0.isPaid } : invoices
    }

    var groupedInvoices: [(String, [Invoice])] {
        switch grouping {
        case .none:
            return [("", filteredInvoices)]
        case .byCustomer:
            let groups = Dictionary(grouping: filteredInvoices) { invoice in
                invoice.customer?.name ?? "No Customer"
            }
            return groups.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        case .byStatus:
            let groups = Dictionary(grouping: filteredInvoices) { invoice in
                invoice.isPaid ? "Paid" : "Outstanding"
            }
            return groups.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Picker("Group By:", selection: $grouping) {
                    ForEach(InvoiceGrouping.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Hide Paid", isOn: $hidePaid)
                    .padding(.leading)
            }
            .padding()

            Button("Export to CSV") {
                exportToCSV()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)

            List {
                ForEach(groupedInvoices, id: \.0) { (header, group) in
                    if grouping != .none {
                        Section(header: Text(header)) {
                            invoiceRows(for: group)
                        }
                    } else {
                        invoiceRows(for: group)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Existing Invoices")
        .sheet(isPresented: $showCSVShare) {
            if let url = csvURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    @ViewBuilder
    func invoiceRows(for list: [Invoice]) -> some View {
        ForEach(list, id: \.id) { invoice in
            NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice: \(invoice.invoiceNumber)")
                        .font(.headline)
                    Text("Total: \(String(format: "%.2f", invoice.totalAmount))")
                        .foregroundColor(.secondary)
                    Text("Status: \(invoice.isPaid ? "Paid" : "Outstanding")")
                        .foregroundColor(invoice.isPaid ? .green : .red)
                    if let customer = invoice.customer {
                        Text("Customer: \(customer.name)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            .swipeActions(edge: .trailing) {
                if !invoice.isPaid {
                    Button("Mark Paid") {
                        invoice.isPaid = true
                        try? context.save()
                    }
                    .tint(.green)
                }
            }
        }
    }

    func exportToCSV() {
        var csv = "InvoiceNumber,Date,DueDate,Status,Customer,Subtotal,Tax,Total\n"
        let df = DateFormatter()
        df.dateStyle = .short

        for invoice in invoices {
            let status = invoice.isPaid ? "Paid" : "Outstanding"
            let custName = invoice.customer?.name.replacingOccurrences(of: ",", with: "") ?? ""
            csv += "\(invoice.invoiceNumber),\(df.string(from: invoice.date)),\(df.string(from: invoice.dueDate)),\(status),\(custName),\(invoice.subtotal),\(invoice.taxAmount),\(invoice.totalAmount)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("invoices_export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            self.csvURL = url
            self.showCSVShare = true
        } catch {
            print("Error writing CSV: \(error)")
        }
    }
}

// MARK: - Invoice Detail View
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

// MARK: - Edit Info
struct EditInfoView: View {
    var body: some View {
        Form {
            NavigationLink("Edit Company Info", destination: EditCompanyInfoView())
            NavigationLink("Edit Product Catalog", destination: EditProductCatalogView())
            NavigationLink("Edit Invoice Appearance", destination: EditInvoiceAppearanceView())
        }
        .navigationTitle("Edit Info")
    }
}

// MARK: - Edit Company Info
struct EditCompanyInfoView: View {
    @Environment(\.modelContext) private var context
    @Query var companyInfos: [CompanyInfo]

    @State private var name = ""
    @State private var streetAddress = ""
    @State private var postCode = ""
    @State private var city = ""
    @State private var country = ""
    @State private var taxID = ""
    @State private var taxLabel = "VAT"
    @State private var taxRate: Int = 0
    @State private var selectedImageData: Data?
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var footerText = ""
    @State private var bankAccount = ""
    @State private var paymentInstructions = "Please pay to {bankAccount} referencing invoice {invoiceNumber}"
    @State private var ccEmail = ""

    var body: some View {
        Form {
            Section(header: Text("Company Details")) {
                TextField("Name", text: $name)
                TextField("Street Address", text: $streetAddress)
                TextField("Post Code", text: $postCode)
                TextField("City", text: $city)
                TextField("Country", text: $country)
                TextField("Tax ID", text: $taxID)
            }

            Section(header: Text("Tax Info")) {
                TextField("Tax Label", text: $taxLabel)
                TextField("Tax Rate (0-100)", value: $taxRate, format: .number)
                    .keyboardType(.numberPad)
                Text("Enter integer, e.g. 25 for 25% VAT")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Section(header: Text("Footer & Payment")) {
                TextField("Footer (e.g. payment terms)", text: $footerText)
                TextField("Bank Account", text: $bankAccount)
                TextField("Payment Instructions", text: $paymentInstructions)
                    .font(.footnote)
                    .foregroundColor(.gray)
                TextField("CC Email (Your email to get a copy)", text: $ccEmail)
                    .keyboardType(.emailAddress)
            }

            Section(header: Text("Logo")) {
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } else if let company = companyInfos.first, let logo = company.logoImage {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } else {
                    Text("No logo selected")
                        .foregroundColor(.gray)
                }

                Button("Select Logo") {
                    showPhotoPicker = true
                }
            }
        }
        .onAppear {
            if let company = companyInfos.first {
                name = company.name
                streetAddress = company.streetAddress
                postCode = company.postCode
                city = company.city
                country = company.country
                taxID = company.taxID
                taxLabel = company.taxLabel
                taxRate = company.taxRate
                footerText = company.footerText
                bankAccount = company.bankAccount
                paymentInstructions = company.paymentInstructions
                ccEmail = company.ccEmail
            }
        }
        .navigationTitle("Edit Company Info")
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
        .onDisappear {
            if let company = companyInfos.first {
                company.name = name
                company.streetAddress = streetAddress
                company.postCode = postCode
                company.city = city
                company.country = country
                company.taxID = taxID
                company.taxLabel = taxLabel
                company.taxRate = taxRate
                company.footerText = footerText
                company.bankAccount = bankAccount
                company.paymentInstructions = paymentInstructions
                company.ccEmail = ccEmail
                if let data = selectedImageData {
                    company.logoData = data
                }
                try? context.save()
            } else {
                let company = CompanyInfo(name: name,
                                          streetAddress: streetAddress,
                                          postCode: postCode,
                                          city: city,
                                          country: country,
                                          taxID: taxID,
                                          taxLabel: taxLabel,
                                          taxRate: taxRate,
                                          logoData: selectedImageData,
                                          footerText: footerText,
                                          bankAccount: bankAccount,
                                          paymentInstructions: paymentInstructions,
                                          ccEmail: ccEmail)
                context.insert(company)
                try? context.save()
            }
        }
    }
}

// MARK: - Edit Product Catalog
struct EditProductCatalogView: View {
    @Environment(\.modelContext) private var context
    @Query var products: [Product]

    @State private var productName = ""
    @State private var productPrice = ""
    @State private var productTaxRate: Int?
    @State private var productCurrency = "USD"

    var body: some View {
        Form {
            Section("Add New Product") {
                TextField("Name", text: $productName)
                TextField("Price", text: $productPrice)
                    .keyboardType(.decimalPad)
                TextField("Tax Rate Override (0-100)", value: $productTaxRate, format: .number)
                    .keyboardType(.numberPad)
                TextField("Currency (e.g. USD, EUR)", text: $productCurrency)

                Button("Add") {
                    guard let price = Double(productPrice), !productName.isEmpty else { return }
                    let p = Product(name: productName, price: price, taxRate: productTaxRate, currency: productCurrency.uppercased())
                    context.insert(p)
                    try? context.save()
                    productName = ""
                    productPrice = ""
                    productTaxRate = nil
                    productCurrency = "USD"
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Existing Products") {
                List(products, id: \.id) { product in
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .fontWeight(.semibold)
                        HStack {
                            Text("Price: \(String(format: "%.2f", product.price)) \(product.currency)")
                            if let tax = product.taxRate {
                                Text("Tax: \(tax)%")
                            } else {
                                Text("Uses company tax rate")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Edit Product Catalog")
    }
}

// MARK: - Edit Invoice Appearance
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
*/
