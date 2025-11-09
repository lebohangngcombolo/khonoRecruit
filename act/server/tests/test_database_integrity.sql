-- ============================================================
-- DATABASE INTEGRITY VERIFICATION FOR HIRING MANAGER
-- Run this script to verify data integrity and score calculations
-- ============================================================

-- Set proper display formatting
\pset border 2
\pset format wrapped

-- ============================================================
-- 1. VERIFY HIRING MANAGER DATA ACCESS
-- ============================================================
\echo ''
\echo '=== HIRING MANAGER DATA ACCESS ==='
\echo ''

-- List all hiring managers and their job counts
SELECT 
    u.id as user_id,
    u.email,
    u.role,
    COALESCE(json_extract_path_text(u.profile, 'first_name'), '') || ' ' || 
    COALESCE(json_extract_path_text(u.profile, 'last_name'), '') as full_name,
    u.is_verified,
    u.enrollment_completed,
    COUNT(DISTINCT r.id) as total_jobs_created,
    COUNT(DISTINCT a.id) as total_applications,
    COUNT(DISTINCT i.id) as interviews_scheduled
FROM users u
LEFT JOIN requisitions r ON r.created_by = u.id
LEFT JOIN applications a ON a.requisition_id = r.id
LEFT JOIN interviews i ON i.hiring_manager_id = u.id
WHERE u.role = 'hiring_manager'
GROUP BY u.id, u.email, u.role, u.profile, u.is_verified, u.enrollment_completed
ORDER BY u.created_at DESC;

-- ============================================================
-- 2. VERIFY ROLE-BASED ACCESS (User Roles Distribution)
-- ============================================================
\echo ''
\echo '=== USER ROLES DISTRIBUTION ==='
\echo ''

SELECT 
    role,
    COUNT(*) as user_count,
    COUNT(CASE WHEN is_verified THEN 1 END) as verified_count,
    COUNT(CASE WHEN is_active THEN 1 END) as active_count,
    ROUND(AVG(CASE WHEN is_verified THEN 1 ELSE 0 END) * 100, 2) as verification_rate
FROM users
GROUP BY role
ORDER BY user_count DESC;

-- ============================================================
-- 3. VERIFY SCORE CALCULATIONS (60/40 Weighting)
-- ============================================================
\echo ''
\echo '=== SCORE CALCULATION VERIFICATION ==='
\echo ''

-- Check applications where overall_score doesn't match expected calculation
WITH score_check AS (
    SELECT 
        a.id as application_id,
        c.full_name as candidate_name,
        r.title as job_title,
        COALESCE(json_extract_path_text(c.profile, 'cv_score')::DECIMAL, 0) as cv_score,
        a.assessment_score,
        a.overall_score as stored_overall_score,
        -- Calculate expected score using job weightings
        (
            COALESCE(json_extract_path_text(c.profile, 'cv_score')::DECIMAL, 0) * 
            COALESCE((r.weightings->>'cv')::DECIMAL, 60) / 100
        ) + (
            COALESCE(a.assessment_score, 0) * 
            COALESCE((r.weightings->>'assessment')::DECIMAL, 40) / 100
        ) as calculated_overall_score,
        r.weightings
    FROM applications a
    JOIN candidates c ON a.candidate_id = c.id
    JOIN requisitions r ON a.requisition_id = r.id
    WHERE a.overall_score IS NOT NULL
)
SELECT 
    application_id,
    candidate_name,
    job_title,
    cv_score,
    assessment_score,
    stored_overall_score,
    ROUND(calculated_overall_score, 2) as expected_score,
    ROUND(ABS(stored_overall_score - calculated_overall_score), 4) as difference,
    CASE 
        WHEN ABS(stored_overall_score - calculated_overall_score) < 0.01 THEN '✓ CORRECT'
        ELSE '✗ MISMATCH'
    END as status,
    weightings
FROM score_check
ORDER BY difference DESC
LIMIT 20;

-- Summary of score accuracy
\echo ''
\echo '=== SCORE ACCURACY SUMMARY ==='
\echo ''

WITH score_check AS (
    SELECT 
        a.id,
        a.overall_score as stored_score,
        (
            COALESCE(json_extract_path_text(c.profile, 'cv_score')::DECIMAL, 0) * 
            COALESCE((r.weightings->>'cv')::DECIMAL, 60) / 100
        ) + (
            COALESCE(a.assessment_score, 0) * 
            COALESCE((r.weightings->>'assessment')::DECIMAL, 40) / 100
        ) as calculated_score
    FROM applications a
    JOIN candidates c ON a.candidate_id = c.id
    JOIN requisitions r ON a.requisition_id = r.id
    WHERE a.overall_score IS NOT NULL
)
SELECT 
    COUNT(*) as total_applications,
    COUNT(CASE WHEN ABS(stored_score - calculated_score) < 0.01 THEN 1 END) as correct_scores,
    COUNT(CASE WHEN ABS(stored_score - calculated_score) >= 0.01 THEN 1 END) as incorrect_scores,
    ROUND(
        COUNT(CASE WHEN ABS(stored_score - calculated_score) < 0.01 THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 
        2
    ) as accuracy_percentage
FROM score_check;

-- ============================================================
-- 4. VERIFY JOB WEIGHTINGS CONFIGURATION
-- ============================================================
\echo ''
\echo '=== JOB WEIGHTINGS CONFIGURATION ==='
\echo ''

SELECT 
    r.id as job_id,
    r.title as job_title,
    r.category,
    u.email as created_by_email,
    r.weightings,
    (r.weightings->>'cv')::INT as cv_weight,
    (r.weightings->>'assessment')::INT as assessment_weight,
    COUNT(a.id) as application_count,
    r.vacancy,
    r.created_at
FROM requisitions r
LEFT JOIN users u ON r.created_by = u.id
LEFT JOIN applications a ON a.requisition_id = r.id
GROUP BY r.id, r.title, r.category, u.email, r.weightings, r.vacancy, r.created_at
ORDER BY r.created_at DESC
LIMIT 20;

-- ============================================================
-- 5. VERIFY INTERVIEW SCHEDULING AND NOTIFICATIONS
-- ============================================================
\echo ''
\echo '=== INTERVIEW SCHEDULING STATUS ==='
\echo ''

SELECT 
    i.id as interview_id,
    c.full_name as candidate_name,
    r.title as job_title,
    hm.email as hiring_manager_email,
    i.scheduled_time,
    i.interview_type,
    i.status,
    i.meeting_link,
    CASE 
        WHEN i.scheduled_time > NOW() THEN 'Upcoming'
        WHEN i.scheduled_time < NOW() AND i.status = 'scheduled' THEN 'Overdue'
        ELSE 'Completed/Cancelled'
    END as time_status,
    i.created_at
FROM interviews i
JOIN candidates c ON i.candidate_id = c.id
JOIN applications a ON i.application_id = a.id
JOIN requisitions r ON a.requisition_id = r.id
LEFT JOIN users hm ON i.hiring_manager_id = hm.id
ORDER BY i.scheduled_time DESC
LIMIT 20;

-- Interview status summary
\echo ''
\echo '=== INTERVIEW STATUS SUMMARY ==='
\echo ''

SELECT 
    status,
    COUNT(*) as count,
    interview_type,
    COUNT(CASE WHEN scheduled_time > NOW() THEN 1 END) as upcoming,
    COUNT(CASE WHEN scheduled_time < NOW() THEN 1 END) as past
FROM interviews
GROUP BY status, interview_type
ORDER BY count DESC;

-- ============================================================
-- 6. VERIFY CANDIDATE SHORTLISTING
-- ============================================================
\echo ''
\echo '=== TOP CANDIDATES BY JOB (Shortlist Preview) ==='
\echo ''

-- Show top 5 candidates for each active job
WITH ranked_candidates AS (
    SELECT 
        r.id as job_id,
        r.title as job_title,
        c.full_name as candidate_name,
        COALESCE(json_extract_path_text(c.profile, 'cv_score')::DECIMAL, 0) as cv_score,
        a.assessment_score,
        a.overall_score,
        a.status,
        ROW_NUMBER() OVER (PARTITION BY r.id ORDER BY a.overall_score DESC) as rank
    FROM applications a
    JOIN candidates c ON a.candidate_id = c.id
    JOIN requisitions r ON a.requisition_id = r.id
    WHERE a.overall_score IS NOT NULL
)
SELECT 
    job_id,
    job_title,
    rank,
    candidate_name,
    cv_score,
    assessment_score,
    ROUND(overall_score, 2) as overall_score,
    status
FROM ranked_candidates
WHERE rank <= 5
ORDER BY job_id, rank;

-- ============================================================
-- 7. VERIFY TEAM COLLABORATION DATA
-- ============================================================
\echo ''
\echo '=== TEAM COLLABORATION ACTIVITY ==='
\echo ''

-- Team notes summary
SELECT 
    'Team Notes' as feature,
    COUNT(*) as total_count,
    COUNT(DISTINCT created_by) as active_users,
    MAX(created_at) as last_activity
FROM team_notes
UNION ALL
-- Team messages summary
SELECT 
    'Team Messages' as feature,
    COUNT(*) as total_count,
    COUNT(DISTINCT sender_id) as active_users,
    MAX(sent_at) as last_activity
FROM team_messages
UNION ALL
-- Team activities summary
SELECT 
    'Team Activities' as feature,
    COUNT(*) as total_count,
    COUNT(DISTINCT user_id) as active_users,
    MAX(timestamp) as last_activity
FROM team_activities;

-- ============================================================
-- 8. VERIFY NOTIFICATIONS
-- ============================================================
\echo ''
\echo '=== NOTIFICATION STATUS ==='
\echo ''

SELECT 
    u.email,
    u.role,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN n.is_read THEN 1 END) as read_count,
    COUNT(CASE WHEN NOT n.is_read THEN 1 END) as unread_count,
    MAX(n.created_at) as last_notification
FROM notifications n
JOIN users u ON n.user_id = u.id
GROUP BY u.email, u.role
ORDER BY unread_count DESC, total_notifications DESC
LIMIT 20;

-- ============================================================
-- 9. VERIFY AUDIT LOGS (Admin Actions Only)
-- ============================================================
\echo ''
\echo '=== RECENT AUDIT LOG ENTRIES ==='
\echo ''

SELECT 
    al.id,
    u.email as admin_email,
    al.action,
    tu.email as target_user_email,
    al.timestamp,
    al.ip_address
FROM audit_logs al
LEFT JOIN users u ON al.admin_id = u.id
LEFT JOIN users tu ON al.target_user_id = tu.id
ORDER BY al.timestamp DESC
LIMIT 15;

-- ============================================================
-- 10. DATA CONSISTENCY CHECKS
-- ============================================================
\echo ''
\echo '=== DATA CONSISTENCY CHECKS ==='
\echo ''

-- Check for orphaned records
SELECT 
    'Orphaned Applications (no candidate)' as issue,
    COUNT(*) as count
FROM applications a
LEFT JOIN candidates c ON a.candidate_id = c.id
WHERE c.id IS NULL
UNION ALL
SELECT 
    'Orphaned Applications (no requisition)' as issue,
    COUNT(*) as count
FROM applications a
LEFT JOIN requisitions r ON a.requisition_id = r.id
WHERE r.id IS NULL
UNION ALL
SELECT 
    'Orphaned Interviews (no candidate)' as issue,
    COUNT(*) as count
FROM interviews i
LEFT JOIN candidates c ON i.candidate_id = c.id
WHERE c.id IS NULL
UNION ALL
SELECT 
    'Orphaned Interviews (no application)' as issue,
    COUNT(*) as count
FROM interviews i
LEFT JOIN applications a ON i.application_id = a.id
WHERE a.id IS NULL;

-- ============================================================
-- SUMMARY
-- ============================================================
\echo ''
\echo '==============================================='
\echo 'DATABASE INTEGRITY VERIFICATION COMPLETE'
\echo '==============================================='
\echo ''
\echo 'Review the results above for any issues:'
\echo '1. Score calculations should match (< 0.01 difference)'
\echo '2. All hiring managers should have proper access'
\echo '3. No orphaned records should exist'
\echo '4. Interview notifications should be created'
\echo ''
