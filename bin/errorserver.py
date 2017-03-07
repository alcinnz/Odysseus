#! /usr/bin/python3
"""Used to test default error pages. """
from http.server import *

class ErrorServer(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(int(self.path[1:]))
        self.end_headers()

try:
    httpd = HTTPServer(('', 8000), ErrorServer)
    httpd.serve_forever()
except KeyboardInterrupt:
    httpd.socket.close()
