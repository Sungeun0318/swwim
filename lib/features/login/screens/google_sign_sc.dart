import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 구글 로그인 메서드
  Future<UserCredential?> signInWithGoogle() async {
    // 1. 구글 계정 선택 팝업 표시
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // 사용자가 로그인 취소한 경우
      return null;
    }

    // 2. 선택한 계정의 인증 정보를 가져옵니다.
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Firebase에서 사용할 자격증명(credential) 생성
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. 해당 credential로 Firebase에 로그인 시도
    return await _auth.signInWithCredential(credential);
  }

  /// 구글 로그아웃 메서드
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
