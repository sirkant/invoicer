import SwiftUI
import SwiftData

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