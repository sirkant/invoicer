import SwiftUI
import SwiftData

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