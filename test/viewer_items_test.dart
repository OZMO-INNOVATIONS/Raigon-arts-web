import 'package:flutter_test/flutter_test.dart';
import 'package:raigon_art/core/widgets/app_image_viewer.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

void main() {
  test('viewerItemsFromCustomer includes all photos when frames < photos', () {
    final customer = Customer.fromJson({
      'id': 'RA-1025',
      'name': 'sanjay',
      'phone': '5959292949',
      'city': '',
      'photoCount': 3,
      'photoUrls': [
        'https://supabase.co/storage/v1/object/public/raigon-art-storage/customers/RA-1025/photos/My_way_1794677247429_eovo9.webp',
        'https://supabase.co/storage/v1/object/public/raigon-art-storage/customers/RA-1025/photos/scaled_1000350189.webp',
        'https://supabase.co/storage/v1/object/public/raigon-art-storage/customers/RA-1023/photos/My_way.webp',
      ],
      'photoNames': [
        'My_way_1794677247429_eovo9.webp',
        'scaled_1000350189.webp',
        'My_way.webp',
      ],
      'photoSizeLabels': [
        '0.2 MB',
        '0.0 MB',
        'High-Res Photo',
      ],
      'frames': [
        {
          'id': '430df752-73e8-43cd-ab36-0b1118e5a49d',
          'size': '12x18',
          'unit': 'Inches',
          'frameType': 'Wooden Frame',
          'material': 'Teak Wood Moulding',
          'finish': 'Walnut Brown',
          'orientation': 'Landscape (Horizontal)',
          'qty': 2,
          'notes': '',
          'photoName': 'My_way.webp',
          'photoUrl':
              'https://supabase.co/storage/v1/object/public/raigon-art-storage/customers/RA-1023/photos/My_way.webp',
        },
      ],
      'qty': 2,
    });

    final items = viewerItemsFromCustomer(customer);

    expect(items.length, 3, reason: 'All 3 artworks must be in the viewer items');
    expect(items[0].url, contains('My_way.webp'));
    expect(items[1].url, contains('My_way_1794677247429_eovo9.webp'));
    expect(items[2].url, contains('scaled_1000350189.webp'));
  });

  test('viewerItemsFromCustomer handles empty frames with multiple photos', () {
    final customer = Customer.fromJson({
      'id': 'RA-1026',
      'name': 'test customer',
      'phone': '1234567890',
      'city': '',
      'photoUrls': [
        'https://supabase.co/photos/1.webp',
        'https://supabase.co/photos/2.webp',
        'https://supabase.co/photos/3.webp',
      ],
      'photoNames': ['1.webp', '2.webp', '3.webp'],
      'frames': [],
    });

    final items = viewerItemsFromCustomer(customer);
    expect(items.length, 3);
    expect(items[0].title, 'Artwork #1');
    expect(items[1].title, 'Artwork #2');
    expect(items[2].title, 'Artwork #3');
  });

  test('viewerItemsFromCustomer deduplicates exact URLs with query params', () {
    final customer = Customer.fromJson({
      'id': 'RA-1027',
      'name': 'test customer',
      'phone': '1234567890',
      'city': '',
      'photoUrls': [
        'https://supabase.co/photos/1.webp?t=100',
        'https://supabase.co/photos/1.webp?t=200',
        'https://supabase.co/photos/2.webp',
      ],
      'photoNames': ['1.webp', '1.webp', '2.webp'],
      'frames': [],
    });

    final items = viewerItemsFromCustomer(customer);
    expect(items.length, 2);
  });
}
