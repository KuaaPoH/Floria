import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().trim().min(1, "Vui lòng nhập email").email("Email không hợp lệ"),
  password: z.string().min(1, "Vui lòng nhập mật khẩu"),
  remember: z.boolean(),
});

export const registerSchema = z
  .object({
    displayName: z.string().trim().min(2, "Họ tên tối thiểu 2 ký tự").max(60, "Họ tên tối đa 60 ký tự"),
    email: z.string().trim().min(1, "Vui lòng nhập email").email("Email không hợp lệ"),
    password: z.string().min(8, "Mật khẩu tối thiểu 8 ký tự").regex(/[A-Za-z]/, "Cần ít nhất 1 chữ cái").regex(/\d/, "Cần ít nhất 1 chữ số"),
    confirmPassword: z.string(),
    acceptTerms: z.literal(true, { errorMap: () => ({ message: "Bạn cần đồng ý với điều khoản sử dụng" }) }),
  })
  .refine((d) => d.password === d.confirmPassword, { path: ["confirmPassword"], message: "Mật khẩu xác nhận không khớp" });

export const forgotSchema = z.object({ email: z.string().trim().min(1, "Vui lòng nhập email").email("Email không hợp lệ") });

export type LoginValues = z.infer<typeof loginSchema>;
export type RegisterValues = z.infer<typeof registerSchema>;
