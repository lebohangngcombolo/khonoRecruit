# Analytics Page Redesign - Summary

## Overview
The Hiring Manager Analytics page has been completely redesigned to use real data from existing backend endpoints and remove all mock/placeholder data.

## Changes Made

### 1. AdminService Updates (`lib/services/admin_service.dart`)

#### Time Range Support
- **Added**: Proper time range mapping (`1m`, `3m`, `6m`, `1y`) to days parameter
- **Updated**: `getAnalytics()` method now:
  - Passes `days` query parameter to `/analytics/users-growth` endpoint
  - Makes parallel API calls using `Future.wait()` for better performance
  - Properly converts interview status and type data from lists to maps

#### New Data Mappings
Added mappings for previously unused backend data:
- `monthly_applications`: Monthly application counts
- `cv_score_distribution`: CV score ranges and counts
- `interview_status_breakdown`: Interview statuses (scheduled, completed, cancelled, etc.)
- `interviews_by_type`: Interview types (phone, video, in-person, etc.)
- `assessment_score_distribution`: Assessment score ranges
- `average_scores_by_requisition`: Average assessment scores per job

### 2. HMAnalyticsPage Complete Rewrite (`lib/screens/hiring_manager/hm_analytics_page.dart`)

#### State Management
- **Simplified**: Reduced state variables to just `_analyticsData`, `_isLoading`, `_error`, `_selectedTimeRange`
- **Fixed**: Time range values now use API format (`'1m'`, `'3m'`, etc.) instead of display strings

#### UI Header
- **Hidden**: Export CSV button (commented out) until backend supports it
- **Fixed**: Refresh button now calls `_loadAnalytics()` method

#### Time Range Selector
- **Updated**: Dropdown now uses correct API values with display label mapping
- **Added**: Helper text noting that time range only applies to User Growth chart

#### Error Handling
- **Added**: Dedicated `_buildErrorState()` widget with retry button
- **Improved**: Better error messages and user feedback

#### Key Metrics Tiles (Row 1)
**Real Data (3 tiles)**:
- Total Applications
- Total Hires
- Quality Score (from average assessment score)

**Placeholder Tiles (2 tiles)** - greyed out with "Coming soon" label:
- Avg Time to Fill
- Cost per Hire

#### New Chart Widgets (All Using Real Data)

**Row 2: Status Breakdown | Top Jobs**
- `_buildStatusBreakdownChart()`: Doughnut chart of application statuses
- `_buildTopJobsChart()`: Column chart of top jobs by application count

**Row 3: User Growth | Monthly Applications**
- `_buildUserGrowthChart()`: Line chart of user growth (respects time range)
- `_buildMonthlyApplicationsChart()`: Column chart of monthly applications

**Row 4: Interview Status | Interviews by Type**
- `_buildInterviewStatusChart()`: Bar chart of interview statuses
- `_buildInterviewsByTypeChart()`: Pie chart of interview types

**Row 5: CV Score Distribution | Assessment Score Distribution**
- `_buildCVScoreDistributionChart()`: Column chart of CV score ranges
- `_buildAssessmentScoreDistributionChart()`: Column chart of assessment score ranges

**Row 6: Average Assessment by Requisition**
- `_buildAverageAssessmentByRequisitionChart()`: Bar chart of average scores per job

**Footer: Conversion Funnel**
- `_buildConversionFunnel()`: 3-stage funnel (Applied → Interviewed → Hired)

#### Removed Components
- All mock data functions (`_getHiringTrendData()`, `_getSourceData()`, etc.)
- Predictive analytics panel (not supported by backend)
- Detailed reports section (not implemented in backend)
- Unused chart widgets

#### Helper Methods
- `_buildChartContainer()`: Consistent chart wrapper with title
- `_buildEmptyChart()`: Empty state for charts with no data
- `_buildFunnelStep()`: Individual funnel stage component

## Backend Endpoints Used

All endpoints are protected by `@role_required(["admin", "hiring_manager"])`:

1. `GET /api/admin/analytics/dashboard`
   - Total counts (users, candidates, requisitions, applications)
   - Application status breakdown
   - Recent activity (last 7 days)
   - Average scores (CV and assessment)

2. `GET /api/admin/analytics/users-growth?days={30|90|180|365}`
   - User growth data over time
   - Candidate growth subset

3. `GET /api/admin/analytics/applications-analysis`
   - Applications by requisition (top 10)
   - CV score distribution
   - Monthly applications

4. `GET /api/admin/analytics/interviews-analysis`
   - Interview status breakdown
   - Interviews by type
   - Monthly interviews

5. `GET /api/admin/analytics/assessments-analysis`
   - Assessment score distribution
   - Recommendation breakdown
   - Average scores by requisition

## Data Flow

```
User selects time range
    ↓
HMAnalyticsPage._loadAnalytics()
    ↓
AdminService.getAnalytics(timeRange: '1m')
    ↓
Parallel API calls to 5 endpoints
    ↓
Parse and map responses
    ↓
setState with _analyticsData
    ↓
UI renders charts with real data
```

## Empty States

Three types of empty states handled:
1. **Loading**: Shows spinner with "Loading analytics..." message
2. **Error**: Shows error icon, message, and retry button
3. **No Data**: Shows "No Analytics Data Available" when `total_applications == 0`
4. **Per-Chart Empty**: Each chart shows "No data available" if its dataset is empty

## Features

### Implemented ✅
- Real-time data from 5 backend endpoints
- Time range selector (affects User Growth chart)
- All available backend metrics displayed
- Conversion funnel with real counts
- Empty/loading/error states
- Proper role-based access (admin, hiring_manager)
- Responsive layout with glassmorphism design
- Data refresh functionality

### Not Implemented (Backend Gaps) ⚠️
- Export to CSV (button hidden)
- Avg Time to Fill metric (placeholder tile)
- Cost per Hire metric (placeholder tile)
- Shortlisted count in funnel (shows 0)
- Time range support for non-growth endpoints
- Source performance data
- Diversity metrics
- Predictive analytics

## Dependencies

No new dependencies required. Uses existing:
- `syncfusion_flutter_charts` for all charts
- `http` for API calls
- `flutter_secure_storage` (via AuthService) for token management

## Next Steps (Optional Backend Enhancements)

1. **Add time filtering** to dashboard and analysis endpoints
2. **Implement** avg_time_to_fill calculation (hire date - requisition created date)
3. **Implement** cost_per_hire if cost data exists
4. **Add** shortlisted status to application workflow
5. **Create** export endpoint: `GET /api/admin/analytics/export?type=...&format=csv`
6. **Add** source tracking to applications (LinkedIn, Indeed, referral, etc.)
7. **Add** diversity fields to candidate profiles
8. **Consider** adding predictive analytics endpoint if desired

## Testing Checklist

- [ ] Page loads without errors
- [ ] Time range selector updates User Growth chart
- [ ] All charts display when data exists
- [ ] Empty states show when no data available
- [ ] Error state shows on API failure with retry button
- [ ] Refresh button reloads all data
- [ ] Placeholder metrics clearly marked as "Coming soon"
- [ ] Role-based access works (hiring_manager and admin only)
- [ ] Charts are responsive and readable
- [ ] No mock data is displayed

## Migration Notes

- **Breaking Change**: Old mock data functions removed
- **State Structure**: Simplified from multiple state variables to single `_analyticsData` map
- **Time Range Format**: Changed from display strings to API codes
- **No Migration Needed**: Page is self-contained, no database changes required

## Files Modified

1. `lib/services/admin_service.dart` (Updated `getAnalytics` method)
2. `lib/screens/hiring_manager/hm_analytics_page.dart` (Complete rewrite)

## Files NOT Modified

- Backend routes (all existing endpoints used as-is)
- Database models
- Other frontend pages
- Authentication/authorization logic
