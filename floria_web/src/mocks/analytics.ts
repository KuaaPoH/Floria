import { seeded } from "@/lib/id";

/** Demo time series for the Overview dashboard, generated deterministically per range. */
export function overviewSeries(days: number) {
  const r = seeded(days * 13);
  const today = new Date();
  let users = 31500 - days * 38;
  return Array.from({ length: days }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() - (days - 1 - i));
    const weekend = d.getDay() === 0 || d.getDay() === 6 ? 1.25 : 1;
    users += Math.round(25 + r() * 35);
    const scans = Math.round((1700 + r() * 600 + i * 4) * weekend);
    return {
      date: d.toISOString(),
      users,
      newUsers: Math.round(25 + r() * 35),
      plantScans: scans,
      diseaseScans: Math.round(scans * (0.32 + r() * 0.08)),
      revenue: Math.round((2.2 + r() * 1.8) * 1_000_000 * weekend),
      orders: Math.round((28 + r() * 22) * weekend),
      sessions: Math.round((900 + r() * 400) * weekend),
    };
  });
}

export const TOP_DISEASES = [
  { name: "Đốm lá", value: 3820 },
  { name: "Thối rễ", value: 2410 },
  { name: "Phấn trắng", value: 1960 },
  { name: "Gỉ sắt", value: 1240 },
  { name: "Cháy lá VK", value: 980 },
];
