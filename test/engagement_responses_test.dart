import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/data/models/engagement_responses.dart';

void main() {
  group('LikeVideoResult.fromJson', () {
    test('parses likes, dislikes, liked', () {
      final r = LikeVideoResult.fromJson({'likes': 5, 'dislikes': 0, 'liked': true});
      expect(r.likes, 5);
      expect(r.dislikes, 0);
      expect(r.liked, true);
    });

    test('parses isActive as liked', () {
      final r = LikeVideoResult.fromJson({'likes': 10, 'isActive': true});
      expect(r.liked, true);
    });

    test('defaults when empty', () {
      final r = LikeVideoResult.fromJson({});
      expect(r.likes, 0);
      expect(r.dislikes, 0);
      expect(r.liked, false);
    });
  });

  group('SubscribeResult.fromJson', () {
    test('parses subscriberCount and isSubscribed', () {
      final r = SubscribeResult.fromJson({'subscriberCount': 100, 'isSubscribed': true});
      expect(r.subscriberCount, 100);
      expect(r.isSubscribed, true);
    });

    test('defaults when empty', () {
      final r = SubscribeResult.fromJson({});
      expect(r.subscriberCount, 0);
      expect(r.isSubscribed, false);
    });
  });

  group('DislikeVideoResult.fromJson', () {
    test('parses likes, dislikes, disliked', () {
      final r = DislikeVideoResult.fromJson({'likes': 3, 'dislikes': 1, 'disliked': true});
      expect(r.likes, 3);
      expect(r.dislikes, 1);
      expect(r.disliked, true);
    });

    test('defaults when empty', () {
      final r = DislikeVideoResult.fromJson({});
      expect(r.likes, 0);
      expect(r.dislikes, 0);
      expect(r.disliked, false);
    });
  });
}
