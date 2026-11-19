/**
 * Feature service registry. Every service switches between local mock data and the REST API
 * based on NEXT_PUBLIC_DATA_MODE (see src/lib/config.ts).
 */
import type * as T from "@/types";
import { seedUsers } from "@/mocks/users";
import { seedPlants } from "@/mocks/plants";
import { seedDiseases } from "@/mocks/diseases";
import { DEFAULT_AI_CONFIG, seedLabelReviews, seedModels } from "@/mocks/ai";
import { seedInventoryTx, seedOrders, seedProducts, seedReviews, seedVouchers } from "@/mocks/commerce";
import { DEFAULT_REMOTE_CONFIG, seedArticles, seedBanners, seedConfigVersions, seedFlags, seedWeatherRules } from "@/mocks/content";
import { DEFAULT_ASSISTANT, DEFAULT_PROMPT, seedActionTags, seedCampaigns, seedGuardrails, seedPromptVersions, seedReports, seedTickets } from "@/mocks/comms";
import { seedAdmins, seedBackups, seedServices } from "@/mocks/system";
import { createResourceService } from "./resource";
import { createSingletonService } from "./singleton";

export { auditService, logAudit } from "./audit.service";

// Users & RBAC (Nhóm 1 - đã nối dữ liệu thật)
export const usersService = createResourceService<T.AppUser>("users", seedUsers);
export const adminsService = createResourceService<T.AdminAccount>("admins", seedAdmins, { forceMock: true });

// Botanical (Nhóm 2 - đã nối dữ liệu thật)
export const plantsService = createResourceService<T.Plant>("plants", seedPlants);
export const diseasesService = createResourceService<T.Disease>("diseases", seedDiseases);

// AI Lab (Task 4)
export const modelsService = createResourceService<T.AiModel>("ai-models", seedModels, { forceMock: true });
export const labelReviewsService = createResourceService<T.LabelReview>("label-reviews", seedLabelReviews, { forceMock: true });
export const aiConfigService = createSingletonService<T.AiConfig>("ai-config", () => DEFAULT_AI_CONFIG, { forceMock: true });

// Assistant (Task 4)
export const assistantSettingsService = createSingletonService<T.AssistantSettings>("assistant-settings", () => DEFAULT_ASSISTANT, { forceMock: true });
export const promptDraftService = createSingletonService<{ content: string }>("assistant-prompt-draft", () => ({ content: DEFAULT_PROMPT }), { forceMock: true });
export const promptVersionsService = createResourceService<T.PromptVersion>("assistant-prompt-versions", seedPromptVersions, { forceMock: true });
export const guardrailsService = createResourceService<T.Guardrail>("assistant-guardrails", seedGuardrails, { forceMock: true });
export const actionTagsService = createResourceService<T.ActionTag>("assistant-action-tags", seedActionTags, { forceMock: true });
export const reportsService = createResourceService<T.ConversationReport>("assistant-reports", seedReports, { forceMock: true });

// Commerce (Nhóm 3 - đã nối dữ liệu thật)
export const ordersService = createResourceService<T.Order>("orders", seedOrders);
export const productsService = createResourceService<T.Product>("products", seedProducts);
export const inventoryService = createResourceService<T.InventoryTx>("inventory-transactions", seedInventoryTx);
export const vouchersService = createResourceService<T.Voucher>("vouchers", seedVouchers);
export const reviewsService = createResourceService<T.ProductReview>("reviews", seedReviews);

// Content (Nhóm 4 - đã nối dữ liệu thật)
export const articlesService = createResourceService<T.Article>("articles", seedArticles);
export const bannersService = createResourceService<T.Banner>("banners", seedBanners);
export const weatherRulesService = createResourceService<T.WeatherRule>("weather-rules", seedWeatherRules);
export const flagsService = createResourceService<T.FeatureFlag>("feature-flags", seedFlags, { forceMock: true });
export const remoteConfigDraftService = createSingletonService<T.RemoteConfig>("remote-config-draft", () => structuredClone(DEFAULT_REMOTE_CONFIG), { forceMock: true });
export const configVersionsService = createResourceService<T.ConfigVersion>("remote-config-versions", seedConfigVersions, { forceMock: true });

// Communication (Nhóm 4 & Task 4)
export const campaignsService = createResourceService<T.Campaign>("campaigns", seedCampaigns);
export const ticketsService = createResourceService<T.Ticket>("tickets", seedTickets, { forceMock: true });

// System (Task 4)
export const backupsService = createResourceService<T.BackupRecord>("backups", seedBackups, { forceMock: true });
export const servicesHealthService = createResourceService<T.ServiceHealth>("service-health", seedServices, { forceMock: true });
