ALTER TABLE app.uploaded_asset
  ADD COLUMN IF NOT EXISTS uploader_address varchar(42);

ALTER TABLE app.comment
  ADD COLUMN IF NOT EXISTS challenge_id uuid;

CREATE TABLE IF NOT EXISTS app.write_rate_limit (
  key_hash varchar(66) NOT NULL,
  bucket_start bigint NOT NULL,
  request_count integer NOT NULL DEFAULT 1,
  PRIMARY KEY (key_hash, bucket_start)
);
CREATE INDEX IF NOT EXISTS write_rate_limit_expiry_idx
  ON app.write_rate_limit (bucket_start);

CREATE UNIQUE INDEX IF NOT EXISTS comment_challenge_unique
  ON app.comment (challenge_id) WHERE challenge_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS wallet_nonce_expiry_idx
  ON app.wallet_nonce (expires_at);
CREATE UNIQUE INDEX IF NOT EXISTS wallet_session_token_unique
  ON app.wallet_session (token_hash);
CREATE INDEX IF NOT EXISTS wallet_session_expiry_idx
  ON app.wallet_session (expires_at);
CREATE INDEX IF NOT EXISTS uploaded_asset_uploader_created_idx
  ON app.uploaded_asset (uploader_address, created_at DESC)
  WHERE uploader_address IS NOT NULL;

DO $$ BEGIN
  ALTER TABLE app.comment
    ADD CONSTRAINT comment_parent_fk FOREIGN KEY (parent_comment_id)
    REFERENCES app.comment(id) ON DELETE SET NULL NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE app.comment
    ADD CONSTRAINT comment_root_fk FOREIGN KEY (root_comment_id)
    REFERENCES app.comment(id) ON DELETE SET NULL NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE app.comment
    ADD CONSTRAINT comment_reply_to_fk FOREIGN KEY (reply_to_comment_id)
    REFERENCES app.comment(id) ON DELETE SET NULL NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE app.comment_reaction
    ADD CONSTRAINT comment_reaction_comment_fk FOREIGN KEY (comment_id)
    REFERENCES app.comment(id) ON DELETE CASCADE NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  IF to_regclass('chain_projection.trades') IS NOT NULL THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS trades_block_idx ON chain_projection.trades (block_number, log_index)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS trades_market_time_idx ON chain_projection.trades (market_vault, block_timestamp DESC)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS trades_contest_market_order_idx ON chain_projection.trades (contest_id, market_vault, block_number, log_index)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS trades_market_trader_order_idx ON chain_projection.trades (market_vault, trader, block_number, log_index)';
  END IF;
END $$;
