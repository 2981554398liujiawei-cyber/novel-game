extends RefCounted

## Small offline JSON Schema validator for the subset used by this project.
## It deliberately has no network resolution or remote $ref support.


func validate(value: Variant, schema: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    _validate_value(value, schema, "$", errors)
    return errors


func _validate_value(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
    if schema.has("type") and not _matches_declared_type(value, schema["type"]):
        errors.append("%s: expected type %s" % [path, str(schema["type"])])
        return

    if schema.has("const") and value != schema["const"]:
        errors.append("%s: value must equal %s" % [path, str(schema["const"])])

    if schema.has("enum") and value not in schema["enum"]:
        errors.append("%s: value is not in the allowed set" % path)

    if value is Dictionary:
        _validate_dictionary(value, schema, path, errors)
    elif value is Array:
        _validate_array(value, schema, path, errors)
    elif value is String:
        _validate_string(value, schema, path, errors)
    elif value is int or value is float:
        _validate_number(value, schema, path, errors)

    if schema.has("allOf"):
        for child_schema: Variant in schema["allOf"]:
            if child_schema is Dictionary:
                _validate_value(value, child_schema, path, errors)

    if schema.has("if") and schema["if"] is Dictionary:
        var condition_errors: Array[String] = []
        _validate_value(value, schema["if"], path, condition_errors)
        if condition_errors.is_empty() and schema.get("then") is Dictionary:
            _validate_value(value, schema["then"], path, errors)
        elif not condition_errors.is_empty() and schema.get("else") is Dictionary:
            _validate_value(value, schema["else"], path, errors)


func _validate_dictionary(value: Dictionary, schema: Dictionary, path: String, errors: Array[String]) -> void:
    for required_key: Variant in schema.get("required", []):
        if not value.has(required_key):
            errors.append("%s: missing required property '%s'" % [path, str(required_key)])

    var properties: Dictionary = schema.get("properties", {})
    var additional_properties: Variant = schema.get("additionalProperties", true)
    for key: Variant in value.keys():
        if properties.has(key) and properties[key] is Dictionary:
            _validate_value(value[key], properties[key], "%s.%s" % [path, str(key)], errors)
        elif additional_properties is bool and not additional_properties:
            errors.append("%s: unknown property '%s'" % [path, str(key)])
        elif additional_properties is Dictionary:
            _validate_value(value[key], additional_properties, "%s.%s" % [path, str(key)], errors)

    if schema.has("minProperties") and value.size() < int(schema["minProperties"]):
        errors.append("%s: expected at least %d properties" % [path, int(schema["minProperties"])])


func _validate_array(value: Array, schema: Dictionary, path: String, errors: Array[String]) -> void:
    if schema.has("minItems") and value.size() < int(schema["minItems"]):
        errors.append("%s: expected at least %d items" % [path, int(schema["minItems"])])
    if schema.has("maxItems") and value.size() > int(schema["maxItems"]):
        errors.append("%s: expected at most %d items" % [path, int(schema["maxItems"])])
    if schema.get("uniqueItems", false):
        for index: int in range(value.size()):
            if value[index] in value.slice(0, index):
                errors.append("%s[%d]: duplicate array item" % [path, index])
    if schema.get("items") is Dictionary:
        for index: int in range(value.size()):
            _validate_value(value[index], schema["items"], "%s[%d]" % [path, index], errors)


func _validate_string(value: String, schema: Dictionary, path: String, errors: Array[String]) -> void:
    if schema.has("minLength") and value.length() < int(schema["minLength"]):
        errors.append("%s: string is shorter than %d characters" % [path, int(schema["minLength"])])
    if schema.has("pattern"):
        var regex := RegEx.new()
        if regex.compile(str(schema["pattern"])) != OK:
            errors.append("%s: schema contains an invalid pattern" % path)
        elif regex.search(value) == null:
            errors.append("%s: value does not match required pattern" % path)


func _validate_number(value: Variant, schema: Dictionary, path: String, errors: Array[String]) -> void:
    var numeric_value := float(value)
    if schema.has("minimum") and numeric_value < float(schema["minimum"]):
        errors.append("%s: value is below minimum %s" % [path, str(schema["minimum"])])
    if schema.has("maximum") and numeric_value > float(schema["maximum"]):
        errors.append("%s: value is above maximum %s" % [path, str(schema["maximum"])])


func _matches_declared_type(value: Variant, declared_type: Variant) -> bool:
    if declared_type is Array:
        for candidate: Variant in declared_type:
            if _matches_type(value, str(candidate)):
                return true
        return false
    return _matches_type(value, str(declared_type))


func _matches_type(value: Variant, type_name: String) -> bool:
    match type_name:
        "object":
            return value is Dictionary
        "array":
            return value is Array
        "string":
            return value is String
        "integer":
            return value is int or (value is float and is_equal_approx(value, floor(value)))
        "number":
            return value is int or value is float
        "boolean":
            return value is bool
        "null":
            return value == null
        _:
            return false
