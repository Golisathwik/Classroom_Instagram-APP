# 📸 Classroom Instagram

**A Smart Academic Engagement Platform. Combining the best of social media with the structure of a classroom.**

This project was built for the **JBIET HackX 2025** hackathon.

![Image](https://github.com/user-attachments/assets/5975b907-88b6-4afa-80ac-bf234cff6369)

---

## 🚀 Live Demo & Video

* **Live Web App:** [**ADD YOUR FIREBASE HOSTING URL HERE**]
* **Video Walkthrough (2 Mins):**



> **Note to Evaluators:** A video walkthrough is the best way to see all the features (including both Student and Teacher roles) in action!

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
| ![IMG-20251031-WA0013](https://github.com/user-attachments/assets/f745b029-74aa-4723-940a-c7d189de7b4a)

 | ![Image](https://github.com/user-attachments/assets/c4be0d86-b5c6-4458-b5a4-31d2d713672a) | ![Image](https://github.com/user-attachments/assets/b89f4f72-5ab5-4f41-83a2-1823e3abf2e2) |
### 1. Role-Based Dashboards (Student vs. Teacher)

The app provides a completely different, tailored UI depending on the user's role, which is selected at sign-up.

| **Student Dashboard** | **Teacher Dashboard** |
| :---: | :---: |
| A 4-tab navigation for `Home`, `Work`, `AI Study`, and `Profile`. Designed for consumption and interaction. | A 3-tab navigation with a center-docked "Create" button. Designed for content creation and management. |
| ![Image](https://github.com/user-attachments/assets/c4be0d86-b5c6-4458-b5a4-31d2d713672a) | ![Image](https://github.com/user-attachments/assets/b89f4f72-5ab5-4f41-83a2-1823e3abf2e2) |

### 2. The Social Feed (Posts, Likes & Comments)

A real-time, Instagram-style feed where teachers and students can post updates.

* **Full-Width Image Posts:** Images are displayed in their full aspect ratio, just like a modern social app.
* **Real-time Likes:** Tap the heart, and the count updates instantly for everyone, powered by Firestore.
* **Real-time Comments:** A full comment section for each post.

| **Main Feed** | **Comments Page** |
| :---: | :---: |
| ![Image](https://github.com/user-attachments/assets/d60c67e2-0706-4a7a-beac-89b96ff2cd24) | ![Image](https://github.com/user-attachments/assets/5cfbd1ab-2efa-4ff9-ac05-be82cbd96a4c) |

### 3. "Wow" Feature: AI Study Buddy

An integrated AI tool to help students study. Using the **Google Gemini API**, students can paste in their lecture notes and instantly receive a set of Q&A flashcards.

| **Input Notes** | **Generated Flashcards** |
| :---: | :---: |
| ![Image](https://github.com/user-attachments/assets/a90a1ab7-acd5-4fa0-90f2-400b289c852d) | ![Image](https://github.com/user-attachments/assets/4c194366-aa3e-465b-ad5f-54e774674d12) |

### 4. The Complete Academic Loop (End-to-End)

This is the core of the platform. We built the *entire* feedback loop for assignments.

#### 1. Teacher Posts Assignment
Teachers get a dedicated "Create Assignment" form with title, description, and a due date picker.
![Image](https://github.com/user-attachments/assets/1dec7a52-e70d-4059-aa7f-e66718e768ec)

#### 2. Student Views Assignment
Students see all assignments in their "Work" tab, sorted by due date.
![IMG-20251031-WA0016](https://github.com/user-attachments/assets/c3f6358f-da48-4f20-b18f-4d1c61770f5b)


#### 3. Student Submits Work
Students can upload their work (PDF, images, etc.) and add a private comment for the teacher.
[**ADD SCREENSHOT of the `submit_assignment_page.dart` with a file selected**]

#### 4. Teacher Views Submissions
The teacher's dashboard lists all student submissions for each assignment. They can view the file and see the student's comments.
![WhatsApp Image 2025-11-01 at 00 17 18_669cebfd](https://github.com/user-attachments/assets/c368a497-da2b-4edb-b081-eb80e8572606)

#### 5. Teacher Posts Grade
The teacher can post a mark (e.g., "A+" or "95/100") directly from the submissions page.
![IMG-20251031-WA0028](https://github.com/user-attachments/assets/45624ccb-b17b-4dca-9a92-7fe1a3deafa1)


#### 6. Student Views Grade
The student can go to their "My Marks" page to see all their grades in one place.
![IMG-20251031-WA0023](https://github.com/user-attachments/assets/0f73257a-5df5-48f1-963a-f18a548b47c0)



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
