import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/data/models/channel_metadata.dart';
import 'package:viikshana/data/models/home_feed_response.dart';
import 'package:viikshana/data/models/video_detail.dart';
import 'package:viikshana/data/models/video_item.dart';

void main() {
  group('VideoItem.fromJson', () {
    test('parses minimal valid JSON', () {
      final json = {'id': 'v1', 'title': 'Test Video'};
      final item = VideoItem.fromJson(json);
      expect(item.id, 'v1');
      expect(item.title, 'Test Video');
      expect(item.thumbnailUrl, isNull);
      expect(item.channelId, isNull);
      expect(item.channelName, isNull);
      expect(item.viewCount, 0);
      expect(item.durationSeconds, 0);
      expect(item.publishedAt, isNull);
    });

    test('parses full JSON', () {
      final json = {
        'id': 'v2',
        'title': 'Full Video',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'channelId': 'ch1',
        'channelName': 'Channel One',
        'viewCount': 1000,
        'durationSeconds': 120,
        'publishedAt': '2024-01-15T10:00:00Z',
      };
      final item = VideoItem.fromJson(json);
      expect(item.id, 'v2');
      expect(item.title, 'Full Video');
      expect(item.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(item.channelId, 'ch1');
      expect(item.channelName, 'Channel One');
      expect(item.viewCount, 1000);
      expect(item.durationSeconds, 120);
      expect(item.publishedAt, isNotNull);
    });

    test('handles numeric viewCount as string', () {
      final item = VideoItem.fromJson({
        'id': 'v3',
        'title': 'T',
        'viewCount': '999',
      });
      expect(item.viewCount, 999);
    });

    test('toJson round-trip', () {
      const item = VideoItem(
        id: 'v1',
        title: 'Title',
        thumbnailUrl: 'https://t.co',
        viewCount: 5,
      );
      final json = item.toJson();
      final back = VideoItem.fromJson(json);
      expect(back.id, item.id);
      expect(back.title, item.title);
      expect(back.thumbnailUrl, item.thumbnailUrl);
      expect(back.viewCount, item.viewCount);
    });

    test('resolves relative thumbnail with media base URL', () {
      final item = VideoItem.fromJson({
        'id': 'v1',
        'title': 'T',
        'thumbnail': '/processed/abc/thumbnail.jpg',
      });
      expect(
        item.thumbnailUrl,
        'https://videoprocess.viikshana.com/processed/abc/thumbnail.jpg',
      );
    });
  });

  group('ChannelMetadata.fromJson', () {
    test('parses minimal and full JSON', () {
      expect(
        ChannelMetadata.fromJson({'id': 'c1'}).id,
        'c1',
      );
      final full = ChannelMetadata.fromJson({
        'id': 'c2',
        'name': 'My Channel',
        'avatarUrl': 'https://example.com/avatar.png',
      });
      expect(full.id, 'c2');
      expect(full.name, 'My Channel');
      expect(full.avatarUrl, 'https://example.com/avatar.png');
    });
  });

  group('VideoDetail.fromJson', () {
    test('parses minimal JSON', () {
      final json = {'id': 'vd1', 'title': 'Detail Video'};
      final d = VideoDetail.fromJson(json);
      expect(d.id, 'vd1');
      expect(d.title, 'Detail Video');
      expect(d.hlsUrl, isNull);
      expect(d.likeCount, 0);
      expect(d.commentCount, 0);
      expect(d.channel, isNull);
    });

    test('parses full JSON with channel', () {
      final json = {
        'id': 'vd2',
        'title': 'Detail',
        'hlsUrl': 'https://example.com/hls.m3u8',
        'likeCount': 42,
        'commentCount': 7,
        'channel': {'id': 'ch1', 'name': 'Channel', 'avatarUrl': 'https://a.co'},
      };
      final d = VideoDetail.fromJson(json);
      expect(d.hlsUrl, 'https://example.com/hls.m3u8');
      expect(d.likeCount, 42);
      expect(d.commentCount, 7);
      expect(d.channel?.id, 'ch1');
      expect(d.channel?.name, 'Channel');
    });

    test('toVideoItem preserves core fields', () {
      final d = VideoDetail.fromJson({
        'id': 'vd3',
        'title': 'Convert',
        'channelName': 'CN',
        'viewCount': 10,
      });
      final item = d.toVideoItem();
      expect(item.id, d.id);
      expect(item.title, d.title);
      expect(item.channelName, 'CN');
      expect(item.viewCount, 10);
    });
  });

  group('HomeFeedResponse.fromJson', () {
    test('parses empty videos list', () {
      final json = {'videos': [], 'page': 1, 'limit': 20};
      final r = HomeFeedResponse.fromJson(json);
      expect(r.videos, isEmpty);
      expect(r.page, 1);
      expect(r.limit, 20);
      expect(r.total, isNull);
    });

    test('parses single video in feed', () {
      final json = {
        'videos': [
          {'id': 'v1', 'title': 'First'}
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
      };
      final r = HomeFeedResponse.fromJson(json);
      expect(r.videos.length, 1);
      expect(r.videos.first.id, 'v1');
      expect(r.videos.first.title, 'First');
      expect(r.page, 1);
      expect(r.limit, 20);
      expect(r.total, 1);
    });

    test('parses real API shape: regularVideos, hasMore, nextPage', () {
      final json = {
        'success': true,
        'regularVideos': [
          {
            'id': 'ZqY5Tz',
            'title': 'Bhojpuri Song',
            'views': 1,
            'duration': 213,
            'thumbnailHome': 'https://example.com/thumb.jpg',
            'channel': {'id': 36, 'name': 'Right Things'},
          }
        ],
        'hasMore': true,
        'nextPage': 2,
      };
      final r = HomeFeedResponse.fromJson(json);
      expect(r.videos.length, 1);
      expect(r.videos.first.id, 'ZqY5Tz');
      expect(r.videos.first.title, 'Bhojpuri Song');
      expect(r.videos.first.channelName, 'Right Things');
      expect(r.videos.first.viewCount, 1);
      expect(r.videos.first.durationSeconds, 213);
      expect(r.videos.first.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(r.hasMore, true);
      expect(r.nextPage, 2);
    });

    test('handles missing videos key', () {
      final r = HomeFeedResponse.fromJson({'page': 2});
      expect(r.videos, isEmpty);
      expect(r.page, 2);
    });

    test('toJson round-trip', () {
      final r = HomeFeedResponse.fromJson({
        'videos': [
          {'id': 'a', 'title': 'A'}
        ],
        'page': 1,
        'limit': 10,
        'total': 1,
      });
      final json = r.toJson();
      final back = HomeFeedResponse.fromJson(json);
      expect(back.videos.length, 1);
      expect(back.videos.first.id, 'a');
      expect(back.page, 1);
      expect(back.limit, 10);
      expect(back.total, 1);
    });
  });
}
