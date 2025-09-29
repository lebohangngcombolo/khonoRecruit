from flask import render_template, current_app
from app.extensions import mail
from flask_mail import Message
from threading import Thread
import logging

class EmailService:
    @staticmethod
    def send_verification_email(email, verification_code):
        """Send email verification code."""
        subject = "Verify Your Email Address"
        try:
            html = render_template('email_templates/verification_email.html', 
                                   verification_code=verification_code)
        except Exception:
            logging.error(f"Failed to render verification email template for {email}", exc_info=True)
            html = f"Your verification code is: {verification_code}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_password_reset_email(email, reset_token):
        """Send password reset instructions."""
        subject = "Password Reset Request"
        reset_link = f"https://yourapp.com/reset-password?token={reset_token}"
        try:
            html = render_template('email_templates/password_reset_email.html', 
                                   reset_link=reset_link)
        except Exception:
            logging.error(f"Failed to render password reset template for {email}", exc_info=True)
            html = f"Reset your password using this link: {reset_link}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_interview_invitation(email, candidate_name, interview_date, interview_type, meeting_link=None):
        """Send interview invitation email."""
        subject = "Interview Invitation"
        try:
            html = render_template('email_templates/interview_invitation.html',
                                   candidate_name=candidate_name,
                                   interview_date=interview_date,
                                   interview_type=interview_type,
                                   meeting_link=meeting_link)
        except Exception:
            logging.error(f"Failed to render interview invitation template for {email}", exc_info=True)
            html = f"Hi {candidate_name}, your {interview_type} interview is scheduled on {interview_date}. Link: {meeting_link}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_application_status_update(email, candidate_name, status, position_title):
        """Send application status update email."""
        subject = f"Application Update for {position_title or 'your position'}"
        try:
            html = render_template('email_templates/application_status_update.html',
                                   candidate_name=candidate_name,
                                   status=status,
                                   position_title=position_title)
        except Exception:
            logging.error(f"Failed to render application status update template for {email}", exc_info=True)
            html = f"Hi {candidate_name}, your application for {position_title} status is: {status}"

        EmailService.send_async_email(subject, [email], html)

    @staticmethod
    def send_async_email(subject, recipients, html_body):
        """Send email in a background thread safely."""
        from app import create_app
        app = create_app()

        # Ensure subject is a string
        subject = str(subject)

        def send_email(app, subject, recipients, html_body):
            with app.app_context():
                try:
                    msg = Message(
                        subject=subject,
                        recipients=recipients,
                        html=html_body,
                        sender=app.config['MAIL_USERNAME']
                    )
                    mail.send(msg)
                except Exception as e:
                    logging.error(f"Failed to send email to {recipients}: {str(e)}", exc_info=True)

        thread = Thread(target=send_email, args=[app, subject, recipients, html_body])
        thread.start()
