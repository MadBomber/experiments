#!/usr/bin/env python3
# py_stuff/tornado/hello_workd.py
# Just a simple single URL minimalistic response

import tornado.ioloop
import tornado.web


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, world<br />How can tornado performance be enhanced to support 150+ transactions per second?<p>Is the auto-reload working?</p><h1>YES!</h1>")

def make_app():
    settings = {
        'debug':True,  # will cause an auto-reload on file changes
        # other stuff
    }
    return tornado.web.Application([
        (r"/", MainHandler),
    ],
    **settings,
    )


if __name__ == "__main__":
    app = make_app()
    app.listen(8888)
    tornado.ioloop.IOLoop.current().start()
