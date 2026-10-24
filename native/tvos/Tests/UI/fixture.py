"""Local test content only; never connects to a real LunaTV account."""
from http.server import ThreadingHTTPServer,BaseHTTPRequestHandler
from urllib.parse import urlsplit,parse_qs
from pathlib import Path
import json
base=Path(__file__).resolve().parents[4]/'assets'
class Handler(BaseHTTPRequestHandler):
 def log_message(self,*args): pass
 def do_GET(self):
  path=urlsplit(self.path);q=parse_qs(path.query)
  if path.path.startswith('/poster/'):
   name='images/icon.png' if path.path.endswith('square') else 'tv_icons/icon-1920x720.png'
   data=(base/name).read_bytes();kind='image/png'
  else:
   value={}
   if path.path=='/api/server-config':value={'SiteName':'UI Fixture','StorageType':'kvrocks'}
   elif path.path=='/api/douban':
    offset=int(q.get('pageStart',['0'])[0]);limit=9 if q.get('type')==['movie'] else 43
    value={'code':200,'list':[{'title':('较长影片标题用于检查两行排版 ' if n%3==0 else '影片 ')+str(n+1).zfill(2),'poster':'http://127.0.0.1:18087/poster/'+('square' if n%2 else 'wide'),'rate':'8.8'} for n in range(offset,min(offset+20,limit))]}
    print('page',q.get('type'),offset,'returned',len(value['list']),flush=True)
   elif path.path=='/api/image-proxy':
    name='images/icon.png' if q.get('url',[''])[0].endswith('square') else 'tv_icons/icon-1920x720.png'
    data=(base/name).read_bytes();kind='image/png';self.send_response(200);self.send_header('Content-Type',kind);self.end_headers();self.wfile.write(data);return
   data=json.dumps(value,ensure_ascii=False).encode();kind='application/json'
  self.send_response(200);self.send_header('Content-Type',kind);self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
ThreadingHTTPServer(('127.0.0.1',18087),Handler).serve_forever()
