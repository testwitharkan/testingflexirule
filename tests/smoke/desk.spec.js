const { test, expect } = require("../support/fixtures");
const { login } = require("../support/frappe");

test.describe("FlexiRule Desk smoke checks", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("RuleFlow workspace renders its primary shortcuts and cards", async ({ page }) => {
    await page.goto("/app/workspace/ruleflow");
    await expect(page.locator(".workspace-header")).toBeVisible();

    for (const label of ["New Rule", "Rule List", "Rule Builder", "Execution Logs"]) {
      await expect(page.locator(".shortcut-widget").filter({ hasText: label }).first())
        .toBeVisible();
    }
    for (const label of ["Total Rules", "Active Rules"]) {
      await expect(page.locator(".number-card-widget").filter({ hasText: label }).first())
        .toBeVisible();
    }
  });

  test("Rule list opens the Visual Builder for a real inactive Rule", async ({
    page,
    testRules,
  }) => {
    const doc = await testRules.create();
    await page.goto("/app/rule");

    const row = page.locator(".list-row-container .list-row").filter({
      hasText: doc.rule_name,
    }).first();
    await expect(row).toBeVisible({ timeout: 30000 });
    const openButton = row.locator('button[title*="Open Rule Builder"]');
    await expect(openButton).toBeVisible();
    await openButton.click();

    await expect(page).toHaveURL(new RegExp("/app/rule-builder/" + encodeURIComponent(doc.name)));
    await expect(page.locator(".vue-flow")).toBeVisible({ timeout: 60000 });
    await expect(page.locator(".rule-builder-container")).toBeVisible();
  });

  test("Rule form saves its native Link and Select fields", async ({ page, testRules }) => {
    const unique = "PW_UI_FORM_" + Date.now();
    testRules.track(unique);
    await page.goto("/app/rule/new-rule-1");

    const nameInput = page.locator('[data-fieldname="rule_name"] input');
    await expect(nameInput).toBeVisible({ timeout: 30000 });
    await nameInput.fill(unique);

    const doctypeInput = page.locator('[data-fieldname="document_type"] input');
    await doctypeInput.fill("Contact");
    const doctypeSuggestion = page.locator(".awesomplete li[role='option']")
      .filter({ hasText: "Contact" }).first();
    await expect(doctypeSuggestion).toBeVisible({ timeout: 15000 });
    await doctypeSuggestion.click();
    await expect(doctypeInput).toHaveValue("Contact");

    const triggerSelect = page.locator('[data-fieldname="trigger_event"] select');
    await triggerSelect.selectOption({ label: "After Save" });

    const saveResponsePromise = page.waitForResponse((response) =>
      response.url().includes("/api/method/frappe.desk.form.save.savedocs") ||
      response.url().includes("method=frappe.desk.form.save.savedocs")
    );
    await page.getByRole("button", { name: "Save", exact: true }).click();
    const saveResponse = await saveResponsePromise;
    expect(saveResponse.status()).toBe(200);

    await expect(page.getByRole("button", { name: "Visual Builder" })).toBeVisible({
      timeout: 30000,
    });

    const saved = await page.evaluate(() => {
      const doc = window.cur_frm && window.cur_frm.doc;
      return doc ? { name: doc.name, is_active: doc.is_active } : null;
    });
    if (saved && saved.name) testRules.track(saved.name);
  });
});