export type MappingStatus = "mapped" | "unmatched" | "duplicate";

export interface MappingRow {
  classId: number;
  className: string;
  records: { id: string; name: string }[];
  status: MappingStatus;
}

/** Compare model output classes with dictionary records: unmatched = no record, duplicate = 2+ records. */
export function buildMapping(classes: { id: number; name: string }[], records: { id: string; name: string; aiClassId: number | null }[]): MappingRow[] {
  return classes.map((c) => {
    const matched = records.filter((r) => r.aiClassId === c.id).map((r) => ({ id: r.id, name: r.name }));
    return { classId: c.id, className: c.name, records: matched, status: matched.length === 0 ? "unmatched" : matched.length > 1 ? "duplicate" : "mapped" };
  });
}

/** Dictionary records that point at no model class. */
export function orphanRecords(records: { id: string; name: string; aiClassId: number | null }[]) {
  return records.filter((r) => r.aiClassId === null);
}
