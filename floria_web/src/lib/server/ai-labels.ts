import fs from "node:fs";
import path from "node:path";

const FALLBACK_SPECIES = [
  "Adenium obesum", "Aglaonema commutatum", "Alocasia amazonica", "Alocasia macrorrhizos",
  "Aloe vera", "Anthurium andraeanum", "Asplenium nidus", "Begonia maculata",
  "Bougainvillea glabra", "Calathea makoyana", "Calathea orbifolia", "Chlorophytum comosum",
  "Codiaeum variegatum", "Crassula ovata", "Cycas revoluta", "Dieffenbachia seguine",
  "Dracaena fragrans", "Dracaena marginata", "Dracaena reflexa", "Epipremnum aureum",
  "Euphorbia milii", "Ficus benjamina", "Ficus elastica", "Ficus lyrata",
  "Hedera helix", "Maranta leuconeura", "Monstera deliciosa", "Nephrolepis exaltata",
  "Pachira aquatica", "Peperomia obtusifolia", "Philodendron bipinnatifidum", "Philodendron hederaceum",
  "Pilea peperomioides", "Sansevieria trifasciata", "Schefflera arboricola", "Schlumbergera truncata",
  "Spathiphyllum wallisii", "Syngonium podophyllum", "Tradescantia zebrina", "Zamioculcas zamiifolia",
];

const FALLBACK_DISEASES = ["Anthracnose", "Bacterial_Blight", "Healthy", "Leaf_Spot", "Powdery_Mildew"];

function readLabelFile(relativePath: string, fallback: string[]): string[] {
  const candidates = [
    path.resolve(process.cwd(), relativePath),
    path.resolve(process.cwd(), "..", relativePath),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) {
      const lines = fs
        .readFileSync(p, "utf-8")
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean);
      if (lines.length > 0) return lines;
    }
  }
  return fallback;
}

export function getSpeciesClasses(): Array<{ id: number; name: string }> {
  return readLabelFile("AI_Engine/models/labels.txt", FALLBACK_SPECIES).map((name, id) => ({ id, name }));
}

export function getDiseaseClasses(): Array<{ id: number; name: string }> {
  return readLabelFile("AI_Engine/models/disease_labels.txt", FALLBACK_DISEASES).map((name, id) => ({ id, name }));
}
