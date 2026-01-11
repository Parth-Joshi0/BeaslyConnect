import json
import math
import base64
import uuid
import os
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

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



@app.route('/CreateUpdateUserProfile', methods=['POST'])
def create_update_user_profile():
    data = request.get_json()

    email = data['email']
    image = data.get('profileImage', '')
    
    # Read existing database
    with open("UserDB.json", "r") as f:
        userDB = json.load(f)

    # Create user object
    user = {
        "Image(base64)": image,
        "email/userName": email,
        "name": data['fullName'],
        "age": int(data['age']),
        "height(Inches)": int(data['height']),
        "weight(Pounds)": int(data['weight']),
        "gender": data['gender'],
        "otherInformation": data.get('otherInformation', ''),
        "volGenderPref": data.get('volGenderPref', ''),
        "phoneNum": data['phoneNumber'],
        "CurrentPair": None
    }

    # Check if user exists (update) or create new
    users = userDB.get("Users", [])
    user_index = None

    for i, usr in enumerate(users):
        if usr.get("email/userName") == email:
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
    with open("UserDB.json", "w") as f:
        json.dump(userDB, f, indent=4)

    return jsonify({
        'success': True,
        'message': 'Profile saved successfully'
    })


@app.route('/CheckUser', methods=['GET'])
def CheckUser(email):
    with open("UserDB.json", "r") as f:
        userDB = json.load(f)

    for user in userDB.get("Users", []):
        if user.get("email/userName") == email:
            return json.dumps({"hasProfile": True})
    return json.dumps({"hasProfile": False})


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "VolunteerDB.json")

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
