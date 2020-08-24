//
//  ImageView.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/// Conform to equatable to prevent refreshing the static image
/// https://swiftui-lab.com/equatableview/

// Mark:- ImageView
struct ImageView: View, Equatable {
    var printer: DeallocPrinter
    let id = UUID()
    let url: String
    @ObservedObject var viewModel : NetworkCacheViewModel
    
    init(url: String, shipViewModel: ShipViewModel, label: String = "") {
        printer = DeallocPrinter("PAKImageView \(id)")
        
        // Images Support
        self.viewModel = NetworkCacheViewModel(moc: shipViewModel.moc)
        self.url = url
        print("PAKImageView.init(url: \(url)) id = \(id)")
        self.viewModel.loadImage(url: url)
    }
    
                                                            
    /// If the NetworkCacheViewModel adopts INetworkCacheViewModel, I get the following error
    /// Thread 1: EXC_BAD_ACCESS (code=EXC_I386_GPFLT) when referencing self.viewModel.image.
    /// It works if INetworkCacheViewModel is not adopted
    var body: some View {
        print("body computed for ImageView.url = \(url)")
        
        return Image(uiImage: self.viewModel.image) // Thread Error
            .resizable()
            .onAppear {
                print("\(self.id) PAKImageView Image.onAppear loadImage url: \(self.url)")
            }
    }
    
    static func == (lhs: ImageView, rhs: ImageView) -> Bool {
        return lhs.url == rhs.url
    }
}


