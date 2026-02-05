# 📸 Classroom Instagram

**A Smart Academic Engagement Platform. Combining the best of social media with the structure of a classroom.**

This project was built for the **JBIET HackX 2025** hackathon.

![HACKX_POSTER_MODIFIED_page-0001](https://github.com/user-attachments/assets/1755a87f-ffc4-4924-9add-e60e3afb1d8a)


---

## 🚀 Live Demo

* **Live Web App:** (https://classroom-instagram-app.web.app/)

---

## 🎯 The Problem

Traditional classroom management tools (like Google Classroom) are formal, rigid, and non-engaging. Students rarely interact beyond submitting assignments, leading to low motivation. Meanwhile, students are highly active on social media platforms, which foster creativity, peer interaction, and instant updates.

## ✨ Our Solution

"Classroom Instagram" is an AI-powered academic social platform that works like Instagram for the classroom. It's visual, interactive, and engaging.

* Teachers can post academic notices, assignments, marks, and attendance.
* Students can interact with posts, submit work, and view their grades.
* A built-in AI assistant helps students study by generating flashcards from notes.

## 🏆 Key Features

### 1. Role-Based Authentication & Dashboards

The app provides a completely different, tailored UI depending on the user's role. This is established during the **Sign Up** process, where a user must identify as either a Student or a Teacher. This role is then saved to Firestore and controls the entire app experience.

| **Sign Up (with Role Selection)** | **Student Dashboard** | **Teacher Dashboard** |
| :---: | :---: | :---: |
| The beautiful login screen includes a toggle that appears during sign-up, allowing users to select their role. | Students get a 4-tab view focused on consuming content, viewing work, and using the AI study tool. | Teachers get a 3-tab view with a center "Create" button, focused on posting assignments and managing grades. |
| <img width="400" height="844" alt="Screenshot_20260205-112021" src="https://github.com/user-attachments/assets/e346db08-8aee-44fb-825b-d9d7aa1d2623" /> | <img width="400" height="844" alt="Screenshot_20260205-111933" src="https://github.com/user-attachments/assets/4d7f7a0c-f076-4138-b0e5-d3067d7e134a" /> | <img width="400" height="844" alt="Screenshot_20260205-112113" src="https://github.com/user-attachments/assets/f398e786-6683-45c7-bf9e-3fce2716656b" /> |

### 2. The Social Feed (Posts, Likes & Comments)

A real-time, Instagram-style feed where teachers and students can post updates.

* **Full-Width Image Posts:** Images are displayed in their full aspect ratio, just like a modern social app.
* **Real-time Likes:** Tap the heart, and the count updates instantly for everyone, powered by Firestore.
* **Real-time Comments:** A full comment section for each post.

| **Main Feed** | **Comments Page** |
| :---: | :---: |
| <img width="400" height="844" alt="Screenshot_20260205-111933" src="https://github.com/user-attachments/assets/a8268221-48b7-45d9-878c-1deaf68bcc0b" /> |  ![WhatsApp Image 2025-10-31 at 23 28 26_bd7a08c0](https://github.com/user-attachments/assets/7f570a4c-1823-411c-a872-52138813a5e2)  |

### 3. "Wow" Feature: AI Study Buddy

An integrated AI tool to help students study. Using the **Google Gemini API**, students can paste in their lecture notes and instantly receive a set of Q&A flashcards.

| **Input Notes** | **Generated Flashcards** |
| :---: | :---: |
| ![IMG-20251031-WA0017](https://github.com/user-attachments/assets/7d5a0dfa-6935-4091-aa65-ee21557399fd) | ![IMG-20251031-WA0018](https://github.com/user-attachments/assets/045bcd75-afbb-4e70-bbfc-1d2f51a3bd03) |

### 4. The Complete Academic Loop (End-to-End)

This is the core of the platform. We built the *entire* feedback loop for assignments.

#### 1. Teacher Posts Assignment
Teachers get a dedicated "Create Assignment" form with title, description, and a due date picker.

![IMG-20251031-WA0025](https://github.com/user-attachments/assets/05646167-ceb5-4b54-b35c-4a50b5d1ebab)


#### 2. Student Views Assignment
Students see all assignments in their "Work" tab, sorted by due date. 

![Image](https://github.com/user-attachments/assets/0aff0e30-573b-4a1e-ba13-df40ebfccd27)


#### 3. Student Submits Work
Students can upload their work (PDF, images, etc.) and add a private comment for the teacher. 

<img width="498" height="640" alt="image" src="https://github.com/user-attachments/assets/ef392b80-d8a5-4af8-bc9e-9f43a4cc07c5" />


#### 4. Teacher Views Submissions
The teacher's dashboard lists all student submissions for each assignment. They can view the file and see the student's comments. 

![WhatsApp Image 2025-11-01 at 00 17 18_669cebfd](https://github.com/user-attachments/assets/d057f255-c287-47c2-800a-26b4837dac6d)


#### 5. Teacher Posts Grade
The teacher can post a mark (e.g., "A+" or "95/100") directly from the submissions page.

<img width="380" height="802" alt="Screenshot_20260205-112131" src="https://github.com/user-attachments/assets/3da2cc9c-f53e-4e6d-a053-3ea6b8119c0d" />



#### 6. Student Views Grade
The student can go to their "My Marks" page to see all their grades in one place.

<img width="331" height="700" alt="Screenshot_20260205-112005" src="https://github.com/user-attachments/assets/49d75d61-3f3b-472e-b6e2-8d596e1213d4" />


## Tinker
 🛠️ Technology Stack

| Category | Technology |
| :--- | :--- |
| **Frontend** | Flutter (cross-platform for Web, iOS, & Android) |
| **Backend** | Firebase (Authentication, Firestore, Storage) |
| **AI** | Google AI Studio (Gemini API) |
| **Key Packages** | `firebase_core`, `cloud_firestore`, `firebase_storage`, `file_picker`, `image_picker`, `google_generative_ai`, `intl`, `timeago` |

---

# 🏛️ Project Architecture & Database Schema

This document outlines the high-level architecture and database structure for the Classroom Instagram app.

## 1. System Architecture

The app uses a **Flutter frontend** with a **Firebase backend**. This is a classic "serverless" model that allows for rapid development, real-time data, and high scalability.

* **Flutter:** Handles all UI and business logic.
* **Firebase Authentication:** Manages user sign-up, login, and identity.
* **Cloud Firestore:** Acts as our main NoSQL database for all app data.
* **Firebase Storage:** Used to host and serve user-uploaded images and files (like assignment submissions).
* **Google Gemini API:** Provides AI-powered features like the flashcard generator.

## 2. Cloud Firestore Schema

This diagram shows how our data collections are organized in Firestore.

```mermaid
graph TD;
    subgraph "Root"
        C1[users]
        C2[posts]
        C3[assignments]
    end

    C1 -- doc/userId --> U["User Document<br/>role: student/teacher<br/>email: user@email.com"]

    C2 -- doc/postId --> P["Post Document<br/>text: Hello...<br/>imageUrl: ...<br/>likes: [...]<br/>commentCount: 5"]

    C3 -- doc/assignmentId --> A["Assignment Document<br/>title: History Essay<br/>dueDate: ...<br/>teacherId: ..."]

    P -- subcollection --> C4[comments]
    C4 -- doc/commentId --> CM["Comment Document<br/>text: Great post!<br/>userEmail: ..."]

    A -- subcollection --> C5[submissions]
    C5 -- doc/studentId --> S["Submission Document<br/>fileUrl: ...<br/>fileName: essay.pdf<br/>grade: A-"]

```

---


## 🔄 System Workflow

We use Firebase for robust authentication and a role-based system to direct users to the correct experience. When a user logs in, the app checks their "role" in Firestore (`student` or `teacher`) and provides the correct navigation shell for their tasks.

```mermaid
graph TD;
    A[User Enters App] --> B{Is Logged In?};
    B -- No --> C[LoginPage];
    C -- Signs Up as Student --> D[Create student user doc];
    C -- Signs Up as Teacher --> E[Create teacher user doc];
    B -- Yes --> F[RoleGate];
    F -- Reads user doc --> G{Role?};
    
    G -- "student" --> H[StudentNavigationShell];
    H --> H1[Social Feed];
    H --> H2[Assignments Page];
    H --> H3[AI Study Page];
    H --> H4[Profile Page];
    
    G -- "teacher" --> I[TeacherNavigationShell];
    I --> I1[Teacher Dashboard];
    I --> I2[Post Marks Page];
    I --> I3[Profile Page];
    I -- FAB --> I4[Create Assignment Page];
```
---

## 🔮 Future Roadmap

Given more time, we would love to expand the platform's features:

* **Attendance Module:** A "check-in" button for students that allows teachers to take attendance in real-time.
* **AI-Powered Moderation:** Use an AI model to automatically flag inappropriate language in posts or comments.
* **Direct Messaging:** A chat system for student-to-student and student-to-teacher communication.
* **Push Notifications:** Send real-time push notifications for new grades, assignments, and comments.
* **Calendar Integration:** A full calendar view that automatically populates with assignment due dates.
