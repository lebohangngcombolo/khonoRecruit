import re
import os
from datetime import datetime
import spacy
from spacy.util import is_package
from spacy.cli import download as spacy_download
import PyPDF2
import docx
from collections import Counter

class CVParser:
    def __init__(self):
        self.model_name = "en_core_web_sm"
        try:
            if not is_package(self.model_name):
                print(f"spaCy model '{self.model_name}' not found. Downloading...")
                spacy_download(self.model_name)
            self.nlp = spacy.load(self.model_name)
        except Exception as e:
            raise Exception(f"Failed to load spaCy model '{self.model_name}': {str(e)}")

    # -------------------------
    # Extract text from file
    # -------------------------
    def extract_text_from_file(self, file_path, file_type):
        try:
            text = ""
            if file_type == 'pdf':
                with open(file_path, 'rb') as f:
                    pdf_reader = PyPDF2.PdfReader(f)
                    for page in pdf_reader.pages:
                        page_text = page.extract_text()
                        if page_text:
                            text += page_text + "\n"
            elif file_type == 'docx':
                doc = docx.Document(file_path)
                for para in doc.paragraphs:
                    text += para.text + "\n"
            else:
                with open(file_path, 'r', encoding='utf-8') as f:
                    text = f.read()
            return text
        except Exception as e:
            raise Exception(f"Error extracting text from {file_path}: {str(e)}")

    # -------------------------
    # Main parsing method
    # -------------------------
    def parse_cv(self, cv_text):
        try:
            doc = self.nlp(cv_text)
            job_titles = self.extract_job_titles(cv_text)
            certifications = self.extract_certifications(cv_text)
            skills = self.extract_skills(cv_text, job_titles, certifications)
            
            return {
                'name': self.extract_name(doc),
                'email': self.extract_email(cv_text),
                'phone': self.extract_phone(cv_text),
                'skills': skills,
                'experience': self.extract_experience(cv_text),
                'education': self.extract_education(cv_text),
                'job_titles': job_titles,
                'certifications': certifications,
                'raw_text': cv_text
            }
        except Exception as e:
            raise Exception(f"Error parsing CV: {str(e)}")

    # -------------------------
    # Extract name using spaCy
    # -------------------------
    def extract_name(self, doc):
        for ent in doc.ents:
            if ent.label_ == "PERSON":
                return ent.text
        return ""

    # -------------------------
    # Extract email
    # -------------------------
    def extract_email(self, text):
        match = re.search(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b', text)
        return match.group(0) if match else ""

    # -------------------------
    # Extract phone number
    # -------------------------
    def extract_phone(self, text):
        match = re.search(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}', text)
        return match.group(0) if match else ""

    # -------------------------
    # Extract skills with confidence
    # -------------------------
    def extract_skills(self, text, job_titles=None, certifications=None):
        base_skills = [
            'python', 'java', 'javascript', 'c++', 'c#', 'ruby', 'php', 'swift', 'kotlin', 'go',
            'html', 'css', 'react', 'angular', 'vue', 'django', 'flask', 'node.js', 'express',
            'sql', 'mysql', 'postgresql', 'mongodb', 'redis', 'oracle',
            'docker', 'kubernetes', 'aws', 'azure', 'gcp', 'jenkins', 'git', 'ci/cd',
            'pandas', 'numpy', 'tensorflow', 'pytorch', 'scikit-learn', 'ml', 'ai'
        ]

        text_lower = text.lower()
        words = re.findall(r'\b\w[\w.+#/-]*\b', text_lower)
        word_counts = Counter(words)
        total_words = sum(word_counts.values()) if sum(word_counts.values()) > 0 else 1

        # Combine skills from base, job titles, certifications
        skills_to_check = set(base_skills)
        if job_titles:
            for title in job_titles:
                for word in title.split():
                    skills_to_check.add(word.lower())
        if certifications:
            for cert in certifications:
                for word in cert.split():
                    skills_to_check.add(word.lower())

        # Calculate confidence based on frequency
        skills_confidence = {}
        for skill in skills_to_check:
            count = word_counts.get(skill.lower(), 0)
            confidence = min(count / total_words, 1.0)
            if confidence > 0:
                skills_confidence[skill] = round(confidence, 3)

        return skills_confidence

    # -------------------------
    # Extract experience
    # -------------------------
    def extract_experience(self, text):
        experience_years = 0
        experience_details = []

        patterns = [
            r'(\d+)\s*(?:\+)?\s*(?:years?|yrs?)',
            r'experience.*?(\d+)\s*(?:years?|yrs?)'
        ]
        for pattern in patterns:
            for match in re.findall(pattern, text, re.IGNORECASE):
                try:
                    years = float(match)
                    experience_years = max(experience_years, years)
                except:
                    continue

        sentences = re.split(r'(?<=[.!?])\s+', text)
        keywords = ['worked', 'experience', 'job', 'position', 'role', 'internship']
        for sent in sentences:
            if any(k in sent.lower() for k in keywords):
                experience_details.append(sent.strip())

        return {'total_years': experience_years, 'details': experience_details[:5]}

    # -------------------------
    # Extract education
    # -------------------------
    def extract_education(self, text):
        education_list = []
        keywords = ['university', 'college', 'institute', 'bachelor', 'master', 'phd', 'degree', 'diploma']
        sentences = re.split(r'(?<=[.!?])\s+', text)
        for sent in sentences:
            if any(k in sent.lower() for k in keywords):
                education_list.append(sent.strip())
        return education_list

    # -------------------------
    # Extract job titles
    # -------------------------
    def extract_job_titles(self, text):
        job_keywords = [
            'software engineer', 'developer', 'manager', 'analyst', 'consultant', 
            'intern', 'designer', 'architect', 'administrator', 'specialist'
        ]
        sentences = re.split(r'(?<=[.!?])\s+', text.lower())
        titles = []
        for sent in sentences:
            for keyword in job_keywords:
                if keyword in sent:
                    titles.append(sent.strip())
        return list(set(titles))

    # -------------------------
    # Extract certifications
    # -------------------------
    def extract_certifications(self, text):
        cert_keywords = [
            'certified', 'certification', 'diploma', 'certificate', 'cisco', 'aws', 'pmp', 'scrum', 'itil'
        ]
        sentences = re.split(r'(?<=[.!?])\s+', text.lower())
        certifications = []
        for sent in sentences:
            for keyword in cert_keywords:
                if keyword in sent:
                    certifications.append(sent.strip())
        return list(set(certifications))
