class Review {
  final int idUlasan;
  final double rating;
  final String reviewText;
  final String userName;
  final String tanggalUlasan;

  Review({
    required this.idUlasan,
    required this.rating,
    required this.reviewText,
    required this.userName,
    required this.tanggalUlasan,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String name = 'Pengguna Anonim';
    if (json['users'] != null && json['users']['name'] != null) {
      name = json['users']['name'];
    }

    return Review(
      idUlasan: json['id_ulasan'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: json['komentar'] ?? 'Tidak ada komentar.',
      tanggalUlasan: json['tanggal_ulasan'] ?? '',
      userName: name,
    );
  }
}
