import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'dart:io' as io;

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
  
  int page = 0;
  int errcnt = 0;
  bool eof = false;

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

                if (feedback['feedback'] != null && feedback['feedback'].toString().length > 1000)
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

    for (var item in items)
    {
        builder.write('<h2>${item['firstName']} ${item['surname']}</h2>\r\n');
        builder.write('<h3>Date:${item['dateFeedback']} Country:${item['country']} ${item['userType']} ${item['publication']}</h3>\r\n');
        builder.write('<p>${item['feedback'].toString().replaceAll('\n', '\n<br>\n')}</p>\r\n');
        builder.write('<hr>\r\n');
    }

    builder.write('\r\n</body>\r\n</html>');

    var file = io.File(fileName);
    await file.writeAsString(builder.toString());

}


