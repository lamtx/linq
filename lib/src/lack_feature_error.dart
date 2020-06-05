class _LackFeatureException implements Exception {
    const _LackFeatureException(this.feature);

    final String feature;

    @override
    String toString() => "Feature is not supported because Dart lacks $feature";
}

const lacksReflection = _LackFeatureException("Reflection");