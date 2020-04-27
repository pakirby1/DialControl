//
//  TextView.swift
//  DialControl
//
//  Created by Phil Kirby on 4/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct TextView: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    var placeholderText: String = "Text View"
    @Binding var text: String
    @EnvironmentObject var textViewObservable: TextViewObservable
    
    func makeUIView(context: UIViewRepresentableContext<TextView>) -> UITextView {
        let textView = UITextView()
        
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.font = UIFont.systemFont(ofSize: 17)
        
        textView.text = placeholderText
        textView.textColor = .placeholderText
        
        self.textViewObservable.height = textView.contentSize.height
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<TextView>) {
        
        if text != "" || uiView.textColor == .label {
            uiView.text = text
            uiView.textColor = .label
        }
        
        uiView.delegate = context.coordinator
    }
    
    func frame(numLines: CGFloat) -> some View {
        let height = UIFont
            .systemFont(ofSize: 17)
            .lineHeight * numLines
        
        return self.frame(height: height)
    }
    
    func makeCoordinator() -> TextView.Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView
        
        init(_ parent: TextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            self.parent.textViewObservable.height = textView.contentSize.height
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text == "" {
                textView.text = parent.placeholderText
                textView.textColor = .placeholderText
            }
        }
    }
}

class TextViewObservable: ObservableObject {
    @Published var height: CGFloat = 0
}
