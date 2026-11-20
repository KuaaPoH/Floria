import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

const execFileAsync = promisify(execFile);

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const url = new URL(req.url);
    const folder = (url.searchParams.get("folder") ?? "all").trim();

    const db = getAdminDb();
    const snap =
      folder === "all"
        ? await db.collection("TrainingDataset").get()
        : await db.collection("TrainingDataset").where("folderName", "==", folder).get();

    if (snap.empty) {
      return NextResponse.json({ error: "Không có ảnh nào trong kho để tải." }, { status: 404 });
    }

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "floria_ds_"));
    const tmpZip = path.join(os.tmpdir(), `floria_dataset_${Date.now()}.zip`);

    try {
      let downloaded = 0;
      await Promise.all(
        snap.docs.map(async (doc, idx) => {
          const d = doc.data() ?? {};
          const fName = String(d.folderName || "unknown").replace(/[<>:"/\\|?*]+/g, "_");
          const fileName = String(d.fileName || `img_${idx}.jpg`).replace(/[<>:"/\\|?*]+/g, "_");
          const imageUrl = String(d.imageUrl || "").trim();
          if (!imageUrl) return;

          try {
            const imgRes = await fetch(imageUrl);
            if (!imgRes.ok) return;
            const buf = Buffer.from(await imgRes.arrayBuffer());
            const folderDir = folder === "all" ? path.join(tmpDir, fName) : tmpDir;
            if (!fs.existsSync(folderDir)) fs.mkdirSync(folderDir, { recursive: true });
            fs.writeFileSync(path.join(folderDir, fileName), buf);
            downloaded++;
          } catch {
            // Bỏ qua ảnh lỗi mạng đơn lẻ
          }
        }),
      );

      if (downloaded === 0) {
        return NextResponse.json({ error: "Không tải được ảnh nào từ Cloudinary." }, { status: 502 });
      }

      if (process.platform === "win32") {
        await execFileAsync("powershell.exe", [
          "-NoProfile",
          "-Command",
          `Compress-Archive -Path '${path.join(tmpDir, "*").replace(/'/g, "''")}' -DestinationPath '${tmpZip.replace(/'/g, "''")}' -Force`,
        ]);
      } else {
        await execFileAsync("zip", ["-r", tmpZip, "."], { cwd: tmpDir });
      }

      const zipBuf = fs.readFileSync(tmpZip);
      const downloadName = folder === "all" ? "floria_dataset_all.zip" : `floria_dataset_${folder}.zip`;
      return new NextResponse(zipBuf, {
        status: 200,
        headers: {
          "Content-Type": "application/zip",
          "Content-Disposition": `attachment; filename="${downloadName}"`,
        },
      });
    } finally {
      if (fs.existsSync(tmpDir)) {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
      if (fs.existsSync(tmpZip)) {
        fs.unlinkSync(tmpZip);
      }
    }
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi nén dataset";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
