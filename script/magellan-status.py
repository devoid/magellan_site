#!/usr/bin/env python
import os, subprocess, tempfile, re, sys, requests, argparse, json

def editor_buffer(template):
    template = template or ""
    f = tempfile.NamedTemporaryFile(delete=False)

    f.write(template)
    f.close()
    cmd = os.environ.get('EDITOR', 'vi') + ' ' + f.name
    subprocess.call(cmd, shell=True)
    final = []
    with open(f.name, 'r') as f:
        comments = re.compile("^#")
        [ final.append(line) for line in f if not comments.match(line) ]
        final = "\n".join(final)
        os.unlink(f.name)
    return final 

parser = argparse.ArgumentParser(description="""
Check or set the system status light for Magellan.
"""
)
parser.add_argument('-s', '--status', dest="status", choices=['good', 'alert', 'down'], 
    help="Set the service status to a good message.")
parser.add_argument('--amend', dest="amend", action="store_const", const=True,
    help="Amend the existing status rather than pushing a new status onto the history.")
parser.add_argument('--host', dest="host", help="Talk to a non-default host")
parser.add_argument('-m', '--message', dest="message", help="Message to display.")

# Just make parser return a dictionary with non-None values
args = { k : v for k,v in vars(parser.parse_args()).iteritems() if v != None}
host = args.get('host', 'cloud.mcs.anl.gov')
host = 'http://' + host + '/status/api'
res  = None
editor_template = """\
# Enter a useful status message
# Lines beginning in a "#" will be removed
"""
if args.get('status'):
    message = args.get('message')
    if not message:
        message = editor_buffer(editor_template)
    payload = {
        'status' : args.get('status'),
        'message' : message,
        'amend' : args.get('amend', False)
    }
    headers = { "Content-type" : "application/json", "Accept": "application/json" }
    res = requests.post(host, data=json.dumps(payload), headers=headers)
else:
    res = requests.get(host)

if res and re.match("^application/json", res.headers['content-type']):
    body = res.json()
    text = 'Status: ' + body['message']
    try:
        from termcolor import colored
        colors = { 'good' : 'green', 'alert' : 'yellow', 'down' : 'red' }
        color = colors.get(body['status'], 'yellow')
        text = colored(text, color)
    except ImportError:
        pass
    print(text)
elif res:
    sys.stderr.write("Invalid response from " + host + "\n")
    sys.stderr.write(res.headers['content-type'])
else:
    sys.stderr.write("No response from " + host + "\n")
