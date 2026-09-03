CREATE TABLE IF NOT EXISTS app.uploaded_asset (
  content_hash varchar(66) PRIMARY KEY,
  mime_type varchar(32) NOT NULL,
  byte_size integer NOT NULL CHECK (byte_size > 0 AND byte_size <= 2097152),
  storage_key text NOT NULL UNIQUE,
  original_name text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app.contest_metadata (
  metadata_hash varchar(66) PRIMARY KEY,
  metadata_uri text NOT NULL UNIQUE,
  metadata_json jsonb NOT NULL,
  creator_address varchar(42) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS contest_metadata_creator_idx
  ON app.contest_metadata (creator_address, created_at DESC);
