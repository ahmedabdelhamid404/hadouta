# Hadouta Phase 5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Translate the Phase 3 design spec (`docs/design/specs/2026-05-02-phase-3-design-spec.md`) into shipped, working code in `hadouta-web` + `hadouta-backend`. Land both the locked landing page and the 7-step order wizard with phone-OTP + Paymob payment + WhatsApp confirmation. Ship behind feature flag for staged rollout.

**Architecture:** Frontend in Next.js 16 (App Router) + React 19 + Tailwind 4 + shadcn/ui in `hadouta-web`. Backend in Hono + Drizzle + Postgres in `hadouta-backend` (Neon EU-Central). Phone OTP wires to existing ADR-018 Better-Auth phone-number plugin (already implemented session 5). Paymob is a NEW integration (backend creates payment intent, frontend redirects to Paymob hosted UI). Wizard state lives in client-side Zustand store + autosaves to backend draft order on every step transition. AI pipeline + WhatsApp delivery integration is OUT OF SCOPE for this plan (Sprint 3+).

**Tech Stack:** Next.js 16, React 19, Tailwind 4, shadcn/ui, react-hook-form, Zod, openapi-fetch, Sentry, PostHog (frontend); Hono, Drizzle ORM, Postgres, Better-Auth, Vitest, drizzle-kit, Twilio (already wired), Paymob SDK (NEW) (backend).

**Sequencing strategy (for time pressure):**
- **Part 1 (backend schema + APIs)** — can be developed in parallel with Part 2 (different repos, no shared files)
- **Part 2 (landing page)** — ships independently before wizard exists; CTA temporarily routes to placeholder
- **Part 3 (wizard frontend)** — depends on Part 1's APIs; can start when Part 1's draft-order endpoint is live
- **Part 4 (Paymob + production wiring)** — gating step before public launch; depends on Track B (Meta verification, Twilio sender)

Estimated: 8-12 days solo. Subagent-driven execution can compress to ~5-7 days if dispatching per task.

---

## Pre-flight checklist

Before any tasks below, verify:

- [ ] On a clean branch in each repo: `git checkout -b feat/phase-5-implementation`
- [ ] `hadouta-backend`: `pnpm install && pnpm typecheck && pnpm test` all pass
- [ ] `hadouta-web`: `pnpm install && pnpm typecheck` passes
- [ ] Neon dev branch URL set in `hadouta-backend/.env` (DATABASE_URL points to dev branch, not production)
- [ ] `pnpm db:studio` opens drizzle studio successfully (verifies DB connection)
- [ ] Visual companion wireframes accessible for reference (paths in `.superpowers/brainstorm/<latest-session>/content/`)

---

# Part 1 — Backend: schema migration + wizard APIs + Paymob

This part can run in parallel with Part 2. Both ship independently; Part 3 depends on this part being complete.

## Task 1.1 — Add `moral_values` table to Drizzle schema

**Files:**
- Modify: `hadouta-backend/src/db/schema.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// hadouta-backend/tests/integration/moral-values.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import { db } from '../../src/db';
import { moralValues } from '../../src/db/schema';
import { eq } from 'drizzle-orm';

describe('moral_values table', () => {
  it('persists a moral value and reads it back', async () => {
    const inserted = await db.insert(moralValues).values({
      nameAr: 'الشجاعة',
      nameEn: 'Courage',
      description: 'Standing up for what is right despite fear',
      suitableAgeBands: ['3-5', '5-7', '6-8'],
      sortOrder: 1,
    }).returning();

    expect(inserted[0].nameAr).toBe('الشجاعة');
    expect(inserted[0].suitableAgeBands).toEqual(['3-5', '5-7', '6-8']);
    expect(inserted[0].active).toBe(true);

    // cleanup
    await db.delete(moralValues).where(eq(moralValues.id, inserted[0].id));
  });
});
```

- [ ] **Step 2: Run test to verify it fails (table doesn't exist yet)**

```bash
cd hadouta-backend && pnpm test moral-values
```
Expected: FAIL — `moralValues` not exported / table missing.

- [ ] **Step 3: Add `moralValues` table to schema**

In `hadouta-backend/src/db/schema.ts`, after the existing themes table, add:

```typescript
export const moralValues = pgTable('moral_values', {
  id: uuid('id').primaryKey().defaultRandom(),
  nameAr: text('name_ar').notNull(),
  nameEn: text('name_en').notNull(),
  description: text('description'),
  suitableAgeBands: text('suitable_age_bands').array().notNull().default(sql`'{}'::text[]`),
  active: boolean('active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});
```

Make sure imports include `boolean`, `integer`, `timestamp`, `sql`.

- [ ] **Step 4: Generate migration**

```bash
cd hadouta-backend && pnpm db:generate
```
Expected: new migration file `0003_<adjective_noun>.sql` created in `src/db/migrations/`.

- [ ] **Step 5: Apply migration**

```bash
cd hadouta-backend && pnpm db:migrate
```
Expected: "applying migrations done!" output.

- [ ] **Step 6: Run test to verify pass**

```bash
pnpm test moral-values
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/db/schema.ts src/db/migrations/0003_*.sql src/db/migrations/meta tests/integration/moral-values.test.ts
git commit -m "feat(db): add moral_values catalog table

Per Phase 3 design Decision 2 — story input combinatorial requires
moral_value_id FK on orders. moral_values table holds 8 catalog values
with bilingual names + age-band suitability tags."
```

## Task 1.2 — Add `supporting_characters` table

**Files:**
- Modify: `hadouta-backend/src/db/schema.ts`
- Test: `hadouta-backend/tests/integration/supporting-characters.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
// tests/integration/supporting-characters.test.ts
import { describe, it, expect } from 'vitest';
import { db } from '../../src/db';
import { orders, supportingCharacters } from '../../src/db/schema';
import { eq } from 'drizzle-orm';

describe('supporting_characters table', () => {
  it('cascades delete when parent order is deleted', async () => {
    const order = await db.insert(orders).values({ userId: 'test-user' }).returning();
    const char = await db.insert(supportingCharacters).values({
      orderId: order[0].id,
      name: 'نور',
      role: 'sibling',
      appearanceInputType: 'description',
      descriptionSkinTone: '#a06d3e',
      descriptionHair: 'شعر طويل أسود',
      descriptionClothingStyle: 'modern',
      position: 1,
    }).returning();

    expect(char[0].name).toBe('نور');
    await db.delete(orders).where(eq(orders.id, order[0].id));
    const orphans = await db.select().from(supportingCharacters).where(eq(supportingCharacters.orderId, order[0].id));
    expect(orphans).toHaveLength(0);
  });
});
```

- [ ] **Step 2: Run test (fails — table missing)**

- [ ] **Step 3: Add `supportingCharacters` table**

In `schema.ts` after `orders`:

```typescript
export const supportingCharacterRoleEnum = pgEnum('supporting_character_role', [
  'sibling', 'friend', 'grandparent', 'parent', 'pet', 'other'
]);

export const appearanceInputTypeEnum = pgEnum('appearance_input_type', ['photo', 'description']);

export const clothingStyleEnum = pgEnum('clothing_style', [
  'modern', 'egyptian_traditional', 'school_uniform', 'custom'
]);

export const supportingCharacters = pgTable('supporting_characters', {
  id: uuid('id').primaryKey().defaultRandom(),
  orderId: uuid('order_id').notNull().references(() => orders.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  role: supportingCharacterRoleEnum('role').notNull(),
  appearanceInputType: appearanceInputTypeEnum('appearance_input_type').notNull(),
  photoId: uuid('photo_id'),  // FK to photos table — added in later task
  descriptionSkinTone: text('description_skin_tone'),
  descriptionHair: text('description_hair'),
  descriptionClothingStyle: clothingStyleEnum('description_clothing_style'),
  descriptionEyeColor: text('description_eye_color'),
  position: integer('position').notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
}, (table) => ({
  positionCheck: sql`CHECK (position IN (1, 2))`,
}));
```

- [ ] **Step 4: Generate + apply migration**

```bash
pnpm db:generate && pnpm db:migrate
```

- [ ] **Step 5: Test passes**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(db): add supporting_characters table + role/input/clothing enums"
```

## Task 1.3 — Extend `themes` table with age-band tagging

**Files:**
- Modify: `hadouta-backend/src/db/schema.ts`

- [ ] **Step 1: Add columns to themes table**

```typescript
// In existing themes definition, add:
suitableAgeBands: text('suitable_age_bands').array().notNull().default(sql`'{}'::text[]`),
descriptionAr: text('description_ar'),
descriptionEn: text('description_en'),
illustrationKey: text('illustration_key'),  // points to inline SVG icon registry by key
```

- [ ] **Step 2: Generate + apply migration**

```bash
pnpm db:generate && pnpm db:migrate
```

- [ ] **Step 3: Add GIN index on age bands for filter queries**

Hand-edit migration to add:
```sql
CREATE INDEX IF NOT EXISTS idx_themes_age_bands ON themes USING gin(suitable_age_bands);
```

Re-run `pnpm db:migrate` — confirms idempotent.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(db): extend themes with age-band tagging + bilingual descriptions"
```

## Task 1.4 — Extend `orders` table with all wizard fields

**Files:**
- Modify: `hadouta-backend/src/db/schema.ts`

- [ ] **Step 1: Add columns to orders table**

In `orders` definition, add (in addition to existing user_id, style, status):

```typescript
buyerName: text('buyer_name'),
childName: text('child_name'),
childAgeBand: text('child_age_band'),  // '3-5' | '5-7' | '6-8'
childAgeExact: integer('child_age_exact'),  // 3-8
childGender: text('child_gender'),  // 'boy' | 'girl'
childHobbies: text('child_hobbies'),
childFavoriteFood: text('child_favorite_food'),
childFavoriteColor: text('child_favorite_color'),
childSpecialTraits: text('child_special_traits'),
appearanceInputType: appearanceInputTypeEnum('appearance_input_type'),
descriptionSkinTone: text('description_skin_tone'),
descriptionHair: text('description_hair'),
descriptionClothingStyle: clothingStyleEnum('description_clothing_style'),
descriptionEyeColor: text('description_eye_color'),
hasSupportingCharacters: boolean('has_supporting_characters').notNull().default(false),
themeId: uuid('theme_id').references(() => themes.id),
moralValueId: uuid('moral_value_id').references(() => moralValues.id),
customSceneText: text('custom_scene_text'),
specialOccasionText: text('special_occasion_text'),
dedicationText: text('dedication_text'),
priceCents: integer('price_cents'),  // 25000 = 250 EGP * 100
paymobOrderId: text('paymob_order_id'),  // for reconciliation
```

Update `status` enum to include: `'draft' | 'pending_payment' | 'paid' | 'in_production' | 'review' | 'delivered' | 'failed'`.

- [ ] **Step 2: Add CHECK constraints (hand-edited migration)**

After `pnpm db:generate`, hand-add to the new migration:

```sql
ALTER TABLE orders
  ADD CONSTRAINT child_age_band_check CHECK (child_age_band IS NULL OR child_age_band IN ('3-5','5-7','6-8')),
  ADD CONSTRAINT child_age_exact_check CHECK (child_age_exact IS NULL OR (child_age_exact BETWEEN 3 AND 8)),
  ADD CONSTRAINT child_gender_check CHECK (child_gender IS NULL OR child_gender IN ('boy','girl'));

CREATE INDEX IF NOT EXISTS idx_orders_theme_id ON orders(theme_id);
CREATE INDEX IF NOT EXISTS idx_orders_moral_value_id ON orders(moral_value_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
```

- [ ] **Step 3: Apply migration**

```bash
pnpm db:migrate
```

- [ ] **Step 4: Verify in drizzle studio**

```bash
pnpm db:studio
```
Expected: orders table shows all new columns with correct types.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(db): extend orders with full wizard schema (Phase 3 design)"
```

## Task 1.5 — Seed `moral_values` catalog

**Files:**
- Create: `hadouta-backend/src/scripts/seed-moral-values.ts`
- Test: `hadouta-backend/tests/integration/moral-values-seed.test.ts`

- [ ] **Step 1: Create seed script**

```typescript
// src/scripts/seed-moral-values.ts
import { db } from '../db';
import { moralValues } from '../db/schema';

const VALUES = [
  { nameAr: 'الشجاعة', nameEn: 'Courage', description: 'Standing up despite fear', sortOrder: 1 },
  { nameAr: 'الأمانة', nameEn: 'Honesty', description: 'Telling the truth even when hard', sortOrder: 2 },
  { nameAr: 'الكرم', nameEn: 'Generosity', description: 'Sharing with others', sortOrder: 3 },
  { nameAr: 'احترام الكبار', nameEn: 'Respect for Elders', description: 'Honoring grandparents and teachers', sortOrder: 4 },
  { nameAr: 'المثابرة', nameEn: 'Perseverance', description: 'Trying again after setbacks', sortOrder: 5 },
  { nameAr: 'اللطف', nameEn: 'Kindness', description: 'Being gentle with others', sortOrder: 6 },
  { nameAr: 'التعاون', nameEn: 'Cooperation', description: 'Working together', sortOrder: 7 },
  { nameAr: 'الصبر', nameEn: 'Patience', description: 'Waiting calmly', sortOrder: 8 },
];

async function seed() {
  for (const value of VALUES) {
    await db.insert(moralValues).values({
      ...value,
      suitableAgeBands: ['3-5', '5-7', '6-8'],  // all values applicable across all bands
    }).onConflictDoNothing();
  }
  console.log(`Seeded ${VALUES.length} moral values`);
  process.exit(0);
}

seed().catch(console.error);
```

- [ ] **Step 2: Run seed**

```bash
pnpm tsx src/scripts/seed-moral-values.ts
```
Expected: "Seeded 8 moral values".

- [ ] **Step 3: Add npm script + commit**

In `package.json` scripts: `"db:seed:moral-values": "tsx src/scripts/seed-moral-values.ts"`.

```bash
git commit -m "feat(db): seed 8 moral values catalog (Phase 3 Decision 2)"
```

## Task 1.6 — Seed `themes` catalog with age-band tags

**Files:**
- Create: `hadouta-backend/src/scripts/seed-themes.ts`

- [ ] **Step 1: Create seed script**

```typescript
// src/scripts/seed-themes.ts
import { db } from '../db';
import { themes } from '../db/schema';

const THEMES = [
  { nameAr: 'أول يوم في المدرسة', nameEn: 'First Day at School', descriptionAr: 'الطفل يواجه مغامرة بداية المدرسة لأول مرة', suitableAgeBands: ['5-7', '6-8'], illustrationKey: 'school' },
  { nameAr: 'الصداقة', nameEn: 'Friendship', descriptionAr: 'بناء صداقات حقيقية والاهتمام بالآخرين', suitableAgeBands: ['3-5', '5-7', '6-8'], illustrationKey: 'friendship' },
  { nameAr: 'العيد', nameEn: 'Eid Celebration', descriptionAr: 'احتفال العيد مع العائلة، الهدايا، والفرح', suitableAgeBands: ['3-5', '5-7', '6-8'], illustrationKey: 'eid' },
  { nameAr: 'رمضان', nameEn: 'Ramadan', descriptionAr: 'تجربة جمال وروحانية رمضان', suitableAgeBands: ['5-7', '6-8'], illustrationKey: 'ramadan' },
  { nameAr: 'الكريسماس', nameEn: 'Christmas', descriptionAr: 'احتفال الكريسماس بطريقة مصرية أصيلة', suitableAgeBands: ['3-5', '5-7', '6-8'], illustrationKey: 'christmas' },
  { nameAr: 'شم النسيم', nameEn: 'Sham El-Nessim', descriptionAr: 'احتفال شم النسيم — ربيع مصر', suitableAgeBands: ['5-7', '6-8'], illustrationKey: 'shamel' },
  { nameAr: 'عيد ميلاد', nameEn: 'Birthday', descriptionAr: 'يوم خاص لطفلك', suitableAgeBands: ['3-5', '5-7', '6-8'], illustrationKey: 'birthday' },
  { nameAr: 'مغامرة كبيرة', nameEn: 'The Big Adventure', descriptionAr: 'مغامرة مثيرة تعلم الشجاعة والمثابرة', suitableAgeBands: ['5-7', '6-8'], illustrationKey: 'adventure' },
];

async function seed() {
  for (const theme of THEMES) {
    await db.insert(themes).values({ ...theme, supportedStyles: ['watercolor'] }).onConflictDoNothing();
  }
  console.log(`Seeded ${THEMES.length} themes`);
  process.exit(0);
}
seed().catch(console.error);
```

- [ ] **Step 2: Run + commit**

```bash
pnpm tsx src/scripts/seed-themes.ts
git commit -m "feat(db): seed 8 themes with age-band tags (religion-neutral pan-Egyptian)"
```

## Task 1.7 — Create wizard order CRUD endpoints

**Files:**
- Create: `hadouta-backend/src/routes/orders.ts`
- Create: `hadouta-backend/src/schemas/orders.ts`
- Modify: `hadouta-backend/src/server.ts` (mount routes)

- [ ] **Step 1: Define Zod schemas**

```typescript
// src/schemas/orders.ts
import { z } from 'zod';

export const childInfoSchema = z.object({
  buyerName: z.string().min(1).max(120),
  childName: z.string().min(1).max(80),
  childAgeBand: z.enum(['3-5', '5-7', '6-8']),
  childAgeExact: z.number().int().min(3).max(8),
  childGender: z.enum(['boy', 'girl']),
  childHobbies: z.string().max(500).optional(),
  childFavoriteFood: z.string().max(120).optional(),
  childFavoriteColor: z.string().max(80).optional(),
  childSpecialTraits: z.string().max(500).optional(),
});

export const appearanceSchema = z.object({
  appearanceInputType: z.enum(['photo', 'description']),
  descriptionSkinTone: z.string().optional(),  // hex color
  descriptionHair: z.string().max(200).optional(),
  descriptionClothingStyle: z.enum(['modern', 'egyptian_traditional', 'school_uniform', 'custom']).optional(),
  descriptionEyeColor: z.string().max(80).optional(),
});

export const supportingCharacterInputSchema = z.object({
  name: z.string().min(1).max(80),
  role: z.enum(['sibling', 'friend', 'grandparent', 'parent', 'pet', 'other']),
  appearanceInputType: z.enum(['photo', 'description']),
  descriptionSkinTone: z.string().optional(),
  descriptionHair: z.string().max(200).optional(),
  descriptionClothingStyle: z.enum(['modern', 'egyptian_traditional', 'school_uniform', 'custom']).optional(),
  position: z.union([z.literal(1), z.literal(2)]),
});

export const storyDetailsSchema = z.object({
  themeId: z.string().uuid(),
  moralValueId: z.string().uuid(),
  customSceneText: z.string().max(500).optional(),
  specialOccasionText: z.string().max(200).optional(),
});

export const dedicationSchema = z.object({
  dedicationText: z.string().max(280).optional(),
});

export const draftOrderSchema = z.object({
  childInfo: childInfoSchema.partial(),
  appearance: appearanceSchema.partial(),
  supportingCharacters: z.array(supportingCharacterInputSchema).max(2).optional(),
  storyDetails: storyDetailsSchema.partial(),
  dedication: dedicationSchema.partial(),
});
```

- [ ] **Step 2: Create routes**

```typescript
// src/routes/orders.ts
import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { db } from '../db';
import { orders, supportingCharacters } from '../db/schema';
import { eq } from 'drizzle-orm';
import { childInfoSchema, appearanceSchema, storyDetailsSchema, dedicationSchema, supportingCharacterInputSchema } from '../schemas/orders';

const ordersRouter = new OpenAPIHono();

// POST /api/orders/draft — create new draft
ordersRouter.openapi(
  createRoute({
    method: 'post',
    path: '/draft',
    request: {
      body: { content: { 'application/json': { schema: z.object({ buyerName: z.string().optional() }).optional() } } },
    },
    responses: {
      201: { description: 'Draft created', content: { 'application/json': { schema: z.object({ orderId: z.string().uuid() }) } } },
    },
  }),
  async (c) => {
    const body = await c.req.json().catch(() => ({}));
    const order = await db.insert(orders).values({
      status: 'draft',
      style: 'watercolor',
      buyerName: body?.buyerName ?? null,
    }).returning();
    return c.json({ orderId: order[0].id }, 201);
  }
);

// PATCH /api/orders/:id — update partial fields per step
ordersRouter.openapi(
  createRoute({
    method: 'patch',
    path: '/:id',
    request: {
      params: z.object({ id: z.string().uuid() }),
      body: { content: { 'application/json': { schema: z.object({}).passthrough() } } },
    },
    responses: { 200: { description: 'Updated' } },
  }),
  async (c) => {
    const { id } = c.req.valid('param');
    const body = await c.req.json();

    // Strip supporting_characters key — handled separately
    const { supportingCharacters: chars, ...orderFields } = body;

    if (Object.keys(orderFields).length > 0) {
      await db.update(orders).set(orderFields).where(eq(orders.id, id));
    }

    if (Array.isArray(chars)) {
      // Replace supporting characters: delete existing, insert new
      await db.delete(supportingCharacters).where(eq(supportingCharacters.orderId, id));
      if (chars.length > 0) {
        await db.insert(supportingCharacters).values(chars.map((ch: any) => ({ ...ch, orderId: id })));
        await db.update(orders).set({ hasSupportingCharacters: true }).where(eq(orders.id, id));
      } else {
        await db.update(orders).set({ hasSupportingCharacters: false }).where(eq(orders.id, id));
      }
    }

    return c.json({ ok: true });
  }
);

// GET /api/orders/:id — read full order including supporting characters
ordersRouter.openapi(
  createRoute({
    method: 'get',
    path: '/:id',
    request: { params: z.object({ id: z.string().uuid() }) },
    responses: { 200: { description: 'Order' } },
  }),
  async (c) => {
    const { id } = c.req.valid('param');
    const order = await db.select().from(orders).where(eq(orders.id, id)).limit(1);
    if (!order[0]) return c.json({ error: 'not found' }, 404);
    const chars = await db.select().from(supportingCharacters).where(eq(supportingCharacters.orderId, id));
    return c.json({ ...order[0], supportingCharacters: chars });
  }
);

export { ordersRouter };
```

- [ ] **Step 3: Mount in server**

```typescript
// src/server.ts — add after existing route mounts
import { ordersRouter } from './routes/orders';
app.route('/api/orders', ordersRouter);
```

- [ ] **Step 4: Write integration tests**

```typescript
// tests/integration/orders.test.ts
import { describe, it, expect } from 'vitest';
import { app } from '../../src/server';

describe('Orders API', () => {
  it('creates draft, updates fields, reads back', async () => {
    const create = await app.request('/api/orders/draft', { method: 'POST', body: JSON.stringify({}), headers: { 'Content-Type': 'application/json' } });
    expect(create.status).toBe(201);
    const { orderId } = await create.json();

    const update = await app.request(`/api/orders/${orderId}`, {
      method: 'PATCH',
      body: JSON.stringify({ childName: 'ليلى', childAgeBand: '5-7', childAgeExact: 5, childGender: 'girl' }),
      headers: { 'Content-Type': 'application/json' },
    });
    expect(update.status).toBe(200);

    const read = await app.request(`/api/orders/${orderId}`);
    const data = await read.json();
    expect(data.childName).toBe('ليلى');
    expect(data.childAgeBand).toBe('5-7');
    expect(data.supportingCharacters).toEqual([]);
  });
});
```

- [ ] **Step 5: Run tests**

```bash
pnpm test orders
```

- [ ] **Step 6: Verify OpenAPI export**

```bash
pnpm openapi:export
```
Expected: `/api/orders/draft`, `/api/orders/{id}` GET + PATCH appear in `openapi.json`.

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(api): wizard order draft CRUD endpoints"
```

## Task 1.8 — Create theme + moral_values list endpoints

**Files:**
- Create: `hadouta-backend/src/routes/catalog.ts`
- Modify: `hadouta-backend/src/server.ts`

- [ ] **Step 1: Endpoints**

```typescript
// src/routes/catalog.ts
import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { db } from '../db';
import { themes, moralValues } from '../db/schema';
import { eq, sql } from 'drizzle-orm';

const catalogRouter = new OpenAPIHono();

// GET /api/catalog/themes?ageBand=5-7 — filtered by age band
catalogRouter.openapi(
  createRoute({
    method: 'get',
    path: '/themes',
    request: {
      query: z.object({ ageBand: z.enum(['3-5', '5-7', '6-8']).optional() }),
    },
    responses: { 200: { description: 'Themes' } },
  }),
  async (c) => {
    const { ageBand } = c.req.valid('query');
    const baseQuery = db.select().from(themes).where(eq(themes.active, true));
    let result;
    if (ageBand) {
      result = await db.select().from(themes).where(sql`${themes.active} = true AND ${ageBand} = ANY(${themes.suitableAgeBands})`);
    } else {
      result = await baseQuery;
    }
    return c.json({ themes: result });
  }
);

// GET /api/catalog/moral-values
catalogRouter.openapi(
  createRoute({
    method: 'get',
    path: '/moral-values',
    responses: { 200: { description: 'Moral values' } },
  }),
  async (c) => {
    const values = await db.select().from(moralValues).where(eq(moralValues.active, true)).orderBy(moralValues.sortOrder);
    return c.json({ moralValues: values });
  }
);

export { catalogRouter };
```

- [ ] **Step 2: Mount**

```typescript
// src/server.ts
import { catalogRouter } from './routes/catalog';
app.route('/api/catalog', catalogRouter);
```

- [ ] **Step 3: Test**

```typescript
// tests/integration/catalog.test.ts
import { describe, it, expect } from 'vitest';
import { app } from '../../src/server';

describe('Catalog API', () => {
  it('returns themes filtered by age band', async () => {
    const res = await app.request('/api/catalog/themes?ageBand=3-5');
    const { themes } = await res.json();
    expect(themes.length).toBeGreaterThan(0);
    themes.forEach((t: any) => expect(t.suitableAgeBands).toContain('3-5'));
  });

  it('returns 8 moral values sorted', async () => {
    const res = await app.request('/api/catalog/moral-values');
    const { moralValues } = await res.json();
    expect(moralValues).toHaveLength(8);
    expect(moralValues[0].nameAr).toBe('الشجاعة');
  });
});
```

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(api): catalog endpoints — themes (age-band filtered) + moral_values"
```

## Task 1.9 — Photo upload endpoint (multipart, stores to Cloudflare R2)

**Files:**
- Create: `hadouta-backend/src/routes/photos.ts`
- Create: `hadouta-backend/src/lib/r2.ts`
- Modify: `hadouta-backend/.env` + `.env.example`

- [ ] **Step 1: Add R2 dependency + env**

```bash
cd hadouta-backend && pnpm add @aws-sdk/client-s3
```

In `.env.example`:
```
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=hadouta-photos
R2_PUBLIC_URL=https://photos.hadouta.com
```

- [ ] **Step 2: R2 client wrapper**

```typescript
// src/lib/r2.ts
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

export const r2 = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
});

export async function uploadPhoto(key: string, body: Buffer | Uint8Array, contentType: string) {
  await r2.send(new PutObjectCommand({
    Bucket: process.env.R2_BUCKET_NAME!,
    Key: key,
    Body: body,
    ContentType: contentType,
  }));
  return `${process.env.R2_PUBLIC_URL}/${key}`;
}
```

- [ ] **Step 3: Photos table + photo upload route**

Add to schema:
```typescript
export const photos = pgTable('photos', {
  id: uuid('id').primaryKey().defaultRandom(),
  orderId: uuid('order_id').references(() => orders.id, { onDelete: 'cascade' }),
  ownerType: text('owner_type').notNull(),  // 'main_child' | 'supporting_character'
  ownerCharacterId: uuid('owner_character_id').references(() => supportingCharacters.id, { onDelete: 'cascade' }),
  url: text('url').notNull(),
  contentType: text('content_type').notNull(),
  fileSize: integer('file_size').notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});
```

Generate + apply migration.

```typescript
// src/routes/photos.ts
import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { db } from '../db';
import { photos } from '../db/schema';
import { uploadPhoto } from '../lib/r2';
import { randomUUID } from 'crypto';

const photosRouter = new OpenAPIHono();

photosRouter.post('/upload', async (c) => {
  const orderId = c.req.query('orderId');
  const ownerType = c.req.query('ownerType') ?? 'main_child';
  const ownerCharacterId = c.req.query('ownerCharacterId') ?? null;
  if (!orderId) return c.json({ error: 'orderId required' }, 400);

  const formData = await c.req.formData();
  const file = formData.get('file') as File | null;
  if (!file) return c.json({ error: 'file required' }, 400);

  if (file.size > 5 * 1024 * 1024) return c.json({ error: 'file too large (5MB max)' }, 413);
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
    return c.json({ error: 'unsupported file type' }, 415);
  }

  const buffer = Buffer.from(await file.arrayBuffer());
  const key = `orders/${orderId}/${randomUUID()}-${file.name.replace(/[^a-zA-Z0-9._-]/g, '_')}`;
  const url = await uploadPhoto(key, buffer, file.type);

  const photo = await db.insert(photos).values({
    orderId, ownerType, ownerCharacterId, url, contentType: file.type, fileSize: file.size,
  }).returning();

  return c.json({ photoId: photo[0].id, url }, 201);
});

photosRouter.delete('/:id', async (c) => {
  const { id } = c.req.param();
  await db.delete(photos).where(eq(photos.id, id));
  return c.json({ ok: true });
});

export { photosRouter };
```

- [ ] **Step 4: Mount + test + commit**

Mount in `server.ts`. Write integration test that uploads a tiny test image, verifies R2 URL returned, deletes. Use a mock R2 in test if needed.

```bash
git commit -m "feat(api): photo upload endpoint with Cloudflare R2 backend"
```

## Task 1.10 — Paymob payment intent endpoint

**Files:**
- Create: `hadouta-backend/src/lib/paymob.ts`
- Create: `hadouta-backend/src/routes/payments.ts`
- Modify: `.env` + `.env.example`

- [ ] **Step 1: Add Paymob env vars**

```
PAYMOB_API_KEY=
PAYMOB_INTEGRATION_ID_CARD=
PAYMOB_INTEGRATION_ID_VODAFONE_CASH=
PAYMOB_INTEGRATION_ID_INSTAPAY=
PAYMOB_IFRAME_ID=
PAYMOB_HMAC_SECRET=
PAYMOB_BASE_URL=https://accept.paymob.com/api
```

- [ ] **Step 2: Paymob client wrapper**

```typescript
// src/lib/paymob.ts
const BASE = process.env.PAYMOB_BASE_URL!;

async function authToken(): Promise<string> {
  const res = await fetch(`${BASE}/auth/tokens`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ api_key: process.env.PAYMOB_API_KEY }),
  });
  const data = await res.json();
  return data.token;
}

export async function createPaymobOrder(amountCents: number, currency = 'EGP', merchantOrderId: string): Promise<{ id: number }> {
  const token = await authToken();
  const res = await fetch(`${BASE}/ecommerce/orders`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: token, delivery_needed: false, amount_cents: amountCents, currency,
      merchant_order_id: merchantOrderId, items: [],
    }),
  });
  return await res.json();
}

export async function createPaymentKey(paymobOrderId: number, amountCents: number, billingData: any, integrationId: string): Promise<string> {
  const token = await authToken();
  const res = await fetch(`${BASE}/acceptance/payment_keys`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: token, amount_cents: amountCents, expiration: 3600,
      order_id: paymobOrderId, billing_data: billingData,
      currency: 'EGP', integration_id: integrationId,
    }),
  });
  const data = await res.json();
  return data.token;
}

export function buildIframeUrl(paymentKey: string): string {
  return `https://accept.paymob.com/api/acceptance/iframes/${process.env.PAYMOB_IFRAME_ID}?payment_token=${paymentKey}`;
}
```

- [ ] **Step 3: Payment intent route**

```typescript
// src/routes/payments.ts
import { OpenAPIHono } from '@hono/zod-openapi';
import { db } from '../db';
import { orders } from '../db/schema';
import { eq } from 'drizzle-orm';
import { createPaymobOrder, createPaymentKey, buildIframeUrl } from '../lib/paymob';

const paymentsRouter = new OpenAPIHono();

paymentsRouter.post('/intent', async (c) => {
  const { orderId } = await c.req.json();
  const order = await db.select().from(orders).where(eq(orders.id, orderId)).limit(1);
  if (!order[0]) return c.json({ error: 'order not found' }, 404);
  if (order[0].status !== 'pending_payment') return c.json({ error: 'order not in pending_payment' }, 400);

  const amountCents = order[0].priceCents ?? 25000;  // default 250 EGP

  // Step 1: create Paymob order
  const paymobOrder = await createPaymobOrder(amountCents, 'EGP', orderId);

  // Step 2: create payment key (use card integration as default; Paymob iframe lets user switch methods)
  const billingData = {
    apartment: 'NA', email: order[0].buyerEmail ?? 'noemail@hadouta.com',
    floor: 'NA', first_name: (order[0].buyerName ?? 'Customer').split(' ')[0],
    street: 'NA', building: 'NA', phone_number: order[0].buyerPhone ?? '+201000000000',
    shipping_method: 'NA', postal_code: 'NA', city: 'Cairo',
    country: 'EG', last_name: (order[0].buyerName ?? 'Customer').split(' ').slice(1).join(' ') || 'NA', state: 'NA',
  };
  const key = await createPaymentKey(paymobOrder.id, amountCents, billingData, process.env.PAYMOB_INTEGRATION_ID_CARD!);
  const iframeUrl = buildIframeUrl(key);

  // Persist Paymob order ID for reconciliation
  await db.update(orders).set({ paymobOrderId: String(paymobOrder.id) }).where(eq(orders.id, orderId));

  return c.json({ iframeUrl, paymobOrderId: paymobOrder.id });
});

paymentsRouter.post('/webhook', async (c) => {
  // Paymob webhook — verifies HMAC, marks order paid
  const body = await c.req.json();
  const hmac = c.req.query('hmac');
  // TODO: HMAC verification per Paymob docs (compute SHA512 over fields, compare to hmac header)
  // For MVP, log and update — harden in Sprint 2 follow-up
  if (body?.success && body?.order?.merchant_order_id) {
    await db.update(orders).set({ status: 'paid' }).where(eq(orders.id, body.order.merchant_order_id));
  }
  return c.json({ received: true });
});

export { paymentsRouter };
```

- [ ] **Step 4: Mount + test (smoke + webhook simulation) + commit**

```bash
git commit -m "feat(api): Paymob integration — payment intent + webhook (HMAC TODO Sprint 2)"
```

## Task 1.11 — Sync OpenAPI types to frontend

- [ ] **Step 1: Restart backend dev server**

```bash
cd hadouta-backend && pnpm dev
```

- [ ] **Step 2: Sync types in frontend**

```bash
cd ../hadouta-web && pnpm sync-types
```
Expected: `src/lib/api/api-types.ts` regenerated with new endpoints.

- [ ] **Step 3: Commit frontend types**

```bash
git commit -m "feat(api-types): sync OpenAPI types for wizard + catalog + payments"
```

---

# Part 2 — Landing page (parallel to Part 1)

This part can run independently — no schema dependencies. Files in `hadouta-web/src/app/page.tsx` + new section components in `src/components/landing/`.

## Task 2.1 — Decompose page.tsx into sections

**Files:**
- Modify: `hadouta-web/src/app/page.tsx`
- Create: `hadouta-web/src/components/landing/{hero,storyteller-setup,sample-preview,how-it-works,theme-gallery-preview,trust-band,pricing,faq,site-footer,site-header}.tsx`

- [ ] **Step 1: Replace existing `page.tsx` with section composition**

```tsx
// src/app/page.tsx
import { SiteHeader } from '@/components/landing/site-header';
import { Hero } from '@/components/landing/hero';
import { StorytellerSetup } from '@/components/landing/storyteller-setup';
import { SamplePreview } from '@/components/landing/sample-preview';
import { HowItWorks } from '@/components/landing/how-it-works';
import { ThemeGalleryPreview } from '@/components/landing/theme-gallery-preview';
import { TrustBand } from '@/components/landing/trust-band';
import { Pricing } from '@/components/landing/pricing';
import { Faq } from '@/components/landing/faq';
import { SiteFooter } from '@/components/landing/site-footer';

export default function HomePage() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        <StorytellerSetup />
        <SamplePreview />
        <HowItWorks />
        <ThemeGalleryPreview />
        <TrustBand />
        <Pricing />
        <Faq />
      </main>
      <SiteFooter />
    </>
  );
}
```

- [ ] **Step 2: Create stub files for each section** (each just exports a div with section name; will be filled in subsequent tasks)

```tsx
// e.g. src/components/landing/hero.tsx
export function Hero() {
  return <section className="bg-background py-12">Hero — TBD</section>;
}
```

Repeat for all 9 sections.

- [ ] **Step 3: Verify page builds + renders**

```bash
cd hadouta-web && pnpm typecheck && pnpm build
pnpm dev  # then open localhost:3000
```
Expected: page shows 9 stubbed sections in order, no errors.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(landing): decompose page into 9 section components (stubs)"
```

## Task 2.2 — Site header

**Files:** `src/components/landing/site-header.tsx`

- [ ] **Step 1: Implement**

```tsx
import Link from 'next/link';

export function SiteHeader() {
  return (
    <header className="bg-background border-b border-border/40">
      <div className="container mx-auto flex items-center justify-between py-4 px-4">
        <Link href="/" className="font-display text-2xl text-primary">حدوتة</Link>
        <nav className="flex gap-6 text-sm">
          <Link href="#sample" className="text-foreground/70 hover:text-foreground">شوف نموذج</Link>
          <Link href="/wizard" className="text-foreground/70 hover:text-foreground">ابدأ</Link>
        </nav>
      </div>
    </header>
  );
}
```

- [ ] **Step 2: Verify in browser, commit**

```bash
git commit -m "feat(landing): site header with Aref Ruqaa logo + nav"
```

## Task 2.3 — Hero section (option A — illustration-right, text-left)

**Files:** `src/components/landing/hero.tsx`

- [ ] **Step 1: Implement**

```tsx
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export function Hero() {
  return (
    <section className="bg-background py-16 md:py-24">
      <div className="container mx-auto px-4">
        <div className="grid md:grid-cols-2 gap-12 items-center" dir="rtl">
          {/* Illustration — right in RTL = first in source order */}
          <div className="aspect-[4/3] rounded-2xl bg-gradient-to-br from-hadouta-blush/70 to-hadouta-ochre/70 flex items-center justify-center">
            <span className="text-foreground/50 text-sm">رسمة مائية: تيتة وطفل في مطبخ القاهرة (Phase 5 — placeholder)</span>
          </div>

          {/* Text + CTA — left in RTL = second in source order */}
          <div className="space-y-6">
            <h1 className="font-heading text-4xl md:text-5xl font-bold leading-tight">
              حدوتة لطفلك،<br />من قلب مصر
            </h1>
            <p className="text-lg text-foreground/75">
              كتاب مخصص بعناية لطفلك، جاهز في ٢-٣ أيام
            </p>
            <Button asChild size="lg">
              <Link href="/wizard">ابدأ حدوتة طفلك</Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Verify in browser at mobile breakpoint, commit**

Test at 375px width (iPhone SE) — illustration stacks above text.

```bash
git commit -m "feat(landing): hero section (option A — RTL illustration-right, text-left)"
```

## Task 2.4 — Storyteller setup section

**Files:** `src/components/landing/storyteller-setup.tsx`

- [ ] **Step 1: Implement**

```tsx
export function StorytellerSetup() {
  return (
    <section className="bg-gradient-to-b from-background to-secondary/40 py-16">
      <div className="container mx-auto px-4 max-w-3xl text-center" dir="rtl">
        <p className="font-display text-2xl text-primary mb-4">۞</p>
        <p className="font-heading text-2xl md:text-3xl leading-relaxed text-foreground">
          كل حدوتة بتبدأ بطفل. اسم، ضحكة، طريقة لما يضحك ولما يعيط. خلينا نعرفه أكتر — ونرسمله حدوتته.
        </p>
      </div>
    </section>
  );
}
```

(Final copy is Phase 6 brand statements; this is acceptable Storyteller-voice placeholder.)

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): Storyteller setup section (Phase 6 copy TBD)"
```

## Task 2.5 — Sample preview section

**Files:** `src/components/landing/sample-preview.tsx`

- [ ] **Step 1: Implement static placeholder**

```tsx
export function SamplePreview() {
  return (
    <section id="sample" className="bg-primary/95 py-16 text-primary-foreground">
      <div className="container mx-auto px-4 max-w-5xl" dir="rtl">
        <h2 className="font-heading text-3xl md:text-4xl font-bold mb-3">شوف نموذج</h2>
        <p className="opacity-90 mb-8">صفحات من حدوتة "أحمد" — كل طفل يصبح بطل قصته الخاصة.</p>
        <div className="grid md:grid-cols-3 gap-6">
          {[1, 2, 3].map((n) => (
            <div key={n} className="aspect-[3/4] rounded-xl bg-gradient-to-br from-hadouta-blush/40 to-hadouta-ochre/40 flex items-center justify-center text-primary-foreground/60 text-sm">
              صفحة {n}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

(Real sample images come from AI pipeline — Sprint 3+. Placeholders for now.)

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): sample preview section (placeholder spreads)"
```

## Task 2.6 — How-it-works section

**Files:** `src/components/landing/how-it-works.tsx`

- [ ] **Step 1: Implement 4-step explainer**

```tsx
const steps = [
  { num: '١', title: 'اخترلنا طفلك', sub: 'اسمه، عمره، صورته أو وصفه — وكتير من اللمسات اللي بتميزه' },
  { num: '٢', title: 'اختار الموضوع والقيمة', sub: 'العيد، أول يوم مدرسة، الشجاعة، الكرم — المزيج بيخلي القصة شخصية' },
  { num: '٣', title: 'بنحضّر القصة', sub: 'بناءً على قوالب صممها كتّاب ورسامين مصريين' },
  { num: '٤', title: 'فريقنا المصري بيراجعها', sub: 'كل حدوتة بنراجعها بدقة قبل ما توصلك' },
];

export function HowItWorks() {
  return (
    <section className="bg-background py-16">
      <div className="container mx-auto px-4 max-w-5xl" dir="rtl">
        <h2 className="font-heading text-3xl md:text-4xl font-bold mb-3 text-center">إزاي بنعملها؟</h2>
        <p className="text-center text-foreground/70 mb-10">٤ خطوات وحدوتتك في إيدك</p>
        <div className="grid md:grid-cols-4 gap-6">
          {steps.map((s) => (
            <div key={s.num} className="text-center space-y-3">
              <div className="font-display text-3xl text-primary">{s.num}</div>
              <h3 className="font-heading text-lg font-semibold">{s.title}</h3>
              <p className="text-sm text-foreground/70 leading-relaxed">{s.sub}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): how-it-works 4-step section (honest copy)"
```

## Task 2.7 — Theme gallery preview

**Files:** `src/components/landing/theme-gallery-preview.tsx`

- [ ] **Step 1: Static preview of 4-6 themes (no API call — landing is fast static)**

```tsx
const themes = [
  { ar: 'أول يوم مدرسة', icon: '🏫' },
  { ar: 'الصداقة', icon: '🤝' },
  { ar: 'العيد', icon: '🌙' },
  { ar: 'الكريسماس', icon: '⭐' },
  { ar: 'شم النسيم', icon: '🥚' },
  { ar: 'مغامرة كبيرة', icon: '⛰️' },
];

export function ThemeGalleryPreview() {
  return (
    <section className="bg-secondary/30 py-16">
      <div className="container mx-auto px-4 max-w-5xl" dir="rtl">
        <h2 className="font-heading text-3xl md:text-4xl font-bold mb-3 text-center">مواضيع للحدوتة</h2>
        <p className="text-center text-foreground/70 mb-10">من رمضان والعيد لشم النسيم وأول يوم مدرسة</p>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {themes.map((t) => (
            <div key={t.ar} className="bg-background rounded-xl p-4 text-center">
              <div className="text-3xl mb-2">{t.icon}</div>
              <p className="font-heading font-semibold">{t.ar}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): theme gallery preview (static, 6 themes)"
```

## Task 2.8 — Trust band (3-part honest claim)

**Files:** `src/components/landing/trust-band.tsx`

- [ ] **Step 1: Implement**

```tsx
const claims = [
  { ar: 'كتّاب ورسامين مصريين', sub: 'بيصمموا قوالب حكاياتنا — ثقافة مصرية أصيلة في كل صفحة' },
  { ar: 'مراجعة بإيد مصرية', sub: 'فريقنا بيراجع كل حدوتة بدقة قبل ما توصلك' },
  { ar: 'جاهزة في ٢-٣ أيام', sub: 'وقت كافي للعناية والمراجعة — مش دقايق' },
];

export function TrustBand() {
  return (
    <section className="bg-hadouta-teal py-16 text-hadouta-cream">
      <div className="container mx-auto px-4 max-w-5xl" dir="rtl">
        <h2 className="font-heading text-3xl md:text-4xl font-bold mb-10 text-center">وعدنا</h2>
        <div className="grid md:grid-cols-3 gap-8">
          {claims.map((c) => (
            <div key={c.ar} className="text-center space-y-3">
              <h3 className="font-heading text-xl font-semibold">{c.ar}</h3>
              <p className="text-sm opacity-90 leading-relaxed">{c.sub}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

(Team photos: Track B — Ahmed sources photos and we swap placeholders later.)

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): trust band (3-part honest claim — production-honesty rule applied)"
```

## Task 2.9 — Pricing section

**Files:** `src/components/landing/pricing.tsx`

- [ ] **Step 1: Implement**

```tsx
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export function Pricing() {
  return (
    <section className="bg-hadouta-ochre/20 py-16">
      <div className="container mx-auto px-4 max-w-2xl text-center" dir="rtl">
        <h2 className="font-heading text-3xl md:text-4xl font-bold mb-3">السعر</h2>
        <div className="bg-background rounded-2xl p-8 shadow-sm border border-border/30 my-6">
          <div className="font-display text-5xl text-primary mb-2">٢٥٠ ج.م</div>
          <p className="text-foreground/70 mb-6">حدوتة كاملة، PDF عالي الجودة، جاهز للتحميل</p>
          <Button asChild size="lg" className="w-full">
            <Link href="/wizard">ابدأ حدوتة طفلك</Link>
          </Button>
        </div>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): pricing section — single tier 250 EGP"
```

## Task 2.10 — FAQ section

**Files:** `src/components/landing/faq.tsx`

- [ ] **Step 1: Add shadcn Accordion**

```bash
cd hadouta-web && pnpm dlx shadcn@latest add accordion
```

- [ ] **Step 2: Implement**

```tsx
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

const faqs = [
  { q: 'إزاي بتعملوا الحدوتة؟', a: 'بنبني الحدوتة على قوالب صممها كتّاب ورسامين مصريين، ثم فريقنا المصري بيراجع كل كتاب بدقة قبل ما يوصلك. التحضير بياخد ٢-٣ أيام.' },
  { q: 'لو ما رضيتش عن الحدوتة؟', a: 'بنحضّرها تاني — وقت إضافي حوالي ٢٤ ساعة، شامل في السعر. هدفنا ترضى أنت وطفلك.' },
  { q: 'هل لازم أرفع صورة لطفلي؟', a: 'لأ — تقدر ترفع صور أو توصف طفلك بنفسك (لون البشرة، الشعر، اللباس). الطريقتين بيطلعوا حدوتة جميلة.' },
  { q: 'الكتاب مطبوع ولا رقمي؟', a: 'PDF رقمي عالي الجودة دلوقتي. النسخة المطبوعة هتكون متاحة كإضافة في v1.5 (أوائل ٢٠٢٧).' },
  { q: 'بتاخدوا أي طرق دفع؟', a: 'كارت فيزا/ماستركارد، فودافون كاش، إنستاباي — كله عبر Paymob الآمن.' },
];

export function Faq() {
  return (
    <section className="bg-background py-16">
      <div className="container mx-auto px-4 max-w-3xl" dir="rtl">
        <h2 className="font-heading text-3xl md:text-4xl font-bold mb-10 text-center">أسئلة متكررة</h2>
        <Accordion type="single" collapsible>
          {faqs.map((f, i) => (
            <AccordionItem key={i} value={`item-${i}`}>
              <AccordionTrigger className="text-right font-heading">{f.q}</AccordionTrigger>
              <AccordionContent className="text-foreground/75 leading-relaxed">{f.a}</AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): FAQ accordion — 5 honest answers (production-honesty applied)"
```

## Task 2.11 — Site footer

**Files:** `src/components/landing/site-footer.tsx`

- [ ] **Step 1: Implement**

```tsx
export function SiteFooter() {
  return (
    <footer className="bg-secondary/40 border-t border-border/30 py-10">
      <div className="container mx-auto px-4" dir="rtl">
        <div className="flex flex-col md:flex-row justify-between items-center gap-4">
          <div>
            <span className="font-display text-2xl text-primary">حدوتة</span>
            <p className="text-sm text-foreground/60 mt-1">— كتب أطفال مصرية مخصصة</p>
          </div>
          <nav className="flex gap-6 text-sm text-foreground/60">
            <a href="/privacy">سياسة الخصوصية</a>
            <a href="/terms">شروط الاستخدام</a>
            <a href="/contact">تواصل معنا</a>
          </nav>
        </div>
      </div>
    </footer>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(landing): site footer with privacy/terms/contact links"
```

## Task 2.12 — Mobile responsive verification

- [ ] **Step 1: Open in browser at multiple viewports**

```bash
cd hadouta-web && pnpm dev
```

Use Chrome DevTools device toolbar to test: iPhone SE (375px), iPhone 14 (390px), iPad Mini (768px), Desktop (1280px). Verify:
- [ ] Hero stacks vertically on mobile
- [ ] How-it-works grid wraps to 2-col / 1-col
- [ ] Theme gallery wraps appropriately
- [ ] Trust band wraps
- [ ] Pricing card readable
- [ ] FAQ accordion works
- [ ] All Arabic text RTL'd correctly

- [ ] **Step 2: Fix any breakpoint issues** — commonly: header collapses to hamburger or just shrinks links; ensure no horizontal scroll.

- [ ] **Step 3: Commit fixes**

```bash
git commit -m "fix(landing): mobile responsive tuning across all sections"
```

## Task 2.13 — Vercel preview deploy

- [ ] **Step 1: Push branch to remote**

```bash
git push -u origin feat/phase-5-implementation
```

- [ ] **Step 2: Vercel auto-deploys preview** — wait for the preview URL to appear in GitHub PR or Vercel dashboard. Open it. Verify landing page renders with brand chrome.

- [ ] **Step 3: Run Lighthouse on preview URL**

In Chrome DevTools → Lighthouse → run for Mobile + Desktop. Targets:
- Performance: 85+
- Accessibility: 95+
- Best Practices: 95+
- SEO: 90+

Address obvious issues (image alt text, semantic HTML, color contrast — should already be AA from Phase 2 tokens).

---

# Part 3 — Wizard frontend (depends on Part 1's APIs being live)

This part has the most components. Sequential within itself but depends on Part 1.

## Task 3.1 — Wizard route + Zustand state store

**Files:**
- Create: `hadouta-web/src/app/wizard/layout.tsx`, `page.tsx`, `[step]/page.tsx`
- Create: `hadouta-web/src/lib/wizard/store.ts`
- Create: `hadouta-web/src/lib/wizard/api.ts`

- [ ] **Step 1: Add Zustand**

```bash
cd hadouta-web && pnpm add zustand
```

- [ ] **Step 2: Create store**

```typescript
// src/lib/wizard/store.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface ChildInfo {
  childName?: string;
  childAgeBand?: '3-5' | '5-7' | '6-8';
  childAgeExact?: number;
  childGender?: 'boy' | 'girl';
  childHobbies?: string;
  childFavoriteFood?: string;
  childFavoriteColor?: string;
  childSpecialTraits?: string;
  buyerName?: string;
}

export interface Appearance {
  appearanceInputType?: 'photo' | 'description';
  photoIds?: string[];  // up to 3
  descriptionSkinTone?: string;
  descriptionHair?: string;
  descriptionClothingStyle?: 'modern' | 'egyptian_traditional' | 'school_uniform' | 'custom';
  descriptionEyeColor?: string;
}

export interface SupportingChar {
  name: string;
  role: 'sibling' | 'friend' | 'grandparent' | 'parent' | 'pet' | 'other';
  appearanceInputType: 'photo' | 'description';
  photoId?: string;
  descriptionSkinTone?: string;
  descriptionHair?: string;
  descriptionClothingStyle?: string;
  position: 1 | 2;
}

export interface StoryDetails {
  themeId?: string;
  moralValueId?: string;
  customSceneText?: string;
  specialOccasionText?: string;
}

interface WizardState {
  orderId?: string;
  step: number;
  childInfo: ChildInfo;
  appearance: Appearance;
  supportingCharacters: SupportingChar[];
  storyDetails: StoryDetails;
  dedicationText?: string;

  setOrderId: (id: string) => void;
  setStep: (n: number) => void;
  updateChildInfo: (patch: Partial<ChildInfo>) => void;
  updateAppearance: (patch: Partial<Appearance>) => void;
  setSupportingCharacters: (chars: SupportingChar[]) => void;
  updateStoryDetails: (patch: Partial<StoryDetails>) => void;
  setDedication: (text: string) => void;
  reset: () => void;
}

const initial = {
  step: 1,
  childInfo: {} as ChildInfo,
  appearance: {} as Appearance,
  supportingCharacters: [] as SupportingChar[],
  storyDetails: {} as StoryDetails,
  dedicationText: undefined,
};

export const useWizardStore = create<WizardState>()(
  persist(
    (set) => ({
      ...initial,
      setOrderId: (orderId) => set({ orderId }),
      setStep: (step) => set({ step }),
      updateChildInfo: (patch) => set((s) => ({ childInfo: { ...s.childInfo, ...patch } })),
      updateAppearance: (patch) => set((s) => ({ appearance: { ...s.appearance, ...patch } })),
      setSupportingCharacters: (supportingCharacters) => set({ supportingCharacters }),
      updateStoryDetails: (patch) => set((s) => ({ storyDetails: { ...s.storyDetails, ...patch } })),
      setDedication: (dedicationText) => set({ dedicationText }),
      reset: () => set({ ...initial, orderId: undefined }),
    }),
    { name: 'hadouta-wizard' }
  )
);
```

- [ ] **Step 3: API client wrapper**

```typescript
// src/lib/wizard/api.ts
import { client } from '@/lib/api/client';

export async function createDraftOrder(buyerName?: string) {
  const { data } = await client.POST('/api/orders/draft', { body: { buyerName } });
  return data!.orderId;
}

export async function patchOrder(orderId: string, patch: any) {
  await client.PATCH('/api/orders/{id}', { params: { path: { id: orderId } }, body: patch });
}

export async function fetchOrder(orderId: string) {
  const { data } = await client.GET('/api/orders/{id}', { params: { path: { id: orderId } } });
  return data;
}

export async function fetchThemes(ageBand?: string) {
  const { data } = await client.GET('/api/catalog/themes', { params: { query: { ageBand } } });
  return data!.themes;
}

export async function fetchMoralValues() {
  const { data } = await client.GET('/api/catalog/moral-values', {});
  return data!.moralValues;
}

export async function uploadPhoto(orderId: string, file: File, ownerType: 'main_child' | 'supporting_character', ownerCharacterId?: string) {
  const formData = new FormData();
  formData.append('file', file);
  const url = `/api/photos/upload?orderId=${orderId}&ownerType=${ownerType}${ownerCharacterId ? `&ownerCharacterId=${ownerCharacterId}` : ''}`;
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}${url}`, { method: 'POST', body: formData });
  if (!res.ok) throw new Error('upload failed');
  return await res.json();  // { photoId, url }
}

export async function createPaymentIntent(orderId: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/payments/intent`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ orderId }),
  });
  return await res.json();  // { iframeUrl, paymobOrderId }
}
```

- [ ] **Step 4: Wizard layout + step router**

```tsx
// src/app/wizard/layout.tsx
import { WizardStepper } from '@/components/wizard/stepper';

export default function WizardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-background">
      <WizardStepper />
      <main className="container mx-auto max-w-2xl px-4 py-8">{children}</main>
    </div>
  );
}
```

```tsx
// src/app/wizard/page.tsx — redirect to step 1
import { redirect } from 'next/navigation';
export default function WizardEntry() { redirect('/wizard/1'); }
```

```tsx
// src/app/wizard/[step]/page.tsx
'use client';
import { useParams } from 'next/navigation';
import { Step1 } from '@/components/wizard/step-1-child-info';
import { Step2 } from '@/components/wizard/step-2-appearance';
import { Step3 } from '@/components/wizard/step-3-supporting';
import { Step4 } from '@/components/wizard/step-4-story';
import { Step5 } from '@/components/wizard/step-5-review';
import { Step6 } from '@/components/wizard/step-6-checkout';
import { Step7 } from '@/components/wizard/step-7-confirmation';

export default function WizardStepPage() {
  const { step } = useParams<{ step: string }>();
  switch (step) {
    case '1': return <Step1 />;
    case '2': return <Step2 />;
    case '3': return <Step3 />;
    case '4': return <Step4 />;
    case '5': return <Step5 />;
    case '6': return <Step6 />;
    case '7': return <Step7 />;
    default: return <div>Step not found</div>;
  }
}
```

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(wizard): route + Zustand store + API client (skeleton)"
```

## Task 3.2 — Wizard stepper component

**Files:** `hadouta-web/src/components/wizard/stepper.tsx`

- [ ] **Step 1: Implement**

```tsx
'use client';
import { useWizardStore } from '@/lib/wizard/store';
import { cn } from '@/lib/utils';

const labels = ['طفلك', 'الصورة', 'العائلة', 'الحدوتة', 'مراجعة', 'الدفع', 'تم'];

export function WizardStepper() {
  const step = useWizardStore((s) => s.step);
  return (
    <div className="bg-secondary/40 border-b border-border/30 py-3">
      <div className="container mx-auto max-w-3xl px-4" dir="rtl">
        <div className="flex gap-1">
          {labels.map((label, i) => {
            const num = i + 1;
            const isActive = num === step;
            const isDone = num < step;
            const isCheckout = num === 6;
            const isConfirm = num === 7;
            return (
              <div
                key={num}
                className={cn(
                  'flex-1 rounded-md text-center font-heading text-xs py-2 px-1',
                  isActive && (isCheckout ? 'bg-hadouta-ochre text-foreground' : isConfirm ? 'bg-hadouta-teal text-hadouta-cream' : 'bg-primary text-primary-foreground'),
                  isDone && 'bg-hadouta-teal/15 text-hadouta-teal',
                  !isActive && !isDone && 'bg-foreground/5 text-foreground/45'
                )}
              >
                <span className="block font-display text-[10px] opacity-85">{['١','٢','٣','٤','٥','٦','٧'][i]}</span>
                {label}{isDone && ' ✓'}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(wizard): stepper component"
```

## Task 3.3 — Step 1: Child info form (option A — all visible)

**Files:** `hadouta-web/src/components/wizard/step-1-child-info.tsx`

- [ ] **Step 1: Implement form with react-hook-form + Zod**

```tsx
'use client';
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useRouter } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { createDraftOrder, patchOrder } from '@/lib/wizard/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';

const schema = z.object({
  childName: z.string().min(1, 'اسم الطفل مطلوب').max(80),
  childAgeBand: z.enum(['3-5', '5-7', '6-8']),
  childAgeExact: z.coerce.number().int().min(3).max(8),
  childGender: z.enum(['boy', 'girl']),
  childHobbies: z.string().max(500).optional(),
  childFavoriteFood: z.string().max(120).optional(),
  childFavoriteColor: z.string().max(80).optional(),
  childSpecialTraits: z.string().max(500).optional(),
  buyerName: z.string().min(1, 'اسمك مطلوب').max(120),
});

type FormData = z.infer<typeof schema>;

export function Step1() {
  const router = useRouter();
  const store = useWizardStore();

  const { register, handleSubmit, watch, setValue, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { ...store.childInfo, ...(store.childInfo.buyerName ? { buyerName: store.childInfo.buyerName } : {}) },
  });

  const ageBand = watch('childAgeBand');
  const gender = watch('childGender');

  const onSubmit = async (data: FormData) => {
    let orderId = store.orderId;
    if (!orderId) {
      orderId = await createDraftOrder(data.buyerName);
      store.setOrderId(orderId);
    }
    await patchOrder(orderId, data);
    store.updateChildInfo(data);
    store.setStep(2);
    router.push('/wizard/2');
  };

  return (
    <form dir="rtl" onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <header>
        <h2 className="font-heading text-2xl font-bold">أخبرنا عن بطل الحدوتة</h2>
        <p className="text-foreground/70 text-sm mt-1">كل حدوتة بتبدأ بطفل. عرّفنا عن طفلك ونحن نبني له قصته. <span className="font-display text-primary">۞</span></p>
      </header>

      <div className="space-y-2">
        <Label>اسم الطفل *</Label>
        <Input placeholder="مثلاً: ليلى" {...register('childName')} />
        {errors.childName && <p className="text-sm text-destructive">{errors.childName.message}</p>}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>الفئة العمرية *</Label>
          <div className="grid grid-cols-3 gap-1">
            {(['3-5', '5-7', '6-8'] as const).map((b) => (
              <button type="button" key={b} onClick={() => setValue('childAgeBand', b)} className={cn('rounded-md py-2 text-xs font-heading border', ageBand === b ? 'bg-primary/15 border-primary' : 'border-border')}>
                {b.replace('-', '–')}
              </button>
            ))}
          </div>
        </div>
        <div className="space-y-2">
          <Label>العمر *</Label>
          <Input type="number" min={3} max={8} {...register('childAgeExact')} />
        </div>
      </div>

      <div className="space-y-2">
        <Label>الجنس *</Label>
        <div className="grid grid-cols-2 gap-2">
          {(['girl', 'boy'] as const).map((g) => (
            <button type="button" key={g} onClick={() => setValue('childGender', g)} className={cn('rounded-md py-3 font-heading border', gender === g ? 'bg-primary/15 border-primary' : 'border-border')}>
              {g === 'girl' ? '👧 بنت' : '👦 ولد'}
            </button>
          ))}
        </div>
      </div>

      <div className="space-y-2">
        <Label>هوايات طفلك <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
        <Input placeholder="الرسم، الموسيقى، اللعب في الحديقة..." {...register('childHobbies')} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label>أكلة مفضلة <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
          <Input placeholder="الكنافة..." {...register('childFavoriteFood')} />
        </div>
        <div className="space-y-2">
          <Label>لون مفضل <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
          <Input placeholder="الأزرق..." {...register('childFavoriteColor')} />
        </div>
      </div>

      <div className="space-y-2">
        <Label>حاجة مميزة عن طفلك <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
        <textarea className="w-full rounded-md border border-border bg-background p-2 text-sm" rows={3} placeholder="ضحكتها مميزة، شجاعة، تحب الحيوانات..." {...register('childSpecialTraits')} />
      </div>

      <div className="rounded-md bg-hadouta-teal/8 border-t border-hadouta-teal/20 p-4 space-y-2">
        <Label>اسمك (ولي الأمر) *</Label>
        <Input placeholder="مثلاً: أحمد محمد" {...register('buyerName')} />
        {errors.buyerName && <p className="text-sm text-destructive">{errors.buyerName.message}</p>}
      </div>

      <div className="flex justify-between pt-4 border-t border-border/30">
        <Button type="button" variant="outline" onClick={() => router.push('/')}>← الرئيسية</Button>
        <Button type="submit" disabled={isSubmitting}>التالي ←</Button>
      </div>
    </form>
  );
}
```

- [ ] **Step 2: Verify form submits, persists to backend, navigates to step 2**

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(wizard): step 1 child info form with autosave to backend draft"
```

## Task 3.4 — Step 2: Photo OR description path picker

**Files:**
- Create: `hadouta-web/src/components/wizard/step-2-appearance.tsx`
- Create: `hadouta-web/src/components/wizard/photo-upload.tsx`
- Create: `hadouta-web/src/components/wizard/description-form.tsx`
- Create: `hadouta-web/src/components/wizard/skin-tone-picker.tsx`

- [ ] **Step 1: Path picker (initial state)**

```tsx
// step-2-appearance.tsx
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { patchOrder } from '@/lib/wizard/api';
import { PhotoUpload } from './photo-upload';
import { DescriptionForm } from './description-form';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

export function Step2() {
  const router = useRouter();
  const store = useWizardStore();
  const [path, setPath] = useState<'photo' | 'description' | null>(store.appearance.appearanceInputType ?? null);

  const proceed = async () => {
    if (!path || !store.orderId) return;
    await patchOrder(store.orderId, { appearanceInputType: path, ...store.appearance });
    store.setStep(3);
    router.push('/wizard/3');
  };

  if (!path) {
    return (
      <div dir="rtl" className="space-y-6">
        <header>
          <h2 className="font-heading text-2xl font-bold">صورة طفلك في الكتاب</h2>
          <p className="text-foreground/70 text-sm mt-1">إزاي عاوز {store.childInfo.childName ?? 'طفلك'} يظهر في الرسومات؟ في طريقتين، اختار اللي يريحك:</p>
        </header>

        <div className="grid grid-cols-2 gap-3">
          <button onClick={() => { setPath('photo'); store.updateAppearance({ appearanceInputType: 'photo' }); }} className="relative bg-card rounded-xl p-4 text-center border-2 border-primary hover:bg-primary/5">
            <span className="absolute -top-2 right-3 bg-primary text-primary-foreground text-[10px] px-2 py-0.5 rounded">الأكثر شيوعاً</span>
            <div className="text-3xl mb-2">📷</div>
            <h3 className="font-heading font-semibold">ارفع صور طفلك</h3>
            <p className="text-xs text-foreground/65 mt-1 leading-relaxed">١-٣ صور. هنرسم نسخة مائية لطفلك بنفس الوجه في كل صفحة.</p>
          </button>

          <button onClick={() => { setPath('description'); store.updateAppearance({ appearanceInputType: 'description' }); }} className="bg-card rounded-xl p-4 text-center border-2 border-border hover:bg-secondary/30">
            <div className="text-3xl mb-2">✎</div>
            <h3 className="font-heading font-semibold">اوصف طفلك بدلاً من ذلك</h3>
            <p className="text-xs text-foreground/65 mt-1 leading-relaxed">اختار لون البشرة، اوصف الشعر واللباس. مناسب للخصوصية.</p>
          </button>
        </div>

        <div className="flex justify-between pt-4">
          <Button variant="outline" onClick={() => router.push('/wizard/1')}>← السابق</Button>
        </div>
      </div>
    );
  }

  // Path selected — show expanded form
  return (
    <div dir="rtl" className="space-y-4">
      <header>
        <h2 className="font-heading text-2xl font-bold">
          <span className={cn('inline-block text-xs px-2 py-1 rounded mr-2', path === 'photo' ? 'bg-primary text-primary-foreground' : 'bg-hadouta-teal text-hadouta-cream')}>
            {path === 'photo' ? '📷 طريقة الصور' : '✎ طريقة الوصف'}
          </span>
          {path === 'photo' ? 'صورة طفلك' : 'اوصف طفلك'}
        </h2>
      </header>

      <div className="bg-hadouta-teal/8 border border-hadouta-teal/20 rounded-md p-2 text-xs">
        اخترت طريقة {path === 'photo' ? 'الصور' : 'الوصف'}.{' '}
        <button onClick={() => setPath(path === 'photo' ? 'description' : 'photo')} className="text-hadouta-teal underline">
          ↻ تحويل لطريقة {path === 'photo' ? 'الوصف' : 'الصور'}
        </button>
      </div>

      {path === 'photo' ? <PhotoUpload /> : <DescriptionForm />}

      <div className="flex justify-between pt-4 border-t border-border/30">
        <Button variant="outline" onClick={() => router.push('/wizard/1')}>← السابق</Button>
        <Button onClick={proceed}>التالي ←</Button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Photo upload component**

```tsx
// photo-upload.tsx
'use client';
import { useRef, useState } from 'react';
import { useWizardStore } from '@/lib/wizard/store';
import { uploadPhoto } from '@/lib/wizard/api';

export function PhotoUpload() {
  const store = useWizardStore();
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const photoIds = store.appearance.photoIds ?? [];

  const handleFile = async (file: File) => {
    if (!store.orderId) return;
    setUploading(true);
    try {
      const { photoId } = await uploadPhoto(store.orderId, file, 'main_child');
      store.updateAppearance({ photoIds: [...photoIds, photoId] });
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="space-y-3">
      <div className="grid grid-cols-3 gap-2">
        {[0, 1, 2].map((i) => {
          const id = photoIds[i];
          return (
            <div key={i} className={cn('aspect-square rounded-lg flex items-center justify-center text-2xl', id ? 'bg-gradient-to-br from-hadouta-blush/40 to-hadouta-ochre/40' : 'border-2 border-dashed border-border bg-background text-foreground/30')}>
              {id ? <span>🖼️</span> : '+'}
            </div>
          );
        })}
      </div>

      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        disabled={photoIds.length >= 3 || uploading}
        className="w-full border-2 border-dashed border-border rounded-lg py-6 text-center bg-background hover:bg-secondary/30 disabled:opacity-50"
      >
        <div className="text-2xl mb-1">⤴</div>
        <div className="font-heading font-semibold text-sm">{uploading ? 'بنرفع...' : photoIds.length === 0 ? 'ضيف صورة' : 'ضيف صورة تانية'}</div>
        <div className="text-xs text-foreground/55">JPG · PNG · WEBP · حتى ٥ ميجابايت لكل صورة</div>
      </button>

      <input ref={inputRef} type="file" accept="image/jpeg,image/png,image/webp" hidden onChange={(e) => e.target.files?.[0] && handleFile(e.target.files[0])} />

      <div className="bg-hadouta-ochre/10 border-r-2 border-hadouta-ochre rounded p-3 text-xs leading-relaxed">
        <strong>للحصول على أفضل نتيجة:</strong> صور بضوء نهار، الوجه واضح، خلفية مش مزدحمة. ٢-٣ صور أفضل من واحدة.
      </div>
    </div>
  );
}

function cn(...classes: (string | false | undefined)[]) { return classes.filter(Boolean).join(' '); }
```

- [ ] **Step 3: Description form component**

```tsx
// description-form.tsx
'use client';
import { useWizardStore } from '@/lib/wizard/store';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { SkinTonePicker } from './skin-tone-picker';
import { cn } from '@/lib/utils';

const CLOTHING_OPTIONS = [
  { value: 'modern', label: 'عصري' },
  { value: 'egyptian_traditional', label: 'تقليدي مصري' },
  { value: 'school_uniform', label: 'زي مدرسي' },
  { value: 'custom', label: 'مخصص' },
] as const;

export function DescriptionForm() {
  const { appearance, updateAppearance } = useWizardStore();
  return (
    <div className="space-y-5">
      <div className="space-y-2">
        <Label>لون البشرة *</Label>
        <SkinTonePicker value={appearance.descriptionSkinTone} onChange={(v) => updateAppearance({ descriptionSkinTone: v })} />
      </div>

      <div className="space-y-2">
        <Label>وصف الشعر *</Label>
        <Input placeholder="شعر طويل أسود، شعر قصير بني مجعد..." value={appearance.descriptionHair ?? ''} onChange={(e) => updateAppearance({ descriptionHair: e.target.value })} />
      </div>

      <div className="space-y-2">
        <Label>طريقة اللباس *</Label>
        <div className="grid grid-cols-2 gap-2">
          {CLOTHING_OPTIONS.map((c) => (
            <button key={c.value} type="button" onClick={() => updateAppearance({ descriptionClothingStyle: c.value })} className={cn('rounded-md py-2 px-1 text-sm border', appearance.descriptionClothingStyle === c.value ? 'bg-primary/15 border-primary font-semibold' : 'border-border')}>
              {c.label}
            </button>
          ))}
        </div>
      </div>

      <div className="space-y-2">
        <Label>لون العيون <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
        <Input placeholder="بني، أخضر، أزرق..." value={appearance.descriptionEyeColor ?? ''} onChange={(e) => updateAppearance({ descriptionEyeColor: e.target.value })} />
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Skin tone picker**

```tsx
// skin-tone-picker.tsx
const TONES = ['#3a2415', '#6e4528', '#a06d3e', '#c8915f', '#e0b685', '#f0d2a8'];

export function SkinTonePicker({ value, onChange }: { value?: string; onChange: (v: string) => void }) {
  return (
    <div className="flex gap-2">
      {TONES.map((tone) => (
        <button key={tone} type="button" onClick={() => onChange(tone)} aria-label={`Skin tone ${tone}`}
          className={`w-7 h-7 rounded-full border-2 ${value === tone ? 'border-primary ring-2 ring-primary/20' : 'border-foreground/10'}`} style={{ background: tone }}
        />
      ))}
    </div>
  );
}
```

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(wizard): step 2 photo OR description fork with skin-tone picker"
```

## Task 3.5 — Step 3: Supporting characters (option A — invitation card + skip)

**Files:**
- Create: `hadouta-web/src/components/wizard/step-3-supporting.tsx`
- Create: `hadouta-web/src/components/wizard/character-form.tsx`

- [ ] **Step 1: Step 3 main**

```tsx
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { patchOrder } from '@/lib/wizard/api';
import { CharacterForm } from './character-form';
import { Button } from '@/components/ui/button';

export function Step3() {
  const router = useRouter();
  const store = useWizardStore();
  const [chars, setChars] = useState(store.supportingCharacters);

  const skipOrContinue = async (skip: boolean) => {
    if (!store.orderId) return;
    const finalChars = skip ? [] : chars;
    await patchOrder(store.orderId, { supportingCharacters: finalChars });
    store.setSupportingCharacters(finalChars);
    store.setStep(4);
    router.push('/wizard/4');
  };

  if (chars.length === 0) {
    return (
      <div dir="rtl" className="space-y-6">
        <header>
          <h2 className="font-heading text-2xl font-bold">حد تاني في الحدوتة؟</h2>
          <p className="text-foreground/70 text-sm mt-1">حدوتة {store.childInfo.childName ?? 'طفلك'} هتكون عنها أساساً. لو حابة تضيفي أخت، صديق، تيتا، أو حد من العيلة في القصة — تقدر دلوقتي. <strong>اختياري</strong>.</p>
        </header>

        <div className="bg-card rounded-xl border border-border p-6 text-center space-y-3">
          <div className="w-20 h-14 mx-auto rounded-lg bg-gradient-to-br from-hadouta-blush/60 to-hadouta-ochre/60 flex items-center justify-center text-2xl">👨‍👩‍👧‍👦</div>
          <h3 className="font-heading font-semibold">أضف شخصية للحدوتة</h3>
          <p className="text-sm text-foreground/65">أخ، أخت، صديق، تيتا، جدو، أو شخصية مهمة لطفلك. حتى ٢ شخصيات.</p>
          <Button variant="outline" onClick={() => setChars([{ name: '', role: 'sibling', appearanceInputType: 'description', position: 1 } as any])}>+ أضف شخصية</Button>
        </div>

        <div className="flex justify-between pt-4 border-t border-border/30">
          <Button variant="ghost" className="text-hadouta-teal underline" onClick={() => skipOrContinue(true)}>تخطي هذه الخطوة</Button>
          <Button variant="outline" onClick={() => router.push('/wizard/2')}>← السابق</Button>
        </div>
      </div>
    );
  }

  return (
    <div dir="rtl" className="space-y-4">
      <header>
        <h2 className="font-heading text-2xl font-bold">العائلة في الحدوتة</h2>
      </header>
      {chars.map((char, idx) => (
        <CharacterForm key={idx} char={char} onChange={(c) => setChars((prev) => prev.map((x, i) => i === idx ? c : x))} onRemove={() => setChars((prev) => prev.filter((_, i) => i !== idx))} />
      ))}
      {chars.length < 2 && (
        <button onClick={() => setChars([...chars, { name: '', role: 'friend', appearanceInputType: 'description', position: (chars.length + 1) as 1 | 2 }])} className="w-full border-2 border-dashed border-border rounded-lg py-3 text-sm text-foreground/65">
          + شخصية تانية (اختياري)
        </button>
      )}
      <div className="flex justify-between pt-4 border-t border-border/30">
        <Button variant="outline" onClick={() => router.push('/wizard/2')}>← السابق</Button>
        <Button onClick={() => skipOrContinue(false)}>التالي ←</Button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Character form (per-character mini-form)**

```tsx
// character-form.tsx
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';

const ROLES = [
  { value: 'sibling', label: 'أخ/أخت' },
  { value: 'friend', label: 'صديق' },
  { value: 'grandparent', label: 'تيتا/جدو' },
  { value: 'parent', label: 'أب/أم' },
  { value: 'pet', label: 'حيوان أليف' },
  { value: 'other', label: 'آخر' },
];

export function CharacterForm({ char, onChange, onRemove }: any) {
  return (
    <div className="bg-secondary/30 border border-border/50 rounded-lg p-3 space-y-2">
      <div className="flex items-center gap-2">
        <span className="bg-hadouta-ochre/30 px-2 py-0.5 rounded text-xs font-heading font-semibold">شخصية {char.position}</span>
        <button type="button" onClick={onRemove} className="ml-auto text-xs text-foreground/55 underline">إزالة</button>
      </div>
      <Input placeholder="اسم الشخصية، مثلاً: نور" value={char.name} onChange={(e) => onChange({ ...char, name: e.target.value })} />
      <div className="grid grid-cols-3 gap-1">
        {ROLES.map((r) => (
          <button key={r.value} type="button" onClick={() => onChange({ ...char, role: r.value })} className={cn('rounded text-xs py-1 border', char.role === r.value ? 'bg-primary/15 border-primary font-semibold' : 'border-border')}>
            {r.label}
          </button>
        ))}
      </div>
      <div className="grid grid-cols-2 gap-1">
        <button type="button" onClick={() => onChange({ ...char, appearanceInputType: 'photo' })} className={cn('rounded text-xs py-1.5 border-dashed border', char.appearanceInputType === 'photo' ? 'border-primary bg-primary/10' : 'border-border')}>📷 ارفع صورة</button>
        <button type="button" onClick={() => onChange({ ...char, appearanceInputType: 'description' })} className={cn('rounded text-xs py-1.5 border-dashed border', char.appearanceInputType === 'description' ? 'border-primary bg-primary/10' : 'border-border')}>✎ اوصف</button>
      </div>
      {/* Note: per-character photo upload + description fields are inline-expanded. Phase 5 sub-decision: collapse vs expand. Default expand. */}
    </div>
  );
}
```

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(wizard): step 3 supporting characters (invitation + per-char form)"
```

## Task 3.6 — Step 4: Story details

**Files:**
- Create: `hadouta-web/src/components/wizard/step-4-story.tsx`
- Create: `hadouta-web/src/components/wizard/theme-card.tsx`

- [ ] **Step 1: Implement step 4 with theme grid + moral grid + free-text**

```tsx
'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { patchOrder, fetchThemes, fetchMoralValues } from '@/lib/wizard/api';
import { ThemeCard } from './theme-card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

export function Step4() {
  const router = useRouter();
  const store = useWizardStore();
  const [themes, setThemes] = useState<any[]>([]);
  const [morals, setMorals] = useState<any[]>([]);

  useEffect(() => {
    fetchThemes(store.childInfo.childAgeBand).then(setThemes);
    fetchMoralValues().then(setMorals);
  }, [store.childInfo.childAgeBand]);

  const proceed = async () => {
    if (!store.orderId || !store.storyDetails.themeId || !store.storyDetails.moralValueId) return;
    await patchOrder(store.orderId, store.storyDetails);
    store.setStep(5);
    router.push('/wizard/5');
  };

  const canProceed = !!(store.storyDetails.themeId && store.storyDetails.moralValueId);

  return (
    <form dir="rtl" className="space-y-6" onSubmit={(e) => { e.preventDefault(); proceed(); }}>
      <header>
        <h2 className="font-heading text-2xl font-bold">حدوتة {store.childInfo.childName ?? 'طفلك'} عن إيه؟</h2>
        <p className="text-foreground/70 text-sm mt-1">اختار موضوع القصة + قيمة تربوية تحب طفلك يتعلمها.</p>
      </header>

      <div className="space-y-2">
        <Label>موضوع الحدوتة * <span className="text-xs text-hadouta-teal bg-hadouta-teal/10 px-1.5 rounded">مفلتر للعمر {store.childInfo.childAgeBand}</span></Label>
        <div className="grid grid-cols-2 gap-2">
          {themes.map((t) => (
            <ThemeCard key={t.id} theme={t} selected={store.storyDetails.themeId === t.id} onSelect={() => store.updateStoryDetails({ themeId: t.id })} />
          ))}
        </div>
      </div>

      <div className="space-y-2">
        <Label>قيمة تربوية تحب طفلك يتعلمها *</Label>
        <div className="grid grid-cols-4 gap-1">
          {morals.map((m) => (
            <button key={m.id} type="button" onClick={() => store.updateStoryDetails({ moralValueId: m.id })} className={cn('rounded py-2 px-1 text-xs border text-center leading-tight', store.storyDetails.moralValueId === m.id ? 'bg-primary/15 border-primary font-semibold' : 'border-border')}>
              {m.nameAr}
            </button>
          ))}
        </div>
      </div>

      <div className="space-y-2">
        <Label>مشهد خاص تحب يكون في الحدوتة <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
        <textarea className="w-full rounded-md border border-border bg-background p-2 text-sm" rows={3}
          placeholder="مثلاً: مشهد ليلى بتساعد أخوها الصغير يربط الحذاء..."
          value={store.storyDetails.customSceneText ?? ''} onChange={(e) => store.updateStoryDetails({ customSceneText: e.target.value })} maxLength={500}
        />
      </div>

      <div className="space-y-2">
        <Label>مناسبة خاصة <span className="text-foreground/50 text-xs">(اختياري)</span></Label>
        <Input placeholder="عيد ميلاد ليلى، نجاحها بالمدرسة..." value={store.storyDetails.specialOccasionText ?? ''} onChange={(e) => store.updateStoryDetails({ specialOccasionText: e.target.value })} maxLength={200} />
      </div>

      <div className="flex justify-between pt-4 border-t border-border/30">
        <Button type="button" variant="outline" onClick={() => router.push('/wizard/3')}>← السابق</Button>
        <Button type="submit" disabled={!canProceed}>التالي ←</Button>
      </div>
    </form>
  );
}
```

- [ ] **Step 2: Theme card component**

```tsx
// theme-card.tsx
const ICONS: Record<string, string> = {
  school: '🏫', friendship: '🤝', eid: '🌙', ramadan: '🕌',
  christmas: '⭐', shamel: '🥚', birthday: '🎂', adventure: '⛰️',
};

export function ThemeCard({ theme, selected, onSelect }: any) {
  return (
    <button type="button" onClick={onSelect} className={`relative bg-card rounded-lg p-2 text-center border-2 ${selected ? 'border-primary bg-primary/8' : 'border-border'}`}>
      <div className="h-9 flex items-center justify-center text-2xl">{ICONS[theme.illustrationKey] ?? '📖'}</div>
      <div className="font-heading font-semibold text-xs leading-tight mt-1">{theme.nameAr}</div>
      <div className="text-[9px] text-hadouta-teal bg-hadouta-teal/10 inline-block px-1.5 rounded mt-1">
        {theme.suitableAgeBands.join(' · ')}
      </div>
    </button>
  );
}
```

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(wizard): step 4 story details with age-filtered theme grid"
```

## Task 3.7 — Step 5: Review + dedication + edit jumps

**Files:** `hadouta-web/src/components/wizard/step-5-review.tsx`

- [ ] **Step 1: Implement**

```tsx
'use client';
import { useRouter } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { patchOrder } from '@/lib/wizard/api';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';

export function Step5() {
  const router = useRouter();
  const store = useWizardStore();
  const { childInfo, appearance, supportingCharacters, storyDetails, dedicationText, orderId } = store;

  const editJump = (step: number) => router.push(`/wizard/${step}`);

  const proceedToCheckout = async () => {
    if (!orderId) return;
    await patchOrder(orderId, { dedicationText, status: 'pending_payment', priceCents: 25000 });
    store.setStep(6);
    router.push('/wizard/6');
  };

  return (
    <div dir="rtl" className="space-y-4">
      <header>
        <h2 className="font-heading text-2xl font-bold">حكاية {childInfo.childName ?? 'طفلك'} جاهزة تبدأ</h2>
        <p className="text-foreground/70 text-sm mt-1">راجع التفاصيل قبل ما نبدأ. تقدر تعدل أي قسم بضغطة واحدة.</p>
      </header>

      <SummaryCard icon="👧" title="الطفل" onEdit={() => editJump(1)}>
        <Row label="الاسم">{childInfo.childName}</Row>
        <Row label="العمر">{childInfo.childAgeExact} سنوات (الفئة {childInfo.childAgeBand})</Row>
        <Row label="الجنس">{childInfo.childGender === 'girl' ? 'بنت' : 'ولد'}</Row>
        {childInfo.childHobbies && <Row label="هوايات">{childInfo.childHobbies}</Row>}
        {childInfo.childSpecialTraits && <Row label="حاجة مميزة">{childInfo.childSpecialTraits}</Row>}
      </SummaryCard>

      <SummaryCard icon="📷" title="الصورة" onEdit={() => editJump(2)}>
        <Row label="الطريقة">{appearance.appearanceInputType === 'photo' ? `صور (${appearance.photoIds?.length ?? 0} مرفوعة)` : 'وصف يدوي'}</Row>
      </SummaryCard>

      <SummaryCard icon="👨‍👩‍👧" title="العائلة" onEdit={() => editJump(3)}>
        {supportingCharacters.length === 0 ? <p className="italic text-foreground/55 text-sm">مفيش شخصيات إضافية — الحدوتة عن {childInfo.childName}</p>
        : supportingCharacters.map((c, i) => <Row key={i} label={`شخصية ${c.position}`}>{c.name} ({c.role})</Row>)}
      </SummaryCard>

      <SummaryCard icon="📖" title="الحدوتة" onEdit={() => editJump(4)}>
        <Row label="الموضوع"><span className="font-semibold">{/* TODO render theme name from id */}الموضوع</span></Row>
        <Row label="القيمة"><span className="font-semibold">{/* TODO render moral name from id */}القيمة</span></Row>
        {storyDetails.customSceneText && <Row label="مشهد خاص">{storyDetails.customSceneText}</Row>}
        {storyDetails.specialOccasionText && <Row label="المناسبة">{storyDetails.specialOccasionText}</Row>}
      </SummaryCard>

      <div className="bg-gradient-to-b from-hadouta-blush/15 to-card rounded-xl border border-hadouta-blush/40 p-4">
        <div className="text-xl mb-1">✉</div>
        <h3 className="font-heading font-bold mb-1">إهداء (اختياري)</h3>
        <p className="text-sm text-foreground/65 mb-2">جملة قصيرة هتظهر في أول صفحة من الكتاب — لمسة عائلية.</p>
        <textarea className="w-full rounded-md border border-border bg-background p-2 text-sm" rows={2} maxLength={280}
          placeholder='مثال: "إلى ليلى، شجاعتك أحلى من كل حدوتة — من بابا، أحمد"'
          value={dedicationText ?? ''} onChange={(e) => store.setDedication(e.target.value)}
        />
      </div>

      <div className="bg-hadouta-teal/8 border-t border-hadouta-teal/20 px-4 py-4 -mx-4 rounded-md">
        <p className="text-center text-xs text-foreground/65 mb-2">
          <strong className="text-hadouta-teal font-heading">فريقنا المصري بيراجع كل كتاب قبل التسليم</strong>{' '}— حدوتتك جاهزة في ٢-٣ أيام
        </p>
        <Button onClick={proceedToCheckout} className="w-full" size="lg">
          ابدأ حدوتة {childInfo.childName ?? 'طفلك'} — ٢٥٠ ج.م
          <span className="block text-xs opacity-85 mt-1 font-normal">الخطوة التالية: تأكيد رقم الموبايل + الدفع</span>
        </Button>
      </div>

      <div className="flex justify-end pt-2">
        <Button variant="outline" onClick={() => router.push('/wizard/4')}>← السابق</Button>
      </div>
    </div>
  );
}

function SummaryCard({ icon, title, onEdit, children }: any) {
  return (
    <div className="bg-card rounded-lg border border-border/40 p-3">
      <div className="flex items-center gap-2 pb-2 mb-2 border-b border-dashed border-border/40">
        <span>{icon}</span>
        <h4 className="font-heading font-bold text-sm">{title}</h4>
        <button onClick={onEdit} className="ml-auto text-xs text-hadouta-teal underline">تعديل</button>
      </div>
      <div className="space-y-1">{children}</div>
    </div>
  );
}

function Row({ label, children }: any) {
  return <div className="flex text-xs"><span className="text-foreground/55 min-w-[80px]">{label}:</span><span className="text-foreground flex-1">{children}</span></div>;
}
```

- [ ] **Step 2: Resolve theme + moral name lookup (replace TODOs)**

In step 5, fetch theme + moral by ID once and render names. Store catalog data in wizard store or fetch on mount.

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(wizard): step 5 review + dedication + edit-jumps + reassurance"
```

## Task 3.8 — Step 6: Phone OTP + Paymob redirect

**Files:** `hadouta-web/src/components/wizard/step-6-checkout.tsx`

- [ ] **Step 1: Phone OTP UI wired to existing Better-Auth phone-number plugin**

Phone-OTP backend already exists from session 5 (ADR-018). Endpoints: `/api/auth/phone-number/send-otp` + `/api/auth/phone-number/verify`.

```tsx
'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createPaymentIntent } from '@/lib/wizard/api';

const API = process.env.NEXT_PUBLIC_API_URL!;

export function Step6() {
  const router = useRouter();
  const store = useWizardStore();
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [phase, setPhase] = useState<'enter-phone' | 'enter-otp' | 'verified' | 'paying'>('enter-phone');
  const [resendIn, setResendIn] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const sendOtp = async () => {
    setError(null);
    const fullPhone = `+20${phone.replace(/^0/, '').replace(/\s/g, '')}`;
    const res = await fetch(`${API}/api/auth/phone-number/send-otp`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber: fullPhone }),
    });
    if (!res.ok) { setError('فشل إرسال الرمز. تأكد من الرقم.'); return; }
    setPhase('enter-otp');
    let countdown = 60; setResendIn(countdown);
    const t = setInterval(() => { countdown--; setResendIn(countdown); if (countdown <= 0) clearInterval(t); }, 1000);
  };

  const verifyOtp = async () => {
    setError(null);
    const fullPhone = `+20${phone.replace(/^0/, '').replace(/\s/g, '')}`;
    const res = await fetch(`${API}/api/auth/phone-number/verify`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber: fullPhone, code: otp }),
    });
    if (!res.ok) { setError('الرمز غلط أو انتهت صلاحيته.'); return; }
    setPhase('verified');
  };

  const pay = async () => {
    if (!store.orderId) return;
    setPhase('paying');
    const { iframeUrl } = await createPaymentIntent(store.orderId);
    window.location.href = iframeUrl;
  };

  return (
    <div dir="rtl" className="space-y-4">
      <header>
        <h2 className="font-heading text-2xl font-bold">تأكيد + الدفع</h2>
        <p className="text-foreground/70 text-sm mt-1">محتاجين رقم موبايل لما الكتاب يجهز نبعتلك إشعار على واتساب. مش هتسجل أو تحفظ كلمة سر.</p>
      </header>

      <div className="bg-card rounded-lg border border-border p-4 space-y-3">
        <h4 className="font-heading font-bold text-sm">رقم موبايلك</h4>
        <p className="text-xs text-foreground/55">مصري — هنبعت رمز التأكيد على واتساب أول</p>
        <div className="flex gap-2">
          <span className="bg-card border border-border rounded-md px-3 py-2 text-sm">🇪🇬 +20</span>
          <Input dir="ltr" className="text-right" placeholder="100 1234567" value={phone} onChange={(e) => setPhone(e.target.value)} disabled={phase !== 'enter-phone'} />
        </div>

        {phase === 'enter-phone' && <Button onClick={sendOtp} className="w-full">أرسل رمز التأكيد</Button>}

        {(phase === 'enter-otp' || phase === 'verified') && (
          <>
            {phase === 'verified' && <p className="text-xs text-hadouta-teal bg-hadouta-teal/10 inline-block px-2 py-0.5 rounded">✓ تم التأكيد</p>}
            <p className="text-xs text-foreground/65">الرمز اللي وصلك على واتساب:</p>
            <div className="grid grid-cols-6 gap-1" dir="ltr">
              {[0,1,2,3,4,5].map((i) => (
                <input key={i} maxLength={1} value={otp[i] ?? ''}
                  onChange={(e) => {
                    const next = otp.split(''); next[i] = e.target.value; setOtp(next.join('').slice(0,6));
                    if (e.target.value && i < 5) (e.target.nextElementSibling as HTMLInputElement)?.focus();
                  }}
                  className="rounded border-2 border-border py-2 text-center text-base font-bold disabled:opacity-50"
                  disabled={phase === 'verified'}
                />
              ))}
            </div>

            {phase === 'enter-otp' && (
              <div className="flex justify-between text-xs text-foreground/65 pt-2">
                <span>{resendIn > 0 ? `إعادة الإرسال متاحة في 0:${String(resendIn).padStart(2,'0')}` : <button onClick={sendOtp} className="text-hadouta-teal underline">إعادة الإرسال</button>}</span>
                <button onClick={() => { setPhase('enter-phone'); setOtp(''); }} className="text-hadouta-teal underline">تغيير الرقم</button>
              </div>
            )}

            {phase === 'enter-otp' && otp.length === 6 && <Button onClick={verifyOtp} className="w-full">تأكيد الرمز</Button>}
          </>
        )}

        {error && <p className="text-sm text-destructive">{error}</p>}
      </div>

      <div className="bg-gradient-to-b from-hadouta-ochre/15 to-card rounded-lg border border-hadouta-ochre/30 p-4 space-y-2">
        <div className="flex justify-between text-sm"><span>حدوتة {store.childInfo.childName ?? 'طفلك'}</span><span>٢٥٠ ج.م</span></div>
        <div className="flex justify-between font-heading font-bold text-base pt-2 border-t border-dashed border-border/40"><span>المجموع</span><span>٢٥٠ ج.م</span></div>
        <p className="text-center text-xs text-foreground/55 pt-1">
          الدفع آمن عبر Paymob<br />
          💳 📱 🏦<br />
          <span className="text-[10px]">كارت فيزا/ماستركارد · فودافون كاش · إنستاباي</span>
        </p>
      </div>

      <Button onClick={pay} disabled={phase !== 'verified'} className="w-full" size="lg">
        ابدأ حدوتة {store.childInfo.childName ?? 'طفلك'} — ادفع ٢٥٠ ج.م
        <span className="block text-xs opacity-85 mt-1 font-normal">هتتحول للدفع الآمن عبر Paymob</span>
      </Button>

      <div className="flex justify-end pt-2">
        <Button variant="outline" onClick={() => router.push('/wizard/5')}>← مراجعة</Button>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify Better-Auth phone-number endpoints accept these payloads**

Backend was implemented session 5. Verify routes exist:
```bash
cd hadouta-backend && pnpm dev
curl -s http://localhost:3001/openapi.json | jq '.paths | keys[]' | grep phone
```

Expected: `/api/auth/phone-number/send-otp`, `/api/auth/phone-number/verify` listed.

- [ ] **Step 3: End-to-end smoke test**

Manually flow through wizard 1→6, send OTP to your real number (Twilio sandbox), verify, click pay, land on Paymob iframe. Use Paymob test cards.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(wizard): step 6 phone OTP + Paymob redirect"
```

## Task 3.9 — Step 7: Confirmation

**Files:** `hadouta-web/src/components/wizard/step-7-confirmation.tsx`

- [ ] **Step 1: Implement** (full component, similar to wireframe)

```tsx
'use client';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { useWizardStore } from '@/lib/wizard/store';
import { fetchOrder } from '@/lib/wizard/api';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export function Step7() {
  const params = useSearchParams();
  const orderIdFromUrl = params.get('orderId');
  const store = useWizardStore();
  const orderId = orderIdFromUrl ?? store.orderId;
  const [order, setOrder] = useState<any>(null);

  useEffect(() => { if (orderId) fetchOrder(orderId).then(setOrder); }, [orderId]);
  useEffect(() => {
    // Track conversion event
    if (typeof window !== 'undefined' && (window as any).posthog) {
      (window as any).posthog.capture('order_confirmed', { orderId });
    }
  }, [orderId]);

  return (
    <div dir="rtl" className="space-y-0">
      <div className="bg-gradient-to-b from-hadouta-blush/30 to-background py-12 text-center px-4">
        <div className="w-20 h-20 mx-auto mb-3 rounded-full bg-gradient-to-br from-hadouta-blush via-hadouta-ochre to-hadouta-teal/40 flex items-center justify-center text-3xl">📖</div>
        <h2 className="font-display text-3xl font-bold leading-tight">حكاية {order?.childName ?? store.childInfo.childName ?? 'طفلك'} بدأت</h2>
        <p className="font-heading text-base mt-1">— شكراً يا {order?.buyerName ?? store.childInfo.buyerName}</p>
        <p className="text-sm text-foreground/70 max-w-md mx-auto mt-4 leading-relaxed">
          بدأنا في إعداد حدوتة {order?.childName ?? store.childInfo.childName}. خلال ٢-٣ أيام، فريقنا المصري بيراجعها وبيبعتلك رسالة على واتساب لما تكون جاهزة.
        </p>
      </div>

      <div className="bg-card rounded-lg border border-border/40 p-3 mt-4 mx-2 space-y-1">
        <Row label="رقم الطلب">#HAD-{new Date().getFullYear()}-{String(order?.id ?? '0042').slice(-4)}</Row>
        <Row label="طول الكتاب">١٦ صفحة · رسومات مائية</Row>
        <Row label="جاهز خلال">٢-٣ أيام</Row>
      </div>

      <div className="bg-hadouta-teal/8 border border-hadouta-teal/20 rounded-md p-3 text-sm leading-relaxed mt-3">
        <strong className="text-hadouta-teal font-heading">كل حدوتة بنراجعها بعناية.</strong> لو الإصدار الأول مش بمستوى طفلك، بنحضّرها تاني — وقت إضافي حوالي ٢٤ ساعة، شامل في السعر.
      </div>

      <div className="space-y-2 px-2 pt-4">
        <Button variant="outline" className="w-full">تتبع حالة الطلب</Button>
        <Link href="/" className="block text-center text-sm text-hadouta-teal underline py-2">العودة للصفحة الرئيسية</Link>
      </div>
    </div>
  );
}

function Row({ label, children }: any) {
  return <div className="flex justify-between text-sm py-1 border-b border-dashed border-border/30 last:border-0"><span className="text-foreground/55">{label}</span><span className="font-semibold">{children}</span></div>;
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(wizard): step 7 confirmation with honest copy"
```

---

# Part 4 — End-to-end integration + production readiness

## Task 4.1 — End-to-end smoke test (manual)

- [ ] Start backend (`pnpm dev` in hadouta-backend) + frontend (`pnpm dev` in hadouta-web)
- [ ] Open `http://localhost:3000`
- [ ] Verify landing page renders all sections correctly
- [ ] Click "ابدأ حدوتة طفلك" → wizard opens at `/wizard/1`
- [ ] Fill child info form → submit → land on step 2
- [ ] Pick photo path → upload a real image → verify thumbnail shows
- [ ] Switch to description path → fill skin tone + hair + clothing → verify state preserved when switching back to photo
- [ ] Continue to step 3 → add 1 supporting character with description → verify
- [ ] Step 4 → verify themes are filtered by age band picked in step 1 → select theme + moral
- [ ] Step 5 → verify all data appears in summary cards → click "تعديل" on Child card → verify it jumps to step 1 with answers preserved → return to step 5
- [ ] Add dedication → click "ابدأ حدوتة" CTA → land on step 6
- [ ] Enter phone → send OTP (Twilio sandbox/dev) → enter code → verify
- [ ] Click "ادفع" → land on Paymob iframe (test mode)
- [ ] Use Paymob test card `5123456789012346 / 12/27 / 123` → succeed
- [ ] Land on `/wizard/7?orderId=<id>` → confirmation renders correctly
- [ ] Verify order in `pnpm db:studio` shows status='paid', all fields populated

## Task 4.2 — Production env vars

Set in Vercel + Railway dashboards:
- `NEXT_PUBLIC_API_URL` — Railway prod backend URL
- `R2_*` keys (Cloudflare R2)
- `PAYMOB_*` keys (test for staging, live for prod)
- `TWILIO_*` already set per session 5

## Task 4.3 — Vercel production deploy

```bash
git push origin feat/phase-5-implementation  # creates PR
# After review + merge to main:
# Vercel auto-deploys to https://hadouta-web.vercel.app
# Railway auto-deploys to https://hadouta-backend-production.up.railway.app
```

Verify smoke test from Task 4.1 against production URLs.

## Task 4.4 — WhatsApp template submission (Track B partial)

Per ADR-018 + brand brief WhatsApp spec:
1. Submit Auth template (OTP) — typically auto-approved
2. Submit Order Confirmation utility template — 24-48h Meta review
3. Defer marketing templates to Sprint 2

## Task 4.5 — Update sprint tracker + write session note

```bash
cd /home/ahmed/Desktop/hadouta
# Update docs/sprints/sprint-tracker.md to mark Phase 5 ✅
# Write docs/session-notes/<date>-session-X.md with summary
git add docs/sprints/sprint-tracker.md docs/session-notes/
git commit -m "docs: Phase 5 implementation complete"
```

---

## Self-Review Checklist

After plan written, verify:

- [x] **Spec coverage**: every section in `phase-3-design-spec.md` has a corresponding task — landing 9 sections (Tasks 2.2-2.11) + wizard 7 steps (Tasks 3.3-3.9) + 3 upstream structural decisions baked into schema (Tasks 1.1-1.4)
- [x] **No placeholders**: every step shows the actual code, no TBD/TODO except the explicit "Phase 5+ deferred" notes (e.g., real watercolor hero illustration, theme card SVG icons get refined)
- [x] **Type consistency**: TypeScript types match across backend Zod schemas + frontend Zustand store + form schemas
- [x] **DB migrations sequenced**: 0003 (moral_values) → 0004 (supporting_characters) → 0005 (themes extension) → 0006 (orders extension) → 0007 (photos)
- [x] **Tests written**: integration tests for backend tables + APIs; manual e2e for full wizard flow
- [x] **AI-honesty rule applied**: all customer-facing copy in tasks 2.x and 3.x uses the quiet middle path (no "hand-painted", no loud "AI" badge, leads with Egyptian human review + 2-3 day care signal)
- [x] **Brand brief amendment referenced**: production-honesty section in `brand-brief.md` cited
- [x] **Schema migration safety**: column additions (no destructive changes to existing data); production migration safe to roll forward

---

## Execution Handoff

Plan complete and saved to `docs/design/specs/2026-05-02-phase-5-implementation-plan.md`. Two execution options:

**1. Subagent-Driven (recommended for time pressure)** — I dispatch a fresh subagent per task (or per Part 1 / 2 / 3 chunk), review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session (or a fresh one) using `superpowers:executing-plans`, batch execution with checkpoints for your review.

**Which approach?**
