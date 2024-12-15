import Foundation
import UIKit
import PDFKit

// Add `import SwiftUI` only if needed. Usually not required since it's utility code.

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

                // Company Info
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

                // Gray header row
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

                // Footer near bottom
                let footerStartY: CGFloat = 700
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