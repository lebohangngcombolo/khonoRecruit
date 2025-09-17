import spacy
import PyPDF2
import docx
import re
from datetime import datetime
from app.extensions import mongo_db
from spacy.util import is_package, get_package_path
from spacy.cli import download as spacy_download

class CVParser:
    def __init__(self):
        model_name = "en_core_web_sm"
        try:
            # Check if model is installed
            if not is_package(model_name):
                print(f"spaCy model '{model_name}' not found. Downloading...")
                spacy_download(model_name)
            self.nlp = spacy.load(model_name)
        except Exception as e:
            raise Exception(f"Failed to load spaCy model '{model_name}': {str(e)}")

    def extract_text_from_file(self, file_path, file_type):
        try:
            text = ""
            if file_type == 'pdf':
                with open(file_path, 'rb') as file:
                    pdf_reader = PyPDF2.PdfReader(file)
                    for page in pdf_reader.pages:
                        text += page.extract_text() + "\n"
            elif file_type == 'docx':
                doc = docx.Document(file_path)
                for para in doc.paragraphs:
                    text += para.text + "\n"
            else:
                with open(file_path, 'r', encoding='utf-8') as file:
                    text = file.read()
            return text
        except Exception as e:
            raise Exception(f"Error extracting text from file: {str(e)}")

    def parse_cv(self, cv_text):
        try:
            doc = self.nlp(cv_text)
            return {
                'name': self.extract_name(doc),
                'email': self.extract_email(cv_text),
                'phone': self.extract_phone(cv_text),
                'skills': self.extract_skills(doc),
                'experience': self.extract_experience(doc),
                'education': self.extract_education(doc),
                'raw_text': cv_text
            }
        except Exception as e:
            raise Exception(f"Error parsing CV: {str(e)}")

    def extract_name(self, doc):
        for ent in doc.ents:
            if ent.label_ == "PERSON":
                return ent.text
        return ""

    def extract_email(self, text):
        match = re.search(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', text)
        return match.group(0) if match else ""

    def extract_phone(self, text):
        match = re.search(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}', text)
        return match.group(0) if match else ""

    def extract_skills(self, doc):
        common_skills = {
            'programming': ['python', 'java', 'javascript', 'c++', 'c#', 'ruby', 'php', 'swift', 'kotlin', 'go'],
            'web': ['html', 'css', 'react', 'angular', 'vue', 'django', 'flask', 'node.js', 'express'],
            'database': ['sql', 'mysql', 'postgresql', 'mongodb', 'redis', 'oracle'],
            'devops': ['docker', 'kubernetes', 'aws', 'azure', 'gcp', 'jenkins', 'git', 'ci/cd'],
            'data': ['pandas', 'numpy', 'tensorflow', 'pytorch', 'scikit-learn', 'ml', 'ai']
        }
        skills = set()
        text_lower = doc.text.lower()
        for skill_list in common_skills.values():
            for skill in skill_list:
                if skill in text_lower:
                    skills.add(skill)
        return list(skills)

    def extract_experience(self, doc):
        experience = []
        patterns = [r'(\d+)\s*(?:years?|yrs?)\s*(?:of)?\s*experience',
                    r'experience.*?(\d+)\s*(?:years?|yrs?)',
                    r'(\d+)\s*\+?\s*years?']
        total_experience = 0
        text = doc.text.lower()
        for pattern in patterns:
            for match in re.findall(pattern, text):
                try:
                    years = float(match)
                    total_experience = max(total_experience, years)
                except:
                    continue
        for sent in doc.sents:
            if any(word in sent.text.lower() for word in ['worked', 'experience', 'job', 'position', 'role']):
                experience.append(sent.text)
        return {'total_years': total_experience, 'details': experience[:5]}

    def extract_education(self, doc):
        education = []
        keywords = ['university', 'college', 'institute', 'bachelor', 'master', 'phd', 'degree', 'diploma']
        for sent in doc.sents:
            if any(k in sent.text.lower() for k in keywords):
                education.append(sent.text)
        return education
