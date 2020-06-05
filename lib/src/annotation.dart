class _KotlinMethodMarker {
    const _KotlinMethodMarker(this.whatType);

    final String whatType;
}

const Object implement = _KotlinMethodMarker("extension-method-implement");

const Object overridableExtension = _KotlinMethodMarker("overridable-extension-method");
