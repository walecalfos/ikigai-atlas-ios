import SwiftUI
import IkigaiCore

/// Writes the atlas to temporary files for the share sheet.
@MainActor
enum Exporter {
    private static var baseName: String {
        "Ikigai Atlas"
    }

    static func markdownFile(for atlas: Atlas) -> URL? {
        let name = atlas.name.trimmed
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(name.isEmpty ? baseName : "\(baseName) – \(name)")
            .appendingPathExtension("md")
        do {
            try atlas.markdown().write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// A full backup that can be read back by the app.
    static func backupFile(for atlas: Atlas) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ikigai-atlas-backup")
            .appendingPathExtension("json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(atlas).write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Renders a printable view of the atlas into a single tall PDF page.
    static func pdfFile<Content: View>(named name: String, width: CGFloat = 612, @ViewBuilder content: () -> Content) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name).appendingPathExtension("pdf")
        let renderer = ImageRenderer(content: content().frame(width: width).environment(\.colorScheme, .light))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        var succeeded = false
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            draw(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            succeeded = true
        }
        return succeeded ? url : nil
    }
}
