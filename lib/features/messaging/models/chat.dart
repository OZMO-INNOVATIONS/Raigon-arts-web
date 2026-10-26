import 'channel.dart';

class ChatMsg {
  ChatMsg(this.text, this.fromBot, {this.linkLabel = '', this.linkUrl = ''});
  final String text, linkLabel, linkUrl;
  final bool fromBot;
  final DateTime at = DateTime.now();
}

class Convo {
  Convo(this.channel, this.contact);
  final Channel channel;
  final String contact;
  final List<ChatMsg> msgs = [];
}
