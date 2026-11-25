"use client";

import { useState } from "react";
import { Flag, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { scanService } from "@/services/scan.service";

interface ReportScanDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  predictedLabel: string;
  predictedNameVi: string;
  confidence: number | null;
  isValidPlant: boolean;
  isDiseaseScan: boolean;
  imageUrl: string;
}

export function ReportScanDialog({
  open,
  onOpenChange,
  predictedLabel,
  predictedNameVi,
  confidence,
  isValidPlant,
  isDiseaseScan,
  imageUrl,
}: ReportScanDialogProps) {
  const [suggestedName, setSuggestedName] = useState("");
  const [note, setNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const submit = async () => {
    if (!suggestedName.trim() && !note.trim()) {
      toast.error("Vui lòng nhập tên gợi ý hoặc mô tả yêu cầu cập nhật.");
      return;
    }
    setSubmitting(true);
    try {
      await scanService.reportScan({
        reportType: "update_request",
        suggestedName: suggestedName.trim(),
        note: note.trim(),
        predictedLabel,
        predictedNameVi,
        confidence,
        isValidPlant,
        isDiseaseScan,
        imageUrl,
      });
      toast.success("Đã gửi yêu cầu cập nhật tới đội ngũ Floria!");
      setSuggestedName("");
      setNote("");
      onOpenChange(false);
    } catch (e) {
      toast.error((e as Error).message || "Không thể gửi yêu cầu lúc này.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-3xl sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Flag className="size-4 text-warning" /> Yêu cầu cập nhật
          </DialogTitle>
          <DialogDescription>
            Đề xuất cập nhật thông tin loài cây hoặc dữ liệu nhận diện cho thư viện Floria.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <Field
            label={isDiseaseScan ? "Tên bệnh hoặc tình trạng đề xuất" : "Tên loài cây đề xuất cập nhật"}
            htmlFor="rep-name"
          >
            <Input
              id="rep-name"
              value={suggestedName}
              onChange={(e) => setSuggestedName(e.target.value)}
              placeholder={isDiseaseScan ? "Ví dụ: Cháy mép lá do nắng, đốm lá…" : "Ví dụ: Trầu bà thanh xuân, Monstera…"}
            />
          </Field>
          <Field label="Nội dung yêu cầu cập nhật" htmlFor="rep-note">
            <Textarea
              id="rep-note"
              rows={3}
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Mô tả đặc điểm hoặc thông tin bạn muốn Floria bổ sung / cập nhật…"
            />
          </Field>
        </div>
        <DialogFooter>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>Hủy</Button>
          <Button disabled={submitting} onClick={submit}>
            {submitting && <Loader2 className="animate-spin" />} Gửi yêu cầu
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
