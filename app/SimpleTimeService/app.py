from flask import Flask, request, jsonify
from datetime import datetime
app = Flask(__name__)
"""
remove ordering while giving the json response
"""
app.json.sort_keys = False

@app.route('/', methods=['GET'])
def index():
    """ 
    current timestamp in ISO 8601 format
    """
    now = datetime.now().isoformat()
    """ 
    visitor IP (handles proxies via X-Forwarded-For if present)
    """
    ip = request.headers.get('X-Forwarded-For', request.remote_addr)
    return jsonify({
        "timestamp": now,
        "ip": ip
    })

if __name__ == '__main__':
    """ listen on all interfaces, port 5000
    """
    app.run(host='0.0.0.0', port=5000)
