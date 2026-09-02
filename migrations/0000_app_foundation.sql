CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS chain_projection;

DO $$ BEGIN
  CREATE TYPE comment_status AS ENUM ('ACTIVE', 'AUTHOR_DELETED', 'MOD_HIDDEN');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE position_side AS ENUM ('A', 'B', 'BOTH', 'NONE', 'UNVERIFIED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS app.wallet_nonce (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_id integer NOT NULL,
  address varchar(42) NOT NULL,
  nonce_hash varchar(66) NOT NULL,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS wallet_nonce_active_unique
  ON app.wallet_nonce (chain_id, address, nonce_hash);

CREATE TABLE IF NOT EXISTS app.wallet_session (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_id integer NOT NULL,
  address varchar(42) NOT NULL,
  token_hash varchar(66) NOT NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS wallet_session_address_idx
  ON app.wallet_session (chain_id, address);

CREATE TABLE IF NOT EXISTS app.comment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_id integer NOT NULL,
  contest_id varchar(66) NOT NULL,
  market_vault varchar(42) NOT NULL,
  market_version integer NOT NULL,
  author_address varchar(42) NOT NULL,
  root_comment_id uuid,
  parent_comment_id uuid,
  reply_to_comment_id uuid,
  body text NOT NULL,
  body_normalized_hash varchar(66) NOT NULL,
  status comment_status NOT NULL DEFAULT 'ACTIVE',
  position_side_at_post position_side NOT NULL DEFAULT 'UNVERIFIED',
  position_block_number bigint,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX IF NOT EXISTS comment_contest_live_idx
  ON app.comment (chain_id, contest_id, created_at DESC);
CREATE INDEX IF NOT EXISTS comment_root_idx
  ON app.comment (root_comment_id, created_at ASC);

CREATE TABLE IF NOT EXISTS app.comment_reaction (
  chain_id integer NOT NULL,
  comment_id uuid NOT NULL,
  user_address varchar(42) NOT NULL,
  type varchar(16) NOT NULL DEFAULT 'LIKE',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (chain_id, comment_id, user_address, type)
);

CREATE TABLE IF NOT EXISTS app.outbox_event (
  sequence bigserial PRIMARY KEY,
  event_id uuid NOT NULL DEFAULT gen_random_uuid(),
  chain_id integer NOT NULL,
  aggregate_type varchar(32) NOT NULL,
  aggregate_id uuid NOT NULL,
  event_type varchar(64) NOT NULL,
  schema_version integer NOT NULL DEFAULT 1,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS outbox_event_id_unique
  ON app.outbox_event (event_id);
CREATE INDEX IF NOT EXISTS outbox_unpublished_idx
  ON app.outbox_event (published_at, sequence);
