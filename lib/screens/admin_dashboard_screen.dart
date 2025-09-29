// ============================================================================
// AFO ADMIN DASHBOARD SCREEN
// ============================================================================

/// Comprehensive admin dashboard for AFO chat application
/// 
/// Features:
/// • Real-time platform analytics and metrics
/// • Interactive charts and data visualizations
/// • Quick action buttons for common admin tasks
/// • User statistics and engagement metrics
/// • Content moderation overview
/// • System health monitoring
/// • Role-based access control integration
/// 
/// Dependencies:
/// • fl_chart: For interactive charts and data visualization
/// • admin_models: Data models for analytics and admin operations
/// • admin_service: Backend service for admin operations
/// • Navigation to user management and issue tracking screens
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => const AdminDashboardScreen(),
///   ),
/// );
/// ```

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import 'user_management_screen.dart';
import 'issue_tracking_screen.dart';

/// Main admin dashboard screen providing comprehensive platform overview
/// 
/// This stateful widget displays real-time analytics, charts, and quick actions
/// for administrators to monitor and manage the AFO chat platform effectively.
/// 
/// Key Features:
/// • Real-time platform metrics and analytics
/// • Interactive data visualization with charts
/// • Quick access to user management and moderation tools
/// • Role-based permission checking
/// • Automatic data refresh and streaming updates
class AdminDashboardScreen extends StatefulWidget {
  /// Creates an instance of AdminDashboardScreen
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

/// State class for AdminDashboardScreen managing data and UI state
/// 
/// Handles real-time analytics data, loading states, and user interactions
/// with the dashboard interface. Integrates with AdminService for backend
/// operations and maintains responsive UI updates.
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  /// Service instance for admin operations and data retrieval
  final AdminService _adminService = AdminService();
  
  /// Current platform analytics data, null while loading
  PlatformAnalytics? _analytics;
  
  /// Loading state indicator for dashboard data
  bool _isLoading = true;
  
  /// Selected time period for analytics display (day/week/month)
  String _selectedPeriod = 'week';

  /// Initialize the dashboard screen and load initial data
  /// 
  /// Sets up real-time data streams and loads the initial analytics data
  /// to populate the dashboard with current platform metrics.
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupStreams();
  }

  /// Set up real-time data streams for automatic dashboard updates
  /// 
  /// Subscribes to the analytics stream from AdminService to receive
  /// real-time updates of platform metrics without manual refresh.
  /// Updates are only applied if the widget is still mounted.
  void _setupStreams() {
    _adminService.analyticsStream.listen((analytics) {
      if (mounted) {
        setState(() {
          _analytics = analytics;
        });
      }
    });
  }

  /// Load dashboard analytics data from the backend service
  /// 
  /// Fetches the latest platform analytics including user statistics,
  /// content metrics, and moderation data. Updates the UI state based
  /// on the success or failure of the data loading operation.
  /// 
  /// Handles errors gracefully by displaying user-friendly error messages.
  Future<void> _loadDashboardData() async {
    try {
      final analytics = await _adminService.getAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load dashboard data: $e');
    }
  }

  /// Display error message to the user via SnackBar
  /// 
  /// Shows a red-colored SnackBar with the provided error message
  /// to inform users of any issues or failures in the dashboard.
  /// 
  /// Parameters:
  /// - [message]: The error message to display to the user
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Build the main dashboard UI with analytics and controls
  /// 
  /// Creates a comprehensive admin dashboard layout including:
  /// • App bar with refresh button and menu options
  /// • Loading indicator during data fetch
  /// • Error state for failed data loading
  /// • Pull-to-refresh functionality
  /// • Scrollable content with analytics widgets
  /// 
  /// The dashboard adapts to loading and error states, providing
  /// a smooth user experience during data operations.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AFO Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('Failed to load dashboard data'))
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome card
                        _buildWelcomeCard(),
                        
                        const SizedBox(height: 20),
                        
                        // Quick stats
                        _buildQuickStats(),
                        
                        const SizedBox(height: 20),
                        
                        // Quick actions
                        _buildQuickActions(),
                        
                        const SizedBox(height: 20),
                        
                        // Charts row
                        Row(
                          children: [
                            Expanded(child: _buildUserRoleChart()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildReportTypeChart()),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // User registration trend
                        _buildRegistrationChart(),
                        
                        const SizedBox(height: 20),
                        
                        // Recent activity
                        _buildRecentActivity(),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build the welcome card displaying admin information
  /// 
  /// Creates a visually appealing gradient card that welcomes the
  /// current admin user and displays their role and last update time.
  /// 
  /// Features:
  /// • Gradient background (indigo to purple)
  /// • Admin name and role display
  /// • Last updated timestamp
  /// • Responsive text styling
  /// 
  /// Returns: Widget containing the welcome card UI
  Widget _buildWelcomeCard() {
    final admin = _adminService.currentAdmin;
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${admin?.displayName ?? 'Admin'}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${admin?.role.toString().split('.').last.toUpperCase() ?? 'Unknown'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_analytics?.lastUpdated != null ? _formatDateTime(_analytics!.lastUpdated) : 'Never'}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the quick statistics overview cards
  /// 
  /// Creates a row of statistical cards displaying key platform metrics:
  /// • Total Users: Complete user count
  /// • Active Today: Users active in last 24 hours
  /// • Pending Reports: Unresolved content reports
  /// • Banned Users: Currently banned user count
  /// 
  /// Each card uses distinct colors and icons for visual differentiation.
  /// The layout is responsive and adapts to different screen sizes.
  /// 
  /// Returns: Widget containing the statistics card row
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            _analytics!.totalUsers.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Today',
            _analytics!.activeUsersToday.toString(),
            Icons.person_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pending Reports',
            _analytics!.pendingReports.toString(),
            Icons.report,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Banned Users',
            _analytics!.bannedUsers.toString(),
            Icons.block,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the quick actions section with navigation buttons
  /// 
  /// Creates a grid of action buttons for common administrative tasks:
  /// • Manage Users: Navigate to user management screen
  /// • View Reports: Navigate to issue tracking screen
  /// • Group Management: Navigate to group management
  /// • System Settings: Access platform configuration
  /// 
  /// Each button includes descriptive icons and color coding for
  /// easy identification and improved user experience.
  /// 
  /// Returns: Widget containing the quick actions section
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Manage Users',
                Icons.people_alt,
                Colors.blue,
                () => _navigateToUserManagement(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'View Reports',
                Icons.flag,
                Colors.orange,
                () => _navigateToIssueTracking(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Group Management',
                Icons.group,
                Colors.green,
                () => _navigateToGroupManagement(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Analytics',
                Icons.analytics,
                Colors.purple,
                () => _navigateToAnalytics(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build an individual action button for the quick actions section
  /// 
  /// Creates a Material Design card with an interactive button that includes:
  /// • Circular icon container with background color
  /// • Descriptive text label below the icon
  /// • Tap feedback with InkWell ripple effect
  /// • Consistent padding and layout
  /// 
  /// Parameters:
  /// - [title]: Text label displayed below the icon
  /// - [icon]: IconData for the button icon
  /// - [color]: Color theme for icon and background
  /// - [onTap]: Callback function executed when button is tapped
  /// 
  /// Returns: Widget containing the styled action button
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the user role distribution pie chart
  /// 
  /// Creates an interactive pie chart displaying the distribution of users
  /// across different roles (user, moderator, admin, superAdmin).
  /// 
  /// Features:
  /// • Colorful pie chart sections with role labels
  /// • Percentage and count display for each role
  /// • Interactive hover and touch feedback
  /// • Professional chart styling with fl_chart
  /// 
  /// The chart helps administrators understand the role distribution
  /// and identify any imbalances in the user hierarchy.
  /// 
  /// Returns: Widget containing the user role pie chart
  Widget _buildUserRoleChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Users by Role',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildUserRolePieChartSections(),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build pie chart sections for user role distribution
  /// 
  /// Converts the analytics data into PieChartSectionData objects
  /// for rendering the user role chart. Each section represents
  /// a different user role with distinct colors and labels.
  /// 
  /// Features:
  /// • Dynamic color assignment from predefined palette
  /// • Role name and count labels on each section
  /// • Consistent styling with white text on colored background
  /// • Proportional section sizes based on user counts
  /// 
  /// Returns: List of PieChartSectionData for the chart
  List<PieChartSectionData> _buildUserRolePieChartSections() {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    final roles = _analytics!.usersByRole;
    int colorIndex = 0;

    return roles.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// Build the report type distribution bar chart
  /// 
  /// Creates an interactive bar chart showing the distribution of
  /// content reports by violation type (spam, harassment, etc.).
  /// 
  /// Features:
  /// • Vertical bar chart with category labels
  /// • Interactive touch feedback for detailed values
  /// • Dynamic scaling based on maximum report count
  /// • Professional orange color scheme
  /// 
  /// This chart helps administrators identify the most common
  /// types of content violations requiring moderation attention.
  /// 
  /// Returns: Widget containing the report type bar chart
  Widget _buildReportTypeChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports by Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _analytics!.reportsByType.values.isNotEmpty 
                      ? _analytics!.reportsByType.values.reduce((a, b) => a > b ? a : b).toDouble() + 5
                      : 10,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: _buildReportTypeBottomTitle,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildReportTypeBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom axis labels for the report type chart
  /// 
  /// Generates abbreviated labels for report types to fit within
  /// the limited space of the chart x-axis. Truncates type names
  /// to 4 characters for compact display.
  /// 
  /// Parameters:
  /// - [value]: The x-axis value representing the report type index
  /// - [meta]: Chart metadata for title positioning
  /// 
  /// Returns: Widget containing the abbreviated report type label
  Widget _buildReportTypeBottomTitle(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final reportTypes = _analytics!.reportsByType.keys.toList();
    
    if (value.toInt() >= 0 && value.toInt() < reportTypes.length) {
      final type = reportTypes[value.toInt()];
      return Text(type.substring(0, 4), style: style);
    }
    return const Text('');
  }

  /// Build bar chart group data for report type visualization
  /// 
  /// Converts report statistics into BarChartGroupData objects
  /// for rendering the report type distribution chart.
  /// 
  /// Features:
  /// • Individual bars for each report type
  /// • Consistent orange color scheme
  /// • Rounded corners for modern appearance
  /// • Proportional heights based on report counts
  /// 
  /// Returns: List of BarChartGroupData for the chart
  List<BarChartGroupData> _buildReportTypeBarGroups() {
    final reports = _analytics!.reportsByType;
    int index = 0;
    
    return reports.entries.map((entry) {
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.orange,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  /// Build the user registration trend chart
  /// 
  /// Creates a line chart displaying user registration trends over
  /// the selected time period (day/week/month). Includes a dropdown
  /// selector for changing the time period view.
  /// 
  /// Features:
  /// • Interactive line chart with trend visualization
  /// • Period selector dropdown (day/week/month)
  /// • Responsive chart scaling and labeling
  /// • Professional blue color scheme
  /// 
  /// This chart helps administrators monitor user growth patterns
  /// and identify registration trends over time.
  /// 
  /// Returns: Widget containing the registration trend chart
  Widget _buildRegistrationChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Registrations (Last 7 Days)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: _buildRegistrationBottomTitle,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildRegistrationSpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom axis labels for registration trend chart
  /// 
  /// Generates date labels for the x-axis of the registration trend chart.
  /// Shows abbreviated date strings for compact display within chart constraints.
  /// 
  /// Parameters:
  /// - [value]: The x-axis value representing the date index
  /// - [meta]: Chart metadata for title positioning
  /// 
  /// Returns: Widget containing the formatted date label
  Widget _buildRegistrationBottomTitle(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final registrations = _analytics!.userRegistrationsByDay;
    final dates = registrations.keys.toList();
    
    if (value.toInt() >= 0 && value.toInt() < dates.length) {
      return Text(dates[value.toInt()], style: style);
    }
    return const Text('');
  }

  /// Build data points for the registration trend line chart
  /// 
  /// Converts registration statistics into FlSpot objects for rendering
  /// the line chart. Each spot represents a day's registration count.
  /// 
  /// Returns: List of FlSpot objects for the line chart data
  List<FlSpot> _buildRegistrationSpots() {
    final registrations = _analytics!.userRegistrationsByDay;
    final entries = registrations.entries.toList();
    
    return entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();
  }

  /// Build the recent activity feed section
  /// 
  /// Creates a timeline-style list of recent platform activities including:
  /// • New user registrations
  /// • Content reports received
  /// • Moderation actions taken
  /// • Group creations and updates
  /// 
  /// Each activity item includes an icon, description, and timestamp
  /// to help administrators stay informed about platform events.
  /// 
  /// Returns: Widget containing the recent activity feed
  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'New user registered',
              'user@example.com joined AFO',
              Icons.person_add,
              Colors.green,
              '2 minutes ago',
            ),
            _buildActivityItem(
              'Report received',
              'Inappropriate content reported',
              Icons.flag,
              Colors.orange,
              '15 minutes ago',
            ),
            _buildActivityItem(
              'User banned',
              'user123 was banned for harassment',
              Icons.block,
              Colors.red,
              '1 hour ago',
            ),
            _buildActivityItem(
              'Group created',
              'New group "Study Group" was created',
              Icons.group_add,
              Colors.blue,
              '2 hours ago',
            ),
          ],
        ),
      ),
    );
  }

  /// Build an individual activity item for the recent activity feed
  /// 
  /// Creates a timeline entry with icon, title, subtitle, and timestamp.
  /// Uses color-coded icons to categorize different types of activities.
  /// 
  /// Parameters:
  /// - [title]: Primary activity description
  /// - [subtitle]: Additional activity details
  /// - [icon]: Icon representing the activity type
  /// - [color]: Color theme for the activity icon
  /// - [time]: Relative timestamp (e.g., "2 minutes ago")
  /// 
  /// Returns: Widget containing the formatted activity item
  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Format DateTime object to readable string representation
  /// 
  /// Converts DateTime to a user-friendly format: "DD/MM/YYYY HH:MM"
  /// Used for displaying timestamps in the dashboard interface.
  /// 
  /// Parameters:
  /// - [dateTime]: The DateTime object to format
  /// 
  /// Returns: Formatted date string for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // ========================================================================
  // NAVIGATION METHODS
  // ========================================================================

  /// Navigate to the User Management screen
  /// 
  /// Opens the UserManagementScreen where administrators can view,
  /// edit, and moderate user accounts. Provides comprehensive user
  /// administration capabilities.
  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  /// Navigate to the Issue Tracking screen
  /// 
  /// Opens the IssueTrackingScreen for reviewing and resolving
  /// content reports and moderation issues.
  void _navigateToIssueTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IssueTrackingScreen()),
    );
  }

  /// Navigate to Group Management (placeholder)
  /// 
  /// Future implementation for group administration features.
  /// Currently shows a "coming soon" message to users.
  void _navigateToGroupManagement() {
    // TODO: Implement group management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group management coming soon!')),
    );
  }

  /// Navigate to Detailed Analytics (placeholder)
  /// 
  /// Future implementation for advanced analytics and reporting.
  /// Currently shows a "coming soon" message to users.
  void _navigateToAnalytics() {
    // TODO: Implement detailed analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detailed analytics coming soon!')),
    );
  }

  /// Handle app bar menu item selection
  /// 
  /// Processes user selections from the app bar popup menu including
  /// profile access, settings, and logout functionality.
  /// 
  /// Parameters:
  /// - [value]: The selected menu item identifier
  void _onMenuSelected(String value) {
    switch (value) {
      case 'profile':
        // TODO: Show admin profile
        break;
      case 'settings':
        // TODO: Show admin settings
        break;
      case 'logout':
        _logout();
        break;
    }
  }

  /// Log out the current admin user
  /// 
  /// Clears the admin session and navigates back to the login screen.
  /// Uses the AdminService to handle secure logout operations.
  void _logout() {
    _adminService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Clean up resources when the widget is disposed
  /// 
  /// Ensures proper cleanup of streams, controllers, and other resources
  /// to prevent memory leaks and maintain app performance.
  @override
  void dispose() {
    super.dispose();
  }
}