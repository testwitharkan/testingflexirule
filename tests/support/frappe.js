const { expect } = require("@playwright/test");

async function login(page) {
  const username = process.env.FRAPPE_TEST_USER || "Administrator";
  const password = process.env.FRAPPE_TEST_PASSWORD || "admin";

  await page.goto("/login");
  const emailInput = page.locator("#login_email");
  if (await emailInput.isVisible().catch(() => false)) {
    await emailInput.fill(username);
    await page.locator("#login_password").fill(password);
    await Promise.all([
      page.waitForURL((url) => !url.pathname.includes("/login"), { timeout: 45000 }),
      page.locator("button.btn-login").click(),
    ]);
  } else {
    await page.goto("/app");
  }

  if (page.url().includes("setup-wizard")) {
    throw new Error(
      "Frappe redirected to the setup wizard. Complete frappe.utils.install.complete_setup_wizard in the test-site setup before running UI tests."
    );
  }

  await expect(page.locator(".navbar")).toBeVisible({ timeout: 45000 });
  await page.waitForFunction(() => typeof window.frappe?.call === "function");
}

async function callFrappe(page, method, args) {
  return page.evaluate(async ({ method, args }) => {
    if (!window.frappe || typeof window.frappe.call !== "function") {
      throw new Error("Frappe client API is not available in this page.");
    }
    const response = await window.frappe.call({ method, args });
    if (response && response.exc) {
      throw new Error(String(response._server_messages || response.exc));
    }
    return response ? response.message : null;
  }, { method, args });
}

async function createRule(page, overrides = {}) {
  const unique = Date.now().toString(36) + "_" + Math.random().toString(36).slice(2, 8);
  const ruleName = overrides.rule_name || "PW_UI_" + unique;
  const doc = {
    doctype: "Rule",
    rule_name: ruleName,
    trigger_type: "DocType Event",
    document_type: "Contact",
    trigger_event: "After Save",
    priority: 0,
    execution_mode: "Synchronous",
    is_active: 0,
    debug_mode: 0,
    ...overrides,
  };
  return callFrappe(page, "frappe.client.insert", { doc });
}

async function deleteRule(page, name) {
  if (!name) return;
  return callFrappe(page, "frappe.client.delete", { doctype: "Rule", name });
}

module.exports = {
  login,
  callFrappe,
  createRule,
  deleteRule,
};