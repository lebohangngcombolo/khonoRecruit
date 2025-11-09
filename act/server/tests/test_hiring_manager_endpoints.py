"""
Comprehensive API endpoint testing for Hiring Manager role
Tests access control, functionality, and admin isolation
"""

import requests
import json
from datetime import datetime, timedelta
import sys

# Configuration
BASE_URL = "http://127.0.0.1:5000"
API_URL = f"{BASE_URL}/api/admin"

# IMPORTANT: Replace these with actual tokens from your login
HM_TOKEN = "your_hiring_manager_jwt_token_here"
ADMIN_TOKEN = "your_admin_jwt_token_here"  # For comparison tests

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_success(msg):
    print(f"{Colors.GREEN}[OK] {msg}{Colors.END}")

def print_error(msg):
    print(f"{Colors.RED}[FAIL] {msg}{Colors.END}")

def print_info(msg):
    print(f"{Colors.BLUE}[INFO] {msg}{Colors.END}")

def print_warning(msg):
    print(f"{Colors.YELLOW}[WARN] {msg}{Colors.END}")


class HiringManagerTests:
    def __init__(self, hm_token, admin_token=None):
        self.hm_headers = {"Authorization": f"Bearer {hm_token}", "Content-Type": "application/json"}
        self.admin_headers = {"Authorization": f"Bearer {admin_token}", "Content-Type": "application/json"} if admin_token else None
        self.test_results = {"passed": 0, "failed": 0, "warnings": 0}
        
    def test_accessible_endpoints(self):
        """Test that hiring manager CAN access shared endpoints"""
        print_info("\n=== Testing Accessible Endpoints ===")
        
        accessible_endpoints = [
            ("GET", "/dashboard-counts", "Dashboard Statistics"),
            ("GET", "/jobs", "Job Listings"),
            ("GET", "/candidates", "Candidate List"),
            ("GET", "/cv-reviews", "CV Reviews"),
            ("GET", "/analytics/dashboard", "Analytics Dashboard"),
            ("GET", "/analytics/users-growth", "User Growth Analytics"),
            ("GET", "/analytics/applications-analysis", "Applications Analysis"),
            ("GET", "/analytics/interviews-analysis", "Interviews Analysis"),
            ("GET", "/recent-activities", "Recent Activities"),
        ]
        
        for method, endpoint, description in accessible_endpoints:
            try:
                url = f"{API_URL}{endpoint}"
                response = requests.get(url, headers=self.hm_headers)
                
                if response.status_code == 200:
                    print_success(f"{description}: {endpoint}")
                    self.test_results["passed"] += 1
                else:
                    print_error(f"{description}: {endpoint} - Status {response.status_code}")
                    self.test_results["failed"] += 1
            except Exception as e:
                print_error(f"{description}: {endpoint} - Error: {str(e)}")
                self.test_results["failed"] += 1
    
    def test_blocked_admin_endpoints(self):
        """Test that hiring manager CANNOT access admin-only endpoints"""
        print_info("\n=== Testing Admin-Only Endpoint Blocking ===")
        
        admin_only_endpoints = [
            ("GET", "/users", "User Management List"),
            ("GET", "/audits", "Audit Logs"),
            ("GET", "/powerbi/data", "Power BI Data Export"),
            ("GET", "/powerbi/status", "Power BI Status"),
        ]
        
        for method, endpoint, description in admin_only_endpoints:
            try:
                url = f"{API_URL}{endpoint}"
                response = requests.get(url, headers=self.hm_headers)
                
                if response.status_code == 403:
                    print_success(f"{description}: {endpoint} - Correctly blocked (403)")
                    self.test_results["passed"] += 1
                elif response.status_code == 401:
                    print_success(f"{description}: {endpoint} - Blocked (401 Unauthorized)")
                    self.test_results["passed"] += 1
                else:
                    print_error(f"{description}: {endpoint} - NOT BLOCKED! Status {response.status_code}")
                    self.test_results["failed"] += 1
            except Exception as e:
                print_error(f"{description}: {endpoint} - Error: {str(e)}")
                self.test_results["failed"] += 1
    
    def test_job_crud_operations(self):
        """Test complete job CRUD workflow"""
        print_info("\n=== Testing Job Management (CRUD) ===")
        
        # 1. Create Job
        job_data = {
            "title": f"Test Senior Engineer - {datetime.now().strftime('%Y%m%d%H%M%S')}",
            "description": "This is a test job created by automated tests",
            "job_summary": "Test job summary",
            "category": "Engineering",
            "required_skills": ["Python", "Flask", "PostgreSQL", "Docker"],
            "qualifications": ["Bachelor's Degree", "5+ years experience"],
            "min_experience": 5.0,
            "weightings": {"cv": 70, "assessment": 30},  # Test custom weighting
            "vacancy": 2
        }
        
        try:
            # CREATE
            response = requests.post(f"{API_URL}/jobs", headers=self.hm_headers, json=job_data)
            if response.status_code in [200, 201]:
                job = response.json().get('job', response.json())
                job_id = job.get('id')
                print_success(f"Job Created - ID: {job_id}, Title: {job_data['title']}")
                self.test_results["passed"] += 1
                
                # READ
                response = requests.get(f"{API_URL}/jobs/{job_id}", headers=self.hm_headers)
                if response.status_code == 200:
                    retrieved_job = response.json()
                    if retrieved_job['title'] == job_data['title']:
                        print_success(f"Job Retrieved - Verified title match")
                        self.test_results["passed"] += 1
                    else:
                        print_error(f"Job Retrieved - Title mismatch")
                        self.test_results["failed"] += 1
                else:
                    print_error(f"Job Retrieval Failed - Status {response.status_code}")
                    self.test_results["failed"] += 1
                
                # UPDATE
                update_data = {"title": f"Updated Test Job - {datetime.now().strftime('%H%M%S')}"}
                response = requests.put(f"{API_URL}/jobs/{job_id}", headers=self.hm_headers, json=update_data)
                if response.status_code == 200:
                    print_success(f"Job Updated - New title: {update_data['title']}")
                    self.test_results["passed"] += 1
                else:
                    print_error(f"Job Update Failed - Status {response.status_code}")
                    self.test_results["failed"] += 1
                
                # DELETE
                response = requests.delete(f"{API_URL}/jobs/{job_id}", headers=self.hm_headers)
                if response.status_code in [200, 204]:
                    print_success(f"Job Deleted - ID: {job_id}")
                    self.test_results["passed"] += 1
                else:
                    print_error(f"Job Deletion Failed - Status {response.status_code}")
                    self.test_results["failed"] += 1
            else:
                print_error(f"Job Creation Failed - Status {response.status_code}: {response.text}")
                self.test_results["failed"] += 4  # All 4 operations failed
        except Exception as e:
            print_error(f"Job CRUD Test Error: {str(e)}")
            self.test_results["failed"] += 4
    
    def test_score_calculation(self):
        """Test candidate score calculation with custom weightings"""
        print_info("\n=== Testing Score Calculation Algorithm ===")
        
        # First, get list of jobs
        try:
            response = requests.get(f"{API_URL}/jobs", headers=self.hm_headers)
            if response.status_code == 200:
                jobs = response.json()
                if not jobs:
                    print_warning("No jobs found - skipping score calculation test")
                    self.test_results["warnings"] += 1
                    return
                
                # Test shortlist for first job
                job = jobs[0]
                job_id = job['id']
                weightings = job.get('weightings', {'cv': 60, 'assessment': 40})
                
                response = requests.get(f"{API_URL}/jobs/{job_id}/shortlist", headers=self.hm_headers)
                if response.status_code == 200:
                    candidates = response.json()
                    if not candidates:
                        print_warning(f"No candidates for job {job_id} - skipping score validation")
                        self.test_results["warnings"] += 1
                        return
                    
                    # Validate score calculation for each candidate
                    all_correct = True
                    for candidate in candidates[:5]:  # Check first 5
                        cv_score = candidate.get('cv_score', 0)
                        assessment_score = candidate.get('assessment_score', 0)
                        overall_score = candidate.get('overall_score', 0)
                        
                        # Calculate expected score using job weightings
                        cv_weight = weightings.get('cv', 60) / 100
                        assessment_weight = weightings.get('assessment', 40) / 100
                        expected_score = (cv_score * cv_weight) + (assessment_score * assessment_weight)
                        
                        # Allow 0.01 tolerance for floating point
                        if abs(overall_score - expected_score) < 0.01:
                            print_success(f"Score Correct - Candidate {candidate.get('full_name', 'Unknown')}: "
                                        f"CV={cv_score}, Assessment={assessment_score}, "
                                        f"Overall={overall_score:.2f} (Expected={expected_score:.2f})")
                        else:
                            print_error(f"Score Mismatch - Candidate {candidate.get('full_name', 'Unknown')}: "
                                      f"Overall={overall_score:.2f}, Expected={expected_score:.2f}")
                            all_correct = False
                    
                    if all_correct:
                        self.test_results["passed"] += 1
                    else:
                        self.test_results["failed"] += 1
                else:
                    print_error(f"Shortlist retrieval failed - Status {response.status_code}")
                    self.test_results["failed"] += 1
            else:
                print_error(f"Jobs retrieval failed - Status {response.status_code}")
                self.test_results["failed"] += 1
        except Exception as e:
            print_error(f"Score Calculation Test Error: {str(e)}")
            self.test_results["failed"] += 1
    
    def test_notifications(self):
        """Test notification retrieval"""
        print_info("\n=== Testing Notifications ===")
        
        # Note: We need a user_id - typically from JWT token
        # This is a simplified test - you may need to extract user_id from token
        try:
            # Try to get recent activities which doesn't need user_id
            response = requests.get(f"{API_URL}/recent-activities", headers=self.hm_headers)
            if response.status_code == 200:
                print_success("Recent Activities Retrieved")
                self.test_results["passed"] += 1
            else:
                print_error(f"Recent Activities Failed - Status {response.status_code}")
                self.test_results["failed"] += 1
        except Exception as e:
            print_error(f"Notifications Test Error: {str(e)}")
            self.test_results["failed"] += 1
    
    def test_team_endpoints(self):
        """Test team collaboration endpoints"""
        print_info("\n=== Testing Team Collaboration ===")
        
        team_endpoints = [
            ("/team/members", "Team Members List"),
            ("/team/notes", "Shared Notes"),
            ("/team/messages", "Team Messages"),
            ("/team/activities", "Team Activities"),
        ]
        
        for endpoint, description in team_endpoints:
            try:
                url = f"{API_URL}{endpoint}"
                response = requests.get(url, headers=self.hm_headers)
                
                if response.status_code == 200:
                    print_success(f"{description}: {endpoint}")
                    self.test_results["passed"] += 1
                else:
                    print_error(f"{description}: {endpoint} - Status {response.status_code}")
                    self.test_results["failed"] += 1
            except Exception as e:
                print_error(f"{description}: {endpoint} - Error: {str(e)}")
                self.test_results["failed"] += 1
    
    def print_summary(self):
        """Print test execution summary"""
        print_info("\n" + "="*60)
        print_info("TEST EXECUTION SUMMARY")
        print_info("="*60)
        
        total = self.test_results["passed"] + self.test_results["failed"]
        success_rate = (self.test_results["passed"] / total * 100) if total > 0 else 0
        
        print(f"\n{Colors.GREEN}Passed: {self.test_results['passed']}{Colors.END}")
        print(f"{Colors.RED}Failed: {self.test_results['failed']}{Colors.END}")
        print(f"{Colors.YELLOW}Warnings: {self.test_results['warnings']}{Colors.END}")
        print(f"\nSuccess Rate: {success_rate:.1f}%")
        
        if self.test_results["failed"] == 0:
            print(f"\n{Colors.GREEN}*** ALL TESTS PASSED! *** Hiring Manager implementation is working correctly.{Colors.END}")
            return 0
        else:
            print(f"\n{Colors.RED}*** SOME TESTS FAILED! *** Please review the errors above.{Colors.END}")
            return 1


def main():
    print_info("="*60)
    print_info("HIRING MANAGER API ENDPOINT TEST SUITE")
    print_info("="*60)
    
    # Check if tokens are set
    if HM_TOKEN == "your_hiring_manager_jwt_token_here":
        print_error("\nERROR: Please set HM_TOKEN in the script with a valid hiring manager JWT token")
        print_info("\nTo get a token:")
        print_info("1. Login via the frontend or use: POST http://127.0.0.1:5000/api/auth/login")
        print_info("2. Extract the access_token from the response")
        print_info("3. Replace HM_TOKEN value in this script\n")
        return 1
    
    tester = HiringManagerTests(HM_TOKEN, ADMIN_TOKEN)
    
    # Run all test suites
    tester.test_accessible_endpoints()
    tester.test_blocked_admin_endpoints()
    tester.test_job_crud_operations()
    tester.test_score_calculation()
    tester.test_notifications()
    tester.test_team_endpoints()
    
    # Print summary and return exit code
    return tester.print_summary()


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
