//
//  ContentView.swift
//  ws
//
//  Created by Yeonwoo Lee on 2023/07/16.
//

import SwiftUI
import AuthenticationServices
import Amplify
import AWSCognitoAuthPlugin


struct ContentView: View {
    
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        VStack {
            
                        Spacer()
            
                        SignInWithAppleButton(
                            onRequest: configureRequest,
                            onCompletion: handleResult
                        )
                        .frame(maxWidth: 300, maxHeight: 45)
            
                        Spacer()
            
            
                        Button(action: {
                            Task{
                                await signOutLocally2()
                            }
            
            
                        }) {
                            HStack {
                                Spacer()
                                Text("로그아웃")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(16)
                        }
            
                        Button(action: {
                            Task{
                                await checkLoginStatus()
                            }
            
                        }) {
                            HStack {
                                Spacer()
                                Text("로그인/로그아웃 체크")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(16)
                        }
            
            
            //테스트 뷰
//            if isLoggedIn {
//                // 로그인된 상태의 뷰 표시
//                Text("사용자가 로그인되어 있습니다.")
//                Button(action: {
//                    Task{
//                        await signOutLocally()
//                    }
//
//
//                }) {
//                    HStack {
//                        Spacer()
//                        Text("로그아웃")
//                            .foregroundColor(.white)
//                            .font(.body)
//                            .fontWeight(.bold)
//                        Spacer()
//                    }
//                    .frame(height: 56)
//                    .background(Color.black)
//                    .cornerRadius(16)
//                }
//            } else {
//                // 로그아웃된 상태의 뷰 표시
//                SignInWithAppleButton(
//                    onRequest: configureRequest,
//                    onCompletion: handleResult
//                )
//                .frame(maxWidth: 300, maxHeight: 45)
//            }
//
            
        }
        .padding()
        .onAppear {
            Task{
                await checkLoginStatus()
            }
        }
    }
    
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.email]
    }
    
    func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityToken = credential.identityToken,
                // 자격증명에서 계정 정보 가져오기 (예시로 credential에 포함되어 있다고 가정)
                let email = credential.email,
                let authorizationCode = String(data: credential.authorizationCode!, encoding: .utf8)
                    
                    
            else { return }
            
            

            
            // 프린트
            print("Email:", email)
            print("Authorization Code:", authorizationCode)
            
            // 옵셔널 바인딩이 필요없는
                        let userIdentifier = credential.user
            let password = generateRandomPassword(length: 12)
            
            
            // 자격증명
            self.federateToIdentityPools(with: identityToken, credential: credential)
            
            
            Task{
                await signUp(username: userIdentifier, password: password, email: email)
            }
            
            // 로그인 시험
//            Task{
//                await signIn(username: email, password: authorizationCode)
//            }
            
        case .failure(let error):
            print(error)
        }
    }
    
    func federateToIdentityPools(with token: Data, credential: ASAuthorizationAppleIDCredential) {
        guard
            let tokenString = String(data: token, encoding: .utf8),
            let plugin = try? Amplify.Auth.getPlugin(for: "awsCognitoAuthPlugin") as? AWSCognitoAuthPlugin
        else { return }
        
        Task {
            do {
                let result = try await plugin.federateToIdentityPool(
                    withProviderToken: tokenString,
                    for: .apple
                )
                print("Successfully federated user to identity pool with result:", result)
                
            }
            
            catch {
                print("Failed to federate to identity pool with error:", error)
            }
        }
    }
    
    func signUp(username: String, password: String?, email: String) async {
        
        // Amplify를 사용하여 사용자 등록
        let userAttributes = [
            AuthUserAttribute(.email, value: email),
            AuthUserAttribute(.name, value: username)
        ]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        
        
        
        do {
            let signUpResult = try await Amplify.Auth.signUp(
                // 이건 그저 Cognito 사용자용이다.
                username: email,
                password: password,
                // 이건 애플에서 받아온 정보
                options: options)
            print("Successfully signed up user:", signUpResult)
            
            
        } catch let error as AuthError {
            // AuthError가 발생한 경우, 해당 오류를 출력합니다.
            print("사용자 등록 중 오류 발생: \(error)")
        } catch {
            print("Failed to sign up user with error:", error)
        }
        
        print("확인")
    }
    
    //테스트
    func signOutLocally2() async {
        do {
            // AWSCognitoAuthPlugin 얻기
            guard let plugin = try? Amplify.Auth.getPlugin(for: "awsCognitoAuthPlugin") as? AWSCognitoAuthPlugin else {
                print("Failed to get AWSCognitoAuthPlugin")
                return
            }

            // Federation을 제거
            try await plugin.clearFederationToIdentityPool()

            // 로그아웃
            let result = await Amplify.Auth.signOut()

            guard let signOutResult = result as? AWSCognitoSignOutResult else {
                print("Signout failed")
                return
            }

            print("Local signout successful: \(signOutResult.signedOutLocally)")
            switch signOutResult {
            case .complete:
                // Sign Out completed fully and without errors.
                print("Signed out successfully")

            case let .partial(revokeTokenError, globalSignOutError, hostedUIError):
                // Sign Out completed with some errors. User is signed out of the device.
                if let hostedUIError = hostedUIError {
                    print("HostedUI error  \(String(describing: hostedUIError))")
                }

                if let globalSignOutError = globalSignOutError {
                    print("GlobalSignOut error  \(String(describing: globalSignOutError))")
                }

                if let revokeTokenError = revokeTokenError {
                    print("Revoke token error  \(String(describing: revokeTokenError))")
                }

            case .failed(let error):
                // Sign Out failed with an exception, leaving the user signed in.
                print("SignOut failed with \(error)")
            }
        } catch {
            print("Failed to clear federation or sign out with error: \(error)")
        }
    }

    
    
    // 로그아웃
    func signOutLocally() async {
        
        let result = await Amplify.Auth.signOut()
        guard let signOutResult = result as? AWSCognitoSignOutResult
        else {
            print("Signout failed")
            return
        }
        
        print("Local signout successful: \(signOutResult.signedOutLocally)")
        switch signOutResult {
        case .complete:
            // Sign Out completed fully and without errors.
            print("Signed out successfully")
            
        case let .partial(revokeTokenError, globalSignOutError, hostedUIError):
            // Sign Out completed with some errors. User is signed out of the device.
            
            if let hostedUIError = hostedUIError {
                print("HostedUI error  \(String(describing: hostedUIError))")
            }
            
            if let globalSignOutError = globalSignOutError {
                // Optional: Use escape hatch to retry revocation of globalSignOutError.accessToken.
                print("GlobalSignOut error  \(String(describing: globalSignOutError))")
            }
            
            if let revokeTokenError = revokeTokenError {
                // Optional: Use escape hatch to retry revocation of revokeTokenError.accessToken.
                print("Revoke token error  \(String(describing: revokeTokenError))")
            }
            
        case .failed(let error):
            // Sign Out failed with an exception, leaving the user signed in.
            print("SignOut failed with \(error)")
        }
    }
    
    
    
    
    
    //임시
    func signIn(username: String, password: String) async {
        do {
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password
            )
            if signInResult.isSignedIn {
                print("Sign in succeeded")
            }
        } catch let error as AuthError {
            print("Sign in failed \(error)")
        } catch {
            print("Unexpected error: \(error)")
        }
    }
    
    func checkLoginStatus() async {
        do{
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                // 로그인된 상태인 경우
                print("사용자는 현재 로그인되어 있습니다.")
            } else {
                // 로그아웃된 상태인 경우
                print("사용자는 현재 로그아웃된 상태입니다.")
            }
        } catch {
            
            print("로그인 상태 확인에 실패했습니다. 오류: \(error)")
        }
    }
    
    
}

// 랜덤 비밀번호
public func generateRandomPassword(length: Int) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in characters.randomElement()! })
}

// 로그인, 로그아웃 체크
//func checkLoginStatus() async {
//        do {
//            let session = try await Amplify.Auth.fetchAuthSession()
//            // 사용자가 로그인된 상태인지 여부 확인
//            if session.isSignedIn {
//                print("사용자는 현재 로그인되어 있습니다.")
//                // 여기서 로그인된 사용자의 정보를 사용할 수 있습니다.
//            } else {
//                print("사용자는 현재 로그아웃된 상태입니다.")
//            }
//        } catch {
//            print("로그인 상태 확인에 실패했습니다. 오류: \(error)")
//        }
//}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
