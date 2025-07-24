;; Digital Public Recreation Center - Equipment Maintenance Contract
;; Coordinates exercise machine repairs and cleaning

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-EQUIPMENT-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STATUS (err u302))
(define-constant ERR-MAINTENANCE-NOT-FOUND (err u303))
(define-constant ERR-INVALID-INPUT (err u304))
(define-constant ERR-EQUIPMENT-EXISTS (err u305))
(define-constant ERR-INVALID-PRIORITY (err u306))

;; Equipment Status
(define-constant STATUS-OPERATIONAL u1)
(define-constant STATUS-MAINTENANCE u2)
(define-constant STATUS-OUT-OF-ORDER u3)
(define-constant STATUS-RETIRED u4)

;; Maintenance Priority
(define-constant PRIORITY-LOW u1)
(define-constant PRIORITY-MEDIUM u2)
(define-constant PRIORITY-HIGH u3)
(define-constant PRIORITY-CRITICAL u4)

;; Equipment Categories
(define-constant CATEGORY-CARDIO u1)
(define-constant CATEGORY-STRENGTH u2)
(define-constant CATEGORY-FREE-WEIGHTS u3)
(define-constant CATEGORY-POOL u4)
(define-constant CATEGORY-COURT u5)

;; Data Variables
(define-data-var next-equipment-id uint u1)
(define-data-var next-maintenance-id uint u1)
(define-data-var total-equipment uint u0)

;; Data Maps
(define-map equipment
  { equipment-id: uint }
  {
    name: (string-ascii 50),
    category: uint,
    model: (string-ascii 50),
    serial-number: (string-ascii 50),
    purchase-date: uint,
    warranty-expiration: uint,
    location: (string-ascii 50),
    status: uint,
    last-maintenance: uint,
    next-maintenance: uint,
    total-usage-hours: uint,
    maintenance-cost: uint
  }
)

(define-map maintenance-records
  { maintenance-id: uint }
  {
    equipment-id: uint,
    maintenance-type: (string-ascii 50),
    description: (string-ascii 200),
    technician: principal,
    scheduled-date: uint,
    completed-date: (optional uint),
    cost: uint,
    priority: uint,
    is-completed: bool,
    parts-replaced: (string-ascii 200)
  }
)

(define-map equipment-usage
  { equipment-id: uint, date: uint }
  {
    usage-hours: uint,
    user-count: uint,
    issues-reported: uint
  }
)

(define-map maintenance-technicians
  { technician-principal: principal }
  {
    name: (string-ascii 50),
    specialties: (list 5 uint),
    certification-level: uint,
    is-active: bool,
    total-repairs: uint
  }
)

(define-map equipment-issues
  { equipment-id: uint, issue-id: uint }
  {
    reporter: principal,
    description: (string-ascii 200),
    severity: uint,
    report-date: uint,
    is-resolved: bool,
    resolution-notes: (string-ascii 200)
  }
)

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-technician (technician-principal principal))
  (match (map-get? maintenance-technicians { technician-principal: technician-principal })
    tech-data (get is-active tech-data)
    false
  )
)

;; Helper Functions
(define-private (is-valid-status (status uint))
  (or
    (is-eq status STATUS-OPERATIONAL)
    (or
      (is-eq status STATUS-MAINTENANCE)
      (or
        (is-eq status STATUS-OUT-OF-ORDER)
        (is-eq status STATUS-RETIRED)
      )
    )
  )
)

(define-private (is-valid-priority (priority uint))
  (or
    (is-eq priority PRIORITY-LOW)
    (or
      (is-eq priority PRIORITY-MEDIUM)
      (or
        (is-eq priority PRIORITY-HIGH)
        (is-eq priority PRIORITY-CRITICAL)
      )
    )
  )
)

(define-private (is-valid-category (category uint))
  (or
    (is-eq category CATEGORY-CARDIO)
    (or
      (is-eq category CATEGORY-STRENGTH)
      (or
        (is-eq category CATEGORY-FREE-WEIGHTS)
        (or
          (is-eq category CATEGORY-POOL)
          (is-eq category CATEGORY-COURT)
        )
      )
    )
  )
)

(define-private (calculate-next-maintenance (last-maintenance uint) (category uint))
  (let
    (
      (maintenance-interval
        (if (is-eq category CATEGORY-CARDIO)
          u2592000  ;; 30 days for cardio equipment
          (if (is-eq category CATEGORY-POOL)
            u604800   ;; 7 days for pool equipment
            u5184000  ;; 60 days for other equipment
          )
        )
      )
    )
    (+ last-maintenance maintenance-interval)
  )
)

;; Public Functions

;; Add new equipment
(define-public (add-equipment
  (name (string-ascii 50))
  (category uint)
  (model (string-ascii 50))
  (serial-number (string-ascii 50))
  (location (string-ascii 50))
  (warranty-months uint)
)
  (let
    (
      (equipment-id (var-get next-equipment-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (warranty-expiration (+ current-time (* warranty-months u2592000))) ;; months to seconds
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-category category) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len serial-number) u0) ERR-INVALID-INPUT)

    (map-set equipment
      { equipment-id: equipment-id }
      {
        name: name,
        category: category,
        model: model,
        serial-number: serial-number,
        purchase-date: current-time,
        warranty-expiration: warranty-expiration,
        location: location,
        status: STATUS-OPERATIONAL,
        last-maintenance: current-time,
        next-maintenance: (calculate-next-maintenance current-time category),
        total-usage-hours: u0,
        maintenance-cost: u0
      }
    )

    (var-set next-equipment-id (+ equipment-id u1))
    (var-set total-equipment (+ (var-get total-equipment) u1))

    (ok equipment-id)
  )
)

;; Register maintenance technician
(define-public (register-technician
  (name (string-ascii 50))
  (specialties (list 5 uint))
  (certification-level uint)
)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= certification-level u1) (<= certification-level u5)) ERR-INVALID-INPUT)

    (map-set maintenance-technicians
      { technician-principal: tx-sender }
      {
        name: name,
        specialties: specialties,
        certification-level: certification-level,
        is-active: true,
        total-repairs: u0
      }
    )

    (ok true)
  )
)

;; Schedule maintenance
(define-public (schedule-maintenance
  (equipment-id uint)
  (maintenance-type (string-ascii 50))
  (description (string-ascii 200))
  (scheduled-date uint)
  (priority uint)
  (estimated-cost uint)
)
  (let
    (
      (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
      (maintenance-id (var-get next-maintenance-id))
    )
    (asserts! (or (is-contract-owner) (is-technician tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-priority priority) ERR-INVALID-PRIORITY)
    (asserts! (> (len maintenance-type) u0) ERR-INVALID-INPUT)

    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      {
        equipment-id: equipment-id,
        maintenance-type: maintenance-type,
        description: description,
        technician: tx-sender,
        scheduled-date: scheduled-date,
        completed-date: none,
        cost: estimated-cost,
        priority: priority,
        is-completed: false,
        parts-replaced: ""
      }
    )

    ;; Update equipment status if high priority
    (if (>= priority PRIORITY-HIGH)
      (map-set equipment
        { equipment-id: equipment-id }
        (merge equipment-data { status: STATUS-MAINTENANCE })
      )
      true
    )

    (var-set next-maintenance-id (+ maintenance-id u1))
    (ok maintenance-id)
  )
)

;; Complete maintenance
(define-public (complete-maintenance
  (maintenance-id uint)
  (actual-cost uint)
  (parts-replaced (string-ascii 200))
)
  (let
    (
      (maintenance-data (unwrap! (map-get? maintenance-records { maintenance-id: maintenance-id }) ERR-MAINTENANCE-NOT-FOUND))
      (equipment-data (unwrap! (map-get? equipment { equipment-id: (get equipment-id maintenance-data) }) ERR-EQUIPMENT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq (get technician maintenance-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-completed maintenance-data)) ERR-INVALID-INPUT)

    ;; Update maintenance record
    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      (merge maintenance-data {
        completed-date: (some current-time),
        cost: actual-cost,
        is-completed: true,
        parts-replaced: parts-replaced
      })
    )

    ;; Update equipment
    (map-set equipment
      { equipment-id: (get equipment-id maintenance-data) }
      (merge equipment-data {
        status: STATUS-OPERATIONAL,
        last-maintenance: current-time,
        next-maintenance: (calculate-next-maintenance current-time (get category equipment-data)),
        maintenance-cost: (+ (get maintenance-cost equipment-data) actual-cost)
      })
    )

    ;; Update technician stats
    (match (map-get? maintenance-technicians { technician-principal: tx-sender })
      tech-data
        (map-set maintenance-technicians
          { technician-principal: tx-sender }
          (merge tech-data {
            total-repairs: (+ (get total-repairs tech-data) u1)
          })
        )
      false
    )

    (ok true)
  )
)

;; Report equipment issue
(define-public (report-issue
  (equipment-id uint)
  (description (string-ascii 200))
  (severity uint)
)
  (let
    (
      (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (issue-id u1) ;; Simplified - in real implementation, track issue IDs properly
    )
    (asserts! (and (>= severity u1) (<= severity u5)) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    (map-set equipment-issues
      { equipment-id: equipment-id, issue-id: issue-id }
      {
        reporter: tx-sender,
        description: description,
        severity: severity,
        report-date: current-time,
        is-resolved: false,
        resolution-notes: ""
      }
    )

    ;; Update equipment status if critical issue
    (if (>= severity u4)
      (map-set equipment
        { equipment-id: equipment-id }
        (merge equipment-data { status: STATUS-OUT-OF-ORDER })
      )
      true
    )

    (ok issue-id)
  )
)

;; Update equipment status
(define-public (update-equipment-status (equipment-id uint) (new-status uint))
  (let
    (
      (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
    )
    (asserts! (or (is-contract-owner) (is-technician tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-status new-status) ERR-INVALID-STATUS)

    (map-set equipment
      { equipment-id: equipment-id }
      (merge equipment-data { status: new-status })
    )

    (ok true)
  )
)

;; Record equipment usage
(define-public (record-usage
  (equipment-id uint)
  (usage-hours uint)
  (user-count uint)
)
  (let
    (
      (equipment-data (unwrap! (map-get? equipment { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
      (current-date (/ (unwrap-panic (get-block-info? time (- block-height u1))) u86400)) ;; Convert to days
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> usage-hours u0) ERR-INVALID-INPUT)

    ;; Record daily usage
    (map-set equipment-usage
      { equipment-id: equipment-id, date: current-date }
      {
        usage-hours: usage-hours,
        user-count: user-count,
        issues-reported: u0
      }
    )

    ;; Update total usage hours
    (map-set equipment
      { equipment-id: equipment-id }
      (merge equipment-data {
        total-usage-hours: (+ (get total-usage-hours equipment-data) usage-hours)
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get equipment information
(define-read-only (get-equipment (equipment-id uint))
  (map-get? equipment { equipment-id: equipment-id })
)

;; Get maintenance record
(define-read-only (get-maintenance-record (maintenance-id uint))
  (map-get? maintenance-records { maintenance-id: maintenance-id })
)

;; Get technician information
(define-read-only (get-technician (technician-principal principal))
  (map-get? maintenance-technicians { technician-principal: technician-principal })
)

;; Check if equipment needs maintenance
(define-read-only (needs-maintenance (equipment-id uint))
  (match (map-get? equipment { equipment-id: equipment-id })
    equipment-data
      (let
        (
          (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        )
        (>= current-time (get next-maintenance equipment-data))
      )
    false
  )
)

;; Get equipment by status
(define-read-only (get-equipment-status (equipment-id uint))
  (match (map-get? equipment { equipment-id: equipment-id })
    equipment-data (some (get status equipment-data))
    none
  )
)

;; Get equipment usage for date
(define-read-only (get-usage (equipment-id uint) (date uint))
  (map-get? equipment-usage { equipment-id: equipment-id, date: date })
)

;; Get equipment issue
(define-read-only (get-issue (equipment-id uint) (issue-id uint))
  (map-get? equipment-issues { equipment-id: equipment-id, issue-id: issue-id })
)

;; Get total equipment count
(define-read-only (get-total-equipment)
  (var-get total-equipment)
)
