//
//  SignUpView.swift
//  ws
//
//  Created by Yeonwoo Lee on 2023/07/16.
//

import SwiftUI

struct SignUpView: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                Text("가입하기")
                    .foregroundColor(.white)
                    .font(.body)
                    .fontWeight(.bold)
                Spacer()
            }
            .frame(height: 56)
            .padding(.horizontal, 16)
            .background(Color.black)
            .cornerRadius(16)
        }
        .padding()
    
        
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
