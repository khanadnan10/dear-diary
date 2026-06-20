# 05 — Security Architecture

## Threat Model

| Threat | Mitigation |
|--------|------------|
| Physical device access | Biometric lock + session timeout |
| Backup extraction (Android) | App-private storage + `android:allowBackup="false"` |
| Screenshot in app switcher | `FLAG_SECURE` on Android, equivalent on iOS |
| Key extraction from storage | flutter_secure_storage → Keychain/Keystore |
| Plaintext on disk | AES-256 encryption before any disk write |
| Audio in media gallery | `.nomedia` + app-private directory |
| Log leakage | Never log decrypted content or keys |

---

## Biometric Authentication

**Library:** `local_auth`

### Flow
```
App Launch
    │
    ▼
Is device enrolled with biometric/PIN?
    ├── No → Show "Please set up device lock" dialog → Exit app
    └── Yes
         │
         ▼
    Show biometric prompt
         ├── Success → Load app
         ├── Too many failures → Lockout handled by OS
         └── Cancelled → Stay on lock screen (do not exit app)
```

### Session Timeout
- Timer starts when app goes to background (`AppLifecycleState.paused`)
- On resume: if elapsed > `session_timeout_minutes` → re-authenticate
- Timer resets on every foreground interaction
- Default timeout: 5 minutes (configurable in settings)

### Implementation Notes
```dart
// Always use the biometricOnly: false fallback for PIN
final didAuthenticate = await localAuth.authenticate(
  localizedReason: 'Unlock your diary',
  options: const AuthenticationOptions(
    biometricOnly: false,  // Allow PIN fallback
    stickyAuth: true,      // Re-prompt if interrupted
  ),
);
```

---

## Text Encryption

**Algorithm:** AES-256-GCM  
**Key:** 256-bit, stored in secure storage  
**IV/Nonce:** Random 12-byte nonce, prepended to ciphertext  

```
Stored value = base64(nonce [12 bytes] + ciphertext + auth_tag [16 bytes])
```

### Encrypt
```dart
String encryptText(String plaintext, Uint8List key) {
  final nonce = generateSecureRandomBytes(12);
  final cipher = AesGcm.with256bits();
  final secretKey = SecretKey(key);
  final encrypted = await cipher.encrypt(
    plaintext.codeUnits,
    secretKey: secretKey,
    nonce: nonce,
  );
  final combined = Uint8List.fromList([...nonce, ...encrypted.concatenation()]);
  return base64.encode(combined);
}
```

**Library recommendation:** `cryptography` (dart) — pure Dart, audited, no native code dependency issues.

---

## Screenshot Prevention

**Android:**
```dart
// In MainActivity.kt
window.setFlags(
  WindowManager.LayoutParams.FLAG_SECURE,
  WindowManager.LayoutParams.FLAG_SECURE
)
```
Or via Flutter plugin: `flutter_windowmanager`

**iOS:** iOS blurs the app switcher thumbnail automatically when `FLAG_SECURE` equivalent is set; use `UIScreen.main.isCaptured` observation if additional control is needed.

---

## What Must NEVER Happen

- ❌ Never log decrypted entry text
- ❌ Never store the encryption key in `SharedPreferences`
- ❌ Never write plaintext to a temp file before encrypting
- ❌ Never expose raw audio paths in analytics or logs
- ❌ Never cache decrypted entries to disk
- ❌ Never allow the app to start without authentication on cold launch
