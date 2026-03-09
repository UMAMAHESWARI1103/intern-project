from flask import Flask, jsonify, request
from flask_cors import CORS
from sklearn.neighbors import NearestNeighbors
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MinMaxScaler
import pandas as pd
import numpy as np
from pymongo import MongoClient
from bson import ObjectId
import traceback
from datetime import datetime

app = Flask(__name__)
CORS(app)

# ─────────────────────────────────────────
# MongoDB connection
# ─────────────────────────────────────────
client = MongoClient("mongodb://localhost:27017/godsconnect")
db     = client["godsconnect"]   # ← your DB name

# ─────────────────────────────────────────
# HARDCODED TEMPLES (same as your backend)
# Used for content-based filtering features
# ─────────────────────────────────────────
HARDCODED_TEMPLES = [
    {"id": "1001", "name": "Palani Murugan Temple",         "deity": "Lord Murugan",        "location": "Palani, Dindigul",         "festivals": "Thaipusam Skanda Shashti Panguni Uthiram"},
    {"id": "1002", "name": "Thiruchendur Murugan Temple",   "deity": "Lord Murugan",        "location": "Thiruchendur, Thoothukudi","festivals": "Skanda Shashti Thaipusam Vaikasi Visakam"},
    {"id": "1003", "name": "Swamimalai Murugan Temple",     "deity": "Lord Murugan",        "location": "Swamimalai, Kumbakonam",   "festivals": "Thaipusam Skanda Shashti"},
    {"id": "1004", "name": "Tiruttani Murugan Temple",      "deity": "Lord Murugan",        "location": "Tiruttani, Tiruvallur",    "festivals": "Skanda Shashti Vaikasi Visakam"},
    {"id": "1005", "name": "Pazhamudircholai Murugan",      "deity": "Lord Murugan",        "location": "Pazhamudircholai, Madurai","festivals": "Thaipusam Panguni Uthiram"},
    {"id": "1006", "name": "Tirupati Balaji Temple",        "deity": "Lord Venkateswara",   "location": "Tirupati, Andhra Pradesh", "festivals": "Brahmotsavam Vaikunta Ekadasi"},
    {"id": "1007", "name": "Kapaleeshwarar Temple",         "deity": "Lord Shiva",          "location": "Mylapore, Chennai",        "festivals": "Arubathimoovar Panguni Uthiram"},
    {"id": "1008", "name": "Parthasarathy Temple",          "deity": "Lord Vishnu",         "location": "Triplicane, Chennai",      "festivals": "Brahmotsavam Vaikunta Ekadasi"},
    {"id": "1009", "name": "Marundeeswarar Temple",         "deity": "Lord Shiva",          "location": "Thiruvanmiyur, Chennai",   "festivals": "Shivaratri Arudra"},
    {"id": "1010", "name": "Vadapalani Murugan Temple",     "deity": "Lord Murugan",        "location": "Vadapalani, Chennai",      "festivals": "Skanda Shashti Thaipusam"},
    {"id": "1011", "name": "Meenakshi Amman Temple",        "deity": "Goddess Meenakshi",   "location": "Madurai",                  "festivals": "Meenakshi Thirukalyanam Navaratri"},
    {"id": "1012", "name": "Brihadeeswarar Temple",         "deity": "Lord Shiva",          "location": "Thanjavur",                "festivals": "Shivaratri Karthigai"},
    {"id": "1013", "name": "Ramanathaswamy Temple",         "deity": "Lord Shiva",          "location": "Rameswaram",               "festivals": "Shivaratri Karthigai Deepam"},
    {"id": "1014", "name": "Nataraja Temple",               "deity": "Lord Shiva",          "location": "Chidambaram",              "festivals": "Natyanjali Shivaratri Arudra"},
    {"id": "1015", "name": "Arunachaleswarar Temple",       "deity": "Lord Shiva",          "location": "Thiruvannamalai",          "festivals": "Karthigai Deepam Shivaratri"},
    {"id": "1016", "name": "Kamakshi Amman Temple",         "deity": "Goddess Kamakshi",    "location": "Kanchipuram",              "festivals": "Navaratri Brahmotsavam"},
    {"id": "1017", "name": "Varadharaja Perumal Temple",    "deity": "Lord Vishnu",         "location": "Kanchipuram",              "festivals": "Brahmotsavam Vaikunta Ekadasi"},
    {"id": "1018", "name": "Ranganathaswamy Temple",        "deity": "Lord Vishnu",         "location": "Srirangam, Tiruchirappalli","festivals": "Vaikunta Ekadasi Brahmotsavam"},
    {"id": "1019", "name": "Sarangapani Temple",            "deity": "Lord Vishnu",         "location": "Kumbakonam",               "festivals": "Brahmotsavam Vaikunta Ekadasi"},
    {"id": "1020", "name": "Airavatesvara Temple",          "deity": "Lord Shiva",          "location": "Darasuram, Kumbakonam",    "festivals": "Shivaratri Karthigai"},
]

# ═══════════════════════════════════════════════════════════════════
#  HELPER: fetch all donations from MongoDB
# ═══════════════════════════════════════════════════════════════════
def get_donations():
    try:
        raw = list(db.donations.find(
            {"paymentStatus": "paid"},
            {"_id": 0, "donorEmail": 1, "templeId": 1, "templeName": 1, "amount": 1}
        ))
        return pd.DataFrame(raw) if raw else pd.DataFrame()
    except Exception as e:
        print(f"[MongoDB] Donation fetch error: {e}")
        return pd.DataFrame()

# ═══════════════════════════════════════════════════════════════════
#  HELPER: fetch DB temples + merge with hardcoded
# ═══════════════════════════════════════════════════════════════════
def get_all_temples():
    temples = {t['id']: t for t in HARDCODED_TEMPLES}
    try:
        db_temples = list(db.temples.find({}, {"_id": 1, "name": 1, "deity": 1, "location": 1, "festivals": 1}))
        for t in db_temples:
            tid = str(t['_id'])
            festivals = t.get('festivals', [])
            if isinstance(festivals, list):
                festivals = ' '.join(festivals)
            temples[tid] = {
                "id":        tid,
                "name":      t.get('name', ''),
                "deity":     t.get('deity', ''),
                "location":  t.get('location', ''),
                "festivals": festivals,
            }
    except Exception as e:
        print(f"[MongoDB] Temple fetch error: {e}")
    return list(temples.values())

# ═══════════════════════════════════════════════════════════════════
#  ML MODEL 1: COLLABORATIVE FILTERING (KNN)
#  Finds users similar to the current user based on donation patterns
#  Returns temple IDs that similar users donated to
# ═══════════════════════════════════════════════════════════════════
def collaborative_filtering(user_email, df):
    if df.empty or len(df['donorEmail'].unique()) < 2:
        return [], "not_enough_users"

    # Build User × Temple matrix  (rows=users, cols=temples, values=amount donated)
    matrix = df.pivot_table(
        index='donorEmail', columns='templeId',
        values='amount', aggfunc='sum', fill_value=0
    )

    if user_email not in matrix.index:
        return [], "new_user"

    # Train KNN — cosine similarity finds users with similar donation taste
    n_neighbors = min(5, len(matrix))
    model = NearestNeighbors(metric='cosine', algorithm='brute', n_neighbors=n_neighbors)
    model.fit(matrix.values)

    user_idx    = matrix.index.tolist().index(user_email)
    user_vector = matrix.values[user_idx].reshape(1, -1)

    distances, indices = model.kneighbors(user_vector)

    # Temples this user already donated to
    user_temples = set(df[df['donorEmail'] == user_email]['templeId'].tolist())

    # Collect temples that similar users donated to but current user hasn't
    recommended = {}
    for dist, idx in zip(distances.flatten(), indices.flatten()):
        similar_email = matrix.index[idx]
        if similar_email == user_email:
            continue
        similarity = 1 - dist   # cosine distance → similarity
        sim_temples = df[df['donorEmail'] == similar_email]['templeId'].tolist()
        for tid in sim_temples:
            if tid not in user_temples:
                recommended[tid] = recommended.get(tid, 0) + similarity

    # Sort by score descending
    sorted_recs = sorted(recommended.items(), key=lambda x: x[1], reverse=True)
    return [tid for tid, _ in sorted_recs[:10]], "collaborative"

# ═══════════════════════════════════════════════════════════════════
#  ML MODEL 2: CONTENT-BASED FILTERING (TF-IDF + Cosine Similarity)
#  Looks at what TYPES of temples user donated to (deity, festivals)
#  Recommends similar temples they haven't visited
# ═══════════════════════════════════════════════════════════════════
def content_based_filtering(user_email, df, all_temples):
    if df.empty:
        return [], "no_data"

    user_df = df[df['donorEmail'] == user_email]
    if user_df.empty:
        return [], "new_user"

    user_temple_ids = set(user_df['templeId'].tolist())

    # Build feature string for each temple: "deity location festivals"
    temple_map = {t['id']: t for t in all_temples}

    def build_features(t):
        return f"{t.get('deity','')} {t.get('location','')} {t.get('festivals','')} {t.get('name','')}".lower()

    # All temples as a list for TF-IDF
    all_ids      = [t['id'] for t in all_temples]
    all_features = [build_features(t) for t in all_temples]

    if len(all_features) < 2:
        return [], "not_enough_temples"

    # TF-IDF vectorize temple features
    tfidf   = TfidfVectorizer(stop_words='english')
    tfidf_matrix = tfidf.fit_transform(all_features)

    # Build a "user profile" = average of TF-IDF vectors of donated temples
    donated_indices = [i for i, tid in enumerate(all_ids) if tid in user_temple_ids]
    if not donated_indices:
        return [], "no_matching_temples"

    user_profile = np.mean(tfidf_matrix[donated_indices].toarray(), axis=0).reshape(1, -1)

    # Cosine similarity between user profile and every temple
    similarities = cosine_similarity(user_profile, tfidf_matrix.toarray()).flatten()

    # Score temples — exclude ones user already donated to
    scored = []
    for i, (tid, sim) in enumerate(zip(all_ids, similarities)):
        if tid not in user_temple_ids:
            scored.append((tid, float(sim)))

    scored.sort(key=lambda x: x[1], reverse=True)
    return [tid for tid, _ in scored[:10]], "content_based"

# ═══════════════════════════════════════════════════════════════════
#  HYBRID: Combine both ML models
#  CF score weighted 60%, CB score weighted 40%
# ═══════════════════════════════════════════════════════════════════
def hybrid_recommend(user_email):
    df          = get_donations()
    all_temples = get_all_temples()

    cf_ids, cf_type = collaborative_filtering(user_email, df)
    cb_ids, cb_type = content_based_filtering(user_email, df, all_temples)

    # If new user or not enough data → fallback to popular temples
    if cf_type == "new_user" and cb_type == "new_user":
        return popular_temples(df, all_temples), "popular"

    if cf_type == "not_enough_users":
        # Only content-based available
        return enrich_temples(cb_ids, all_temples), "content_based"

    # Combine scores
    scores = {}
    for rank, tid in enumerate(cf_ids):
        scores[tid] = scores.get(tid, 0) + (0.6 * (10 - rank))   # CF weight = 60%
    for rank, tid in enumerate(cb_ids):
        scores[tid] = scores.get(tid, 0) + (0.4 * (10 - rank))   # CB weight = 40%

    sorted_ids = sorted(scores.keys(), key=lambda x: scores[x], reverse=True)
    return enrich_temples(sorted_ids[:5], all_temples), "hybrid_ml"

# ═══════════════════════════════════════════════════════════════════
#  POPULAR TEMPLES fallback (for new users with no donation history)
# ═══════════════════════════════════════════════════════════════════
def popular_temples(df, all_temples):
    if df.empty:
        # Return first 5 hardcoded temples
        return all_temples[:5]
    popular_ids = (
        df.groupby('templeId')['amount']
        .sum()
        .nlargest(5)
        .index.tolist()
    )
    result = enrich_temples(popular_ids, all_temples)
    if not result:
        return all_temples[:5]
    return result

# ═══════════════════════════════════════════════════════════════════
#  Enrich temple IDs with full temple details
# ═══════════════════════════════════════════════════════════════════
def enrich_temples(temple_ids, all_temples):
    temple_map = {t['id']: t for t in all_temples}
    result     = []
    for tid in temple_ids:
        if tid in temple_map:
            result.append(temple_map[tid])
    return result

# ═══════════════════════════════════════════════════════════════════
#  API ROUTES
# ═══════════════════════════════════════════════════════════════════

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status":     "ML server running ✅",
        "port":       5001,
        "algorithms": ["KNN Collaborative Filtering", "TF-IDF Content-Based Filtering", "Hybrid"],
        "timestamp":  datetime.now().isoformat()
    })

# ─────────────────────────────────────────────────────────────────
# Main recommendation endpoint
# GET /recommend/<user_email>
# ─────────────────────────────────────────────────────────────────
@app.route('/recommend/<path:user_email>', methods=['GET'])
def recommend(user_email):
    try:
        temples, rec_type = hybrid_recommend(user_email)

        type_labels = {
            "hybrid_ml":    "🤖 ML Hybrid (Collaborative + Content-Based)",
            "collaborative":"🤝 Collaborative Filtering (KNN)",
            "content_based":"📖 Content-Based Filtering (TF-IDF)",
            "popular":      "🔥 Trending Temples (new user)",
        }

        return jsonify({
            "success":      True,
            "userEmail":    user_email,
            "suggestions":  temples,
            "type":         rec_type,
            "typeLabel":    type_labels.get(rec_type, rec_type),
            "count":        len(temples),
        })

    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e), "suggestions": []}), 500

# ─────────────────────────────────────────────────────────────────
# Debug: show what ML sees for a user
# GET /debug/<user_email>
# ─────────────────────────────────────────────────────────────────
@app.route('/debug/<path:user_email>', methods=['GET'])
def debug(user_email):
    try:
        df          = get_donations()
        all_temples = get_all_temples()
        user_df     = df[df['donorEmail'] == user_email] if not df.empty else pd.DataFrame()

        return jsonify({
            "total_donations_in_db": len(df),
            "unique_users":          int(df['donorEmail'].nunique()) if not df.empty else 0,
            "unique_temples_in_db":  int(df['templeId'].nunique())  if not df.empty else 0,
            "user_donations":        user_df.to_dict('records') if not user_df.empty else [],
            "total_temples_for_ml":  len(all_temples),
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ─────────────────────────────────────────────────────────────────
# Add a test donation (for testing ML without real payments)
# POST /test-donation  { "email": "...", "templeId": "...", "templeName": "...", "amount": 100 }
# ─────────────────────────────────────────────────────────────────
@app.route('/test-donation', methods=['POST'])
def add_test_donation():
    try:
        data = request.json
        db.donations.insert_one({
            "donorEmail":    data['email'],
            "templeId":      data['templeId'],
            "templeName":    data['templeName'],
            "amount":        data.get('amount', 100),
            "paymentStatus": "paid",
            "createdAt":     datetime.now(),
            "isTestData":    True,
        })
        return jsonify({"success": True, "message": "Test donation added ✅"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    print("\n🚀 Temple ML Server running on http://localhost:5001")
    print("📊 Algorithms: KNN Collaborative Filtering + TF-IDF Content-Based (Hybrid)")
    print("🔗 Endpoints:")
    print("   GET  /health")
    print("   GET  /recommend/<email>")
    print("   GET  /debug/<email>")
    print("   POST /test-donation\n")
    app.run(port=5001, debug=True)