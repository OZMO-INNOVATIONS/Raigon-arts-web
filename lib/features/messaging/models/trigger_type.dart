import 'channel.dart';

enum TriggerType { keyword, anyMessage, postComment, storyReply }

extension TriggerX on TriggerType {
  String get title => switch (this) {
        TriggerType.keyword => 'A specific word or words',
        TriggerType.anyMessage => 'Any message',
        TriggerType.postComment => 'A comment on your post',
        TriggerType.storyReply => 'A reply to your story',
      };
  String get short => switch (this) {
        TriggerType.keyword => 'keyword',
        TriggerType.anyMessage => 'any message',
        TriggerType.postComment => 'comment',
        TriggerType.storyReply => 'story reply',
      };
  String get desc => switch (this) {
        TriggerType.keyword => 'Reply only when the message contains your words.',
        TriggerType.anyMessage => 'Reply to every new message, like a welcome note.',
        TriggerType.postComment => 'Send a DM when someone comments. Add words to filter.',
        TriggerType.storyReply => 'Reply when someone answers one of your stories.',
      };
  bool allows(Channel c) => c.isIg || this == TriggerType.keyword || this == TriggerType.anyMessage;
}
