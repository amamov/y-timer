// 앱 아이콘(1024x1024, 알파 없음)을 그린다. 사용법: swift scripts/make-icon.swift <출력.png>
import AppKit

let size = 1024
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let ink = CGColor(gray: 1, alpha: 0.95)
ctx.setFillColor(CGColor(gray: 0, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let center = CGPoint(x: 512, y: 512)
ctx.setLineCap(.round)
ctx.setLineWidth(44)
ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.12))
ctx.addArc(center: center, radius: 330, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()
// 12시에서 시계 방향으로 남은 3/4.
ctx.setStrokeColor(ink)
ctx.addArc(center: center, radius: 330, startAngle: .pi / 2, endAngle: -.pi, clockwise: true)
ctx.strokePath()

let font = NSFont.systemFont(ofSize: 360, weight: .light)
let text = NSAttributedString(string: "X", attributes: [.font: font, .foregroundColor: NSColor.white])
let line = CTLineCreateWithAttributedString(text)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
ctx.textPosition = CGPoint(x: 512 - bounds.midX, y: 512 - bounds.midY)
CTLineDraw(line, ctx)

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
