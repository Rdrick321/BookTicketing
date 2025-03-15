import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for tickets
  final List<Map<String, dynamic>> _activeTickets = [
    {
      'id': 'TIX-2025-0001',
      'movieTitle': 'Joker',
      'image': 'assets/movies/joker1.jpg',
      'date': DateTime(2025, 3, 10, 18, 30), // March 10, 2025, 6:30 PM
      'cinema': 'Cinema City - Hall 3',
      'seats': ['F5', 'F6'],
      'totalPrice': 24.99,
      'qrCode':
          'assets/qrcodes/ticket1.png', // You would need to generate real QR codes
    },
    {
      'id': 'TIX-2025-0002',
      'movieTitle': 'Batman',
      'image': 'assets/movies/batman1.jpg',
      'date': DateTime(2025, 3, 15, 20, 0), // March 15, 2025, 8:00 PM
      'cinema': 'Cinema City - Hall 1',
      'seats': ['D7', 'D8', 'D9'],
      'totalPrice': 37.50,
      'qrCode': 'assets/qrcodes/ticket2.png',
    },
  ];

  final List<Map<String, dynamic>> _historyTickets = [
    {
      'id': 'TIX-2025-0000',
      'movieTitle': 'Black Panther',
      'image': 'assets/movies/blackpanther1.jpg',
      'date': DateTime(2025, 2, 20, 19, 15), // Feb 20, 2025, 7:15 PM
      'cinema': 'Cinema City - Hall 2',
      'seats': ['G10', 'G11'],
      'totalPrice': 24.99,
      'qrCode': 'assets/qrcodes/ticket3.png',
    },
    {
      'id': 'TIX-2025-9998',
      'movieTitle': 'Logan',
      'image': 'assets/movies/logan1.jpg',
      'date': DateTime(2025, 1, 30, 21, 0), // Jan 30, 2025, 9:00 PM
      'cinema': 'Cinema City - IMAX',
      'seats': ['H3'],
      'totalPrice': 19.99,
      'qrCode': 'assets/qrcodes/ticket4.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(),
          // Tab bar view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketsList(_activeTickets, true),
                _buildTicketsList(_historyTickets, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.amber,
        indicatorWeight: 3,
        labelColor: Colors.amber,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        tabs: const [Tab(text: 'UPCOMING'), Tab(text: 'HISTORY')],
      ),
    );
  }

  Widget _buildTicketsList(List<Map<String, dynamic>> tickets, bool isActive) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.local_activity_outlined : Icons.history,
              size: 60,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No upcoming tickets' : 'No ticket history',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Navigate to homepage or booking section
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Navigating to homepage")),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.amber),
              child: const Text('Browse Movies'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket, isActive);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isActive) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final now = DateTime.now();

    // Check if ticket is today
    final isToday =
        ticket['date'].year == now.year &&
        ticket['date'].month == now.month &&
        ticket['date'].day == now.day;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with movie image and basic info
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Movie poster
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 100,
                    child: Image.asset(
                      ticket['image'],
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.movie,
                              size: 40,
                              color: Colors.white54,
                            ),
                          ),
                    ),
                  ),
                ),
                // Movie info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (isToday && isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red[700],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                ticket['movieTitle'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(ticket['date']),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(ticket['date']),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dashed divider
          _buildDashedDivider(),

          // Details section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInfoRow('Cinema', ticket['cinema']),
                const SizedBox(height: 8),
                _buildInfoRow('Seats', ticket['seats'].join(', ')),
                const SizedBox(height: 8),
                _buildInfoRow('Ticket ID', ticket['id']),
              ],
            ),
          ),

          // QR code and actions
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // QR code (placeholder)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(right: 12),
                  child: const Center(
                    child: Icon(Icons.qr_code, size: 60, color: Colors.black),
                  ),
                ),
                // Action buttons
                Expanded(
                  child: Column(
                    children: [
                      if (isActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Adding to wallet..."),
                                ),
                              );
                            },
                            icon: const Icon(Icons.wallet, size: 16),
                            label: const Text(
                              'Add to Wallet',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isActive
                                      ? "Sharing ticket details..."
                                      : "Viewing ticket details...",
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            isActive ? Icons.share : Icons.receipt_long,
                            size: 16,
                          ),
                          label: Text(
                            isActive ? 'Share' : 'Details',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 8.0;
          const dashSpace = 4.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return Container(
                width: dashWidth,
                height: 1,
                color: Colors.grey[700],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
