import google.generativeai as genai
import json
import os

api_key = os.getenv('GEMINI_API_KEY')
genai.configure(api_key=api_key)

model = genai.GenerativeModel("gemini-2.5-flash")


def analyze_and_match_volunteer(problem):
    
    # Ask Gemini to analyze the problem
    analysis_prompt = f"""
    Analyze this user problem and respond ONLY with valid JSON:

    Problem: {problem}

    Determine:
    1. Which qualifications are needed (CPR Training, First Aid Certification, Medical Certification, Driver's License for transportation)
    2. Urgency level (1=can wait, 2=soon, 3=urgent/call police)
    3. If urgency is 3, should they call police instead?

    Response format:
    {{
        "needed_qualifications": ["CPR Training", "First Aid Certification", "Medical Certification", "Driver's License"],
        "urgency": 1,
        "call_police": false,
        "reason": "brief explanation"
    }}
    """

    response = model.generate_content(analysis_prompt)
    
    # Parse the response
    try:
        response_text = response.text.strip()
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()
        
        analysis = json.loads(response_text)
    except:
        # Fallback parsing
        analysis = {
            "needed_qualifications": [],
            "urgency": 2,
            "call_police": False,
            "reason": "Unable to analyze problem"
        }
    
    # If should call police, return immediately
    if analysis.get("call_police", False):
        return {
            "volunteer": None,
            "analysis": analysis,
            "message": "This situation requires immediate emergency assistance. Please call 911."
        }
    
    # Find best matching volunteer
    with open("VolunteerDB.json", "r") as f:
        volDB = json.load(f)
    
    volunteers = volDB.get("Volunteers", [])
    needed_quals = set(analysis.get("needed_qualifications", []))
    
    best_match = None
    best_score = 0
    
    for vol in volunteers:
        vol_quals = set(vol.get("Qualifications", []))
        
        # Count matching qualifications
        matches = len(needed_quals & vol_quals)
        
        # Calculate score (prioritize exact matches)
        score = matches
        
        # Bonus for having transportation when needed
        if "Driver's License" in needed_quals and vol.get("car") != "No Car":
            score += 0.5
        
        if score > best_score:
            best_score = score
            best_match = vol
    
    return {
        "volunteer": best_match,
        "analysis": analysis,
        "message": "Match found" if best_match else "No suitable volunteers available"
    }


result = analyze_and_match_volunteer("I need someone to drive my elderly mother to a doctor's appointment")

print(f"Urgency: {result['analysis']['urgency']}")
print(f"Needed: {result['analysis']['needed_qualifications']}")
print(f"Best volunteer: {result['volunteer']['name'] if result['volunteer'] else 'None'}")

