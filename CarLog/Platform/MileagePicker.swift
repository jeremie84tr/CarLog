//
//  MileagePicker.swift
//  CarLog
//
//  Sélecteur de kilométrage : roulette sur iOS, saisie chiffre par chiffre sur macOS.
//

import SwiftUI

struct MileagePicker: View {
    let title: LocalizedStringKey
    @Binding var value: Int64
    /// Valeurs proposées par la roulette iOS (ignorées sur macOS).
    let candidates: [Int64]

    var body: some View {
#if os(iOS)
        Picker(title, selection: $value) {
            ForEach(candidates, id: \.self) { km in
                Text("\(km) Km").tag(km)
            }
        }
        .pickerStyle(.wheel)
#else
        LabeledContent(title) { DigitMileageEditor(value: $value) }
#endif
    }
}

#if os(macOS)
/// N+1 chiffres (N = nombre de chiffres de la valeur) : un champ par chiffre,
/// avec un bouton au-dessus (+1 de l'unité du rang) et un au-dessous (−1).
private struct DigitMileageEditor: View {
    @Binding var value: Int64

    private var digitCount: Int { String(max(value, 0)).count + 1 }

    var body: some View {
        HStack(spacing: 4) {
            ForEach((0..<digitCount).reversed(), id: \.self) { position in
                DigitColumn(value: $value, position: position)
            }
            Text("Km").foregroundStyle(.secondary).padding(.leading, 4)
        }
    }
}

private struct DigitColumn: View {
    @Binding var value: Int64
    /// 0 = unités, 1 = dizaines, etc.
    let position: Int

    private var unit: Int64 { (0..<position).reduce(1) { acc, _ in acc * 10 } }
    private var digit: Int64 { (value / unit) % 10 }

    private var digitText: Binding<String> {
        Binding(
            get: { String(digit) },
            set: { newText in
                guard let last = newText.last(where: \.isNumber), let d = Int64(String(last)) else { return }
                value = max(0, value - digit * unit + d * unit)
            }
        )
    }

    var body: some View {
        VStack(spacing: 2) {
            Button { value += unit } label: { Image(systemName: "chevron.up") }
            TextField("", text: digitText)
                .multilineTextAlignment(.center)
                .frame(width: 26)
                .textFieldStyle(.roundedBorder)
            Button { value = max(0, value - unit) } label: { Image(systemName: "chevron.down") }
                .disabled(value < unit)
        }
        .buttonStyle(.borderless)
    }
}
#endif
