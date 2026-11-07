package br.academico.cesuca.ada

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Parte nativa do alerta (Fase 9): enviar SMS e ligar sem abrir outro app.
//
// O Dart chama estes métodos por um MethodChannel. Quem PEDE a permissão à
// usuária é o Dart (permission_handler); aqui só conferimos se ela existe.
//
// Privacidade: o telefone e o texto NUNCA são impressos (nada de Log aqui).
// Os erros voltam ao Dart só como um código curto:
//   permission_denied  -> falta a permissão
//   not_available      -> o aparelho não tem telefonia
//   invalid_args       -> chamada sem telefone ou sem texto
//   failed             -> qualquer outro problema
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> sendSms(call, result)
                    "call" -> placeCall(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasPermission(permission: String): Boolean =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun hasTelephony(): Boolean =
        packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)

    private fun sendSms(call: MethodCall, result: MethodChannel.Result) {
        val phone = call.argument<String>("phone")
        val text = call.argument<String>("text")
        if (phone.isNullOrEmpty() || text.isNullOrEmpty()) {
            result.error("invalid_args", null, null)
            return
        }
        if (!hasPermission(Manifest.permission.SEND_SMS)) {
            result.error("permission_denied", null, null)
            return
        }
        if (!hasTelephony()) {
            result.error("not_available", null, null)
            return
        }

        try {
            val smsManager: SmsManager? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    getSystemService(SmsManager::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getDefault()
                }
            if (smsManager == null) {
                result.error("not_available", null, null)
                return
            }

            // Um SMS comporta ~160 letras. Texto + link passa disso, então o
            // sistema divide em partes (o aparelho de quem recebe as junta).
            val parts = smsManager.divideMessage(text)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(phone, null, text, null, null)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("failed", null, null)
        }
    }

    private fun placeCall(call: MethodCall, result: MethodChannel.Result) {
        val phone = call.argument<String>("phone")
        if (phone.isNullOrEmpty()) {
            result.error("invalid_args", null, null)
            return
        }
        if (!hasPermission(Manifest.permission.CALL_PHONE)) {
            result.error("permission_denied", null, null)
            return
        }
        if (!hasTelephony()) {
            result.error("not_available", null, null)
            return
        }

        try {
            // ACTION_CALL liga direto (ACTION_DIAL só abriria o discador).
            val intent = Intent(Intent.ACTION_CALL, Uri.fromParts("tel", phone, null))
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("failed", null, null)
        }
    }

    companion object {
        const val CHANNEL = "br.academico.cesuca.ada/emergency"
    }
}
