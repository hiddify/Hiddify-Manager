#!/usr/bin/env python

from __future__ import annotations
from typing import Tuple, List, Optional, Any, Iterable
import threading

import os
import subprocess
import sys
import signal
import urwid
import re
from twisted.internet import reactor, threads
el = urwid.TwistedEventLoop()


regex = re.compile(r'####(\d+)####(.*?)####(.*?)####')


class ANSICanvas(urwid.canvas.Canvas):
    def __init__(self, size: Tuple[int, int], text_lines: List[str]) -> None:
        super().__init__()

        self.maxcols, self.maxrows = size

        self.text_lines = text_lines

    def cols(self) -> int:
        return self.maxcols

    def rows(self) -> int:
        return self.maxrows

    def content(
        self,
        trim_left: int = 0, trim_top: int = 0,
        cols: Optional[int] = None, rows: Optional[int] = None,
        attr_map: Optional[Any] = None
    ) -> Iterable[List[Tuple[None, str, bytes]]]:
        assert cols is not None
        assert rows is not None

        for i in range(rows):
            if i < len(self.text_lines):
                text = self.text_lines[i].encode('utf-8')
            else:
                text = b''

            padding = bytes().rjust(max(0, cols - len(text)))
            line = [(None, 'U', text + padding)]

            yield line


class ANSIWidget(urwid.Widget):
    _sizing = frozenset([urwid.widget.BOX])

    def __init__(self, text: str = '') -> None:
        self.lines = text.split('\n')

    def set_content(self, lines: List[str]) -> None:
        self.lines = lines
        self._invalidate()

    def render(
        self,
        size: Tuple[int, int], focus: bool = False
    ) -> urwid.canvas.Canvas:
        canvas = ANSICanvas(size, self.lines)

        return canvas


def escape_ansi(line):
    ansi_escape = re.compile(r'(?:\x1B[@-_]|[\x80-\x9F])[0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', line)


def get_line(text):
    return urwid.BoxAdapter(ANSIWidget(text), 1)


class LogListBox(urwid.ListBox):
    def __init__(self):
        body = urwid.SimpleFocusListWalker([get_line("")])
        super().__init__(body)

    def add_log_line(self, data, err, replace=False):
        logfile.writelines([data])
        # data = escape_ansi(data)
        progress_match = regex.match(data)

        if progress_match:
            p = int(progress_match.group(1))
            progressbar.set_completion(p)
            title = f'{progress_match.group(2)} '
            desc = f'{progress_match.group(3)}'
            progressbar_header.set_text([('progress_header_title', title), (" "), ('progress_header_descr', desc)])
            # if p >= 100:
            #     raise urwid.ExitMainLoop()
        else:
            # txt = [("error", data)] if err else data
            txt = f'\033[91m{data}\033[0m' if err else data
            if replace:
                self.body[-1].set_content(txt)
            else:
                self.body.append(get_line(txt))
        if self.focus_position >= len(self.body) - 2:
            self.focus_position = len(self.body)-1

    # def add_log(self, data):
    #     logfile.write(data)
    #     for c in data:
    #         current = self.body[-1]
    #         if '\n' == c:
    #             progress_match = regex.match(current.text)

    #             if progress_match:
    #                 p = int(progress_match.group(1))
    #                 if p >= 100:
    #                     raise urwid.ExitMainLoop()
    #                 progressbar.set_completion(p)
    #                 title = f'{progress_match.group(2)} '
    #                 desc = f'{progress_match.group(3)}'
    #                 progressbar_header.set_text([('progress_header_title', title), (" "), ('progress_header_descr', desc)])
    #                 current.set_text("")

    #             else:
    #                 self.body.append(urwid.Text(''))
    #             if self.focus_position >= len(self.body) - 2:
    #                 self.focus_position = len(self.body)-1
    #         elif '\r' == c:
    #             current.set_text("")
    #         else:
    #             current.set_text(current.text + c)

    #         current.text


palette = [
    ("body", "default", "default"),
    ("foot", "dark cyan", "dark blue", "bold"),
    ("key", "light cyan", "dark blue", "underline"),
    ("footer_foot", "light gray", "black"),
    ("footer_key", "light cyan", "black", "underline"),
    ("footer_title", "white", "black",),
    ("header_title",  "black", "white",),
    ("header_version",  "dark red", "white",),
    ("header_back",  "black", "white",),

    ("progressbar_header",  "black", "light gray"),
    ("progress_header_title",   "white", "black", "bold"),
    ("progress_header_descr", "dark blue", "light gray"),

    ("progressbar_normal",  "light gray", "black"),
    ("progressbar_complete",  "white", "dark blue"),


]
header_text = [
    ("header_title", "Hiddify Manager"),
    "    ",
    ("header_version", open('/opt/hiddify-manager/VERSION', 'r').read().strip()),
]
footer_info = [
    ("footer_title", "KEY"),
    "    ",
    ("footer_key", "Q"),
    ", ",
    ("footer_key", "CTRL+C"),
    " exits      ",
    ("footer_key", "UP"),
    ", ",
    ("footer_key", "DOWN"),
    ", ",
    ("footer_key", "PAGE+UP"),
    ", ",
    ("footer_key", "PAGE DOWN"),
    " move",


]
listbox = LogListBox()

edit_widget = urwid.AttrMap(urwid.Text(header_text), 'header_back')
progressbar = urwid.ProgressBar("progressbar_normal", "progressbar_complete", 0, 100)
progressbar_header = urwid.Text('')
footer_footer = urwid.AttrMap(urwid.Text(footer_info), "footer_foot")

footer = urwid.Pile([urwid.AttrMap(progressbar_header, 'progressbar_header'), progressbar, footer_footer])

frame_widget = urwid.Frame(header=edit_widget, body=urwid.AttrMap(listbox, "body"), footer=footer)


def exit_on_enter(key):
    if key in ("q", "Q"):
        raise urwid.ExitMainLoop()


loop = urwid.MainLoop(frame_widget, palette, unhandled_input=exit_on_enter, handle_mouse=False, event_loop=el)


stdline = ''
errline = ''

std_err_line = ['', '']


def handle_in(data, err):
    global std_err_line
    indx = 1 if err else 0
    last_char = ''
    for c in data.decode():
        if c in ['\r', '\n']:
            listbox.add_log_line(std_err_line[indx], err)
            std_err_line[indx] = ''
        # elif '\r' == c:
        #     listbox.add_log_line(std_err_line[indx], err, replace=True)
        #     std_err_line[indx] = ''
        else:
            std_err_line[indx] += c


def received_output(data):
    handle_in(data, False)


def received_err(data):
    handle_in(data, True)


# listbox.add_log("####0####INSTALLING####Hiddify Manager#####\n")
write_fd = loop.watch_pipe(received_output)
write_fd_err = loop.watch_pipe(received_err)


def run(cmds):
    global proc
    import time
    proc = subprocess.Popen(
        cmds,
        stdout=write_fd,
        stderr=write_fd_err,
        close_fds=True,
    )


def exit():
    logfile.close()
    try:
        proc.send_signal(signal.SIGTERM)
    except:
        pass
    sys.exit(0)


def exit_loop_exception(x, t):
    raise urwid.ExitMainLoop


@el.handle_exit
def exit_loop(a):
    loop.set_alarm_in(0, exit_loop_exception)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: progress_bar_process.py logfile command arg1 arg2 arg3")
        exit(1)
    logfile = open(sys.argv[1], 'w')
    run(sys.argv[2:])
    d = threads.deferToThread(proc.wait)
    d.addCallback(exit_loop)
    try:
        loop.run()
    except:
        pass

    exit()
