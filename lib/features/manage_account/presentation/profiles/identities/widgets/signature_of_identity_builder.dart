import 'package:flutter/cupertino.dart';
import 'package:jmap_dart_client/jmap/identities/identity.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/profiles/identities/widgets/signature_builder.dart';

class SignatureOfIdentityBuilder extends StatelessWidget {

  const SignatureOfIdentityBuilder({Key? key, required this.identity}) : super(key: key);

  final Identity identity;

  @override
  Widget build(BuildContext context) {
    return SignatureBuilder(
      height: 256,
      htmlSignature: identity.htmlSignature,
      textSignature: identity.textSignature
    );
  }
}

