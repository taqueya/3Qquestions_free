import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
// import '../../ui/screens/home_screen.dart'; // Commented out likely broken import 

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // ログインモードか、登録モードか
  bool _isLoading = false;

  // 認証処理
  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        // ログイン処理
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // 新規登録処理
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登録完了！確認メールをチェックしてください')),
          );
        }
      }
      
      // 成功したらホーム画面へ遷移など（AuthGateで監視していれば自動遷移する場合もあります）
      
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予期せぬエラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'ログイン' : '新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(_isLogin ? 'ログイン' : '登録'),
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin ? 'アカウントをお持ちでない方は登録へ' : 'ログインへ戻る'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Googleでログイン'),
              onPressed: _googleSignIn,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _googleSignIn() async {
    try {
      setState(() => _isLoading = true);
      
      // NOTE: You need to set these keys or configure them in platform specific files
      // For Android, just SHA-1 in Cloud Console + Web Client ID logic usually works.
      const webClientId = '98809686126-fsd4f6o8f6185opt6cdg53pba3996rpt.apps.googleusercontent.com'; 
      const iosClientId = '98809686126-fsd4f6o8f6185opt6cdg53pba3996rpt.apps.googleusercontent.com';

      // NOTE: serverClientId is necessary for Android to get the ID Token for Supabase.
      // clientId should be null on Android (it uses the SHA-1 registered in Cloud Console).
      // clientId IS required on iOS.
      
      String? clientId;
      String? serverClientId;
      
      if (kIsWeb) {
        clientId = webClientId;
        serverClientId = null;
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        clientId = iosClientId;
        serverClientId = webClientId;
      } else {
        // Android and others
        clientId = null;
        serverClientId = webClientId;
       }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      
      // Ensure previous sign out to force account picker
      // await googleSignIn.signOut(); 

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;
      
      if (googleAuth == null) {
        return; // Cancelled
      }
      
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      if (mounted) {
         context.go('/');
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Login Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}