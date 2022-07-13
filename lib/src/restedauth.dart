class RestedJWT {
  RestedJWT();

  String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(33) + 89;
    });

    return new String.fromCharCodes(codeUnits);
  }

  JwtClaim _generateClaimset({Map additional_claims = null}) {
    // Horrible workaround to Dart Map -> Json problems, ref: https://github.com/flutter/flutter/issues/16589
    final cleanMap = jsonDecode(jsonEncode(additional_claims));

    final claimSet = new JwtClaim(
        issuer: rsettings.getVariable('jwt_issuer'),
        //subject: 'some_subject',
        //audience: ['client1.example.com', 'client2.example.com'],
        jwtId: _randomString(32),
        otherClaims: cleanMap,
        maxAge: Duration(minutes: rsettings.getVariable('jwt_duration')));
    return claimSet;
  }

  Map generate_token({Map additional_claims}) {
    JwtClaim claim_set = _generateClaimset(additional_claims: additional_claims);
    String token = issueJwtHS256(claim_set, rsettings.getVariable('jwt_key'));
    Map tokenmap = { "access_token": token };
    return tokenmap;
  }

  int verify_token(String token) {
    try {
      final JwtClaim decClaimSet = verifyJwtHS256Signature(token, rsettings.getVariable('jwt_key'));
      DateTime issued_at = DateTime.parse(decClaimSet['iat'].toString());
      DateTime expires = DateTime.parse(decClaimSet['exp'].toString());
      Duration duration = DateTime.now().difference(issued_at);
      if (duration.inMinutes >= rsettings.getVariable('jwt_duration')) {
        return (401);
      } else {
        if (_custom_JWT_verification(token)) {
          return (200); // "OK"
        } else {
          return (401);
        }
      }
    } on JwtException {
      return (401); // "Unauthorized"
    }
  }

  static String getClaim(String token, String key) {
    try {
      final JwtClaim decClaimSet = verifyJwtHS256Signature(token, rsettings.getVariable('jwt_key'));
      if(decClaimSet.containsKey(key)) {
        return decClaimSet[key];
      } else {
        return null;
      }
    } catch(e) {
      print("error: " + e.toString());
      return null;
    }
  }

  static Map<String, dynamic> getClaims(String token) {
    Map<String, dynamic> claims = {};
    try {
      final JwtClaim decClaimSet = verifyJwtHS256Signature(token, rsettings.getVariable('jwt_key'));        
        for(String name in decClaimSet.claimNames(includeRegisteredClaims: false)) {
          claims[name] = decClaimSet[name];
        }
      }
     catch(e) {
      print("error extracting claims from JWT: " + e.toString());
    }
    return claims;
  }
}