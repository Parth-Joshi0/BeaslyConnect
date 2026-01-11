import json
import math
import base64
import uuid
import os
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "VolunteerDB.json")
USER_DB_PATH = os.path.join(BASE_DIR, "UserDB.json")
HELP_REQUESTS_PATH = os.path.join(BASE_DIR, "HelpRequests.json")
VOICE_RECORDINGS_DIR = os.path.join(BASE_DIR, "voice_recordings")

# Create voice recordings directory if it doesn't exist
os.makedirs(VOICE_RECORDINGS_DIR, exist_ok=True)

@app.route('/SubmitHelpRequest', methods=['POST'])
def submit_help_request():
    data = request.get_json()

    email = data['email']
    situation_text = data['situationText']
    voice_recording = data.get('voiceRecording', None)  # Base64 encoded audio

    # Generate unique request ID
    request_id = f"req_{int(datetime.now().timestamp())}"

    # Save voice recording if present
    voice_file_path = None
    if voice_recording:
        voice_file_path = os.path.join(VOICE_RECORDINGS_DIR, f"{request_id}.m4a")
        # Decode base64 and save
        audio_data = base64.b64decode(voice_recording)
        with open(voice_file_path, "wb") as f:
            f.write(audio_data)

    # Create help request object
    help_request = {
        "requestId": request_id,
        "userEmail": email,
        "situationText": situation_text,
        "voiceRecordingPath": voice_file_path,
        "hasVoiceRecording": voice_recording is not None,
        "timestamp": datetime.now().isoformat(),
        "status": "pending",  # pending, accepted, completed
        "assignedVolunteer": None
    }

    # Read existing requests
    if os.path.exists(HELP_REQUESTS_PATH):
        with open(HELP_REQUESTS_PATH, "r") as f:
            requests_db = json.load(f)
    else:
        requests_db = {"requests": []}

    # Add new request
    requests_db["requests"].append(help_request)

    # Save back to file
    with open(HELP_REQUESTS_PATH, "w") as f:
        json.dump(requests_db, f, indent=4)

    return jsonify({
        'success': True,
        'requestId': request_id,
        'message': 'Help request submitted successfully'
    })

def image_to_base64(image_data):
    """Convert base64 string or return as is"""
    return image_data

@app.route('/CreateUpdateProfile', methods=['POST'])
def create_update_profile():
    data = request.get_json()

    email = data['email']
    certifications = data['certifications']
    hasCar = '1' if data['ownsCar'] else '0'

    # Car logic
    if "Driver's License" in certifications and hasCar == '1':
        car = f"{data.get('carColor', '')} {data.get('carMake', '')}"
        carModel = data.get('carMake', '')
        carColour = data.get('carColor', '')
    else:
        car = "No Car"
        carModel = None
        carColour = None

    # Calculate strength
    weight = int(data['weight'])
    height = int(data['height'])
    strength = 10 * math.sqrt(weight / height)

    # Read existing database
    with open("VolunteerDB.json", "r") as f:
        volDB = json.load(f)

    # Create user object
    user = {
        "image": data.get('profileImage', ''),
        "email/userName": email,
        "name": data['fullName'],
        "Qualifications": certifications,
        "age": int(data['age']),
        "height(Inches)": height,
        "weight(Pounds)": weight,
        "gender": data['gender'],
        "car": car,
        "carModel": carModel,
        "carColour": carColour,
        "strength": int(strength),
        "phoneNum": data['phoneNumber'],
        'CurrentPair': None
    }

    # Check if user exists (update) or create new
    volunteers = volDB.get("Volunteers", [])
    user_index = None

    for i, vol in enumerate(volunteers):
        if vol.get("email/userName") == email:
            user_index = i
            break

    if user_index is not None:
        # Update existing user
        volunteers[user_index] = user
    else:
        # Add new user
        volunteers.append(user)

    volDB["Volunteers"] = volunteers

    # Save back to file
    with open("VolunteerDB.json", "w") as f:
        json.dump(volDB, f, indent=4)

    return jsonify({
        'success': True,
        'message': 'Profile saved successfully'
    })


@app.route('/checkUser', methods=['POST'])
def check_user():
    try:
        data = request.get_json(silent=True) or {}
        email = (data.get("email") or request.headers.get("X-User-Email") or "").strip().lower()

        if not email:
            return jsonify({"hasProfile": False, "error": "Missing email"}), 400

        with open(USER_DB_PATH, "r") as f:
            userDB = json.load(f)

        users = userDB.get("Users", [])
        if not isinstance(users, list):
            return jsonify({"hasProfile": False, "error": "Users is not a list"}), 500

        for user in users:
            stored = (user.get("email/userName") or user.get("email") or user.get("userName") or "")
            stored = stored.strip().lower()

            if stored == email:
                return jsonify({"hasProfile": True})

        return jsonify({"hasProfile": False})

    except FileNotFoundError:
        return jsonify({"hasProfile": False, "error": f"UserDB.json not found at {USER_DB_PATH}"}), 500
    except json.JSONDecodeError:
        return jsonify({"hasProfile": False, "error": "UserDB.json is not valid JSON"}), 500
    except Exception as e:
        print("ERROR /checkUser:", repr(e))
        return jsonify({"hasProfile": False, "error": str(e)}), 500


@app.route('/CreateUpdateUserProfile', methods=['POST'])
def create_update_user_profile():
    data = request.get_json()

    email = data['email']

    # Create user object
    user = {
        "image": data.get('profileImage', ''),
        "email/userName": email,
        "name": data['fullName'],
        "age": int(data['age']),
        "height": data['height'],
        "weight": data['weight'],
        "condition": data.get('condition', ''),
        "genderPreference": data.get('genderPreference', ''),
        "currentPair": None
    }

    # Read existing database
    with open(USER_DB_PATH, "r") as f:
        userDB = json.load(f)

    # Check if user exists (update) or create new
    users = userDB.get("Users", [])
    user_index = None

    for i, u in enumerate(users):
        stored = (u.get("email/userName") or u.get("email") or u.get("userName") or "")
        if stored.strip().lower() == email.strip().lower():
            user_index = i
            break

    if user_index is not None:
        # Update existing user
        users[user_index] = user
    else:
        # Add new user
        users.append(user)

    userDB["Users"] = users

    # Save back to file
    with open(USER_DB_PATH, "w") as f:
        json.dump(userDB, f, indent=4)

    return jsonify({
        'success': True,
        'message': 'User profile saved successfully'
    })


@app.route('/CheckVol', methods=['POST'])
def check_vol():
    try:
        data = request.get_json(silent=True) or {}
        email = (data.get("email") or request.headers.get("X-User-Email") or "").strip().lower()

        if not email:
            return jsonify({"hasProfile": False, "error": "Missing email"}), 400

        with open(DB_PATH, "r") as f:
            volDB = json.load(f)

        users = volDB.get("Volunteers", [])
        if not isinstance(users, list):
            return jsonify({"hasProfile": False, "error": "Users is not a list"}), 500

        for vol in users:
            stored = (vol.get("email/userName") or vol.get("email") or vol.get("userName") or "")
            stored = stored.strip().lower()

            if stored == email:
                return jsonify({"hasProfile": True})

        return jsonify({"hasProfile": False})

    except FileNotFoundError:
        return jsonify({"hasProfile": False, "error": f"VolunteerDB.json not found at {DB_PATH}"}), 500
    except json.JSONDecodeError:
        return jsonify({"hasProfile": False, "error": "VolunteerDB.json is not valid JSON"}), 500
    except Exception as e:
        print("ERROR /CheckVol:", repr(e))
        return jsonify({"hasProfile": False, "error": str(e)}), 500


def updateUser(email, **updates):
    with open("UserDB.json", "r") as f:
        userDB = json.load(f)

    for user in userDB.get("Users", []):
        if user.get("email/userName") == email:
            for k, v in updates.items():
                user[k] = v

            with open("UserDB.json", "w") as f:
                json.dump(userDB, f, indent=4)

            return user
    return None

def getUser(email):
    with open("UserDB.json", "r") as f:
        userDB = json.load(f)

    for user in userDB.get("Users", []):
        if user.get("email/userName") == email:
            return user
    return


# makeVolProfile(
#     "person6.jpg",
#     "James123@gmail.com",
#     "James",
#     [],
#     "20",
#     "200",
#     "Male",
#     "68",
#     '2982828282',
#     "1",
#     "Toyota Corolla",
#     "Blue",
# )

# makeVolProfile(
#     "person4.jpg",
#     "Pubert@gmail.com",
#     "Pubert",
#     [],
#     "20",
#     "115",
#     "52",
#     "Male",
#     "0",
#     "1234345576"
# )

# makeUserProfile(
#     "person5.jpg",
#     "hamlet@gmail.com",
#     "Hamlet",
#     '55',
#     "155",
#     "62",
#     "Male",
#     ['Diabetes'],
#     "Male",
#     "1234345576"
# )

# makeUserProfile(
#     "person7.jpg",
#     "goblin1@gmail.com",
#     "goblin1",
#     '67',
#     "190",
#     "65",
#     "Female",
#     ['Diabetes', 'Artheritis', 'Insomnia'],
#     "No Preference",
#     "1234345576"
# )
