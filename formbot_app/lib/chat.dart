/*This software is free to use by anyone. It comes with no warranties and is provided solely "AS-IS".
It may contain significant bugs, or may not even perform the intended tasks, or fail to be fit for any purpose.
University of Maryland is not responsible for any shortcomings and the user is solely responsible for the use.*/

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:sound_stream/sound_stream.dart';
import 'package:dialogflow_grpc/dialogflow_grpc.dart' as dialog_flow;

// https://pub.dev/packages/dialogflow_grpc/example
class Chat extends StatefulWidget {
  static const String routeName = 'conversation';
  Chat({Key key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  String selection = '';
  String templateURL = '';

  // bool _isRecording = false;

  // RecorderStream _recorder = RecorderStream();
  // StreamSubscription _recorderStatus;
  // StreamSubscription<List<int>> _audioStreamSubscription;
  // BehaviorSubject<List<int>> _audioStream;

  // DialogflowGrpc class instance
  dialog_flow.DialogflowGrpcV2 dialogflow;

  @override
  void initState() {
    super.initState();
    initPlugin();
    _showDialog();
  }
  _showDialog() async {
    await Future.delayed(Duration(milliseconds: 50));

    Widget dropdownButton = DropdownButton<String>(
      key: Key('templateDropdown'),
      hint:new Text("Select a Template"),
      onChanged: (value) {
        setState(() {
          selection = value;
        });
      },
      items: <String>['Vaccination Record', 'New Prescription', 'Medical History', 'D'].map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(value),
        );
      }).toList(),
    );

    Widget cancelButton = TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: Text('Cancel'),
    );

    Widget proceedButton = TextButton(
      key: Key('proceedBtn'),
        onPressed: () {
          Navigator.of(context).pop();
          setState(() {
            // templateURL = 'https://docs.google.com/document/d/1yQyeG1vwL3D5vfDZV3INv5syqNUWu_Xl26QyVbTUrSE/edit?usp=drivesdk';
            templateURL = 'https://docs.google.com/document/d/1o525SlozEGxS-d4PVp_GsDt6j8C9L6W8U5J63CFB6gU/edit?usp=sharing';
          });
          _greeting(templateURL);
        },
        child: Text('Proceed')
    );

    AlertDialog templateSelector = AlertDialog(
      title: Text('Step 1: Select Form Template'),
      content: dropdownButton,
      actions: [
        cancelButton,
        proceedButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return templateSelector;
      },
    );
  }

  _greeting(String URL){
    handleSubmitted('hi');
    handleSubmitted(URL);
  }

  @override
  void dispose() {
    // _recorderStatus?.cancel();
    // _audioStreamSubscription?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlugin() async {
    // _recorderStatus = _recorder.status.listen((status) {
    //   if (mounted)
    //     setState(() {
    //       _isRecording = status == SoundStreamStatus.Playing;
    //     });
    // });
    //
    // await Future.wait([
    //   _recorder.initialize()
    // ]);


    final serviceAccount = dialog_flow.ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/credentials.json'))}');

    dialogflow = dialog_flow.DialogflowGrpcV2.viaServiceAccount(serviceAccount);
  }

  // void stopStream() async {
  //   await _recorder.stop();
  //   await _audioStreamSubscription?.cancel();
  //   await _audioStream?.close();
  // }

  void handleSubmitted(text) async {
    print(text);
    _textController.clear();

    // Dialogflow detectIntent call
    ChatMessage message = ChatMessage(
      text: text,
      name: "You",
      type: true,
    );

    setState(() {
      _messages.insert(0, message);
    });

    var data = await dialogflow.detectIntent(text, 'en-US');
    String fulfillmentText = data.queryResult.fulfillmentText;
    if(fulfillmentText.isNotEmpty) {
      ChatMessage botMessage = ChatMessage(
        text: fulfillmentText,
        name: "Bot",
        type: false,
      );

      setState(() {
        _messages.insert(0, botMessage);
      });
    }
  }

  // void handleStream() async {
  //   _recorder.start();
  //
  //   _audioStream = BehaviorSubject<List<int>>();
  //   _audioStreamSubscription = _recorder.audioStream.listen((data) {
  //     _audioStream.add(data);
  //   });
  //
  //   // Create and audio InputConfig
  //   //  See: https://cloud.google.com/dialogflow/es/docs/reference/rpc/google.cloud.dialogflow.v2#google.cloud.dialogflow.v2.InputAudioConfig
  //   var config = InputConfig(
  //       encoding: 'AUDIO_ENCODING_LINEAR_16',
  //       languageCode: 'en-US',
  //       sampleRateHertz: 8000
  //   );
  //
  //   if (Platform.isIOS) {
  //     config = InputConfig(
  //         encoding: 'AUDIO_ENCODING_LINEAR_16',
  //         languageCode: 'en-US',
  //         sampleRateHertz: 16000
  //     );
  //   }
  //
  //   // Make the streamingDetectIntent call, with the InputConfig and the audioStream
  //   final responseStream = dialogflow.streamingDetectIntent(config, _audioStream);
  //
  //   // Get the transcript and detectedIntent and show on screen
  //   responseStream.listen((data) {
  //     print('----');
  //     print(data);
  //     setState(() {
  //       //print(data);
  //       String transcript = data.recognitionResult.transcript;
  //       String queryText = data.queryResult.queryText;
  //       String fulfillmentText = data.queryResult.fulfillmentText;
  //
  //       if(fulfillmentText.isNotEmpty) {
  //         ChatMessage message = ChatMessage(
  //           text: queryText,
  //           name: "You",
  //           type: true,
  //         );
  //
  //         ChatMessage botMessage = ChatMessage(
  //           text: fulfillmentText,
  //           name: "Bot",
  //           type: false,
  //         );
  //
  //         _messages.insert(0, message);
  //         _textController.clear();
  //         _messages.insert(0, botMessage);
  //
  //       }
  //       if(transcript.isNotEmpty) {
  //         _textController.text = transcript;
  //       }
  //     });
  //   },onError: (e){
  //     //print(e);
  //   },onDone: () {
  //     //print('done');
  //   });
  //
  // }

  // The chat interface
  //
  //------------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('chat_page'),
      appBar: AppBar(
        title: Text('Conversation'),
        backgroundColor: Color(0xFF007fbc),
      ),

      body: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => _messages[index],
                itemCount: _messages.length,
              ),
          ),
            Divider(height: 1.0),
            Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor
                ),
                child: IconTheme(
                  data: IconThemeData(color: Theme.of(context).accentColor),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: <Widget>[Flexible(
                        child: TextField(
                          key: Key('msgTextfield'),
                          controller: _textController,
                          onSubmitted: handleSubmitted,
                          decoration: InputDecoration.collapsed(hintText: "Send a message"),
                        ),
                      ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          child: IconButton(
                            key:  Key('msgSendBtn'),
                            icon: Icon(Icons.send),
                            onPressed: () => handleSubmitted(_textController.text),
                          ),
                        ),
                        IconButton(
                          iconSize: 30.0,
                          // icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                          // onPressed: _isRecording ? stopStream : handleStream,
                          icon: Icon(Icons.mic),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                )
            ),
          ]
      ),
    );
  }
}


//------------------------------------------------------------------------------------
// The chat message balloon
//
//------------------------------------------------------------------------------------
class ChatMessage extends StatelessWidget {
  ChatMessage({this.text, this.name, this.type});

  final String text;
  final String name;
  final bool type;

  List<Widget> otherMessage(context) {
    return <Widget>[
      Container(
        margin: const EdgeInsets.only(right: 16.0),
        child: CircleAvatar(child: Text('B')),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(this.name,
                style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(text),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> myMessage(context) {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(this.name, style: Theme.of(context).textTheme.subtitle1),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(text),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.only(left: 16.0),
        child: CircleAvatar(
            child: Text(
              this.name[0],
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: this.type ? myMessage(context) : otherMessage(context),
      ),
    );
  }
}