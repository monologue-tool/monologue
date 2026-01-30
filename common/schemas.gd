extends Node

var VARIABLE: Dictionary = {
	"title": "Variable",
	"type": "object",
	"properties":
	{
		"name":
		{
			"type": "text",
			"default": "new variable",
			"required": true,
			"unique": true,
			"validation": {"min_length": 1}
		},
		"type":
		{
			"type": "dropdown",
			"options": ["bool", "string", "int", "float"],
			"default": "string",
			"required": true
		},
		"value":
		{
			"type": "dynamic",
			"case_property": "type",
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
			"fields": ["name", "type", "value", "description"],
		},
		"list_item":
		{
			"fields": ["name", "type", "value", "description"],
			"actions": ["duplicate", "delete"],
		}
	}
}

var CHARACTER: Dictionary = {
	"title": "Character",
	"type": "object",
	"properties":
	{
		"id":
		{
			"type": "text",
			"default": IDGen.generate,
			"unique": true,
		},
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
			"unique": true,
			"protect": true,
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
			"fields": ["name", "description"],
		},
		"list_item":
		{
			"fields": ["name", "description"],
			"actions": ["edit", "duplicate", "delete"],
		}
	}
}

var PORTRAIT: Dictionary = {
	"title": "Portrait",
	"type": "object",
	"properties":
	{
		"name":
		{
			"type": "text",
			"default": "new portrait",
			"required": true,
			"unique": true,
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
			"options": ["static", "animated"],
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
			"fields": ["name", "type", "image_path"],
		},
		"compact":
		{
			"fields": ["name", "type", "image_path"],
		}
	}
}

var ITEM: Dictionary = {
	"title": "Portrait",
	"type": "object",
	"properties":
	{
		"id":
		{
			"type": "text",
			"default": IDGen.generate,
			"unique": true,
		},
		"name":
		{
			"type": "text",
			"default": "new item",
			"required": true,
			"unique": true,
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
			"fields": ["name", "description"],
		},
		"list_item":
		{
			"fields": ["name", "description"],
			"actions": ["edit", "duplicate", "delete"],
		}
	}
}

# TODO: Location backgrounds with variants
var LOCATION: Dictionary = {
	"title": "Portrait",
	"type": "object",
	"properties":
	{
		"name":
		{
			"type": "text",
			"default": "new location",
			"required": true,
			"unique": true,
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
			"fields": ["name", "description"],
		},
		"list_item":
		{
			"fields": ["name", "description"],
			"actions": ["edit", "delete"],
		}
	}
}
