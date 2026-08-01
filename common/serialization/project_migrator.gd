## Brings a project file written by an older Monologue up to the current format.
class_name ProjectMigrator


## True when [param from_version] can be brought up to
## [constant ManifestDocument.FORMAT_VERSION].
static func can_migrate(from_version: int) -> bool:
	return from_version == ManifestDocument.FORMAT_VERSION


## Returns the migrated document data. Records what it did, or could not do, in
## [param result].
static func migrate(
	data: Dictionary, from_version: int, result: ValidationResult
) -> Dictionary:
	if from_version == ManifestDocument.FORMAT_VERSION:
		return data

	result.add_error(
		(
			"This project uses file format %d, which this version of Monologue cannot read."
			% from_version
		),
		&"unsupported_format"
	)
	return data
