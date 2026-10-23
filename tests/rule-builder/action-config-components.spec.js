const { test, expect } = require("../support/fixtures");
const { login } = require("../support/frappe");

// These labels map to the explicit component registry in
// flexirule/public/js/flexirule/rule_builder/components/rule_config/ConfigurationPanel.vue.
// Process is excluded because the selectable operation list depends on site-specific Process records.
const configurableActions = [
  "Assignment",
  "Condition",
  "Loop",
  "Switch",
  "Wait",
  "Notify",
  "Raise Error",
  "Query Records",
  "Document Action",
  "Sub-Rule",
];

async function addAction(page, actionLabel, customLabel) {
  const addButton = page.locator('[data-testid="edge-add-button"], .edge-add-button').last();
  await expect(addButton).toBeVisible({ timeout: 30000 });
  await addButton.click();

  const option = page.locator(".result-item.is-option").filter({ hasText: actionLabel }).first();
  await expect(option).toBeVisible({ timeout: 15000 });
  await option.click();

  // Some action types have an operation-selection step before their label step.
  const labeling = page.locator(".labeling-container");
  if (!(await labeling.isVisible().catch(() => false))) {
    const operation = page.locator(".result-item.is-option").first();
    await expect(operation).toBeVisible({ timeout: 15000 });
    await operation.click();
  }

  await expect(labeling).toBeVisible({ timeout: 15000 });
  await labeling.locator("input").fill(customLabel);
  await labeling.locator("button.btn-primary").click();

  const node = page.locator(".vue-flow__node").filter({ hasText: customLabel }).first();
  await expect(node).toBeVisible({ timeout: 20000 });
  return node;
}

test.describe("FlexiRule action configuration component registry", () => {
  for (const actionLabel of configurableActions) {
    test(actionLabel + " selects and renders its configuration component", async ({
      page,
      testRules,
    }) => {
      await login(page);
      const rule = await testRules.create();
      await page.goto("/app/rule-builder/" + encodeURIComponent(rule.name));
      await expect(page.locator(".vue-flow")).toBeVisible({ timeout: 60000 });

      const customLabel = "PW Component " + actionLabel.replace(/[^a-z0-9]+/gi, "_");
      const node = await addAction(page, actionLabel, customLabel);
      await node.click();

      const modal = page.locator(".config-modal-container");
      await expect(modal).toBeVisible({ timeout: 20000 });
      await expect(modal.locator(".configuration-panel")).toBeVisible();
      await expect(
        modal.locator(".configuration-panel .empty-config"),
        actionLabel + " should resolve to its registered configuration component, not the empty fallback."
      ).toHaveCount(0);
      await expect(modal.locator(".configuration-panel .panel-sections > *")).not.toHaveCount(0);

      await modal.locator("button.close-action").click();
      await expect(modal).toHaveCount(0);
    });
  }
});