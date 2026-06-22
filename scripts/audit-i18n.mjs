#!/usr/bin/env node
/**
 * Quick check: t("key", "fallback") keys missing from pw-i18n.js
 * Usage: node scripts/audit-i18n.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const website = path.join(root, "..", "pagewalker", "website");
const i18n = fs.readFileSync(path.join(website, "js", "pw-i18n.js"), "utf8");
const dictKeys = new Set([...i18n.matchAll(/^\s+"([a-zA-Z0-9_.]+)":/gm)].map((m) => m[1]));

const used = new Map();
const re = /\bt\(\s*"([^"]+)"\s*,\s*"((?:\\.|[^"\\])*)"\s*\)/g;
for (const file of fs.readdirSync(path.join(website, "js")).filter((f) => f.endsWith(".js"))) {
  const src = fs.readFileSync(path.join(website, "js", file), "utf8");
  let m;
  while ((m = re.exec(src))) used.set(m[1], m[2]);
}

const missing = [...used.keys()].filter((k) => !dictKeys.has(k));
if (missing.length) {
  console.error(`Missing ${missing.length} i18n keys:`);
  missing.sort().forEach((k) => console.error(`  - ${k}`));
  process.exit(1);
}
console.log(`OK — ${used.size} t(key,fallback) keys covered.`);
process.exit(0);
