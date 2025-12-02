# utils/password_validator.py
import re

class PasswordValidator:
    def __init__(self, min_length=8, max_length=128):
        self.min_length = min_length
        self.max_length = max_length

        self.uppercase_pattern = r"[A-Z]"
        self.lowercase_pattern = r"[a-z]"
        self.number_pattern = r"[0-9]"
        self.special_pattern = r"[!@#$%^&*(),.?\":{}|<>]"

    def validate(self, password: str):
        errors = []

        if not password:
            errors.append("Password is required.")
            return False, errors

        if len(password) < self.min_length:
            errors.append(f"Password must be at least {self.min_length} characters long.")

        if len(password) > self.max_length:
            errors.append(f"Password must not exceed {self.max_length} characters.")

        if not re.search(self.uppercase_pattern, password):
            errors.append("Password must contain at least one uppercase letter.")

        if not re.search(self.lowercase_pattern, password):
            errors.append("Password must contain at least one lowercase letter.")

        if not re.search(self.number_pattern, password):
            errors.append("Password must contain at least one digit.")

        if not re.search(self.special_pattern, password):
            errors.append("Password must contain at least one special character (!@#$ etc).")

        return len(errors) == 0, errors
