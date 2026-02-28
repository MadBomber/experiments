# Implementation Plan: [Feature Name]

**Status:** [Draft / Approved / In Progress / Complete]
**Architect:** [Agent Name]
**Date:** [YYYY-MM-DD]

## 1. Executive Summary
*Briefly describe what we are building and why (Job to be Done).*

## 2. Technical Decisions (Architectural Record)
- **Database:** [e.g., New table `comments` with JSONB column for metadata]
- **Frontend:** [e.g., Turbo Frame for inline editing]
- **Logic:** [e.g., `Comments::Create` Interaction]

## 3. Schema Changes

```ruby
# Migration Plan
create_table :comments do |t|
  t.references :user, foreign_key: true, null: false
  t.references :post, foreign_key: true, null: false
  t.text :body, null: false
  t.timestamps
end
```

## 4. Step-by-Step Implementation

### Phase 1: Foundation (Models & DB)
- [ ] **Step 1.1:** Generate migration for `comments`.
    - *Verification:* `rails db:migrate` runs cleanly.
- [ ] **Step 1.2:** Create `Comment` model with validations and associations.
    - *Test:* Unit test for associations and validations.

### Phase 2: Core Logic (Backend)
- [ ] **Step 2.1:** Create `Comments::Create` interaction/service.
    - *Test:* Unit test handling valid/invalid inputs.
- [ ] **Step 2.2:** Add policies (Pundit) for creation.

### Phase 3: Interface (Frontend/API)
- [ ] **Step 3.1:** Add Controller `CommentsController#create`.
    - *Test:* Request spec (POST /comments).
- [ ] **Step 3.2:** Implement View (Turbo Frame) or JSON response.
    - *Test:* System spec (User clicks reply, types, sees comment).

## 5. Definition of Done (Auditor Checklist)
- [ ] All tests pass (Unit + System).
- [ ] Rubocop is clean.
- [ ] Brakeman shows no new warnings.
- [ ] N+1 queries checked.
