import SwiftUI

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