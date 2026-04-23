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
      widget.onUnreadCountChanged?.call(); // 🔔 panggil callback
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
    await _service.deleteAllNotifications();
    widget.onUnreadCountChanged?.call();
    _loadNotifications();
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'order':
        return '🎫';
      case 'reminder':
        return '⏰';
      case 'promo':
        return '🏷️';
      case 'review':
        return '⭐';
      default:
        return '📢';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'baru saja';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: const Color(0xFF1E7AC1),
        foregroundColor: Colors.white,
        actions: [
          if (_notifikasi.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(color: Colors.white),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_all') _deleteAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Text('Hapus Semua'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifikasi.isEmpty
          ? const Center(child: Text('Belum ada notifikasi'))
          : ListView.builder(
              itemCount: _notifikasi.length,
              itemBuilder: (context, index) {
                final item = _notifikasi[index];
                return Dismissible(
                  key: Key(item.id.toString()),
                  background: Container(color: Colors.red),
                  onDismissed: (_) => _deleteNotification(item.id),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isRead
                          ? Colors.grey.shade100
                          : const Color(0xFF1E7AC1).withOpacity(0.1),
                      child: Text(
                        _getTypeIcon(item.type),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: item.isRead
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E7AC1),
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () => _markAsRead(item),
                  ),
                );
              },
            ),
    );
  }
}
