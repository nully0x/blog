+++
title = "A note on code style"
date = "2026-03-07"
authors = ["nully0x"]
[taxonomies]
tags = ["code", "syle"]
+++

---

# Security vs UX

Most code style discussions focus on the surface: readability, maintainability, or performance. But there's an argument that shapes decisions the conflict between writing code that protects the system and code that serves the user.

A small example from a sign-in implementation illustrates this.

### The User-Focused Approach (Semantic Clarity)

When a user submits credentials, the server looks up the user by email. Two things can go wrong: the user doesn't exist, or the database throws an error. Clean, semantically correct code would handle them differently:

```typescript
if (!user) {
  // Client knows to check their spelling
  return new ApplicationError("Invalid email or password", 401)
}

if (user instanceof Error) {
  // Client knows the system is struggling
  return new ApplicationError("Internal server error", 500)
}

```

This is user-focused code. The client gets an accurate signal. A `401` means "check your credentials." A `500` means "something went wrong on our end, try again."

### The Security-Focused Approach (The Information Leak)

Security-focused code looks unintuitive based on UX. It intentionally collapses distinct failures into a single, vague response:

```typescript
if (user instanceof Error) {
  Logger.error(`Error fetching user during sign-in`, user)
  // Intentionally returning 401 instead of 500
  return new ApplicationError("Invalid email or password", 401)
}

if (!user) {
  return new ApplicationError("Invalid email or password", 401)
}

```

**Why?** Returning a `500` for a DB error leaks information. An attacker can observe: *"this email returns 401, that email returns 500."* From that difference, they can infer whether an account exists. This is **User Enumeration**.

### The Side Channel (Timing Attacks)

The tension goes deeper than status codes. Even if the response body is identical, the **time** it takes to process the request can leak the same information.

If a database lookup for a non-existent user returns in 10ms, but a `bcrypt` password comparison for an existing user takes 300ms, the attacker still wins. Security-focused code might introduce artificial delays to ensure every auth request takes the same amount of time. To a performance-focused dev, this looks like a bug. To a security focused dev, that just normal.

### The Broader Principle

Security-focused code often violates our intuitions about "good" code:

* **Generic messages** look like poor error handling.
* **Uniform response times** look like performance regressions.
* **Redundant checks** look like over-engineering.

Neither is wrong. The problem is when a codebase doesn't document a given piece of code to which it focuses on. A dev seeing the collapsed `401` without context will flag it as a bug and they'd be right, by the normal rules.

### Which should you use?

When security shapes a code decision, make it visible. The comment isn't for the compiler; it's for the future version of yourself who will look at this and think "this looks wrong."

Security-focused code and user-focused code can coexist, but they need to be legible to each other. The style isn't arbitrary. The master it serves should be declared.


