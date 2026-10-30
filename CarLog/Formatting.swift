//
//  Formatting.swift
//  CarLog
//

import Foundation

/// Devise unique de l'app, partagée par les champs de saisie et l'affichage.
let appCurrencyCode = "EUR"

let moneyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = appCurrencyCode
    return formatter
}()

extension Double {
    /// Nombre localisé avec 2 décimales maximum, pour l'affichage.
    var shortNumber: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }

    /// Prix au litre : toujours 3 décimales (ex. 1,899).
    var pricePerLiterString: String {
        formatted(.number.precision(.fractionLength(3)))
    }
}
