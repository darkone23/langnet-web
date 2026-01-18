from flask import Blueprint, jsonify, request, render_template

api = Blueprint('api', __name__)

@api.route('/hello', methods=['GET'])
def hello():
    """JSON API endpoint"""
    return jsonify({'message': 'Hello from Flask API!'})

@api.route('/hello', methods=['POST'])
def hello_post():
    """JSON API endpoint for POST requests"""
    data = request.get_json()
    return jsonify({'message': f'Hello, {data.get("name", "World")}!'})

@api.route('/hello-htmx', methods=['GET'])
def hello_htmx():
    """HTMX endpoint that returns HTML partial"""
    return '''
    <div class="alert alert-success">
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>Hello from Flask API via HTMX!</span>
    </div>
    '''

@api.route('/main-content', methods=['GET'])
def main_content():
    """Returns the main HTML content as a partial"""
    return render_template('main_content.html')
