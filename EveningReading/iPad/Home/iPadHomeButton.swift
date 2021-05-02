//
//  iPadHomeButton.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import SwiftUI

struct iPadHomeButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var title: String
    @Binding var imageName: String
    @Binding var buttonBackground: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(self.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .lineLimit(1)
            }
            .frame(alignment: .leading)
            .padding(20)
            Spacer()
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .imageScale(.large)
                .foregroundColor(.black)
                .frame(width: 36)
                .padding(.trailing, 20)
        }
        .background(buttonBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 10)
    }
}

struct iPadHomeButton_Previews: PreviewProvider {
    static var previews: some View {
        iPadHomeButton(title: .constant("Chaty"), imageName: .constant("glyphicons-basic-238-chat-message"), buttonBackground: .constant(Color("HomeButtonChat")))
    }
}
