# Luma export format (`.luma`)

Luma backup files are UTF-8 JSON with extension **`.luma`**. The canonical filename is:

`luma-backup-YYYY-MM-DD.luma`

where `YYYY-MM-DD` is the UTC calendar date of `meta.exported_at`.

## Top-level structure

### Unencrypted export

```json
{
  "meta": { ... },
  "data": {
    "periods": [ ... ],
    "day_entries": [ ... ]
  }
}
```

- **`meta`** — always present (see below).
- **`data`** — object holding export payload. Keys inside `data` are omitted when there is nothing to export (e.g. periods-only backups omit `day_entries`).

### Encrypted export

The file is still JSON. The plaintext document above is encrypted; the file contains:

```json
{
  "meta": { ... },
  "payload": "<base64>"
}
```

- **`meta`** — same shape as in the plaintext export (so readers can inspect version and flags without the password).
- **`payload`** — base64 encoding of the binary ciphertext (see [Encryption](#encryption)).

The inner plaintext (before encryption) is exactly the unencrypted JSON document: `meta` plus `data`.

## Field naming

All JSON keys use **snake_case**.

## Dates and times

`start_utc`, `end_utc`, and `date_utc` are **ISO-8601** strings in **UTC** (e.g. `2024-05-01T00:00:00.000Z`).

## Null handling

Optional fields are **omitted** from JSON when `null` (not serialized as `null`).

## `meta` object

| Field | Type | Description |
| ----- | ---- | ----------- |
| `format_version` | int | Export container version. Breaking changes bump this. Current: `1`. |
| `schema_version` | int | On-disk Drift schema the export was built from (matches app migrations). |
| `app_version` | string | App build label (e.g. `1.0.0+1`). |
| `exported_at` | string | UTC timestamp when the export was created. |
| `encrypted` | bool | `true` if the file uses the encrypted envelope (`payload`); `false` for plaintext `data`. |
| `content_types` | array of string | What categories are included, e.g. `periods`, `symptoms`, `notes`. |

## `data.periods`

Ordered by `start_utc` ascending. Each element:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `ref_id` | int | yes | **File-local** sequence `1..n` for this export only. Not the database primary key. |
| `start_utc` | string | yes | Period start instant (UTC ISO-8601). |
| `end_utc` | string | no | Period end instant, omitted when absent. |

## `data.day_entries`

Ordered by `date_utc` ascending. Each element:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `period_ref_id` | int | yes | Links to `periods[].ref_id` in this file. |
| `date_utc` | string | yes | Calendar day in UTC (ISO-8601). |
| `flow_intensity` | int | no | Flow / bleeding intensity when exported. |
| `pain_score` | int | no | Pain score when exported. |
| `mood` | int | no | Mood code when exported. |
| `notes` | string | no | Free-text notes when exported. |

Symptom fields are omitted when not included in the export options.

### `ref_id` semantics

`ref_id` and `period_ref_id` exist so imports can relate day rows to periods **inside the file** without exposing or preserving original SQLite `id` values.

## Encryption

When `meta.encrypted` is `true`:

1. The **plaintext** is the full unencrypted JSON UTF-8 document (`meta` + `data`).
2. Plaintext is encrypted with **AES-256-GCM**.
3. A 256-bit key is derived with **Argon2id** from the user password and a random salt.

### Binary layout of decoded `payload` (before base64)

After base64-decoding `payload`, the blob is:

| Segment | Length | Description |
| ------- | ------ | ----------- |
| Salt | 16 bytes | Argon2id salt / nonce input. |
| Nonce | 12 bytes | AES-GCM nonce. |
| Ciphertext | variable | AES-GCM ciphertext. |
| MAC | 16 bytes | AES-GCM authentication tag. |

Argon2id parameters (fixed for this format):

- `parallelism`: 2  
- `memory`: 19456 (KiB blocks)  
- `iterations`: 2  
- `hashLength`: 32  

Wrong passwords fail decryption with an authentication error (GCM tag mismatch), not silent corruption.

## Version compatibility

- **`format_version`** — increment when the file envelope or encryption layout changes in a breaking way.
- **`schema_version`** — tracks the semantic shape of period/day data; importers can use it alongside `format_version` to migrate or reject unsupported combinations.

## Example (truncated, unencrypted)

```json
{
  "meta": {
    "format_version": 1,
    "schema_version": 3,
    "app_version": "1.0.0+1",
    "exported_at": "2026-04-06T12:00:00.000Z",
    "encrypted": false,
    "content_types": ["periods", "symptoms", "notes"]
  },
  "data": {
    "periods": [
      {
        "ref_id": 1,
        "start_utc": "2024-05-01T00:00:00.000Z",
        "end_utc": "2024-05-04T00:00:00.000Z"
      }
    ],
    "day_entries": [
      {
        "period_ref_id": 1,
        "date_utc": "2024-05-02T00:00:00.000Z",
        "flow_intensity": 2,
        "pain_score": 1
      }
    ]
  }
}
```
