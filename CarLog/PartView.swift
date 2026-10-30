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
