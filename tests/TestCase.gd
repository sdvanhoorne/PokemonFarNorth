class_name TestCase
extends RefCounted
## Base class for headless tests. Put tests in res://tests/test_*.gd,
## extend TestCase, and name each test method test_*.

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [message, str(expected), str(actual)])

func check_approx(actual: float, expected: float, message: String = "") -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s expected %s, got %s" % [message, str(expected), str(actual)])
