import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'restedsettings.dart';
import 'restedrequest.dart';
import 'errors.dart';

class RestedJWT {
  Function _custom_JWT_verification;

  RestedJWT() {
    //_custom_JWT_verification = custom_JWT_verification;
  }

  void setCustomVerificationMethod(Function _method) {
    _custom_JWT_verification = _method;
  }

  bool custom_JWT_verification(String token) {
    return true;
  }

    Future<RestedRequest> validateAuth(RestedRequest request) async {
        try {
            if (request.unverified_access_token == null) {
                request.unverified_access_token = request.request.headers.value(HttpHeaders.authorizationHeader);

                // Checks that the authorization header is formatted correctly.
                if (request.unverified_access_token != null) {
                    List<String> authtype = request.unverified_access_token.split(' ');
                    List<String> valid_auths = ['BEARER', 'ACCESS_TOKEN', 'TOKEN', 'REFRESH_TOKEN', 'JWT'];
                    if (valid_auths.contains(authtype[0].toUpperCase())) {
                        request.unverified_access_token = authtype[1];
                    } else {
                        return await Errors.raise(request, 400);
                    }
                }
            } 

            if (request.unverified_access_token != null) {
                int verify_result = verify_token(request.unverified_access_token);
                if (verify_result != 401) {
                    request.access_token = request.unverified_access_token;
                    request.claims = RestedJWT.getClaims(request.access_token);
                } else {
                    return await Errors.raise(request, 401);
                }
            }

            return request;

        } catch(e) {
            return await Errors.raise(request, 500);
        }
    }

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