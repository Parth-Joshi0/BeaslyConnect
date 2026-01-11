import google.generativeai as genai
import json
import os

api_key = os.getenv('GEMINI_API_KEY', 'AIzaSyBzJ-FmRC3cIu9UXQ-_3XkTDXMyRQmgsvc')
genai.configure(api_key=api_key)

model = genai.GenerativeModel("gemini-1.5-flash")
chat = model.start_chat()

# Initial system prompt
system_prompt = (
    "XXXXXXX is an app created for volunteers to help around the "
    "community they are currently in. A user below will give their problem statement and the urgency of "
    "their issue. 1 means they can wait, 2 means they want help soon, and 3 is urgent. "
    "Based on the information given, parse through the database provided and find the person most suited for this job. "
    "When responding from this point further, speak as if you are speaking to the user directly and warmly."
)

chat.send_message(system_prompt)



def analyze_problem(problem, urgency):
    analysis_prompt = f"""
    User Request:
    Problem: {problem}
    Urgency Level: {urgency} (1=can wait, 2=soon, 3=urgent)

    Analyze this problem and determine which of these FOUR characteristics are required:
    1. Transportation - needs a ride, delivery, or vehicle
    2. CPR Training - needs emergency cardiac response capability
    3. Medical Certification - needs professional medical expertise
    4. First Aid Certification - needs basic first aid/injury care

    Respond ONLY in this JSON format:
    "required_characteristics": 
        "transportation": true/false,
        "cpr_training": true/false,
        "medical_certification": true/false,
        "first_aid_certification": true/false,
    "problem_category": "brief category like 'medical emergency', 'transportation', etc",
    "urgency_note": "brief note about timing needs"
    """

    response = chat.send_message(analysis_prompt)
    try:
        # Extract JSON from response (handles markdown code blocks)
        response_text = response.text.strip()
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()

        return json.loads(response_text)
    except:
        # Fallback if JSON parsing fails
        return {
            "required_characteristics": {
                "transportation": "transport" in problem.lower() or "ride" in problem.lower() or "drive" in problem.lower(),
                "cpr_training": "cpr" in problem.lower() or "cardiac" in problem.lower() or "heart" in problem.lower(),
                "medical_certification": "medical" in problem.lower() or "doctor" in problem.lower() or "nurse" in problem.lower(),
                "first_aid_certification": "first aid" in problem.lower() or "injury" in problem.lower() or "hurt" in problem.lower()
            },
            "problem_category": "general assistance",
            "urgency_note": f"urgency level {urgency}"
        }


def match_volunteer(required_chars, urgency, user_location=None):
    try:
        with open('VolunteerDB.json', 'r', encoding='utf-8') as f:
            data = json.load(f)

        volunteers = data.get('volunteers', [])
        best_match = None
        best_score = 0

        for volunteer in volunteers:
            score = 0
            chars = volunteer.get('characteristics', {})

            for char, required in required_chars.items():
                if required and chars.get(char, False):
                    score += 1

            if score > 0:
                if chars.get('medical certification'):
                    score += 0.5
                if chars.get('cpr training'):
                    score += 0.3

            if user_location and volunteer.get('location', '').lower() == user_location.lower():
                score += 0.5

            if score > best_score:
                best_score = score
                best_match = volunteer

        return best_match

    except Exception as e:
        print(f"Database error: {e}")
        return None
