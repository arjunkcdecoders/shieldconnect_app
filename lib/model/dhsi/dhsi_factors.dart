import 'dhsi_factor_item.dart';

class DhsiFactors {
  final DhsiFactorItem? harmSignals;
  final DhsiFactorItem? behaviorChanges;
  final DhsiFactorItem? repeatExposure;
  final DhsiFactorItem? goodChoices;

  DhsiFactors({
    this.harmSignals,
    this.behaviorChanges,
    this.repeatExposure,
    this.goodChoices,
  });

  factory DhsiFactors.fromJson(Map<String, dynamic> json) {
    return DhsiFactors(
      harmSignals: json['harmSignals'] != null ? DhsiFactorItem.fromJson(json['harmSignals']) : null,
      behaviorChanges: json['behaviorChanges'] != null ? DhsiFactorItem.fromJson(json['behaviorChanges']) : null,
      repeatExposure: json['repeatExposure'] != null ? DhsiFactorItem.fromJson(json['repeatExposure']) : null,
      goodChoices: json['goodChoices'] != null ? DhsiFactorItem.fromJson(json['goodChoices']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'harmSignals': harmSignals?.toJson(),
      'behaviorChanges': behaviorChanges?.toJson(),
      'repeatExposure': repeatExposure?.toJson(),
      'goodChoices': goodChoices?.toJson(),
    };
  }
}
