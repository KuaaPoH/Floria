import { isMock } from "@/config/env";
import { completeSchedule } from "@/features/garden/logic";
import { uid } from "@/lib/id";
import { readDb, writeDb } from "@/mocks/user/db";
import { findPlantInfo, getAllPlantsInfo, PLANTS_INFO } from "@/mocks/user/plants-info";
import type { CareSchedule, CareScheduleSuggestion, CareType, DiaryNote, PlantInfo, UserGarden, UserPlant } from "@/types/user";
import { http } from "./api/http";
import { fetchUserCatalog } from "./content.service";
import { latency, MockError, requireUid } from "./mock/util";
import { session } from "./session";

export type GardenInput = Pick<UserGarden, "name" | "coverImage" | "environment" | "light" | "description">;
export type PlantInput = Pick<UserPlant, "gardenId" | "speciesId" | "nickname" | "location" | "image"> & {
  healthStatus?: string;
  waterFrequencyDays?: number;
  fertilizeFrequencyDays?: number;
  fertilizeEnabled?: boolean;
  checkPestFrequencyDays?: number;
  notes?: string;
};
export type DiaryInput = Pick<DiaryNote, "plantId" | "category" | "content" | "images"> & { title?: string; diagnosisId?: string | null };

export interface GardenService {
  listGardens(): Promise<UserGarden[]>;
  createGarden(input: GardenInput): Promise<UserGarden>;
  updateGarden(id: string, patch: Partial<GardenInput>): Promise<UserGarden>;
  deleteGarden(id: string): Promise<void>;
  listPlants(): Promise<UserPlant[]>;
  addPlant(input: PlantInput): Promise<UserPlant>;
  updatePlant(id: string, patch: Partial<PlantInput & Pick<UserPlant, "healthStatus" | "activeDiseaseId">>): Promise<UserPlant>;
  deletePlant(id: string): Promise<void>;
  listSchedules(): Promise<CareSchedule[]>;
  completeSchedule(id: string): Promise<CareSchedule>;
  updateSchedule(id: string, patch: Partial<Pick<CareSchedule, "intervalDays" | "preferredTime" | "enabled">>): Promise<CareSchedule>;
  applySuggestion(plantId: string, s: CareScheduleSuggestion): Promise<CareSchedule>;
  listDiary(plantId?: string): Promise<DiaryNote[]>;
  createDiary(input: DiaryInput): Promise<DiaryNote>;
  updateDiary(id: string, patch: Partial<Pick<DiaryNote, "title" | "content" | "images" | "category">>): Promise<DiaryNote>;
  deleteDiary(id: string): Promise<void>;
  listSpecies(): Promise<PlantInfo[]>;
}

const me = () => requireUid(session.get());

function scheduleFor(plantId: string, type: CareType, intervalDays: number, time: string, now = new Date()): CareSchedule {
  const next = new Date(now.getTime() + intervalDays * 86400000);
  const [h, m] = time.split(":").map(Number);
  next.setHours(h, m, 0, 0);
  return { id: uid("cs"), plantId, type, intervalDays, preferredTime: time, lastDoneAt: null, nextDueAt: next.toISOString(), enabled: true, history: [] };
}

const ownedPlantIds = (db: ReturnType<typeof readDb>, userId: string) => new Set(db.plants.filter((p) => p.userId === userId).map((p) => p.id));

const mockGarden: GardenService = {
  async listGardens() {
    await latency();
    const u = me();
    return readDb().gardens.filter((g) => g.userId === u);
  },
  async createGarden(input) {
    await latency();
    const u = me();
    return writeDb((db) => {
      const g: UserGarden = { ...input, id: uid("g"), userId: u, createdAt: new Date().toISOString() };
      db.gardens.push(g);
      return g;
    });
  },
  async updateGarden(id, patch) {
    await latency();
    const u = me();
    return writeDb((db) => {
      const g = db.gardens.find((x) => x.id === id && x.userId === u);
      if (!g) throw new MockError("Không tìm thấy khu vườn.", "not_found");
      Object.assign(g, patch);
      return g;
    });
  },
  async deleteGarden(id) {
    await latency();
    const u = me();
    writeDb((db) => {
      const plantIds = new Set(db.plants.filter((p) => p.gardenId === id && p.userId === u).map((p) => p.id));
      db.gardens = db.gardens.filter((g) => !(g.id === id && g.userId === u));
      db.plants = db.plants.filter((p) => !plantIds.has(p.id));
      db.schedules = db.schedules.filter((s) => !plantIds.has(s.plantId));
      db.diary = db.diary.filter((d) => !plantIds.has(d.plantId));
    });
  },
  async listPlants() {
    await latency();
    const u = me();
    return readDb().plants.filter((p) => p.userId === u);
  },
  async addPlant(input) {
    await latency(500, 800);
    const u = me();
    const info = findPlantInfo(input.speciesId);
    if (!info) throw new MockError("Loài cây không có trong bách khoa.", "unknown_species");
    return writeDb((db) => {
      if (!db.gardens.some((g) => g.id === input.gardenId && g.userId === u)) throw new MockError("Không tìm thấy khu vườn.", "not_found");
      const plant: UserPlant = { ...input, id: uid("pl"), userId: u, healthStatus: "healthy", activeDiseaseId: null, addedAt: new Date().toISOString() };
      db.plants.push(plant);
      db.schedules.push(
        scheduleFor(plant.id, "watering", info.wateringDays, "07:00"),
        scheduleFor(plant.id, "fertilizing", info.fertilizingDays, "08:30"),
        scheduleFor(plant.id, "inspection", info.inspectionDays, "18:00"),
      );
      return plant;
    });
  },
  async updatePlant(id, patch) {
    await latency();
    const u = me();
    return writeDb((db) => {
      const p = db.plants.find((x) => x.id === id && x.userId === u);
      if (!p) throw new MockError("Không tìm thấy cây.", "not_found");
      if (patch.gardenId && !db.gardens.some((g) => g.id === patch.gardenId && g.userId === u)) throw new MockError("Không tìm thấy khu vườn.", "not_found");
      Object.assign(p, patch);
      return p;
    });
  },
  async deletePlant(id) {
    await latency();
    const u = me();
    writeDb((db) => {
      if (!db.plants.some((p) => p.id === id && p.userId === u)) throw new MockError("Không tìm thấy cây.", "not_found");
      db.plants = db.plants.filter((p) => p.id !== id);
      db.schedules = db.schedules.filter((s) => s.plantId !== id);
      db.diary = db.diary.filter((d) => d.plantId !== id);
    });
  },
  async listSchedules() {
    await latency(150, 350);
    const u = me();
    const db = readDb();
    const ids = ownedPlantIds(db, u);
    return db.schedules.filter((s) => ids.has(s.plantId));
  },
  async completeSchedule(id) {
    await latency(200, 400);
    const u = me();
    return writeDb((db) => {
      const idx = db.schedules.findIndex((s) => s.id === id);
      if (idx < 0 || !ownedPlantIds(db, u).has(db.schedules[idx].plantId)) throw new MockError("Không tìm thấy lịch.", "not_found");
      db.schedules[idx] = completeSchedule(db.schedules[idx], new Date(), uid("log"));
      return db.schedules[idx];
    });
  },
  async updateSchedule(id, patch) {
    await latency();
    const u = me();
    return writeDb((db) => {
      const s = db.schedules.find((x) => x.id === id);
      if (!s || !ownedPlantIds(db, u).has(s.plantId)) throw new MockError("Không tìm thấy lịch.", "not_found");
      Object.assign(s, patch);
      if (patch.intervalDays || patch.preferredTime) {
        const base = s.lastDoneAt ? new Date(s.lastDoneAt) : new Date();
        const next = new Date(base.getTime() + s.intervalDays * 86400000);
        const [h, m] = s.preferredTime.split(":").map(Number);
        next.setHours(h, m, 0, 0);
        s.nextDueAt = next.toISOString();
      }
      return s;
    });
  },
  async applySuggestion(plantId, sug) {
    await latency();
    const u = me();
    return writeDb((db) => {
      if (!ownedPlantIds(db, u).has(plantId)) throw new MockError("Không tìm thấy cây.", "not_found");
      let s = db.schedules.find((x) => x.plantId === plantId && x.type === sug.careType);
      if (!s) {
        s = scheduleFor(plantId, sug.careType, sug.intervalDays, sug.preferredTime);
        db.schedules.push(s);
        return s;
      }
      s.intervalDays = sug.intervalDays;
      s.preferredTime = sug.preferredTime;
      s.enabled = true;
      const base = s.lastDoneAt ? new Date(s.lastDoneAt) : new Date();
      const next = new Date(base.getTime() + sug.intervalDays * 86400000);
      const [h, m] = sug.preferredTime.split(":").map(Number);
      next.setHours(h, m, 0, 0);
      s.nextDueAt = next.toISOString();
      return s;
    });
  },
  async listDiary(plantId) {
    await latency(150, 350);
    const u = me();
    return readDb()
      .diary.filter((d) => d.userId === u && (!plantId || d.plantId === plantId))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  async createDiary(input) {
    await latency();
    const u = me();
    return writeDb((db) => {
      if (!ownedPlantIds(db, u).has(input.plantId)) throw new MockError("Không tìm thấy cây.", "not_found");
      const now = new Date().toISOString();
      const note: DiaryNote = { ...input, diagnosisId: input.diagnosisId ?? null, id: uid("dn"), userId: u, createdAt: now, updatedAt: now };
      db.diary.push(note);
      return note;
    });
  },
  async updateDiary(id, patch) {
    await latency();
    const u = me();
    return writeDb((db) => {
      const d = db.diary.find((x) => x.id === id && x.userId === u);
      if (!d) throw new MockError("Không tìm thấy nhật ký.", "not_found");
      Object.assign(d, patch, { updatedAt: new Date().toISOString() });
      return d;
    });
  },
  async deleteDiary(id) {
    await latency();
    const u = me();
    writeDb((db) => {
      db.diary = db.diary.filter((d) => !(d.id === id && d.userId === u));
    });
  },
  async listSpecies() {
    return PLANTS_INFO;
  },
};

interface GardenSnapshotPayload {
  gardens: UserGarden[];
  plants: UserPlant[];
  schedules: CareSchedule[];
  diary: DiaryNote[];
}

let gardenSnapshotCache: { data: GardenSnapshotPayload; expiresAt: number } | null = null;
let gardenSnapshotInflight: Promise<GardenSnapshotPayload> | null = null;

function invalidateGardenSnapshot() {
  gardenSnapshotCache = null;
}

async function fetchGardenSnapshot(): Promise<GardenSnapshotPayload> {
  if (gardenSnapshotCache && gardenSnapshotCache.expiresAt > Date.now()) {
    return gardenSnapshotCache.data;
  }
  if (gardenSnapshotInflight) return gardenSnapshotInflight;
  gardenSnapshotInflight = Promise.all([
    http<GardenSnapshotPayload>("/gardens"),
    fetchUserCatalog().catch(() => null),
  ])
    .then(([data]) => {
      gardenSnapshotCache = { data, expiresAt: Date.now() + 8_000 };
      return data;
    })
    .finally(() => {
      gardenSnapshotInflight = null;
    });
  return gardenSnapshotInflight;
}

const apiGarden: GardenService = {
  async listGardens() {
    const snap = await fetchGardenSnapshot();
    return snap.gardens;
  },
  async createGarden(input) {
    const res = await http<UserGarden>("/gardens", { method: "POST", json: { action: "createGarden", ...input } });
    invalidateGardenSnapshot();
    return res;
  },
  async updateGarden(id, patch) {
    const res = await http<UserGarden>("/gardens", { method: "POST", json: { action: "updateGarden", id, patch } });
    invalidateGardenSnapshot();
    return res;
  },
  async deleteGarden(id) {
    await http("/gardens", { method: "POST", json: { action: "deleteGarden", id } });
    invalidateGardenSnapshot();
  },
  async listPlants() {
    const snap = await fetchGardenSnapshot();
    return snap.plants;
  },
  async addPlant(input) {
    const res = await http<UserPlant>("/gardens", { method: "POST", json: { action: "addPlant", ...input } });
    invalidateGardenSnapshot();
    return res;
  },
  async updatePlant(id, patch) {
    const res = await http<UserPlant>("/gardens", { method: "POST", json: { action: "updatePlant", id, patch } });
    invalidateGardenSnapshot();
    return res;
  },
  async deletePlant(id) {
    await http("/gardens", { method: "POST", json: { action: "deletePlant", id } });
    invalidateGardenSnapshot();
  },
  async listSchedules() {
    const snap = await fetchGardenSnapshot();
    return snap.schedules;
  },
  async completeSchedule(id) {
    const res = await http<CareSchedule>("/gardens", { method: "POST", json: { action: "completeSchedule", id } });
    invalidateGardenSnapshot();
    return res;
  },
  async updateSchedule(id, patch) {
    const res = await http<CareSchedule>("/gardens", { method: "POST", json: { action: "updateSchedule", id, patch } });
    invalidateGardenSnapshot();
    return res;
  },
  async applySuggestion(plantId, suggestion) {
    const res = await http<CareSchedule>("/gardens", { method: "POST", json: { action: "applySuggestion", plantId, suggestion } });
    invalidateGardenSnapshot();
    return res;
  },
  async listDiary(plantId) {
    const snap = await fetchGardenSnapshot();
    return plantId ? snap.diary.filter((d) => d.plantId === plantId) : snap.diary;
  },
  async createDiary(input) {
    const res = await http<DiaryNote>("/gardens", { method: "POST", json: { action: "createDiary", ...input } });
    invalidateGardenSnapshot();
    return res;
  },
  async updateDiary(id, patch) {
    const res = await http<DiaryNote>("/gardens", { method: "POST", json: { action: "updateDiary", id, patch } });
    invalidateGardenSnapshot();
    return res;
  },
  async deleteDiary(id) {
    await http("/gardens", { method: "POST", json: { action: "deleteDiary", id } });
    invalidateGardenSnapshot();
  },
  async listSpecies() {
    const cat = await fetchUserCatalog();
    return cat?.plantsInfo ?? [];
  },
};

export const gardenService: GardenService = isMock() ? mockGarden : apiGarden;
