from pdfminer.high_level import extract_text
import os

class PDFService:
    @staticmethod
    def extract_text_from_pdf(file_path: str) -> str:
        if not os.path.exists(file_path):
            raise FileNotFoundError("PDF file not found")
        text = extract_text(file_path)
        return text.strip()
