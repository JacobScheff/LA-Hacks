//
//  DocumentScannerView.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/25/26.
//
// Follows Apple's "Extract Text from Images" tutorial pattern.
// iOS 18 Vision APIs: RecognizeTextRequest + ImageRequestHandler (async/await)
// Sources: UIImagePickerController (camera + library) + VNDocumentCameraViewController

import UIKit
import Vision        // iOS 18: RecognizeTextRequest, ImageRequestHandler
import VisionKit     // VNDocumentCameraViewController

// MARK: - DocumentScannerViewController

class DocumentScannerViewController: UIViewController {

    // MARK: UI

    private lazy var cameraButton   = pill("📷  Camera",          tint: .systemBlue)
    private lazy var libraryButton  = pill("🖼  Photo Library",   tint: .systemGreen)
    private lazy var documentButton = pill("📄  Scan Document",   tint: .systemPurple)

    private lazy var imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var statusLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.text = "Choose a source to begin"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 12
        tv.text = "Extracted text will appear here…"
        tv.textColor = .placeholderText
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var doneButton = pill("✅  Save to Nova's Memory", tint: .systemIndigo)

    private lazy var spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    /// The most recently extracted chunk — saved to MemoryStore on "Save" tap.
    private var pendingChunk: CurriculumChunk?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan Curriculum"
        view.backgroundColor = .systemBackground
        buildLayout()
        cameraButton.addTarget(self, action: #selector(tapCamera), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(tapLibrary), for: .touchUpInside)
        documentButton.addTarget(self, action: #selector(tapDocument), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(tapSave), for: .touchUpInside)
        doneButton.isEnabled = false
    }

    // MARK: - Source actions

    @objc private func tapCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert("Camera not available on this device."); return
        }
        present(makePicker(source: .camera), animated: true)
    }

    @objc private func tapLibrary() {
        present(makePicker(source: .photoLibrary), animated: true)
    }

    @objc private func tapDocument() {
        guard VNDocumentCameraViewController.isSupported else {
            showAlert("Document scanner not supported."); return
        }
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        present(vc, animated: true)
    }

    private func makePicker(source: UIImagePickerController.SourceType) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = source
        p.allowsEditing = false
        p.delegate = self
        return p
    }

    // MARK: - Save to MemoryStore

    @objc private func tapSave() {
        guard let chunk = pendingChunk else { return }

        // Persist to curriculum_chunks.json + annotate memory.md
        MemoryStore.shared.saveCurriculumScan(chunk)

        setStatus("✅ Saved \(chunk.ragChunks().count) RAG windows to Nova's memory!")
        doneButton.isEnabled = false
        pendingChunk = nil
    }

    // MARK: - Vision OCR  (Apple "Extract Text from Images" tutorial pattern)
    //
    //  var request = RecognizeTextRequest()          ← new iOS 18 struct API
    //  let handler = ImageRequestHandler(cgImage)    ← replaces VNImageRequestHandler
    //  let obs     = try await handler.perform(request)  ← async, no callbacks

    func extractText(from image: UIImage, source: String) {
        imageView.image = image
        textView.text = ""
        textView.textColor = .label
        doneButton.isEnabled = false
        pendingChunk = nil
        setStatus("Running Vision OCR…")
        spinner.startAnimating()

        Task {
            await recognizeText(in: image, source: source)
        }
    }

    private func recognizeText(in image: UIImage, source: String) async {
        guard let cgImage = image.cgImage else {
            await MainActor.run { spinner.stopAnimating(); setStatus("❌ Couldn't read image data.") }
            return
        }

        do {
            // ── Apple tutorial steps ──────────────────────────────────────────
            var request = RecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = [Locale.Language(identifier: "en-US")]

            let handler = ImageRequestHandler(cgImage)
            let observations = try await handler.perform(request)

            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = lines.joined(separator: "\n")
            // ─────────────────────────────────────────────────────────────────

            let chunk = CurriculumChunk(
                id: UUID(),
                rawText: fullText,
                source: source,
                timestamp: Date()
            )

            await MainActor.run {
                spinner.stopAnimating()
                pendingChunk = chunk
                textView.text = fullText.isEmpty ? "(No text detected)" : fullText
                doneButton.isEnabled = !fullText.isEmpty
                setStatus("✅ \(lines.count) lines · \(chunk.wordCount) words · \(chunk.ragChunks().count) RAG windows ready — tap Save to add to Nova's memory")
            }

        } catch {
            await MainActor.run {
                spinner.stopAnimating()
                setStatus("❌ OCR failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Multi-page document (VNDocumentCameraViewController)

    private func processScannedDocument(_ scan: VNDocumentCameraScan) {
        setStatus("Processing \(scan.pageCount) page(s)…")
        spinner.startAnimating()

        Task {
            var allLines: [String] = []
            for pageIndex in 0..<scan.pageCount {
                let pageImage = scan.imageOfPage(at: pageIndex)
                guard let cg = pageImage.cgImage else { continue }

                var request = RecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = ImageRequestHandler(cg)
                if let obs = try? await handler.perform(request) {
                    allLines.append("--- Page \(pageIndex + 1) ---")
                    allLines.append(contentsOf: obs.compactMap { $0.topCandidates(1).first?.string })
                }
            }

            let fullText = allLines.joined(separator: "\n")
            let chunk = CurriculumChunk(
                id: UUID(),
                rawText: fullText,
                source: "DocumentScan(\(scan.pageCount)p)",
                timestamp: Date()
            )

            await MainActor.run {
                spinner.stopAnimating()
                imageView.image = scan.imageOfPage(at: 0)
                textView.text = fullText
                pendingChunk = chunk
                doneButton.isEnabled = !fullText.isEmpty
                setStatus("✅ \(scan.pageCount) pages · \(chunk.wordCount) words · \(chunk.ragChunks().count) RAG windows ready — tap Save")
            }
        }
    }

    // MARK: - Helpers

    private func setStatus(_ msg: String) {
        DispatchQueue.main.async { self.statusLabel.text = msg }
    }

    private func showAlert(_ msg: String) {
        let ac = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        ac.addAction(.init(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func pill(_ title: String, tint: UIColor) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.baseBackgroundColor = tint
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .medium
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var a = $0; a.font = .systemFont(ofSize: 16, weight: .semibold); return a
        }
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    // MARK: - Layout

    private func buildLayout() {
        let srcStack = UIStackView(arrangedSubviews: [cameraButton, libraryButton, documentButton])
        srcStack.axis = .vertical
        srcStack.spacing = 10
        srcStack.translatesAutoresizingMaskIntoConstraints = false

        [srcStack, imageView, statusLabel, textView, doneButton, spinner].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            srcStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            srcStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            srcStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            imageView.topAnchor.constraint(equalTo: srcStack.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 180),

            statusLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -12),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 50),

            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
        [cameraButton, libraryButton, documentButton].forEach {
            $0.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension DocumentScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else {
            setStatus("❌ Could not load image."); return
        }
        let src = picker.sourceType == .camera ? "Camera" : "PhotoLibrary"
        extractText(from: image, source: src)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension DocumentScannerViewController: VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true)
        processScannedDocument(scan)
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true)
        setStatus("❌ Scan error: \(error.localizedDescription)")
    }
}
