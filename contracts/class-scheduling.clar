;; Digital Public Recreation Center - Class Scheduling Contract
;; Handles fitness class bookings and instructor assignments

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-CLASS-NOT-FOUND (err u201))
(define-constant ERR-CLASS-FULL (err u202))
(define-constant ERR-ALREADY-BOOKED (err u203))
(define-constant ERR-BOOKING-NOT-FOUND (err u204))
(define-constant ERR-INVALID-TIME (err u205))
(define-constant ERR-INSTRUCTOR-NOT-AVAILABLE (err u206))
(define-constant ERR-INVALID-INPUT (err u207))
(define-constant ERR-CLASS-ALREADY-EXISTS (err u208))
(define-constant ERR-PAST-CLASS (err u209))

;; Class Types
(define-constant CLASS-YOGA u1)
(define-constant CLASS-CARDIO u2)
(define-constant CLASS-STRENGTH u3)
(define-constant CLASS-SWIMMING u4)
(define-constant CLASS-DANCE u5)
(define-constant CLASS-MARTIAL-ARTS u6)

;; Data Variables
(define-data-var next-class-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var total-classes uint u0)

;; Data Maps
(define-map classes
  { class-id: uint }
  {
    name: (string-ascii 50),
    instructor: principal,
    class-type: uint,
    start-time: uint,
    end-time: uint,
    max-capacity: uint,
    current-enrollment: uint,
    location: (string-ascii 50),
    description: (string-ascii 200),
    is-active: bool,
    price: uint
  }
)

(define-map class-bookings
  { booking-id: uint }
  {
    class-id: uint,
    member-principal: principal,
    booking-time: uint,
    is-confirmed: bool,
    is-attended: bool,
    payment-amount: uint
  }
)

(define-map member-class-bookings
  { member-principal: principal, class-id: uint }
  { booking-id: uint }
)

(define-map instructors
  { instructor-principal: principal }
  {
    name: (string-ascii 50),
    specialties: (list 5 uint),
    certification-date: uint,
    is-active: bool,
    hourly-rate: uint,
    total-classes-taught: uint
  }
)

(define-map class-waitlist
  { class-id: uint, position: uint }
  {
    member-principal: principal,
    join-time: uint
  }
)

(define-map class-ratings
  { class-id: uint, member-principal: principal }
  {
    rating: uint,
    comment: (string-ascii 200),
    rating-date: uint
  }
)

;; Authorization Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-instructor (instructor-principal principal))
  (match (map-get? instructors { instructor-principal: instructor-principal })
    instructor-data (get is-active instructor-data)
    false
  )
)

;; Helper Functions
(define-private (is-valid-class-type (class-type uint))
  (or
    (is-eq class-type CLASS-YOGA)
    (or
      (is-eq class-type CLASS-CARDIO)
      (or
        (is-eq class-type CLASS-STRENGTH)
        (or
          (is-eq class-type CLASS-SWIMMING)
          (or
            (is-eq class-type CLASS-DANCE)
            (is-eq class-type CLASS-MARTIAL-ARTS)
          )
        )
      )
    )
  )
)

(define-private (is-class-full (class-id uint))
  (match (map-get? classes { class-id: class-id })
    class-data (>= (get current-enrollment class-data) (get max-capacity class-data))
    true
  )
)

(define-private (has-member-booked-class (member-principal principal) (class-id uint))
  (is-some (map-get? member-class-bookings { member-principal: member-principal, class-id: class-id }))
)

;; Public Functions

;; Create a new fitness class
(define-public (create-class
  (name (string-ascii 50))
  (instructor principal)
  (class-type uint)
  (start-time uint)
  (end-time uint)
  (max-capacity uint)
  (location (string-ascii 50))
  (description (string-ascii 200))
  (price uint)
)
  (let
    (
      (class-id (var-get next-class-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-class-type class-type) ERR-INVALID-INPUT)
    (asserts! (> start-time current-time) ERR-INVALID-TIME)
    (asserts! (> end-time start-time) ERR-INVALID-TIME)
    (asserts! (> max-capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (is-instructor instructor) ERR-INSTRUCTOR-NOT-AVAILABLE)

    (map-set classes
      { class-id: class-id }
      {
        name: name,
        instructor: instructor,
        class-type: class-type,
        start-time: start-time,
        end-time: end-time,
        max-capacity: max-capacity,
        current-enrollment: u0,
        location: location,
        description: description,
        is-active: true,
        price: price
      }
    )

    (var-set next-class-id (+ class-id u1))
    (var-set total-classes (+ (var-get total-classes) u1))

    (ok class-id)
  )
)

;; Register as an instructor
(define-public (register-instructor
  (name (string-ascii 50))
  (specialties (list 5 uint))
  (hourly-rate uint)
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> hourly-rate u0) ERR-INVALID-INPUT)

    (map-set instructors
      { instructor-principal: tx-sender }
      {
        name: name,
        specialties: specialties,
        certification-date: current-time,
        is-active: true,
        hourly-rate: hourly-rate,
        total-classes-taught: u0
      }
    )

    (ok true)
  )
)

;; Book a class
(define-public (book-class (class-id uint))
  (let
    (
      (class-data (unwrap! (map-get? classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (booking-id (var-get next-booking-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (get is-active class-data) ERR-CLASS-NOT-FOUND)
    (asserts! (> (get start-time class-data) current-time) ERR-PAST-CLASS)
    (asserts! (not (has-member-booked-class tx-sender class-id)) ERR-ALREADY-BOOKED)
    (asserts! (not (is-class-full class-id)) ERR-CLASS-FULL)

    ;; Create booking
    (map-set class-bookings
      { booking-id: booking-id }
      {
        class-id: class-id,
        member-principal: tx-sender,
        booking-time: current-time,
        is-confirmed: true,
        is-attended: false,
        payment-amount: (get price class-data)
      }
    )

    ;; Map member to booking
    (map-set member-class-bookings
      { member-principal: tx-sender, class-id: class-id }
      { booking-id: booking-id }
    )

    ;; Update class enrollment
    (map-set classes
      { class-id: class-id }
      (merge class-data {
        current-enrollment: (+ (get current-enrollment class-data) u1)
      })
    )

    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id)
  )
)

;; Cancel a class booking
(define-public (cancel-booking (class-id uint))
  (let
    (
      (booking-data (unwrap! (map-get? member-class-bookings { member-principal: tx-sender, class-id: class-id }) ERR-BOOKING-NOT-FOUND))
      (class-data (unwrap! (map-get? classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (get start-time class-data) current-time) ERR-PAST-CLASS)

    ;; Remove booking
    (map-delete member-class-bookings { member-principal: tx-sender, class-id: class-id })

    ;; Update class enrollment
    (map-set classes
      { class-id: class-id }
      (merge class-data {
        current-enrollment: (- (get current-enrollment class-data) u1)
      })
    )

    (ok true)
  )
)

;; Mark attendance for a class
(define-public (mark-attendance (class-id uint) (member-principal principal))
  (let
    (
      (class-data (unwrap! (map-get? classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (booking-data (unwrap! (map-get? member-class-bookings { member-principal: member-principal, class-id: class-id }) ERR-BOOKING-NOT-FOUND))
      (booking-id (get booking-id booking-data))
      (booking-details (unwrap! (map-get? class-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND))
    )
    (asserts! (is-eq (get instructor class-data) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set class-bookings
      { booking-id: booking-id }
      (merge booking-details { is-attended: true })
    )

    (ok true)
  )
)

;; Rate a class
(define-public (rate-class
  (class-id uint)
  (rating uint)
  (comment (string-ascii 200))
)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (has-member-booked-class tx-sender class-id) ERR-BOOKING-NOT-FOUND)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-INPUT)

    (map-set class-ratings
      { class-id: class-id, member-principal: tx-sender }
      {
        rating: rating,
        comment: comment,
        rating-date: current-time
      }
    )

    (ok true)
  )
)

;; Join waitlist for full class
(define-public (join-waitlist (class-id uint))
  (let
    (
      (class-data (unwrap! (map-get? classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (position u1) ;; Simplified - in real implementation, calculate actual position
    )
    (asserts! (get is-active class-data) ERR-CLASS-NOT-FOUND)
    (asserts! (is-class-full class-id) ERR-INVALID-INPUT)
    (asserts! (not (has-member-booked-class tx-sender class-id)) ERR-ALREADY-BOOKED)

    (map-set class-waitlist
      { class-id: class-id, position: position }
      {
        member-principal: tx-sender,
        join-time: current-time
      }
    )

    (ok position)
  )
)

;; Admin function to cancel a class
(define-public (cancel-class (class-id uint))
  (let
    (
      (class-data (unwrap! (map-get? classes { class-id: class-id }) ERR-CLASS-NOT-FOUND))
    )
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)

    (map-set classes
      { class-id: class-id }
      (merge class-data { is-active: false })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get class information
(define-read-only (get-class (class-id uint))
  (map-get? classes { class-id: class-id })
)

;; Get member's booking for a class
(define-read-only (get-member-booking (member-principal principal) (class-id uint))
  (map-get? member-class-bookings { member-principal: member-principal, class-id: class-id })
)

;; Get instructor information
(define-read-only (get-instructor (instructor-principal principal))
  (map-get? instructors { instructor-principal: instructor-principal })
)

;; Check if class is available for booking
(define-read-only (is-class-available (class-id uint))
  (match (map-get? classes { class-id: class-id })
    class-data
      (let
        (
          (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        )
        (and
          (get is-active class-data)
          (> (get start-time class-data) current-time)
          (< (get current-enrollment class-data) (get max-capacity class-data))
        )
      )
    false
  )
)

;; Get class rating
(define-read-only (get-class-rating (class-id uint) (member-principal principal))
  (map-get? class-ratings { class-id: class-id, member-principal: member-principal })
)

;; Get total classes count
(define-read-only (get-total-classes)
  (var-get total-classes)
)

;; Get booking details
(define-read-only (get-booking (booking-id uint))
  (map-get? class-bookings { booking-id: booking-id })
)
