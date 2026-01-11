import json
import math
import base64
import uuid
import os
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

def image_to_base64(imageDir):  # For Testing
    with open(imageDir, "rb") as image_file:
        image_bytes = image_file.read()
        encoded_bytes = base64.b64encode(image_bytes)
        encoded_string = encoded_bytes.decode("utf-8")
    return encoded_string


@app.route('/CreateUpdateProfile', methods=['POST'])
def create_update_profile():
    data = request.get_json()

    email = data['email']
    profile_data = {
        'email/userName': email,
        'fullName': data['fullName'],
        'phoneNumber': data['phoneNumber'],
        'certifications': data['certifications'],  # Array of strings
        'age': data['age'],
        'gender': data['gender'],
        'weight': data['weight'],
        'height': data['height'],
        'ownsCar': data['ownsCar'],
        'licensePlate': data.get('licensePlate', ''),
        'carMake': data.get('carMake', ''),
        'carColor': data.get('carColor', ''),
        'profileImage': data.get('profileImage', '')  # Base64 string
    }

    # Read existing database
    with open("VolunteerDB.json", "r") as f:
        volDB = json.load(f)

    # Check if user exists (update) or create new
    users = volDB.get("Volunteers", [])
    user_index = None

    for i, vol in enumerate(users):
        if vol.get("email/userName") == email:
            user_index = i
            break

    if user_index is not None:
        # Update existing user
        users[user_index] = profile_data
    else:
        # Add new user
        users.append(profile_data)

    volDB["Volunteers"] = users

    # Save back to file
    with open("VolunteerDB.json", "w") as f:
        json.dump(volDB, f, indent=2)

    return jsonify({
        'success': True,
        'message': 'Profile saved successfully'
    })




def makeUserProfile(image,email, name, age, weight, height, gender, otherInformation, volGenderPref, phoneNum, currPair = None):
    with open("UserDB.json", "r") as f:
        userDB = json.load(f)

    user = {
        "Image(base64)": image_to_base64(image),
        "email/userName": email,
        "name": name,
        "age": int(age),
        "height(Inches)": int(height),
        "weight(Pounds)": int(weight),
        "gender": gender,
        "otherInformation": otherInformation,
        "volGenderPref": volGenderPref,
        "phoneNum": phoneNum,
        "CurrentPair": currPair
    }

    userDB["Users"].append(user)

    with open("UserDB.json", "w") as f:
        json.dump(userDB, f, indent=4)
    return user

def updateVolunteer(email, **updates):
    with open("VolunteerDB.json", "r") as f:
        volDB = json.load(f)

    for vol in volDB.get("Volunteers", []):
        if vol.get("email/userName") == email:
            # apply updates (only keys you pass in)
            for k, v in updates.items():
                vol[k] = v

            with open("VolunteerDB.json", "w") as f:
                json.dump(volDB, f, indent=4)

            return vol  # updated record

    return None  # not found

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
