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
            TextField("Nom", text: $part.name)
            
            TextField("Prix", value: $part.price, format: .currency(code: appCurrencyCode))
                .keyboardType(.decimalPad)
        }
    }
}

/// Devise unique de l'app, partagée par les champs de saisie et l'affichage.
let appCurrencyCode = "EUR"

let moneyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = appCurrencyCode
    return formatter
}()
