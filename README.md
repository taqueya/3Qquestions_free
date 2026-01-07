# Walkthrough: IP Skills Level 2 App

I have generated the source code for the IP Skills Level 2 Practice App. Since the local Flutter environment was not detected, I have created the project structure manually.

## Setup Instructions

### 1. Environment Verification
Ensure you have Flutter installed. Run:
```bash
flutter doctor
```

### 2. Dependency Installation
Navigate to the project folder and install dependencies:
```bash
cd c:\Users\USER\Documents\Antigravity\2Qquestion
flutter pub get
```

### 3. Supabase Configuration
Open `lib/core/constants.dart` and update the following with your Supabase project details:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Database Setup
Ensure your Supabase project has the following tables:

**Table: `questions`**
- `id` (int8, primary key)
- `exam_count` (text)
- `question_number` (int8)
- `category` (text)
- `question_text` (text)
- `correct_option` (text)
- `wrong_options` (text)
- `explanation` (text)

**Table: `user_mistakes`**
- `id` (int8, primary key, auto-gen)
- `user_id` (uuid or text)
- `question_id` (int8, foreign key to questions.id)
- `created_at` (timestamp, default now())

### 5. Running the App
```bash
flutter run
```

## Features Implemented
- **Home Page**: Select specific Exam or Category.
- **Quiz Page**:
    - Dispalys Question Source (`第X回 問Y (分野)`).
    - Shuffles options (Correct + 3 Wrong).
    - Checks answer and shows Explanation.
- **Result Page**:
    - Shows accuracy rate and correct/total count.
    - Displays Pie Chart (using `fl_chart`).
- **Authentication**:
    - Email/Password & Google Sign-In.
    - **Google Sign-In Setup Required**:
        1. **Google Cloud Console**:
            - Create a **Web Client ID** (Application Type: Web Application).
            - Add `http://localhost:3000` to "Authorized JavaScript origins".
        2. **Code Configuration**:
            - `lib/presentation/pages/auth_page.dart`: Set `webClientId` to the Web Client ID.
            - `web/index.html`: Add `<meta name="google-signin-client_id" content="YOUR_CLIENT_ID">`.
        3. **Running the App (Web)**:
            - Run with fixed port: `flutter run -d chrome --web-port 3000`
- **Mistake Management**:
    - Wrong answers are saved to `user_mistakes`.
    - "Mistake Mode" fetches these questions for review (Per User).
    - Handles UUID constraint for guest users (Fallback).
