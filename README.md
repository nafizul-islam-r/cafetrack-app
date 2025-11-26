\# 🍽️ CafeTrack Mobile — Real-Time Cafeteria Management App



CafeTrack Mobile is a cross-platform \*\*Flutter\*\* application (iOS \& Android) that digitizes cafeteria inventory, manages board-game assets, and collects user feedback — all in real time using \*\*Firebase\*\*.



---



\## ✨ Features



\### 👥 Public / User Portal

\- \*\*Real-Time Inventory Viewing:\*\* Browse live food menu and updated stock.

\- \*\*Asset Availability:\*\* View total and available board-game units.

\- \*\*User Reviews:\*\* Submit star ratings and written comments.

\- \*\*Profile Management:\*\* Registration + login using Firebase Authentication.



\### 🛠️ Administrative Panel (Staff Access)

\- \*\*Full CRUD Control:\*\* Manage food inventory \& board-game assets.

\- \*\*Digital Assignment System:\*\* Log checkout/return via Student ID.

\- \*\*Data Oversight:\*\* View user feedback \& item statuses.



---



\## 🧭 User Setup Guide (Development Installation)



> Ensure Flutter, Dart, Git, and Firebase CLI are installed.



\### 1. Clone the Repository

\\`\\`\\`bash

git clone \[YOUR\_GITHUB\_REPO\_URL]

cd cafetrack\_flutter

\\`\\`\\`



\### 2. Install Dependencies

\\`\\`\\`bash

flutter pub get

\\`\\`\\`



---



\# 🔥 3. Firebase Setup (Required)



\### A. Create Firebase Project

1\. Go to Firebase Console.

2\. Create a new project (e.g., `cafetrack-dev`).

3\. Enable:

&nbsp;  - Authentication (Email/Password)

&nbsp;  - Cloud Firestore



\### B. Configure Apps \& Download Config Files



\#### Android

Download `google-services.json` and place it in:

android/app/



markdown

Copy code



\#### iOS

Download `GoogleService-Info.plist` and place it in:

ios/Runner/



r

Copy code



\### C. Generate firebase\_options.dart

\\`\\`\\`bash

flutterfire configure

\\`\\`\\`



This will generate:

lib/firebase\_options.dart



yaml

Copy code



---



\# 🛡️ 4. Configure Security Rules \& Admin User



\### Firestore Security Rules (Example)

\\`\\`\\`js

rules\_version = '2';

service cloud.firestore {

&nbsp; match /databases/{database}/documents {



&nbsp;   // Users collection

&nbsp;   match /users/{userId} {

&nbsp;     allow read: if request.auth != null;



&nbsp;     allow create: if request.auth != null \&\&

&nbsp;       request.auth.uid == userId;



&nbsp;     allow update: if request.auth != null \&\&

&nbsp;       (request.auth.uid == userId ||

&nbsp;        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');



&nbsp;     allow delete: if request.auth != null \&\&

&nbsp;       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

&nbsp;   }



&nbsp;   // Inventory collection

&nbsp;   match /inventory/{itemId} {

&nbsp;     allow read: if true;



&nbsp;     allow write: if request.auth != null \&\&

&nbsp;       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

&nbsp;   }

&nbsp; }

}

\\`\\`\\`



\### Create Initial Admin User

1\. Create a user in Firebase Authentication.

2\. Add Firestore document under:

users/{UID}



yaml

Copy code



Example:

\\`\\`\\`json

{

&nbsp; "name": "Admin User",

&nbsp; "email": "admin@example.com",

&nbsp; "role": "admin",

&nbsp; "createdAt": "timestamp"

}

\\`\\`\\`



---



\# ▶️ 5. Run the Application

\\`\\`\\`bash

flutter run

\\`\\`\\`



---



\# 🏗️ Project Architecture



This project uses a \*\*Serverless Architecture\*\* with Firebase.



| Component | Technology | Description |

|----------|------------|-------------|

| Frontend | Flutter / Dart | UI \& business logic |

| Backend  | Firebase | Serverless backend |

| Database | Cloud Firestore | Realtime NoSQL DB |

| Auth     | Firebase Auth | Secure login system |

| Logic    | Security Rules | Access control enforcement |



---



\# 🖼️ App Screenshots



> Replace paths with real screenshot files.



| Login / Signup | Inventory Grid | Assignment Panel |

|----------------|----------------|------------------|

| !\[Login](assets/screenshots/login.png) | !\[Inventory](assets/screenshots/inventory.png) | !\[Assignment](assets/screenshots/assignment.png) |



---



\# 🤝 Contribution



This project was developed as a university software project.  

Contributions and suggestions are welcome.



---



\# 📄 License



This project is licensed under the \*\*MIT License\*\*.  

See the `LICENSE` file for details.

