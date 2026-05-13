class MockData {
  static final List<Map<String, dynamic>> notices = [
    {
      'id': '1',
      'title': 'Pool Maintenance',
      'description': 'The main swimming pool will be closed for regular maintenance this Thursday from 8 AM to 2 PM.',
      'date': 'Oct 24, 2026',
      'isUrgent': false,
    },
    {
      'id': '2',
      'title': 'Elevator B Out of Service',
      'description': 'Elevator B in the North Wing is currently undergoing repairs. Please use Elevator A.',
      'date': 'Oct 23, 2026',
      'isUrgent': true,
    },
    {
      'id': '3',
      'title': 'Community BBQ',
      'description': 'Join us for the monthly community BBQ this Saturday at the rooftop garden!',
      'date': 'Oct 20, 2026',
      'isUrgent': false,
    },
  ];

  static final List<Map<String, dynamic>> activeBills = [
    {
      'id': 'b1',
      'title': 'Maintenance Fee',
      'period': 'October 2026',
      'amount': 150.00,
      'status': 'Unpaid',
      'dueDate': 'Oct 31, 2026',
    },
    {
      'id': 'b2',
      'title': 'Water Bill',
      'period': 'September 2026',
      'amount': 45.50,
      'status': 'Paid',
      'dueDate': 'Oct 15, 2026',
    },
  ];

  static final List<Map<String, dynamic>> recentVisitors = [
    {
      'id': 'v1',
      'name': 'John Doe',
      'type': 'Delivery',
      'time': 'Today, 10:30 AM',
      'status': 'Completed',
    },
    {
      'id': 'v2',
      'name': 'Jane Smith',
      'type': 'Guest',
      'time': 'Yesterday, 4:00 PM',
      'status': 'Completed',
    },
  ];
}
