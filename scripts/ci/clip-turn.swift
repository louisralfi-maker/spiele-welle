// Turns the simulator's recording of a landscape game upright and shrinks it (Lanternhold build 3, lane 4: the horde's
// clip, POLISH.md 6.6). `xcrun simctl io recordVideo` records the portrait frame buffer, so a game held in landscape
// left stands on its side in it: the world's west at the top, its ground on the left (the same as a simulator
// screenshot without its orientation tag). This turns it a quarter turn counterclockwise (west to the left, the ground
// to the bottom) into `width` x `height` (default 1310 x 602, the shape of 2622 x 1206 with even sides), H.264, no sound.
//   swift clip-turn.swift <in.mp4> <out.mp4> [width height]
// It prints one line and exits 0 on success, 1 on any failure (sim-clip.sh then keeps the clip as it was).
import AVFoundation
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: swift clip-turn.swift <in.mp4> <out.mp4> [width height]")
    exit(1)
}
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])
let width = args.count >= 5 ? (Double(args[3]) ?? 1310) : 1310
let height = args.count >= 5 ? (Double(args[4]) ?? 602) : 602

let asset = AVURLAsset(url: input)
guard let track = asset.tracks(withMediaType: .video).first else {
    print("clip-turn: no video track in \(input.path)")
    exit(1)
}
// The frame as the recorder coded it. Its own transform (a rotation tag; identity for the simulator's recordings) is
// left out, so the turn below is the only one, as sim-clip.sh's ffmpeg path does with -noautorotate.
let stored = track.naturalSize
let srcW = abs(stored.width)
let srcH = abs(stored.height)
guard srcW > 0, srcH > 0 else {
    print("clip-turn: empty frame")
    exit(1)
}
// A quarter turn counterclockwise on screen (y down): (x, y) -> (y, srcW - x); then scaled to the output.
let turn = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: srcW)
let scale = CGAffineTransform(scaleX: width / srcH, y: height / srcW)
let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
layer.setTransform(turn.concatenating(scale), at: .zero)
instruction.layerInstructions = [layer]
let composition = AVMutableVideoComposition()
composition.instructions = [instruction]
composition.renderSize = CGSize(width: width, height: height)
let rate = track.nominalFrameRate
composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(rate > 1 ? min(60, rate.rounded()) : 30))

guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
    print("clip-turn: no export session")
    exit(1)
}
try? FileManager.default.removeItem(at: output)
export.outputURL = output
export.outputFileType = .mp4
export.videoComposition = composition
export.shouldOptimizeForNetworkUse = true
let done = DispatchSemaphore(value: 0)
export.exportAsynchronously { done.signal() }
if done.wait(timeout: .now() + 240) == .timedOut {
    export.cancelExport()
    print("clip-turn: the export took over 240 s")
    exit(1)
}
guard export.status == .completed else {
    print("clip-turn: export \(export.status.rawValue): \(export.error.map { "\($0)" } ?? "no error")")
    exit(1)
}
print("clip-turn: \(Int(srcW))x\(Int(srcH)) (transform \(track.preferredTransform)) -> \(Int(width))x\(Int(height)), turned upright")
exit(0)
