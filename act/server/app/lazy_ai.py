"""
Lazy-loading wrapper for AI/ML modules to reduce startup memory.
Only import heavy libraries when actually needed.
"""
import os

# Global instances (loaded on-demand)
_spacy_model = None
_sentence_transformer = None

def get_spacy_model():
    """Lazy load spaCy model only when needed."""
    global _spacy_model
    if _spacy_model is None:
        print("🔄 Loading spaCy model (this may take a moment)...")
        import spacy
        _spacy_model = spacy.load('en_core_web_sm')
        print("✅ spaCy model loaded")
    return _spacy_model

def get_sentence_transformer():
    """Lazy load sentence transformer only when needed."""
    global _sentence_transformer
    if _sentence_transformer is None:
        print("🔄 Loading sentence transformer model...")
        from sentence_transformers import SentenceTransformer
        _sentence_transformer = SentenceTransformer('all-MiniLM-L6-v2')
        print("✅ Sentence transformer loaded")
    return _sentence_transformer

def is_ai_enabled():
    """Check if AI features should be enabled based on environment."""
    # Disable AI features on free tier or when explicitly disabled
    return os.environ.get('ENABLE_AI_FEATURES', 'false').lower() == 'true'

# Lightweight alternatives for free tier
def simple_text_analysis(text):
    """Simple text analysis without heavy ML libraries."""
    import re
    
    return {
        'word_count': len(text.split()),
        'char_count': len(text),
        'sentence_count': len(re.split(r'[.!?]+', text)),
        'has_email': bool(re.search(r'\b[\w.-]+@[\w.-]+\.\w+\b', text)),
        'has_phone': bool(re.search(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', text))
    }
