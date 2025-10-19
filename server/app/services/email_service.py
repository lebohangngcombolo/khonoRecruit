from flask import render_template, current_app
from app.extensions import mail
from flask_mail import Message
from threading import Thread
from app.extensions import redis_client
import logging

class EmailService:

    @staticmethod
    def send_verification_email(email, verification_code):
        """Send email verification code."""
        subject = "Verify Your Email Address"
        try:
            html = render_template(
                'email_templates/verification_email.html', 
                verification_code=verification_code
            )
        except Exception:
            logging.error(f"Failed to render verification email template for {email}", exc_info=True)
            html = f"Your verification code is: {verification_code}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_password_reset_email(email, reset_token):
        """Send password reset instructions."""
        subject = "Password Reset Request"
        reset_link = f"http://localhost:65290/reset-password?token={reset_token}"
        try:
            html = render_template(
                'email_templates/password_reset_email.html', 
                reset_link=reset_link
            )
        except Exception:
            logging.error(f"Failed to render password reset template for {email}", exc_info=True)
            html = f"Reset your password using this link: {reset_link}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_interview_invitation(email, candidate_name, interview_date, interview_type, meeting_link=None):
        """Send interview invitation email."""
        subject = "Interview Invitation"
        try:
            html = render_template(
                'email_templates/interview_invitation.html',
                candidate_name=candidate_name,
                interview_date=interview_date,
                interview_type=interview_type,
                meeting_link=meeting_link
            )
        except Exception:
            logging.error(f"Failed to render interview invitation template for {email}", exc_info=True)
            html = f"Hi {candidate_name}, your {interview_type} interview is scheduled on {interview_date}. Link: {meeting_link}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_application_status_update(email, candidate_name, status, position_title):
        """Send application status update email."""
        subject = f"Application Update for {position_title or 'your position'}"
        try:
            html = render_template(
                'email_templates/application_status_update.html',
                candidate_name=candidate_name,
                status=status,
                position_title=position_title
            )
        except Exception:
            logging.error(f"Failed to render application status update template for {email}", exc_info=True)
            html = f"Hi {candidate_name}, your application for {position_title} status is: {status}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_temporary_password(email, password, first_name=None):
        """Send enrollment email with temporary password."""
        subject = "Your Temporary Password"

        try:
            html = render_template(
                'email_templates/temporary_password.html',
                password=password,
                first_name=first_name,
                current_year=2025
            )
            text_body = f"Hello {first_name or ''},\n\nYour temporary password is: {password}"
        except Exception:
            logging.error(f"Failed to render temporary password template for {email}", exc_info=True)
            html = text_body = f"Your temporary password is: {password}"

        EmailService.send_async_email(subject, [email], html, text_body=text_body)
        
    @staticmethod
    def send_async_email(subject, recipients, html_body, text_body=None):
        """Send email in a background thread safely."""
        from app import create_app
        app = create_app()

        # Ensure subject is a string
        subject = str(subject)

        def send_email(app, subject, recipients, html_body, text_body):
            with app.app_context():
                try:
                    msg = Message(
                        subject=subject,
                        recipients=recipients,
                        html=html_body,
                        body=text_body or "",
                        sender=app.config['MAIL_USERNAME']
                    )
                    mail.send(msg)
                except Exception as e:
                    logging.error(f"Failed to send email to {recipients}: {str(e)}", exc_info=True)

        thread = Thread(target=send_email, args=[app, subject, recipients, html_body, text_body])
        thread.start()
        
    @staticmethod
    def send_interview_cancellation(email, candidate_name, interview_date, interview_type, reason=None):
        """
        Send email notification that an interview has been cancelled.
        Includes optional reason and always provides HTML + plain text.
        """
        subject = "Interview Cancellation Notice"
    
        # Ensure reason is a string
        reason_text = reason or "No specific reason provided."
    
        try:
            html = render_template(
                'email_templates/interview_cancellation.html',
                candidate_name=candidate_name,
                interview_date=interview_date,
                interview_type=interview_type,
                reason=reason_text
            )
            text_body = f"Hi {candidate_name},\n\nYour {interview_type} interview scheduled on {interview_date} has been cancelled.\nReason: {reason_text}\n\nPlease contact us for rescheduling."
        except Exception:
            logging.error(f"Failed to render interview cancellation template for {email}", exc_info=True)
            html = text_body = f"Hi {candidate_name}, your {interview_type} interview scheduled on {interview_date} has been cancelled.\nReason: {reason_text}"

        EmailService.send_async_email(subject, [email], html, text_body=text_body)
        
    @staticmethod
    def send_interview_reschedule_email(email, candidate_name, old_time, new_time, interview_type, meeting_link=None):
        """Send interview reschedule notification."""
        subject = "Interview Rescheduled"
        try:
            html = render_template(
                "email_templates/interview_reschedule.html",
                candidate_name=candidate_name,
                old_time=old_time,
                new_time=new_time,
                interview_type=interview_type,
                meeting_link=meeting_link
            )
        except Exception:
            logging.error(f"Failed to render reschedule email template for {email}", exc_info=True)
            html = f"Hi {candidate_name}, your {interview_type} interview has been rescheduled from {old_time} to {new_time}. Link: {meeting_link}"

        EmailService.send_async_email(subject, [email], html)

