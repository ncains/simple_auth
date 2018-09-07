import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_auth/simple_auth.dart' as simpleAuth;
import 'package:simple_auth_flutter/basic_login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as storage;


class SimpleAuthFlutterPersistant implements simpleAuth.AuthStorage {
  static storage.FlutterSecureStorage _storage = new storage.FlutterSecureStorage();
  static const MethodChannel _channel =
      const MethodChannel('simple_auth_flutter/showAuthenticator');
  static const EventChannel _eventChannel =
      const EventChannel('simple_auth_flutter/urlChanged');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod("getPlatformVersion");
    return version;
  }

  static Map<String, simpleAuth.WebAuthenticator> authenticators = {};
  static Future showAuthenticator(
      simpleAuth.WebAuthenticator authenticator) async {
    var initialUrl = await authenticator.getInitialUrl();

    authenticators[authenticator.identifier] = authenticator;

    String url = await _channel.invokeMethod("showAuthenticator", {
      "initialUrl": initialUrl.toString(),
      "identifier": authenticator.identifier,
      "title": authenticator.title,
      "allowsCancel": authenticator.allowsCancel.toString(),
      "redirectUrl": authenticator.redirectUrl,
      "useEmbeddedBrowser": authenticator.useEmbeddedBrowser.toString()
    });
    if (url == "cancel") {
      authenticator.cancel();
      return;
    }
  }

  static Future showBasicAuthenticator(
      simpleAuth.BasicAuthAuthenticator authenticator) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => new BasicLoginPage(authenticator));
  }

  static SimpleAuthFlutterPersistant _shared = new SimpleAuthFlutterPersistant();
  static BuildContext context;
  static void init(BuildContext context) {
    SimpleAuthFlutterPersistant.context = context;
    simpleAuth.AuthStorage.shared = _shared;
    simpleAuth.OAuthApi.sharedShowAuthenticator = showAuthenticator;
    simpleAuth.BasicAuthApi.sharedShowAuthenticator = showBasicAuthenticator;
    onUrlChanged.listen((UrlChange change) {
      var authenticator = authenticators[change.identifier];
      if (change.url == "canceled") {
        authenticator.cancel();
        return;
      } else if (change.url == "error") {
        authenticator.onError(change.description);
        return;
      }

      var uri = Uri.tryParse(change.url);
      if (authenticator.checkUrl(uri)) {
        _channel.invokeMethod("completed", {"identifier": change.identifier});
      } else if (change.foreComplete) {
        authenticator.onError("Unable to get an AuthToken from the server");
      }
    });
  }

  static Stream<UrlChange> _onUrlChanged;
  static Stream<UrlChange> get onUrlChanged {
    if (_onUrlChanged == null) {
      _onUrlChanged = _eventChannel.receiveBroadcastStream().map(
          (dynamic event) => new UrlChange(
              event["identifier"],
              event["url"],
              event["forceComplete"].toString().toLowerCase() == "true",
              event["description"]));
    }
    return _onUrlChanged;
  }

  @override
  Future<String> read({String key}) async {
    String value = await _storage.read(key: key,); 
    return value;
  }

  @override
  Future<void> write({String key, String value}) async {
    try {
        await _storage.write(key: key,value: value); 
    } 
    catch (e) {
      throw new Exception("Error saving data to Flutter AuthStorage");
    }
  }
}

class UrlChange {
  String url;
  String identifier;
  bool foreComplete;
  String description;
  UrlChange(this.identifier, this.url, this.foreComplete, this.description);
}
