import type { AppUser, AuthProvider, AccountStatus } from "@/types";
import { daysAgo, seeded } from "@/lib/id";

const FIRST = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương"];
const MIDDLE = ["Thị", "Văn", "Minh", "Ngọc", "Thanh", "Hoài", "Gia", "Bảo", "Thu", "Quốc"];
const LAST = ["An", "Bình", "Châu", "Dung", "Giang", "Hà", "Khánh", "Linh", "My", "Nam", "Phúc", "Quân", "Trang", "Tú", "Vy", "Yến", "Hưng", "Thảo", "Duy", "Hạnh"];
const CITIES = ["TP. Hồ Chí Minh", "Hà Nội", "Đà Nẵng", "Cần Thơ", "Đà Lạt", "Huế", "Nha Trang", "Hải Phòng"];
const PROVIDERS: AuthProvider[] = ["google", "google", "email", "apple", "facebook", "google", "email"];

const strip = (s: string) => s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();

export function seedUsers(): AppUser[] {
  const r = seeded(42);
  return Array.from({ length: 64 }, (_, i) => {
    const f = FIRST[Math.floor(r() * FIRST.length)];
    const m = MIDDLE[Math.floor(r() * MIDDLE.length)];
    const l = LAST[Math.floor(r() * LAST.length)];
    const fullName = `${f} ${m} ${l}`;
    const status: AccountStatus = i % 17 === 5 ? "locked" : i % 23 === 7 ? "pending" : "active";
    const plants = Math.floor(r() * 24);
    const scans = plants * 3 + Math.floor(r() * 40);
    return {
      id: `usr_${(1001 + i).toString()}`,
      fullName,
      email: `${strip(l)}.${strip(f)}${10 + i}@${i % 3 === 0 ? "gmail.com" : i % 3 === 1 ? "yahoo.com.vn" : "outlook.com"}`,
      phone: `09${Math.floor(10000000 + r() * 89999999)}`,
      city: CITIES[Math.floor(r() * CITIES.length)],
      provider: PROVIDERS[i % PROVIDERS.length],
      registeredAt: daysAgo(Math.floor(r() * 300) + 2),
      lastActiveAt: daysAgo(Math.floor(r() * 20), 8 + (i % 12)),
      plants,
      scans,
      diseaseScans: Math.floor(scans * 0.35),
      orders: Math.floor(r() * 9),
      status,
    };
  });
}
