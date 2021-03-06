import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:path/path.dart' as p;

void main(List<String> arguments) async
{
  // This example uses the Google Books API to search for books about http.
  // https://developers.google.com/books/docs/overview
  //
  // https://ec.europa.eu/info/law/better-regulation/brpapi/allFeedback?publicationId=22174011&page=0&size=100
  // https://ec.europa.eu/info/law/better-regulation/brpapi/feedbackById?feedbackId=2230523&initiativeId=12872
  // 2230546
  // https://ec.europa.eu/info/law/better-regulation/brpapi/feedbackById?feedbackId=2230546&initiativeId=12872
  //
  // atachment: (090166e5dc0e29d3 == documentId)
  // https://ec.europa.eu/info/law/better-regulation/api/download/090166e5dc0e29d3

  int page = 0;
  int errcnt = 0;
  bool eof = false;
  bool attDownload = true;

  var result = <dynamic>[];
  var resultLong = <dynamic>[];

  while (!eof)
  {
      print ('Load page :$page');

      var url =
          Uri.https('ec.europa.eu', '/info/law/better-regulation/brpapi/allFeedback', { 'publicationId' : '22174011', 'page': page.toString(), 'size': '100'});

      print (url.toString());
      // Await the http get response, then decode the json-formatted response.
      var response = await http.get(url);

      if (response.statusCode == 200)
      {
        var jsonResponse = convert.jsonDecode(response.body);
        if ((jsonResponse as Map<dynamic,dynamic>).containsKey('_embedded'))
        {
            var items = jsonResponse['_embedded']['feedbackV1'] as List<dynamic>;
            print('Number of books about http: ${items.length}.');
            errcnt = 0;

            for (var item in items)
            {
                var hasAtt = false;

                var feedback = <String,dynamic>{};

                feedback['id']        = item['id'];
                feedback['firstName'] = item['firstName'];
                feedback['surname']   = item['surname'];
                feedback['dateFeedback']  = item['dateFeedback'];
                feedback['feedback']  = item['feedback'];
                feedback['publication']  = item['publication'];
                feedback['country']   = item['country'];
                feedback['userType']  = item['userType'];
                feedback['publication']  = item['publication'];
                feedback['attachments']  = item['attachments'];
                feedback['organization']  = item['organization'];

                if (feedback['firstName'].toString().contains('Daris'))
                {
                    var brk = 1;
                }

                if (attDownload && feedback['attachments'] is List<dynamic>)
                {
                    var attList = feedback['attachments'] as List<dynamic>;

                    for(var att in attList)
                    {
                        var attUrl =
                            Uri.https('ec.europa.eu', '/info/law/better-regulation/api/download/${ att['documentId']}');

                        print ('Attachment: ${attUrl.toString()}');

                        var attResponse = await http.get(attUrl);

                        if (attResponse.statusCode == 200)
                        {
                            var dir = './att/${att['documentId']}';
                            var fname = '$dir/${att['ersFileName']}';

                            print ('Write file:$fname');
                            await Directory(dir).create(recursive: true);

                            var buffer = attResponse.bodyBytes;

                            await File(fname).writeAsBytes(buffer);
                            hasAtt = true;
                        }

                    }
                }
                /*if (feedback['feedback'].toString().contains('...'))
                {
                  var itemUrl =  Uri.https('ec.europa.eu', 'info/law/better-regulation/brpapi/feedbackById',
                                            { 'feedbackId' : item['id'].toString(), 'initiativeId' : '12872'});
                  print ('Long feedback: ${itemUrl.toString()}');
                  var itemResponse = await http.get(itemUrl);
                  if (itemResponse.statusCode == 200)
                  {
                      var itemJson = convert.jsonDecode(itemResponse.body);
                      feedback['feedback'] = itemJson['feedback'];
                      resultLong.add(feedback);
                  }
                }*/

                if (hasAtt || feedback['feedback'] != null && feedback['feedback'].toString().length > 1000 )
                {
                    resultLong.add(feedback);
                }

                result.add(feedback);
            }

            page++;
        }
        else
        {
            eof = true;
        }
      }
      else
      {
        print('Request failed with status: ${response.statusCode}.');
        if (++errcnt>20) return;
      }
  }

  print ('Found ${result.length} feedbacks');
  var jsonResult = convert.jsonEncode(result);
  var file = io.File('feedbacks.json');
  await file.writeAsString(jsonResult);
  toHtml('feedbacks.html', result);

  print ('Found ${resultLong.length} long feedbacks');
  jsonResult = convert.jsonEncode(resultLong);
  file = io.File('feedbacks-long.json');
  await file.writeAsString(jsonResult);
  toHtml('feedbacks-long.html', resultLong);

}


void toHtml(String fileName,List<dynamic> items) async
{
    StringBuffer builder = new StringBuffer();

    builder.write('<html>\r\n<body>\r\n');
    int index = 1;

    for (var item in items)
    {
        builder.write('<h2><small>[$index]</small>&nbsp;&nbsp;&nbsp;${item['firstName']} ${item['surname']} ${item['organization'] ?? ''}</h2>\r\n');
        builder.write('<h3>Date:${item['dateFeedback']} Country:${item['country']} ${item['userType']} ${item['publication']}</h3>\r\n');
        builder.write('<p>${item['feedback'].toString().replaceAll('\n', '\n<br>\n')}</p>\r\n');
        if (item['attachments'] is List<dynamic>)
        {
            var attList = item['attachments'] as List<dynamic>;

            if (attList.length > 0)
            {
                builder.write('<p>P????lohy</p>\r\n');

                for(var att in attList)
                {
                  var path =  p.absolute('att/${att['documentId']}/${att['ersFileName']}');
                  var info = '${att['ersFileName']}';

                  builder.write('<p><a href="file:///$path">$info</a></p>\r\n');
                }
            }
        }

        builder.write('<hr>\r\n');
        index++;
    }

    builder.write('\r\n</body>\r\n</html>');

    var file = io.File(fileName);
    await file.writeAsString(builder.toString());

}

