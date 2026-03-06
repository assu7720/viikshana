import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/data/models/channel_metadata.dart';
import 'package:viikshana/data/models/comment.dart';
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

    test('parses duration as string (e.g. related API "8053.000")', () {
      final item = VideoItem.fromJson({
        'id': 'v1',
        'title': 'T',
        'duration': '8053.000',
      });
      expect(item.durationSeconds, 8053);
    });

    test('parses duration as double', () {
      final item = VideoItem.fromJson({
        'id': 'v1',
        'title': 'T',
        'duration': 6017.0,
      });
      expect(item.durationSeconds, 6017);
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

    test('parses isSubscribed when present', () {
      final sub = ChannelMetadata.fromJson({'id': 'c1', 'isSubscribed': true});
      expect(sub.isSubscribed, true);
      final unsub = ChannelMetadata.fromJson({'id': 'c2', 'isSubscribed': false});
      expect(unsub.isSubscribed, false);
      final noKey = ChannelMetadata.fromJson({'id': 'c3'});
      expect(noKey.isSubscribed, isNull);
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

    test('resolves relative hlsUrl with media base URL', () {
      final d = VideoDetail.fromJson({
        'id': 'v1',
        'title': 'T',
        'hlsUrl': '/processed/fr1zWx/360p/playlist.m3u8',
      });
      expect(
        d.hlsUrl,
        'https://videoprocess.viikshana.com/processed/fr1zWx/360p/playlist.m3u8',
      );
    });

    test('parses likedByMe when present', () {
      final d = VideoDetail.fromJson({'id': 'v1', 'title': 'T', 'likedByMe': true});
      expect(d.likedByMe, true);
      final d2 = VideoDetail.fromJson({'id': 'v2', 'title': 'T', 'likedByMe': false});
      expect(d2.likedByMe, false);
      final d3 = VideoDetail.fromJson({'id': 'v3', 'title': 'T'});
      expect(d3.likedByMe, isNull);
    });

    test('parses likes and dislikes from API keys', () {
      final d = VideoDetail.fromJson({'id': 'v1', 'title': 'T', 'likes': 10, 'dislikes': 2});
      expect(d.likeCount, 10);
      expect(d.dislikeCount, 2);
      final d2 = VideoDetail.fromJson({'id': 'v2', 'title': 'T', 'likeCount': 5, 'dislikeCount': 0});
      expect(d2.likeCount, 5);
      expect(d2.dislikeCount, 0);
    });

    test('parses dislikedByMe and subscribedToChannel when present', () {
      final d = VideoDetail.fromJson({'id': 'v1', 'title': 'T', 'dislikedByMe': true});
      expect(d.dislikedByMe, true);
      final d2 = VideoDetail.fromJson({'id': 'v2', 'title': 'T', 'subscribedToChannel': true});
      expect(d2.subscribedToChannel, true);
      final d3 = VideoDetail.fromJson({'id': 'v3', 'title': 'T', 'subscribed_to_channel': true});
      expect(d3.subscribedToChannel, true);
      final d4 = VideoDetail.fromJson({'id': 'v4', 'title': 'T'});
      expect(d4.dislikedByMe, isNull);
      expect(d4.subscribedToChannel, isNull);
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

    test('parses related API shape: relatedVideos and string duration', () {
      final json = {
        'success': true,
        'relatedVideos': [
          {
            'id': '6DJ9sI',
            'title': 'Valiyava - 2017 Malayalam Action Movie',
            'thumbnailHome': 'https://videoprocess.viikshana.com/processed/6DJ9sI/thumbnail_home_1772776987048.jpg',
            'views': 0,
            'duration': '8053.000',
            'channel': {'id': 4, 'name': 'Movie Market', 'handle': 'moviemarket'},
          },
          {
            'id': 'i404SV',
            'title': 'Balraju Latest Romantic Action',
            'thumbnail': 'https://videoprocess.viikshana.com/processed/i404SV/thumbnail.jpg',
            'views': 5,
            'duration': 6017.0,
            'channel': {'id': 4, 'name': 'Movie Market'},
          },
        ],
        'hasMore': false,
      };
      final r = HomeFeedResponse.fromJson(json);
      expect(r.videos.length, 2);
      expect(r.videos[0].id, '6DJ9sI');
      expect(r.videos[0].durationSeconds, 8053);
      expect(r.videos[0].channelName, 'Movie Market');
      expect(r.videos[1].id, 'i404SV');
      expect(r.videos[1].durationSeconds, 6017);
      expect(r.videos[1].viewCount, 5);
      expect(r.hasMore, false);
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

  group('Comment.fromJson', () {
    test('parses minimal valid JSON', () {
      final json = {
        'id': 1,
        'videoId': 'v1',
        'userId': 10,
        'text': 'Hello',
      };
      final c = Comment.fromJson(json);
      expect(c.id, 1);
      expect(c.videoId, 'v1');
      expect(c.userId, 10);
      expect(c.text, 'Hello');
      expect(c.username, isNull);
      expect(c.parentCommentId, isNull);
      expect(c.createdAt, isNull);
      expect(c.updatedAt, isNull);
      expect(c.replies, isEmpty);
    });

    test('parses full JSON with username and dates', () {
      final json = {
        'id': 2,
        'videoId': 'v2',
        'userId': 20,
        'username': 'viewer1',
        'text': 'Great video!',
        'parentCommentId': null,
        'createdAt': '2024-06-01T12:00:00Z',
        'updatedAt': '2024-06-01T12:05:00Z',
      };
      final c = Comment.fromJson(json);
      expect(c.id, 2);
      expect(c.username, 'viewer1');
      expect(c.text, 'Great video!');
      expect(c.createdAt, isNotNull);
      expect(c.updatedAt, isNotNull);
    });

    test('parses userName as username fallback', () {
      final c = Comment.fromJson({
        'id': 1,
        'videoId': 'v1',
        'userId': 1,
        'text': 'x',
        'userName': 'alias',
      });
      expect(c.username, 'alias');
    });

    test('parses nested replies', () {
      final json = {
        'id': 1,
        'videoId': 'v1',
        'userId': 1,
        'text': 'Parent',
        'replies': [
          {'id': 2, 'videoId': 'v1', 'userId': 2, 'text': 'Reply'},
        ],
      };
      final c = Comment.fromJson(json);
      expect(c.replies.length, 1);
      expect(c.replies.first.id, 2);
      expect(c.replies.first.text, 'Reply');
    });
  });

  group('VideoCommentsResponse.fromJson', () {
    test('parses empty comments list', () {
      final r = VideoCommentsResponse.fromJson({'comments': [], 'page': 1});
      expect(r.comments, isEmpty);
      expect(r.page, 1);
      expect(r.total, isNull);
    });

    test('parses comments key', () {
      final json = {
        'comments': [
          {'id': 1, 'videoId': 'v1', 'userId': 1, 'text': 'First'},
        ],
        'page': 1,
        'total': 1,
      };
      final r = VideoCommentsResponse.fromJson(json);
      expect(r.comments.length, 1);
      expect(r.comments.first.text, 'First');
      expect(r.page, 1);
      expect(r.total, 1);
    });

    test('parses data key as comments fallback', () {
      final r = VideoCommentsResponse.fromJson({
        'data': [
          {'id': 1, 'videoId': 'v1', 'userId': 1, 'text': 'From data'},
        ],
        'page': 2,
      });
      expect(r.comments.length, 1);
      expect(r.comments.first.text, 'From data');
      expect(r.page, 2);
    });

    test('handles missing list', () {
      final r = VideoCommentsResponse.fromJson({'page': 1});
      expect(r.comments, isEmpty);
    });
  });
}
