from flask import Flask

def reverse_string(s):
	"""Custom filter to reverse a string."""
	return s[::-1]

def capitalize_words(s):
	"""Custom filter to capitalize all words in a string."""
	return " ".join(word.capitalize() for word in s.split())

def register_filters(app: Flask):
	"""Register custom filters with the Flask app."""
	app.jinja_env.filters["reverse_string"] = reverse_string
	app.jinja_env.filters["capitalize_words"] = capitalize_words