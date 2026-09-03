import {
  bigint,
  bigserial,
  index,
  integer,
  jsonb,
  pgEnum,
  pgSchema,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";

export const appSchema = pgSchema("app");

export const commentStatus = pgEnum("comment_status", [
  "ACTIVE",
  "AUTHOR_DELETED",
  "MOD_HIDDEN",
]);
export const positionSide = pgEnum("position_side", [
  "A",
  "B",
  "BOTH",
  "NONE",
  "UNVERIFIED",
]);

export const walletNonces = appSchema.table(
  "wallet_nonce",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    chainId: integer("chain_id").notNull(),
    address: varchar("address", { length: 42 }).notNull(),
    nonceHash: varchar("nonce_hash", { length: 66 }).notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    consumedAt: timestamp("consumed_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex("wallet_nonce_active_unique").on(table.chainId, table.address, table.nonceHash),
  ],
);

export const walletSessions = appSchema.table(
  "wallet_session",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    chainId: integer("chain_id").notNull(),
    address: varchar("address", { length: 42 }).notNull(),
    tokenHash: varchar("token_hash", { length: 66 }).notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    revokedAt: timestamp("revoked_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [index("wallet_session_address_idx").on(table.chainId, table.address)],
);

export const comments = appSchema.table(
  "comment",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    chainId: integer("chain_id").notNull(),
    contestId: varchar("contest_id", { length: 66 }).notNull(),
    marketVault: varchar("market_vault", { length: 42 }).notNull(),
    marketVersion: integer("market_version").notNull(),
    authorAddress: varchar("author_address", { length: 42 }).notNull(),
    rootCommentId: uuid("root_comment_id"),
    parentCommentId: uuid("parent_comment_id"),
    replyToCommentId: uuid("reply_to_comment_id"),
    body: text("body").notNull(),
    bodyNormalizedHash: varchar("body_normalized_hash", { length: 66 }).notNull(),
    status: commentStatus("status").default("ACTIVE").notNull(),
    positionSideAtPost: positionSide("position_side_at_post").default("UNVERIFIED").notNull(),
    positionBlockNumber: bigint("position_block_number", { mode: "bigint" }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    deletedAt: timestamp("deleted_at", { withTimezone: true }),
  },
  (table) => [
    index("comment_contest_live_idx").on(table.chainId, table.contestId, table.createdAt),
    index("comment_root_idx").on(table.rootCommentId, table.createdAt),
  ],
);

export const commentReactions = appSchema.table(
  "comment_reaction",
  {
    chainId: integer("chain_id").notNull(),
    commentId: uuid("comment_id").notNull(),
    userAddress: varchar("user_address", { length: 42 }).notNull(),
    type: varchar("type", { length: 16 }).default("LIKE").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.chainId, table.commentId, table.userAddress, table.type] }),
  ],
);

export const outboxEvents = appSchema.table(
  "outbox_event",
  {
    sequence: bigserial("sequence", { mode: "bigint" }).primaryKey(),
    eventId: uuid("event_id").defaultRandom().notNull(),
    chainId: integer("chain_id").notNull(),
    aggregateType: varchar("aggregate_type", { length: 32 }).notNull(),
    aggregateId: uuid("aggregate_id").notNull(),
    eventType: varchar("event_type", { length: 64 }).notNull(),
    schemaVersion: integer("schema_version").default(1).notNull(),
    payload: jsonb("payload").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    publishedAt: timestamp("published_at", { withTimezone: true }),
  },
  (table) => [
    uniqueIndex("outbox_event_id_unique").on(table.eventId),
    index("outbox_unpublished_idx").on(table.publishedAt, table.sequence),
  ],
);

export const uploadedAssets = appSchema.table("uploaded_asset", {
  contentHash: varchar("content_hash", { length: 66 }).primaryKey(),
  mimeType: varchar("mime_type", { length: 32 }).notNull(),
  byteSize: integer("byte_size").notNull(),
  storageKey: text("storage_key").notNull().unique(),
  originalName: text("original_name"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
});

export const contestMetadata = appSchema.table(
  "contest_metadata",
  {
    metadataHash: varchar("metadata_hash", { length: 66 }).primaryKey(),
    metadataUri: text("metadata_uri").notNull().unique(),
    metadataJson: jsonb("metadata_json").notNull(),
    creatorAddress: varchar("creator_address", { length: 42 }).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [index("contest_metadata_creator_idx").on(table.creatorAddress, table.createdAt)],
);
