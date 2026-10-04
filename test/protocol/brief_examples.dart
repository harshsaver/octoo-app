/// The JSON examples from the brief (§7.2), with the `{…}` placeholders
/// filled in from the field tables.
library;

import 'dart:convert';

import 'package:octo_family/transport/simulator/sample_screen.dart';

Map<String, Object?> decode(String json) =>
    jsonDecode(json) as Map<String, Object?>;

const taskJson = '''
{"id":"t_3f9a1c2b7d4e","from":"u_harsh","fromName":"Harsh",
 "text":"Join the Discord server from Priya's invite and start the call",
 "job":"call.join","scope":"change","may":["open","call"],"status":"running",
 "say":"Opening Priya's invite",
 "steps":[{"n":1,"at":1790000001000,"say":"Opening Priya's invite","did":"Opened discord.gg","ok":true,"error":null}],
 "result":null,"resultForHer":null,
 "createdAt":1790000000000,"startedAt":1790000000500,"endedAt":null}
''';

const todoJson = '''
{"id":"d_8a1f","at":1790000000000,"text":"Is this safe?",
 "answer":"It's an ad pretending to be a warning.",
 "context":{"app":"Google Chrome","window":"Alert","url":"https://example.com"},
 "done":false,"replies":[{"at":1790000005000,"from":"Harsh","text":"Close it!"}]}
''';

const entryJson = '''
{"at":1790000000000,"kind":"task","by":"Harsh","text":"Join the Discord call",
 "taskId":"t_3f9a1c2b7d4e","job":"call.join","outcome":"done"}
''';

const policyJson = '''
{"askEveryChange":true,"askBeforeLooking":false,"never":["install"],"blockedSites":["facebook.com"]}
''';

/// Every "her computer → app" example, by name.
final Map<String, String> hostExamples = {
  'pair.code':
      '{"type":"pair.code","code":"482913","computer":"Mom\'s laptop"}',
  'pair.done': '{"type":"pair.done","hostId":"h_…","computer":"Mom\'s laptop","person":"Mom"}',
  'pair.failed': '{"type":"pair.failed","reason":"That code doesn\'t match.","final":false}',
  'result ok': '{"type":"result","requestId":"r1","ok":true,"taskId":"t_…"}',
  'result error': '{"type":"result","requestId":"r1","ok":false,"error":"unknown_job","message":"Octo doesn\'t know the job “x”."}',
  'task': '{"type":"task","task":$taskJson}',
  'status':
      '''
{"type":"status","requestId":"q1","computer":"Mom's laptop","person":"Mom","language":"hi","os":"windows","busy":true,
 "task":$taskJson,"queued":[],"recent":[],"todos":{"open":1},"help":{"since":1790000000000},
 "policy":$policyJson,"family":[{"name":"Harsh","device":"Harsh's iPhone"}],
 "jobs":[{"id":"wifi.check","title":"Check the Wi-Fi and internet","scope":"look","may":[]}],"agent":{"connected":true}}
''',
  'todo': '{"type":"todo","todo":$todoJson}',
  'todos': '{"type":"todos","requestId":"d1","todos":[$todoJson]}',
  'log': '{"type":"log","requestId":"l1","entries":[$entryJson]}',
  'help':
      '{"type":"help","at":1790000000000,"text":"The printer isn\'t working"}',
  'screen ok':
      '{"type":"screen","ok":true,"at":1790000000000,"screenshot":"$sampleScreenDataUri","app":"Microsoft Edge","window":"…"}',
  'screen no': '{"type":"screen","ok":false,"reason":"She said no."}',
  'policy': '{"type":"policy","policy":$policyJson,"declined":true}',
  'removed': '{"type":"removed"}',
};

/// Every "app → her computer" example, verbatim.
const List<String> appExamples = [
  '{"type":"pair.request","token":"<from the QR code>","name":"Harsh","device":"Harsh\'s iPhone"}',
  '{"type":"pair.confirm","code":"482913"}',
  '{"type":"status","requestId":"q1"}',
  '{"type":"task.create","requestId":"r1","text":"Join the Discord server from Priya\'s invite and start the call","job":"call.join"}',
  '{"type":"task.stop","requestId":"r2","taskId":"t_3f9a1c2b7d4e"}',
  '{"type":"policy.set","requestId":"p1","policy":{"askEveryChange":true,"askBeforeLooking":false,"never":["install"],"blockedSites":["facebook.com"]}}',
  '{"type":"profile.set","requestId":"p2","person":"Mom","computer":"Mom\'s laptop","language":"hi"}',
  '{"type":"todos","requestId":"d1"}',
  '{"type":"todo.reply","todoId":"d_8a1…","text":"Yes, it\'s a scam. Close the tab."}',
  '{"type":"todo.done","todoId":"d_8a1…"}',
  '{"type":"log","requestId":"l1","since":1790000000000,"limit":100}',
  '{"type":"message","text":"Calling you in 5 minutes!"}',
  '{"type":"screen.request"}',
  '{"type":"leave"}',
];
