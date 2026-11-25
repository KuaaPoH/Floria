/** Lightweight in-browser stand-in for the CLIP gatekeeper: measures how "plant-like" (green/leafy) an image is. */
export async function analyzeImage(src: string): Promise<{ greenRatio: number; hash: number }> {
  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const i = new Image();
    i.crossOrigin = "anonymous";
    i.onload = () => resolve(i);
    i.onerror = reject;
    i.src = src;
  });
  const size = 48;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext("2d")!;
  ctx.drawImage(img, 0, 0, size, size);
  const { data } = ctx.getImageData(0, 0, size, size);
  let green = 0;
  let hash = 2166136261;
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    if (g > r * 1.05 && g > b * 1.05 && g > 40) green++;
    hash ^= (r >> 4) + (g >> 4) * 16 + (b >> 4) * 256;
    hash = Math.imul(hash, 16777619) >>> 0;
  }
  return { greenRatio: green / (size * size), hash };
}
