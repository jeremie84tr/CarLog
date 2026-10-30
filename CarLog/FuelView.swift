//
//  FuelView.swift
//  CarLog
//
//  Created by Jeremie LOHYER on 26/07/2025.
//

import SwiftUI

struct FuelView: View {
    
    @ObservedObject var fuel: Fuel
    
    var body: some View {
        Section("Carburant") {
            TextField("Quantité", value: $fuel.quantity, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
            Toggle("Plein", isOn: $fuel.full)
            
            TextField("Prix", value: $fuel.price, format: .currency(code: appCurrencyCode))
                .keyboardType(.decimalPad)
        }
    }
}
