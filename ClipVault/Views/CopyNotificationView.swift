//
//  CopyNotificationView.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import SwiftUI

struct CopyNotificationView: View {
    @Binding var isVisible: Bool
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
    }
}

struct CopyNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        CopyNotificationView(isVisible: .constant(true), message: "Copied!")
            .frame(width: 300, height: 200)
    }
}
