import spacy
import PyPDF2
import docx
import re
from datetime import datetime
from app.extensions import mongo_db

class CVParser:
    def __init__(self):
        self.nlp = spacy.load("en_core_web_sm")
    
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
            
            # Extract name
            name = self.extract_name(doc)
            
            # Extract email
            email = self.extract_email(cv_text)
            
            # Extract phone
            phone = self.extract_phone(cv_text)
            
            # Extract skills
            skills = self.extract_skills(doc)
            
            # Extract experience
            experience = self.extract_experience(doc)
            
            # Extract education
            education = self.extract_education(doc)
            
            return {
                'name': name,
                'email': email,
                'phone': phone,
                'skills': skills,
                'experience': experience,
                'education': education,
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
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        match = re.search(email_pattern, text)
        return match.group(0) if match else ""
    
    def extract_phone(self, text):
        phone_pattern = r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'
        match = re.search(phone_pattern, text)
        return match.group(0) if match else ""
    
    def extract_skills(self, doc):
        # Common skills dictionary
        common_skills = {
            'programming': ['python', 'java', 'javascript', 'c++', 'c#', 'ruby', 'php', 'swift', 'kotlin', 'go'],
            'web': ['html', 'css', 'react', 'angular', 'vue', 'django', 'flask', 'node.js', 'express'],
            'database': ['sql', 'mysql', 'postgresql', 'mongodb', 'redis', 'oracle'],
            'devops': ['docker', 'kubernetes', 'aws', 'azure', 'gcp', 'jenkins', 'git', 'ci/cd'],
            'data': ['pandas', 'numpy', 'tensorflow', 'pytorch', 'scikit-learn', 'ml', 'ai']
        }
        
        skills = set()
        text_lower = doc.text.lower()
        
        for category, skill_list in common_skills.items():
            for skill in skill_list:
                if skill in text_lower:
                    skills.add(skill)
        
        return list(skills)
    
    def extract_experience(self, doc):
        experience = []
        experience_patterns = [
            r'(\d+)\s*(?:years?|yrs?)\s*(?:of)?\s*experience',
            r'experience.*?(\d+)\s*(?:years?|yrs?)',
            r'(\d+)\s*\+?\s*years?'
        ]
        
        text = doc.text.lower()
        total_experience = 0
        
        for pattern in experience_patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                try:
                    years = float(match)
                    if years > total_experience:
                        total_experience = years
                except ValueError:
                    continue
        
        # Extract job experiences
        for sent in doc.sents:
            if any(word in sent.text.lower() for word in ['worked', 'experience', 'job', 'position', 'role']):
                experience.append(sent.text)
        
        return {
            'total_years': total_experience,
            'details': experience[:5]  # Limit to 5 most relevant experiences
        }
    
    def extract_education(self, doc):
        education = []
        education_keywords = ['university', 'college', 'institute', 'bachelor', 'master', 'phd', 'degree', 'diploma']
        
        for sent in doc.sents:
            if any(keyword in sent.text.lower() for keyword in education_keywords):
                education.append(sent.text)
        
        return education