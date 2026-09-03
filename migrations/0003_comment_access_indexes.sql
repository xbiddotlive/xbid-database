CREATE INDEX IF NOT EXISTS comment_author_rate_idx
  ON app.comment (chain_id, contest_id, author_address, created_at DESC);
