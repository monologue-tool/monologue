class_name Schemas

static var VARIABLE: Dictionary = {
	"title": "Variable",
	"type": "object",
	"properties":
	{
		"name":
		{
			"type": "text",
			"default": "",
			"required": true,
			"validation": {"min_length": 1, "unique": true}
		},
		"type":
		{
			"type": "dropdown",
			"enum": ["bool", "string", "int", "float"],
			"default": "string",
			"required": true
		},
		"value":
		{
			"type": "dynamic",
			"cases":
			{
				"bool": {"type": "bool", "default": false},
				"string": {"type": "text", "default": "", "coerce": "string"},
				"int": {"type": "number", "default": 0, "coerce": "int"},
				"float": {"type": "number", "default": 0.0, "coerce": "float"}
			}
		},
		"description":
		{
			"type": "textarea",
			"default": "",
			"rows": 3,
		}
	},
	"layouts":
	{
		"default":
		{
			"display": "vertical",
			"fields": ["name", "type", "value", "description"],
		},
		"list_item":
		{
			"display": "vertical",
			"fields": ["name", "type", "value", "description"],
		}
	}
}

static var CHARACTER: Dictionary = {
	"title": "Character",
	"type": "object",
	"properties":
	{
		"protected":
		{
			"type": "bool",
			"default": false,
		},
		"name":
		{
			"type": "text",
			"default": NameGenerator.generate,
			"required": true,
			"validation": {"min_length": 1},
		},
		"display_name":
		{
			"type": "text",
			"default": "",
		},
		"nicknames":
		{
			"type": "text",
			"default": "",
		},
		"description":
		{
			"type": "textarea",
			"default": "",
			"rows": 4,
		},
		"portraits":
		{
			"type": "list",
			"default": [],
			"minItems": 1,
			"data_schema": PORTRAIT,
		},
		"default_portrait": {"type": "string", "default": "", "validation": {}}
	},
	"layouts":
	{
		"default":
		{
			"display": "vertical",
			"fields": ["name", "description"],
		},
		"list_item":
		{
			"display": "vertical",
			"fields": ["name", "description"],
		}
	}
}

static var PORTRAIT: Dictionary = {
	"title": "Portrait",
	"type": "object",
	"properties":
	{
		"name":
		{
			"type": "text",
			"default": "",
			"required": true,
		},
		"protected":
		{
			"type": "bool",
			"default": false,
			"tooltip": "Prevent deletion",
		},
		"type":
		{
			"type": "dropdown",
			"enum": ["static", "animated"],
			"default": "static",
			"required": true,
		},
		"mirror":
		{
			"type": "bool",
			"default": false,
			"tooltip": "Mirror the image horizontally",
		},
		"offset":
		{
			"type": "vector2",
			"default": Vector2.ZERO,
		},
		"image_path":
		{
			"type": "path",
			"default": "",
			"filter": ["*.png", "*.jpg", "*.jpeg"],
			"required": true,
			"condition": {"property": "type", "equals": "static"}
		},
		"timeline":
		{
			"type": "timeline",
			"default": null,
			"required": true,
			"condition": {"property": "type", "equals": "animated"}
		}
	},
	"layouts":
	{
		"default":
		{
			"sections":
			[
				{"title": "General", "fields": ["name", "type"]},
				{"title": "Display", "fields": ["mirror", "offset"]},
				{"title": "Content", "fields": ["image_path", "timeline"], "conditional": true}
			]
		},
		"compact":
		{
			"layout": "horizontal",
			"fields": ["name", "type", "image_path"],
		},
		"thumbnail":
		{
			"layout": "card",
			"show_preview": true,
			"preview_from": "image_path",
			"title_format": "{name}",
			"fields": ["type", "mirror"]
		}
	}
}

static var ITEM: Dictionary = {
	"title": "Portrait",
	"type": "object",
	"properties":
	{
		"name":
		{
			"type": "text",
			"default": "",
			"required": true,
		},
		"description":
		{
			"type": "textarea",
			"default": "",
			"rows": 4,
		},
	},
	"layouts":
	{
		"default":
		{
			"display": "vertical",
			"fields": ["name", "description"],
		},
		"list_item":
		{
			"display": "vertical",
			"fields": ["name", "description"],
		}
	}
}


static func validate(data: Dictionary, schema: Dictionary) -> Dictionary:
	var errors: Array = []
	var properties = schema.get("properties", {})

	for prop_name in properties:
		var prop_config = properties[prop_name]
		var value = data.get(prop_name)

		if prop_config.get("required", false):
			if value == null or (value is String and value.is_empty()):
				errors.append("%s is required" % prop_name)

		if prop_config.has("validation"):
			var validation = prop_config["validation"]
			if validation.has("pattern") and value is String:
				var regex = RegEx.new()
				regex.compile(validation["pattern"])
				if not regex.search(value):
					errors.append("%s format is invalid" % prop_name)

			if validation.has("min_length") and value is String:
				if value.length() < validation["min_length"]:
					errors.append("%s is too short" % prop_name)

	return {"valid": errors.is_empty(), "errors": errors}
