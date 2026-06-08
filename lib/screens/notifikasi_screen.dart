import 'package:flutter/material.dart';
import '../services/notifikasi_service.dart';
import '../models/notifikasi.dart';

class NotifikasiScreen extends StatefulWidget {
  final VoidCallback? onUnreadCountChanged;
  const NotifikasiScreen({super.key, this.onUnreadCountChanged});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final NotifikasiService _service = NotifikasiService();
  List<Notifikasi> _notifikasi = [];
  bool _isLoading = true;
  String _filter = 'semua';

  static const Color _brandBlue = Color(0xFF1E7AC1);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await _service.getNotifications();
    setState(() {
      _notifikasi = data;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(Notifikasi item) async {
    if (!item.isRead) {
      await _service.markAsRead(item.id);
      widget.onUnreadCountChanged?.call();
      _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    widget.onUnreadCountChanged?.call();
    _loadNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    await _service.deleteNotification(id);
    widget.onUnreadCountChanged?.call();
    _loadNotifications();
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua?'),
        content: const Text('Semua notifikasi akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteAllNotifications();
      widget.onUnreadCountChanged?.call();
      _loadNotifications();
    }
  }

  List<Notifikasi> get _filteredNotifikasi {
    if (_filter == 'semua') return _notifikasi;
    if (_filter == 'belum_dibaca') {
      return _notifikasi.where((n) => !n.isRead).toList();
    }
    return _notifikasi.where((n) => n.type == _filter).toList();
  }

  _NotifStyle _getStyle(String type) {
    switch (type) {
      case 'order':
        return _NotifStyle(
          icon: Icons.confirmation_number_rounded,
          color: _brandBlue,
          bg: const Color(0xFFEBF5FF),
          label: 'Pesanan',
        );
      case 'reminder':
        return _NotifStyle(
          icon: Icons.alarm_rounded,
          color: const Color(0xFFF97316),
          bg: const Color(0xFFFFF7ED),
          label: 'Pengingat',
        );
      case 'promo':
        return _NotifStyle(
          icon: Icons.local_offer_rounded,
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFECFDF5),
          label: 'Promo',
        );
      default:
        return _NotifStyle(
          icon: Icons.notifications_rounded,
          color: Colors.grey,
          bg: Colors.grey.shade100,
          label: 'Info',
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 7) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifikasi.where((n) => !n.isRead).length;
    final filtered = _filteredNotifikasi;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount belum dibaca',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text(
                'Baca Semua',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete_all') _deleteAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: _brandBlue,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: _filter == 'semua',
                      onTap: () => setState(() => _filter = 'semua'),
                    ),
                    _FilterChip(
                      label: 'Belum Dibaca',
                      selected: _filter == 'belum_dibaca',
                      onTap: () => setState(() => _filter = 'belum_dibaca'),
                      badge: unreadCount > 0 ? unreadCount : null,
                    ),
                    _FilterChip(
                      label: 'Pesanan',
                      selected: _filter == 'order',
                      onTap: () => setState(() => _filter = 'order'),
                    ),
                    _FilterChip(
                      label: 'Pengingat',
                      selected: _filter == 'reminder',
                      onTap: () => setState(() => _filter = 'reminder'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // List notifikasi
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _brandBlue),
                  )
                : filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: _brandBlue,
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildNotifCard(filtered[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(Notifikasi item) {
    final style = _getStyle(item.type);

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _deleteNotification(item.id),
      child: GestureDetector(
        onTap: () => _markAsRead(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFEBF5FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead
                  ? Colors.grey.shade200
                  : _brandBlue.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.color, size: 22),
                ),
                const SizedBox(width: 12),

                // Konten
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _brandBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: style.bg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: style.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: _brandBlue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi pemesanan akan muncul di sini',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  _NotifStyle({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E7AC1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF1E7AC1)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFF1E7AC1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected ? const Color(0xFF1E7AC1) : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}