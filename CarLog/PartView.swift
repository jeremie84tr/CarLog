//
//  PartView.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import SwiftUI

struct PartView: View {
    
    @ObservedObject var part: Part
        
    var body: some View {
        VStack {
            TextField("Name", text: $part.name)
            
            TextField("Price", value: $part.price, format: .currency(code: "EUR"))
                .keyboardType(.numbersAndPunctuation)
        }
    }
}

var moneyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currencyPlural
    return formatter
}
