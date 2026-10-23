const { test, expect } = require("../support/fixtures");
const { login } = require("../support/frappe");

async function addAction(page, actionLabel, customLabel) {
  const addButton = page.locator('[data-testid="edge-add-button"], .edge-add-button').last();
  await expect(addButton).toBeVisible({ timeout: 30000 });
  await addButton.click();

  const option = page.locator(".result-item.is-option").filter({ hasText: actionLabel }).first();
  await expect(option).toBeVisible({ timeout: 15000 });
  await option.click();

  const labeling = page.locator(".labeling-container");
  if (!(await labeling.isVisible().catch(() => false))) {
    const nextOption = page.locator(".result-item.is-option").first();
    await expect(nextOption).toBeVisible({ timeout: 15000 });
    await nextOption.click();
  }

  await expect(labeling).toBeVisible({ timeout: 15000 });
  await labeling.locator("input").fill(customLabel);
  await labeling.locator("button.btn-primary").click();

  const newNode = page.locator(".vue-flow__node").filter({ hasText: customLabel }).first();
  await expect(newNode).toBeVisible({ timeout: 20000 });
  return newNode;
}

test.describe("FlexiRule Visual Builder", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("lazy bundle registers the builder and displays the VueFlow canvas", async ({
    page,
    testRules,
  }) => {
    const doc = await testRules.create();
    await page.goto("/app/rule-builder/" + encodeURIComponent(doc.name));

    await expect(page.locator(".rule-builder-container")).toBeVisible({ timeout: 60000 });
    await expect(page.locator(".vue-flow")).toBeVisible();
    await expect(page.locator(".controls-panel")).toBeVisible();
    await expect(page.locator('button[title="Zoom In"]')).toBeVisible();
    await expect(page.locator('button[title="Zoom Out"]')).toBeVisible();
    await expect(page.locator('button[title="Fit View"]')).toBeVisible();

    await page.waitForFunction(() =>
      typeof window.frappe?.ui?.RuleBuilder === "function" &&
      typeof window.flexirule?.contracts?.loadContractsFromBackend === "function"
    );
  });

  test("Assignment configuration supports Raw Configuration and return navigation", async ({
    page,
    testRules,
  }) => {
    const doc = await testRules.create();
    await page.goto("/app/rule-builder/" + encodeURIComponent(doc.name));
    await expect(page.locator(".vue-flow")).toBeVisible({ timeout: 60000 });

    const node = await addAction(page, "Assignment", "PW Assignment Modal");
    await node.click();

    const modal = page.locator(".config-modal-container");
    await expect(modal).toBeVisible({ timeout: 20000 });
    await expect(modal.locator(".workspace-view-container")).toBeVisible();
    await expect(modal.locator(".assignment-config")).toBeVisible();
    await expect(modal.locator(".assignment-config .add-assignment-btn")).toBeVisible();

    await modal.locator('.header-toolbar button[title*="Raw Configuration"]').click();
    await expect(modal.locator(".full-raw-config-container")).toBeVisible();
    await expect(modal.locator(".btn-back-nav")).toBeVisible();

    await modal.locator(".btn-back-nav").click();
    await expect(modal.locator(".workspace-view-container")).toBeVisible();
    await expect(modal.locator(".full-raw-config-container")).toHaveCount(0);

    await modal.locator("button.close-action").click();
    await expect(modal).toHaveCount(0);
  });

  test("canvas action label persists after Save Rule and reload", async ({ page, testRules }) => {
    const doc = await testRules.create();
    await page.goto("/app/rule-builder/" + encodeURIComponent(doc.name));
    await expect(page.locator(".vue-flow")).toBeVisible({ timeout: 60000 });

    await addAction(page, "Wait", "PW Persisted Wait");

    const saveButton = page.getByRole("button", { name: /Save Rule/ });
    await expect(saveButton).toBeVisible();
    await saveButton.click();
    await expect(page.locator(".desk-alert.green")).toContainText("Saved", { timeout: 30000 });

    await page.reload();
    await expect(page.locator(".vue-flow")).toBeVisible({ timeout: 60000 });
    await expect(page.locator(".vue-flow__node").filter({ hasText: "PW Persisted Wait" }))
      .toBeVisible({ timeout: 30000 });
  });
});