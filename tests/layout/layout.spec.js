const { test, expect } = require("../support/fixtures");
const { login } = require("../support/frappe");
const { auditLayout } = require("../support/ui-audit");

test.describe("FlexiRule layout and component geometry", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("RuleFlow workspace has usable geometry at desktop and laptop widths", async ({
    page,
  }) => {
    for (const viewport of [{ width: 1440, height: 900 }, { width: 1024, height: 768 }]) {
      await page.setViewportSize(viewport);
      await page.goto("/app/workspace/ruleflow");
      await expect(page.locator(".workspace-header")).toBeVisible({ timeout: 30000 });
      const measurements = await auditLayout(page, test.info(), "workspace-" + viewport.width);
      expect(measurements.elements[".workspace-header"]).not.toBeNull();
      expect(measurements.elements[".layout-main-section"]).not.toBeNull();
    }
  });

  test("Visual Builder canvas and primary controls fit the viewport", async ({
    page,
    testRules,
  }) => {
    const doc = await testRules.create();
    for (const viewport of [{ width: 1440, height: 900 }, { width: 1024, height: 768 }]) {
      await page.setViewportSize(viewport);
      await page.goto("/app/rule-builder/" + encodeURIComponent(doc.name));
      await expect(page.locator(".rule-builder-container")).toBeVisible({ timeout: 60000 });
      await expect(page.locator(".vue-flow")).toBeVisible();
      await expect(page.locator(".controls-panel")).toBeVisible();
      const measurements = await auditLayout(page, test.info(), "builder-" + viewport.width);
      expect(measurements.elements[".rule-builder-container"]).not.toBeNull();
      expect(measurements.elements[".vue-flow"]).not.toBeNull();
    }
  });
});