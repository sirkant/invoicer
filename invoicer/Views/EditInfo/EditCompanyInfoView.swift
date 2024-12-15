import SwiftUI
import SwiftData
import PhotosUI

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
                let company = CompanyInfo(
                    name: name,
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
                    ccEmail: ccEmail
                )
                context.insert(company)
                try? context.save()
            }
        }
    }
}