import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zenly_like/components/auth_modal/components/close_modal.dart';
import 'package:zenly_like/components/auth_modal/components/auth_text_form_field.dart';
import 'package:zenly_like/components/auth_modal/components/submit_button.dart';
import 'package:zenly_like/components/auth_modal/components/sign_in_form.dart';
import 'package:zenly_like/components/auth_modal/components/sign_up_form.dart';

enum AuthModalType {
   signIn,
   signUp;
 }      

class AuthModal extends StatefulWidget {
    const AuthModal({super.key});

    @override
    State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  AuthModalType modalType = AuthModalType.signIn;
  String buttonLabel = '新規登録へ';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => unFocus(context),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            height: MediaQuery.of(context).size.height * 0.95,
            child: SingleChildScrollView(
                child: Column(
                    children: [
                        const CloseModalButton(),

                        modalType == AuthModalType.signIn
                            ? const SignInForm()
                            : const SignUpForm(),

                        TextButton(
                            onPressed: switchModalType,
                            child: Text(buttonLabel),
                        ),
                        const SizedBox(height:300),
                    ],
                ),
            ),
        ),    
    );
  }

    void unFocus(BuildContext context) {
        final FocusScopeNode currentScope = FocusScope.of(context);
        if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
        FocusManager.instance.primaryFocus!.unfocus();
        }
    }



    void switchModalType() {
        setState(() {
        modalType = modalType == AuthModalType.signIn
            ? AuthModalType.signUp
            : AuthModalType.signIn;

        buttonLabel = modalType == AuthModalType.signIn ? '新規登録へ' : 'サインインへ';
        });
    }
}