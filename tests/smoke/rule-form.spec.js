const { test, expect } = require("../support/fixtures");
const { login } = require("../support/frappe");

test.describe("Rule form conditional behavior", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("trigger type updates the trigger-dependent fields", async ({ page }) => {
    await page.goto("/app/rule/new-rule-1");

    const triggerType = page.locator('[data-fieldname="trigger_type"] select');
    const triggerEvent = page.locator('.frappe-control[data-fieldname="trigger_event"]');
    const triggerCondition = page.locator('.frappe-control[data-fieldname="trigger_condition"]');

    await expect(triggerType).toBeVisible({ timeout: 30000 });
    await expect(triggerEvent).toBeVisible();

    await triggerType.selectOption({ label: "Scheduler Event" });
    await expect(triggerEvent).toBeHidden();
    await expect(triggerCondition).toBeHidden();

    await triggerType.selectOption({ label: "Callable Event" });
    await expect(triggerEvent).toBeHidden();
    await expect(page.locator('.frappe-control[data-fieldname="exposed_as_subrule"]')).toBeVisible();
  });

  test("an active Rule is locked and offers the deactivation dialog", async ({
    page,
    testRules,
  }) => {
    const doc = await testRules.create({ is_active: 1 });
    await page.goto("/app/rule/" + encodeURIComponent(doc.name));

    const ruleName = page.locator('[data-fieldname="rule_name"] input').first();
    await expect(ruleName).toBeVisible({ timeout: 30000 });
    await expect.poll(() => ruleName.evaluate((element) => element.readOnly)).toBe(true);

    const active = page.locator('input[data-fieldname="is_active"]');
    await expect(active).toBeVisible();
    await active.uncheck({ force: true });

    await expect(page.getByText("Deactivate Rule", { exact: true })).toBeVisible();
    await expect(page.getByRole("button", { name: "Edit Current Rule" })).toBeVisible();

    await page.getByRole("button", { name: "Edit Current Rule" }).click();
    await expect.poll(() => active.isChecked()).toBe(false);
  });
});