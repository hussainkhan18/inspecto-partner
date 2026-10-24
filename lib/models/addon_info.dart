enum AddonAccessState {
  unlocked,
  notPurchased,
  limitReached,
}

class AddonInfo {
  final bool allowed;
  final String status;
  final String? statusMessage;
  final bool isTrial;
  final String? tier;
  final String? addonName;
  final int limitQuantity;
  final int usedQuantity;
  final int remainingQuantity;
  final String? expiresAt;

  const AddonInfo({
    required this.allowed,
    required this.status,
    this.statusMessage,
    required this.isTrial,
    this.tier,
    this.addonName,
    required this.limitQuantity,
    required this.usedQuantity,
    required this.remainingQuantity,
    this.expiresAt,
  });

  factory AddonInfo.fromJson(Map<String, dynamic> json) {
    return AddonInfo(
      allowed: json['allowed'] == true,
      status: json['status']?.toString() ?? 'NOT_PURCHASED',
      statusMessage: json['status_message']?.toString(),
      isTrial: json['is_trial'] == true,
      tier: json['tier']?.toString(),
      addonName: json['addon_name']?.toString(),
      limitQuantity:
          int.tryParse(json['limit_quantity']?.toString() ?? '') ?? 0,
      usedQuantity: int.tryParse(json['used_quantity']?.toString() ?? '') ?? 0,
      remainingQuantity:
          int.tryParse(json['remaining_quantity']?.toString() ?? '') ?? 0,
      expiresAt: json['expires_at']?.toString(),
    );
  }

  /// Safe fallback used when an addon key is missing from the response
  /// defaults to locked, never breaks the UI.

  factory AddonInfo.locked() => const AddonInfo(
        allowed: false,
        status: 'NOT_PURCHASED',
        isTrial: false,
        limitQuantity: 0,
        usedQuantity: 0,
        remainingQuantity: 0,
      );

  AddonAccessState get accessState {
    if (allowed) {
      if (limitQuantity > 0 && remainingQuantity <= 0) {
        return AddonAccessState.limitReached;
      }

      return AddonAccessState.unlocked;
    }

    if (status.toUpperCase() == 'NOT_PURCHASED') {
      return AddonAccessState.notPurchased;
    }

    if (limitQuantity > 0 && remainingQuantity <= 0) {
      return AddonAccessState.limitReached;
    }

    return AddonAccessState.notPurchased;
  }

  bool get isLocked => accessState != AddonAccessState.unlocked;

  bool get hasUsageLimit => limitQuantity > 0;

  String get usageLabel => '$remainingQuantity/$limitQuantity';

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        'status': status,
        'status_message': statusMessage,
        'is_trial': isTrial,
        'tier': tier,
        'addon_name': addonName,
        'limit_quantity': limitQuantity,
        'used_quantity': usedQuantity,
        'remaining_quantity': remainingQuantity,
        'expires_at': expiresAt,
      };
}
