import type { InventoryTx, Order, Product, ProductReview, Voucher, FulfillmentStatus, PaymentStatus } from "@/types";
import { daysAgo, seeded } from "@/lib/id";
import { IMAGES } from "./images";

const P: [string, Product["category"], number, number, number, string][] = [
  ["Phân bón hữu cơ trùn quế 1kg", "Phân bón", 95000, 79000, 142, "fertilizer"],
  ["Phân NPK 20-20-15 cho cây cảnh 500g", "Phân bón", 65000, 55000, 8, "fertilizer"],
  ["Phân tan chậm Osmocote 300g", "Phân bón", 145000, 125000, 64, "fertilizer"],
  ["Đất trồng cây cảnh trộn sẵn 5dm³", "Đất & giá thể", 55000, 49000, 210, "fertilizer"],
  ["Giá thể vỏ thông cho lan 2L", "Đất & giá thể", 70000, 62000, 0, "fertilizer"],
  ["Đá perlite 5L", "Đất & giá thể", 85000, 75000, 37, "fertilizer"],
  ["Chậu gốm men mờ Sage 16cm", "Chậu cây", 185000, 159000, 46, "pot"],
  ["Chậu gốm men mờ Sage 22cm", "Chậu cây", 265000, 229000, 4, "pot"],
  ["Chậu nhựa tự tưới 18cm", "Chậu cây", 89000, 79000, 120, "pot"],
  ["Kéo cắt tỉa cành thép không gỉ", "Dụng cụ làm vườn", 220000, 189000, 58, "shears"],
  ["Bình xịt phun sương 1L", "Dụng cụ làm vườn", 75000, 65000, 3, "shears"],
  ["Bộ dụng cụ làm vườn mini 3 món", "Dụng cụ làm vườn", 159000, 139000, 75, "shears"],
  ["Thuốc trị nấm gốc đồng 100g", "Thuốc trị sâu bệnh", 45000, 39000, 96, "fertilizer"],
  ["Dầu neem hữu cơ 250ml", "Thuốc trị sâu bệnh", 135000, 119000, 0, "fertilizer"],
  ["Thuốc trừ rệp sinh học 100ml", "Thuốc trị sâu bệnh", 68000, 59000, 22, "fertilizer"],
  ["Dung dịch dưỡng lá bóng 300ml", "Chăm sóc cây", 89000, 75000, 81, "fertilizer"],
  ["Kích rễ B1 Thái Lan 100ml", "Chăm sóc cây", 55000, 45000, 140, "fertilizer"],
  ["Que thử độ ẩm đất", "Chăm sóc cây", 125000, 99000, 9, "shears"],
];

export function seedProducts(): Product[] {
  const r = seeded(11);
  return P.map(([name, category, op, price, stock, img], i) => ({
    id: `prd_${String(i + 1).padStart(3, "0")}`,
    name,
    sku: `FL-${category.slice(0, 2).toUpperCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/Đ/g, "D")}-${String(100 + i)}`,
    category,
    image: IMAGES[img as keyof typeof IMAGES],
    originalPrice: op,
    price,
    stock,
    lowStockThreshold: 10,
    visible: i !== 4,
    sold: Math.floor(r() * 600) + 20,
    rating: Math.round((3.8 + r() * 1.2) * 10) / 10,
    description: `${name} — sản phẩm chính hãng do Floria tuyển chọn, phù hợp cho người mới bắt đầu chăm cây.`,
    updatedAt: daysAgo(i + 1),
  }));
}

const CUSTOMERS = [
  ["Nguyễn Thị Lan", "lan.nguyen@gmail.com", "0903 112 455", "12 Nguyễn Huệ, Q.1, TP. Hồ Chí Minh"],
  ["Trần Minh Khoa", "khoa.tran@outlook.com", "0912 334 210", "45 Láng Hạ, Đống Đa, Hà Nội"],
  ["Lê Hoài Thương", "thuong.le@yahoo.com.vn", "0987 556 120", "88 Bạch Đằng, Hải Châu, Đà Nẵng"],
  ["Phạm Gia Huy", "huy.pham@gmail.com", "0938 778 902", "21 Trần Phú, Phường 4, Đà Lạt"],
  ["Võ Ngọc Ánh", "anh.vo@gmail.com", "0909 667 345", "7 Lê Lợi, Ninh Kiều, Cần Thơ"],
  ["Đặng Quốc Bảo", "bao.dang@gmail.com", "0977 220 118", "150 Hai Bà Trưng, Q.3, TP. Hồ Chí Minh"],
  ["Hoàng Thu Trang", "trang.hoang@outlook.com", "0965 431 879", "3 Hùng Vương, TP. Huế"],
];

const FLOW: FulfillmentStatus[] = ["pending", "confirmed", "shipping", "delivered"];

export function seedOrders(): Order[] {
  const r = seeded(99);
  const products = seedProducts();
  return Array.from({ length: 36 }, (_, i) => {
    const c = CUSTOMERS[i % CUSTOMERS.length];
    const count = 1 + Math.floor(r() * 3);
    const items = Array.from({ length: count }, () => {
      const p = products[Math.floor(r() * products.length)];
      return { productId: p.id, name: p.name, qty: 1 + Math.floor(r() * 3), price: p.price };
    });
    const subtotal = items.reduce((s, it) => s + it.qty * it.price, 0);
    const shippingFee = subtotal > 500000 ? 0 : 30000;
    const discount = i % 5 === 0 ? Math.round(subtotal * 0.1) : 0;
    const method = i % 3 === 0 ? "COD" : "ZALOPAY";
    const age = Math.floor(i / 2);
    const cancelled = i % 13 === 6;
    const stage = cancelled ? 1 : Math.min(3, Math.max(0, 3 - Math.floor(age / 4) + (i % 2 === 0 ? 0 : -1)));
    const fulfillment: FulfillmentStatus = cancelled ? "cancelled" : FLOW[age < 2 ? Math.min(stage, 1) : stage];
    const base = new Date(daysAgo(age, 8 + (i % 9)));
    const timeline = FLOW.slice(0, FLOW.indexOf(fulfillment === "cancelled" ? "confirmed" : fulfillment) + 1).map((s, k) => ({
      status: s,
      at: new Date(base.getTime() + k * 1000 * 60 * 60 * 9).toISOString(),
      by: k === 0 ? "Hệ thống" : k % 2 ? "Ngô Thanh Tú" : "Hồ Gia Linh",
    }));
    if (cancelled) timeline.push({ status: "cancelled", at: new Date(base.getTime() + 1000 * 60 * 60 * 20).toISOString(), by: "Ngô Thanh Tú" });
    let paymentStatus: PaymentStatus;
    if (method === "ZALOPAY") paymentStatus = cancelled ? "refund_requested" : i % 11 === 4 ? "failed" : "paid";
    else paymentStatus = fulfillment === "delivered" ? "paid" : "unpaid";
    return {
      id: `ord_${i + 1}`,
      code: `FL${String(26110000 + 412 - i)}`,
      customerName: c[0],
      customerEmail: c[1],
      phone: c[2],
      address: c[3],
      createdAt: base.toISOString(),
      items,
      shippingFee,
      discount,
      voucherCode: discount ? "XANHMAT10" : undefined,
      total: subtotal + shippingFee - discount,
      paymentMethod: method,
      paymentStatus,
      fulfillment,
      timeline,
      transaction:
        method === "ZALOPAY" && paymentStatus !== "failed"
          ? { id: `ZLP${14000000 + i * 37}`, at: new Date(base.getTime() + 1000 * 90).toISOString(), sandbox: true }
          : undefined,
      notes: i % 7 === 2 ? "Khách yêu cầu giao giờ hành chính." : "",
    } satisfies Order;
  });
}

export function seedInventoryTx(): InventoryTx[] {
  const products = seedProducts();
  const r = seeded(5);
  return Array.from({ length: 24 }, (_, i) => {
    const p = products[Math.floor(r() * products.length)];
    const type = i % 4 === 0 ? "adjust" : i % 3 === 0 ? "out" : "in";
    return {
      id: `inv_${i + 1}`,
      productId: p.id,
      productName: p.name,
      type,
      qty: type === "adjust" ? -Math.ceil(r() * 4) : Math.ceil(r() * 60),
      note: type === "in" ? "Nhập hàng từ NCC Xanh Việt" : type === "out" ? "Xuất kho đơn hàng" : "Kiểm kê: hàng lỗi/vỡ",
      by: i % 2 ? "Ngô Thanh Tú" : "Hồ Gia Linh",
      at: daysAgo(i, 8 + (i % 8)),
    } satisfies InventoryTx;
  });
}

export function seedVouchers(): Voucher[] {
  return [
    { id: "vch_1", code: "XANHMAT10", type: "percent", value: 10, minOrder: 300000, maxUsage: 500, used: 214, expiresAt: daysAgo(-30), active: true },
    { id: "vch_2", code: "FREESHIP30", type: "fixed", value: 30000, minOrder: 200000, maxUsage: 1000, used: 687, expiresAt: daysAgo(-12), active: true },
    { id: "vch_3", code: "CAYMOI50K", type: "fixed", value: 50000, minOrder: 400000, maxUsage: 300, used: 300, expiresAt: daysAgo(3), active: false },
    { id: "vch_4", code: "FLORIA15", type: "percent", value: 15, minOrder: 500000, maxUsage: 200, used: 42, expiresAt: daysAgo(-60), active: true },
  ];
}

export function seedReviews(): ProductReview[] {
  const products = seedProducts();
  const texts = [
    "Phân bón dùng rất tốt, cây ra lá mới sau 2 tuần. Đóng gói cẩn thận.",
    "Chậu đẹp, màu y hình, có lỗ thoát nước. Sẽ mua thêm size lớn.",
    "Giao hàng hơi chậm nhưng sản phẩm ổn.",
    "Kéo sắc, cầm chắc tay. Rất đáng tiền!",
    "Sản phẩm không giống mô tả, bao bì bị rách.",
    "Dùng xong cây hết rệp, mùi hơi nồng.",
    "Shop tư vấn nhiệt tình qua trợ lý Floria, mua đúng loại cần.",
    "Hàng kém chất lượng, muốn đổi trả!!!",
  ];
  const names = ["Nguyễn Thị Lan", "Trần Minh Khoa", "Lê Hoài Thương", "Phạm Gia Huy", "Võ Ngọc Ánh", "Đặng Quốc Bảo"];
  return texts.concat(texts.slice(0, 6)).map((content, i) => {
    const p = products[(i * 5) % products.length];
    return {
      id: `rvw_${i + 1}`,
      productId: p.id,
      productName: p.name,
      customer: names[i % names.length],
      rating: content.includes("kém") || content.includes("không giống") ? 1 + (i % 2) : content.includes("chậm") ? 3 : 4 + (i % 2),
      content,
      createdAt: daysAgo(i, 10 + (i % 8)),
      status: i < 5 ? "pending" : i % 4 === 0 ? "hidden" : "approved",
      reply: i === 6 ? "Cảm ơn bạn đã tin dùng Floria! 🌿" : undefined,
    } satisfies ProductReview;
  });
}
