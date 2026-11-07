// Cartão de um contato na tela Alerta: nome, o que aconteceu com ele (SMS
// enviado, ligando, falhou...) e os botões manuais (WhatsApp, SMS, Ligar).
//
// O texto de cada situação fica aqui, em funções simples: o controlador só diz
// o que aconteceu (status e motivo), e a tela escolhe as palavras.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';

// Texto do estado de um envio, ex.: "SMS enviado" ou "Sem permissão para ligar".
String deliveryStatusText(AlertDelivery delivery) {
  final isCall = delivery.action == DeliveryAction.call;

  switch (delivery.status) {
    case DeliveryStatus.pending:
      return 'Aguardando';
    case DeliveryStatus.sending:
      return isCall ? 'Ligando…' : 'Enviando SMS…';
    case DeliveryStatus.sent:
      if (delivery.simulated) {
        return isCall ? 'Ligação simulada' : 'SMS simulado';
      }
      if (isCall) {
        return delivery.viaFallback ? 'Discador aberto' : 'Ligação iniciada';
      }
      return 'SMS enviado';
    case DeliveryStatus.failed:
      switch (delivery.failure) {
        case ActionFailure.permissionDenied:
          return isCall
              ? 'Sem permissão para ligar'
              : 'Sem permissão para enviar SMS';
        case ActionFailure.notAvailable:
          return isCall
              ? 'Este aparelho não consegue ligar'
              : 'Este aparelho não consegue enviar SMS';
        case ActionFailure.failed:
        case null:
          return isCall
              ? 'Não foi possível ligar'
              : 'Não foi possível enviar o SMS';
      }
  }
}

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.canCall,
    required this.foreground,
    required this.background,
    required this.accent,
    required this.onWhatsApp,
    required this.onSms,
    required this.onCall,
    required this.onRetry,
  });

  final AlertDelivery delivery;

  // O botão Ligar só existe no Modo Perigo.
  final bool canCall;

  // Cores vindas da tela Alerta (que muda de cor conforme o modo): texto e ícones,
  // fundo do cartão (escuro e translúcido, como os cartões de progresso) e a cor
  // do texto do botão branco "Tentar de novo".
  final Color foreground;
  final Color background;
  final Color accent;

  final VoidCallback onWhatsApp;
  final VoidCallback onSms;
  final VoidCallback onCall;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = delivery.status == DeliveryStatus.failed;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            delivery.contact.name,
            style: theme.textTheme.titleMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 4),
          // O estado aparece no ÍCONE (✓, aviso, relógio, girando), como nos
          // cartões de progresso; a cor é sempre a do texto da tela.
          Row(
            children: [
              if (delivery.status == DeliveryStatus.sending)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(
                  failed
                      ? LucideIcons.triangleAlert
                      : delivery.status == DeliveryStatus.sent
                      ? LucideIcons.check
                      : LucideIcons.clock,
                  size: 16,
                  color: foreground,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deliveryStatusText(delivery),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Wrap: os botões quebram de linha se não couberem lado a lado.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (failed)
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accent,
                  ),
                  child: const Text('Tentar de novo'),
                ),
              _ActionButton(
                label: 'WhatsApp',
                color: foreground,
                onPressed: onWhatsApp,
              ),
              _ActionButton(label: 'SMS', color: foreground, onPressed: onSms),
              if (canCall)
                _ActionButton(
                  label: 'Ligar',
                  color: foreground,
                  onPressed: onCall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Botão pequeno de texto, com área de toque de 48 de altura (acessibilidade).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: color,
      ),
      child: Text(label),
    );
  }
}
