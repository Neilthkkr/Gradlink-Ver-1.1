//
//  Views+Extensions.swift
//  Unity
//
//  Created by Neil Thakkar on 02/09/2024.
//

import SwiftUI
extension View{
    func closedKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func disableWithOpacity(_ condition: Bool)->some View{
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    func hAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxWidth: .infinity,alignment: alignment)
        
    }
    
    func vAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxHeight: .infinity,alignment: alignment)
        
    }
    
    
    func border(_width: CGFloat,_ color: Color)->some View{
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color,lineWidth: _width)
            }
    }
    func fillView(_ color: Color)->some View{
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
            }
    }
}
