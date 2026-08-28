# Local-first, Android-only, single user

Memova is scoped to a single user on Android with no cloud backend: no accounts, no sync, no network dependency. This is a deliberate boundary — adding sync later means introducing an identity model and backend, which would be a new ADR. The architecture keeps data access behind a repository seam so that future change stays contained, but there is no plan to build it.
