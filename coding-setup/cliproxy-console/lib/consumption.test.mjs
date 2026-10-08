import assert from "node:assert/strict";
import test from "node:test";
import {
  formatCount,
  formatDollars,
  summarizeCodex,
  summarizeCursorPlan,
  summarizeOpenCode,
} from "./consumption.mjs";

test("formats large token totals without pretending they are percents", () => {
  assert.equal(formatCount(282765802), "282.8M");
  assert.equal(formatCount(891629204), "891.6M");
  assert.equal(formatCount(810), "810");
  assert.equal(formatDollars(2000), "$20.00");
});

test("splits Bedrock out of OpenCode and merges model variants", () => {
  const { opencode, bedrock } = summarizeOpenCode([
    { model: { id: "gemini-3.8-flash", providerID: "google" }, sessions: 40, input: 100, output: 10, reasoning: 1, cacheRead: 5, cost: 1 },
    { model: { id: "gemini-3.8-flash", providerID: "google", variant: "high" }, sessions: 7, input: 50, output: 5, reasoning: 0, cacheRead: 1, cost: 0.5 },
    { model: '{"id":"nemotron-3-ultra-free","providerID":"opencode"}', sessions: 1, input: 20, output: 2, reasoning: 0, cacheRead: 0, cost: 0 },
    { model: { id: "global.openai.gpt-5.6-terra", providerID: "amazon-bedrock" }, sessions: 2, input: 0, output: 0, reasoning: 0, cacheRead: 0, cost: 0 },
  ]);
  assert.equal(opencode.length, 2);
  assert.equal(opencode[0].label, "gemini-3.8-flash");
  assert.equal(opencode[0].sessions, 47);
  assert.equal(opencode[0].input, 150);
  assert.equal(bedrock.length, 1);
  assert.equal(bedrock[0].label, "global.openai.gpt-5.6-terra");
  assert.equal(bedrock[0].sessions, 2);
});

test("keeps Codex models that recorded tokens", () => {
  const rows = summarizeCodex([
    { model: "gpt-5.4", provider: "openai", sessions: 253, tokens: 1000 },
    { model: null, provider: "openai", sessions: 279, tokens: 0 },
  ]);
  assert.deepEqual(rows.map((row) => row.label), ["gpt-5.4"]);
});

test("reads Cursor's included allowance and the two percent meters", () => {
  const plan = summarizeCursorPlan({
    membershipType: "pro",
    billingCycleStart: "2026-09-29T11:04:25.000Z",
    billingCycleEnd: "2026-10-29T11:04:25.000Z",
    individualUsage: {
      plan: {
        used: 2000,
        limit: 2000,
        breakdown: { bonus: 6994 },
        autoPercentUsed: 19.2,
        apiPercentUsed: 14,
      },
      onDemand: { enabled: false },
    },
  });
  assert.equal(plan.membership, "pro");
  assert.equal(plan.includedUsedCents, 2000);
  assert.equal(plan.bonusCents, 6994);
  assert.equal(plan.autoPercent, 19.2);
  assert.equal(plan.onDemandEnabled, false);
});
