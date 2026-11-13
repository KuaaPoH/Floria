# MASTER PROMPT — FLORIA ADMIN

> **Product:** Floria Admin  
> **Creative direction:** Premium 2.5D Botanical Editorial Motion  
> **Tagline:** Grow smarter. Care better.  
> **Purpose:** Complete administration workspace for an AI-powered plant identification, plant disease recognition, plant-care assistant, and plant-care commerce ecosystem.

---

## 1. ROLE AND PROJECT GOAL

You are a senior product designer, creative director, UX architect, and full-stack frontend developer.

Build a complete, polished, responsive web administration application named **Floria Admin**.

Floria is an ecosystem that includes:

- A mobile application for identifying plant species and diagnosing plant diseases.
- An AI assistant that provides plant-care guidance.
- A plant and disease knowledge database.
- An e-commerce shop for plant-care products.
- An admin dashboard for managing the entire ecosystem.

The admin application must allow administrators to manage data, AI configurations, content, orders, products, reviews, and application UI settings.

**This must be a working application, not just a visual prototype.**

All primary navigation items, forms, buttons, filters, dialogs, tables, and interactive elements must function.

Use realistic mock data and local persistence. Do not require a real backend or AI service at this stage.

---

## 2. TECHNOLOGY STACK

Use:

- React + TypeScript + Vite.
- Tailwind CSS.
- shadcn/ui for reusable UI components.
- Lucide React for icons.
- React Router for routing.
- Recharts for charts and analytics.
- Framer Motion / Motion for React for animations.
- GSAP + ScrollTrigger only when necessary for advanced scroll-based motion.
- React Hook Form + Zod for forms and validation.
- localStorage for mock data persistence.

Architecture requirements:

- Use reusable components.
- Use a clear folder structure.
- Separate data, UI components, pages, and business logic.
- Implement reusable table, modal, form, card, badge, dropdown, and filter components.
- Provide loading, empty, error, and success states.
- Ensure responsive layouts for desktop, tablet, and mobile.
- Avoid unnecessary dependencies.

**Do not build a real backend.** Simulate operations using localStorage and mock services.

Keep the architecture ready for future integration with:

- Spring Boot REST API.
- Firestore.
- Python ONNX inference service.
- VNPay payment gateway.

---

## 3. DESIGN SYSTEM — STRICT VISUAL DIRECTION

### Design concept: Premium 2.5D Botanical Editorial Motion

The entire application must feel like a premium botanical editorial website combined with a sophisticated digital management workspace.

It should feel:

- Natural.
- Elegant.
- Warm.
- Contemporary.
- Artistic.
- Calm.
- Premium.
- Immersive.

### Absolutely do NOT use

- No 3D environment.
- No isometric illustrations.
- No 3D greenhouse.
- No game-like garden interface.
- No low-poly illustrations.
- No Blender scenes.
- No Three.js.
- No WebGL.
- No React Three Fiber.
- No GLB or FBX runtime scenes.
- No generic SaaS dashboard template.
- No permanent left sidebar.
- No excessive glassmorphism.
- No excessive rounded cards everywhere.
- No cartoon plant illustrations.

### 2.5D visual language

Use real botanical photography and layered image compositions.

Combine:

1. **Background layers:** soft botanical textures, subtle gradients, blurred foliage, and warm atmospheric backgrounds.
2. **Middle layers:** large plant photography, organic shapes, and decorative botanical elements.
3. **Foreground layers:** transparent PNG/WebP plant cutouts, leaves, flowers, and subtle shadows.

Create depth through:

- Layered compositions.
- Natural shadows.
- Scale differences.
- Overlapping images.
- Parallax.
- CSS transforms.
- Clip-path and mask reveals.

Do not simulate depth through 3D geometry.

### Color palette

Use this palette consistently:

| Role | Color | Hex |
|---|---|---|
| Warm ivory | Primary background | `#F6F4EC` |
| Soft sage | Soft surfaces | `#DCE5D5` |
| Botanical green | Highlights | `#91A582` |
| Forest green | Primary text/actions | `#284B36` |
| Terracotta | Restrained accent | `#C47E61` |

Avoid using saturated green everywhere.

### Typography

Suggested fonts:

- Headings: Playfair Display or Cormorant Garamond.
- Body: Inter or Manrope.
- Numbers and metrics: Manrope.

Use large expressive headlines, strong typographic hierarchy, generous whitespace, short descriptive text, and editorial asymmetric layouts.

Avoid making every title small and every section look like a dashboard card.

### Image assets

Prioritize:

- High-quality real plant photography.
- Transparent botanical PNG/WebP cutouts.
- Tropical leaves.
- Monstera.
- Philodendron.
- Calathea.
- Ficus.
- Pothos.
- Flowers and close-up foliage.

Possible asset sources:

- https://unsplash.com/s/photos/botanical-plants
- https://www.pexels.com/search/tropical%20plants/
- https://www.freepik.com/search?format=search&query=botanical%20plant%20transparent%20png

Do not use random low-quality illustrations as substitutes for botanical imagery.

Use available images from reliable sources or generate CSS-based decorative elements when assets are unavailable.

Organize assets in a clear `/public/assets/` directory.

---

## 4. MOTION DESIGN SYSTEM

Motion is a core part of Floria's visual identity. The interface should feel alive, but never distracting.

### A. Floating foliage

- Plant cutout images gently sway.
- Use subtle rotation and vertical translation.
- Different plant layers have slightly different motion timing.
- Animation should feel organic and slow.

### B. Multi-layer parallax

- Foreground foliage moves slightly faster than background.
- Hero plant elements respond subtly to pointer movement.
- Keep movement restrained.
- Disable pointer parallax on touch devices.

### C. Scroll-triggered animation

Use Framer Motion and optionally GSAP ScrollTrigger.

- Sections reveal progressively.
- Images use gentle scale and opacity transitions.
- Text appears with staggered animation.
- Botanical elements can move into position while scrolling.

### D. Organic image reveal

Use:

- clip-path.
- CSS masks.
- opacity.
- scale.
- translate.

Avoid generic rectangular fade-in animations for every section.

### E. Interaction motion

- Navigation hover transitions.
- Button hover feedback.
- Subtle card elevation.
- Smooth modal appearance.
- Elegant dropdown transitions.
- Page transition between workspaces.
- Animated charts and metrics.

### F. Performance and accessibility

- Respect `prefers-reduced-motion`.
- Avoid excessive animation loops.
- Use transform and opacity whenever possible.
- Avoid expensive layout recalculations.
- Ensure smooth performance on mid-range devices.
- No motion should block user interaction.

---

## 5. GLOBAL APPLICATION STRUCTURE

Create eight main modules:

1. **Overview** — Tổng quan hệ thống.
2. **AI Lab & Machine Learning** — Quản lý mô hình và dữ liệu AI.
3. **Floria Assistant & AI Guardrails** — Quản lý trợ lý và quy tắc AI.
4. **App & Web UI** — Remote UI Configuration.
5. **Plant & Disease Dictionary** — Từ điển cây trồng và bệnh.
6. **Order Management** — Quản lý đơn hàng.
7. **Shop & Reviews** — Sản phẩm và đánh giá.
8. **Homepage Content** — Quản lý nội dung trang chủ.

### Global navigation requirements

Do not use a permanent sidebar.

Build a minimal premium navigation system:

- Floria logo.
- Overview.
- Workspace navigation menu containing all eight modules.
- Current workspace title.
- Notification icon.
- Administrator profile menu.
- Breadcrumbs when appropriate.

Use a clean top navigation bar with subtle sticky behavior.

For workspace navigation, use a dropdown, mega menu, or elegant navigation panel.

On mobile, use a compact menu drawer.

Every workspace must have:

- A clear page title.
- A short description.
- A contextual action area.
- Consistent navigation.
- A clear way to return to Overview.

Keep management workspaces practical and information-dense where necessary. Do not force every page into an editorial landing-page layout.

---

## 6. MODULE 01 — OVERVIEW

This is the visual centerpiece of Floria Admin.

The Overview must feel like a premium botanical editorial homepage, not a conventional admin dashboard.

### Hero section

Create a large immersive hero section.

**Headline:**  
“A little greener, every day.”

**Supporting text:**  
“Your intelligent workspace for healthier plants and smarter care.”

Use:

- Large expressive typography.
- Real botanical photography.
- Transparent plant cutout images.
- Layered foliage.
- Organic compositions.
- Subtle floating animations.
- Pointer parallax.
- Natural shadows.
- Warm ivory background.

The hero should have a visually dominant plant composition on one side and typography on the other, with an editorial asymmetric layout.

Do not place every KPI inside the hero.

### Overview metrics

Below the hero, show:

- Total users.
- Total plant scans.
- Successful identification rate.
- Total orders.
- Total revenue.
- Active AI models.

Each metric should include:

- Current value.
- Change compared to previous period.
- Small visual indicator.
- Optional sparkline.

### Analytics section

Create charts using Recharts:

1. User growth over time.
2. Plant recognition activity.
3. Disease detection statistics.
4. Revenue overview.
5. Order status distribution.

Add date filters:

- Last 7 days.
- Last 30 days.
- Last 90 days.
- Custom date range.

Charts must respond to the selected time range using mock data.

### Recent activity

Display:

- Recent plant scans.
- Recent orders.
- Recent reviews.
- AI model events.
- Admin activity.

Use realistic mock data.

### System health

Show:

- AI model status.
- API simulation status.
- Database mock status.
- Storage usage.
- Last synchronization.

Make clear that all statuses are simulated in this prototype.

---

## 7. MODULE 02 — AI LAB & MACHINE LEARNING

This workspace manages Floria's machine learning models and simulated inference workflow.

### A. Model management

Create model cards for:

#### Plant Species Classification

- Model: `tf_efficientnetv2_b0.onnx`
- Classes: 40 plant species
- Accuracy: 90.0%
- Performance: approximately 438 FPS

#### Plant Disease Classification

- Model: `tf_efficientnetv2_b0_disease.onnx`
- Classes: 5 disease classes
- Accuracy: 92.5%
- Performance: approximately 106 FPS

#### CLIP Gatekeeper

- Checks whether uploaded images are relevant to plants.
- Rejects irrelevant or unsupported images.

Each model must support:

- View details.
- Edit metadata.
- Enable/disable.
- Change model version.
- View performance metrics.
- View inference history.
- Simulate model deployment.
- View deployment status.

Do not claim actual model deployment or inference.

### B. AI Sandbox

Build an interactive image inference sandbox.

Features:

1. Drag-and-drop image upload.
2. Image preview.
3. Remove or replace uploaded image.
4. Simulate CLIP Gatekeeper validation.
5. Simulate plant species classification.
6. Simulate disease classification.
7. Show inference latency.
8. Show Top-3 predictions.
9. Show confidence percentages.
10. Display a result summary.

Example simulated output:

- Predicted plant: Monstera deliciosa.
- Confidence: 96.4%.
- Disease: Leaf spot.
- Confidence: 88.2%.
- Inference latency: 124ms.

The results must be generated using mock logic.

Display a clear disclaimer:

**“Kết quả mô phỏng — Chưa kết nối AI Backend.”**

Never imply that real ONNX models have been executed.

### C. Active Learning

Create a dataset review interface for low-confidence predictions.

Default threshold: below 65%.

Display:

- Image thumbnail.
- Scan ID.
- Predicted plant.
- Predicted disease.
- Confidence.
- Date.
- Review status.

Admin actions:

- Open image.
- Change predicted label.
- Select correct species.
- Select correct disease.
- Confirm relabel.
- Mark as reviewed.
- Reject invalid sample.

Add filters:

- Low confidence.
- Unreviewed.
- Reviewed.
- Species.
- Disease.
- Date range.

Persist edits in localStorage.

### D. Model analytics

Show:

- Accuracy trend.
- Inference latency.
- Prediction distribution.
- Confidence distribution.
- Number of processed scans.
- Error rate.

Use mock data and charts.

---

## 8. MODULE 03 — FLORIA ASSISTANT & AI GUARDRAILS

This module manages the AI chatbot's behavior and safety rules.

### A. Assistant settings

Create settings for:

- Assistant name.
- Welcome message.
- Assistant tone.
- Response length.
- Language.
- Personality.
- Plant-care guidance behavior.
- Product recommendation behavior.

Suggested tone presets:

- Friendly expert.
- Professional botanist.
- Simple and beginner-friendly.

Allow editing and saving.

### B. AI Guardrails

Create editable rule management.

Rule categories:

1. Domain restrictions.
2. Plant-related questions.
3. Disease diagnosis limitations.
4. Medical and dangerous advice restrictions.
5. Product recommendation rules.
6. User privacy.
7. Unsupported topics.
8. Response formatting.

Include special response tags:

- `[RECOMMEND_PRODUCT]`
- `[CARE_SCHEDULE]`

The admin can configure:

- When the assistant may recommend a product.
- When the assistant should provide a care schedule.
- How the assistant should handle uncertain plant diagnoses.
- When the assistant must ask for a better image.
- When the assistant should refuse an unsupported request.

### C. Blocked topics

Allow administrators to:

- Add blocked topics.
- Edit blocked topics.
- Remove blocked topics.
- Enable or disable individual restrictions.

### D. Assistant testing sandbox

Create a test chat interface.

Administrators can enter a sample user message and see a simulated assistant response.

Show:

- Input message.
- Matched guardrail rules.
- Detected intent.
- Simulated response.
- Triggered tags.
- Safety status.

Clearly label the entire sandbox as simulated.

---

## 9. MODULE 04 — APP & WEB UI (REMOTE UI CONFIG)

This module manages the UI configuration of Floria's mobile app and website.

It must simulate a Remote UI Configuration system.

### A. Theme management

Create theme presets:

- Botanical Light.
- Forest Green.
- Warm Earth.
- Minimal Ivory.

Allow editing:

- Primary color.
- Secondary color.
- Background.
- Accent color.
- Typography.
- Border radius.

### B. Homepage section management

Create a reorderable list of mobile app homepage sections.

Example sections:

- Welcome Banner.
- Search Plant.
- AI Plant Scanner.
- Featured Plants.
- Plant Care Tips.
- Seasonal Recommendations.
- Shop Products.
- Recent Activity.

Admin can:

- Add section.
- Remove section.
- Enable/disable.
- Reorder using drag-and-drop.
- Edit title.
- Edit subtitle.
- Configure section content.

### C. Banner management

Features:

- Create banner.
- Upload image.
- Edit title and description.
- Set call-to-action.
- Configure destination.
- Set active period.
- Enable/disable.

### D. Feature flags

Create toggles for:

- AI Plant Scanner.
- Disease Detection.
- AI Assistant.
- Product Shop.
- Weather Widget.
- Plant Care Reminder.
- Community Features.

### E. Mobile preview

Build a realistic mobile phone preview.

The preview must update in real time when the admin changes:

- Theme.
- Homepage sections.
- Banner.
- Feature flags.

Include:

- Save draft.
- Preview.
- Publish.

Publishing must show a confirmation dialog and update local mock state only.

Display:

**“Local preview only — chưa đồng bộ lên ứng dụng thật.”**

---

## 10. MODULE 05 — PLANT & DISEASE DICTIONARY

Build a complete knowledge database.

### A. Plant database

Seed at least 40 realistic plant records.

Each plant should include:

- ID.
- Vietnamese name.
- English name.
- Scientific name.
- Category.
- Description.
- Plant image.
- Light requirements.
- Watering requirements.
- Temperature range.
- Humidity.
- Soil type.
- Difficulty level.
- Common problems.
- Care instructions.
- Active status.

Use realistic plant examples:

- Monstera deliciosa.
- Epipremnum aureum.
- Ficus elastica.
- Calathea orbifolia.
- Philodendron hederaceum.
- Sansevieria trifasciata.
- Spathiphyllum.
- Aloe vera.
- Dracaena.
- Peace Lily.

Continue until there are at least 40 records.

### B. Disease database

Seed at least 5 disease groups.

Each disease should include:

- Vietnamese name.
- English name.
- Symptoms.
- Causes.
- Visual signs.
- Prevention.
- Treatment guidance.
- Affected plant types.
- Reference images.
- Severity.
- Active status.

Use common examples such as:

- Leaf spot.
- Powdery mildew.
- Root rot.
- Rust.
- Bacterial leaf blight.

### C. CRUD functionality

Implement:

- Create plant.
- Edit plant.
- Delete plant.
- Create disease.
- Edit disease.
- Delete disease.
- Search.
- Filter.
- Sort.
- Pagination.
- Detail view.

Use image upload preview and form validation.

Add confirmation before destructive actions.

Persist all changes in localStorage.

---

## 11. MODULE 06 — ORDER MANAGEMENT

Create a complete order management workspace.

### A. Order overview

Show:

- Total orders.
- Pending orders.
- Confirmed orders.
- Shipping orders.
- Delivered orders.
- Cancelled orders.
- Total revenue.

### B. Order table

Columns:

- Order ID.
- Customer.
- Date.
- Products.
- Total amount.
- Payment method.
- Payment status.
- Shipping status.
- Actions.

Payment methods:

- COD.
- VNPay.

### C. Order details

Clicking an order opens a detailed view with:

- Customer information.
- Shipping address.
- Contact information.
- Order items.
- Quantity.
- Price.
- Discount.
- Shipping fee.
- Total amount.
- Payment method.
- Payment status.
- Order timeline.
- Admin notes.

### D. Order workflow

Support statuses:

1. Pending.
2. Confirmed.
3. Processing.
4. Shipping.
5. Delivered.
6. Cancelled.

Allow administrators to update status.

Show a confirmation dialog for important transitions.

Record status changes in an order timeline.

### E. Filtering and search

- Search order ID.
- Search customer.
- Filter by order status.
- Filter by payment method.
- Filter by date.
- Filter by payment status.

Use realistic mock orders.

---

## 12. MODULE 07 — SHOP & REVIEWS

Manage products and customer reviews.

### A. Product management

Create product records with:

- Product image.
- Product name.
- SKU.
- Category.
- Description.
- Price.
- Original price.
- Stock.
- Sold quantity.
- Rating.
- Product status.

Product categories:

- Fertilizers.
- Soil and growing media.
- Plant pots.
- Gardening tools.
- Pest control.
- Plant-care products.

Admin actions:

- Create product.
- Edit product.
- Delete product.
- Upload product image.
- Update inventory.
- Change product status.
- Search and filter.

### B. Review management

Show:

- Customer name.
- Product.
- Rating.
- Review content.
- Review date.
- Moderation status.

Moderation actions:

- Approve.
- Hide.
- Reject.
- Delete.

Include filters:

- Rating.
- Product.
- Status.
- Date.

Add a review detail modal.

Persist moderation changes in localStorage.

---

## 13. MODULE 08 — HOMEPAGE CONTENT

This module manages the content displayed on the Floria website and app homepage.

### A. Article management

Create a content management interface.

Each article should include:

- Title.
- Slug.
- Cover image.
- Summary.
- Content.
- Category.
- Author.
- Publication date.
- Status.
- SEO title.
- SEO description.

Article statuses:

- Draft.
- Published.
- Scheduled.
- Archived.

### B. Rich content editor

Create a simple block-based editor.

Support:

- Heading.
- Paragraph.
- Image.
- Quote.
- Bullet list.
- Numbered list.
- Callout.
- Divider.

Allow:

- Add block.
- Edit block.
- Remove block.
- Reorder blocks.
- Preview article.

### C. Homepage content sections

Manage:

- Hero content.
- Featured articles.
- Plant of the week.
- Plant-care tips.
- Seasonal content.
- Promotional banners.
- Featured products.

### D. Weather content widget

Create a configurable weather content widget.

Allow administrators to configure:

- Widget title.
- Location label.
- Description.
- Display status.
- Weather-related plant-care tips.

Use mock weather data only.

Do not claim real-time weather integration.

---

## 14. MOCK DATA & PERSISTENCE

Create realistic initial data for every module.

Use a centralized mock data layer.

Requirements:

- Store editable records in localStorage.
- Seed default records on first launch.
- Do not overwrite user changes on subsequent visits.
- Add reset demo data functionality.
- Add confirmation before resetting.
- Use realistic Vietnamese customer names and addresses.
- Use VND currency formatting.
- Use Vietnamese UI language by default.

The application should support realistic workflows even without a backend.

Examples:

- Create a product and see it in the product table.
- Edit a plant and see the updated detail.
- Change an order status and see the timeline update.
- Approve a review and see the new status.
- Change a UI theme and see the mobile preview update.
- Modify a guardrail and see it reflected in the test sandbox.

---

## 15. LANGUAGE & CONTENT

Default interface language: **Vietnamese**.

Use English only where it improves product terminology, model names, or technical labels.

Use consistent Vietnamese wording.

Suggested navigation labels:

- Tổng quan.
- Phòng thí nghiệm AI.
- Trợ lý Floria.
- Cấu hình giao diện.
- Từ điển cây trồng.
- Quản lý đơn hàng.
- Sản phẩm & đánh giá.
- Quản lý nội dung.

Formatting:

- Currency: VND.
- Dates: DD/MM/YYYY.
- Time: 24-hour format.
- Percentages: standard percentage format.

Use realistic content. Avoid lorem ipsum.

---

## 16. UX REQUIREMENTS

Every page must have a clear hierarchy.

Every workspace must include:

- Page title.
- Description.
- Main action.
- Search and filter where applicable.
- Useful empty state.
- Loading state where appropriate.
- Error feedback.
- Success toast.

Forms must:

- Validate required fields.
- Display clear error messages.
- Support cancel.
- Support save.
- Prevent accidental data loss when appropriate.

Tables must:

- Support pagination.
- Support sorting where relevant.
- Support filtering.
- Support search.
- Have responsive behavior.

Dialogs must:

- Be accessible.
- Support Escape to close.
- Have clear actions.
- Avoid accidental destructive actions.

Do not use buttons that do nothing.

If a feature is simulated, label it clearly.

---

## 17. RESPONSIVE DESIGN

### Desktop

- Full editorial layout.
- Spacious typography.
- Layered botanical hero.
- Practical workspace tables and charts.

### Tablet

- Simplified compositions.
- Reduced parallax.
- Responsive grid layouts.

### Mobile

- Compact navigation drawer.
- Single-column workspace layout.
- Scrollable tables or mobile-friendly record cards.
- Touch-friendly controls.
- Disable pointer-based parallax.
- Reduce decorative animation.

The application must remain fully usable on all screen sizes.

---

## 18. IMPLEMENTATION ORDER

Build the application in the following order.

Do not stop after creating the Overview.

### Phase 1 — Foundation

- Design system.
- Typography.
- Color palette.
- Navigation.
- Routing.
- Reusable components.
- Mock data and localStorage architecture.

### Phase 2 — Overview

- Editorial botanical hero.
- Motion system.
- KPI metrics.
- Analytics.
- Activity.
- System health.

### Phase 3 — AI workspaces

- AI Lab.
- Model management.
- AI Sandbox.
- Active Learning.
- Floria Assistant.
- Guardrails.

### Phase 4 — Application management

- Remote UI Configuration.
- Mobile preview.
- Theme management.
- Feature flags.

### Phase 5 — Knowledge and commerce

- Plant dictionary.
- Disease dictionary.
- Order management.
- Product management.
- Reviews.

### Phase 6 — Content and final polish

- Homepage content.
- Article editor.
- Final interactions.
- Responsive optimization.
- QA.

Build all phases. If implementation requires multiple iterations, preserve the existing architecture and continue from the current state rather than replacing working features.

---

## 19. QUALITY ASSURANCE CHECKLIST

Before considering the project complete, verify:

- [ ] All 8 modules are accessible.
- [ ] Navigation works correctly.
- [ ] Overview has a distinctive 2.5D botanical editorial design.
- [ ] No 3D, isometric, or game-like visual elements.
- [ ] Botanical motion works smoothly.
- [ ] Reduced motion is respected.
- [ ] All charts render.
- [ ] Date filters work.
- [ ] AI Sandbox accepts image uploads.
- [ ] AI results are clearly marked as simulated.
- [ ] Active Learning supports relabeling.
- [ ] Assistant settings can be edited.
- [ ] Guardrails can be managed.
- [ ] Guardrail sandbox works.
- [ ] Remote UI Configuration works.
- [ ] Mobile preview updates correctly.
- [ ] Plant CRUD works.
- [ ] Disease CRUD works.
- [ ] Order status updates work.
- [ ] Product CRUD works.
- [ ] Review moderation works.
- [ ] Article editor works.
- [ ] localStorage persistence works.
- [ ] Reset demo data works.
- [ ] No dead buttons.
- [ ] No broken routes.
- [ ] No console errors.
- [ ] Responsive layouts work.

---

## 20. FINAL CREATIVE DIRECTION

The most important principle:

**Floria must feel like a premium botanical digital product, not an ordinary admin template.**

The Overview should make users feel like they are entering a beautifully curated botanical workspace.

The other modules should maintain the same visual identity while prioritizing usability and information clarity.

Use a balance of:

- 60% functional workspace.
- 25% editorial visual identity.
- 15% motion and interaction details.

The design must be beautiful but practical.

Do not sacrifice usability for decoration.

Do not replace real botanical photography with cartoon illustrations.

Do not turn the application into a 3D greenhouse.

Build a complete, polished, coherent, and functional Floria Admin experience.

**Start building the complete application now.**

---

# FOLLOW-UP PROMPTS FOR LOVABLE

Use these prompts after the initial project generation to audit and improve the result.

## Prompt 1 — Foundation and visual direction audit

```text
Review the entire Floria Admin project against the master specification.

Focus on the global design system, navigation, routing, responsive layouts, and the 2.5D Botanical Editorial Motion visual direction.

Do not use 3D, isometric, or generic SaaS dashboard patterns.

Fix inconsistencies before proceeding. Do not remove existing working functionality.
```

## Prompt 2 — Functional completeness audit

```text
Audit all 8 Floria Admin modules against the original master specification.

Identify missing features, incomplete CRUD operations, non-functional buttons, broken filters, missing validation, and localStorage persistence issues.

Implement all missing functionality. Do not replace working modules with static mockup screens.
```

## Prompt 3 — Premium visual polish

```text
Perform a premium visual polish pass across the entire Floria Admin application.

Improve botanical photography, transparent plant cutouts, layered 2.5D compositions, typography, whitespace, natural shadows, motion transitions, and responsive behavior.

Make the Overview visually distinctive while keeping all management workspaces practical and information-dense.

Do not introduce 3D, isometric scenes, game-like UI, or a permanent sidebar.
```

---

## IMPLEMENTATION NOTE

All AI inference, model deployment, payment processing, weather information, and remote UI publishing are **simulated in this prototype**. Do not display them as real integrations.

The project must be structured so these services can be integrated later, but the current version must be fully usable with mock data and localStorage.
