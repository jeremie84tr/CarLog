// Visuels de mise en avant (en-tête, résultats de recherche) : plusieurs iPhone sur le fond de l'app, sans texte.
// Usage : swift promo.swift <sortie.png> <largeur> <hauteur> <capture:hauteurRel:cxRel:cyRel> ...
// Les téléphones sont dessinés dans l'ordre donné (le dernier est au premier plan). PNG sans canal alpha.
import AppKit

let a = CommandLine.arguments
let sortie = URL(fileURLWithPath: a[1])
let W = Int(a[2])!, H = Int(a[3])!
let w = CGFloat(W), h = CGFloat(H)
let bordureRel: CGFloat = 0.035, rEcran: CGFloat = 62.0 / 440, rBoitier: CGFloat = (62.0 + 15.4) / 440

let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGradient(starting: NSColor(red: 0.17, green: 0.47, blue: 0.40, alpha: 1),
           ending: NSColor(red: 0.04, green: 0.13, blue: 0.13, alpha: 1))!
    .draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)
for (x, y, r) in [(0.06, 0.82, 0.035), (0.95, 0.88, 0.022), (0.90, 0.20, 0.03), (0.12, 0.15, 0.018), (0.80, 0.70, 0.012)] {
    let d = CGFloat(r) * w
    NSColor.white.withAlphaComponent(0.10).setFill()
    NSBezierPath(ovalIn: NSRect(x: CGFloat(x) * w - d / 2, y: CGFloat(y) * h - d / 2, width: d, height: d)).fill()
}

for spec in a.dropFirst(4) {
    let p = spec.split(separator: ":").map(String.init)
    let source = NSImage(contentsOfFile: p[0])!
    let hr = CGFloat(Double(p[1])!), cx = CGFloat(Double(p[2])!) * w, cy = CGFloat(Double(p[3])!) * h
    let ratio = source.size.width / source.size.height
    let ew = hr * h / (1 / ratio + 2 * bordureRel)
    let eh = ew / ratio, b = bordureRel * ew
    let boitier = NSRect(x: cx - (ew + 2 * b) / 2, y: cy - (eh + 2 * b) / 2, width: ew + 2 * b, height: eh + 2 * b)
    let ecran = boitier.insetBy(dx: b, dy: b)
    let rb = rBoitier * ew
    NSGraphicsContext.saveGraphicsState()
    let ombre = NSShadow()
    ombre.shadowColor = NSColor.black.withAlphaComponent(0.45)
    ombre.shadowBlurRadius = w * 0.012
    ombre.shadowOffset = NSSize(width: 0, height: -w * 0.006)
    ombre.set()
    NSColor(white: 0.12, alpha: 1).setFill()
    NSBezierPath(roundedRect: boitier, xRadius: rb, yRadius: rb).fill()
    NSGraphicsContext.restoreGraphicsState()
    let lisere = NSBezierPath(roundedRect: boitier.insetBy(dx: b * 0.06, dy: b * 0.06), xRadius: rb - b * 0.06, yRadius: rb - b * 0.06)
    lisere.lineWidth = b * 0.12
    NSColor(white: 0.42, alpha: 1).setStroke()
    lisere.stroke()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: ecran, xRadius: rEcran * ew, yRadius: rEcran * ew).addClip()
    source.draw(in: ecran)
    NSGraphicsContext.restoreGraphicsState()
}

let dest = CGImageDestinationCreateWithURL(sortie as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
