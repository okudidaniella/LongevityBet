
;; title: LongevityBet
;; version: 1.0.0
;; summary: Synthetic assets smart contract for life extension and anti-aging research investments
;; description: Allows users to mint/burn synthetic tokens backed by longevity research investments,
;;              track research outcomes, and distribute rewards based on research milestones

;; traits
(define-trait sip-010-trait
  (
    ;; Transfer from the caller to a new principal
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    ;; the human readable name of the token
    (get-name () (response (string-ascii 32) uint))
    ;; the ticker symbol, or empty if none
    (get-symbol () (response (string-ascii 32) uint))
    ;; the number of decimals used, e.g. 6 would mean 1_000_000 represents 1 token
    (get-decimals () (response uint uint))
    ;; the balance of the passed principal
    (get-balance (principal) (response uint uint))
    ;; the current total supply (which does not need to be a constant)
    (get-total-supply () (response uint uint))
    ;; an optional URI that represents metadata of this token
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; token definitions
(define-fungible-token longevity-token)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-research-not-found (err u104))
(define-constant err-research-already-exists (err u105))
(define-constant err-invalid-milestone (err u106))
(define-constant err-milestone-already-achieved (err u107))

;; Token metadata
(define-constant token-name "LongevityBet Token")
(define-constant token-symbol "LONG")
(define-constant token-decimals u6)
(define-constant token-uri u"https://longevitybet.io/metadata.json")

;; data vars
(define-data-var total-research-projects uint u0)
(define-data-var token-total-supply uint u0)
(define-data-var emergency-shutdown-active bool false)

;; data maps
;; Research project tracking
(define-map research-projects
  { project-id: uint }
  {
    name: (string-ascii 64),
    description: (string-utf8 256),
    target-amount: uint,
    current-funding: uint,
    milestone-count: uint,
    active: bool,
    creator: principal
  }
)

;; Research milestones
(define-map research-milestones
  { project-id: uint, milestone-id: uint }
  {
    description: (string-utf8 256),
    reward-percentage: uint,
    achieved: bool,
    achievement-block: (optional uint)
  }
)

;; User investments in research projects
(define-map user-investments
  { user: principal, project-id: uint }
  { amount: uint, tokens-minted: uint }
)

;; Token balances and allowances
(define-map token-balances principal uint)

;; public functions

;; SIP-010 compliance functions
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-not-token-owner)
    (asserts! (>= (ft-get-balance longevity-token from) amount) err-insufficient-balance)
    (try! (ft-transfer? longevity-token amount from to))
    (match memo to-print (print to-print) 0x)
    (ok true)
  )
)

(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance longevity-token user))
)

(define-read-only (get-total-supply)
  (ok (var-get token-total-supply))
)

(define-read-only (get-token-uri)
  (ok (some token-uri))
)

;; Core contract functions

;; Create a new research project
(define-public (create-research-project
  (name (string-ascii 64))
  (description (string-utf8 256))
  (target-amount uint)
  (milestone-descriptions (list 10 (string-utf8 256)))
  (milestone-rewards (list 10 uint)))
  (let
    (
      (project-id (+ (var-get total-research-projects) u1))
      (milestone-count (len milestone-descriptions))
    )
    (asserts! (> target-amount u0) err-invalid-amount)
    (asserts! (is-eq (len milestone-descriptions) (len milestone-rewards)) err-invalid-milestone)
    (asserts! (and (> milestone-count u0) (<= milestone-count u10)) err-invalid-milestone)

    ;; Create the research project
    (map-set research-projects
      { project-id: project-id }
      {
        name: name,
        description: description,
        target-amount: target-amount,
        current-funding: u0,
        milestone-count: milestone-count,
        active: true,
        creator: tx-sender
      }
    )

    ;; Create milestones
    (unwrap! (create-milestones project-id milestone-descriptions milestone-rewards u0) err-invalid-milestone)

    ;; Update total projects counter
    (var-set total-research-projects project-id)

    (print { action: "research-project-created", project-id: project-id, creator: tx-sender })
    (ok project-id)
  )
)

;; Invest in a research project and mint synthetic tokens
(define-public (invest-in-research (project-id uint) (stx-amount uint))
  (let
    (
      (project (unwrap! (map-get? research-projects { project-id: project-id }) err-research-not-found))
      (current-investment (default-to { amount: u0, tokens-minted: u0 }
                          (map-get? user-investments { user: tx-sender, project-id: project-id })))
      (tokens-to-mint (/ (* stx-amount u1000000) u1)) ;; 1:1 ratio with 6 decimals
    )
    (asserts! (get active project) err-research-not-found)
    (asserts! (> stx-amount u0) err-invalid-amount)
    (asserts! (not (var-get emergency-shutdown-active)) err-owner-only)

    ;; Transfer STX from user to contract
    (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))

    ;; Mint synthetic tokens to user
    (try! (ft-mint? longevity-token tokens-to-mint tx-sender))

    ;; Update project funding
    (map-set research-projects
      { project-id: project-id }
      (merge project { current-funding: (+ (get current-funding project) stx-amount) })
    )

    ;; Update user investment
    (map-set user-investments
      { user: tx-sender, project-id: project-id }
      {
        amount: (+ (get amount current-investment) stx-amount),
        tokens-minted: (+ (get tokens-minted current-investment) tokens-to-mint)
      }
    )

    ;; Update total supply
    (var-set token-total-supply (+ (var-get token-total-supply) tokens-to-mint))

    (print {
      action: "investment-made",
      project-id: project-id,
      investor: tx-sender,
      stx-amount: stx-amount,
      tokens-minted: tokens-to-mint
    })
    (ok tokens-to-mint)
  )
)

;; Mark a research milestone as achieved (only project creator)
(define-public (achieve-milestone (project-id uint) (milestone-id uint))
  (let
    (
      (project (unwrap! (map-get? research-projects { project-id: project-id }) err-research-not-found))
      (milestone (unwrap! (map-get? research-milestones { project-id: project-id, milestone-id: milestone-id }) err-invalid-milestone))
    )
    (asserts! (is-eq tx-sender (get creator project)) err-not-token-owner)
    (asserts! (not (get achieved milestone)) err-milestone-already-achieved)

    ;; Mark milestone as achieved
    (map-set research-milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone {
        achieved: true,
        achievement-block: (some block-height)
      })
    )

    (print {
      action: "milestone-achieved",
      project-id: project-id,
      milestone-id: milestone-id,
      block-height: block-height
    })
    (ok true)
  )
)

;; Burn tokens and claim proportional STX rewards
(define-public (burn-and-claim (project-id uint) (token-amount uint) (reward-percentage uint))
  (let
    (
      (project (unwrap! (map-get? research-projects { project-id: project-id }) err-research-not-found))
      (user-investment (unwrap! (map-get? user-investments { user: tx-sender, project-id: project-id }) err-not-token-owner))
      (user-share (/ (* token-amount u100) (get tokens-minted user-investment)))
      (project-funding (get current-funding project))
      (user-reward (/ (* project-funding reward-percentage user-share) u10000))
    )
    (asserts! (>= (ft-get-balance longevity-token tx-sender) token-amount) err-insufficient-balance)
    (asserts! (<= token-amount (get tokens-minted user-investment)) err-insufficient-balance)
    (asserts! (<= reward-percentage u100) err-invalid-amount)

    ;; Burn tokens
    (try! (ft-burn? longevity-token token-amount tx-sender))

    ;; Transfer STX reward to user (only if there's enough balance)
    (if (and (> user-reward u0) (>= (stx-get-balance (as-contract tx-sender)) user-reward))
      (try! (as-contract (stx-transfer? user-reward tx-sender tx-sender)))
      true
    )

    ;; Update user investment
    (map-set user-investments
      { user: tx-sender, project-id: project-id }
      (merge user-investment {
        tokens-minted: (- (get tokens-minted user-investment) token-amount)
      })
    )

    ;; Update total supply
    (var-set token-total-supply (- (var-get token-total-supply) token-amount))

    (print {
      action: "tokens-burned-reward-claimed",
      project-id: project-id,
      user: tx-sender,
      tokens-burned: token-amount,
      stx-reward: user-reward
    })
    (ok user-reward)
  )
)

;; Emergency shutdown (owner only)
(define-public (emergency-shutdown)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set emergency-shutdown-active true)
    (print { action: "emergency-shutdown-activated" })
    (ok true)
  )
)

;; read only functions

;; Get research project details
(define-read-only (get-research-project (project-id uint))
  (map-get? research-projects { project-id: project-id })
)

;; Get milestone details
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? research-milestones { project-id: project-id, milestone-id: milestone-id })
)

;; Get user investment in a project
(define-read-only (get-user-investment (user principal) (project-id uint))
  (map-get? user-investments { user: user, project-id: project-id })
)

;; Get total number of research projects
(define-read-only (get-total-projects)
  (var-get total-research-projects)
)

;; Get project funding progress
(define-read-only (get-project-funding-progress (project-id uint))
  (match (map-get? research-projects { project-id: project-id })
    project (/ (* (get current-funding project) u100) (get target-amount project))
    u0
  )
)

;; private functions

;; Create milestones for a research project
(define-private (create-milestones
  (project-id uint)
  (descriptions (list 10 (string-utf8 256)))
  (rewards (list 10 uint))
  (index uint))
  (let
    (
      (milestone-count (len descriptions))
    )
    (asserts! (is-eq (len descriptions) (len rewards)) (err err-invalid-milestone))
    (asserts! (and (> milestone-count u0) (<= milestone-count u10)) (err err-invalid-milestone))

    ;; Create milestones iteratively
    (ok (fold create-milestone-with-index
              descriptions
              {
                project-id: project-id,
                rewards: rewards,
                index: u0,
                success: true
              }))
  )
)

;; Helper function to create a single milestone with index
(define-private (create-milestone-with-index
  (description (string-utf8 256))
  (acc { project-id: uint, rewards: (list 10 uint), index: uint, success: bool }))
  (if (get success acc)
    (let
      (
        (current-index (get index acc))
        (rewards-list (get rewards acc))
        (reward (default-to u0 (element-at rewards-list current-index)))
      )
      (map-set research-milestones
        { project-id: (get project-id acc), milestone-id: (+ current-index u1) }
        {
          description: description,
          reward-percentage: reward,
          achieved: false,
          achievement-block: none
        }
      )
      {
        project-id: (get project-id acc),
        rewards: rewards-list,
        index: (+ current-index u1),
        success: true
      }
    )
    acc
  )
)


