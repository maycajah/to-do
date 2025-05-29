# 📝 Decentralized To-Do List Smart Contract

A smart contract for managing a decentralized to-do list with task tracking, user statistics, and NFT-based achievement badges. Built using Clarity for the Stacks blockchain.

---

## 🚀 Features

* ✅ **Add, complete, update, and delete tasks**
* 🎯 **Track user statistics** (total, active, and completed tasks)
* 🏆 **Earn NFT badges** as achievements for task milestones
* 🔍 **Read-only views** for task details, user stats, and earned achievements
* 🔐 **Ownership-based access** — only the task creator can manage their tasks

---

## 🧱 Contract Components

### 🔧 Constants

* `contract-owner`: The contract deployer
* Error constants (`err-owner-only`, `err-task-not-found`, etc.) for handling validation and access control

### 📊 Data Variables

* `task-counter`: Unique task ID generator
* `badge-counter`: Unique NFT badge ID generator

### 🗂️ Maps

* `tasks`: Stores task data (title, description, timestamps, status)
* `user-stats`: Tracks total, completed, and active tasks per user
* `user-achievements`: Tracks which badges each user has earned

### 🏅 Non-Fungible Token

* `achievement-badge`: NFT representing task completion achievements

---

## 📥 Public Functions

| Function                                   | Description                                           |
| ------------------------------------------ | ----------------------------------------------------- |
| `add-task(title, description)`             | Adds a new task for the sender                        |
| `complete-task(task-id)`                   | Marks a task as completed and checks for badge awards |
| `delete-task(task-id)`                     | Deletes a task (only by owner)                        |
| `update-task(task-id, title, description)` | Updates title/description of an uncompleted task      |
| `task-exists(task-id, user)`               | Checks if a specific task exists for a user           |

---

## 👁️ Read-Only Functions

| Function                                  | Description                                      |
| ----------------------------------------- | ------------------------------------------------ |
| `get-task(task-id, owner)`                | Retrieves task details                           |
| `get-user-stats(user)`                    | Returns total, completed, and active task counts |
| `has-achievement(user, achievement-type)` | Checks if a user has earned a specific badge     |

---

## 🛠️ Private Functions

| Function                                       | Description                                             |
| ---------------------------------------------- | ------------------------------------------------------- |
| `get-next-task-id()`                           | Generates and returns the next unique task ID           |
| `get-next-badge-id()`                          | Generates and returns the next unique NFT badge ID      |
| `update-user-stats(user, is-add, is-complete)` | Updates user's task stats after add/complete/delete     |
| `check-and-award-achievements(user)`           | Checks milestone completions and mints NFTs if earned   |
| `award-badge(user, achievement-type)`          | Mints an NFT badge and stores it in `user-achievements` |

---

## 🏆 Badge System

Badges are earned as NFTs when users hit task completion milestones:

| Milestone | Achievement Type   | Description          |
| --------- | ------------------ | -------------------- |
| 1 task    | `first-task`       | First task completed |
| 10 tasks  | `task-master-10`   | Completed 10 tasks   |
| 50 tasks  | `task-champion-50` | Completed 50 tasks   |
| 100 tasks | `task-legend-100`  | Completed 100 tasks  |

---

## ⚠️ Error Codes

| Code   | Meaning                                     |
| ------ | ------------------------------------------- |
| `u100` | Only contract owner can perform this action |
| `u101` | Task not found                              |
| `u102` | Task already completed                      |
| `u103` | Unauthorized action                         |
| `u104` | Invalid task data                           |

---

## 📌 Notes

* All functions are scoped to the task owner (`tx-sender`)
* NFT badges are implemented using `define-non-fungible-token`
* `block-height` is used for timestamping task creation, completion, and badge earning
* Users can only manage (add/update/complete/delete) their own tasks

---

## 🛠️ Future Improvements

* Add support for task categories or tags
* Introduce due dates and reminders
* Enable badge viewing via external NFT platforms
* Role-based permissions for collaborative task lists

---

## 📄 License

This project is open-source and available under the [MIT License](https://opensource.org/licenses/MIT).