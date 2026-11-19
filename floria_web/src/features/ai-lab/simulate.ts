import { DISEASE_CLASSES, SPECIES_CLASSES } from "@/mocks/ai-classes";
import { seeded } from "@/lib/id";
import type { AiConfig } from "@/types";

export interface Prediction {
  label: string;
  className: string;
  probability: number;
}

export interface PipelineResult {
  simulated: true;
  gatekeeper: { isPlant: boolean; score: number; ms: number };
  species?: { top: Prediction[]; uncertain: boolean; ms: number };
  disease?: { top: Prediction[]; uncertain: boolean; ms: number };
  totalMs: number;
}

function softmaxTopK(scores: number[], k: number) {
  const max = Math.max(...scores);
  const exps = scores.map((s) => Math.exp(s - max));
  const sum = exps.reduce((a, b) => a + b, 0);
  return exps
    .map((e, i) => ({ i, p: e / sum }))
    .sort((a, b) => b.p - a.p)
    .slice(0, k);
}

/**
 * Deterministic SIMULATION of the CLIP → species → disease pipeline for the sandbox UI.
 * It does not run any model; the seed only keeps results stable for the same image.
 */
export function simulatePipeline(seed: number, config: Pick<AiConfig, "topK" | "confidenceThreshold" | "gatekeeperThreshold">): PipelineResult {
  const r = seeded(Math.abs(seed) % 233280 || 1);
  const gateScore = 0.35 + r() * 0.64;
  const gatekeeper = { isPlant: gateScore >= config.gatekeeperThreshold, score: gateScore, ms: Math.round(30 + r() * 15) };
  if (!gatekeeper.isPlant) return { simulated: true, gatekeeper, totalMs: gatekeeper.ms };

  const k = Math.max(1, Math.min(config.topK, 10));
  const sScores = SPECIES_CLASSES.map(() => r() * 2);
  sScores[Math.floor(r() * SPECIES_CLASSES.length)] += 3 + r() * 3;
  const sTop = softmaxTopK(sScores, k).map(({ i, p }) => ({ label: SPECIES_CLASSES[i].vi, className: SPECIES_CLASSES[i].name, probability: p }));

  const dScores = DISEASE_CLASSES.map(() => r() * 1.5);
  dScores[Math.floor(r() * DISEASE_CLASSES.length)] += 1.5 + r() * 3;
  const dTop = softmaxTopK(dScores, Math.min(k, DISEASE_CLASSES.length)).map(({ i, p }) => ({ label: DISEASE_CLASSES[i].vi, className: DISEASE_CLASSES[i].name, probability: p }));

  const species = { top: sTop, uncertain: sTop[0].probability < config.confidenceThreshold, ms: Math.round(55 + r() * 20) };
  const disease = { top: dTop, uncertain: dTop[0].probability < config.confidenceThreshold, ms: Math.round(48 + r() * 20) };
  return { simulated: true, gatekeeper, species, disease, totalMs: gatekeeper.ms + species.ms + disease.ms + Math.round(8 + r() * 6) };
}

export function hashString(s: string) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return h;
}
