//
//  FlowLayout.swift
//  LA Hacks
//
//  Star Hop! Simple flow layout (for connected-stars chips).
//  Ported from project/galaxy-ui.jsx.
//

import SwiftUI

// MARK: - Simple flow layout (for connected-stars chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, totalH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW {
                x = 0; y += rowH + spacing; rowH = 0
            }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            totalH = y + rowH
        }
        return CGSize(width: maxW.isFinite ? maxW : x, height: totalH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX {
                x = bounds.minX; y += rowH + spacing; rowH = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}
