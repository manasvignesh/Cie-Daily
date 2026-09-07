# 🚀 CIE Daily

<div align="center">

### **Technology Awareness • Interactive Learning • Student Community**

**A platform built to help engineering students stay updated with technology, discover new skills, learn from experts, and discuss what they discover.**

<br />

> **Discover. Learn. Explore. Discuss. Grow.**

</div>

---

## 🌐 What is CIE Daily?

**CIE Daily** is a technology-focused platform created for engineering students who want to understand how the world of technology is evolving every day.

The platform focuses primarily on **India**, while also covering important technological and engineering developments from around the world.

It brings together:

**📰 Technology News**
**🎬 Interactive Tech Reels**
**🎙️ Expert-led Learning Spaces**
**🔗 Student Connections**
**💬 Private 1-to-1 Conversations**

The idea is simple:

> **Technology changes every day. Students should be able to keep up with it.**

---

# 💡 The Idea Behind CIE Daily

CIE Daily started from a simple observation:

Engineering students spend a huge amount of time consuming information online, but important technology developments are scattered across different platforms.

So instead of asking students to search everywhere for technology updates, the idea was to create one focused ecosystem around **technology awareness + learning + interaction**.

### The concept evolved in stages.

```text
Technology News
       ↓
Interactive Tech Reels
       ↓
Expert-led Spaces
       ↓
Student Connections
       ↓
Private Discussions
```

---

# 🧠 01 — Technology News

The first concept was straightforward:

### **What if engineering students had a dedicated place for technology news?**

CIE Daily could present:

* Technology developments
* Engineering news
* New applications
* Emerging technologies
* Indian technology updates
* Important global developments

The platform could also allow **CIE members to contribute and publish technology-focused articles**.

The objective was not simply to provide news.

It was to help students **understand what is changing around them**.

---

# 🎬 02 — Interactive Technology Reels

The idea then evolved further.

Students already consume large amounts of short-form content.

So the question became:

> **What if that same format could be used to learn about technology?**

CIE Daily introduces a short-form technology experience inspired by the simplicity and speed of Reels.

Instead of endlessly scrolling through entertainment:

### **Scroll through technology.**

Students can quickly discover:

* New technologies
* Interesting engineering developments
* Emerging applications
* Industry changes
* Short technology explanations

The goal is to make learning **visual, quick and engaging**.

---

# 🎙️ 03 — Spaces

### **The MVP learning initiative of CIE Daily**

Spaces were designed around a different idea:

> **Students should not only know about skills. They should have opportunities to learn them.**

Imagine a CIE member who is highly skilled in video editing.

They could create:

### 🎥 `7 Days of Video Editing`

A structured series where:

**Day 1 → Day 2 → Day 3 → ... → Day 7**

Students join a live Space for approximately **1–1.5 hours per session** and learn directly from someone with practical experience.

The concept can extend to:

```text
Video Editing
UI / UX
Programming
Artificial Intelligence
Design
Content Creation
Emerging Technologies
```

Students can participate beyond a single college, while the instructors and initiative are rooted in **CIE**.

The purpose is bigger than hosting another event.

It is about helping students:

**Explore skills → Discover interests → Learn practically → Build an advantage**

---

# 🔗 04 — Student Connections

Learning becomes more useful when people can share it.

CIE Daily therefore introduces a controlled student connection system using **unique connection codes**.

Instead of publicly exposing personal phone numbers, students can intentionally establish connections.

This creates the foundation for private communication.

---

# 💬 05 — Private 1-to-1 Chat

The chat system came from a simple real-world use case.

Imagine two students reading the same technology article.

One wants to tell a friend:

> *"Bro, look at this."*

They want to share it.

Discuss it.

Exchange opinions.

Continue the conversation.

That is where private 1-to-1 communication comes in.

### Content → Discussion → Connection

CIE Daily therefore becomes more than a place to consume information.

It becomes a place to **talk about what you learn**.

---

# ✨ Core Features

| Feature                   | Purpose                                        |
| ------------------------- | ---------------------------------------------- |
| 📰 **Technology Feed**    | Discover technology & engineering developments |
| 🎬 **Tech Reels**         | Short-form, interactive technology learning    |
| 🎙️ **Spaces**            | Expert-led live learning sessions              |
| 🔗 **Connections**        | Intentional peer discovery                     |
| 💬 **Private Chat**       | One-to-one discussions                         |
| 🛡️ **RBAC**              | Controlled student, creator & admin access     |
| ✍️ **Creator Publishing** | CIE-driven technology content                  |
| 👑 **Admin Controls**     | Platform governance and moderation             |

---

# 🏗️ Architecture

```text
                           ┌──────────────────────┐
                           │       CIE DAILY      │
                           └──────────┬───────────┘
                                      │
                                      ▼
                           ┌──────────────────────┐
                           │     FLUTTER APP      │
                           │       Dart           │
                           └──────────┬───────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
       ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
       │   RIVERPOD   │        │   GOROUTER   │        │   UI / UX    │
       │ State Layer  │        │ Navigation   │        │ Design System│
       └──────┬───────┘        └──────────────┘        └──────────────┘
              │
              ▼
       ┌─────────────────────────────────────────┐
       │              FIREBASE                   │
       ├─────────────────────────────────────────┤
       │ Authentication                          │
       │ Cloud Firestore                         │
       │ Security Rules                          │
       └────────────────────┬────────────────────┘
                            │
                            ▼
                    ┌─────────────────┐
                    │     LIVEKIT     │
                    │    WebRTC       │
                    │  Live Spaces    │
                    └─────────────────┘
```

---

# 🛠️ Tech Stack

### Frontend

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)

* Flutter
* Dart
* Riverpod
* GoRouter

### Backend & Infrastructure

![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)
![Firestore](https://img.shields.io/badge/Cloud%20Firestore-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)

* Firebase Authentication
* Cloud Firestore
* Firestore Security Rules

### Real-Time

![WebRTC](https://img.shields.io/badge/WebRTC-333333?style=for-the-badge\&logo=webrtc\&logoColor=white)

* LiveKit
* WebRTC
* Real-time audio Spaces

### Android

![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge\&logo=android\&logoColor=white)

* Android App Bundle
* Gradle Kotlin DSL
* Production application ID: `com.ciedaily.app`

---

# 📱 Application Structure

```text
CIE Daily
│
├── 🏠 Home
│   └── Technology Feed
│
├── 🔎 Discover
│   └── Interactive Tech Reels
│
├── 🎙️ Spaces
│   └── Live Learning Sessions
│
├── 💬 Chat
│   └── Private Conversations
│
└── 👤 Profile
    └── Identity + Connections
```

---

# 🔐 Role-Based Access

CIE Daily separates platform responsibilities through controlled roles.

### 👑 Main Admin

Responsible for:

* Platform governance
* Moderation
* Creator management
* Content control
* Space management
* Administrative permissions

### ✍️ Creator / CIE Expert

Responsible for:

* Publishing technology content
* Creating Articles and Reels
* Hosting learning Spaces
* Sharing domain expertise

### 🎓 Student

Can:

* Discover technology content
* Read Articles
* Watch Reels
* Join eligible Spaces
* Create student connections
* Use private chat

---

# 🧭 User Journey

```text
                DISCOVER
                   │
                   ▼
             TECHNOLOGY
                   │
          ┌────────┴────────┐
          ▼                 ▼
        ARTICLE            REEL
          │                 │
          └────────┬────────┘
                   ▼
                LEARN
                   │
                   ▼
                SPACE
                   │
                   ▼
               PRACTICE
                   │
                   ▼
               CONNECT
                   │
                   ▼
                DISCUSS
                   │
                   ▼
                  GROW
```

---

# 🔥 Development Journey

CIE Daily was developed as an iterative product rather than being built in one pass.

| Date          | Phase                                                   |
| ------------- | ------------------------------------------------------- |
| **04 Aug**    | 💡 Ideation, innovation & product vision                |
| **05 Aug**    | 🛠️ Flutter SDK & development environment               |
| **06 Aug**    | 🏗️ Architecture, feedback & planning                   |
| **07 Aug**    | 🚀 Main development begins                              |
| **08 Aug**    | 🎙️ Spaces + Admin / Creator system                     |
| **09–11 Aug** | 🎨 UI/UX, spacing, alignment, Reels & Spaces refinement |
| **12–14 Aug** | 💬 Connections + private 1-to-1 chat                    |
| **15 Aug**    | ✨ Production polish + Android preparation               |

---

# 🎯 Product Philosophy

CIE Daily is intentionally designed **not to be just another news application**.

The larger vision is:

```text
              DISCOVER
                  ↓
               LEARN
                  ↓
               EXPLORE
                  ↓
              CONNECT
                  ↓
              DISCUSS
                  ↓
                GROW
```

A student should be able to open CIE Daily and discover something they did not know before.

Then go one step further:

**Learn it.**

Then:

**Explore it.**

Then:

**Discuss it.**

And eventually:

**Build something with it.**

---

# 🗺️ Future Scope

The platform can evolve toward:

* 🤖 AI-assisted technology summaries
* 🔔 Technology & Space notifications
* 🎓 Larger CIE-led learning programs
* 🌍 Broader inter-college participation
* 🧠 Personalized technology discovery
* 🤝 More collaboration features
* 📚 Expanded skill-learning libraries
* 📈 Content and learning analytics

---

# 📦 Current Project Status

```text
✅ Product concept
✅ Flutter foundation
✅ Authentication
✅ Firestore architecture
✅ Technology feed
✅ Articles
✅ Interactive Reels
✅ Spaces
✅ Role-based access
✅ Student connections
✅ Private 1-to-1 chat
✅ UI/UX refinement
✅ Android release preparation
```

### Android

```text
Application ID
com.ciedaily.app
```

---

# 👨‍💻 Creator

<div align="center">

## Manas Vignesh Varma

**Creator & Developer — CIE Daily**

Designed, developed and evolved CIE Daily from an idea for technology awareness into an integrated platform for **technology discovery, interactive learning, skill development and student communication.**

</div>

---

# ⭐ The Idea

<div align="center">

### **Technology changes every day.**

### **Students should know about it.**

### **They should learn from it.**

### **They should grow with it.**

<br />

## **CIE Daily**

### *Discover. Learn. Explore. Discuss. Grow.*

</div>

---

## 📄 Project Documentation

The project documentation includes:

* Product Requirements Document (PRD)
* Development Record
* Development Evidence
* Technical Architecture
* Feature Requirements
* Product Evolution

---

<div align="center">

### Built with curiosity.

### Designed for learning.

### Made for the next generation of engineers.

**© 2026 CIE Daily**

</div>
