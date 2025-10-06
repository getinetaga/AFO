import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../services/admin_service.dart';

class IssueTrackingScreen extends StatefulWidget {
  const IssueTrackingScreen({super.key});

  @override
  State<IssueTrackingScreen> createState() => _IssueTrackingScreenState();
}

class _IssueTrackingScreenState extends State<IssueTrackingScreen> with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  
  List<ContentReport> _allReports = [];
  List<ContentReport> _pendingReports = [];
  List<ContentReport> _reviewedReports = [];
  List<ContentReport> _resolvedReports = [];
  bool _isLoading = true;
  String _selectedTypeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
    _setupStreams();
  }

  void _setupStreams() {
    _adminService.reportsStream.listen((reports) {
      if (mounted) {
        _updateReportLists(reports);
      }
    });
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final reports = await _adminService.getAllReports();
      _updateReportLists(reports);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load reports: $e');
    }
  }

  void _updateReportLists(List<ContentReport> reports) {
    setState(() {
      _allReports = reports;
      _pendingReports = reports.where((r) => r.status == ReportStatus.pending).toList();
      _reviewedReports = reports.where((r) => r.status == ReportStatus.underReview).toList();
      _resolvedReports = reports.where((r) => r.status == ReportStatus.resolved).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Tracking'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'All (${_allReports.length})',
              icon: const Icon(Icons.list, size: 16),
            ),
            Tab(
              text: 'Pending (${_pendingReports.length})',
              icon: const Icon(Icons.pending, size: 16),
            ),
            Tab(
              text: 'Reviewing (${_reviewedReports.length})',
              icon: const Icon(Icons.rate_review, size: 16),
            ),
            Tab(
              text: 'Resolved (${_resolvedReports.length})',
              icon: const Icon(Icons.check_circle, size: 16),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList(_allReports),
                _buildReportsList(_pendingReports),
                _buildReportsList(_reviewedReports),
                _buildReportsList(_resolvedReports),
              ],
            ),
    );
  }

  Widget _buildReportsList(List<ContentReport> reports) {
    final filteredReports = _selectedTypeFilter == 'All' 
        ? reports 
        : reports.where((r) => r.type.toString().split('.').last == _selectedTypeFilter.toLowerCase()).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            Text(
              'Reports will appear here as they are submitted',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        itemCount: filteredReports.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final report = filteredReports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(ContentReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _buildStatusChip(report.status),
                  const SizedBox(width: 8),
                  _buildTypeChip(report.type),
                  const Spacer(),
                  _buildPriorityIndicator(report.priority),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Report title/reason
              Text(
                report.reason,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (report.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  report.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Reporter and target info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Reporter: ${report.reporterUserId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.flag, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${report.reportedContentId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Timestamp and actions
              Row(
                children: [
                  Text(
                    _formatDateTime(report.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  _buildQuickActions(report),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case ReportStatus.underReview:
        color = Colors.blue;
        label = 'Reviewing';
        break;
      case ReportStatus.resolved:
        color = Colors.green;
        label = 'Resolved';
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        label = 'Dismissed';
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTypeChip(ReportType type) {
    final typeStr = type.toString().split('.').last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        typeStr.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(ReportPriority priority) {
    Color color;
    IconData icon;
    
    switch (priority) {
      case ReportPriority.low:
        color = Colors.green;
        icon = Icons.arrow_downward;
        break;
      case ReportPriority.medium:
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case ReportPriority.high:
        color = Colors.red;
        icon = Icons.arrow_upward;
        break;
      case ReportPriority.critical:
        color = Colors.red;
        icon = Icons.priority_high;
        break;
    }
    
    return Tooltip(
      message: '${priority.toString().split('.').last} priority',
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildQuickActions(ContentReport report) {
    if (report.status == ReportStatus.resolved) {
      return const Icon(Icons.check, color: Colors.green, size: 20);
    }
    
    return PopupMenuButton<String>(
      onSelected: (action) => _handleReportAction(action, report),
      itemBuilder: (context) => _buildReportMenuItems(report),
      child: const Icon(Icons.more_vert, color: Colors.grey),
    );
  }

  List<PopupMenuEntry<String>> _buildReportMenuItems(ContentReport report) {
    final currentAdmin = _adminService.currentAdmin;
    final canModerate = currentAdmin != null && 
        _adminService.hasPermission(currentAdmin, AdminPermission.moderateContent);
    
    List<PopupMenuEntry<String>> items = [
      const PopupMenuItem(value: 'view', child: Text('View Details')),
    ];
    
    if (canModerate) {
      if (report.status == ReportStatus.pending) {
        items.add(const PopupMenuItem(value: 'review', child: Text('Start Review')));
      }
      
      if (report.status != ReportStatus.resolved) {
        items.addAll([
          const PopupMenuItem(value: 'resolve', child: Text('Resolve')),
          const PopupMenuItem(value: 'escalate', child: Text('Escalate')),
        ]);
      }
      
      items.addAll([
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete_content', child: Text('Delete Content')),
        const PopupMenuItem(value: 'warn_user', child: Text('Warn User')),
        const PopupMenuItem(value: 'suspend_user', child: Text('Suspend User')),
      ]);
    }
    
    return items;
  }

  void _handleReportAction(String action, ContentReport report) {
    switch (action) {
      case 'view':
        _showReportDetails(report);
        break;
      case 'review':
        _startReview(report);
        break;
      case 'resolve':
        _resolveReport(report);
        break;
      case 'escalate':
        _escalateReport(report);
        break;
      case 'delete_content':
        _deleteContent(report);
        break;
      case 'warn_user':
        _warnUser(report);
        break;
      case 'suspend_user':
        _suspendUser(report);
        break;
    }
  }

  void _showReportDetails(ContentReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Report Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Status and priority
                Row(
                  children: [
                    _buildStatusChip(report.status),
                    const SizedBox(width: 8),
                    _buildTypeChip(report.type),
                    const Spacer(),
                    _buildPriorityIndicator(report.priority),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Report info
                _buildDetailSection('Report Information', [
                  _buildDetailRow('ID', report.reportId),
                  _buildDetailRow('Reason', report.reason),
                  _buildDetailRow('Description', report.description.isNotEmpty ? report.description : 'No description provided'),
                  _buildDetailRow('Created', _formatDateTime(report.createdAt)),
                  _buildDetailRow('Updated', _formatDateTime(report.updatedAt)),
                ]),
                
                const SizedBox(height: 20),
                
                // Reporter info
                _buildDetailSection('Reporter Information', [
                  _buildDetailRow('User ID', report.reporterUserId),
                  _buildDetailRow('Reported At', _formatDateTime(report.createdAt)),
                ]),
                
                const SizedBox(height: 20),
                
                // Target info
                _buildDetailSection('Reported Content', [
                  _buildDetailRow('Content ID', report.reportedContentId),
                  _buildDetailRow('Content Type', report.type.toString().split('.').last),
                  if (report.reportedUserId != null)
                    _buildDetailRow('Reported User', report.reportedUserId!),
                ]),
                
                if (report.resolutionNotes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailSection('Resolution', [
                    _buildDetailRow('Notes', report.resolutionNotes),
                    if (report.resolvedBy != null)
                      _buildDetailRow('Resolved By', report.resolvedBy!),
                  ]),
                ],
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  children: [
                    if (report.status != ReportStatus.resolved) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _startReview(report);
                        },
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Review'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resolveReport(report);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }

  Future<void> _startReview(ContentReport report) async {
    try {
      await _adminService.updateReportStatus(report.reportId, ReportStatus.underReview);
      _showSuccess('Review started for report ${report.reportId}');
      _loadReports();
    } catch (e) {
      _showError('Failed to start review: $e');
    }
  }

  void _resolveReport(ContentReport report) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add resolution notes:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Enter resolution details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.resolveReport(
                  report.reportId, 
                  notesController.text,
                );
                _showSuccess('Report resolved successfully');
                _loadReports();
              } catch (e) {
                _showError('Failed to resolve report: $e');
              }
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _escalateReport(ContentReport report) async {
    final confirmed = await _showConfirmationDialog(
      'Escalate Report',
      'Are you sure you want to escalate this report to higher priority?',
    );
    
    if (confirmed) {
      try {
        // TODO: Implement escalation logic
        _showSuccess('Report escalated successfully');
        _loadReports();
      } catch (e) {
        _showError('Failed to escalate report: $e');
      }
    }
  }

  Future<void> _deleteContent(ContentReport report) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Content',
      'Are you sure you want to delete the reported content? This action cannot be undone.',
    );
    
    if (confirmed) {
      try {
        // TODO: Implement content deletion
        _showSuccess('Content deleted successfully');
        _loadReports();
      } catch (e) {
        _showError('Failed to delete content: $e');
      }
    }
  }

  Future<void> _warnUser(ContentReport report) async {
    if (report.reportedUserId == null) {
      _showError('No user to warn in this report');
      return;
    }
    
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warn User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Send warning to user: ${report.reportedUserId}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Warning message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement user warning
              _showSuccess('Warning sent to user');
            },
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  Future<void> _suspendUser(ContentReport report) async {
    if (report.reportedUserId == null) {
      _showError('No user to suspend in this report');
      return;
    }
    
    final confirmed = await _showConfirmationDialog(
      'Suspend User',
      'Are you sure you want to suspend user ${report.reportedUserId}?',
    );
    
    if (confirmed) {
      try {
        await _adminService.suspendUser(
          report.reportedUserId!,
          'Suspended due to report: ${report.reportId}',
        );
        _showSuccess('User suspended successfully');
        _loadReports();
      } catch (e) {
        _showError('Failed to suspend user: $e');
      }
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Filter by Type:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['All', 'Spam', 'Harassment', 'Inappropriate', 'Violence', 'Other']
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: _selectedTypeFilter == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTypeFilter = type;
                          });
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTypeFilter = 'All';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
