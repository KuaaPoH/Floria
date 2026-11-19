"use client";

import { useState } from "react";
import { Cpu, Eye, GitCompare, History, Rocket, ShieldCheck, Sprout, Microscope } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { StatusBadge } from "@/components/shared/status-badge";
import { ConfirmDialog } from "@/components/shared/confirm-dialog";
import { DemoBadge } from "@/components/shared/demo-badge";
import { chartTheme } from "@/components/shared/chart-card";
import { useResourceMutations } from "@/hooks/use-resource";
import { modelsService } from "@/services";
import { formatDate, formatPercent } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { AiModel } from "@/types";

const KIND_ICON = { gatekeeper: ShieldCheck, species: Sprout, disease: Microscope };

export function ModelCard({ model, canConfigure }: { model: AiModel; canConfigure: boolean }) {
  const { update } = useResourceMutations(modelsService, { entity: "Mô hình AI" });
  const [dialog, setDialog] = useState<null | "details" | "compare" | "rollout" | "rollback" | "toggle">(null);
  const [rollout, setRollout] = useState(model.rollout);
  const [cmpA, setCmpA] = useState(model.versions[0]?.version);
  const [cmpB, setCmpB] = useState(model.versions[1]?.version ?? model.versions[0]?.version);
  const Icon = KIND_ICON[model.kind];
  const prev = model.versions[1];

  const metrics: [string, number][] = [["Accuracy", model.accuracy], ["Precision", model.precision], ["Recall", model.recall], ["F1-score", model.f1]];

  return (
    <div className="card-surface flex flex-col p-5">
      <div className="flex items-start gap-3">
        <span className={cn("grid size-10 shrink-0 place-items-center rounded-xl", model.active ? "bg-accent text-forest" : "bg-muted text-muted-foreground")}>
          <Icon className="size-5" />
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <h3 className="truncate font-semibold">{model.name}</h3>
            <StatusBadge status={model.active ? "active" : "inactive"} label={model.active ? "Active" : "Inactive"} />
          </div>
          <p className="truncate font-mono text-[11px] text-muted-foreground">{model.file}</p>
        </div>
        {canConfigure && <Switch checked={model.active} onCheckedChange={() => setDialog("toggle")} aria-label="Bật/tắt mô hình" />}
      </div>
      <p className="mt-3 text-xs text-muted-foreground">{model.description}</p>
      <div className="mt-4 grid grid-cols-4 gap-2">
        {metrics.map(([l, v]) => (
          <div key={l} className="rounded-lg bg-surface-2/70 p-2 text-center">
            <p className="text-[10px] uppercase tracking-wide text-muted-foreground">{l}</p>
            <p className="mt-0.5 text-sm font-semibold tabular">{formatPercent(v)}</p>
          </div>
        ))}
      </div>
      <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
        <span>Phiên bản <b className="text-foreground">v{model.version}</b></span>
        <span className="flex items-center gap-1"><Cpu className="size-3" /> {model.latencyMs} ms</span>
        <span>{model.classes} lớp</span>
        <span>Cập nhật {formatDate(model.updatedAt)}</span>
      </div>
      <div className="mt-3">
        <div className="mb-1 flex justify-between text-[11px] text-muted-foreground"><span>Rollout</span><span className="tabular">{model.rollout}%</span></div>
        <div className="h-1.5 overflow-hidden rounded-full bg-muted"><div className="h-full rounded-full bg-leaf" style={{ width: `${model.rollout}%` }} /></div>
      </div>
      <div className="mt-4 flex flex-wrap gap-2 border-t pt-4">
        <Button size="sm" variant="outline" onClick={() => setDialog("details")}><Eye /> Chi tiết</Button>
        <Button size="sm" variant="outline" onClick={() => setDialog("compare")} disabled={model.versions.length < 2}><GitCompare /> So sánh</Button>
        {canConfigure && <Button size="sm" variant="soft" onClick={() => { setRollout(model.rollout); setDialog("rollout"); }}><Rocket /> Rollout</Button>}
        {canConfigure && <Button size="sm" variant="ghost" onClick={() => setDialog("rollback")} disabled={!prev}><History /> Rollback</Button>}
      </div>

      <ConfirmDialog
        open={dialog === "toggle"}
        onOpenChange={(o) => !o && setDialog(null)}
        title={model.active ? `Tắt ${model.name}?` : `Kích hoạt ${model.name}?`}
        description={model.active ? "Pipeline nhận diện sẽ bỏ qua mô hình này cho đến khi bật lại." : "Mô hình sẽ được dùng cho các yêu cầu suy luận mới."}
        tone={model.active ? "danger" : "default"}
        onConfirm={() => update.mutate({ id: model.id, patch: { active: !model.active }, before: model.active ? "active" : "inactive", label: model.name })}
      />
      <ConfirmDialog
        open={dialog === "rollback"}
        onOpenChange={(o) => !o && setDialog(null)}
        title={`Rollback về v${prev?.version}?`}
        description={`Phiên bản hiện tại v${model.version} sẽ được thay bằng v${prev?.version} (${prev?.note}).`}
        tone="danger"
        confirmLabel="Rollback"
        onConfirm={() =>
          prev &&
          update.mutate({
            id: model.id,
            patch: { version: prev.version, accuracy: prev.accuracy, f1: prev.f1, latencyMs: prev.latencyMs, versions: [prev, ...model.versions.filter((v) => v.version !== prev.version)], updatedAt: new Date().toISOString() },
            before: `v${model.version}`,
            label: model.name,
          })
        }
      />

      <Dialog open={dialog === "rollout"} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="rounded-2xl">
          <DialogHeader>
            <DialogTitle>Rollout v{model.version}</DialogTitle>
            <DialogDescription>Phần trăm lưu lượng suy luận được định tuyến tới phiên bản này.</DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p className="mb-4 text-center text-3xl font-semibold tabular text-forest">{rollout}%</p>
            <Slider value={[rollout]} min={0} max={100} step={5} onValueChange={([v]) => setRollout(v)} />
            <div className="mt-2 flex justify-between text-[11px] text-muted-foreground"><span>0%</span><span>Canary 10%</span><span>50%</span><span>100%</span></div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialog(null)}>Huỷ</Button>
            <Button onClick={() => { update.mutate({ id: model.id, patch: { rollout }, before: `${model.rollout}%`, label: model.name }); setDialog(null); }}>Áp dụng</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={dialog === "details"} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="rounded-2xl sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">{model.name} <DemoBadge label="Chỉ số demo" /></DialogTitle>
            <DialogDescription>Chỉ số minh hoạ cho giao diện, không phải kết quả đánh giá thực tế của mô hình.</DialogDescription>
          </DialogHeader>
          <Table>
            <TableHeader><TableRow><TableHead>Phiên bản</TableHead><TableHead>Phát hành</TableHead><TableHead>Accuracy</TableHead><TableHead>F1</TableHead><TableHead>Latency</TableHead><TableHead>Ghi chú</TableHead></TableRow></TableHeader>
            <TableBody>
              {model.versions.map((v) => (
                <TableRow key={v.version}>
                  <TableCell className="font-medium">v{v.version} {v.version === model.version && <StatusBadge status="active" label="Hiện tại" />}</TableCell>
                  <TableCell>{formatDate(v.releasedAt)}</TableCell>
                  <TableCell className="tabular">{formatPercent(v.accuracy)}</TableCell>
                  <TableCell className="tabular">{formatPercent(v.f1)}</TableCell>
                  <TableCell className="tabular">{v.latencyMs} ms</TableCell>
                  <TableCell className="text-xs text-muted-foreground">{v.note}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </DialogContent>
      </Dialog>

      <Dialog open={dialog === "compare"} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="rounded-2xl sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>So sánh phiên bản · {model.name}</DialogTitle>
            <DialogDescription>Chỉ số demo.</DialogDescription>
          </DialogHeader>
          <div className="flex gap-2">
            {[[cmpA, setCmpA], [cmpB, setCmpB]].map(([val, set], i) => (
              <Select key={i} value={val as string} onValueChange={set as (v: string) => void}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>{model.versions.map((v) => <SelectItem key={v.version} value={v.version}>v{v.version}</SelectItem>)}</SelectContent>
              </Select>
            ))}
          </div>
          <CompareChart model={model} a={cmpA} b={cmpB} />
        </DialogContent>
      </Dialog>
    </div>
  );
}

function CompareChart({ model, a, b }: { model: AiModel; a?: string; b?: string }) {
  const va = model.versions.find((v) => v.version === a);
  const vb = model.versions.find((v) => v.version === b);
  if (!va || !vb) return null;
  const data = [
    { metric: "Accuracy", A: va.accuracy, B: vb.accuracy },
    { metric: "F1-score", A: va.f1, B: vb.f1 },
  ];
  return (
    <div>
      <div className="h-56">
        <ResponsiveContainer>
          <BarChart data={data}>
            <CartesianGrid stroke={chartTheme.grid} vertical={false} />
            <XAxis dataKey="metric" tick={chartTheme.axis} axisLine={false} tickLine={false} />
            <YAxis domain={[80, 100]} tick={chartTheme.axis} axisLine={false} tickLine={false} width={32} />
            <Tooltip {...chartTheme.tooltip} formatter={(v: number) => formatPercent(v)} />
            <Legend wrapperStyle={{ fontSize: 12 }} formatter={(v) => (v === "A" ? `v${va.version}` : `v${vb.version}`)} />
            <Bar dataKey="A" fill="var(--chart-1)" radius={[6, 6, 0, 0]} barSize={28} />
            <Bar dataKey="B" fill="var(--chart-2)" radius={[6, 6, 0, 0]} barSize={28} />
          </BarChart>
        </ResponsiveContainer>
      </div>
      <p className="text-center text-xs text-muted-foreground">Latency: v{va.version} {va.latencyMs} ms · v{vb.version} {vb.latencyMs} ms</p>
    </div>
  );
}
