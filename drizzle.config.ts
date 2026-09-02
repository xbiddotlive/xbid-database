import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "postgresql",
  schema: "./schema/index.ts",
  out: "./migrations",
  dbCredentials: {
    url:
      process.env.DATABASE_URL ??
      "postgresql://xbid:xbid@127.0.0.1:55432/xbid?sslmode=disable",
  },
  strict: true,
  verbose: true,
});
