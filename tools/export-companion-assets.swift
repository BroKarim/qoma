// Run from the repository root: swift tools/export-companion-assets.swift
// Literal pixel extraction only. All coordinates use the source image's top-left origin.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("Qoma/Assets.xcassets/Companion")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
func source(_ name: String) -> CGImage {
    let url = root.appendingPathComponent("design/qyube-minimum-assets-v1/\(name).png")
    return CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
}

let poses = source("01-poses-no-glasses")
let props = source("03-shared-props")
var manifest: [[String: Any]] = []

func export(
    _ name: String,
    image: CGImage,
    rect: CGRect,
    polygon: [CGPoint] = [],
    ground: CGPoint? = nil,
    scale: CGFloat = 0.78) throws
{
    let size = ground == nil ? rect.size : CGSize(width: 512, height: 512)
    let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    if let ground {
        context.translateBy(x: 256 - ground.x * scale, y: 450 - ground.y * scale)
        context.scaleBy(x: scale, y: scale)
    } else {
        context.translateBy(x: -rect.minX, y: -rect.minY)
    }
    context.clip(to: rect)
    if !polygon.isEmpty {
        context.beginPath()
        context.addLines(between: polygon)
        context.closePath()
        context.clip()
    }
    // Compensate CGImage drawing for the top-left coordinate system.
    context.translateBy(x: 0, y: CGFloat(image.height))
    context.scaleBy(x: 1, y: -1)
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let folder = output.appendingPathComponent("\(name).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("\(name).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
    let contents: [String: Any] = [
        "images": [["filename": "\(name).png", "idiom": "universal"]],
        "info": ["author": "xcode", "version": 1],
    ]
    try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        .write(to: folder.appendingPathComponent("Contents.json"))
    manifest.append([
        "name": name,
        "sourceRect": [rect.minX, rect.minY, rect.width, rect.height],
        "canvas": [size.width, size.height],
        "groundAnchorTopLeft": ground == nil ? [] : [256, 450],
    ])
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: y, width: w, height: h)
}

func points(_ coordinates: [(CGFloat, CGFloat)]) -> [CGPoint] {
    coordinates.map { CGPoint(x: $0.0, y: $0.1) }
}

/// Registered pose library. The live fishing loop uses the articulated pieces below.
let poseSpecs: [(String, CGRect, CGPoint)] = [
    ("Standing", rect(46, 116, 320, 330), CGPoint(x: 215, y: 430)),
    ("Fishing", rect(466, 133, 410, 316), CGPoint(x: 725, y: 432)),
    ("Casting", rect(839, 6, 497, 441), CGPoint(x: 1164, y: 429)),
    ("Pulling", rect(1335, 8, 439, 440), CGPoint(x: 1575, y: 429)),
    ("Deposit", rect(35, 513, 435, 325), CGPoint(x: 209, y: 812)),
    ("Sleeping", rect(505, 578, 399, 249), CGPoint(x: 706, y: 815)),
    ("Hop", rect(929, 478, 386, 335), CGPoint(x: 1123, y: 791)),
    ("Completed", rect(1380, 490, 350, 350), CGPoint(x: 1570, y: 819)),
]
for (name, box, ground) in poseSpecs {
    let mask = name == "Casting" ? points([
        (850, 6),
        (950, 6),
        (1335, 135),
        (1335, 447),
        (980, 447),
        (975, 260),
        (839, 90),
    ]) : []
    try export("CompanionPose\(name)", image: poses, rect: box, polygon: mask, ground: ground)
}

// Overlapping seams are intentional: the torso sits under head and flippers.
try export(
    "CompanionHead",
    image: poses,
    rect: rect(104, 119, 217, 194),
    polygon:
    points([
        (108, 247),
        (111, 196),
        (131, 151),
        (177, 121),
        (240, 121),
        (287, 155),
        (312, 202),
        (320, 251),
        (297, 279),
        (269, 299),
        (213, 311),
        (164, 297),
        (127, 274),
    ]))
try export(
    "CompanionTorso",
    image: poses,
    rect: rect(101, 254, 220, 166),
    polygon:
    points([
        (127, 254),
        (286, 254),
        (307, 307),
        (317, 377),
        (295, 406),
        (251, 420),
        (164, 420),
        (112, 399),
        (101, 364),
        (112, 296),
    ]))
try export(
    "CompanionFlipperLeft",
    image: poses,
    rect: rect(64, 262, 66, 129),
    polygon:
    points([(104, 262), (126, 277), (115, 312), (101, 359), (106, 381), (93, 391), (75, 380), (64, 359), (71, 319)]))
try export(
    "CompanionFlipperRight",
    image: poses,
    rect: rect(288, 254, 69, 147),
    polygon:
    points([
        (290, 254),
        (313, 263),
        (340, 300),
        (357, 346),
        (356, 379),
        (343, 398),
        (328, 401),
        (309, 385),
        (298, 354),
        (301, 319),
    ]))
try export("CompanionFeet", image: poses, rect: rect(107, 405, 220, 40))

let propSpecs: [(String, CGRect)] = [
    ("Floe", rect(29, 215, 520, 230)), ("Bucket", rect(586, 180, 255, 265)),
    ("Fish", rect(932, 265, 288, 144)), ("Tree", rect(164, 618, 190, 238)),
    ("Rod", rect(475, 521, 346, 322)), ("Line", rect(1025, 510, 85, 328)),
    ("SleepMarks", rect(150, 930, 244, 177)), ("Splash", rect(551, 968, 234, 179)),
    ("Bite", rect(989, 926, 96, 244)),
]
for (name, box) in propSpecs {
    try export("Companion\(name)", image: props, rect: box)
}

let manifestURL = root.appendingPathComponent("design/qyube-minimum-assets-v1/asset-manifest.json")
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: manifestURL)
print("Exported \(manifest.count) transparent assets with pose ground anchors at (256, 450).")
