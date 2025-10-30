## Global variables singleton.
##
## Stores application-wide state variables and references that need to be accessed
## from multiple locations throughout the application.
extends Node

## Reference to the language switcher UI component.
var language_switcher: LanguageSwitcher

## Path used for testing purposes.
var test_path: String
