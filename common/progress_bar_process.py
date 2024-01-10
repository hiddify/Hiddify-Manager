#!/usr/bin/env python

from __future__ import annotations
import threading

import os
import subprocess
import sys
import signal
import urwid
import re

regex = re.compile(r'####(\d+)####(.*?)####(.*?)####')


class LogListBox(urwid.ListBox):
    def __init__(self):
        body = urwid.SimpleFocusListWalker([urwid.Text("")])
        super().__init__(body)

    def add_log_newline(self, data, err):
        logfile.writelines([data])
        progress_match = regex.match(data)

        if progress_match:
            p = int(progress_match.group(1))
            progressbar.set_completion(p)
            title = f'{progress_match.group(2)} '
            desc = f'{progress_match.group(3)}'
            progressbar_header.set_text([('progress_header_title', title), (" "), ('progress_header_descr', desc)])
        else:
            if err:
                self.body.append(urwid.Text([("error", data)]))
            else:
                self.body.append(urwid.Text(data))
        if self.focus_position >= len(self.body) - 2:
            self.focus_position = len(self.body)-1

    def add_log(self, data):
        logfile.write(data)
        for c in data:
            current = self.body[-1]
            if '\n' == c:
                progress_match = regex.match(current.text)

                if progress_match:
                    p = int(progress_match.group(1))
                    if p >= 100:
                        raise urwid.ExitMainLoop()
                    progressbar.set_completion(p)
                    title = f'{progress_match.group(2)} '
                    desc = f'{progress_match.group(3)}'
                    progressbar_header.set_text([('progress_header_title', title), (" "), ('progress_header_descr', desc)])
                    current.set_text("")

                else:
                    self.body.append(urwid.Text(''))
                if self.focus_position >= len(self.body) - 2:
                    self.focus_position = len(self.body)-1
            elif '\r' == c:
                current.set_text("")
            else:
                current.set_text(current.text + c)

            current.text


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
progressbar = urwid.ProgressBar("progressbar_normal", "progressbar_complete", 70, 100)
progressbar_header = urwid.Text('')
footer_footer = urwid.AttrMap(urwid.Text(footer_info), "footer_foot")

footer = urwid.Pile([urwid.AttrMap(progressbar_header, 'progressbar_header'), progressbar, footer_footer])

frame_widget = urwid.Frame(header=edit_widget, body=urwid.AttrMap(listbox, "body"), footer=footer)


def exit_on_enter(key):
    if key in ("q", "Q"):
        raise urwid.ExitMainLoop()


loop = urwid.MainLoop(frame_widget, palette, unhandled_input=exit_on_enter, handle_mouse=False)


stdline = ''
errline = ''


def handle_in(data, err):
    global stdline
    global errline
    for c in data.decode():
        if err:
            if '\n' == c:
                listbox.add_log_newline(errline, err)
                errline = ''
            else:
                errline += c

        else:
            if '\n' == c:
                listbox.add_log_newline(stdline, err)
                stdline = ''
            else:

                stdline += c


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


def check_process():
    global proc
    proc.wait()
    exit()


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: progress_bar_process.py logfile command arg1 arg2 arg3")
        exit(1)
    logfile = open(sys.argv[1], 'w')
    run(sys.argv[2:])
    # threading.Thread(target=check_process).start()
    try:
        loop.run()
    except:
        pass

    exit()
