;; Invoice Factoring Platform Contract
;; Enables businesses to tokenize invoices and sell to investors

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-invoice-expired (err u106))
(define-constant err-invoice-paid (err u107))

;; Data Variables
(define-data-var next-invoice-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% fee (250 basis points)

;; Data Maps
(define-map invoices
  { invoice-id: uint }
  {
    issuer: principal,
    debtor: principal,
    amount: uint,
    discount-rate: uint,
    due-date: uint,
    created-at: uint,
    status: (string-ascii 20),
    buyer: (optional principal),
    purchase-price: uint
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

;; Read-only functions
(define-read-only (get-invoice (invoice-id uint))
  (map-get? invoices { invoice-id: invoice-id })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (get-next-invoice-id)
  (var-get next-invoice-id)
)

(define-read-only (calculate-purchase-price (amount uint) (discount-rate uint))
  (let ((discount-amount (/ (* amount discount-rate) u10000)))
    (- amount discount-amount)
  )
)

;; Public functions
(define-public (create-invoice (debtor principal) (amount uint) (discount-rate uint) (due-date uint))
  (let ((invoice-id (var-get next-invoice-id)))
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= discount-rate u5000) err-invalid-amount) ;; Max 50% discount
    (asserts! (> due-date stacks-block-height) err-invoice-expired)
    
    (map-set invoices
      { invoice-id: invoice-id }
      {
        issuer: tx-sender,
        debtor: debtor,
        amount: amount,
        discount-rate: discount-rate,
        due-date: due-date,
        created-at: stacks-block-height,
        status: "active",
        buyer: none,
        purchase-price: u0
      }
    )
    
    (var-set next-invoice-id (+ invoice-id u1))
    (ok invoice-id)
  )
)

(define-public (purchase-invoice (invoice-id uint))
  (let ((invoice-data (unwrap! (get-invoice invoice-id) err-not-found))
        (purchase-price (calculate-purchase-price (get amount invoice-data) (get discount-rate invoice-data)))
        (platform-fee (/ (* purchase-price (var-get platform-fee-rate)) u10000))
        (issuer-payment (- purchase-price platform-fee))
        (buyer-balance (get-user-balance tx-sender)))
    
    (asserts! (is-eq (get status invoice-data) "active") err-unauthorized)
    (asserts! (> (get due-date invoice-data) stacks-block-height) err-invoice-expired)
    (asserts! (>= buyer-balance purchase-price) err-insufficient-funds)
    
    ;; Update buyer balance
    (map-set user-balances
      { user: tx-sender }
      { balance: (- buyer-balance purchase-price) }
    )
    
    ;; Update issuer balance
    (map-set user-balances
      { user: (get issuer invoice-data) }
      { balance: (+ (get-user-balance (get issuer invoice-data)) issuer-payment) }
    )
    
    ;; Update contract owner balance (platform fee)
    (map-set user-balances
      { user: contract-owner }
      { balance: (+ (get-user-balance contract-owner) platform-fee) }
    )
    
    ;; Update invoice status
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice-data {
        status: "sold",
        buyer: (some tx-sender),
        purchase-price: purchase-price
      })
    )
    
    (ok purchase-price)
  )
)

(define-public (pay-invoice (invoice-id uint))
  (let ((invoice-data (unwrap! (get-invoice invoice-id) err-not-found)))
    (asserts! (is-eq tx-sender (get debtor invoice-data)) err-unauthorized)
    (asserts! (is-eq (get status invoice-data) "sold") err-unauthorized)
    
    ;; Update invoice buyer balance
    (match (get buyer invoice-data)
      buyer-principal (map-set user-balances
        { user: buyer-principal }
        { balance: (+ (get-user-balance buyer-principal) (get amount invoice-data)) }
      )
      false
    )
    
    ;; Update invoice status
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice-data { status: "paid" })
    )
    
    (ok (get amount invoice-data))
  )
)

(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ (get-user-balance tx-sender) amount) }
    )
    (ok amount)
  )
)

(define-public (withdraw (amount uint))
  (let ((current-balance (get-user-balance tx-sender)))
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= current-balance amount) err-insufficient-funds)
    
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance amount) }
    )
    (ok amount)
  )
)

;; Admin functions
(define-public (set-platform-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u1000) err-invalid-amount) ;; Max 10% fee
    (var-set platform-fee-rate new-rate)
    (ok new-rate)
  )
)