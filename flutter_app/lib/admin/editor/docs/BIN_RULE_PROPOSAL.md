# Proposed Firestore rule for the UI Editor's Deleted bin (NOT deployed)

The editor's Deleted bin saves to the `ui_bin` collection. On the server
that collection is covered by no rule yet, so Firestore denies it and the
editor keeps the bin on the phone only (offline copy) until a rule exists.

Ribon has said not to deploy this yet. When he OKs it, add this line next to
`match /ui_layouts/{id}` in the root `firestore.rules` and deploy it the
usual way:

```
    // The UI Editor's Deleted bin: admin-only, kept until restored.
    match /ui_bin/{id} { allow read, write: if isAdmin(); }
```

It was first added to `firestore.rules` in 52d36a20 and removed again (never
deployed) so the root file matches what is live.
