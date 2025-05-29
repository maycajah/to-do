;; Decentralized To-Do List Smart Contract
;; Features: Add, complete, delete tasks with NFT badge rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-task-not-found (err u101))
(define-constant err-task-already-completed (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-task (err u104))

;; Data Variables
(define-data-var task-counter uint u0)
(define-data-var badge-counter uint u0)

;; Data Maps
;; Store task details
(define-map tasks 
    { task-id: uint, owner: principal }
    { 
        title: (string-utf8 256),
        description: (string-utf8 1024),
        completed: bool,
        created-at: uint,
        completed-at: (optional uint)
    }
)

;; Track user's task count and completed count
(define-map user-stats
    principal
    {
        total-tasks: uint,
        completed-tasks: uint,
        active-tasks: uint
    }
)

;; NFT Badge definitions
(define-non-fungible-token achievement-badge uint)

;; Map to track which achievements a user has earned
(define-map user-achievements
    { user: principal, achievement-type: (string-ascii 50) }
    { earned: bool, earned-at: uint }
)

;; Helper Functions
(define-private (get-next-task-id)
    (let ((current-id (var-get task-counter)))
        (var-set task-counter (+ current-id u1))
        current-id
    )
)

(define-private (get-next-badge-id)
    (let ((current-id (var-get badge-counter)))
        (var-set badge-counter (+ current-id u1))
        current-id
    )
)

;; Read-only Functions
(define-read-only (get-task (task-id uint) (owner principal))
    (map-get? tasks { task-id: task-id, owner: owner })
)

(define-read-only (get-user-stats (user principal))
    (default-to 
        { total-tasks: u0, completed-tasks: u0, active-tasks: u0 }
        (map-get? user-stats user)
    )
)

(define-read-only (has-achievement (user principal) (achievement-type (string-ascii 50)))
    (default-to 
        { earned: false, earned-at: u0 }
        (map-get? user-achievements { user: user, achievement-type: achievement-type })
    )
)

;; Private Functions
(define-private (update-user-stats (user principal) (is-add bool) (is-complete bool))
    (let ((current-stats (get-user-stats user)))
        (if is-add
            ;; Adding a new task
            (map-set user-stats user {
                total-tasks: (+ (get total-tasks current-stats) u1),
                completed-tasks: (get completed-tasks current-stats),
                active-tasks: (+ (get active-tasks current-stats) u1)
            })
            (if is-complete
                ;; Completing a task
                (map-set user-stats user {
                    total-tasks: (get total-tasks current-stats),
                    completed-tasks: (+ (get completed-tasks current-stats) u1),
                    active-tasks: (- (get active-tasks current-stats) u1)
                })
                ;; Deleting a task
                (map-set user-stats user {
                    total-tasks: (get total-tasks current-stats),
                    completed-tasks: (get completed-tasks current-stats),
                    active-tasks: (- (get active-tasks current-stats) u1)
                })
            )
        )
    )
)

(define-private (check-and-award-achievements (user principal))
    (let (
        (stats (get-user-stats user))
        (completed (get completed-tasks stats))
    )
        ;; Check all achievements
        (begin
            ;; First task completed achievement
            (and (is-eq completed u1) 
                 (not (get earned (has-achievement user "first-task")))
                 (is-ok (award-badge user "first-task")))
            ;; 10 tasks completed achievement
            (and (>= completed u10) 
                 (not (get earned (has-achievement user "task-master-10")))
                 (is-ok (award-badge user "task-master-10")))
            ;; 50 tasks completed achievement
            (and (>= completed u50) 
                 (not (get earned (has-achievement user "task-champion-50")))
                 (is-ok (award-badge user "task-champion-50")))
            ;; 100 tasks completed achievement
            (and (>= completed u100) 
                 (not (get earned (has-achievement user "task-legend-100")))
                 (is-ok (award-badge user "task-legend-100")))
            true
        )
    )
)

(define-private (award-badge (user principal) (achievement-type (string-ascii 50)))
    (let ((badge-id (get-next-badge-id)))
        (map-set user-achievements 
            { user: user, achievement-type: achievement-type }
            { earned: true, earned-at: block-height }
        )
        (nft-mint? achievement-badge badge-id user)
    )
)

;; Public Functions
(define-public (add-task (title (string-utf8 256)) (description (string-utf8 1024)))
    (let (
        (task-id (get-next-task-id))
        (owner tx-sender)
    )
        (if (or (is-eq (len title) u0) (> (len title) u256) (> (len description) u1024))
            err-invalid-task
            (begin
                (map-set tasks 
                    { task-id: task-id, owner: owner }
                    {
                        title: title,
                        description: description,
                        completed: false,
                        created-at: block-height,
                        completed-at: none
                    }
                )
                (update-user-stats owner true false)
                (ok task-id)
            )
        )
    )
)

(define-public (complete-task (task-id uint))
    (let (
        (task-key { task-id: task-id, owner: tx-sender })
        (task (map-get? tasks task-key))
    )
        (match task
            task-data
            (if (get completed task-data)
                err-task-already-completed
                (begin
                    (map-set tasks task-key
                        (merge task-data {
                            completed: true,
                            completed-at: (some block-height)
                        })
                    )
                    (update-user-stats tx-sender false true)
                    (check-and-award-achievements tx-sender)
                    (ok true)
                )
            )
            err-task-not-found
        )
    )
)

(define-public (delete-task (task-id uint))
    (let (
        (task-key { task-id: task-id, owner: tx-sender })
        (task (map-get? tasks task-key))
    )
        (match task
            task-data
            (begin
                (map-delete tasks task-key)
                (if (not (get completed task-data))
                    (update-user-stats tx-sender false false)
                    true
                )
                (ok true)
            )
            err-task-not-found
        )
    )
)

;; Admin function to update task (optional)
(define-public (update-task (task-id uint) (title (string-utf8 256)) (description (string-utf8 1024)))
    (let (
        (task-key { task-id: task-id, owner: tx-sender })
        (task (map-get? tasks task-key))
    )
        (match task
            task-data
            (if (get completed task-data)
                err-task-already-completed
                (if (or (is-eq (len title) u0) (> (len title) u256) (> (len description) u1024))
                    err-invalid-task
                    (begin
                        (map-set tasks task-key
                            (merge task-data {
                                title: title,
                                description: description
                            })
                        )
                        (ok true)
                    )
                )
            )
            err-task-not-found
        )
    )
)

;; Simple function to check if a task exists for a user
(define-read-only (task-exists (task-id uint) (user principal))
    (is-some (map-get? tasks { task-id: task-id, owner: user }))
)